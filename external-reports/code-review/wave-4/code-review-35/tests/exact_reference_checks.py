#!/usr/bin/env python3
"""Independent exact models, NOT execution of Wolfram Language or Mathics.

These validate mathematical witnesses and the narrow candidate algorithms.
They do not establish the public package's outputs or wall-clock performance.
"""
from __future__ import annotations
import argparse
from collections import defaultdict
from fractions import Fraction as F
import json
from math import comb
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[1]
SIGNS = {">": {1}, ">=": {0, 1}, "<": {-1}, "<=": {-1, 0}, "==": {0}, "!=": {-1, 1}}

def sign(value: F) -> int:
    return (value > 0) - (value < 0)

def affine_radius(clauses: list[tuple[F, F, str]]) -> F | None:
    radius = F(1)
    for a, b, relation in clauses:
        leading = sign(a) if a else sign(b)
        if leading not in SIGNS[relation]:
            return None
        if a and b:
            radius = min(radius, abs(a / (2 * b)))
    return radius

def affine_interval_truth(a: F, b: F, relation: str, radius: F) -> bool:
    # Independent whole-interval oracle: affine values are strict convex
    # combinations of the endpoint values on a deleted OPEN interval.
    left, right = a, a + b * radius
    positive = left >= 0 and right >= 0 and (left > 0 or right > 0)
    negative = left <= 0 and right <= 0 and (left < 0 or right < 0)
    zero = left == right == 0
    return {">": positive, ">=": left >= 0 and right >= 0,
            "<": negative, "<=": left <= 0 and right <= 0,
            "==": zero, "!=": positive or negative}[relation]

def sparse_rules(terms: list[tuple[int, F]]) -> list[tuple[int, F]]:
    answer: dict[int, F] = defaultdict(F)
    for degree, coefficient in terms:
        if degree < 0:
            raise ValueError("Polynomial exponents must be nonnegative")
        answer[degree] += coefficient
    return sorted(((degree, value) for degree, value in answer.items() if value), reverse=True)

def dense_rules(terms: list[tuple[int, F]]) -> list[tuple[int, F]]:
    if not terms:
        return []
    coefficients = [F(0)] * (max(degree for degree, _ in terms) + 1)
    for degree, value in terms:
        coefficients[degree] += value
    return [(degree, value) for degree, value in reversed(list(enumerate(coefficients))) if value]

def run_checks() -> dict:
    rng = random.Random(20260909)
    sparse_count = 0
    for degree in range(65):
        for _ in range(5):
            terms = [(rng.randrange(degree + 1), F(rng.randrange(-9, 10), rng.randrange(1, 8)))
                     for _ in range(rng.randrange(0, 15))]
            assert sparse_rules(terms) == dense_rules(terms)
            sparse_count += 1
    huge_degree = 10**9
    assert sparse_rules([(0, F(1)), (huge_degree, F(1))]) == [(huge_degree, F(1)), (0, F(1))]
    family = []
    for exponent in range(1, 161):
        epsilon = F(1, 2**exponent)
        clauses = [(-epsilon, F(1), "<")]
        current_grid = any(affine_interval_truth(*clauses[0], F(1, 2**j)) for j in range(7))
        radius = affine_radius(clauses)
        assert radius is not None and affine_interval_truth(*clauses[0], radius)
        assert current_grid == (exponent <= 6)
        family.append({"Exponent": exponent, "SevenRadiusGridProves": current_grid,
                       "CandidateRadius": str(radius)})
    random_clause_count = 0
    proved = 0
    for _ in range(600):
        clauses = [(F(rng.randrange(-20, 21), rng.randrange(1, 11)),
                    F(rng.randrange(-20, 21), rng.randrange(1, 11)),
                    rng.choice(list(SIGNS))) for _ in range(rng.randrange(1, 6))]
        radius = affine_radius(clauses)
        expected = all((sign(a) if a else sign(b)) in SIGNS[relation] for a, b, relation in clauses)
        assert (radius is not None) == expected
        if radius is not None:
            assert radius > 0 and all(affine_interval_truth(a, b, relation, radius) for a, b, relation in clauses)
            proved += 1
        random_clause_count += 1
    scaled_count = 0
    for exponent in (1, 7, 20, 100, 160):
        for scale_exponent in (-100, -7, 0, 7, 100):
            a, b = -F(1, 2**exponent), F(2)**scale_exponent
            radius = affine_radius([(a, b, "<")])
            assert radius is not None and affine_interval_truth(a, b, "<", radius)
            scaled_count += 1
    # Small Lagrange inverse oracle, entirely rational: x+x^2=y.
    order = 12
    inverse = [F(0)] + [F((-1)**(n - 1) * comb(2*n-2, n-1), n) for n in range(1, order + 1)]
    residual = inverse[:]
    for n in range(order + 1):
        residual[n] += sum(inverse[k] * inverse[n-k] for k in range(n + 1))
    residual[1] -= 1
    assert all(value == 0 for value in residual)
    position_models = []
    for length in (1, 10, 1000, 100000):
        values = [1] * length
        positions = [i for i, value in enumerate(values, 1) if value == 1]
        first = next(i for i, value in enumerate(values, 1) if value == 1)
        assert positions[0] == first == 1
        position_models.append({"FlatListLength": length, "AllMatchesStored": len(positions),
                                "EarlyExitMatchesStored": 1, "AllMatchTests": length, "EarlyExitMatchTests": 1})
    return {"EvidenceType": "Independent exact Python reference models",
            "WolframPackageExecuted": False, "MathicsPackageExecuted": False,
            "AssertionsPassed": True,
            "SparseDenseAgreementCases": sparse_count,
            "HugeSparseExample": {"Degree": huge_degree, "NonzeroOutput": 2,
                                  "DenseSlotsRequiredBySourceAlgorithm": huge_degree + 1,
                                  "HugeDenseArrayActuallyAllocated": False},
            "AffineFamilyCases": len(family), "SevenRadiusGridMisses": sum(not x["SevenRadiusGridProves"] for x in family),
            "AffineRandomConjunctions": random_clause_count, "AffineRandomConjunctionsProved": proved,
            "PositiveCoordinateRescalingsChecked": scaled_count,
            "InversePolynomialOracleThroughPower": order, "InverseCoefficients": [str(x) for x in inverse[1:]],
            "PositionCostModels": position_models, "RadiusFamily": family,
            "LimitWitness": {"Expression": "u/Abs[u]", "FromAbove": 1,
                             "FromBelow": -1, "TwoSidedRealLimitExists": False,
                             "Basis": "Exact identity on each real half-axis, not a CAS observation"}}

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "evidence" / "exact_reference_checks.json")
    args = parser.parse_args()
    result = run_checks()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print({key: value for key, value in result.items() if key not in {"RadiusFamily", "PositionCostModels"}})
    return 0
if __name__ == "__main__":
    raise SystemExit(main())
