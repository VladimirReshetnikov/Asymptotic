#!/usr/bin/env python3
"""Independent unit tests. None loads the repository or a WL interpreter."""
from fractions import Fraction as F
import math
import random
import unittest
from exact_seed_reference import (Budget, BudgetExceeded, evaluate, old_integer_admission,
                                 prove_root, propose_binary_float, rational_admission,
                                 verify_witness, _homogeneous)


class ExactSeedTests(unittest.TestCase):
    def test_integer_control(self):
        self.assertEqual(old_integer_admission([-1, 1], F(1)), F(1))

    def test_half_exposes_gate(self):
        self.assertIsNone(old_integer_admission([-1, 2], F(1, 2)))
        self.assertEqual(rational_admission([-1, 2], F(1, 2)), F(1, 2))

    def test_quarter(self):
        self.assertEqual(rational_admission([-1, 4], F(1, 4)), F(1, 4))

    def test_negative(self):
        self.assertEqual(rational_admission([3, 8], F(-3, 8)), F(-3, 8))

    def test_dyadic_family(self):
        for k in range(1, 25):
            for p in (1, 3, 5, 11):
                q = F(p, 2**k)
                if q.denominator == 1:
                    continue
                with self.subTest(p=p, k=k):
                    self.assertIsNone(old_integer_admission([-q, 1], q))
                    self.assertEqual(rational_admission([-q, 1], q), q)

    def test_affine_rescaling(self):
        for scale in (F(1, 3), F(2), F(17, 8)):
            for offset in (F(0), F(1, 5), F(-7)):
                q = F(3, 8)
                target = scale*q + offset
                self.assertEqual(rational_admission([offset-target, scale], q), q)

    def test_non_dyadic_exact_candidate(self):
        self.assertEqual(rational_admission([-1, 3], F(1, 3)), F(1, 3))

    def test_binary_half_candidate(self):
        q = propose_binary_float(0.5)
        self.assertEqual(q, F(1, 2))
        self.assertIsNotNone(prove_root([-1, 2], q))

    def test_binary_one_third_not_exact_root(self):
        q = propose_binary_float(1.0/3.0)
        self.assertNotEqual(q, F(1, 3))
        self.assertIsNone(prove_root([-1, 3], q))

    def test_next_float_rejected(self):
        q = propose_binary_float(math.nextafter(0.5, 1.0))
        self.assertIsNone(prove_root([-1, 2], q))

    def test_irrational_root_not_promoted(self):
        q = propose_binary_float(math.sqrt(2))
        self.assertIsNone(prove_root([-2, 0, 1], q))

    def test_coefficients_must_be_exact(self):
        with self.assertRaises(TypeError):
            prove_root([-1.0, 2], F(1, 2))

    def test_candidate_must_be_exact(self):
        with self.assertRaises(TypeError):
            prove_root([-1, 2], 0.5)

    def test_nonfinite_seed_refused(self):
        for x in (math.nan, math.inf, -math.inf):
            with self.assertRaises(ValueError):
                propose_binary_float(x)

    def test_multiple_root_only_equality(self):
        witness = prove_root([F(1,4), -1, 1], F(1,2))
        self.assertIsNotNone(witness)
        self.assertIn("uniqueness", witness.to_json()["not_claimed"])

    def test_zero_polynomial_not_uniqueness(self):
        self.assertIsNotNone(prove_root([0], F(17, 31)))
        self.assertIsNone(prove_root([1], F(17, 31)))

    def test_negative_polynomial_scaling(self):
        self.assertIsNotNone(prove_root([F(17,12), F(-17,6)], F(1,2)))

    def test_homogeneous_identity_random(self):
        rng = random.Random(20260910)
        for _ in range(200):
            c = [F(rng.randint(-20,20), rng.randint(1,12))
                 for _ in range(rng.randint(1,8))]
            x = F(rng.randint(-12,12), rng.randint(1,15))
            result = prove_root(c, x)
            self.assertEqual(result is not None, evaluate(c, x) == 0)

    def test_constructed_roots_random(self):
        rng = random.Random(37)
        for _ in range(150):
            q = F(rng.randint(-12,12), rng.randint(1,15))
            g = [F(rng.randint(-7,7), rng.randint(1,9)) for _ in range(5)]
            c = [-q*g[0]]
            c += [g[i-1]-q*g[i] for i in range(1,len(g))]
            c += [g[-1]]
            self.assertIsNotNone(prove_root(c, q))

    def test_modular_pass_is_not_proof(self):
        # Both modular checks pass, but the exact polynomial is a nonzero constant.
        self.assertEqual(_homogeneous([101*103], 1, 2, 101), 0)
        self.assertEqual(_homogeneous([101*103], 1, 2, 103), 0)
        self.assertIsNone(prove_root([101*103], F(1,2)))

    def test_denominator_divisible_by_filter_prime(self):
        self.assertIsNotNone(prove_root([-1, 101], F(1,101)))
        self.assertIsNotNone(prove_root([-1, 103], F(1,103)))

    def test_witness_roundtrip(self):
        w = prove_root([-1, 2], F(1,2)).to_json()
        self.assertTrue(verify_witness(w))

    def test_tampered_witness(self):
        w = prove_root([-1, 2], F(1,2)).to_json()
        w["candidate"] = "3/4"
        self.assertFalse(verify_witness(w))

    def test_forged_degree(self):
        w = prove_root([-1, 2], F(1,2)).to_json()
        w["degree"] = 99
        self.assertFalse(verify_witness(w))

    def test_bounded_schema(self):
        self.assertFalse(verify_witness({"schema": "exact-polynomial-point-equality-v1",
            "coefficients_increasing_degree": ["0/1"]*10000, "candidate": "1/2"}))

    def test_degree_budget(self):
        with self.assertRaises(BudgetExceeded):
            prove_root([1]*20, F(1), Budget(max_degree=10))

    def test_input_bits_budget(self):
        with self.assertRaises(BudgetExceeded):
            prove_root([1, 2**100], F(1), Budget(max_input_bits=32))

    def test_predicted_work_budget(self):
        with self.assertRaises(BudgetExceeded):
            prove_root([1]*40, F(1,2**200), Budget(max_work_bits=2000))

    def test_bad_budget(self):
        with self.assertRaises(ValueError):
            Budget(max_input_bits=0)
        with self.assertRaises(TypeError):
            Budget(max_degree=2.5)

    def test_false_branch_alarm_control(self):
        # These roots are exact but are not the germ at x=0+. The equality
        # checker intentionally makes no branch-connectivity claim.
        self.assertIsNotNone(prove_root([F(-9,200), 1, -2], F(9,20)))
        self.assertIsNotNone(prove_root([F(-231,1000), 2, -3, 1], F(21,10)))


if __name__ == "__main__":
    unittest.main(verbosity=2)
