#!/usr/bin/env python3
"""Independent checks for the Asymptotic 1.8.0 source audit.

This is NOT a Wolfram Language emulator and does NOT execute the repository.
It checks the mathematical counterexamples, selected coefficient identities,
and an allocation-planning policy. Only Python and SymPy are required.
"""
from __future__ import annotations
import argparse
import json
import math
import platform
from dataclasses import asdict, dataclass
from fractions import Fraction
from pathlib import Path
from typing import Iterable
import sympy as sp

COMMIT = "07a9781212beb2eeb9ff16aa625b50ac27974078"
L = sp.Symbol("L", real=True)
u = sp.Symbol("u", positive=True)

@dataclass(frozen=True)
class ExportPlan:
    status: str
    denominator: int | None = None
    minimum_index: int | None = None
    maximum_index: int | None = None
    required_slots: int | None = None


def plan_export(exponents: Iterable[Fraction], remainder_power: Fraction,
                log_degree: int, max_slots: int = 20000) -> ExportPlan:
    """Plan a conservative rational-lattice export without allocating its array."""
    if not isinstance(max_slots, int) or isinstance(max_slots, bool) or max_slots < 1:
        raise ValueError("max_slots must be a positive integer")
    if not isinstance(log_degree, int) or log_degree < 0:
        raise ValueError("log_degree must be a nonnegative integer")
    values = tuple(Fraction(e) for e in exponents)
    rem = Fraction(remainder_power)
    if any(e >= rem for e in values):
        raise ValueError("retained exponents must be strictly below the remainder")
    if log_degree:
        return ExportPlan("LogarithmicRemainder")
    denominator = math.lcm(*(v.denominator for v in values + (rem,)))
    low = int(min(values, default=rem) * denominator)
    high = int(rem * denominator)
    size = high - low
    return ExportPlan("Allowed" if size <= max_slots else "SeriesDataSizeLimit",
                      denominator, low, high, size)


def euler_coefficient(index: tuple[int, ...], gaps: tuple[sp.Expr, ...],
                      polynomials: tuple[sp.Expr, ...], p=sp.Integer(1),
                      r=sp.Integer(1)) -> sp.Expr:
    """Independent implementation of the audit's Euler-operator identity."""
    if len(index) != len(gaps) or len(index) != len(polynomials):
        raise ValueError("index, gaps, and polynomials must have equal lengths")
    if any(not isinstance(k, int) or k < 0 for k in index):
        raise ValueError("indices must be nonnegative integers")
    n = sum(index)
    if not n:
        return sp.Integer(1)
    weight = sum(k*d for k, d in zip(index, gaps))
    q = sp.prod(P**k for P, k in zip(polynomials, index))
    for j in range(1, n):
        q = sp.expand(sp.diff(q, L) + (r + weight + p*j)*q)
    return sp.expand((-1)**n*r*q/(p**n*sp.prod(sp.factorial(k) for k in index)))


