#!/usr/bin/env python3
"""Independent exact-arithmetic checks for the accompanying mathematics.

This is NOT a Wolfram Language interpreter and does not execute the .wl file.
It compares the differential-operator formula with truncated composition,
checks low-order closed forms, and measures errors against high-precision
bisection. Requires Python >=3.9, SymPy, and mpmath. No network access.
"""
from __future__ import annotations
import argparse
from dataclasses import dataclass
from functools import cmp_to_key, lru_cache
from pathlib import Path
import json
import random
import time
from typing import Dict, List, Sequence, Tuple
import mpmath as mp
import sympy as sp

L = sp.Symbol('L', real=True)
Jet = Dict[sp.Expr, sp.Expr]

@lru_cache(maxsize=None)
def canon(x: sp.Expr) -> sp.Expr:
    return sp.expand(x)

@lru_cache(maxsize=None)
def cmp(a: sp.Expr, b: sp.Expr) -> int:
    d = canon(a-b)
    if d == 0 or d.is_zero is True:
        return 0
    if d.is_positive is True:
        return 1
    if d.is_negative is True:
        return -1
    d = sp.simplify(d)
    if d == 0:
        return 0
    if d.is_positive is True:
        return 1
    if d.is_negative is True:
        return -1
    raise ValueError(f'Undecidable exact exponent comparison: {a} versus {b}')


def clean(j: Jet) -> Jet:
    out: Jet = {}
    for e, p in j.items():
        e = canon(sp.sympify(e)); p = sp.expand(p)
        out[e] = sp.expand(out.get(e, sp.S.Zero)+p)
    return {e:p for e,p in out.items() if p != 0}


def add(*jets: Jet) -> Jet:
    out: Jet = {}
    for j in jets:
        for e,p in j.items():
            out[e] = out.get(e, sp.S.Zero)+p
    return clean(out)


def scale(j: Jet, c: sp.Expr) -> Jet:
    return clean({e:c*p for e,p in j.items()})


def mul(a: Jet, b: Jet, bound: sp.Expr) -> Jet:
    out: Jet = {}
    for e,p in a.items():
        for f,q in b.items():
            w = canon(e+f)
            if cmp(w,bound) <= 0:
                out[w] = out.get(w,sp.S.Zero)+p*q
    return clean(out)


def shift(j: Jet, d: sp.Expr, bound: sp.Expr) -> Jet:
    return clean({canon(e+d):p for e,p in j.items() if cmp(e+d,bound)<=0})


def minimum(j: Jet) -> sp.Expr:
    return min(j, key=cmp_to_key(cmp))


def one_plus_power(u: Jet, r: sp.Expr, bound: sp.Expr) -> Jet:
    if not u or r == 0:
        return {sp.S.Zero:sp.S.One}
    d = minimum(u)
    if cmp(d,sp.S.Zero)<=0:
        raise ValueError('positive-order jet required')
    nmax = int(sp.floor(bound/d))
    term: Jet = {sp.S.Zero:sp.S.One}
    out: Jet = dict(term)
    c = sp.S.One
    for n in range(1,nmax+1):
        term = mul(term,u,bound)
        if not term: break
        c = sp.expand(c*(r-n+1)/n)
        if c == 0: break
        out = add(out,scale(term,c))
    return out


def log_one_plus(u: Jet, bound: sp.Expr) -> Jet:
    if not u: return {}
    nmax = int(sp.floor(bound/minimum(u)))
    term: Jet = {sp.S.Zero:sp.S.One}
    out: Jet = {}
    for n in range(1,nmax+1):
        term = mul(term,u,bound)
        if not term: break
        out = add(out,scale(term,sp.Rational((-1)**(n+1),n)))
    return out


def poly_at_jet(p: sp.Expr, logv: Jet, bound: sp.Expr) -> Jet:
    out: Jet = {}
    arg = add({sp.S.Zero:L},logv)
    for c in sp.Poly(p,L).all_coeffs():
        out = add(mul(out,arg,bound),{sp.S.Zero:c})
    return out


@dataclass(frozen=True)
class Model:
    a: sp.Expr
    p: sp.Expr
    corrections: Tuple[Tuple[sp.Expr,sp.Expr],...]


