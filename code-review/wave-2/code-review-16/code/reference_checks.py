#!/usr/bin/env python3
"""Independent mathematical checks, NOT execution or emulation of the package.

Python 3.10+, SymPy. Produces exact-arithmetic evidence for the review.
The closed-boundary oracle supports rational weights. Production WL supports
additional exact real weights; this oracle does not claim to cover those.
"""
from __future__ import annotations
import argparse
import json
import math
from dataclasses import dataclass
from fractions import Fraction as Q
from pathlib import Path
from typing import Callable
import sympy as sp

L = sp.Symbol('L')
Poly = sp.Expr
Jet = dict[Q, Poly]


def merge(rows: Jet) -> Jet:
    return {w: p for w, q in sorted(rows.items()) if (p := sp.expand(q)) != 0}


def multiply_closed(a: Jet, b: Jet, cutoff: Q, max_pairs: int = 20000) -> Jet:
    """Keep weights <= cutoff, including the boundary needed for an O bound."""
    out: Jet = {}
    count = 0
    for wa, pa in sorted(a.items()):
        for wb, pb in sorted(b.items()):
            w = wa + wb
            if w > cutoff:
                break
            count += 1
            if count > max_pairs:
                raise RuntimeError('closed convolution pair budget exceeded')
            out[w] = out.get(w, sp.Integer(0)) + pa * pb
    return merge(out)


def boundary_jet(u: Jet, input_power: Q, input_degree: int,
                 cutoff: Q, coefficient: Callable[[int], Poly | None],
                 max_pairs: int = 20000) -> tuple[Jet, Q, int, list[int]]:
    """f(U)-f(0) for an analytic f, with one sequential callback invocation/k.

    None means permanent termination of the coefficient sequence, not a zero
    coefficient. Missing rational weights have coefficient zero.
    """
    u = merge(u)
    if not u or min(u) <= 0:
        raise ValueError('this reference oracle requires a nonempty positive jet')
    if input_degree < 0 or any(w >= input_power for w in u):
        raise ValueError('input rows must lie strictly below their error power')
    c = min(input_power, cutoff)
    power: Jet = {Q(0): sp.Integer(1)}
    result: Jet = {}
    calls = []
    k = 0
    while True:
        power = multiply_closed(power, u, c, max_pairs)
        if not power:
            break
        k += 1
        calls.append(k)
        q = coefficient(k)
        if q is None:
            break
        for w, p in power.items():
            result[w] = result.get(w, sp.Integer(0)) + q * p
        result = merge(result)
        if len(result) > max_pairs:
            raise RuntimeError('result budget exceeded')
    boundary = sp.expand(result.get(c, 0))
    degree = 0 if boundary == 0 else max(0, int(sp.degree(boundary, L)))
    if c == input_power:
        degree = max(degree, input_degree)
    return {w: p for w, p in result.items() if w < c}, c, degree, calls


def pow2(n: int) -> Q:
    return Q(2**n) if n >= 0 else Q(1, 2**(-n))


