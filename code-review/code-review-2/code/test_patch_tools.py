"""Tests patch machinery only. These do not validate Wolfram semantics."""
import importlib.util
import unittest
from pathlib import Path
spec = importlib.util.spec_from_file_location("patches", Path(__file__).resolve().parents[1] / "patches" / "apply_review_patches.py")
p = importlib.util.module_from_spec(spec)
spec.loader.exec_module(p)
class PatchToolsTests(unittest.TestCase):
    def synthetic(self):
        return "\n".join([p.OLD_PRECISION, p.OLD_POWER, p.OLD_EXACT, p.OLD_EXACT, p.OLD_DENSE, p.OLD_DENSE])
    def test_all_anchors_replaced(self):
        new = p.transform_core(self.synthetic())
        self.assertIn(p.NEW_PRECISION, new)
        self.assertIn(p.NEW_POWER, new)
        self.assertEqual(new.count('"LogarithmicRemainder"'), 2)
        self.assertEqual(new.count('"DenseSeriesDataBudget"'), 2)
    def test_reapplication_refused(self):
        with self.assertRaises(ValueError): p.transform_core(p.transform_core(self.synthetic()))
    def test_missing_anchor_refused(self):
        with self.assertRaises(ValueError): p.transform_core("")
    def test_extra_anchor_refused(self):
        with self.assertRaises(ValueError): p.transform_core(self.synthetic() + p.OLD_PRECISION)
    def test_flat_extension(self):
        self.assertEqual(p.replace_checked(p.OLD_FLAT, p.OLD_FLAT, p.NEW_FLAT, 1, "flat"), p.NEW_FLAT)
    def test_blob_hash(self):
        self.assertEqual(p.git_blob_hash(""), "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391")
if __name__ == "__main__": unittest.main()
