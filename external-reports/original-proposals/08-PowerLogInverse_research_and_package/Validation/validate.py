#!/usr/bin/env python3
"""Independent exact-algebra and high-precision validation.

This does NOT execute Wolfram Language. It independently implements the
mathematical coefficient formula and checks it using clipped binomial/log
composition and ordinary polynomial composition, plus numerical bisection.
Requires Python >=3.9, sympy, mpmath. All validation is offline.
Run from any directory: python Validation/validate.py
"""
from __future__ import annotations
import itertools
import json
import math
import platform
from pathlib import Path
from typing import Dict, Iterable, List, Tuple
import sympy as S
import mpmath as mp

L = S.Symbol('L', real=True)
u = S.Symbol('u', positive=True)
Row = Tuple[S.Expr, S.Expr]
Series = Dict[S.Expr, S.Expr]

def canon(x):
    return S.expand(S.sympify(x))

def lt(a, b) -> bool:
    z = S.simplify(b-a)
    v = z.is_positive
    if v is None:
        v = S.ask(S.Q.positive(z))
    if v is None:
        raise ValueError(f'Undecidable exact order: {a}, {b}')
    return bool(v)

def norm(rows: Iterable[Row], cut) -> Series:
    out: Series = {}
    for e, q in rows:
        e = canon(e)
        if lt(e, cut):
            out[e] = S.expand(out.get(e, S.S.Zero)+q)
    return {e:S.expand(q) for e,q in out.items() if S.expand(q) != 0}

def ordered(d: Series) -> List[Row]:
    from functools import cmp_to_key
    def cmp(a,b):
        return -1 if lt(a,b) else (1 if lt(b,a) else 0)
    return [(e,d[e]) for e in sorted(d,key=cmp_to_key(cmp))]

def add(a: Series, b: Series, cut) -> Series:
    return norm(list(a.items())+list(b.items()),cut)

def mul(a: Series, b: Series, cut) -> Series:
    return norm(((e+f,p*q) for e,p in a.items() for f,q in b.items()),cut)

def scale(a: Series, c, cut) -> Series:
    return norm(((e,p*c) for e,p in a.items()),cut)

def shift(a: Series, d, cut) -> Series:
    return norm(((e+d,p) for e,p in a.items()),cut)

def binomial(r: Series, q, cut) -> Series:
    out={S.S.Zero:S.S.One}; power=out.copy(); k=0; b=S.S.One
    while r:
        k += 1
        power=mul(power,r,cut)
        if not power: break
        b=S.expand(b*(q-k+1)/k)
        if b==0: break
        out=add(out,scale(power,b,cut),cut)
        if k>512: raise RuntimeError('degree budget exceeded')
    return out

def logarithm(r: Series, cut) -> Series:
    out={}; power={S.S.Zero:S.S.One}; k=0
    while r:
        k+=1
        power=mul(power,r,cut)
        if not power: break
        out=add(out,scale(power,S.Rational((-1)**(k+1),k),cut),cut)
        if k>512: raise RuntimeError('degree budget exceeded')
    return out

def polynomial(P, arg: Series, cut) -> Series:
    out={}
    for coeff in S.Poly(P,L).all_coeffs():
        out=add(mul(out,arg,cut),{S.S.Zero:coeff},cut)
    return out

def multiindices(d: List[S.Expr], B):
    # Cartesian bounds deliberately differ from WL simplex DFS.
    bounds=[int(S.ceiling(S.simplify(B/x))) for x in d]
    for m in itertools.product(*(range(n) for n in bounds)):
        if sum(m) and lt(sum((mi*di for mi,di in zip(m,d)),S.S.Zero),B):
            yield m

def inverse(p, corr: List[Row], cutoff) -> Series:
    p=S.sympify(p); cutoff=S.sympify(cutoff)
    d=[S.sympify(t[0]) for t in corr]; pol=[S.sympify(t[1]) for t in corr]
    rows=[(S.S.One,S.S.One)]
    for m in multiindices(d,cutoff-1):
        n=sum(m); delta=canon(sum((mi*di for mi,di in zip(m,d)),S.S.Zero))
        Q=S.expand(S.prod(P**mi for P,mi in zip(pol,m)))
        for j in range(1,n):
            Q=S.expand(S.diff(Q,L)+(1+delta+p*j)*Q)
        Q=S.expand((-1)**n*Q/(p**n*S.prod(S.factorial(mi) for mi in m)))
        rows.append((1+delta,Q))
    return norm(rows,cutoff)

