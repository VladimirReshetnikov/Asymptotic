#!/usr/bin/env python3
"""Independent executable verification. Requires sympy and mpmath.
This validates the mathematics and expected outputs, NOT the Wolfram runtime.
Run from any directory: python validation/reference_validation.py
"""
from __future__ import annotations
import json
import math
from pathlib import Path
from functools import lru_cache
import sympy as S
import mpmath as mp

L = S.Symbol('L', real=True)
OUT = Path(__file__).resolve().parent

@lru_cache(maxsize=None)
def canon(a):
    return S.simplify(a)

@lru_cache(maxsize=None)
def leq(a,b):
    z = canon(b-a)
    if z.is_nonnegative is not None:
        return bool(z.is_nonnegative)
    return bool(z >= 0)   # exact algebraic comparison; never float-sort

def clean(p):
    return S.Poly(S.expand(p),L).as_expr()

def merge(terms):
    out = {}
    for w,p in terms:
        w=canon(w)
        out[w] = out.get(w,0) + p
    return {w:clean(p) for w,p in out.items() if clean(p)!=0}

def add(a,b):
    return merge(list(a.items())+list(b.items()))

def mul(a,b,cut):
    return merge((canon(u+v),p*q) for u,p in a.items() for v,q in b.items()
                 if leq(canon(u+v),cut))

def scale(a,c):
    return merge((w,c*p) for w,p in a.items())

def shift(a,s):
    return merge((canon(w+s),p) for w,p in a.items())

def power(u,r,cut):
    ans={S.Integer(0):S.Integer(1)}; term=ans; coeff=S.Integer(1); j=1
    while True:
        term=mul(term,u,cut)
        if not term: break
        coeff=canon(coeff*(r-j+1)/j)
        if coeff==0: break
        ans=add(ans,scale(term,coeff));j+=1
    return ans

def logarithm(u,cut):
    ans={}; term={S.Integer(0):S.Integer(1)}; j=1
    while True:
        term=mul(term,u,cut)
        if not term: break
        ans=add(ans,scale(term,S.Rational((-1)**(j+1),j)));j+=1
    return ans

def substitute_poly(p,v,cut):
    ans={}
    for c in S.Poly(p,L).all_coeffs():
        ans=add(mul(ans,v,cut),{S.Integer(0):c})
    return ans

def simplex(alphas,cut):
    def rec(j,k,w):
        if j==len(alphas):
            yield (tuple(k),w); return
        m=int(S.floor(canon((cut-w)/alphas[j])))
        for z in range(m+1):
            yield from rec(j+1,k+[z],canon(w+z*alphas[j]))
    yield from rec(0,[],S.Integer(0))

def reversion(blocks,cut):
    alphas=[S.sympify(w) for w,_ in blocks]
    ps=[S.sympify(p) for _,p in blocks]
    result=[]
    for k,w in simplex(alphas,S.sympify(cut)):
        n=sum(k)
        if not n: continue
        q=S.prod(p**i for p,i in zip(ps,k))
        for j in range(n-1):
            q=clean((2+w+j)*q+S.diff(q,L))
        result.append((w,(-1)**n*q/S.prod(S.factorial(i) for i in k)))
    return merge(result)

def residual(blocks,u,cut):
    logu=logarithm(u,cut)
    v=add({S.Integer(0):L},logu)
    ans=dict(u)
    for alpha,p in blocks:
        alpha=S.sympify(alpha)
        if not leq(alpha,cut):continue
        rem=canon(cut-alpha)
        correction=mul(power(u,1+alpha,rem),substitute_poly(p,v,rem),rem)
        ans=add(ans,shift(correction,alpha))
    return merge((w,p) for w,p in ans.items() if leq(w,cut))

def fixed_point(blocks,cut,steps):
    # u_{r+1}= - sum t^alpha (1+u_r)^(1+alpha) P(L+log(1+u_r)).
    # This is a third calculation path, with no differentiation formula.
    u={}
    for _ in range(steps):
        rhs=residual(blocks,u,cut)
        u=add(u,scale(rhs,-1))
    return u

def sorted_items(s):
    from functools import cmp_to_key
    return sorted(s.items(),key=cmp_to_key(lambda a,b: -1 if leq(a[0],b[0]) else 1))

def coefficients():
    out={}
    for n in range(1,9):
        p=(1+L)**n
        for j in range(n-1):p=clean((2+n+j)*p+S.diff(p,L))
        p=clean((-1)**n*p/S.factorial(n))
        assert S.expand(p).coeff(L,n)==(-1)**n*S.catalan(n)
        out[n]=p
    return out

