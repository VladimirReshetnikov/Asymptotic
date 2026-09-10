#!/usr/bin/env python3
"""Independent exact checks for the Asymptotic review.

This is NOT a Wolfram Language interpreter or a Mathics package test.
The frontier model counts the literal full membership scans introduced by
MathicsCompatibility.wl. The polynomial and hypergeometric checks use exact
rational arithmetic, with no numerical samples used as proofs.
Python 3.11+; standard library only. No checksum files are produced.
"""
from __future__ import annotations

from dataclasses import dataclass, replace, asdict
from fractions import Fraction as Q
import argparse
import json
import math
from pathlib import Path
import random
import re
import sys
import unittest

PIN = "7d1bc832895cc90a9b2a978b7b7684acab908bd2"


def rational(value: int | Q) -> Q:
    if isinstance(value, bool) or not isinstance(value, (int, Q)):
        raise TypeError("Only exact integer/Fraction coefficients are admitted")
    return Q(value)


def trim(coefficients: list[int | Q] | tuple[int | Q, ...]) -> tuple[Q, ...]:
    c = [rational(a) for a in coefficients]
    while c and c[-1] == 0:
        c.pop()
    return tuple(c)


@dataclass(frozen=True)
class SignCertificate:
    coefficients: tuple[Q, ...]  # ascending powers, trailing zeros removed
    valuation: int
    leading: Q
    tail_l1: Q
    radius: Q
    sign: int


def certify_polynomial_sign(coefficients: list[int | Q] | tuple[int | Q, ...]) -> SignCertificate:
    """Certify the sign of a NONZERO rational polynomial for 0 < u < r.

    Write p(u)=u^m(a_m+tail). On 0<u<r<=1, |tail|<=A*u,
    where A=sum_{j>m}|a_j|. The chosen r ensures A*r<=|a_m|/2.
    The zero polynomial is handled separately by relation_truth, not assigned
    an artificial positive or negative leading sign.
    """
    c = trim(coefficients)
    if not c:
        raise ValueError("The zero polynomial has no strict sign certificate")
    m = next(i for i, a in enumerate(c) if a)
    leading = c[m]
    tail_l1 = sum((abs(a) for a in c[m + 1:]), Q(0))
    radius = Q(1) if not tail_l1 else min(Q(1), abs(leading) / (2 * tail_l1))
    return SignCertificate(c, m, leading, tail_l1, radius, 1 if leading > 0 else -1)


def verify_sign_certificate(c: SignCertificate) -> bool:
    """Small checker: reconstruct the data and verify a sufficient inequality.

    It accepts any safe radius, not merely the producer's chosen radius.
    """
    try:
        p = trim(c.coefficients)
        if not p or p != c.coefficients or not 0 < c.radius <= 1:
            return False
        m = next(i for i, a in enumerate(p) if a)
        a = p[m]
        A = sum((abs(x) for x in p[m + 1:]), Q(0))
        return (c.valuation == m and c.leading == a and c.tail_l1 == A
                and c.sign == (1 if a > 0 else -1)
                and A * c.radius <= abs(a) / 2)
    except (TypeError, ValueError, AttributeError):
        return False


def relation_truth(coefficients: list[int | Q] | tuple[int | Q, ...], relation: str) -> tuple[bool, Q]:
    """Eventual truth of p(u) relation 0, with a proved deleted radius.

    Not a global interval, parameter-elimination, or injectivity theorem.
    """
    allowed = {">": {1}, ">=": {0, 1}, "<": {-1}, "<=": {-1, 0},
               "==": {0}, "!=": {-1, 1}}
    if relation not in allowed:
        raise ValueError("Unsupported relation")
    p = trim(coefficients)
    if not p:
        return 0 in allowed[relation], Q(1)
    certificate = certify_polynomial_sign(p)
    assert verify_sign_certificate(certificate)
    return certificate.sign in allowed[relation], certificate.radius


