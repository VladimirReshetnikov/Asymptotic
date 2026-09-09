#!/usr/bin/env python3
"""Small exact checker for forall x in [lo,hi]: a*x+b REL 0.

This is a proof-of-design for certificate domain evidence. It does NOT
verify a complete Asymptotic inverse certificate, nonlinear domains, or
Wolfram evaluation. All numeric inputs are exact fractions/integers.
There is no ambient-assumption parameter and no eval of user text.
"""
from __future__ import annotations
from fractions import Fraction
from typing import Any

RELATIONS = {"<", "<=", ">", ">=", "==", "!="}


def rational(value: Any) -> Fraction:
    if isinstance(value, bool) or isinstance(value, float):
        raise TypeError("Use an exact integer, fraction, or rational string, not a float/bool.")
    if not isinstance(value, (int, Fraction, str)):
        raise TypeError("Unsupported rational representation")
    return Fraction(value)


def relation_holds(value: Fraction, relation: str) -> bool:
    if relation not in RELATIONS:
        raise ValueError("Unsupported relation")
    return {"<": value < 0, "<=": value <= 0, ">": value > 0,
            ">=": value >= 0, "==": value == 0, "!=": value != 0}[relation]


def prove_affine(a: Any, b: Any, relation: str, lo: Any, hi: Any) -> dict[str, Any]:
    a, b, lo, hi = map(rational, (a, b, lo, hi))
    if lo > hi:
        raise ValueError("Reversed closed interval")
    if relation not in RELATIONS:
        raise ValueError("Unsupported relation")
    endpoints = [a*lo+b, a*hi+b]
    lower, upper = min(endpoints), max(endpoints)
    proved = {
        "<": upper < 0, "<=": upper <= 0,
        ">": lower > 0, ">=": lower >= 0,
        "==": lower == 0 and upper == 0,
        "!=": upper < 0 or lower > 0,
    }[relation]
    witness = None
    if not proved:
        candidates = [lo, hi]
        if a and lo <= -b/a <= hi:
            candidates.append(-b/a)
        witness = next(x for x in candidates if not relation_holds(a*x+b, relation))
    return {
        "schema": "AffineClosedIntervalProof/1",
        "quantifier": "ForAll",
        "condition": {"a": str(a), "b": str(b), "relation": relation},
        "interval": [str(lo), str(hi)],
        "range": [str(lower), str(upper)],
        "status": "Proved" if proved else "Disproved",
        "counterexample": None if witness is None else str(witness),
        "assumptions": [],
        "arithmetic": "Exact rational endpoints; affine range is attained",
    }


def verify_affine(record: dict[str, Any]) -> bool:
    """Recompute all evidence; do not trust a claimed status or cached range."""
    try:
        c = record["condition"]
        expected = prove_affine(c["a"], c["b"], c["relation"], *record["interval"])
        return record == expected
    except (KeyError, TypeError, ValueError, ZeroDivisionError):
        return False


if __name__ == "__main__":
    import json
    print(json.dumps(prove_affine(1, "-1/4", "<", "9/10", "11/10"), indent=2))
