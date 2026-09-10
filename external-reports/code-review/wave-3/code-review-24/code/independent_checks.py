#!/usr/bin/env python3
"""Independent exact-model and patch-fixture checks; NOT package execution.
Uses only the Python standard library. Run --output evidence/model_checks.json.
"""
from __future__ import annotations
import argparse
import json
import unittest
from collections import defaultdict
from fractions import Fraction as F
from pathlib import Path
import stage_patches as staging

Poly = dict[int, F]

def clean(p: Poly) -> Poly:
    return {n: F(c) for n, c in p.items() if c}

def multiply(a: Poly, b: Poly, cutoff: int, budget: int) -> tuple[Poly, int]:
    result: dict[int, F] = defaultdict(F)
    pairs = 0
    for i, x in sorted(a.items()):
        for j, y in sorted(b.items()):
            if i + j < cutoff:
                pairs += 1
                if pairs > budget:
                    raise RuntimeError("retained pair budget")
                result[i + j] += x*y
    return clean(result), pairs

def add(a: Poly, b: Poly, budget: int) -> Poly:
    result = dict(a)
    for n, c in b.items():
        result[n] = result.get(n, F(0)) + c
    result = clean(result)
    if len(result) > budget:
        raise RuntimeError("support budget")
    return result

def unit_compose(u: Poly, p: int, cutoff: int, budget: int, early_zero: bool) -> tuple[Poly, int]:
    """Zero-frequency, constant-amplitude slice of the audited recurrence.
    Its purpose is an independent combinatorial cost oracle, not emulation
    of Wolfram evaluation, Fourier canonicalization or symbolic assumptions.
    """
    answer: Poly = {0: F(1)}
    product: Poly = {0: F(1)}
    c = F(1)
    k = 0
    work = 0
    while True:
        if early_zero:
            if min(product) + min(u) >= cutoff:
                break
            c *= F(p-k, k+1)
            if c == 0:
                break
        if k >= budget:
            raise RuntimeError("iteration budget")
        product, cost = multiply(product, u, cutoff, budget)
        work += cost
        if not product:
            break
        if not early_zero:
            c *= F(p-k, k+1)
            if c == 0:
                break
        term, cost = multiply(product, {0: c}, cutoff, budget)
        work += cost
        answer = add(answer, term, budget)
        k += 1
    return answer, work

def direct_integer_power(base: Poly, p: int, cutoff: int) -> Poly:
    result: Poly = {0: F(1)}
    for _ in range(p):
        result, _ = multiply(result, base, cutoff, 10**7)
    return result

def reweight(rows: dict[F, F], alpha: F, coefficient: F = F(1)) -> dict[F, F]:
    return {weight + alpha: coefficient*c for weight, c in rows.items()}

