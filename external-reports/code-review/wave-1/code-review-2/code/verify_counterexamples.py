#!/usr/bin/env python3
"""Independent mathematical witnesses for the Asymptotic 1.8.0 review.

This does NOT load or emulate the Wolfram package. It checks the mathematics
behind source-traced findings, a proposed bound, and resource-size estimates.
Python 3.10+; dependencies: sympy, mpmath. No network access is used.
"""
from __future__ import annotations
import argparse
import csv
import json
import math
import platform
import random
from fractions import Fraction as F
from pathlib import Path
from typing import Dict, Tuple
import mpmath as mp
import sympy as sp

COMMIT = "07a9781212beb2eeb9ff16aa625b50ac27974078"
Jet = Dict[Tuple[int, int], F]  # (power of x, power of L) -> rational coefficient

def add(a: Jet, b: Jet) -> Jet:
    out = dict(a)
    for key, value in b.items():
        out[key] = out.get(key, F(0)) + value
        if not out[key]:
            del out[key]
    return out

def multiply(a: Jet, b: Jet, maximum: int) -> Jet:
    out: Jet = {}
    for (pa, la), ca in a.items():
        for (pb, lb), cb in b.items():
            if pa + pb <= maximum:
                key = (pa + pb, la + lb)
                out[key] = out.get(key, F(0)) + ca * cb
    return {k: v for k, v in out.items() if v}

def boundary_degree(a: Jet, p: int) -> int:
    return max((d for (e, d), c in a.items() if e == p and c), default=0)

