import json
import random
import sys
import time
import unittest
from fractions import Fraction as F
from math import isqrt
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "code"))
from dirichlet_jet import DirichletJet as J, dense_retained_pair_count
from patch_dirichlet_goals import REPLACEMENTS, patch_text


def divisor_count(n):
    return sum(n % d == 0 for d in range(1, n + 1))


def mobius_by_factorization(n):
    count = 0
    p = 2
    while p * p <= n:
        if n % p == 0:
            n //= p
            count += 1
            if n % p == 0:
                return 0
        p += 1
    if n > 1:
        count += 1
    return (-1) ** count


class DirichletTests(unittest.TestCase):
    def test_zeta_prefix(self):
        z = J.zeta(40)
        self.assertTrue(all(z.coefficient(n) == 1 for n in range(1, 41)))

    def test_zeta_square_divisors(self):
        z = J.zeta(80)
        zz = z.multiply(z)
        self.assertEqual([zz.coefficient(n) for n in range(1, 81)],
                         [divisor_count(n) for n in range(1, 81)])

    def test_reciprocal_mobius(self):
        inv = J.zeta(128).reciprocal()
        self.assertEqual([inv.coefficient(n) for n in range(1, 129)],
                         [mobius_by_factorization(n) for n in range(1, 129)])

    def test_reciprocal_identity(self):
        z = J.zeta(100)
        self.assertEqual(dict(z.multiply(z.reciprocal()).coefficients), {1: F(1)})

    def test_nonunit_constant_reciprocal(self):
        a = J.finite({1: 2, 2: 3}, 64)
        b = a.reciprocal()
        for k in range(7):
            self.assertEqual(b.coefficient(2**k), (-F(3, 2))**k / 2)
        self.assertEqual(dict(a.multiply(b).coefficients), {1: F(1)})

    def test_negative_constant_reciprocal(self):
        a = J.finite({1: -3, 3: 2}, 40)
        self.assertEqual(dict(a.multiply(a.reciprocal()).coefficients), {1: F(1)})

    def test_associativity_coefficients(self):
        a = J.finite({1: 1, 2: -2, 5: 3}, 60)
        b = J.finite({1: 2, 3: 4, 7: -1}, 50)
        c = J.zeta(40)
        self.assertEqual(dict(a.multiply(b).multiply(c).coefficients),
                         dict(a.multiply(b.multiply(c)).coefficients))

    def test_commutativity(self):
        a = J.finite({2: 1, 5: -3}, 32)
        b = J.zeta(32)
        self.assertEqual(dict(a.multiply(b).coefficients), dict(b.multiply(a).coefficients))

    def test_distributivity_coefficients(self):
        a = J.zeta(40)
        b = J.finite({1: 1, 3: -3}, 40)
        c = J.finite({2: 7, 4: F(1, 3)}, 40)
        self.assertEqual(dict(a.multiply(b.add(c)).coefficients),
                         dict(a.multiply(b).add(a.multiply(c)).coefficients))

    def test_random_convolution_against_divisor_oracle(self):
        rng = random.Random(80173)
        for _ in range(20):
            ca = {n: F(rng.randint(-5, 5), rng.randint(1, 4)) for n in range(1, 25)}
            cb = {n: F(rng.randint(-5, 5), rng.randint(1, 4)) for n in range(1, 25)}
            result = J.finite(ca, 24).multiply(J.finite(cb, 24))
            for n in range(1, 25):
                wanted = sum((ca[d] * cb[n // d] for d in range(1, n+1) if n % d == 0), F(0))
                self.assertEqual(result.coefficient(n), wanted)

    def test_random_reciprocal_identity(self):
        rng = random.Random(713)
        for _ in range(12):
            co = {1: F(rng.choice([-3, -2, 1, 2, 3]))}
            co.update({n: F(rng.randint(-3, 3), 4) for n in range(2, 33)})
            a = J.finite(co, 32)
            self.assertEqual(dict(a.multiply(a.reciprocal()).coefficients), {1: F(1)})

    def test_prefix_intersection(self):
        result = J.zeta(11).multiply(J.zeta(29))
        self.assertEqual(result.known_through, 11)
        with self.assertRaises(IndexError): result.coefficient(12)

    def test_zero_inside_prefix_not_beyond(self):
        a = J.finite({2: 1}, 7)
        self.assertEqual(a.coefficient(3), 0)
        with self.assertRaises(IndexError): a.coefficient(8)

    def test_restriction(self):
        z = J.zeta(10).restrict(3)
        self.assertEqual(dict(z.coefficients), {1: F(1), 2: F(1), 3: F(1)})
        with self.assertRaises(ValueError): z.restrict(4)

    def test_scale(self):
        a = J.zeta(4).scale(-F(2, 3))
        self.assertEqual(a.growth_constant, F(2, 3))
        self.assertEqual(a.coefficient(4), -F(2, 3))

    def test_cancellation_keeps_unknown_tail_bound(self):
        a = J.zeta(8)
        b = a.add(a.scale(-1))
        self.assertEqual(dict(b.coefficients), {})
        self.assertGreater(b.tail_bound(5), 0)

    def test_exact_rational_tail(self):
        z = J.zeta(12)
        bound = z.tail_bound(4)
        self.assertEqual(bound, F(1, 13**4) * (1 + F(13, 3)))
        partial_tail = sum((F(1, n**4) for n in range(13, 600)), F(0))
        self.assertLessEqual(partial_tail, bound)

    def test_convolution_tail_bound(self):
        a = J.zeta(10).multiply(J.zeta(10))
        partial_tail = sum((F(divisor_count(n), n**5) for n in range(11, 300)), F(0))
        self.assertLessEqual(partial_tail, a.tail_bound(5))

    def test_reciprocal_tail_bound(self):
        b = J.zeta(10).reciprocal()
        partial_absolute_tail = sum((F(abs(mobius_by_factorization(n)), n**6)
                                     for n in range(11, 300)), F(0))
        self.assertLessEqual(partial_absolute_tail, b.tail_bound(6))

    def test_tail_domain_rejected(self):
        with self.assertRaises(ValueError): J.zeta(4).tail_bound(1)
        with self.assertRaises(ValueError): J.zeta(4).reciprocal().tail_bound(3)

    def test_inexact_and_bool_rejected(self):
        for c in [0.1, True, complex(1, 0)]:
            with self.assertRaises(TypeError): J(3, {1: c}, 1, 0)
        with self.assertRaises(ValueError): J.zeta(True)

    def test_growth_bound_checked_on_prefix(self):
        with self.assertRaises(ValueError): J(3, {2: 5}, 1, 0)
        with self.assertRaises(ValueError): J(3, {4: 1}, 1, 0)

    def test_immutable_coefficients(self):
        a = J.zeta(3)
        with self.assertRaises(TypeError): a.coefficients[1] = F(99)

    def test_zero_reciprocal_refused(self):
        with self.assertRaises(ZeroDivisionError): J.finite({2: 1}, 10).reciprocal()

    def test_multiplication_budget(self):
        with self.assertRaises(RuntimeError): J.zeta(20).multiply(J.zeta(20), max_pairs=2)

    def test_reciprocal_budgets(self):
        with self.assertRaises(RuntimeError): J.finite({1: 1, 2: 10**10}, 8).reciprocal(max_growth_steps=1)
        with self.assertRaises(RuntimeError): J.zeta(32).reciprocal(max_pairs=1)

    def test_pair_count(self):
        for n in range(1, 40):
            self.assertEqual(dense_retained_pair_count(n), sum(d*m <= n for d in range(1,n+1) for m in range(1,n+1)))

    def test_exact_prefix_evaluation(self):
        self.assertEqual(J.zeta(3).evaluate_prefix(2), F(49, 36))


class PatchFixtureTests(unittest.TestCase):
    def setUp(self):
        # Synthetic anchor fixture, NOT a retrieved complete upstream module.
        self.fixture = "\n".join(old for old, _ in REPLACEMENTS) + "\n"

    def test_three_anchor_changes(self):
        edited = patch_text(self.fixture)
        for old, new in REPLACEMENTS:
            self.assertNotIn(old, edited)
            self.assertIn(new, edited)

    def test_already_patched_rejected(self):
        with self.assertRaises(ValueError): patch_text(patch_text(self.fixture))

    def test_missing_anchor_rejected(self):
        with self.assertRaises(ValueError): patch_text(self.fixture.replace(REPLACEMENTS[0][0], ""))

    def test_duplicate_anchor_rejected(self):
        with self.assertRaises(ValueError): patch_text(self.fixture + REPLACEMENTS[1][0])


if __name__ == "__main__":
    unittest.main(verbosity=2)