def directed_round(q: Q, bits: int, upper: bool) -> Q:
    if bits < 2:
        raise ValueError('bits must be >=2')
    if q == 0:
        return q
    a = abs(q)
    e = a.numerator.bit_length() - a.denominator.bit_length()
    if a < pow2(e):
        e -= 1
    grid = pow2(e - bits + 1)
    n = q / grid
    integer = -((-n.numerator) // n.denominator) if upper else n.numerator // n.denominator
    return grid * integer


def rounded_sum(a: tuple[Q, Q], b: tuple[Q, Q], bits: int) -> tuple[Q, Q]:
    return (directed_round(a[0] + b[0], bits, False),
            directed_round(a[1] + b[1], bits, True))


def identity_residual(center: Q, target: Q, bits: int) -> tuple[Q, Q]:
    # This reproduces only the rational interval arithmetic for Plus[-target,x].
    # It does not reproduce WL evaluation or the full certificate algorithm.
    a = rounded_sum((Q(0), Q(0)), (-target, -target), bits)
    return rounded_sum(a, (center, center), bits)


def log10q(q: Q) -> float:
    return math.log10(abs(q.numerator)) - math.log10(q.denominator)


def run() -> dict:
    tests: list[dict] = []
    def check(name: str, ok: bool, detail: str = '') -> None:
        if not ok:
            raise AssertionError(name + ': ' + detail)
        tests.append({'name': name, 'passed': True, 'detail': detail})

    # The strengthened C04 repair: boundary log degree and cancellation.
    rows, c, d, calls = boundary_jet({Q(1): L}, Q(2), 0, Q(5),
                                   lambda k: sp.Rational(1, sp.factorial(k)))
    check('exponential boundary has logarithmic degree two', d == 2 and rows == {Q(1): L})
    check('callback sequence is single-pass', calls == [1, 2])
    _, _, d, _ = boundary_jet({Q(1): L}, Q(2), 0, Q(5),
                              lambda k: sp.Rational((-1)**(k+1), k))
    check('logarithm boundary has logarithmic degree two', d == 2)
    rows, _, d, _ = boundary_jet({Q(1): L, Q(2): -L**2 / 2}, Q(3), 0, Q(2),
                                  lambda k: sp.Rational(1, sp.factorial(k)))
    check('cancelled boundary gives degree zero', d == 0 and rows == {Q(1): L})
    _, _, d, _ = boundary_jet({Q(1): L}, Q(2), 7, Q(5),
                              lambda k: sp.Rational(1, sp.factorial(k)))
    check('input logarithmic uncertainty retained', d == 7)
    _, _, d, _ = boundary_jet({Q(2, 3): L**4}, Q(3), 0, Q(3, 2),
                              lambda k: sp.Rational(1, sp.factorial(k)))
    check('nonattained rational boundary needs no logarithmic degree', d == 0)

    # Exhaustive small rational-weight polynomial oracles. These are algebraic
    # identities at the boundary, independently checked by SymPy expansion.
    v = sp.Symbol('v')
    trials = 0
    for a in [1, 2, 3]:
        for b in [a+1, a+2]:
            for bound in range(b+1, b+5):
                u = {Q(a, 2): L+1, Q(b, 2): L**2-2}
                cf = lambda k: sp.Rational((-1)**k, k+1) if k <= 8 else None
                ans, c, degree, trace = boundary_jet(u, Q(bound+2, 2), 1, Q(bound, 2), cf)
                polynomial = sum(cf(k) * ((L+1)*v**a + (L**2-2)*v**b)**k for k in range(1, 9))
                polynomial = sp.Poly(sp.expand(polynomial), v)
                expected = {Q(i, 2): sp.expand(polynomial.nth(i)) for i in range(bound) if polynomial.nth(i) != 0}
                bpoly = sp.expand(polynomial.nth(bound))
                expected_degree = 0 if bpoly == 0 else max(0, int(sp.degree(bpoly, L)))
                check(f'closed boundary polynomial oracle {trials+1}', ans == expected and degree == expected_degree)
                check(f'stateful callback ordering {trials+1}', trace == list(range(1, len(trace)+1)))
                trials += 1

    # Certificate isolation counterexample: arithmetic root is outside the
    # retained domain. WL's documented Refine semantics establish the bypass;
    # these Python assertions only check the exact mathematical contradiction.
    target = Q(1, 2)
    check('unrestricted identity equation has root one half', target-target == 0)
    check('one-half violates retained source domain x>1', not target > 1)
    check('entire proposed interval violates x>1', Q(3, 4) < 1)

    # Directed rounding is enclosing at arbitrary signs and small magnitudes.
    for q in [Q(1, 3), Q(-1, 3), Q(0), Q(23, 7), Q(1, 10**100), Q(-17, 13)]:
        for bits in [8, 24, 280]:
            check(f'outward rounding {q} at {bits} bits',
                  directed_round(q, bits, False) <= q <= directed_round(q, bits, True))

    target = Q(1, 3)
    precision_rows = []
    for order in [60, 120, 240, 480, 960, 1920]:
        bits = 4*(order+10)
        lo = directed_round(target, bits, False)
        hi = directed_round(target, bits, True)
        center = (lo+hi)/2
        residual = identity_residual(center, target, bits)
        width = residual[1]-residual[0]
        bound = max(abs(residual[0]), abs(residual[1]))
        constant_width = pow2(-bits-1)
        check(f'non-dyadic constant width at order {order}', hi-lo == constant_width)
        check(f'residual inherits non-dyadic width at order {order}', width >= constant_width)
        check(f'residual radius has lower floor at order {order}', bound >= constant_width/2)
        precision_rows.append({'enclosure_order': order, 'bits': bits,
            'log10_residual_bound': log10q(bound),
            'meets_relative_1e_minus_1000_at_midpoint': bound <= Q(1, 10**1000)*lo})
    check('default order cannot meet very tight pure relative request', not precision_rows[0]['meets_relative_1e_minus_1000_at_midpoint'])
    check('larger enclosure order resolves arithmetic floor', precision_rows[-1]['meets_relative_1e_minus_1000_at_midpoint'])

    # Guarded positive real Zeta tail bounds, checked with exact partial sums.
    # The infinite-tail inequalities are proved in the article, not established
    # by finite summation; only the finite comparison is checked here.
    for s in [2, 3, 5, 10]:
        for m in [1, 2, 5]:
            partial = sum((Q(1, n**s) for n in range(m, m+150)), Q(0))
            lower = Q(1, m**s)
            upper = lower * (1+Q(m, s-1))
            check(f'zeta partial-tail comparison s={s},m={m}', lower <= partial <= upper)

    return {'scope': 'Independent rational arithmetic and polynomial identities; no native Wolfram execution.',
            'passed': len(tests), 'failed': 0, 'polynomial_boundary_trials': trials,
            'certificate_precision_table': precision_rows, 'tests': tests}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    report = run()
    text = json.dumps(report, indent=2)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text+'\n', encoding='utf-8')
    print(f"{report['passed']} independent checks passed; {report['failed']} failed.")
    print(json.dumps(report['certificate_precision_table'], indent=2))

if __name__ == '__main__':
    main()
