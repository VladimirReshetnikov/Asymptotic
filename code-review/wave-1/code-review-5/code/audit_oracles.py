#!/usr/bin/env python3
"""Independent mathematical oracles for the Asymptotic 1.8.0 source audit.

These are NOT an execution, translation, or emulation of the Wolfram package.
Exact combinatorial and symbolic checks support the review; numerical root
comparisons are evidence, not interval certificates. Python 3.9+, SymPy,
mpmath. Run: python code/audit_oracles.py --output results/oracles.json
SPDX-License-Identifier: MIT-0
"""
from __future__ import annotations
import argparse
from fractions import Fraction
from functools import reduce
from math import gcd, factorial
from pathlib import Path
import json
import platform
import time
from typing import Iterable, List, Tuple
import mpmath as mp
import sympy as sp

COMMIT = '07a9781212beb2eeb9ff16aa625b50ac27974078'

def lcm(a: int, b: int) -> int:
    return abs(a // gcd(a, b) * b)

def dense_export_slots(exponents: Iterable[Fraction], remainder: Fraction) -> int:
    """Compute the upstream dense-list length WITHOUT allocating that list."""
    exponents = tuple(Fraction(x) for x in exponents)
    remainder = Fraction(remainder)
    denominator = reduce(lcm, (v.denominator for v in exponents + (remainder,)), 1)
    first = min(exponents, default=remainder)
    width = (remainder - first) * denominator
    if width.denominator != 1 or width < 0:
        raise ValueError('Exponents must precede the remainder on their rational lattice.')
    return int(width)

def multiindex_count(gaps: Iterable[int], exclusive_cutoff: int) -> int:
    """Count nonnegative k with sum(gap_i*k_i)<cutoff, by generating functions."""
    gaps = tuple(gaps)
    if exclusive_cutoff < 1 or any(not isinstance(g, int) or g < 1 for g in gaps):
        raise ValueError('Positive integral gaps and a positive cutoff are required.')
    coefficients = [0] * exclusive_cutoff
    coefficients[0] = 1
    for gap in gaps:
        for weight in range(gap, exclusive_cutoff):
            coefficients[weight] += coefficients[weight - gap]
    return sum(coefficients)

def primitive_rational_lattice(rates: Iterable[Fraction]) -> Tuple[Fraction, List[int]]:
    """Primitive positive generator of a finite positive rational rate family."""
    rates = tuple(Fraction(x) for x in rates)
    if not rates or any(x <= 0 for x in rates):
        raise ValueError('A nonempty family of positive rates is required.')
    denominator = reduce(lcm, (x.denominator for x in rates), 1)
    integers = [int(x * denominator) for x in rates]
    divisor = reduce(gcd, integers)
    return Fraction(divisor, denominator), [x // divisor for x in integers]

def lagrange_block(indices, gaps, polynomials, p, r, ell):
    """Euler-operator coefficient, evaluated independently with SymPy."""
    if len(indices) != len(gaps) or len(indices) != len(polynomials):
        raise ValueError('One gap and polynomial are required per index.')
    if any(not isinstance(k, int) or k < 0 for k in indices):
        raise ValueError('Indices must be nonnegative integers.')
    n = sum(indices)
    if not n:
        return sp.Integer(0), sp.Integer(1)
    p, r = sp.sympify(p), sp.sympify(r)
    weight = sum((sp.sympify(g) * k for k, g in zip(indices, gaps)), sp.Integer(0))
    q = sp.prod(poly ** k for k, poly in zip(indices, polynomials))
    for j in range(1, n):
        q = sp.diff(q, ell) + (r + weight + p * j) * q
    q *= (-1) ** n * r / (p ** n * sp.prod(factorial(k) for k in indices))
    return sp.simplify(weight), sp.expand(q)

def gamma_phase(unit, t, q, c, order):
    return (unit + q * ((1 + unit) * sp.log(1 + unit) - unit)
            - t / 2 + c * t * q / 2 - t * q * sp.log(1 + unit) / 2
            + sum(sp.bernoulli(2*k) * q * t**(2*k) * (1+unit)**(1-2*k)
                  / (2*k*(2*k-1)) for k in range(1, order//2 + 1)))

def barnes_phase(unit, t, q, c, a, order):
    return (unit + unit**2 / 2
            + q * ((1+unit)**2 * sp.log(1+unit)-unit-unit**2/2) / 2
            + c*q*t*(1+unit)/2 - t**2*(sp.Rational(1,12)+a*q)
            - q*t**2*sp.log(1+unit)/12
            + q*sum(sp.bernoulli(2*k+2)*t**(2*k+2)*(1+unit)**(-2*k)
                    / (2*k*(2*k+2)) for k in range(1, max(0, (order-2)//2)+1)))

def implicit_unit(phase, t, order):
    """Solve a finite formal implicit equation with linearized coefficient 1."""
    unit = sp.Integer(0)
    coefficients = []
    for j in range(1, order + 1):
        coefficient = -sp.expand(sp.series(phase(unit), t, 0, j+1).removeO()).coeff(t, j)
        coefficient = sp.factor(coefficient)
        coefficients.append(coefficient)
        unit += coefficient * t**j
    residual = sp.expand(sp.series(phase(unit), t, 0, order+1).removeO())
    return sp.expand(unit), coefficients, sp.simplify(residual)

def interval_exp_unit(q: Fraction, order: int):
    """Exact positive Taylor enclosure, 0<=q<=1/2. No dyadic rounding here."""
    q = Fraction(q)
    if not 0 <= q <= Fraction(1,2) or order < 0:
        raise ValueError('Require 0<=q<=1/2 and nonnegative order.')
    partial = sum((q**k / factorial(k) for k in range(order+1)), Fraction(0))
    tail = q**(order+1) / factorial(order+1) / (1-q/Fraction(order+2))
    return partial, partial + tail

def interval_log_unit(q: Fraction, order: int):
    """Exact atanh-series enclosure, 1<=q<=2."""
    q = Fraction(q)
    if not 1 <= q <= 2 or order < 1:
        raise ValueError('Require 1<=q<=2 and positive order.')
    u = (q-1)/(q+1)
    partial = 2*sum((u**(2*k+1)/Fraction(2*k+1) for k in range(order)), Fraction(0))
    tail = 2*u**(2*order+1) / ((2*order+1)*(1-u*u))
    return partial, partial + tail

def mp_fraction(q):
    return mp.mpf(q.numerator)/q.denominator

def run_oracles():
    start = time.perf_counter()
    records = []
    def check(name, condition, details=None):
        result = bool(condition)
        records.append({'name': name, 'passed': result, 'details': details})
        if not result:
            raise AssertionError(name)
    slots = dense_export_slots([Fraction(1,10**9)], Fraction(1))
    check('dense-rational-grid-width', slots == 999_999_999, {'slots':slots, 'allocation_performed':False})
    counts = {str(h):multiindex_count(range(1,31),h) for h in (20,24,28,30,32,36)}
    check('newton-wrapper-multiindex-lower-bound',counts['30']==23025,counts)
    base,degrees=primitive_rational_lattice([2,3])
    check('primitive-flat-lattice-2-3',base==1 and degrees==[2,3],{'base':str(base),'degrees':degrees})
    base,degrees=primitive_rational_lattice([Fraction(2,3),Fraction(5,6)])
    check('primitive-flat-lattice-rational',base==Fraction(1,6) and degrees==[4,5])
    y,L,t,q,C,A = sp.symbols('y L t q C A')
    log_coeff=[]
    for n in range(6):
        _,coefficient=lagrange_block([n],[1],[1+L],1,1,L)
        log_coeff.append(coefficient)
    g=sum(log_coeff[n]*y**(n+1) for n in range(6))
    log_g=L+sp.series(sp.log(g/y),y,0,6).removeO()
    residual=sp.expand(sp.series(g+g*g*(1+log_g)-y,y,0,7).removeO())
    check('power-log-euler-formula-composition-through-y6',residual==0,
          {'coefficients':[str(c) for c in log_coeff]})
    # A separate rational function identity establishes the Newton fixture's answer.
    check('geometric-polynomial-inverse-fixture',sp.cancel((y/(1+y))/(1-y/(1+y))-y)==0)
    # The rejected source is genuinely nonreal, not just missing an assumed sign.
    x=sp.symbols('x',positive=True)
    check('negative-root-observable-is-nonreal',sp.simplify(sp.im(1+sp.sqrt(-x))-sp.sqrt(x))==0)
    # Diagnostic normalization must subtract the finite target offset.
    c=sp.symbols('c')
    check('residual-offset-normalization',sp.cancel(y/(y-c)-1-c/(y-c))==0)
    # Gamma and Barnes equations are derived from their finite logarithmic models.
    gu,gc,gr=implicit_unit(lambda u:gamma_phase(u,t,q,C,4),t,4)
    bu,bc,br=implicit_unit(lambda u:barnes_phase(u,t,q,C,A,4),t,4)
    check('gamma-finite-model-residual-order-four',gr==0,{'coefficients':[str(z) for z in gc]})
    check('barnes-finite-model-residual-order-four',br==0,{'coefficients':[str(z) for z in bc]})
    check('gamma-first-correction',sp.expand(gc[0]-(1-C*q)/2)==0)
    check('gamma-second-correction',sp.expand(gc[1]-(q/24-C*C*q**3/8))==0)
    check('barnes-first-correction',sp.expand(bc[0]+C*q/2)==0)
    check('barnes-second-correction',sp.expand(bc[1]-(sp.Rational(1,12)+A*q+C*C*q*q*(1-q)/8))==0)
    with mp.workdps(100):
        for value in (Fraction(0),Fraction(1,10),Fraction(1,2)):
            lo,hi=interval_exp_unit(value,30)
            truth=mp.exp(mp_fraction(value))
            check('exp-enclosure-sample-'+str(value),mp_fraction(lo)<=truth<=mp_fraction(hi))
        for value in (Fraction(1),Fraction(3,2),Fraction(2)):
            lo,hi=interval_log_unit(value,40)
            truth=mp.log(mp_fraction(value))
            check('log-enclosure-sample-'+str(value),mp_fraction(lo)<=truth<=mp_fraction(hi))
        alpha=mp.sqrt(2)
        irrational=[]
        for target in (mp.mpf('1e-4'),mp.mpf('1e-8'),mp.mpf('1e-12')):
            terms=[]
            for n in range(6):
                coeff=mp.mpf(1) if n==0 else ((-1)**n/mp.factorial(n)*mp.fprod(1+n*(alpha-1)+j for j in range(1,n)))
                terms.append(coeff*target**(1+n*(alpha-1)))
            approximate=mp.fsum(terms)
            root=mp.findroot(lambda z:z+z**alpha-target,(target/2,target))
            scaled=abs(root-approximate)/target**(1+6*(alpha-1))
            irrational.append({'target':str(target),'error':mp.nstr(abs(root-approximate),15),'scaled_error':mp.nstr(scaled,15)})
        check('irrational-power-inverse-root-comparison',all(mp.mpf(row['scaled_error'])<100 for row in irrational),irrational)
        root_rows=[]
        gu_fn=sp.lambdify((t,q,C),gu,'mpmath')
        bu_fn=sp.lambdify((t,q,C,A),bu,'mpmath')
        for X in (20,50,100):
            X=mp.mpf(X); logarithm=mp.log(X)
            Y=X*(logarithm-1)
            gamma_approx=X*(1+gu_fn(1/X,1/logarithm,mp.log(2*mp.pi)))
            gamma_root=mp.findroot(lambda z:mp.loggamma(z)-Y,(X,X+1))
            B=X*X*(logarithm-mp.mpf('1.5'))/2
            barnes_approx=1+X*(1+bu_fn(1/X,1/(logarithm-1),mp.log(2*mp.pi),mp.log(mp.glaisher)))
            barnes_root=mp.findroot(lambda z:mp.log(mp.barnesg(z))-B,(X,X+1))
            root_rows.append({'core':str(X),'gamma_error':mp.nstr(abs(gamma_root-gamma_approx),15),'barnes_error':mp.nstr(abs(barnes_root-barnes_approx),15)})
        check('gamma-barnes-numerical-errors-decrease',all(mp.mpf(root_rows[i+1][k])<mp.mpf(root_rows[i][k]) for i in range(2) for k in ('gamma_error','barnes_error')),root_rows)
    return {'snapshot':COMMIT,'status':'independent_oracles_executed','native_wolfram_executed':False,
            'warning':'No result in this file is a native Wolfram package test. Numerical comparisons are not certificates.',
            'environment':{'python':platform.python_version(),'sympy':sp.__version__,'mpmath':mp.__version__},
            'check_count':len(records),'passed':sum(r['passed'] for r in records),
            'elapsed_seconds':round(time.perf_counter()-start,4),'checks':records}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=Path('oracles.json'))
    args=parser.parse_args()
    result=run_oracles()
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(f"{result['passed']}/{result['check_count']} independent checks passed; native Wolfram tests were not run.")
    print(args.output)

if __name__=='__main__':
    main()