class ExactMathematics(unittest.TestCase):
    def test_lerch_moments(self):
        # Differentiating 1/(1-z) repeatedly with z*d/dz gives these moments.
        z = F(1, 2)
        moments = [1/(1-z), z/(1-z)**2,
                   z*(1+z)/(1-z)**3, z*(1+4*z+z*z)/(1-z)**4]
        self.assertEqual(moments, [2, 2, 6, 26])
        self.assertEqual([((-1)**k)*(k+1)*m for k,m in enumerate(moments)], [2,-4,18,-104])

    def test_lerch_exact_taylor_remainder(self):
        for n in range(101):
            t = F(n, 7)
            remainder = 1/(1+t)**2 - (1-2*t+3*t*t)
            self.assertEqual(remainder, -t**3*(4+3*t)/(1+t)**2)

    def test_lerch_rigorous_taylor_bound(self):
        for n in range(101):
            t = F(n, 7)
            remainder = 1/(1+t)**2 - (1-2*t+3*t*t)
            self.assertLessEqual(abs(remainder), 4*t**3)
            self.assertLessEqual(remainder, 0)

    def test_positive_chart_finite_expression(self):
        rows = {F(2): F(2), F(3): F(-4), F(4): F(18)}
        shifted = reweight(rows, F(-1,2))
        self.assertEqual(shifted, {F(3,2): 2,F(5,2):-4,F(7,2):18})
        # Evaluate in w=1/x^2 with positive rational x: all half powers exact.
        for x in (F(1),F(2),F(7,3),F(11)):
            lhs = x*(2/x**4-4/x**6+18/x**8)
            rhs = sum(c*x**(-int(2*b)) for b,c in shifted.items())
            self.assertEqual(lhs,rhs)

    def test_negative_chart_changes_expression_sign_not_error_size(self):
        rows = {F(2):F(2),F(3):F(-4),F(4):F(18)}
        shifted = reweight(rows,F(-1,2),F(-1))
        for radius in (F(1),F(2),F(7,3),F(11)):
            x = -radius
            self.assertEqual(x*(2/x**4-4/x**6+18/x**8),
                             sum(c*radius**(-int(2*b)) for b,c in shifted.items()))
        self.assertEqual(F(5)-F(1,2),F(9,2))

    def test_lerch_weighted_bound_transport(self):
        for x in (F(1),F(2),F(7,3),F(11)):
            self.assertEqual(x*F(104)/x**10,F(104)/x**9)
            self.assertEqual(F(104)*(1/x**2)**4/x,F(104)/x**9)

    def test_fourier_model_reproduces_avoidable_failure(self):
        with self.assertRaisesRegex(RuntimeError,"retained pair"):
            unit_compose({1:F(1),2:F(1)},1,5,3,False)

    def test_fourier_model_early_termination(self):
        self.assertEqual(unit_compose({1:F(1),2:F(1)},1,5,3,True)[0],
                         {0:F(1),1:F(1),2:F(1)})

    def test_fourier_model_work_is_not_wall_time(self):
        u={i:F(1) for i in range(1,9)}
        old,old_cost=unit_compose(u,1,17,100,False)
        new,new_cost=unit_compose(u,1,17,100,True)
        self.assertEqual(old,new)
        self.assertEqual(old_cost-new_cost,64)

    def test_polynomial_recurrence_against_cartesian_oracle(self):
        for p in range(7):
            for cutoff in (3,5,8,13):
                u={1:F(2),3:F(-1)}
                actual,_=unit_compose(u,p,cutoff,10000,True)
                expected=direct_integer_power({0:F(1),**u},p,cutoff)
                self.assertEqual(actual,expected)

    def test_empty_next_support_terminates_before_recurrence(self):
        self.assertEqual(unit_compose({4:F(1)},3,4,1,True),({0:F(1)},0))

class PatchFixtures(unittest.TestCase):
    def test_unique_default_anchor(self):
        self.assertEqual(staging.apply_patches(staging.DEFAULT_BEFORE,["backend-default"]),staging.DEFAULT_AFTER)
    def test_unique_key_anchor(self):
        self.assertEqual(staging.apply_patches(staging.KEYS_BEFORE,["computed-keys"]),staging.KEYS_AFTER)
    def test_unique_fourier_anchor(self):
        self.assertEqual(staging.apply_patches(staging.FOURIER_BEFORE,["fourier-termination"]),staging.FOURIER_AFTER)
    def test_missing_anchor_refused(self):
        with self.assertRaises(staging.PatchError): staging.apply_patches("unrelated",["backend-default"])
    def test_duplicate_anchor_refused(self):
        with self.assertRaises(staging.PatchError): staging.apply_patches(staging.DEFAULT_BEFORE*2,["backend-default"])
    def test_reapplying_refused(self):
        with self.assertRaises(staging.PatchError): staging.apply_patches(staging.DEFAULT_AFTER,["backend-default"])
    def test_repeated_patch_name_refused(self):
        with self.assertRaises(staging.PatchError): staging.apply_patches(staging.DEFAULT_BEFORE,["backend-default"]*2)
    def test_unknown_patch_refused(self):
        with self.assertRaises(staging.PatchError): staging.apply_patches("",["nonexistent"])
    def test_empty_patch_selection_refused(self):
        with self.assertRaises(staging.PatchError): staging.apply_patches("",[])
    def test_combined_synthetic_fixture(self):
        source="\n".join(p.before for p in staging.PATCHES.values())
        out=staging.apply_patches(source,list(staging.PATCHES))
        for p in staging.PATCHES.values(): self.assertIn(p.after,out)

if __name__=="__main__":
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--output",type=Path,required=True)
    args=ap.parse_args()
    suite=unittest.TestSuite([unittest.defaultTestLoader.loadTestsFromTestCase(ExactMathematics),
                              unittest.defaultTestLoader.loadTestsFromTestCase(PatchFixtures)])
    result=unittest.TextTestRunner(verbosity=2).run(suite)
    report={"scope":"Independent exact mathematics, recurrence-cost model and synthetic patch fixtures; NO Wolfram package execution",
            "tests_run":result.testsRun,"failures":len(result.failures),"errors":len(result.errors),
            "success":result.wasSuccessful(),
            "subcases_note":"Several methods contain deterministic rational subcases; these are not separate package tests."}
    args.output.write_text(json.dumps(report,indent=2),encoding="utf-8")
    raise SystemExit(0 if result.wasSuccessful() else 1)
