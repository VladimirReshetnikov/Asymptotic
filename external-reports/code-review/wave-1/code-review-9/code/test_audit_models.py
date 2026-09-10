"""Executed independent tests, not upstream Wolfram package tests."""
from fractions import Fraction as F
from math import comb
import random
import unittest
from audit_models import (Work, dense_bridge_plan, integer_power, multiply,
    lagrange_coefficient, collision_fixture, product_precision,
    required_product_precision, inverse_quadratic)

class AuditModelTests(unittest.TestCase):
    def test_dense_bridge_small(self):
        self.assertEqual(dense_bridge_plan([F(0), F(1, 997)], F(1))["dense_slots"], 997)

    def test_dense_bridge_huge_dimension_without_allocation(self):
        p = dense_bridge_plan([F(0), F(1, 10**9)], F(1))
        self.assertEqual((p["sparse_blocks"], p["dense_slots"]), (2, 10**9))

    def test_dense_bridge_empty(self):
        self.assertEqual(dense_bridge_plan([], F(7, 3))["dense_slots"], 0)

    def test_dense_bridge_validation(self):
        with self.assertRaises(ValueError):
            dense_bridge_plan([F(1)], F(1))

    def test_millionth_power_low_cutoff(self):
        n = 10**6
        work = Work()
        got = integer_power({F(0): F(1), F(1): F(1)}, n, F(3), work)
        self.assertEqual(got, {F(0): F(1), F(1): F(n), F(2): F(comb(n, 2))})
        self.assertLessEqual(work.peak_support, 3)

    def test_full_power_budget_fails_but_truncated_succeeds(self):
        base = {F(0): F(1), F(1): F(1)}
        with self.assertRaises(RuntimeError):
            integer_power(base, 256, None, pair_limit=200)
        got = integer_power(base, 256, F(3), pair_limit=200)
        self.assertEqual(got[F(2)], comb(256, 2))

    def test_cutoff_boundary_exclusive(self):
        self.assertEqual(integer_power({F(0): F(1), F(1): F(1)}, 8, F(1)), {F(0): F(1)})

    def test_shifted_negative_valuation(self):
        base = {F(-4): F(1), F(-3): F(1)}
        got = integer_power(base, 3, F(-9))
        self.assertEqual(got, {F(-12): F(1), F(-11): F(3), F(-10): F(3)})

    def test_zero_and_zeroth_power(self):
        self.assertEqual(integer_power({}, 3, F(4)), {})
        self.assertEqual(integer_power({}, 0, F(1)), {F(0): F(1)})
        self.assertEqual(integer_power({}, 0, F(0)), {})

    def test_fractional_support(self):
        self.assertEqual(integer_power({F(0): F(1), F(1, 7): F(1)}, 3, F(3, 7)),
                         {F(0): F(1), F(1, 7): F(3), F(2, 7): F(3)})

    def test_randomized_truncation_oracle(self):
        rng = random.Random(9781)
        for _ in range(100):
            base = {F(rng.randrange(-4, 7), 3): F(rng.randrange(-3, 4))
                    for _ in range(4)}
            n = rng.randrange(1, 7)
            h = F(rng.randrange(-8, 14), 3)
            full = integer_power(base, n)
            expected = {w: c for w, c in full.items() if w < h}
            self.assertEqual(integer_power(base, n, h), expected)

    def test_collision_count(self):
        self.assertEqual(collision_fixture(), {"gaps": 24, "inside_indices": 2925,
            "boundary_indices": 17550, "budgeted_indices": 20475, "retained_weights": 142})

    def test_collision_fixture_small_enumeration(self):
        from itertools import product
        m = 4
        indices = [k for k in product(range(5), repeat=m) if sum(k) <= 4]
        inside = [k for k in indices if sum(k) <= 3]
        weights = {sum((F(1) + F(j + 1, 1000))*ki
                       for j, ki in enumerate(k)) for k in inside}
        fixture = collision_fixture(m)
        self.assertEqual((len(indices), len(inside), len(weights)),
                         (fixture["budgeted_indices"], fixture["inside_indices"], fixture["retained_weights"]))

    def test_lagrange_log_first_two_corrections(self):
        args = ((F(1),), ((F(1), F(1)),))
        self.assertEqual(lagrange_coefficient((1,), *args), (F(1), (F(-1), F(-1))))
        self.assertEqual(lagrange_coefficient((2,), *args), (F(2), (F(3), F(5), F(2))))

    def test_lagrange_matches_catalan(self):
        oracle = inverse_quadratic(14)
        for n in range(1, 13):
            w, q = lagrange_coefficient((n,), (F(1),), ((F(1),),))
            self.assertEqual(q, (oracle[w + 1],))

    def test_lagrange_mixed_collision(self):
        # f=x+x^2+x^3: inverse cubic coefficient combines k=(2,0) and (0,1).
        data = ((F(1), F(2)), ((F(1),), (F(1),)))
        _, a = lagrange_coefficient((2, 0), *data)
        _, b = lagrange_coefficient((0, 1), *data)
        self.assertEqual(a[0] + b[0], F(1))

    def test_lagrange_nonunit_leading_power(self):
        # f=x^2(1+x), inverse x=z - z^2/2 + 5 z^3/8 + ...
        self.assertEqual(lagrange_coefficient((1,), (F(1),), ((F(1),),), F(2))[1], (F(-1, 2),))
        self.assertEqual(lagrange_coefficient((2,), (F(1),), ((F(1),),), F(2))[1], (F(5, 8),))

    def test_inverse_quadratic_residual(self):
        g = inverse_quadratic(12)
        square = multiply(g, g, F(12))
        residual = {w: g.get(w, F(0)) + square.get(w, F(0)) for w in set(g) | set(square)}
        self.assertEqual({w: c for w, c in residual.items() if c}, {F(1): F(1)})

    def test_refinement_fixed_margin_shortfall(self):
        # A source with valuation 0, times exact x^-10. h=5, heuristic gives Pa=7.
        self.assertEqual(product_precision(F(7), None, F(0), F(-10)), F(-3))
        self.assertEqual(required_product_precision(F(5), F(0), F(-10))[0], F(15))
        self.assertEqual(product_precision(F(15), None, F(0), F(-10)), F(5))

    def test_real_domain_counterexample(self):
        import cmath
        self.assertNotEqual(cmath.acos(2).imag, 0)

if __name__ == "__main__":
    unittest.main(verbosity=2)
