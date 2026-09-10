#!/usr/bin/env python3
"""Independent exact/numerical oracles for the review, NOT the WL package.

The rational exp-ratio inverse returns a genuine enclosure certified by
rational Taylor bounds and monotonicity. SymPy observations reproduce only
an upstream argument-conversion mechanism, not a full Mathics kernel run.
"""
from __future__ import annotations
import argparse
from dataclasses import dataclass
from fractions import Fraction as F
from functools import reduce
import json
import math
from pathlib import Path
import platform
from typing import Iterable

BUNDLE = Path(__file__).resolve().parents[1]

@dataclass(frozen=True)
class Interval:
    lower: F
    upper: F
    def __post_init__(self) -> None:
        if self.lower > self.upper:
            raise ValueError('Reversed interval')
    @property
    def width(self) -> F:
        return self.upper - self.lower
    def as_dict(self) -> dict:
        return {'lower': str(self.lower), 'upper': str(self.upper), 'width': str(self.width)}


def exp_enclosure(x: F, tolerance: F, max_terms: int = 4096) -> Interval:
    """For rational x >= 0, enclose exp(x) using a positive Taylor tail.

    After S_n, t_{n+1}=x^(n+1)/(n+1)!. All subsequent term ratios
    are <= x/(n+2); when this is <1 the geometric majorant is rigorous.
    """
    x, tolerance = F(x), F(tolerance)
    if x < 0 or tolerance <= 0 or max_terms < 1:
        raise ValueError('Require x>=0, positive tolerance and positive term budget')
    if x == 0:
        return Interval(F(1), F(1))
    partial, term = F(1), F(1)
    for n in range(1, max_terms + 1):
        term *= x / n
        partial += term
        next_term = term * x / (n + 1)
        ratio = x / (n + 2)
        if ratio < 1:
            tail = next_term / (1 - ratio)
            if tail <= tolerance:
                return Interval(partial, partial + tail)
    raise RuntimeError('Exponential enclosure term budget exhausted')


def exp_ratio_inverse(y: F, bits: int = 72) -> tuple[Interval, dict]:
    """Enclose the unique x>1 solving exp(x)/x=y, for rational y>e.

    This does not call ProductLog/LambertW or use floating-point decisions.
    It refuses undecided sign tests rather than silently choosing a branch.
    """
    y = F(y)
    if y <= 0 or not isinstance(bits, int) or not 1 <= bits <= 512:
        raise ValueError('Require y>0 and bits in 1..512')
    width = F(1, 2**bits)
    attempts = 0
    def sign(x: F) -> tuple[int, Interval]:
        nonlocal attempts
        tolerance = F(1, 2**(bits + 16))
        for _ in range(12):
            enclosure = exp_enclosure(x, tolerance)
            attempts += 1
            if enclosure.upper < y*x:
                return -1, enclosure
            if enclosure.lower > y*x:
                return 1, enclosure
            tolerance /= 2**32
        raise RuntimeError('Residual sign unresolved within arithmetic budget')
    left = F(1)
    left_sign, _ = sign(left)
    if left_sign != -1:
        raise ValueError('This increasing branch requires y>e')
    right = F(2)
    for _ in range(40):
        if sign(right)[0] == 1:
            break
        right *= 2
    else:
        raise RuntimeError('Bracketing budget exhausted')
    bisections = 0
    while right-left > width:
        midpoint = (left+right)/2
        if sign(midpoint)[0] < 0:
            left = midpoint
        else:
            right = midpoint
        bisections += 1
    sl, el = sign(left)
    sr, er = sign(right)
    assert sl == -1 and sr == 1
    certificate = {
        'equation': 'exp(x)/x = y', 'y': str(y),
        'domain': 'x>1', 'strictly_increasing': 'derivative = exp(x)*(x-1)/x^2 > 0',
        'left_exp_upper_less_than_y_times_left': el.upper < y*left,
        'right_exp_lower_greater_than_y_times_right': er.lower > y*right,
        'bisections': bisections, 'exact_sign_enclosures': attempts,
        'requested_width': str(width), 'width_met': right-left <= width,
        'decisions': 'rational arithmetic only; existence by continuity, uniqueness by monotonicity'
    }
    return Interval(left, right), certificate


