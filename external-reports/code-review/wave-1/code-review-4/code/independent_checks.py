#!/usr/bin/env python3
"""Exact independent witnesses. These checks DO NOT execute Wolfram Language."""
from __future__ import annotations
import argparse
from fractions import Fraction
from math import factorial, lcm
import json
from pathlib import Path
import platform
import sympy as sp


def dense_plan(weights: list[Fraction], frontier: Fraction, limit: int = 20000) -> dict:
    if not isinstance(limit, int) or isinstance(limit, bool) or limit < 1:
        raise ValueError("limit must be a positive integer")
    if not all(isinstance(w, Fraction) for w in weights) or not isinstance(frontier, Fraction):
        raise TypeError("weights and frontier must be fractions.Fraction instances")
    if any(w >= frontier for w in weights):
        raise ValueError("every retained weight must be strictly below the frontier")
    denominator = lcm(*(w.denominator for w in weights), frontier.denominator)
    start = min(weights, default=frontier) * denominator
    end = frontier * denominator
    assert start.denominator == end.denominator == 1
    slots = int(end - start)
    return {"denominator": denominator, "nmin": int(start), "nmax": int(end),
            "required_slots": slots, "stored_blocks": len(weights),
            "slot_limit": limit, "admissible": slots <= limit,
            "eight_bytes_per_slot_model": 8 * slots}


def inverse_coefficients(order: int = 5):
    """For f(x)=x+x^(1+d), inverse is y*W(y^d), W+t*W^(1+d)=1."""
    d, t = sp.symbols("d t")
    coefficients = [sp.Integer(1)]
    for n in range(1, order + 1):
        coefficients.append(sp.factor(sp.Rational((-1)**n, factorial(n)) * sp.prod(1+n*d+j for j in range(1, n))))
    w = sum(c*t**n for n, c in enumerate(coefficients))
    # Independently compose using the binomial identity, without the package's Euler recurrence.
    h = w - 1
    composed_power = sum(sp.Rational(1, factorial(k))*sp.prod(1+d-j for j in range(k)) * h**k
                         for k in range(order))
    residual = sp.Poly(sp.expand(w + t*composed_power - 1), t)
    checks = [sp.factor(residual.coeff_monomial(t**n)) == 0 for n in range(order+1)]
    return d, coefficients, checks


def run_checks() -> dict:
    large = dense_plan([Fraction(1,10007), Fraction(1,10009)], Fraction(1))
    assert large["denominator"] == 100160063
    assert large["nmin"] == 10007
    assert large["required_slots"] == 100150056
    assert not large["admissible"]
    small = dense_plan([Fraction(1,101), Fraction(1,103)], Fraction(1))
    assert small["required_slots"] == 10302 and small["admissible"]
    d, coeffs, checks = inverse_coefficients(5)
    assert all(checks)
    x = sp.Symbol("x", positive=True)
    assert sp.simplify(sp.sqrt(-x*x) - sp.I*x) == 0
    # The candidate correction sequence is identically zero after one step for a=0,Q0=1.
    ell = sp.Symbol("ell")
    q = sp.Integer(1)
    recurrence = []
    for k in range(5):
        q = sp.expand(((0-k)*q+sp.diff(q,ell))/(k+1))
        recurrence.append(str(q))
    assert recurrence == ["0"]*5
    # Exact multiplicity of a colliding semigroup layer.
    collision = [(i,j) for i in range(3) for j in range(2) if i+2*j == 2]
    assert collision == [(0,1),(2,0)]
    # Differentiate an O(x^2) witness; the x^-3 term prevents O(x) derivative control.
    r = x**2 * sp.sin(x**-4)
    derivative = sp.diff(r,x)
    assert sp.simplify(derivative - (2*x*sp.sin(x**-4)-4*x**-3*sp.cos(x**-4))) == 0
    return {
        "status": "PASS", "scope": "Independent exact Python/SymPy mathematics; NOT a package test",
        "python": platform.python_version(), "sympy": sp.__version__,
        "dense_large": large, "dense_small": small,
        "inverse_coefficients": [str(c) for c in coeffs],
        "inverse_residual_coefficients_zero_through_order_5": checks,
        "pure_remainder_branch_witness": "sqrt(-x^2)=I*x for real x>0",
        "zero_coefficient_recurrence": recurrence,
        "weight_2_collisions_for_gaps_1_2": collision,
        "derivative_witness": str(derivative),
        "provenance_binary_tree_nodes": {str(n): 2**(n+1)-1 for n in (5,10,20,30)},
        "large_dense_array_allocated": False,
        "wolfram_kernel_executed": False
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    report = run_checks()
    text = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    print(text)

if __name__ == "__main__":
    main()