def conjunction_truth(clauses: list[tuple[list[int | Q], str]]) -> tuple[bool, Q]:
    results = [relation_truth(p, op) for p, op in clauses]
    return all(t for t, _ in results), min((r for _, r in results), default=Q(1))


def pochhammer(a: int | Q, n: int) -> Q:
    if isinstance(n, bool) or not isinstance(n, int) or n < 0:
        raise ValueError("Pochhammer index must be a nonnegative integer")
    a = rational(a)
    ans = Q(1)
    for j in range(n):
        ans *= a + j
    return ans


def terminating_pfq(upper: list[int | Q], lower: list[int | Q], max_degree: int = 1000) -> tuple[Q, ...]:
    """Exact terminating unregularized pFq, with no lower-parameter poles.

    No p<=q+1 restriction is necessary for a terminating polynomial.
    Nonpositive integer lower parameters are refused EVEN if a top parameter
    terminates earlier: this avoids silently choosing a parameter-limit convention.
    """
    a = [rational(x) for x in upper]
    b = [rational(x) for x in lower]
    if any(x.denominator == 1 and x <= 0 for x in b):
        raise ValueError("Nonpositive integer lower parameter: convention not admitted")
    degrees = [-int(x) for x in a if x.denominator == 1 and x <= 0]
    if not degrees:
        raise ValueError("No proved terminating upper parameter")
    N = min(degrees)
    if isinstance(max_degree, bool) or not isinstance(max_degree, int) or max_degree < 0:
        raise ValueError("max_degree must be a nonnegative integer")
    if N > max_degree:
        raise ValueError("Terminating polynomial exceeds degree budget")
    c = [Q(1)]
    for k in range(N):
        numerator = math.prod((x + k for x in a), start=Q(1))
        denominator = (k + 1) * math.prod((x + k for x in b), start=Q(1))
        if denominator == 0:
            raise ArithmeticError("Unexpected pole after parameter validation")
        c.append(c[-1] * numerator / denominator)
    return trim(c)


def pfq_direct(upper: list[int | Q], lower: list[int | Q], n: int) -> Q:
    return (math.prod((pochhammer(a, n) for a in upper), start=Q(1)) /
            (math.factorial(n) * math.prod((pochhammer(b, n) for b in lower), start=Q(1))))


def frontier_counts(cutoff: int, gaps: tuple[int, ...] = (1, 2)) -> dict:
    """Count membership comparisons for the source's positive-gap layer algorithm.

    The literal Mathics KeyExistsQ maps SameQ over every key, so each query
    costs len(boundary) comparisons, even for an early hit. All other work
    (normalization, key conversion, sorting, coefficient arithmetic) is excluded.
    """
    if cutoff < 1 or not gaps or any(g < 1 for g in gaps):
        raise ValueError("Positive cutoff and positive integer gaps required")
    origin = (0,) * len(gaps)
    boundary = {origin: 0}
    inside: set[tuple[int, ...]] = set()
    scans = queries = inserts = layers = 0
    peak = 1
    while boundary and min(boundary.values()) < cutoff:
        weight = min(boundary.values())
        layer = [k for k, w in boundary.items() if w == weight]
        for k in layer:
            del boundary[k]
        inside.update(layer)
        for k in layer:
            for j, gap in enumerate(gaps):
                neighbor = tuple(v + (i == j) for i, v in enumerate(k))
                queries += 1
                scans += len(boundary)
                if neighbor not in boundary:
                    boundary[neighbor] = weight + gap
                    inserts += 1
                    peak = max(peak, len(boundary))
        layers += 1
    if gaps == (1, 2):
        oracle = {(i, j) for i in range(cutoff) for j in range(cutoff)
                  if i + 2 * j < cutoff}
        if inside != oracle:
            raise AssertionError("Frontier disagrees with direct lattice enumeration")
    return {"cutoff": cutoff, "gaps": list(gaps), "inside_indices": len(inside),
            "membership_queries": queries, "full_scan_comparisons": scans,
            "peak_boundary_keys": peak, "layers": layers, "insertions": inserts,
            "scope": "exact structural operation count; not Mathics timing"}


