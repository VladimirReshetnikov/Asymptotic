#!/usr/bin/env python3
"""Independent exact arithmetic and patch-fixture checks; never executes Wolfram.

All model checks are separate from package acceptance. Uses only Python's
standard library. The geometric oracle is an exact identity, not a numerical
fit, and the finite-demand tests use Fraction throughout.
"""
from __future__ import annotations
import argparse
from fractions import Fraction as F
import json
from pathlib import Path
import platform
from observable_order_patch import ANCHOR, PRECONDITION, INSERT, transform


def ceil_fraction(x: F) -> int:
    return -((-x.numerator) // x.denominator)


def required_endpoint(cutoff: F, valuation: F) -> int:
    if cutoff <= 0 or valuation <= 0:
        raise ValueError("This planner models a positive cutoff and positive valuation.")
    return ceil_fraction(cutoff / valuation)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    ns = parser.parse_args()
    records: list[dict] = []
    def check(name: str, condition: bool, population: str, **data: object) -> None:
        if not condition:
            raise AssertionError(name)
        records.append({"name": name, "population": population, "passed": True, **data})

    ratios = []
    for denominator in (10, 100, 1000, 10000):
        x = F(1, denominator)
        exact = 1 / (1 - x)
        bad_polynomial = 1 + x
        error = exact - bad_polynomial
        check(f"geometric-remainder-{denominator}",
              error == x*x/(1-x), "exact-rational-identity")
        ratio = error/(x**3)
        ratios.append({"x": str(x), "error": str(error), "error_div_x_cubed": str(ratio)})
        check(f"false-cubic-bound-growth-{denominator}", ratio > 1/x,
              "exact-rational-inequality")

    alphas = [F(1,4), F(1,3), F(1,2), F(2,3), F(1), F(3,2), F(2), F(3)]
    cuts = [F(1,2), F(1), F(3,2), F(2), F(5,2), F(3), F(4), F(5), F(7)]
    for alpha in alphas:
        for cutoff in cuts:
            n = required_endpoint(cutoff, alpha)
            needed = [k for k in range(n + 3) if F(k)*alpha < cutoff]
            check(f"largest-needed-{alpha}-{cutoff}", max(needed) == n-1,
                  "rational-demand-model")
            for q in range(1, n + 3):
                check(f"endpoint-equivalence-{alpha}-{cutoff}-{q}",
                      (q >= n) == (F(q)*alpha >= cutoff), "rational-demand-model")
                if q < n:
                    check(f"unknown-required-coefficient-{alpha}-{cutoff}-{q}",
                          q in needed, "rational-demand-model")

    # Independent sparse rational-power composition of a geometric polynomial.
    # Each coefficient before the first unknown term is exactly one.
    for alpha in alphas:
        for q in range(1, 8):
            coefficients = {alpha*k: F(1) for k in range(q)}
            product: dict[F, F] = {}
            for exponent, coefficient in coefficients.items():
                product[exponent] = product.get(exponent, F(0)) + coefficient
                nxt = exponent + alpha
                product[nxt] = product.get(nxt, F(0)) - coefficient
            product = {e:c for e,c in product.items() if c}
            check(f"geometric-sparse-identity-{alpha}-{q}",
                  product == {F(0):F(1), alpha*q:F(-1)}, "exact-sparse-polynomial-model")

    # Patch tests use only a deliberately tiny source fixture, not the repository.
    fixture = "(* fixture prefix *)\n" + PRECONDITION + "\n" + ANCHOR + "\n(* fixture suffix *)\n"
    patched = transform(fixture)
    check("patch-inserts-once", patched.count("Review T01:") == 1, "synthetic-patch-fixture")
    check("patch-preserves-original-regularity", PRECONDITION in patched, "synthetic-patch-fixture")
    check("patch-has-minimal-endpoint-guard", "native[[5]] >= n" in patched, "synthetic-patch-fixture")
    check("patch-only-inserts", patched.replace(INSERT, "", 1) == fixture, "synthetic-patch-fixture")
    for name, text in [("already-patched", patched), ("missing", ""),
                       ("ambiguous", fixture + fixture), ("displaced", fixture.replace(ANCHOR, "gap\n"+ANCHOR))]:
        caught = False
        try:
            transform(text)
        except ValueError:
            caught = True
        check(f"patch-refuses-{name}", caught, "synthetic-patch-fixture")

    counts: dict[str,int] = {}
    for rec in records:
        counts[rec["population"]] = counts.get(rec["population"], 0) + 1
    result = {
        "python_version": platform.python_version(),
        "repository_revision": "6687962f3c858a4f93623cfc496f33e35c6763d4",
        "native_package_executed": False,
        "native_patch_executed": False,
        "scope": "Exact independent rational/sparse models and a synthetic text-patch fixture only.",
        "checks_passed": len(records), "checks_failed": 0,
        "populations": counts, "witness_ratios": ratios, "checks": records
    }
    payload = json.dumps(result, indent=2) + "\n"
    if ns.output:
        ns.output.parent.mkdir(parents=True, exist_ok=True)
        ns.output.write_text(payload, encoding="utf-8")
    print(json.dumps({k: result[k] for k in ("python_version", "checks_passed", "checks_failed", "populations", "native_package_executed")}, indent=2))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
