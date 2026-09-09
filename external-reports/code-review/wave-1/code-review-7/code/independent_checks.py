#!/usr/bin/env python3
"""Independent mathematical checks for the Asymptotic audit.

This is NOT a Wolfram Language emulator and does not run the repository.
Dependencies: sympy, mpmath. All checks are bounded; the dense-span test never
allocates the inferred large Wolfram coefficient arrays.
"""
from __future__ import annotations
import argparse
from fractions import Fraction as F
from functools import reduce
from math import gcd, lcm, factorial
from pathlib import Path
import json
import platform
import unittest
import mpmath as mp
import sympy as sp

L = sp.Symbol("L", real=True)


def dense_span(exponents: list[F], remainder: F) -> int:
    """Length of the lattice array constructed by makeSeriesData."""
    denominator = lcm(*(q.denominator for q in [*exponents, remainder]))
    minimum = min(exponents) if exponents else remainder
    span = (remainder - minimum) * denominator
    if span.denominator != 1 or span < 0:
        raise ValueError("Nonintegral or negative span")
    return span.numerator


def dense_allowed(exponents: list[F], remainder: F, cap: int = 100_000) -> bool:
    if not isinstance(cap, int) or isinstance(cap, bool) or cap < 0:
        raise ValueError("cap must be a nonnegative integer")
    return dense_span(exponents, remainder) <= cap


def rational_rate_lattice(rates: list[F]) -> tuple[F, list[int]]:
    """Largest positive rational fundamental rate, without dense enumeration."""
    if not rates or any(r <= 0 for r in rates):
        raise ValueError("Positive rates required")
    denominator = lcm(*(r.denominator for r in rates))
    numerators = [int(r * denominator) for r in rates]
    fundamental = F(reduce(gcd, numerators), denominator)
    return fundamental, [int(r / fundamental) for r in rates]


def lagrange_block(k: tuple[int, ...], gaps: tuple[sp.Expr, ...],
                   polynomials: tuple[sp.Expr, ...], p: sp.Expr = sp.S.One,
                   r: sp.Expr = sp.S.One) -> tuple[sp.Expr, sp.Expr]:
    """Independent transcription of the Euler-operator coefficient identity."""
    if len(k) != len(gaps) or len(k) != len(polynomials) or any(i < 0 for i in k):
        raise ValueError("Invalid multi-index")
    n = sum(k)
    if n == 0:
        return sp.S.Zero, sp.S.One
    w = sp.simplify(sum(i * d for i, d in zip(k, gaps)))
    q = sp.expand(sp.prod(P**i for P, i in zip(polynomials, k)))
    for j in range(1, n):
        q = sp.expand(sp.diff(q, L) + (r + w + p*j)*q)
    q *= (-1)**n * r / (p**n * sp.prod(sp.factorial(i) for i in k))
    return w, sp.expand(q)


def elliptic_samples() -> list[dict[str, str | int]]:
    """mpmath uses the parameter m, as does WL EllipticK[m], not modulus k."""
    rows = []
    with mp.workdps(110):
        for k in (1, 2, 4, 6, 8, 12):
            u = mp.mpf(10) ** (-k)
            log = mp.log(4/u)
            approximation = log + u*u*(log - 1)/4
            remainder = mp.ellipk(1-u*u) - approximation
            rows.append({
                "decimal_exponent": k,
                "u": f"1e-{k}",
                "remainder_over_u4": mp.nstr(remainder/u**4, 22),
                "remainder_over_u4_log_1_u": mp.nstr(remainder/(u**4*mp.log(1/u)), 22),
                "remainder_over_u_7_over_2": mp.nstr(remainder/u**mp.mpf("3.5"), 22),
            })
    return rows


def interval_example() -> dict[str, str]:
    """Exact rational residual-to-root bound for f(x)=x+x^2, target 1/100."""
    lo, hi, c, y = F(9, 1000), F(11, 1000), F(99, 10000), F(1, 100)
    residual = c + c*c - y
    mu = 1 + 2*lo
    radius = abs(residual)/mu
    assert lo <= c-radius <= c+radius <= hi
    assert lo + lo*lo < y < hi + hi*hi
    return {"target": str(y), "center": str(c), "residual": str(residual),
            "derivative_lower_bound": str(mu), "radius": str(radius),
            "lower_endpoint": str(c-radius), "upper_endpoint": str(c+radius)}