def lower_lambert_enclosure(z: F, bits: int = 72) -> tuple[Interval, dict]:
    """Enclose real W_{-1}(z), for rational -1/e < z < 0."""
    z = F(z)
    if z >= 0:
        raise ValueError('Require negative rational z')
    interval, certificate = exp_ratio_inverse(-1/z, bits)
    return Interval(-interval.upper, -interval.lower), certificate


def product(items: Iterable[F]) -> F:
    return reduce(lambda a,b: a*b, items, F(1))


def hypergeom_data(upper: Iterable[F], lower: Iterable[F], order: int) -> tuple[list[F], int | None]:
    """Exact rational pFq coefficients, with unambiguous denominator admission.

    All nonpositive integer lower parameters are rejected, including cases
    where a limiting/cancellation convention might define another function.
    """
    upper, lower = tuple(map(F, upper)), tuple(map(F, lower))
    if not isinstance(order, int) or not 0 <= order <= 4096:
        raise ValueError('Order must be an integer in 0..4096')
    if any(b.denominator == 1 and b <= 0 for b in lower):
        raise ValueError('Nonpositive integer lower parameter: regularization is not selected')
    terminations = [-int(a) for a in upper if a.denominator == 1 and a <= 0]
    degree = min(terminations) if terminations else None
    if degree is None and len(upper) > len(lower)+1:
        raise ValueError('Nonterminating divergent defining series is not an analytic Taylor model')
    coefficients = [F(1)]
    for n in range(order):
        coefficients.append(coefficients[-1] * product(a+n for a in upper) /
                            ((n+1)*product(b+n for b in lower)))
    return coefficients, degree


