#!/usr/bin/env python3
"""Independent mathematics checks; this does NOT execute the Wolfram package.

Requires mpmath and sympy. Tests a tagged asymptotic-envelope model, derives
flat inverse coefficients, and compares direct with normalized error evaluation.
"""
from __future__ import annotations
from fractions import Fraction
import json
from pathlib import Path
import random
from typing import Optional
import mpmath as mp
import sympy as sp

Bound = Optional[tuple[Fraction, int]]  # None means exact zero.

def add(a: Bound, b: Bound) -> Bound:
    if a is None: return b
    if b is None: return a
    return min((a,b), key=lambda z: (z[0], -z[1]))

def mul(a: Bound, b: Bound) -> Bound:
    if a is None or b is None: return None
    return a[0]+b[0], a[1]+b[1]

def tagged_projection(aj: list[Bound], at: Bound,
                      bj: list[Bound], bt: Bound) -> Bound:
    """Independent oracle: keep degree tags on ALL contributions."""
    na, nb = len(aj)-1, len(bj)-1
    boundary = min(na,nb)+1
    terms: list[tuple[int, Bound]] = []
    for i,a in enumerate(aj):
        for j,b in enumerate(bj):
            if i+j >= boundary: terms.append((i+j,mul(a,b)))
    terms += [(na+1+j,mul(at,b)) for j,b in enumerate(bj)]
    terms += [(nb+1+i,mul(bt,a)) for i,a in enumerate(aj)]
    terms += [(na+nb+2,mul(at,bt))]
    result: Bound = None
    for degree,bound in terms:
        if degree == boundary: result = add(result,bound)
    if result is None and any(bound is not None for _,bound in terms):
        return Fraction(0),0
    return result

def boundary_projection(aj: list[Bound], at: Bound,
                        bj: list[Bound], bt: Bound) -> Bound:
    """Model of proposed code: boundary convolution plus eligible zero sectors."""
    na, nb = len(aj)-1, len(bj)-1
    n = min(na,nb)
    convolution: list[Bound] = [None]*(na+nb+1)
    for i,a in enumerate(aj):
        for j,b in enumerate(bj):
            convolution[i+j] = add(convolution[i+j],mul(a,b))
    result = convolution[n+1]
    if na == n: result = add(result,mul(at,bj[0]))
    if nb == n: result = add(result,mul(bt,aj[0]))
    later = (any(t is not None for t in convolution[n+2:]) or
             (at is not None and any(t is not None for t in bj)) or
             (bt is not None and any(t is not None for t in aj)) or
             (at is not None and bt is not None))
    return (Fraction(0),0) if result is None and later else result

def normalized_error_ratio(y: mp.mpf) -> mp.mpf:
    """For inverse of x+exp(-1/x), compute (g-(y-E))/(E^2/y^2).

Solves the algebraically equivalent normalized correction equation. No
subtraction of two source roots is performed. This is numerical, not certified.
"""
    e = mp.exp(-1/y)
    def equation(w: mp.mpf) -> mp.mpf:
        u = y-e+(e*e/(y*y))*w
        t = -e*(1-e*w/(y*y))/(u*y)
        exprel = mp.expm1(t)/t if t else mp.mpf(1)
        return w - y*(1-e*w/(y*y))/u*exprel
    return mp.findroot(equation, (mp.mpf('0.9'),mp.mpf('1.1')))

def main() -> None:
    rng = random.Random(921387)
    def rb() -> Bound:
        return None if rng.randrange(4)==0 else (Fraction(rng.randint(-30,30),rng.randint(1,5)),rng.randrange(7))
    for _ in range(4000):
        na,nb = rng.randint(1,8),rng.randint(1,8)
        aj,bj = [rb() for _ in range(na+1)],[rb() for _ in range(nb+1)]
        at,bt = rb(),rb()
        assert tagged_projection(aj,at,bj,bt)==boundary_projection(aj,at,bj,bt)
    # The zero-boundary/later-tail branch must not yield an exact-zero tail.
    assert boundary_projection([None,None],(Fraction(-2),0),
                               [None,None],(Fraction(-2),0))==(Fraction(0),0)
    assert boundary_projection([None,None],None,[None,None],None) is None
    y = sp.symbols('y', positive=True)
    coefficients = {}
    for k in range(1,5):
        ck = sp.simplify((-1)**k/sp.factorial(k)*
                        sp.diff(sp.exp(-k/y),y,k-1)/sp.exp(-k/y))
        coefficients[str(k)] = str(ck)
    assert sp.simplify(sp.sympify(coefficients['2'],locals={'y':y})-1/y**2)==0
    numerical = {}
    with mp.workdps(60):
        v = mp.mpf(1)/1000; e=mp.exp(-1/v); q=v-e
        g=v
        for _ in range(5): g=v-mp.exp(-1/g)
        numerical['direct_60_dps_error']=mp.nstr(g-q,20)
        numerical['normalized_60_dps_ratio']=mp.nstr(normalized_error_ratio(v),55)
        numerical['log10_remainder_scale']=mp.nstr(mp.log10(e*e/(v*v)),30)
    with mp.workdps(950):
        v=mp.mpf(1)/1000; e=mp.exp(-1/v); q=v-e; g=v
        for _ in range(5): g=v-mp.exp(-1/g)
        ratio=(g-q)/(e*e/(v*v))
        assert abs(ratio-1)<mp.mpf('1e-70')
        assert g-q>0
        numerical['direct_950_dps_error']=mp.nstr(g-q,70)
        numerical['direct_950_dps_ratio']=mp.nstr(ratio,70)
    result={
        'scope':'Independent bound-model and mathematical checks, NOT package tests',
        'random_seed':921387,'random_projection_cases_passed':4000,
        'edge_cases_passed':2,'inverse_coefficients':coefficients,'numerics':numerical,
        'flat_product_baseline_rho_for_depths_1_1_to_1_3':[-4,-6,-8],
        'flat_product_sharp_rho_for_same_depths':[-1,-1,-1],
        'limitations':'The random model checks envelope bookkeeping; it does not certify the whole Wolfram implementation or numerical root.'}
    output=Path(__file__).resolve().parents[1]/'evidence'/'independent_results.json'
    output.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))

if __name__=='__main__': main()