class IndependentChecks(unittest.TestCase):
    def test_sparse_span_scales_with_denominator(self):
        for n in (10, 1000, 10**6, 10**9):
            self.assertEqual(dense_span([F(0), F(1, n)], F(1)), n)

    def test_dense_guard_is_bounded(self):
        self.assertTrue(dense_allowed([F(0), F(1, 1000)], F(1)))
        self.assertFalse(dense_allowed([F(0), F(1, 10**9)], F(1)))

    def test_empty_dense_span(self):
        self.assertEqual(dense_span([], F(3, 2)), 0)

    def test_rational_gcd_rates(self):
        self.assertEqual(rational_rate_lattice([F(2), F(3)]), (F(1), [2, 3]))
        self.assertEqual(rational_rate_lattice([F(2, 3), F(4, 5)]), (F(2, 15), [5, 6]))
        self.assertEqual(rational_rate_lattice([F(6), F(9)]), (F(3), [2, 3]))

    def test_rate_validation(self):
        for rates in ([], [F(0)], [F(-1), F(2)]):
            with self.assertRaises(ValueError):
                rational_rate_lattice(rates)

    def test_catalan_inverse_coefficients(self):
        for n in range(10):
            _, q = lagrange_block((n,), (sp.S.One,), (sp.S.One,))
            self.assertEqual(q, (-1)**n * sp.catalan(n))

    def test_independent_polynomial_inverse_composition(self):
        y = sp.Symbol("y")
        approximation = sum((-1)**n*sp.catalan(n)*y**(n+1) for n in range(9))
        self.assertEqual(sp.series(approximation+approximation**2-y, y, 0, 10).removeO(), 0)

    def test_logarithmic_euler_blocks(self):
        self.assertEqual(lagrange_block((1,), (sp.S.One,), (1+L,))[1], -1-L)
        self.assertEqual(lagrange_block((2,), (sp.S.One,), (1+L,))[1], 2*L**2+5*L+3)

    def test_irrational_blocks(self):
        beta = sp.sqrt(2)
        gap = beta - 1
        self.assertEqual(lagrange_block((1,), (gap,), (sp.S.One,))[1], -1)
        self.assertEqual(sp.simplify(lagrange_block((2,), (gap,), (sp.S.One,))[1]-beta), 0)
        expected = -beta*(3*beta-1)/2
        self.assertEqual(sp.simplify(lagrange_block((3,), (gap,), (sp.S.One,))[1]-expected), 0)

    def test_resonance_merging(self):
        # f=u(1+a*u+b*u^2): weight 2 receives k=(2,0) and k=(0,1).
        a, b = sp.symbols("a b")
        _, first = lagrange_block((2, 0), (sp.S.One, sp.Integer(2)), (a, b))
        _, second = lagrange_block((0, 1), (sp.S.One, sp.Integer(2)), (a, b))
        self.assertEqual(sp.expand(first+second), 2*a*a-b)

    def test_elliptic_tail_coefficients(self):
        # DLMF 19.12.1/3, converted from modulus to parameter 1-u^2.
        self.assertEqual(sp.rf(sp.Rational(1, 2), 2)**2 / sp.factorial(2)**2, sp.Rational(9,64))
        decrement = sum(sp.Rational(2, (2*j+1)*(2*j+2)) for j in range(2))
        self.assertEqual(decrement, sp.Rational(7, 6))

    def test_elliptic_tail_numerics(self):
        rows = elliptic_samples()
        divergent = [mp.mpf(row["remainder_over_u4"]) for row in rows]
        absorbed = [mp.mpf(row["remainder_over_u_7_over_2"]) for row in rows]
        self.assertTrue(all(a < b for a, b in zip(divergent, divergent[1:])))
        self.assertLess(absorbed[-1], absorbed[0]/1000)
        self.assertLess(abs(mp.mpf(rows[-1]["remainder_over_u4_log_1_u"])-mp.mpf(9)/64), mp.mpf("0.002"))

    def test_no_real_square_root_of_negative_input(self):
        u = sp.Symbol("u", positive=True)
        self.assertEqual(sp.simplify(sp.im(sp.sqrt(-u))), sp.sqrt(u))

    def test_exact_interval_example(self):
        example = interval_example()
        with mp.workdps(70):
            root = (mp.sqrt(mp.mpf("1.04"))-1)/2
            def to_mp(x: str):
                q = F(x)
                return mp.mpf(q.numerator)/q.denominator
            self.assertLess(to_mp(example["lower_endpoint"]), root)
            self.assertLess(root, to_mp(example["upper_endpoint"]))

    def test_value_bound_does_not_imply_derivative_bound(self):
        u = sp.Symbol("u", positive=True)
        remainder = u*u*sp.sin(1/u**2)
        self.assertEqual(sp.diff(remainder, u), 2*u*sp.sin(u**(-2))-2*sp.cos(u**(-2))/u)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1]/"results")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(IndependentChecks)
    with (args.output/"independent-tests.txt").open("w", encoding="utf-8") as log:
        result = unittest.TextTestRunner(stream=log, verbosity=2).run(suite)
    summary = {
        "scope": "Independent Python/SymPy/mpmath checks; no repository WL execution",
        "python": platform.python_version(), "sympy": sp.__version__, "mpmath": mp.__version__,
        "tests_run": result.testsRun, "failures": len(result.failures), "errors": len(result.errors),
        "passed": result.wasSuccessful(), "elliptic_samples": elliptic_samples(),
        "dense_spans": [{"n": n, "dense_entries": dense_span([F(0), F(1,n)], F(1))} for n in (1000, 10**6, 10**9)],
        "interval_example": interval_example(),
    }
    (args.output/"independent-results.json").write_text(json.dumps(summary, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({key: summary[key] for key in ("tests_run", "failures", "errors", "passed")}, indent=2))
    return 0 if result.wasSuccessful() else 1

if __name__ == "__main__":
    raise SystemExit(main())