# Literal regular expression and group assignment transcribed from the pinned source.
CURRENT_CASE_PATTERN = re.compile(r'^portableTest\["([a-z0-9-]+)", "([a-z]+)",', re.MULTILINE)
SHARDS = {
    "foundation": ("loading", "primitive", "assumptions"),
    "calculus": ("forward", "inverse", "arithmetic"),
    "contracts": ("callable", "contracts", "native", "flat", "certificate", "numerical", "logarithmic"),
    "special": ("special", "families"),
    "operations": ("operations",),
}


def check_partition(cases: list[tuple[str, str]], shards: dict[str, tuple[str, ...]]) -> dict:
    """Require each inventory case to appear in exactly one shard per entry point."""
    if not cases or len({name for name, _ in cases}) != len(cases):
        raise ValueError("Empty inventory or duplicate case IDs")
    counts = {name: sum(group in groups for groups in shards.values()) for name, group in cases}
    missing = [name for name, n in counts.items() if n == 0]
    duplicates = [name for name, n in counts.items() if n > 1]
    if missing or duplicates:
        raise ValueError(f"Invalid CI partition: missing={missing}, duplicated={duplicates}")
    return {"cases": len(cases), "shards": len(shards), "exactly_once": True}


def positive_finite_timeout(text: str | float) -> float:
    try:
        value = float(text)
    except (TypeError, ValueError, OverflowError) as error:
        raise argparse.ArgumentTypeError("timeout must be a finite positive number") from error
    if not math.isfinite(value) or value <= 0:
        raise argparse.ArgumentTypeError("timeout must be a finite positive number")
    return value