def correction_jet(v: Jet, model: Model, bound: sp.Expr) -> Jet:
    u = add(v,{sp.S.Zero:-sp.S.One})
    lv = log_one_plus(u,bound)
    out: Jet = {}
    for d,p in model.corrections:
        out = add(out,shift(mul(one_plus_power(u,d,bound),
                              poly_at_jet(p,lv,bound),bound),d,bound))
    return out


def fixed_point(model: Model, bound: sp.Expr, q: sp.Expr=sp.S.One) -> Jet:
    if not model.corrections:
        return {sp.S.Zero:sp.S.One}
    d = min((e for e,_ in model.corrections),key=cmp_to_key(cmp))
    nmax = int(sp.floor(bound/d))+1
    v: Jet = {sp.S.Zero:sp.S.One}
    for _ in range(nmax):
        nxt = one_plus_power(correction_jet(v,model,bound),-1/model.p,bound)
        if nxt == v: break
        v = nxt
    return one_plus_power(add(v,{sp.S.Zero:-sp.S.One}),q,bound)


def multi_indices(deltas: Sequence[sp.Expr], bound: sp.Expr):
    def visit(i: int, w: sp.Expr, ks: Tuple[int,...]):
        if i==len(deltas):
            yield w,ks
        else:
            kmax=int(sp.floor((bound-w)/deltas[i]))
            for k in range(kmax+1):
                yield from visit(i+1,canon(w+k*deltas[i]),ks+(k,))
    yield from visit(0,sp.S.Zero,())


def lagrange(model: Model, bound: sp.Expr, q: sp.Expr=sp.S.One) -> Jet:
    out: Jet = {}
    for w,ks in multi_indices([e for e,_ in model.corrections],bound):
        n=sum(ks)
        if n==0:
            out[sp.S.Zero]=sp.S.One
            continue
        p=sp.prod(P**k for (_,P),k in zip(model.corrections,ks))
        p=sp.expand(p)
        for j in range(1,n):
            p=sp.expand((q+w+model.p*j)*p+sp.diff(p,L))
        p=sp.expand((-1)**n*q*p/(model.p**n*sp.prod(sp.factorial(k) for k in ks)))
        out[w]=out.get(w,sp.S.Zero)+p
    return clean(out)


def residual(v: Jet, model: Model, bound: sp.Expr) -> Jet:
    u=add(v,{sp.S.Zero:-sp.S.One})
    return add(mul(one_plus_power(u,model.p,bound),
                   add({sp.S.Zero:sp.S.One},correction_jet(v,model,bound)),bound),
               {sp.S.Zero:-sp.S.One})


def equal_jets(a: Jet,b: Jet) -> bool:
    return all(sp.simplify(a.get(w,0)-b.get(w,0))==0 for w in set(a)|set(b))


