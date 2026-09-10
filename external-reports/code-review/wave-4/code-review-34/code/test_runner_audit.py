"""Execute the pinned upstream runner against deterministic fake processes.

These are tests OF the Python runner, not Mathics or Wolfram package tests.
The fake executable implements only the runner's documented stdout protocol.
"""
from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM = ROOT / "fixtures" / "run_mathics_tests_upstream.py"
OBSERVATIONS: list[dict] = []


def exercise(mode: str, timeout: str = "5", candidate: bool = False) -> dict:
    with tempfile.TemporaryDirectory(prefix="runner-audit-") as td:
        root = Path(td)
        val = root / "validation"
        val.mkdir()
        runner = val / "run_mathics_tests.py"
        text = UPSTREAM.read_text(encoding="utf-8")
        if candidate:
            from stage_runner_patch import patched_text
            text = patched_text(text)
        runner.write_text(text, encoding="utf-8")
        suite = val / "MathicsTests.wl"
        suite.write_text('portableTest["case-one", "test", 1, 1];\n'
                         'portableTest["case-two", "test", 2, 2];\n', encoding="utf-8")
        source = root / "AsymptoticAnalysis.wl"
        source.write_text("ORIGINAL\n", encoding="utf-8")
        output = root / "result.json"
        capture = root / "checkpoint.json"
        fake = root / "fake-kernel"
        # This is intentionally NOT a Wolfram interpreter. Its identity is
        # explicit in the protocol, evidence and article.
        fake.write_text(f'''#!{sys.executable}
import json, os, pathlib, sys, time
mode = {mode!r}
source = pathlib.Path(os.environ["ASYMPTOTIC_PORTABLE_SOURCE"])
case = os.environ["ASYMPTOTIC_PORTABLE_CASE"]
suite = pathlib.Path(sys.argv[-1])
report = pathlib.Path({str(output)!r})
capture = pathlib.Path({str(capture)!r})
actual = "CONTROL"
if mode == "sticky-change":
    if case == "case-one":
        source.write_text("CHANGED\\n", encoding="utf-8")
        actual = "changed source"
    else:
        old = json.loads(report.read_text())
        capture.write_text(json.dumps({{"SourcesUnchangedDuringRun": old["SourcesUnchangedDuringRun"]}}))
        source.write_text("ORIGINAL\\n", encoding="utf-8")
        actual = "restored source"
elif mode == "frozen-suite-change":
    if case == "case-one":
        suite.write_text("MUTATED SUITE\\n", encoding="utf-8")
        actual = "changed frozen suite"
    else:
        actual = suite.read_text().strip()
elif mode == "persistent-change":
    source.write_text("CHANGED\\n", encoding="utf-8")
    actual = "changed source"
elif mode == "sleep":
    time.sleep(0.25)
elif mode == "protocol-error":
    print("not a valid record")
    sys.exit(0)
print("ASYMPTOTIC_PORTABLE_KERNEL\\tPython fake protocol process (not a WL kernel)")
print("ASYMPTOTIC_PORTABLE_ACTUAL_BEGIN")
print(actual)
print("ASYMPTOTIC_PORTABLE_ACTUAL_END")
print("ASYMPTOTIC_PORTABLE_EXPECTED_BEGIN")
print(actual)
print("ASYMPTOTIC_PORTABLE_EXPECTED_END")
print("ASYMPTOTIC_PORTABLE_RESULT\\t" + case + "\\tSuccess")
''', encoding="utf-8")
        fake.chmod(0o755)
        command = [sys.executable, str(runner), "--wolfram", str(fake),
                   "--source", str(source), "--output", str(output),
                   "--timeout", timeout]
        p = subprocess.run(command, capture_output=True, text=True, timeout=15)
        report = json.loads(output.read_text()) if output.exists() else None
        prior = json.loads(capture.read_text()) if capture.exists() else None
        # No digest files or digest tables are exported. The upstream runner
        # creates temporary provenance fields; retain only relevant evidence.
        fields = ("RunComplete", "Selected", "Executed", "Succeeded", "Failed", "NotRun",
                  "SourcesUnchangedDuringRun", "SnapshotMatchedAtCheckpoints")
        observation = {
            "mode": mode, "timeout": timeout, "candidate": candidate,
            "exit_code": p.returncode,
            "intermediate_checkpoint": prior,
            "report": None if report is None else {k: report[k] for k in fields if k in report},
            "results": [] if report is None else [
                {k: r[k] for k in ("TestID", "Outcome", "ActualOutput") if k in r}
                for r in report["Results"]],
            "exception": next((name for name in ("ValueError", "OverflowError") if name in p.stderr), None),
            "stderr_last_lines": p.stderr.splitlines()[-3:],
        }
        OBSERVATIONS.append(observation)
        return observation


