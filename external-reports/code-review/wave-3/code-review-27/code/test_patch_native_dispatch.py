"""Patch-mechanism tests on source-excerpt fixtures, NOT native package tests."""
import tempfile
import subprocess
import sys
import unittest
from pathlib import Path
from patch_native_dispatch import (
    DEFAULT_OLD, DEFAULT_NEW, PREPARATION_MARKER, PREPARATION_END,
    PROTECTION_OLD, PROTECTION_NEW, SELECTOR_LINE, PatchError, patch_text)

# These anchors are transcribed from the pinned source. The fixture is not
# a full Wolfram program and is deliberately not described as one.
FIXTURE = (PREPARATION_MARKER + "\n   fixture comment *)\n" + SELECTOR_LINE +
           PREPARATION_END + DEFAULT_OLD + "\n" + PROTECTION_OLD + "\n")

class PatchTests(unittest.TestCase):
    def test_default_only(self):
        text, changes = patch_text(FIXTURE, ["defaults"])
        self.assertIn(DEFAULT_NEW, text)
        self.assertIn(PROTECTION_OLD, text)
        self.assertEqual(len(changes), 1)

    def test_keys_only(self):
        text, _ = patch_text(FIXTURE, ["option-keys"])
        self.assertEqual(text.count(SELECTOR_LINE), 1)
        self.assertLess(text.index(PREPARATION_END), text.index(SELECTOR_LINE))
        self.assertIn("HoldComplete[RuleDelayed[resolved, value]]", text)
        self.assertIn(DEFAULT_OLD, text)

    def test_callable_only(self):
        text, _ = patch_text(FIXTURE, ["callable-role"])
        self.assertIn(PROTECTION_NEW, text)
        self.assertIn("_InverseFunction | _ConditionalExpression", text)
        self.assertIn(DEFAULT_OLD, text)

    def test_combined(self):
        text, changes = patch_text(FIXTURE)
        self.assertEqual(len(changes), 3)
        self.assertIn(DEFAULT_NEW, text)
        self.assertIn(PROTECTION_NEW, text)

    def test_missing_anchor_refused(self):
        with self.assertRaises(PatchError):
            patch_text(FIXTURE.replace(DEFAULT_OLD, "different"))

    def test_duplicate_anchor_refused(self):
        with self.assertRaises(PatchError):
            patch_text(FIXTURE + DEFAULT_OLD)

    def test_second_application_refused(self):
        first, _ = patch_text(FIXTURE)
        with self.assertRaises(PatchError):
            patch_text(first)

    def test_crlf_preserved(self):
        text, _ = patch_text(FIXTURE.replace("\n", "\r\n"))
        self.assertNotIn("\n", text.replace("\r\n", ""))

    def test_bom_preserved(self):
        text, _ = patch_text("\ufeff" + FIXTURE)
        self.assertTrue(text.startswith("\ufeff"))

    def test_unknown_fix_refused(self):
        with self.assertRaises(PatchError):
            patch_text(FIXTURE, ["everything"])

    def test_duplicate_fix_refused(self):
        with self.assertRaises(PatchError):
            patch_text(FIXTURE, ["defaults", "defaults"])

    def test_no_requested_edits(self):
        text, changes = patch_text(FIXTURE, [])
        self.assertEqual(text, FIXTURE)
        self.assertEqual(changes, [])

    def test_actual_file_round_trip(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "source.wl"
            output = Path(directory) / "candidate.wl"
            source.write_bytes(FIXTURE.encode("utf-8"))
            script = Path(__file__).with_name("patch_native_dispatch.py")
            command = [sys.executable, str(script), str(source), str(output)]
            completed = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(completed.returncode, 0, completed.stderr)
            # Existing output and in-place requests must fail without touching input.
            refused = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(refused.returncode, 2)
            in_place = subprocess.run([sys.executable, str(script), str(source), str(source)],
                                      capture_output=True, text=True)
            self.assertEqual(in_place.returncode, 2)
            self.assertEqual(source.read_bytes(), FIXTURE.encode("utf-8"))
            self.assertIn(DEFAULT_NEW, output.read_text("utf-8"))

if __name__ == "__main__":
    unittest.main(verbosity=2)
