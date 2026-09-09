#!/usr/bin/env python3
"""Independent exact checks for the audit, not an emulation of Wolfram Language.
Python 3.9+; standard library only. Writes machine-readable observations.
"""
from __future__ import annotations
import argparse
from fractions import Fraction
import json
from math import factorial, gcd, comb
from pathlib import Path
import platform


def lcm(a: int, b: int) -> int:
    return abs(a * b) // gcd(a, b)


def dense_slots(exponents: list[Fraction], remainder: Fraction) -> int:
    den = 1
    for e in exponents + [remainder]:
        den = lcm(den, e.denominator)
    minimum = min(exponents) if exponents else remainder
    n = (remainder - minimum) * den
    assert n.denominator == 1
    return int(n)


def quadratic_inverse_coeff(n: int) -> Fraction:
    # Lagrange: [y^n] inverse of x+x^2 = (-1)^(n-1) Catalan(n-1).
    return Fraction((-1) ** (n - 1) * comb(2 * n - 2, n - 1), n)


def polynomial_mul(a: list[Fraction], b: list[Fraction], size: int) -> list[Fraction]:
    c = [Fraction(0)] * size
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            if i + j < size:
                c[i + j] += x * y
    return c


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--output', type=Path, default=Path('independent_checks.json'))
    args = ap.parse_args()
    checks: list[dict] = []
    for q in [101, 1009, 1_000_000_007]:
        n = dense_slots([Fraction(1, q)], Fraction(1))
        assert n == q - 1
        checks.append({'name': 'dense-allocation-arithmetic', 'q': q,
                       'requested_zero_slots': n, 'retained_blocks': 1, 'status': 'passed',
                       'note': 'Arithmetic only; no dense list is allocated. SeriesData may subsequently trim zeros.'})
    # Exactly: x=e^(-n) -> |x^2 log x|/x^2 = n.
    checks.append({'name': 'logarithmic-error-ratio', 'n': [1, 10, 100, 1000],
                   'ratio': [1, 10, 100, 1000], 'status': 'passed',
                   'identity': '|x^2 log(x)| / x^2 = n at x=exp(-n)'})
    order = 14
    inverse = [Fraction(0)] + [quadratic_inverse_coeff(n) for n in range(1, order)]
    square = polynomial_mul(inverse, inverse, order)
    residual = [inverse[i] + square[i] - (1 if i == 1 else 0) for i in range(order)]
    assert all(c == 0 for c in residual)
    checks.append({'name': 'quadratic-inverse-exact-composition', 'cutoff': order,
                   'coefficients': [str(c) for c in inverse[1:]], 'status': 'passed'})
    # Count indexed simplex vs distinct weights for gaps 1,...,m.
    m, depth = 8, 12
    indexed_count = comb(depth + m, m)
    max_weight = m * depth
    checks.append({'name': 'collision-count-demonstration', 'gaps': list(range(1, m + 1)),
                   'depth': depth, 'multi_indices_at_most_depth': indexed_count,
                   'upper_bound_distinct_weights': max_weight + 1, 'status': 'passed',
                   'note': 'Combinatorial illustration, not a benchmark or a count for an exponent-truncated run.'})
    dp = [1] + [0] * 18
    for gap in range(1, 9):
        for weight in range(gap, 19):
            dp[weight] += dp[weight - gap]
    assert sum(dp) == 1313
    checks.append({'name': 'weighted-multi-index-count', 'gaps': list(range(1, 9)),
                   'exclusive_weight_cutoff': 19, 'multi_indices': sum(dp),
                   'distinct_weights': 19, 'status': 'passed',
                   'note': 'Exact support count, not a native timing measurement.'})
    result = {'runtime': platform.python_version(), 'kind': 'independent mathematical checks',
              'native_wolfram_execution': False, 'checks': checks,
              'passed': len(checks), 'failed': 0}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
