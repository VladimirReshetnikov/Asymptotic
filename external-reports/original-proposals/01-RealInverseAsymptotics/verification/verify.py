#!/usr/bin/env python3
"""Independent exact and numerical checks of the article's formulas.

This is a SymPy/mpmath reference implementation, NOT a Wolfram Language
interpreter. Passing these checks does not certify the .wl implementation.
No network access is used. Run: python verification/verify.py --output verification
"""
from __future__ import annotations
import argparse
import json
import math
import pathlib
import platform
from dataclasses import dataclass
from itertools import product
import sympy as s
import mpmath as mp

L = s.Symbol('L', real=True)
y = s.Symbol('y', positive=True)


def canon(e):
    return s.simplify(e)


def lt(a, b):
    q = s.simplify(a-b)
    if q.is_negative is not None:
        return bool(q.is_negative)
    raise ValueError(f'Exact sign unresolved: {q}')


def merge(terms):
    ans = {}
    for e, c in terms:
        e = canon(e)
        ans[e] = s.expand(ans.get(e, 0) + c)
    ans = {e: s.expand(s.simplify(c)) for e, c in ans.items()}
    return {e: c for e, c in ans.items() if c != 0}


def trim(jet, bound):
    return {e:c for e,c in jet.items() if lt(e,bound)}


def mul(u, v, bound):
    return merge((canon(e+f), a*b) for e,a in u.items() for f,b in v.items()
                 if lt(e+f,bound))


def scale(u, a):
    return merge((e,a*c) for e,c in u.items())


def add(*jets):
    return merge(pair for jet in jets for pair in jet.items())


def jpower(u, n, bound):
    ans = {s.Integer(0):s.Integer(1)}
    for _ in range(n):
        ans = mul(ans,u,bound)
    return ans


def unit(u, r, bound, log=False):
    ans = {} if log else {s.Integer(0):s.Integer(1)}
    power = {s.Integer(0):s.Integer(1)}
    for n in range(1,1000):
        power = mul(power,u,bound)
        if not power:
            return ans
        coef = s.Rational((-1)**(n+1),n) if log else s.binomial(r,n)
        ans = add(ans,scale(power,coef))
    raise RuntimeError('jet iteration limit')


@dataclass(frozen=True)
class Model:
    p: s.Expr
    a: s.Expr
    deltas: tuple
    polynomials: tuple


def region(deltas, bound):
    inside = []
    def visit(j, left, prefix):
        if j == len(deltas):
            inside.append(tuple(prefix)); return
        k = 0
        while lt(k*deltas[j],left):
            visit(j+1,canon(left-k*deltas[j]),prefix+[k]); k += 1
            if k>1000:
                raise RuntimeError('index limit')
    visit(0,bound,[])
    frontier=set()
    for n in inside:
        for j in range(len(deltas)):
            v=list(n); v[j]+=1; v=tuple(v)
            if not lt(sum(k*d for k,d in zip(v,deltas)),bound):
                frontier.add(v)
    return inside,frontier


def inverse(model, cutoff):
    p=s.sympify(model.p); d=model.deltas; b=model.polynomials
    h=canon(p*cutoff-1)
    ns,frontier=region(d,h)
    terms=[]
    for n in ns:
        N=sum(n); A=canon(sum(k*di for k,di in zip(n,d)))
        if N==0:
            terms.append((s.Integer(0),s.Integer(1))); continue
        q=s.prod(bi**ni for bi,ni in zip(b,n))
        for j in range(1,N):
            q=s.expand(s.diff(q,L)+(1+A+p*j)*q)
        q=s.expand((-1)**N*q/(p**N*math.prod(math.factorial(k) for k in n)))
        terms.append((A,q))
    return merge(terms),h,ns,frontier


def residual(model, terms, bound):
    u=trim({e:c for e,c in terms.items() if e!=0},bound)
    logu=unit(u,0,bound,log=True)
    ans=add(unit(u,model.p,bound),{s.Integer(0):s.Integer(-1)})
    for d,b in zip(model.deltas,model.polynomials):
        if not lt(d,bound):
            continue
        pol={}
        for k in range(s.degree(b,L)+1):
            pol=add(pol,scale(jpower(logu,k,bound),s.diff(b,L,k)/s.factorial(k)))
        part=mul(unit(u,model.p+d,bound),pol,bound)
        ans=trim(add(ans,{canon(e+d):c for e,c in part.items()}),bound)
    return ans


def expression(model,terms):
    p=s.sympify(model.p); a=s.sympify(model.a)
    return s.Add(*[(y/a)**canon((1+e)/p)*c.subs(L,s.log(y/a)/p)
                   for e,c in terms.items()])