def run_checks() -> dict:
    results: list[dict] = []
    def check(name: str, condition: bool, details=None) -> None:
        ok = bool(condition)
        results.append({"name": name, "passed": ok, "details": details})
        if not ok:
            raise AssertionError(name)

    # Classical reversion: inverse of x+x^2 has alternating Catalan coefficients.
    for n in range(9):
        value = euler_coefficient((n,), (sp.Integer(1),), (sp.Integer(1),))
        check(f"catalan_n_{n}", sp.simplify(value - (-1)**n*sp.catalan(n)) == 0,
              str(value))

    # Non-unit leading power: f(u)=u^2(1+u), z=sqrt(y).
    # Lagrange inversion gives [z^(n+1)]u(z) = [u^n](1+u)^(-(n+1)/2)/(n+1).
    for n in range(7):
        value = euler_coefficient((n,), (sp.Integer(1),), (sp.Integer(1),), p=sp.Integer(2))
        other = sp.binomial(-sp.Rational(n+1, 2), n)/(n+1)
        check(f"puiseux_n_{n}", sp.simplify(value - other) == 0, str(value))

    # Complete logarithmic polynomial, not an isolated monomial.
    c2 = euler_coefficient((2,), (sp.Integer(1),), (1+L,))
    check("complete_logarithmic_block", sp.expand(c2 - (2*L**2+5*L+3)) == 0, str(c2))

    # Colliding multi-index weights for f(u)=u+u^2+u^3.
    collisions = []
    for weight in range(7):
        contributions = [euler_coefficient((weight-2*k2, k2),
                         (sp.Integer(1), sp.Integer(2)),
                         (sp.Integer(1), sp.Integer(1)))
                         for k2 in range(weight//2 + 1)]
        grouped = sp.expand(sum(contributions))
        ordinary = sp.series((1+u+u**2)**(-(weight+1)), u, 0, weight+1).removeO().coeff(u, weight)/(weight+1)
        check(f"weight_collision_{weight}", sp.simplify(grouped-ordinary) == 0, str(grouped))
        collisions.append({"weight": weight, "coefficient": str(grouped), "index_count": len(contributions)})

    alpha = sp.sqrt(2)
    c3 = euler_coefficient((3,), (alpha-1,), (sp.Integer(1),))
    check("irrational_third_correction", sp.simplify(c3 + alpha*(3*alpha-1)/2) == 0, str(c3))

    # The omitted x^2 log(x) is not O(x^2); every positive power absorbs a fixed log.
    check("log_error_not_plain_big_O", sp.limit(sp.log(u), u, 0, dir="+") == -sp.oo,
          "(u^2 log(u))/u^2 -> -Infinity")
    check("strict_power_loss_absorbs_log", sp.limit(sp.sqrt(u)*sp.log(u), u, 0, dir="+") == 0,
          "u^(1/2) log(u) -> 0")
    check("negative_square_has_no_real_square_root", sp.simplify(sp.sqrt(-u**2)-sp.I*u) == 0,
          "principal sqrt(-u^2) = I*u for u>0; no real square root exists")

    # A value remainder alone does not license derivative transport.
    bad = u**2*sp.sin(u**-3)
    derivative = sp.diff(bad, u)
    check("derivative_counterexample_identity",
          sp.simplify(derivative-(2*u*sp.sin(u**-3)-3*u**-2*sp.cos(u**-3))) == 0,
          str(derivative))

    # Lost assumptions change an exact expression away from the assumed parameter locus.
    a = sp.Symbol("a")
    error_after_forgetting = a*u + u**2 - u**2
    check("forgotten_assumption_changes_function",
          error_after_forgetting.subs({a: 1, u: sp.Rational(1,10)}) == sp.Rational(1,10),
          "Dropping a*u under a==0 is invalid after discarding a==0; this is an algebra check, not a WL execution.")

    allocation_examples = []
    for denominator in (101, 1009, 20011, 10**9):
        plan = plan_export((Fraction(1, denominator),), Fraction(1), 0)
        check(f"sparse_lattice_slots_{denominator}", plan.required_slots == denominator-1)
        allocation_examples.append({"N": denominator, **asdict(plan)})
    check("log_export_rejected", plan_export((Fraction(1),), Fraction(2), 1).status == "LogarithmicRemainder")
    check("ordinary_export_allowed", plan_export((Fraction(1), Fraction(2)), Fraction(3), 0).status == "Allowed")
    check("huge_export_blocked_before_allocation", allocation_examples[-1]["status"] == "SeriesDataSizeLimit")
    check("pure_remainder_no_allocation", plan_export((), Fraction(2), 0).required_slots == 0)
    try:
        plan_export((Fraction(2),), Fraction(2), 0)
    except ValueError:
        invalid_rejected = True
    else:
        invalid_rejected = False
    check("invalid_frontier_rejected", invalid_rejected)

    # Exact residual/derivative certificate for x+x^2=1/10, independent of the package.
    target = Fraction(1,10); center = Fraction(9,100)
    interval = (Fraction(2,25), Fraction(1,10))
    derivative_interval = (1+2*interval[0], 1+2*interval[1])
    residual = center+center*center-target
    radius = abs(residual)/derivative_interval[0]
    bracket = (center-radius, center+radius)
    check("certificate_residual_bracket_contained", interval[0] <= bracket[0] <= bracket[1] <= interval[1])
    check("certificate_exact_endpoint_signs", bracket[0]+bracket[0]**2 <= target <= bracket[1]+bracket[1]**2)
    correction = sorted((residual/derivative_interval[0], residual/derivative_interval[1]))
    sharp = (max(interval[0], bracket[0], center-correction[1]),
             min(interval[1], bracket[1], center-correction[0]))
    # This containment follows from the mean-value identity; endpoint signs need not be rounded.
    check("certificate_sharpening_nested", bracket[0] <= sharp[0] <= sharp[1] <= bracket[1])

    return {
        "scope": "Independent mathematical and allocation-policy checks; not execution of the Wolfram package",
        "repository_commit": COMMIT,
        "python_version": platform.python_version(), "sympy_version": sp.__version__,
        "native_wolfram_executed": False,
        "passed": len(results), "failed": 0,
        "checks": results,
        "allocation_examples": allocation_examples,
        "collision_examples": collisions,
        "certificate_example": {"target": str(target), "center": str(center),
            "residual": str(residual), "derivative_interval": list(map(str, derivative_interval)),
            "radius": str(radius), "root_enclosure": list(map(str, sharp))}
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("mathematical_checks.json"))
    args = parser.parse_args()
    report = run_checks()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
    print(f'{report["passed"]} independent checks passed; no Wolfram package execution.')
    print(args.output)

if __name__ == "__main__":
    main()
