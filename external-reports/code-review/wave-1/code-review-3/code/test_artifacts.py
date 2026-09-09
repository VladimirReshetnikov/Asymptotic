"""Tests of the review artifacts, not tests of the upstream Wolfram package."""
from fractions import Fraction
import json
from pathlib import Path
import unittest

from harden_patch import PATCHES, patch_source
from verify_math import dense_slots, polynomial_mul, quadratic_inverse_coeff


class PatchGenerationTests(unittest.TestCase):
    def test_all_anchors_are_replaced(self):
        source = '\n(* fixture separator *)\n'.join(old * count for _, old, _, count in PATCHES)
        result = patch_source(source)
        for _, _, new, count in PATCHES:
            self.assertEqual(result.count(new), count)

    def test_missing_anchor_refuses_patch(self):
        with self.assertRaises(ValueError):
            patch_source('(* not the audited source *)')

    def test_extra_anchor_refuses_patch(self):
        source = '\n'.join(old * count for _, old, _, count in PATCHES)
        with self.assertRaises(ValueError):
            patch_source(source + '\n' + PATCHES[0][1])

    def test_json_patch_spec_matches_python(self):
        spec = json.loads(Path(__file__).with_name('patches.json').read_text(encoding='utf-8'))
        self.assertEqual(spec, [dict(name=n, old=o, new=v, expected=e) for n, o, v, e in PATCHES])


class MathematicalChecks(unittest.TestCase):
    def test_large_denominator_is_arithmetic_only(self):
        self.assertEqual(dense_slots([Fraction(1, 1_000_000_007)], Fraction(1)), 1_000_000_006)

    def test_empty_native_jet_needs_no_slots(self):
        self.assertEqual(dense_slots([], Fraction(3, 2)), 0)

    def test_exact_quadratic_composition(self):
        size = 18
        a = [Fraction(0)] + [quadratic_inverse_coeff(n) for n in range(1, size)]
        aa = polynomial_mul(a, a, size)
        self.assertEqual([a[i] + aa[i] for i in range(size)], [0, 1] + [0] * (size - 2))


if __name__ == '__main__':
    unittest.main()