class UpstreamRunnerTests(unittest.TestCase):
    def test_control_success(self):
        r = exercise("control")
        self.assertEqual(r["exit_code"], 0)
        self.assertTrue(r["report"]["SourcesUnchangedDuringRun"])

    def test_detected_then_restored_change_is_erased(self):
        r = exercise("sticky-change")
        self.assertFalse(r["intermediate_checkpoint"]["SourcesUnchangedDuringRun"])
        self.assertTrue(r["report"]["SourcesUnchangedDuringRun"])
        self.assertEqual(r["exit_code"], 0)

    def test_frozen_suite_mutation_is_not_detected(self):
        r = exercise("frozen-suite-change")
        self.assertEqual(r["results"][1]["ActualOutput"], "MUTATED SUITE")
        self.assertTrue(r["report"]["SourcesUnchangedDuringRun"])
        self.assertEqual(r["exit_code"], 0)

    def test_persistent_source_change_is_detected_control(self):
        r = exercise("persistent-change")
        self.assertEqual(r["exit_code"], 1)
        self.assertFalse(r["report"]["SourcesUnchangedDuringRun"])

    def test_malformed_protocol_is_rejected_control(self):
        r = exercise("protocol-error")
        self.assertEqual(r["exit_code"], 1)
        self.assertEqual(r["results"][0]["Outcome"], "ProtocolError")

    def test_nonfinite_deadlines_reach_process_api(self):
        for value in ("nan", "inf", "1e100"):
            with self.subTest(timeout=value):
                r = exercise("sleep", value)
                self.assertNotEqual(r["exit_code"], 0)
                self.assertIsNotNone(r["exception"])
                self.assertEqual(r["report"]["Executed"], 0)
                self.assertFalse(r["report"]["RunComplete"])

    def test_candidate_keeps_detected_source_changes(self):
        r = exercise("sticky-change", candidate=True)
        self.assertEqual(r["exit_code"], 1)
        self.assertFalse(r["report"]["SourcesUnchangedDuringRun"])

    def test_candidate_rejects_frozen_suite_changes(self):
        r = exercise("frozen-suite-change", candidate=True)
        self.assertEqual(r["exit_code"], 1)
        self.assertFalse(r["report"]["SnapshotMatchedAtCheckpoints"])

    def test_candidate_rejects_bad_deadlines_before_launch(self):
        for value in ("nan", "inf", "1e100", "0", "-1"):
            with self.subTest(timeout=value):
                r = exercise("sleep", value, candidate=True)
                self.assertEqual(r["exit_code"], 2)
                self.assertIsNone(r["report"])
                self.assertIsNone(r["exception"])

    def test_candidate_success_control(self):
        r = exercise("control", candidate=True)
        self.assertEqual(r["exit_code"], 0)
        self.assertTrue(r["report"]["SnapshotMatchedAtCheckpoints"])


if __name__ == "__main__":
    program = unittest.main(exit=False, verbosity=2)
    target = ROOT / "evidence" / "runner-observations.json"
    target.write_text(json.dumps({"evidence_kind": "Python runner tests, fake protocol processes; not WL package execution",
                                 "observations": OBSERVATIONS}, indent=2) + "\n", encoding="utf-8")
    raise SystemExit(not program.result.wasSuccessful())
