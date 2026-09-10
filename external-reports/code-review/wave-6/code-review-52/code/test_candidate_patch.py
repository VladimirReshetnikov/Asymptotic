"""Tests the staging algorithm on synthetic source fragments, not the package."""
import tempfile
import unittest
from pathlib import Path
from candidate_patch import REPLACEMENTS, stage, transform


class PatchTests(unittest.TestCase):
    def test_each_anchor(self):
        for path, entries in REPLACEMENTS.items():
            with self.subTest(path=path):
                source = "\n".join(old for _, old, _ in entries)
                result, receipts = transform(source, entries)
                self.assertEqual(len(receipts), len(entries))
                for _, _, new in entries:
                    self.assertIn(new, result)

    def test_missing_anchor_refused(self):
        with self.assertRaises(ValueError):
            transform("not the source", [("test", "missing", "replacement")])

    def test_duplicate_anchor_refused(self):
        with self.assertRaises(ValueError):
            transform("a a", [("test", "a", "b")])

    def test_stage_leaves_inputs_unchanged(self):
        with tempfile.TemporaryDirectory() as temp:
            root, output = Path(temp) / "input", Path(temp) / "output"
            originals = {}
            for path, entries in REPLACEMENTS.items():
                p = root / path
                p.parent.mkdir(parents=True, exist_ok=True)
                originals[path] = "\n".join(old for _, old, _ in entries) + "\n"
                p.write_text(originals[path], encoding="utf-8")
            report = stage(root, output, True)
            self.assertFalse(report["InputCheckoutModified"])
            self.assertEqual(len(report["Changes"]), 4)
            self.assertTrue((output / "candidate.patch").is_file())
            for path, text in originals.items():
                self.assertEqual((root / path).read_text(encoding="utf-8"), text)

    def test_no_output_on_stale_input(self):
        with tempfile.TemporaryDirectory() as temp:
            root, output = Path(temp) / "input", Path(temp) / "output"
            root.mkdir()
            with self.assertRaises(FileNotFoundError):
                stage(root, output, True)
            self.assertFalse(output.exists())

    def test_refuses_output_inside_checkout(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            with self.assertRaises(ValueError):
                stage(root, root / "output", True)


if __name__ == "__main__":
    unittest.main(verbosity=2)