def residual(A: Series,p,corr: List[Row],cutoff) -> Series:
    p=S.sympify(p); cutoff=S.sympify(cutoff)
    r=add(shift(A,-1,cutoff),{S.S.Zero:-S.S.One},cutoff)
    logx=add({S.S.Zero:L},logarithm(r,cutoff),cutoff)
    unit={S.S.Zero:S.S.One}
    for d,P in corr:
        if lt(S.sympify(d),cutoff):
            term=mul(binomial(r,S.sympify(d),cutoff),polynomial(P,logx,cutoff),cutoff)
            unit=add(unit,shift(term,S.sympify(d),cutoff),cutoff)
    return add(mul(binomial(r,p,cutoff),unit,cutoff),{S.S.Zero:-S.S.One},cutoff)

def evaluate(A: Series, v: mp.mpf) -> mp.mpf:
    ell=mp.log(v)
    out=mp.mpf('0')
    for e,P in A.items():
        # Convert exact symbolic coefficients with more digits than the target.
        ee=mp.mpf(str(S.N(e,mp.mp.dps+10)))
        co=S.Poly(P,L).all_coeffs()
        q=mp.mpf('0')
        for c in co:
            q=q*ell+mp.mpf(str(S.N(c,mp.mp.dps+10)))
        out += v**ee*q
    return out

def bisect_root(f, y, initial, steps=800):
    lo=initial/2; hi=initial*2
    assert f(lo)<y<f(hi), 'root bracket failed'
    for _ in range(steps):
        mid=(lo+hi)/2
        if f(mid)<y: lo=mid
        else: hi=mid
    return (lo+hi)/2