def numerical_checks(polys):
    mp.mp.dps=110
    out=[]
    for yy in ['0.01','0.001','0.000001']:
        y=mp.mpf(yy)
        fun=lambda x:x+x*x*(1+mp.log(x))-y
        x=mp.findroot(fun,(y,y*(1-y*(1+mp.log(y)))))
        ell=mp.log(y)
        for n in [1,2,3,4,6]:
            approx=y+sum(y**(k+1)*S.lambdify(L,polys[k],'mpmath')(ell)
                         for k in range(1,n+1))
            error=abs(approx-x)
            f_res=abs(fun(approx))
            assert error <= f_res/(1-2*mp.exp(mp.mpf('-2.5')))*mp.mpf('1.00000000000000001')
            nextval=abs(y**(n+2)*S.lambdify(L,polys[n+1],'mpmath')(ell))
            out.append({'example':'logarithmic','y':yy,'N':n,
                        'absolute_error':mp.nstr(error,12),
                        'error_over_next_term':mp.nstr(error/nextval,12)})
    p=mp.sqrt(2);a=p-1
    rho=a**a/p**p
    for yy in ['0.01','0.001','0.000001']:
        y=mp.mpf(yy);x=mp.findroot(lambda x:x+x**p-y,(y/2,y))
        for n in [1,3,6,10]:
            approx=mp.mpf(0)
            for k in range(n+1):
                c=(-1)**k*mp.gamma(p*k+1)/(mp.gamma(k+1)*mp.gamma(a*k+2))
                approx+=c*y**(1+a*k)
            err=abs(approx-x)
            k=n+1
            nxt=abs(mp.gamma(p*k+1)/(mp.gamma(k+1)*mp.gamma(a*k+2))*y**(1+a*k))
            out.append({'example':'irrational power','y':yy,'N':n,
                        'absolute_error':mp.nstr(err,12),
                        'error_over_next_term':mp.nstr(err/nxt,12)})
    return out,{'rho':mp.nstr(rho,25),'positive_y_convergence_threshold':mp.nstr(rho**(1/a),25)}

def main():
    tests=[]
    cases=[('logarithmic',[(S.Integer(1),1+L)],S.Integer(6)),
           ('irrational',[(S.sqrt(2)-1,S.Integer(1))],3*(S.sqrt(2)-1)),
           ('resonant',[(S.Rational(1,2),1+L),(S.Integer(1),2-L)],S.Integer(3)),
           ('mixed irrational',[(S.sqrt(2)-1,1+L),(S.Integer(1),2-L)],S.Integer(2)),
           ('scaled coefficients',[(S.Rational(1,2),S.Rational(3,2)*(1+L)),
                                   (S.Integer(1),-L**2/S.Integer(2))],S.Integer(2)),
           ('zero coefficients',[(S.Rational(1,2),0),(S.Integer(1),1)],S.Integer(3)),
           ('noninteger cutoff',[(S.Rational(1,2),1+L)],S.Rational(7,4))]
    for name,blocks,cut in cases:
        u=reversion(blocks,cut)
        rr=residual(blocks,u,cut)
        assert rr=={},(name,rr)
        tests.append({'name':name+' direct-composition','passed':True,'terms':len(u)})
        if name not in ('mixed irrational','irrational'):
            delta=min(w for w,p in blocks)
            steps=int(S.floor(cut/delta))+1
            ff=fixed_point(blocks,cut,steps)
            assert merge(list(u.items())+[(w,-p)for w,p in ff.items()])=={}
            tests.append({'name':name+' fixed-point cross-check','passed':True})
    polys=coefficients()
    expected=[-(L+1),2*L**2+5*L+3,
              -5*L**3-S.Rational(41,2)*L**2-27*L-S.Rational(23,2)]
    for i,p in enumerate(expected,1):
        assert clean(polys[i]-p)==0
        tests.append({'name':f'printed logarithmic polynomial {i}','passed':True})
    tests.append({'name':'Catalan leading coefficients n=1..8','passed':True})
    # Ordinary analytic calibration: inverse x+x^2 has Catalan coefficients.
    plain=reversion([(S.Integer(1),S.Integer(1))],S.Integer(8))
    for n in range(1,9):assert plain[S.Integer(n)]==(-1)**n*S.catalan(n)
    tests.append({'name':'ordinary quadratic inverse n=1..8','passed':True})
    # Gamma formula agrees with finite polynomial formula symbolically.
    p=S.Symbol('p',positive=True)
    for n in range(1,7):
        general=(-1)**n*S.prod(n*p-j for j in range(n-1))/S.factorial(n)
        c=reversion([(S.sqrt(2)-1,S.Integer(1))],canon(n*(S.sqrt(2)-1)))
        assert S.simplify(c[canon(n*(S.sqrt(2)-1))]-general.subs(p,S.sqrt(2)))==0
    tests.append({'name':'pure-power finite coefficient formula n=1..6','passed':True})
    # Deliberately corrupt a coefficient: checker must detect it.
    bad=reversion([(S.Integer(1),1+L)],S.Integer(3));bad[S.Integer(2)]+=1
    assert residual([(S.Integer(1),1+L)],bad,S.Integer(3))!={}
    tests.append({'name':'residual checker rejects corrupted coefficient','passed':True})
    numerical,threshold=numerical_checks(polys)
    results={'status':'PASS','scope':'Independent Python mathematics tests; not native Wolfram execution',
             'sympy_version':S.__version__,'mpmath_version':mp.__version__,
             'symbolic_checks':tests,'numerical_checks':numerical,'pure_power_radius':threshold,
             'logarithmic_polynomials':{str(n):str(p) for n,p in polys.items()}}
    (OUT/'results.json').write_text(json.dumps(results,indent=2)+'\n')
    print(json.dumps({'status':'PASS','symbolic_checks':len(tests),
                      'numerical_cases':len(numerical),'radius':threshold},indent=2))
    for n,p in list(polys.items())[:5]:print(n,p)
    return results

if __name__=='__main__':main()
