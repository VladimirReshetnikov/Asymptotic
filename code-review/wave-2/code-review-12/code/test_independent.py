#!/usr/bin/env python3
"""Independent exact checks and patch-tool tests; NOT a Wolfram emulator."""
from __future__ import annotations
from fractions import Fraction
import json
import math
from pathlib import Path
import unittest
from apply_candidate_patch import transform


def native_integer(n: int, bits: int) -> bool:
    return -(1 << (bits - 1)) <= n < (1 << (bits - 1))


def grid(exponents: list[Fraction], remainder: Fraction) -> tuple[int, int, int, int]:
    denominator = math.lcm(*(e.denominator for e in exponents + [remainder]))
    nmin = min(exponents) * denominator if exponents else remainder * denominator
    nmax = remainder * denominator
    span = max(exponents) * denominator - nmin + 1 if exponents else 0
    return int(nmin), int(nmax), denominator, int(span)


class ExactFacts(unittest.TestCase):
    def test_identity_root_outside_source_domain(self):
        root = Fraction(2)
        self.assertTrue(Fraction(1) < root < Fraction(3))
        self.assertFalse(root > 100)

    def test_valid_identity_root(self):
        root = Fraction(102)
        self.assertTrue(101 < root < 103 and root > 100)

    def test_polynomial_eisenstein(self):
        # z^5 + 5z + 5: Eisenstein at p=5.
        lower_coefficients = [5, 5, 0, 0, 0]
        self.assertTrue(all(c % 5 == 0 for c in lower_coefficients))
        self.assertNotEqual(lower_coefficients[0] % 25, 0)

    def test_polynomial_strict_monotonicity_identity(self):
        # p'(t)=5(t^4+1)>0 for every real t, not just the sample values.
        coefficients = [5, 5, 0, 0, 0, 1]  # ascending powers
        derivative = [k*coefficients[k] for k in range(1, len(coefficients))]
        self.assertEqual(derivative, [5, 0, 0, 0, 5])
        self.assertTrue(all(5*(t**4+1)>0 for t in map(Fraction, range(-10,11))))

    def test_unique_real_root_bracket(self):
        p = lambda t: t**5 + 5*t + 5
        self.assertLess(p(Fraction(-1)), 0)
        self.assertGreater(p(Fraction(0)), 0)
        # Together with the proved derivative sign, these imply one real root.

    def test_sinh_lower_bound_growth(self):
        xs = [1/2, 1/4, 1/8, 1/16]
        values = [x*math.sinh(1/x) for x in xs]
        self.assertTrue(all(a < b for a,b in zip(values, values[1:])))

    def test_machine_low_included(self):
        self.assertTrue(native_integer(-(1<<63), 64))

    def test_machine_high_included(self):
        self.assertTrue(native_integer((1<<63)-1, 64))

    def test_machine_high_excluded(self):
        self.assertFalse(native_integer(1<<63, 64))

    def test_machine_low_excluded(self):
        self.assertFalse(native_integer(-(1<<63)-1, 64))

    def test_range_is_not_density_large_order(self):
        q = 1<<100
        nmin,nmax,den,span = grid([Fraction(0)], Fraction(q))
        self.assertEqual((nmin,nmax,den,span), (0,q,1,1))
        self.assertFalse(native_integer(nmax,64))

    def test_range_is_not_density_large_denominator(self):
        q = 1<<100
        nmin,nmax,den,span = grid([Fraction(1,q)],Fraction(3,q))
        self.assertEqual((nmin,nmax,den,span), (1,3,q,1))
        self.assertFalse(native_integer(den,64))

    def test_ordinary_grid(self):
        self.assertEqual(grid([Fraction(0),Fraction(1),Fraction(2)],Fraction(3)),
                         (0,3,1,3))

    def test_small_ramified_grid(self):
        self.assertEqual(grid([Fraction(1,2),Fraction(3,2)],Fraction(5,2)),
                         (1,5,2,3))

    def test_empty_support(self):
        self.assertEqual(grid([],Fraction(1,7)),(1,1,7,0))

    def test_negative_start(self):
        self.assertEqual(grid([Fraction(-2),Fraction(0)],Fraction(1)),(-2,1,1,3))

    def test_32_bit_boundary(self):
        self.assertFalse(native_integer(1<<31,32))
        self.assertTrue(native_integer((1<<31)-1,32))

    def test_requested_cutoff_not_actual_frontier(self):
        # A cutoff of 2 does not constrain the first omitted exact exponent.
        q = 1<<100
        self.assertLess(0,2)
        self.assertGreater(q,2)
        self.assertFalse(native_integer(q,64))


class PatchMechanics(unittest.TestCase):
    def test_unique_anchor(self):
        self.assertEqual(transform('before OLD after', [{'id':'t','old':'OLD','new':'NEW'}]),
                         'before NEW after')

    def test_missing_anchor_fails(self):
        with self.assertRaises(ValueError):
            transform('absent', [{'id':'t','old':'OLD','new':'NEW'}])

    def test_duplicate_anchor_fails(self):
        with self.assertRaises(ValueError):
            transform('OLD OLD', [{'id':'t','old':'OLD','new':'NEW'}])

    def test_supplied_rule_fixtures(self):
        rules = json.loads(Path(__file__).with_name('patch_rules.json').read_text())
        for rule in rules:
            self.assertEqual(transform(rule['old'], [rule]), rule['new'])

    def test_guard_precedes_dense_allocation_branch(self):
        rules = json.loads(Path(__file__).with_name('patch_rules.json').read_text())
        rule = next(r for r in rules if r['id']=='native-index-range')
        self.assertLess(rule['new'].index('NativeSeriesDataIndexRange'),
                        rule['new'].index('DenseSeriesDataLimit'))

if __name__ == '__main__':
    unittest.main(verbosity=2)