def exp_jet(a: Jet, maximum: int) -> Jet:
    """Exact finite coefficient calculation, including the boundary power."""
    if not a or min(e for e, _ in a) <= 0:
        raise ValueError("A positive-valuation, nonempty argument is required")
    alpha = min(e for e, _ in a)
    term: Jet = {(0, 0): F(1)}
    answer = dict(term)
    for k in range(1, maximum // alpha + 1):
        term = multiply(term, a, maximum)
        answer = add(answer, {key: value / math.factorial(k) for key, value in term.items()})
    return answer

def commensurate_generator(rates: list[F]) -> tuple[F, list[int]]:
    if not rates or any(r <= 0 for r in rates):
        raise ValueError("Rates must be positive")
    reference = min(rates)
    ratios = [r / reference for r in rates]
    denominator = math.lcm(*(r.denominator for r in ratios))
    integers = [int(r * denominator) for r in ratios]
    common = math.gcd(*integers)
    base = reference * F(common, denominator)
    degrees = [n // common for n in integers]
    assert all(base * n == r for n, r in zip(degrees, rates))
    return base, degrees

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "results")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    checks: list[dict] = []
    def check(name: str, condition: bool, detail: str = "") -> None:
        checks.append({"name": name, "passed": bool(condition), "detail": detail})
        if not condition:
            raise AssertionError(name + ": " + detail)

    x, L = sp.symbols("x L", real=True)
    source = 1 + x * L + x**2
    second_order = {
        "log": (sp.log(source), x * L, 1 - L**2 / 2),
        "exp": (sp.exp(x * L + x**2), 1 + x * L, 1 + L**2 / 2),
        "sqrt": (sp.sqrt(source), 1 + x * L / 2, sp.Rational(1, 2) - L**2 / 8),
        "reciprocal": (1 / source, 1 - x * L, L**2 - 1),
    }
    polynomials = {}
    for name, (function, retained, expected) in second_order.items():
        coefficient = sp.expand(sp.series(function - retained, x, 0, 3).removeO()).coeff(x, 2)
        check("F01-" + name + "-boundary-coefficient", sp.simplify(coefficient - expected) == 0)
        polynomials[name] = str(coefficient)
    check("F02-negative-source-square-root-is-not-real", sp.im(sp.sqrt(-sp.Rational(1, 100))) == sp.Rational(1, 10))
    q = 10**9
    check("F04-billion-denominator-width", q - 1 == 999_999_999)
    # This calculation allocates only a 41-element integer list.
    counts = [1] + [0] * 40
    for part in range(1, 21):
        for weight in range(part, 41):
            counts[weight] += counts[weight - part]
    check("F06-multi-index-count", sum(counts) == 207_042)
    check("F06-weight-count", len(counts) == 41)
    base, degrees = commensurate_generator([F(2), F(3)])
    check("F07-rates-2-3", base == 1 and degrees == [2, 3])
    base2, degrees2 = commensurate_generator([F(2, 3), F(4, 5)])
    check("F07-rational-rates", base2 == F(2, 15) and degrees2 == [5, 6])
    alpha, power, goal = 10, -1, 20
    check("F05-required-source-precision", goal - alpha * (power - 1) == 40)
    z = sp.symbols("z")
    inverse_sin = sp.series(1 / sp.sin(z), z, 0, 4).removeO()
    check("F05-independent-reciprocal-expansion", sp.expand(inverse_sin - (1/z + z/6 + 7*z**3/360)) == 0)

    # Randomized exact polynomial checks of the proposed central bound.
    # The old rule at requested cut > P is D_input. The proposed rule uses
    # max(D_input, ceil(P / valuation(U)) * max_log_degree(U)).
    rng = random.Random(20260909)
    underestimated = 0
    for case in range(250):
        P = rng.randint(2, 8)
        D = rng.randint(0, 3)
        U: Jet = {}
        for _ in range(rng.randint(1, 5)):
            key = (rng.randint(1, P - 1), rng.randint(0, 4))
            U = add(U, {key: F(rng.choice([-2, -1, 1, 2]))})
        if not U:
            U = {(1, 0): F(1)}
        alpha = min(e for e, _ in U)
        degree = max(d for _, d in U)
        full = exp_jet(add(U, {(P, D): F(1)}), P)
        actual = boundary_degree(full, P)
        proposed = max(D, math.ceil(F(P, alpha)) * degree)
        if actual > D:
            underestimated += 1
        check(f"F01-exact-bound-case-{case:03d}", proposed >= actual,
              f"P={P}, D={D}, alpha={alpha}, maxDegree={degree}, actual={actual}, proposed={proposed}")

    mp.mp.dps = 180
    numeric = []
    for t in (5, 10, 20, 40, 80):
        xx = mp.exp(-t)
        ll = mp.log(xx)
        functions = {
            "log": (mp.log1p(xx * ll + xx**2) - xx * ll) / xx**2,
            "exp": (mp.expm1(xx * ll + xx**2) - xx * ll) / xx**2,
            "sqrt": (mp.sqrt(1 + xx * ll + xx**2) - 1 - xx * ll/2) / xx**2,
            "reciprocal": (1/(1 + xx * ll + xx**2) - 1 + xx * ll) / xx**2,
        }
        row = {"t": t, "x": mp.nstr(xx, 24)}
        row.update({name + "_error_over_x2": mp.nstr(value, 24) for name, value in functions.items()})
        row["F03_export_error_over_x2"] = str(-t)  # x^2 log(x) / x^2
        numeric.append(row)
    with (args.output / "counterexample_ratios.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(numeric[0]))
        writer.writeheader(); writer.writerows(numeric)
    payload = {
        "repository_commit": COMMIT,
        "execution_scope": "Independent Python/SymPy mathematical checks; NO Wolfram package execution",
        "python": platform.python_version(), "sympy": sp.__version__, "mpmath": mp.__version__,
        "checks_passed": len(checks), "checks_failed": 0,
        "randomized_exact_cases": 250, "cases_exposing_old_degree_underestimate": underestimated,
        "F01_boundary_polynomials": polynomials,
        "F04_dense_entries_without_guard": q - 1,
        "F06_indices_below_weight_41": sum(counts), "F06_distinct_weights": 41,
        "numerical_rows": numeric, "checks": checks,
    }
    (args.output / "independent_checks.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: payload[key] for key in ("checks_passed", "checks_failed", "randomized_exact_cases", "cases_exposing_old_degree_underestimate")}, indent=2))

if __name__ == "__main__":
    main()
