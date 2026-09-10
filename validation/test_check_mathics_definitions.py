"""Offline regression tests for native capture script isolation.

Run: python -m unittest discover -s validation -p test_check_mathics_definitions.py
The kernel process is mocked; no Wolfram installation is required.
"""
from contextlib import redirect_stdout
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location(
    "native_definitions_under_test", Path(__file__).with_name("check_mathics_definitions.py"))
assert SPEC is not None and SPEC.loader is not None
runner = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(runner)


class CaptureSnapshotTests(unittest.TestCase):
    def run_fixture(self, mutation=None):
        with tempfile.TemporaryDirectory(prefix="native-capture-test-") as temporary:
            work = Path(temporary)
            script = work / "capture.wl"
            script.write_bytes(b"original capture script")
            package = work / "AsymptoticAnalysis.wl"
            package.write_bytes(b"package fixture")
            output = work / "report.json"
            captures = work / "captures"
            args = ["check_mathics_definitions.py", "--baseline", str(work),
                    "--candidate", str(work), "--form", "standalone",
                    "--output", str(output), "--captures", str(captures)]
            calls = []

            def execute(command, **kwargs):
                frozen = Path(command[-1])
                self.assertNotEqual(frozen, script)
                self.assertEqual(frozen.read_bytes(), b"original capture script")
                calls.append(frozen)
                if mutation == "original" and len(calls) == 1:
                    script.write_bytes(b"edited during first kernel")
                elif mutation == "snapshot" and len(calls) == 1:
                    frozen.write_bytes(b"corrupted during first kernel")
                Path(kwargs["env"]["ASYMPTOTIC_NATIVE_OUTPUT"]).write_text(
                    json.dumps({"Passed": True}), encoding="utf-8")
                return subprocess.CompletedProcess(command, 0, b"fixture success")

            with patch.object(sys, "argv", args), patch.object(runner, "CAPTURE", script), \
                    patch.object(runner.subprocess, "run", side_effect=execute), \
                    patch.object(runner, "compare", return_value={"Passed": True}), \
                    redirect_stdout(io.StringIO()):
                code = runner.main()
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual((captures / script.name).read_bytes(), b"original capture script")
            return code, report, calls

    def test_unchanged_capture_uses_one_frozen_script_and_passes(self):
        code, report, calls = self.run_fixture()
        self.assertEqual(code, 0)
        self.assertEqual(len(calls), 2)
        self.assertEqual(calls[0], calls[1])
        checks = report["ToolImmutability"]
        self.assertTrue(checks["CaptureSnapshotMatchedSource"])
        self.assertTrue(checks["CaptureSnapshotUnchangedDuringRun"])
        self.assertTrue(checks["OriginalToolsUnchangedDuringRun"])
        self.assertEqual(checks["CaptureSnapshotSHA256"], report["ToolSHA256"]["capture.wl"])

    def test_original_edit_cannot_change_executed_script_or_pass(self):
        code, report, calls = self.run_fixture("original")
        self.assertEqual(code, 1)
        self.assertEqual(len(calls), 2)
        self.assertFalse(report["Passed"])
        self.assertTrue(report["ToolImmutability"]["CaptureSnapshotUnchangedDuringRun"])
        self.assertFalse(report["ToolImmutability"]["OriginalToolsUnchangedDuringRun"])

    def test_snapshot_edit_is_detected_before_another_kernel_starts(self):
        code, report, calls = self.run_fixture("snapshot")
        self.assertEqual(code, 1)
        self.assertEqual(len(calls), 1)
        self.assertFalse(report["Passed"])
        self.assertFalse(report["ToolImmutability"]["CaptureSnapshotUnchangedDuringRun"])
        self.assertTrue(report["ToolImmutability"]["OriginalToolsUnchangedDuringRun"])
        self.assertIn("Frozen native capture script changed",
                      report["Captures"]["Candidate-standalone"]["Error"])


if __name__ == "__main__":
    unittest.main()