def homotopy_inverse(h, order):
    return y+s.Add(*[(-1)**n*s.diff(h**n,y,n-1)/s.factorial(n)
                     for n in range(1,order+1)])


def check_wl_delimiters(path):
    """Static lexical check only: strings, nested WL comments, (), [], {}."""
    text=path.read_text(); i=0; stack=[]; depth=0; string=False
    pairs={')':'(',']':'[','}':'{'}
    while i<len(text):
        if depth:
            if text[i:i+2]=='(*': depth+=1; i+=2; continue
            if text[i:i+2]=='*)': depth-=1; i+=2; continue
            i+=1; continue
        if string:
            if text[i]=='\\': i+=2; continue
            if text[i]=='"': string=False
            i+=1; continue
        if text[i:i+2]=='(*': depth=1; i+=2; continue
        c=text[i]
        if c=='"': string=True
        elif c in '([{': stack.append((c,i))
        elif c in ')]}':
            if not stack or stack[-1][0]!=pairs[c]:
                raise AssertionError(f'{path}: mismatched {c} at {i}')
            stack.pop()
        i+=1
    assert not stack and not depth and not string


def bisect_positive(f,target,seed):
    a,b=seed/2,seed*2
    assert f(a)<target<f(b)
    for _ in range(600):
        c=(a+b)/2
        if f(c)<target: a=c
        else: b=c
    return (a+b)/2


