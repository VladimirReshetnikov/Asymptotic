"""Patch-anchor fixture checks, not package integration tests."""
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "code"))
from patch_predicate import OLD, NEW, transform


class PatchTests(unittest.TestCase):
    def test_single_edit(self):
        source = "prefix\n" + OLD + "\nsuffix\n"
        self.assertEqual(transform(source), "prefix\n" + NEW + "\nsuffix\n")

    def test_missing_anchor(self):
        with self.assertRaises(ValueError):
            transform("unrelated source")

    def test_ambiguous_anchor(self):
        with self.assertRaises(ValueError):
            transform(OLD + "\n" + OLD)

    def test_already_patched(self):
        with self.assertRaises(ValueError):
            transform(NEW)


if __name__ == "__main__":
    unittest.main(verbosity=2)
