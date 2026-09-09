"""Tests of the audit's tooling, NOT tests of the upstream Wolfram package.
SPDX-License-Identifier: MIT-0
"""
from fractions import Fraction
from pathlib import Path
import tempfile
import unittest
import apply_proposed_fixes as patch
from audit_oracles import dense_export_slots, multiindex_count, primitive_rational_lattice


class PatchToolTests(unittest.TestCase):
    def fixture(self):
        # Synthetic anchor fixture; this is explicitly not the full repository file.
        return "\n".join([patch.DENSE_ANCHOR] * 2 + [patch.POWER_ANCHOR] + [patch.LABEL_ANCHOR] * 2)

    def test_all_three_changes(self):
        result, counts = patch.transform(self.fixture())
        self.assertEqual(counts, {"F01": 2, "F02": 1, "F05": 2})
        self.assertEqual(result.count('Return[Missing["DenseRepresentationTooLarge"'), 2)
        self.assertIn('If[P =!= Infinity && ! IntegerQ[rr]', result)
        self.assertEqual(result.count(patch.LABEL_REPLACEMENT), 2)

    def test_missing_anchor_refused(self):
        with self.assertRaises(ValueError):
            patch.transform(self.fixture().replace(patch.POWER_ANCHOR, "", 1))

    def test_extra_anchor_refused(self):
        with self.assertRaises(ValueError):
            patch.transform(self.fixture() + "\n" + patch.DENSE_ANCHOR)

    def test_double_application_refused(self):
        result, _ = patch.transform(self.fixture())
        with self.assertRaises(ValueError):
            patch.transform(result)

    def test_git_empty_blob(self):
        self.assertEqual(patch.git_blob_id(b""), "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391")

    def test_unrelated_source_refused(self):
        with tempfile.TemporaryDirectory() as root:
            source = Path(root) / "wrong.wl"
            source.write_text("Not the audited package\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                patch.load_pinned(source)

    def test_atomic_replace(self):
        with tempfile.TemporaryDirectory() as root:
            source = Path(root) / "sample.txt"
            source.write_bytes(b"before")
            patch.atomic_replace(source, b"after\r\n")
            self.assertEqual(source.read_bytes(), b"after\r\n")


class IndependentPlanningTests(unittest.TestCase):
    def test_sparse_to_dense_width(self):
        self.assertEqual(dense_export_slots([Fraction(1, 10**9)], Fraction(1)), 999999999)

    def test_empty_series_width(self):
        self.assertEqual(dense_export_slots([], Fraction(2)), 0)

    def test_negative_power_backward_precision(self):
        target, valuation, exponent = 5, 1, -10
        required = target - (exponent - 1) * valuation
        self.assertEqual(required, 16)
        self.assertEqual((target + 2) + (exponent - 1) * valuation, -4)

    def test_primitive_lattice(self):
        base, degrees = primitive_rational_lattice([Fraction(2), Fraction(3)])
        self.assertEqual(base, 1)
        self.assertEqual(degrees, [2, 3])


if __name__ == "__main__":
    unittest.main(verbosity=2)