def run_exact(quick: bool=False):
    checks: List[dict] = []
    def check(name: str, condition: bool):
        if not condition: raise AssertionError(name)
        checks.append({'name':name,'passed':True})
    log=Model(sp.S.One,sp.S.One,((sp.S.One,1+L),))
    irrational=Model(sp.S.One,sp.S.One,((sp.sqrt(2)-1,sp.S.One),))
    logjet=lagrange(log,sp.Integer(6))
    expected={0:1,1:-1-L,2:(1+L)*(3+2*L),
              3:-(L+1)*(10*L**2+31*L+23)/2,
              4:(L+1)*(84*L**3+398*L**2+607*L+299)/6}
    for n,p in expected.items():
        check(f'log coefficient {n}',sp.expand(logjet[sp.Integer(n)]-p)==0)
    ij=lagrange(irrational,canon(6*(sp.sqrt(2)-1)))
    expected_i=[1,-1,sp.sqrt(2),-3+sp.sqrt(2)/2,
                -4+17*sp.sqrt(2)/3,-sp.Rational(305,12)+51*sp.sqrt(2)/4]
    for n,c in enumerate(expected_i):
        check(f'irrational coefficient {n}',
              sp.simplify(ij[canon(n*(sp.sqrt(2)-1))]-c)==0)
    for n in range(1,9):
        alpha=sp.Symbol('alpha',positive=True)
        product=sp.prod(n*alpha-j for j in range(n-1))
        operator=sp.prod(1+n*(alpha-1)+j for j in range(1,n))
        check(f'pure-power product identity n={n}',sp.expand(product-operator)==0)
    mixed=Model(sp.S.One,sp.S.One,((sp.Rational(1,2),sp.S.One),(sp.S.One,2*L)))
    mj=lagrange(mixed,sp.Rational(3,2))
    check('resonance weight 1',sp.expand(mj[sp.S.One]-(sp.Rational(3,2)-2*L))==0)
    check('resonance weight 3/2',sp.expand(mj[sp.Rational(3,2)]-(7*L-sp.Rational(5,8)))==0)
    nonlinear=Model(sp.Integer(2),sp.Integer(3),((sp.Rational(1,2),1+L),))
    nj=lagrange(nonlinear,sp.S.One)
    check('nonlinear leading first correction',sp.expand(nj[sp.Rational(1,2)]+(1+L)/3)==0)
    check('nonlinear leading second correction',sp.expand(nj[sp.S.One]-(1+L)*(5*L+7)/18)==0)
    catalog=[('log',log,sp.Integer(5)),
             ('irrational',irrational,canon(4*(sp.sqrt(2)-1))),
             ('resonant',mixed,sp.Integer(2)),
             ('nonlinear-leading',nonlinear,sp.Rational(3,2)),
             ('two-irrational',Model(sp.S.One,sp.S.One,
                ((sp.sqrt(2)-1,1+L),(sp.sqrt(3)-1,1-L))),sp.Rational(3,2)),
             ('half-leading',Model(sp.Integer(3),sp.Rational(1,2),
                ((sp.Rational(2,3),1-L+L**2),)),sp.Rational(4,3)),
             ('vanishing-frontier',Model(sp.S.One,sp.S.One,
                ((sp.S.One,sp.S.One),(sp.Integer(2),sp.Integer(2)))),sp.Integer(3))]
    for name,model,bound in catalog:
        lb=lagrange(model,bound); fp=fixed_point(model,bound)
        check(f'{name}: Lagrange versus fixed point',equal_jets(lb,fp))
        res=residual(lb,model,bound)
        check(f'{name}: composition residual',equal_jets(res,{}))
        if name in ('log','resonant','nonlinear-leading'):
            lq=lagrange(model,bound,sp.Integer(2)); fq=fixed_point(model,bound,sp.Integer(2))
            check(f'{name}: observable square',equal_jets(lq,fq))
    # Deterministic varied fixtures, independently composed with a finite ring.
    rng=random.Random(236367)
    fixtures=[]
    for i in range(4 if quick else 20):
        p=rng.choice([sp.Rational(1,2),sp.S.One,sp.Rational(3,2),sp.Integer(2),sp.Integer(3)])
        d=rng.choice([sp.Rational(1,2),sp.Rational(2,3),sp.S.One])
        if i == 0: p=sp.sqrt(2)
        P=sp.Integer(rng.choice([-2,-1,1,2]))+rng.choice([-1,0,1])*L
        Q=sp.Integer(rng.choice([-2,-1,1,2]))+rng.choice([-1,0,1])*L
        m=Model(sp.S.One,p,((d,P),(2*d,Q)))
        bound=3*d
        lb=lagrange(m,bound); fp=fixed_point(m,bound)
        check(f'fixture {i:02}: algorithm agreement',equal_jets(lb,fp))
        check(f'fixture {i:02}: residual',equal_jets(residual(lb,m,bound),{}))
        q=rng.choice([sp.Rational(-1,2),sp.Rational(1,2),sp.Integer(2)])
        check(f'fixture {i:02}: observable q={q}',equal_jets(lagrange(m,bound,q),fixed_point(m,bound,q)))
        fixtures.append({'p':str(p),'delta':str(d),'P':str(P),'Q':str(Q),'q':str(q)})
    # Truncation error's first coefficient is minus p times inverse frontier.
    for name,m,bound in catalog[:4]:
        d=min((e for e,_ in m.corrections),key=cmp_to_key(cmp))
        full=lagrange(m,bound)
        keep={w:P for w,P in full.items() if cmp(w,bound)<0}
        res=residual(keep,m,bound)
        check(f'{name}: frontier residual sign and slope',
              sp.simplify(res.get(bound,0)+m.p*full.get(bound,0))==0)
    return checks,fixtures