def main():
    checks=[]
    def check(name,condition):
        ok=bool(condition)
        checks.append({'name':name,'passed':ok})
        if not ok: raise AssertionError(name)
    logcorr=[(S.S.One,1+L)]
    A=inverse(1,logcorr,8)
    expected={1:1,2:-1-L,3:2*L**2+5*L+3,
      4:-5*L**3-S.Rational(41,2)*L**2-27*L-S.Rational(23,2)}
    for e,P in expected.items():
        check(f'log example coefficient u^{e}',S.expand(A[S.Integer(e)]-P)==0)
    check('log example residual to relative power 7',residual(A,1,logcorr,7)=={})
    leading=residual(A,1,logcorr,8)
    Aone=inverse(1,logcorr,9)
    check('first omitted log block equals negative residual',
          S.expand(leading[7]+Aone[8])==0)
    # Ordinary u-series computation independent of sparse operations.
    B=inverse(1,logcorr,5)
    expr=sum(u**e*P for e,P in B.items())
    v=S.expand(expr/u-1)
    # Generate log(1+v) by ordinary power series in u (L independent).
    lv=S.series(sum(S.Rational((-1)**(k+1),k)*v**k for k in range(1,5)),u,0,5).removeO()
    direct=S.series(expr+expr**2*(1+L+lv)-u,u,0,5).removeO().expand()
    check('log example direct ordinary-series substitution',direct==0)

    r=S.sqrt(2); delta=r-1
    irrcorr=[(delta,S.S.One)]
    I=inverse(1,irrcorr,canon(1+9*delta))
    for n in range(1,9):
        # generalized Fuss-Catalan product; no generalized binomial black box
        c=(-1)**n*S.prod(n*r-k for k in range(n-1))/S.factorial(n)
        e=canon(1+n*delta)
        check(f'irrational example closed coefficient n={n}',S.expand(I[e]-c)==0)
    # A smaller cutoff keeps exact residual composition inexpensive.
    Is=inverse(1,irrcorr,canon(1+5*delta))
    check('irrational example residual',residual(Is,1,irrcorr,canon(5*delta))=={})
    check('strict irrational boundary omitted',canon(1+9*delta) not in I)

    cases=[
      ('Catalan polynomial',1,[(1,1)],7),
      ('colliding exponents',1,[(1,1),(2,1)],7),
      ('duplicate generator split',1,[(1,L),(1,1)],6),
      ('mixed irrational logarithmic',1,[(r-1,1),(1,L+1)],S.Rational(7,2)),
      ('square-root leading inverse',2,[(1,L),(r,3)],4),
      ('nonintegral leading exponent',S.Rational(3,2),[(S.Rational(1,2),L**2-2),(1,L+3)],3),
      ('sign-changing correction',S.Rational(2,3),[(1,-L**2-1),(2,2*L)],4),
      ('vanishing correction',1,[(1,0)],5),
    ]
    stored={}
    for name,p,corr,C in cases:
        result=inverse(p,corr,C)
        check(name+' residual',residual(result,p,corr,S.sympify(C)-1)=={})
        stored[name]=result
    cat=stored['Catalan polynomial']
    for n in range(0,6):
        check(f'Catalan coefficient {n}',cat[S.Integer(n+1)]==(-1)**n*S.catalan(n))
    collision=stored['colliding exponents']
    check('collision cancels u^4',S.Integer(4) not in collision)
    check('collision u^5 coefficient',collision[S.Integer(5)]==-4)
    check('split same exponent agrees',inverse(1,[(1,L),(1,1)],6)==inverse(1,logcorr,6))
    # Deliberately wrong approximation must be rejected by residual checking.
    broken=dict(inverse(1,logcorr,5)); broken[S.Integer(3)]+=1
    check('corruption detected',residual(broken,1,logcorr,4)!={})
    # Pure p-power has exact inverse u.
    check('monomial inverse',inverse(3,[],6)=={S.S.One:S.S.One})

    mp.mp.dps=110
    numeric=[]
    for name,f,corr,pc,ac,Cs in [
       ('log',lambda x:x+x*x*(1+mp.log(x)),logcorr,mp.mpf(1),mp.mpf(1),[3,5,7]),
       ('irrational',lambda x:x+x**mp.sqrt(2),irrcorr,mp.mpf(1),mp.mpf(1),
        [canon(1+2*delta),canon(1+4*delta),canon(1+6*delta)]),
       ('mixed-p2',lambda x:4*x*x*(1+x*mp.log(x)+3*x**mp.sqrt(2)),[(1,L),(r,3)],
        mp.mpf(2),mp.mpf(4),[3,4,5])
    ]:
        for exponent in (4,8,16):
            y=mp.power(10,-exponent); unif=(y/ac)**(1/pc)
            root=bisect_root(f,y,unif)
            errors=[]
            for C in Cs:
                AA=inverse(S.Rational(str(pc)),corr,C)
                approx=evaluate(AA,unif)
                err=abs(approx-root)
                errors.append(err)
                numeric.append({'case':name,'y':mp.nstr(y,8),'cutoff':str(C),
                  'absolute_error':mp.nstr(err,12),'relative_error':mp.nstr(err/root,12),
                  'normalized_residual':mp.nstr(abs(f(approx)/y-1),12)})
            check(f'{name} successive truncations improve y=1e-{exponent}',
                  all(errors[i+1]<errors[i] for i in range(len(errors)-1)))
    # Remainder constant for two-term log expansion: error/[u^3 L^2] -> 2.
    ratios=[]
    for exponent in (20,50,100):
        mp.mp.dps=4*exponent+50
        y=mp.power(10,-exponent)
        root=bisect_root(lambda x:x+x*x*(1+mp.log(x)),y,y,steps=5*exponent+800)
        approx=y-y*y*(1+mp.log(y))
        rat=(root-approx)/(y**3*mp.log(y)**2)
        ratios.append({'y':f'1e-{exponent}','ratio':mp.nstr(rat,18)})
    check('log remainder leading constant tends to 2',abs(rat-2)<mp.mpf('0.025'))
    # Exact radius via Stirling, evaluated for the motivating irrational power.
    mp.mp.dps=80
    rr=mp.sqrt(2); radius=(rr-1)**(rr-1)/rr**rr
    radius_y=radius**(1/(rr-1))
    result={
      'scope':'Independent Python/SymPy/mpmath validation; not Wolfram-kernel execution.',
      'python':platform.python_version(),'sympy':S.__version__,'mpmath':mp.__version__,
      'passed':sum(c['passed'] for c in checks),'total':len(checks),'checks':checks,
      'numeric':numeric,'log_remainder_ratios':ratios,
      'irrational_radius_t':mp.nstr(radius,30),'irrational_radius_y':mp.nstr(radius_y,30),
      'log_coefficients':{str(e):str(q) for e,q in ordered(A)},
      'mixed_coefficients':{str(e):str(q) for e,q in ordered(stored['mixed irrational logarithmic'])}
    }
    path=Path(__file__).with_name('validation-results.json')
    path.write_text(json.dumps(result,indent=2)+'\n')
    print(f'{result["passed"]}/{result["total"]} independent checks passed.')
    print(f'Results: {path}')
    print('Power-log coefficients:',result['log_coefficients'])
    print('Convergence radius in t:',result['irrational_radius_t'])
    print('Convergence radius in y:',result['irrational_radius_y'])

if __name__=='__main__': main()
