#!/usr/bin/env python3
"""Independent exact/numerical validation of the mathematics, not WL execution.
Requires Python 3.10+, SymPy and mpmath. Writes validation_report.json,
numerics.csv and example_coefficients.tex next to this script.
"""
from __future__ import annotations
import csv
import json
from pathlib import Path
from functools import cmp_to_key
from typing import Dict
import sympy as s
import mpmath as mp

L = s.Symbol('L', real=True)
y = s.Symbol('y', positive=True)
Sparse = Dict[s.Expr, s.Expr]
checks = []


def sign(x):
    q = s.simplify(x)
    if q == 0: return 0
    if q.is_positive is True: return 1
    if q.is_negative is True: return -1
    raise ValueError(f'Unresolved exact order: {q}')


def ordered(values):
    return sorted(values, key=cmp_to_key(lambda a,b: sign(a-b)))


def clean(a: Sparse) -> Sparse:
    r = {}
    for e,c in a.items():
        e, c = s.simplify(e), s.expand(c)
        r[e] = s.expand(r.get(e,0)+c)
    return {e:s.expand(s.simplify(c)) for e,c in r.items() if s.simplify(c)!=0}


def add(a: Sparse, b: Sparse) -> Sparse:
    r = a.copy()
    for e,c in b.items(): r[e]=r.get(e,0)+c
    return clean(r)


def mul(a: Sparse,b: Sparse,cut=None) -> Sparse:
    r={}
    for e,c in a.items():
        for f,d in b.items():
            q=s.simplify(e+f)
            if cut is None or sign(q-cut)<0: r[q]=r.get(q,0)+c*d
    return clean(r)


def scale(a:Sparse,c) -> Sparse:
    return clean({e:c*p for e,p in a.items()})


def shift(a:Sparse,e,c=1) -> Sparse:
    return clean({s.simplify(q+e):c*p for q,p in a.items()})


def euler(q,mu,alpha,n):
    for j in range(1,n): q=s.expand((mu+1+j*alpha)*q+s.diff(q,L))
    return s.simplify((-1)**n*q/(s.factorial(n)*alpha**n)).expand()


def inverse(alpha,a,u:Sparse,cut):
    """The inversion formula under test, with first-omitted frontier."""
    alpha,a,cut=map(s.sympify,(alpha,a,cut))
    cap=s.simplify(alpha*cut-1)
    if sign(cap)<=0: return {},1/alpha,a**(-1/alpha)
    if not u: return {1/alpha:a**(-1/alpha)},s.oo,s.S.Zero
    delta=ordered(u)[0]
    nmax=int(s.ceiling(cap/delta))
    power={s.S.Zero:s.S.One}; acc={s.S.Zero:s.S.One}
    front=None; boundary=s.S.Zero
    for n in range(1,nmax+1):
        raw=mul(power,u); kept={}
        for mu,q in raw.items():
            p=euler(q,mu,alpha,n)
            if sign(mu-cap)<0:
                kept[mu]=q; acc=add(acc,{mu:p})
            elif front is None or sign(mu-front)<0:
                front,boundary=mu,p
            elif sign(mu-front)==0: boundary=s.expand(boundary+p)
        power=kept
        if not power: break
    out={}
    for mu,q in acc.items():
        e=s.simplify((1+mu)/alpha)
        out[e]=s.expand(a**(-e)*q.subs(L,(L-s.log(a))/alpha))
    rho=s.simplify((1+front)/alpha)
    boundary=s.expand(a**(-rho)*boundary.subs(L,(L-s.log(a))/alpha))
    return clean(out),rho,boundary


def unit(v:Sparse,q,cut,islog=False):
    out={} if islog else {s.S.Zero:s.S.One}
    if not v: return out
    nmax=int(s.ceiling(cut/ordered(v)[0]))
    power={s.S.Zero:s.S.One}
    for n in range(1,nmax):
        power=mul(power,v,cut)
        if not power: break
        c=s.Rational((-1)**(n+1),n) if islog else s.binomial(q,n)
        out=add(out,scale(power,c))
    return out