def hypergeom_tail_bound(upper: Iterable[F], lower: Iterable[F], radius: F, order: int) -> dict:
    """Uniform bound for the omitted Taylor tail on |z|<=radius.

    For n>=J, coefficient-term ratios are bounded by
    radius*J^(p-q-1)*prod(1+|a|/J)/prod(1-|b|/J).
    The finite prefix before that ratio regime is bounded separately.
    """
    upper, lower = tuple(map(F, upper)), tuple(map(F, lower))
    radius = F(radius)
    if radius < 0:
        raise ValueError('Radius must be nonnegative')
    coefficients, degree = hypergeom_data(upper, lower, order)
    if degree is not None:
        all_coefficients, _ = hypergeom_data(upper, lower, max(order, degree))
        bound = sum((abs(all_coefficients[n])*radius**n for n in range(order+1,degree+1)), F(0))
        return {'coefficients': coefficients, 'bound': bound, 'polynomial_degree': degree,
                'exact_remainder_zero': order >= degree, 'ratio_start': None, 'ratio_bound': F(0)}
    if len(upper) == len(lower)+1 and radius >= 1:
        raise ValueError('This nonterminating p=q+1 bound requires radius<1')
    J = 1
    for _ in range(13):
        if all(J > abs(b) for b in lower):
            q = (radius * F(J)**(len(upper)-len(lower)-1) *
                 product(1+abs(a)/J for a in upper) /
                 product(1-abs(b)/J for b in lower))
            if q < 1:
                break
        J *= 2
    else:
        raise RuntimeError('Geometric majorant budget exhausted')
    start = max(order+1, J+1)
    all_coefficients, _ = hypergeom_data(upper, lower, start)
    prefix = sum((abs(all_coefficients[n])*radius**n for n in range(order+1, start)), F(0))
    bound = prefix + abs(all_coefficients[start])*radius**start/(1-q)
    return {'coefficients': coefficients, 'bound': bound, 'polynomial_degree': None,
            'exact_remainder_zero': False, 'ratio_start': J, 'ratio_bound': q}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=BUNDLE/'evidence/mathematical_oracles.json')
    args = parser.parse_args()
    import sympy as sp
    import mpmath as mp
    mp.mp.dps = 60
    results = {'scope': 'Independent Python oracles; NOT a Wolfram or Mathics package run',
               'python': platform.python_version(), 'sympy': sp.__version__, 'mpmath': mp.__version__}
    correct = sp.LambertW(sp.Rational(-1,10), -1)
    reversed_call = sp.LambertW(-1, sp.Rational(-1,10))
    results['lambert_conversion'] = {
        'intended_sympy': str(correct), 'intended_value': str(correct.evalf(40)),
        'unpermuted_sympy': str(reversed_call), 'unpermuted_value': str(reversed_call.evalf(40)),
        'principal_unpermuted_0_E': str(sp.LambertW(0,sp.E)),
        'principal_correct_E_0': str(sp.LambertW(sp.E,0))}
    x = sp.Symbol('x', real=True)
    results['limit_oracle'] = {'left': str(sp.limit(sp.Abs(x)/x,x,0,dir='-')),
                              'right': str(sp.limit(sp.Abs(x)/x,x,0,dir='+')),
                              'two_sided_real_limit': 'does not exist (unequal one-sided limits)'}
    certificates=[]
    for y in [F(3), F(10), F(100)]:
        enclosure, proof = exp_ratio_inverse(y)
        expected = -mp.lambertw(-mp.mpf(y.denominator)/y.numerator, -1)
        numerical_lower = mp.mpf(enclosure.lower.numerator)/enclosure.lower.denominator
        numerical_upper = mp.mpf(enclosure.upper.numerator)/enclosure.upper.denominator
        assert numerical_lower < expected < numerical_upper
        certificates.append(dict(interval=enclosure.as_dict(), certificate=proof,
                                 numerical_cross_check=mp.nstr(expected,40)))
    results['exp_ratio_certificates'] = certificates
    hg=[]
    for upper,lower,order in [([], [F(-1,2)],4), ([F(-2),F(1),F(1)],[],2), ([F(1,3),F(2,3)],[F(-1,2)],4)]:
        result = hypergeom_tail_bound(upper,lower,F(1,4),order)
        for z in [mp.mpf('0.25'),mp.mpf('-0.25')]:
            true = mp.hyper([mp.mpf(a.numerator)/a.denominator for a in upper],
                            [mp.mpf(b.numerator)/b.denominator for b in lower],z)
            approx = sum((mp.mpf(c.numerator)/c.denominator*z**n for n,c in enumerate(result['coefficients'])),mp.mpf(0))
            bnd = mp.mpf(result['bound'].numerator)/result['bound'].denominator
            assert abs(true-approx) <= bnd + mp.mpf('1e-55')
        hg.append({'upper':list(map(str,upper)), 'lower':list(map(str,lower)),
                   'order':order, 'radius':'1/4',
                   **{k: [str(c) for c in v] if isinstance(v,list) else str(v) if isinstance(v,F) else v for k,v in result.items()}})
    assert hg[1]['coefficients'] == ['1','-2','4'] and hg[1]['exact_remainder_zero']
    results['hypergeometric_models'] = hg
    results['resource_counts'] = [dict(degree=D, input_support=2, output_support=2,
                                       dense_slots=D+1, slots_actually_allocated_in_this_test=0)
                                  for D in [1000,1000000,10**12]]
    # Reject ambiguous denominator cancellation and divergent nonterminating defining series.
    refusals=[]
    for a,b in [([F(-2)],[F(-2)]),([F(1),F(1)],[])]:
        try:
            hypergeom_data(a,b,4)
        except ValueError as e:
            refusals.append(str(e))
        else:
            raise AssertionError('Expected an admission refusal')
    results['negative_controls'] = refusals
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(results,indent=2))
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
