"""Independent arithmetic checks and patch mechanics; not a Wolfram emulator."""
from fractions import Fraction
from math import ceil, lcm
import cmath
import unittest
import harden_source as hs


def dense_span(exponents, remainder):
    values = [Fraction(x) for x in exponents]
    end = Fraction(remainder)
    den = lcm(*(x.denominator for x in values + [end]))
    start = min(values) if values else end
    return int((end - start) * den)


def retained_unit_depth(valuation, cutoff):
    # Number of positive integer k with k*valuation < cutoff.
    return max(0, ceil(Fraction(cutoff) / Fraction(valuation)) - 1)


def fixture():
    # Deliberately only the fetched source anchors, NOT a pretend full repository.
    return "\n".join([hs.OLD_POWER_SERIES, hs.OLD_COMPOSE,
        hs.PURE_REMAINDER_ANCHOR + ' If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module]]];',
        hs.DENSE_ANCHOR, hs.DENSE_ANCHOR])


class ArithmeticProofChecks(unittest.TestCase):
    def test_dense_thousand(self):
        self.assertEqual(dense_span([1, 1 + Fraction(1, 1000)], 2), 1000)
    def test_dense_billion_without_allocation(self):
        self.assertEqual(dense_span([1, 1 + Fraction(1, 10**9)], 2), 10**9)
    def test_sparse_count_constant(self):
        self.assertEqual(len([Fraction(1), Fraction(1) + Fraction(1, 10**9)]), 2)
    def test_joint_denominators(self):
        self.assertEqual(dense_span([Fraction(1, 3), Fraction(1, 5)], 1), 12)
    def test_empty_span(self):
        self.assertEqual(dense_span([], 2), 0)
    def test_fifty_blocks(self):
        self.assertEqual(1 + retained_unit_depth(Fraction(1, 50), 1), 50)
    def test_exclusive_boundary(self):
        self.assertEqual(retained_unit_depth(Fraction(1, 2), 2), 3)
    def test_noninteger_depth_boundary(self):
        self.assertEqual(retained_unit_depth(Fraction(2, 3), 1), 1)
    def test_negative_base_observable(self):
        self.assertEqual(1 + cmath.sqrt(-1), 1 + 1j)
    def test_assumption_specialization_counterexample(self):
        self.assertEqual(abs(-1), 1)
        self.assertNotEqual(abs(-1), -1)


class PatchMechanics(unittest.TestCase):
    def test_all_replacements(self):
        out, info = hs.patch_text(fixture())
        self.assertIn(hs.NEW_POWER_SERIES, out)
        self.assertIn(hs.NEW_COMPOSE, out)
        self.assertIn(hs.PURE_REMAINDER_FIX, out)
        self.assertEqual(out.count('Missing["DenseRepresentationLimit"'), 2)
        self.assertEqual(info["dense_limit"], 100000)
    def test_zero_composition_break_before_multiplication(self):
        self.assertLess(hs.NEW_COMPOSE.index('If[polyZeroQ'), hs.NEW_COMPOSE.index('pw = jetMul'))
    def test_different_dense_limit(self):
        out, _ = hs.patch_text(fixture(), 123)
        self.assertIn('nmax - nmin > 123', out)
    def test_nonpositive_limit_refused(self):
        with self.assertRaises(ValueError): hs.patch_text(fixture(), 0)
    def test_wrong_revision_refused(self):
        with self.assertRaises(ValueError): hs.identify_source(fixture().encode())
    def test_mismatched_anchor_refused(self):
        with self.assertRaises(ValueError): hs.patch_text(fixture().replace(hs.OLD_COMPOSE, 'changed'))
    def test_repeated_patch_refused(self):
        out, _ = hs.patch_text(fixture())
        with self.assertRaises(ValueError): hs.patch_text(out)
    def test_blob_framing(self):
        self.assertEqual(hs.git_blob_id(b''), 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391')


if __name__ == '__main__':
    unittest.main(verbosity=2)