def run(out):
    out.mkdir(parents=True,exist_ok=True)
    tests=[]
    def passed(name,detail=''):
        tests.append({'name':name,'status':'passed','detail':detail})
    base=Model(s.Integer(1),s.Integer(1),(s.Integer(1),),(1+L,))
    t,h,_,_=inverse(base,s.Integer(8))
    assert residual(base,t,h)=={}
    passed('logarithmic example: exact residual through y^7')
    expected=homotopy_inverse(y**2*(1+s.log(y)),6)
    assert s.simplify(expression(base,t)-expected)==0
    passed('logarithmic example: differential Lagrange cross-check, six corrections')
    polys={str(1+e):str(c) for e,c in t.items()}
    for n in range(1,7):
        assert s.Poly(t[s.Integer(n)],L).LC()==(-1)**n*s.catalan(n)
    passed('six highest-log coefficients equal signed Catalan numbers')
    alpha=s.sqrt(2)
    irr=Model(s.Integer(1),s.Integer(1),(alpha-1,),(s.Integer(1),))
    ti,hi,_,_=inverse(irr,canon(1+5*(alpha-1)))
    assert residual(irr,ti,hi)=={}
    for n in range(1,5):
        coef=(-1)**n*s.prod(n*alpha-j for j in range(n-1))/s.factorial(n)
        assert s.simplify(ti[canon(n*(alpha-1))]-coef)==0
    passed('irrational example: exact residual and all four coefficient products')
    assert s.simplify(ti[canon(3*(alpha-1))]+(6-alpha)/2)==0
    passed('irrational example: coefficient printed in the question')
    cases=[
        ('resonance', Model(s.Integer(1),s.Integer(1),(s.Integer(1),s.Integer(2)),(s.Integer(1),s.Integer(1))),s.Integer(7)),
        ('nonunit leading power',Model(s.Integer(2),s.Integer(3),(s.Integer(1),),(1+L,)),s.Rational(5,2)),
        ('fractional leading power',Model(s.Rational(1,2),s.Integer(2),(s.Rational(1,2),),(L**2-2,)),s.Integer(6)),
        ('mixed irrational gaps',Model(s.Integer(1),s.Integer(1),(s.sqrt(2)-1,s.sqrt(3)-1),(1+L,s.Integer(2))),s.Integer(3)),
        ('two logarithmic blocks',Model(s.Integer(1),s.Integer(1),(s.Integer(1),s.Integer(2)),(L**2+1,2-L)),s.Integer(5)),
    ]
    for name,m,c in cases:
        tr,hr,ns,front=inverse(m,c)
        assert residual(m,tr,hr)=={},name
        passed(name+': independent sparse composition',f'{len(ns)} multi-indices; {len(tr)} surviving blocks')
        if name=='resonance':
            assert tr.get(s.Integer(3),0)==0
            assert tr[s.Integer(2)]==1
            passed('resonance combines and cancels equal exponents')
    # A separately derived closed form for x+x^2 (ordinary analytic reversion).
    poly=Model(s.Integer(1),s.Integer(1),(s.Integer(1),),(s.Integer(1),))
    tp,_,_,_=inverse(poly,s.Integer(9))
    exact=(s.sqrt(1+4*y)-1)/2
    assert s.expand(expression(poly,tp)-s.series(exact,y,0,9).removeO())==0
    passed('ordinary analytic inverse agrees with square-root Taylor expansion')
    # Pure leading monomial, including a symbolic positive coefficient.
    mono=Model(s.Rational(3,2),s.Integer(5),(),())
    tm,hm,_,_=inverse(mono,s.Integer(3))
    assert tm=={s.Integer(0):s.Integer(1)} and residual(mono,tm,hm)=={}
    passed('pure monomial is inverted exactly')
    # Explicit nonzero first omitted residual: truncating after y^2 leaves a
    # y^3 residual -(2 L^2+5 L+3), not O(y^3) after division by y^3.
    t2,h2,_,_=inverse(base,s.Integer(3))
    r2=residual(base,t2,s.Integer(3))
    assert s.expand(r2[s.Integer(2)]+2*L**2+5*L+3)==0
    passed('logarithmic big-O correction checked by first omitted residual')
    # General leading-power first-order coefficient: -B/p in z-coordinate.
    for p in [s.Rational(1,3),s.Integer(2),s.sqrt(2)]:
        m=Model(p,s.Integer(1),(s.Integer(1),),(L+2,))
        tr,_,_,_=inverse(m,canon(s.Rational(5,2)/p))
        assert s.simplify(tr[s.Integer(1)]+(L+2)/p)==0
    passed('general leading-power first displacement')
    root=pathlib.Path(__file__).resolve().parents[1]
    for path in sorted(p for p in root.rglob('*') if p.suffix in {'.wl', '.wlt', '.wls', '.m'}):
        check_wl_delimiters(path)
    passed('Wolfram sources: lexical delimiter check (not execution)')
    mp.mp.dps=150
    numeric=[]
    f=lambda x:x+x*x*(1+mp.log(x))
    for power in [2,4,8]:
        target=mp.mpf(10)**(-power)
        sol=bisect_positive(f,target,target)
        for max_power in [2,3,5,7]:
            tr,_,_,_=inverse(base,s.Integer(max_power+1))
            fn=s.lambdify(y,expression(base,tr),'mpmath')
            approx=fn(target)
            err=abs(approx-sol)
            remscale=target**(max_power+1)*(1+abs(mp.log(target)))**max_power
            resid=abs(f(approx)-target)
            lower=1-2*mp.exp(-mp.mpf(5)/2)
            assert err <= resid/lower*(1+mp.mpf('1e-50'))
            numeric.append({'model':'logarithmic','y':f'1e-{power}',
                'highest_power':max_power,'absolute_error':mp.nstr(err,14),
                'error_over_remainder_scale':mp.nstr(err/remscale,12),
                'residual':mp.nstr(resid,14)})
    fi=lambda x:x+x**mp.sqrt(2)
    for power in [2,4,8]:
        target=mp.mpf(10)**(-power)
        sol=bisect_positive(fi,target,target)
        for corrections in [1,2,3,4]:
            bound=canon(1+(corrections+1)*(s.sqrt(2)-1))
            tr,_,_,_=inverse(irr,bound)
            approx=s.lambdify(y,expression(irr,tr),'mpmath')(target)
            err=abs(approx-sol)
            numeric.append({'model':'irrational','y':f'1e-{power}',
                'corrections':corrections,'absolute_error':mp.nstr(err,14),
                'error_over_remainder_scale':mp.nstr(err/target**(1+(corrections+1)*(mp.sqrt(2)-1)),12)})
    passed('24 high-precision positive-branch numerical comparisons')
    passed('12 numerical checks of the proved global residual error bound')
    result={'status':'all independent checks passed','python':platform.python_version(),
            'sympy':s.__version__,'mpmath':mp.__version__,
            'wolfram_kernel_execution':'NOT RUN: connected Wolfram MCP endpoint returned HTTP 404; no local kernel was available.',
            'precision_decimal_digits':mp.mp.dps,'checks':tests,
            'logarithmic_coefficients':polys,'numerical_results':numeric}
    (out/'verification_results.json').write_text(json.dumps(result,indent=2)+'\n')
    (out/'coefficients.tex').write_text('\n'.join(
        rf'P_{{{n}}}(L)&={s.latex(t[s.Integer(n)])}\\' for n in range(1,7))+'\n')
    print(json.dumps({'checks':len(tests),'status':result['status'],'numerical_rows':len(numeric)},indent=2))
    print('Logarithmic coefficients:',polys)


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',type=pathlib.Path,default=pathlib.Path(__file__).resolve().parent)
    args=parser.parse_args()
    run(args.output)