def mp_expr(e: sp.Expr) -> mp.mpf:
    return mp.mpf(str(sp.N(e,mp.mp.dps)))


def evaluate(model: Model,x: mp.mpf) -> mp.mpf:
    if x==0:return mp.mpf('0')
    l=mp.log(x)
    h=mp.mpf('0')
    for d,P in model.corrections:
        co=sp.Poly(P,L).all_coeffs(); v=mp.mpf('0')
        for c in co:v=v*l+mp_expr(c)
        h+=x**mp_expr(d)*v
    return mp_expr(model.a)*x**mp_expr(model.p)*(1+h)


def bisect(model: Model,y: mp.mpf,t: mp.mpf) -> mp.mpf:
    lo=mp.mpf('0');hi=2*t
    # This is high-precision numerical bracketing, not interval certification.
    if evaluate(model,hi)<=y:raise ValueError('Upper bracket failed')
    for _ in range(int(mp.mp.dps*3.6)+20):
        mid=(lo+hi)/2
        if evaluate(model,mid)<y:lo=mid
        else:hi=mid
    return (lo+hi)/2


def eval_jet(j: Jet,t: mp.mpf,q=sp.S.One) -> mp.mpf:
    l=mp.log(t); total=mp.mpf('0')
    for w,P in j.items():
        val=mp.mpf('0')
        for c in sp.Poly(P,L).all_coeffs():val=val*l+mp_expr(c)
        total+=t**mp_expr(q+w)*val
    return total


def run_numeric():
    mp.mp.dps=180
    data=[]
    cases=[('log',Model(sp.S.One,sp.S.One,((sp.S.One,1+L),)),sp.Integer(4),[-2,-4,-8,-12]),
           ('irrational',Model(sp.S.One,sp.S.One,((sp.sqrt(2)-1,sp.S.One),)),
            canon(5*(sp.sqrt(2)-1)),[-2,-4,-8,-12]),
           ('nonlinear',Model(sp.Integer(2),sp.Integer(3),((sp.Rational(1,2),1+L),)),
            sp.Rational(3,2),[-12,-24,-48])]
    for name,m,bound,exponents in cases:
        allterms=lagrange(m,bound)
        keep={w:P for w,P in allterms.items() if cmp(w,bound)<0}
        frontier={bound:allterms[bound]}
        for e in exponents:
            y=mp.mpf(10)**e;t=(y/mp_expr(m.a))**(1/mp_expr(m.p))
            root=bisect(m,y,t);approx=eval_jet(keep,t)
            first=eval_jet(frontier,t);err=root-approx
            forward=evaluate(m,approx)-y
            row={'case':name,'y':f'1e{e}', 'absolute_error':mp.nstr(abs(err),14),
                 'relative_error':mp.nstr(abs(err/root),14),
                 'error_over_frontier':mp.nstr(err/first,16),
                 'forward_residual':mp.nstr(abs(forward),14)}
            data.append(row)
    alpha=mp.sqrt(2);d=alpha-1;R=d**d/alpha**alpha
    return data,{'alpha':str(alpha),'radius_in_y_to_delta':mp.nstr(R,30),
                 'radius_in_y':mp.nstr(R**(1/d),30),'decimal_precision':mp.mp.dps}


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--quick',action='store_true')
    parser.add_argument('--skip-numerics',action='store_true')
    args=parser.parse_args();start=time.time()
    checks,fixtures=run_exact(args.quick)
    data,radius=([],{}) if args.skip_numerics else run_numeric()
    out={'validation_kind':'Independent Python reference; Wolfram package NOT executed',
         'sympy_version':sp.__version__,'mpmath_version':mp.__version__,
         'exact_checks_passed':len(checks),'exact_checks':checks,'fixtures':fixtures,
         'numeric_checks':data,'pure_power_radius':radius,
         'elapsed_seconds':round(time.time()-start,3)}
    here=Path(__file__).resolve().parent
    (here/'results.json').write_text(json.dumps(out,indent=2)+'\n')
    print(json.dumps({k:v for k,v in out.items() if k not in ('exact_checks','fixtures')},indent=2))
    return 0

if __name__=='__main__':raise SystemExit(main())