class ReferenceTests(unittest.TestCase):
    def test_small_affine_radius(self):
        c = certify_polynomial_sign([Q(1, 1024), -1])
        self.assertEqual(c.radius, Q(1, 2048))
        self.assertTrue(verify_sign_certificate(c))
        self.assertTrue(all(Q(1, 2 ** j) > Q(1, 1024) for j in range(7)))

    def test_zero_relation(self):
        for relation, expected in [("==", True), (">=", True), ("<=", True),
                                    ("!=", False), (">", False), ("<", False)]:
            self.assertEqual(relation_truth([0, 0], relation)[0], expected)

    def test_nonzero_valuation(self):
        c = certify_polynomial_sign([0, 0, -3, 100, -2])
        self.assertEqual((c.valuation, c.sign, c.radius), (2, -1, Q(1, 68)))
        self.assertTrue(verify_sign_certificate(c))

    def test_scale_covariance(self):
        base = certify_polynomial_sign([Q(1, 1024), -1])
        scaled = certify_polynomial_sign([Q(1, 1024), -1024])
        self.assertEqual(scaled.radius, base.radius / 1024)

    def test_certificate_tampering(self):
        c = certify_polynomial_sign([1, -100])
        for bad in [replace(c, sign=-1), replace(c, radius=Q(1)),
                    replace(c, tail_l1=Q(0)), replace(c, leading=Q(2))]:
            self.assertFalse(verify_sign_certificate(bad))

    def test_random_exact_certificates(self):
        rng = random.Random(1729)
        for _ in range(250):
            p = [Q(rng.randrange(-9, 10), rng.randrange(1, 8)) for _ in range(rng.randrange(1, 9))]
            if any(p):
                self.assertTrue(verify_sign_certificate(certify_polynomial_sign(p)))

    def test_conjunction(self):
        truth, radius = conjunction_truth([([0, 1], ">"), ([Q(1, 1024), -1], ">")])
        self.assertTrue(truth)
        self.assertEqual(radius, Q(1, 2048))

    def test_inexact_rejected(self):
        with self.assertRaises(TypeError):
            certify_polynomial_sign([1.0, -1])

    def test_terminating_pfq(self):
        self.assertEqual(terminating_pfq([-2, 1, 3], []), (Q(1), Q(-6), Q(24)))

    def test_negative_noninteger_lower(self):
        self.assertEqual(terminating_pfq([-2, 1], [Q(-1, 2)]), (Q(1), Q(4), Q(-8)))

    def test_recurrence_against_direct_products(self):
        for N in range(11):
            for lower in [[], [Q(1, 2)], [Q(-1, 2)], [Q(3, 2), Q(7, 3)]]:
                upper = [-N, Q(2, 3), Q(5, 2)]
                got = terminating_pfq(upper, lower)
                want = tuple(pfq_direct(upper, lower, k) for k in range(N + 1))
                self.assertEqual(got, want)
                self.assertEqual(pfq_direct(upper, lower, N + 1), 0)

    def test_poles_not_cancelled(self):
        for lower in [[-1], [0], [-4]]:
            with self.assertRaises(ValueError):
                terminating_pfq([-1, 2], lower)

    def test_nonterminating_and_budget_rejected(self):
        with self.assertRaises(ValueError):
            terminating_pfq([1, 2, 3], [])
        with self.assertRaises(ValueError):
            terminating_pfq([-1001, 1], [], 1000)

    def test_frontier_oracle(self):
        for H in range(1, 40):
            got = frontier_counts(H)
            self.assertEqual(got["membership_queries"], 2 * got["inside_indices"])

    def test_format_sensitive_inventory(self):
        text = ('portableTest["control", "forward", 1, 1];\n'
                ' portableTest["indented", "forward", 1, 1];\n'
                'portableTest[\n"multiline", "forward", 1, 1];\n'
                'portableTest["compact","forward",1,1];\n')
        self.assertEqual(CURRENT_CASE_PATTERN.findall(text), [("control", "forward")])

    def test_new_group_unassigned(self):
        cases = [("control", "forward"), ("new-case", "recurrence")]
        with self.assertRaises(ValueError):
            check_partition(cases, SHARDS)

    def test_duplicate_shard_rejected(self):
        with self.assertRaises(ValueError):
            check_partition([("control", "forward")], {"a": ("forward",), "b": ("forward",)})

    def test_empty_inventory_rejected(self):
        with self.assertRaises(ValueError):
            check_partition([], SHARDS)

    def test_good_partition(self):
        self.assertTrue(check_partition([("control", "forward"), ("loader", "loading")], SHARDS)["exactly_once"])

    def test_nonfinite_timeout(self):
        for bad in ["nan", "inf", "-inf", "0", "-1", "nonsense"]:
            with self.assertRaises(argparse.ArgumentTypeError):
                positive_finite_timeout(bad)
        self.assertEqual(positive_finite_timeout("0.125"), 0.125)
        self.assertFalse(float("nan") <= 0)  # current guard misses this
        self.assertFalse(float("inf") <= 0)


def jsonable(value):
    if isinstance(value, Q):
        return str(value)
    if isinstance(value, dict):
        return {k: jsonable(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [jsonable(v) for v in value]
    return value


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "results/reference_results.json")
    args = parser.parse_args()
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ReferenceTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    observations = {
        "repository_commit": PIN,
        "evidence_kind": "independent Python exact models and synthetic validation fixtures",
        "package_executed": False, "mathics_executed": False,
        "python": sys.version.split()[0],
        "tests_run": result.testsRun, "failures": len(result.failures), "errors": len(result.errors),
        "frontier": [frontier_counts(H) for H in (16, 32, 64, 128)],
        "affine_certificate": asdict(certify_polynomial_sign([Q(1, 1024), -1])),
        "terminating_pfq_3f0": terminating_pfq([-2, 1, 3], []),
        "terminating_pfq_negative_lower": terminating_pfq([-2, 1], [Q(-1, 2)]),
        "dense_coefficient_slots": [{"degree": D, "support": 2, "dense_slots": D + 1}
                                    for D in (100, 10000, 1000000)],
        "native_runtime_scope": "One basic Wolfram evaluator call succeeded; package not loaded. See native_probe.txt.",
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(jsonable(observations), indent=2) + "\n", encoding="utf-8")
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