def compose(f:Sparse,g:Sparse,cut):
    """Independent binomial/log composition; no Euler inversion formula."""
    beta=ordered(g)[0]; a=g[beta]
    assert not a.has(L)
    v=shift({e:p for e,p in g.items() if e!=beta},-beta,1/a)
    out={}; b=s.log(a)+beta*L
    for q,p in f.items():
        cap=s.simplify(cut-beta*q)
        if sign(cap)<=0: continue
        pq=unit(v,q,cap); lv=unit(v,0,cap,True)
        lp={s.S.Zero:s.S.One}; polylog={}
        for k in range(int(s.degree(p,L))+1):
            coefficient=s.diff(p,L,k).subs(L,b)/s.factorial(k)
            polylog=add(polylog,scale(lp,coefficient))
            lp=mul(lp,lv,cap)
        out=add(out,shift(mul(pq,polylog,cap),beta*q,a**q))
    return clean(out)


def check(name,condition,detail=''):
    if not bool(condition): raise AssertionError(name+': '+detail)
    checks.append({'name':name,'passed':True,'detail':detail})


def expression(g):
    return sum(y**e*p.subs(L,s.log(y)) for e,p in g.items())


def main():
    outdir=Path(__file__).resolve().parent
    p=s.sqrt(2); d=p-1
    g1,r1,b1=inverse(1,1,{s.S.One:1+L},7)
    expected={1:1,2:-1-L,3:3+5*L+2*L**2,
              4:-s.Rational(23,2)-27*L-s.Rational(41,2)*L**2-5*L**3}
    for e,c in expected.items(): check(f'log coefficient y^{e}',s.expand(g1[s.Integer(e)]-c)==0)
    check('log first omitted power',r1==7)
    check('log first omitted degree',s.degree(b1,L)==6)
    check('log residual through strict power 7',compose({s.S.One:1,s.Integer(2):1+L},g1,7)=={s.S.One:s.S.One})
    g2,r2,b2=inverse(1,1,{d:s.S.One},1+9*d)
    for n in range(10):
        q=s.simplify(1+n*d)
        target=s.S.One if n==0 else s.expand((-1)**n*s.prod(n*p-j for j in range(n-1))/s.factorial(n))
        actual=g2.get(q,b2 if n==9 else None)
        check(f'irrational Fuss-Catalan coefficient n={n}',s.simplify(actual-target)==0)
    # Fewer terms keep the independent radical composition test economical.
    small,rr,bb=inverse(1,1,{d:s.S.One},1+4*d)
    check('irrational residual',compose({s.S.One:1,p:1},small,rr)=={s.S.One:s.S.One})
    cases=[
      ('rational leading power',s.Rational(3,2),1,{s.Rational(1,2):1+L},s.Rational(7,3)),
      ('nonunit scale',2,4,{s.S.One:1+L},s.Rational(5,2)),
      ('collision',1,1,{s.S.One:1,s.Integer(2):s.Integer(2)},5),
      ('mixed logarithms',1,1,{s.S.One:L,s.Integer(2):1+L**2},5),
      ('negative perturbation',1,1,{s.S.One:-1-L},5),
      ('noninteger leading exponent',s.sqrt(2),1,{s.S.One:1+L},s.Rational(5,2)),
      ('two irrational generators',1,1,{s.sqrt(2)-1:1,s.sqrt(3)-1:1},s.Rational(5,2)),
      ('irrational and logarithmic',1,1,{s.sqrt(2)-1:1,s.S.One:1+L},s.Rational(5,2)),
      ('negative log coefficient',s.Rational(1,2),1,{s.Rational(1,2):L**2-2*L+3},6),
    ]
    case_data=[]
    for name,alpha,a,u,cut in cases:
        alpha,a,cut=map(s.sympify,(alpha,a,cut))
        g,r,b=inverse(alpha,a,u,cut)
        f={alpha:a}; f.update({alpha+delta:a*c for delta,c in u.items()})
        rc=s.simplify(r+1-1/alpha)
        residual=compose(f,g,rc)
        check(name+' residual',residual=={s.S.One:s.S.One},str(residual)); print('PASS: '+name,flush=True)
        case_data.append({'name':name,'terms':len(g),'remainder_power':str(r),'boundary_polynomial':str(b)})
    _,rcancel,bcancel=inverse(1,1,{s.S.One:1,s.Integer(2):s.Integer(2)},3)
    check('cancelling boundary kept conservative',rcancel==3 and bcancel==0)
    for alpha,a in [(s.Rational(3,2),s.Integer(8)),(s.sqrt(2),s.Integer(3))]:
        pure,r,b=inverse(alpha,a,{},4)
        check('pure monomial '+str(alpha),pure=={1/alpha:a**(-1/alpha)} and r is s.oo)
    empty,r,b=inverse(1,1,{s.S.One:1+L},s.Rational(1,2))
    check('cutoff below leading term',empty=={} and r==1 and b==1)
    # Independent coefficient-by-coefficient solve, not composition only.
    z=s.Symbol('z'); c1,c2,c3=s.symbols('c1:4')
    ss=1+c1*z+c2*z**2+c3*z**3
    residual=s.series(ss+z*ss**2*(1+L+s.log(ss))-1,z,0,4).removeO().expand()
    sol={}
    for n,c in enumerate([c1,c2,c3],1):
        sol[c]=s.solve(residual.coeff(z,n).subs(sol),c)[0]
        check(f'independent triangular solve n={n}',s.simplify(sol[c]-g1[s.Integer(n+1)])==0)
    mp.mp.dps=100
    numerical=[]
    def invert_bisect(fun,target):
        lo=mp.mpf(0); hi=2*target
        while fun(hi)<target: hi*=2
        for _ in range(420):
            mid=(lo+hi)/2
            if fun(mid)<target: lo=mid
            else: hi=mid
        return (lo+hi)/2
    # Generic lambdify avoids evaluation of a bare Real approximation to exponents.
    for case in ['log','irrational']:
        f=(lambda x:x+x*x*(1+mp.log(x))) if case=='log' else (lambda x:x+x**mp.sqrt(2))
        for exponent in [3,6,12]:
            value=mp.mpf(10)**(-exponent)
            root=invert_bisect(f,value)
            for n in [1,2,3,5]:
                u={s.S.One:1+L} if case=='log' else {d:s.S.One}
                cut=s.Integer(n+2) if case=='log' else 1+(n+1)*d
                g,r,b=inverse(1,1,u,cut)
                approx=s.lambdify(y,expression(g),'mpmath')(value)
                error=abs(root-approx)
                boundary=s.lambdify(y,y**r*b.subs(L,s.log(y)),'mpmath')(value)
                ratio=error/abs(boundary)
                check(f'numerical {case} y=1e-{exponent} n={n}',error < abs(root) and mp.mpf('0.8') < ratio < mp.mpf('1.1'))
                numerical.append({'example':case,'y':f'1e-{exponent}','correction_orders':n,
                   'absolute_error':mp.nstr(error,12),'error_over_first_omitted':mp.nstr(ratio,12)})
    with (outdir/'numerics.csv').open('w',newline='') as fp:
        writer=csv.DictWriter(fp,fieldnames=numerical[0].keys()); writer.writeheader(); writer.writerows(numerical)
    data={'scope':'Independent SymPy algebra and mpmath numerics; the Wolfram package was NOT executed.',
          'sympy_version':s.__version__,'mpmath_version':mp.__version__,
          'passed':len(checks),'failed':0,'checks':checks,'additional_cases':case_data}
    (outdir/'validation_report.json').write_text(json.dumps(data,indent=2)+'\n')
    tex=[]
    for n in range(1,7):
        polynomial=g1.get(s.Integer(n+1),b1)
        tex.append(r'P_{'+str(n)+r'}(L) &= '+s.latex(polynomial)+r' \\')
    (outdir/'example_coefficients.tex').write_text('\n'.join(tex)+'\n')
    print(json.dumps({'passed':len(checks),'failed':0,'additional_cases':case_data},indent=2))
    print('FIRST LOG COEFFICIENTS:')
    for n in range(1,6): print(n,s.factor(g1[s.Integer(n+1)]))

if __name__=='__main__': main()
