from pathlib import Path
import sys
import tempfile
import unittest

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE / "code"))
from emit_candidate_patch import OLD_LABEL, NEW_LABEL, changes, replace_once


class PatchTests(unittest.TestCase):
    def test_one_anchor_only(self):
        self.assertEqual(replace_once("one", "one", "two"), "two")
        for source in ["absent", "oneone"]:
            with self.assertRaises(ValueError):
                replace_once(source, "one", "two")

    def test_diagnostic_fixture(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            file = root / "src/Kernel/NumericalInverseChecks.wl"
            file.parent.mkdir(parents=True)
            original = '"LocalCoordinate" -> "' + OLD_LABEL + '"\n'
            file.write_text(original, encoding="utf-8")
            [(rel, old, new)] = list(changes(root, "diagnostics"))
            self.assertIn(NEW_LABEL, new)
            self.assertEqual(old, original)
            self.assertEqual(file.read_text(encoding="utf-8"), original)

    def test_assumption_fixture(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            file = root / "src/Kernel/MathicsInputAssumptions.wl"
            file.parent.mkdir(parents=True)
            original = ('ClearAll[mathicsProtectInputAssumptions];\n'
                        'mathicsProtectInputAssumptions[held_HoldComplete] := held;'
                        '\n\nIf[DownValues[mathicsOriginalInputCatch] === {}, Null];\n')
            file.write_text(original, encoding="utf-8")
            [(rel, old, new)] = list(changes(root, "assumptions"))
            self.assertIn("Last[position] === 0", new)
            self.assertIn("opaque = Position", new)
            self.assertNotIn("AsymptoticReview`ProtectInputAssumptions", new)
            self.assertTrue(new.endswith('If[DownValues[mathicsOriginalInputCatch] === {}, Null];\n'))
            self.assertEqual(file.read_text(encoding="utf-8"), original)

    def test_changed_boundaries_refused(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            file = root / "src/Kernel/MathicsInputAssumptions.wl"
            file.parent.mkdir(parents=True)
            file.write_text("different code", encoding="utf-8")
            with self.assertRaises(ValueError):
                list(changes(root, "assumptions"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
