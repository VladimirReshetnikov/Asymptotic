"""Offline checks for failure reporting and owned interpreter cleanup.

Run: python -m unittest discover -s validation -p test_mathics_runner.py
No Mathics or Wolfram installation is required. Temporary Python children
exercise the same process cleanup used for interpreter timeouts.
"""

from __future__ import annotations

from contextlib import redirect_stdout
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location(
    "mathics_runner_under_test", Path(__file__).with_name("run_mathics_tests.py"))
assert SPEC is not None and SPEC.loader is not None
runner = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(runner)


def record(outcome: str = "Success", test_id: str = "fixture") -> str:
    prefix = runner.PREFIX
    return (f"{prefix}KERNEL\tFixture kernel\n"
            f"{prefix}ACTUAL_BEGIN\nactual\n{prefix}ACTUAL_END\n"
            f"{prefix}EXPECTED_BEGIN\nexpected\n{prefix}EXPECTED_END\n"
            f"{prefix}RESULT\t{test_id}\t{outcome}\n")


class PortableProtocolTests(unittest.TestCase):
    def test_completed_success_and_failure_are_distinct(self) -> None:
        for outcome, code in (("Success", 0), ("Failure", 1)):
            with self.subTest(outcome=outcome):
                result = runner.parse_output(record(outcome), "fixture", code)
                self.assertEqual(result["Outcome"], outcome)
                self.assertEqual(result["ActualOutput"], "actual")
                self.assertEqual(result["ExpectedOutput"], "expected")
                self.assertEqual(result["Kernel"], "Fixture kernel")

    def test_no_record_cannot_pass_even_with_successful_exit(self) -> None:
        self.assertEqual(runner.parse_output("", "fixture", 0)["Outcome"], "ProtocolError")
        self.assertEqual(runner.parse_output("Traceback\n", "fixture", 1)["Outcome"], "KernelError")

    def test_wrong_duplicate_or_incomplete_records_cannot_pass(self) -> None:
        for text in (record(test_id="another"), record() + record(),
                     record().replace("ACTUAL_END", "ACTUAL_INCOMPLETE"),
                     runner.PREFIX + "RESULT\tfixture\tSuccess\n",
                     record("Unknown")):
            with self.subTest(text=text):
                self.assertEqual(runner.parse_output(text, "fixture", 0)["Outcome"], "ProtocolError")

    def test_kernel_exit_status_must_agree_with_record(self) -> None:
        for outcome, code in (("Success", 1), ("Failure", 0), ("Success", 42)):
            self.assertEqual(runner.parse_output(record(outcome), "fixture", code)["Outcome"], "KernelError")

    def test_multiline_unicode_output_is_preserved(self) -> None:
        text = record().replace("\nactual\n", "\nfirst line\nλ + x²\n")
        self.assertEqual(runner.parse_output(text, "fixture", 0)["ActualOutput"], "first line\nλ + x²")

    def test_effective_iteration_limit_is_recorded(self) -> None:
        text = runner.PREFIX + "ITERATION_LIMIT\t1000000\n" + record()
        self.assertEqual(runner.parse_output(text, "fixture", 0)["KernelIterationLimit"], 1000000)


class PortableProcessTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="mathics-runner-test-")
        self.addCleanup(temporary.cleanup)
        self.work = Path(temporary.name)

    def test_missing_executable_reports_launch_error(self) -> None:
        result = runner.run_case([str(self.work / "absent-executable")], runner.SUITE,
                                 "fixture", "fixture", 1, self.work)
        self.assertEqual(result["Outcome"], "LaunchError")
        self.assertIsNone(result["ExitCode"])

    def test_real_process_returns_complete_record_and_diagnostics(self) -> None:
        command = [sys.executable, "-c", f"print({record()!r})"]
        result = runner.run_case(command, runner.SUITE, "fixture", "fixture", 10, self.work)
        self.assertEqual(result["Outcome"], "Success")
        self.assertIn("Fixture kernel", result["KernelOutput"])

    def test_timeout_terminates_spawned_descendant(self) -> None:
        # A surviving child changes the file continuously. This checks the
        # behavior across both Windows venv redirectors and POSIX process
        # groups without mistaking a terminated POSIX zombie for a live child.
        heartbeat = self.work / "heartbeat.txt"
        child = ("import pathlib,time; p=pathlib.Path(" + repr(str(heartbeat)) + "); "
                 "exec('while True:\\n p.write_text(str(time.time_ns()))\\n time.sleep(0.02)')")
        parent = ("import subprocess,sys,time; "
                  f"subprocess.Popen([sys.executable,'-c',{child!r}]); "
                  "print('child launched',flush=True); time.sleep(30)")
        started = time.monotonic()
        result = runner.run_case([sys.executable, "-c", parent], runner.SUITE,
                                 "fixture", "fixture", 1, self.work)
        self.assertEqual(result["Outcome"], "Timeout")
        self.assertIn("child launched", result["KernelOutput"])
        self.assertLess(time.monotonic() - started, 10)
        self.assertTrue(heartbeat.exists(), result["KernelOutput"])
        stopped_value = heartbeat.read_text()
        time.sleep(0.15)
        self.assertEqual(heartbeat.read_text(), stopped_value, "The timed-out child is still running")

    def test_interrupt_cleans_up_the_owned_process_tree(self) -> None:
        process = unittest.mock.Mock()
        process.communicate.side_effect = [KeyboardInterrupt(), (b"", None)]
        with patch.object(runner.subprocess, "Popen", return_value=process), \
                patch.object(runner, "stop_process_tree") as stop:
            with self.assertRaises(KeyboardInterrupt):
                runner.run_case(["fixture"], runner.SUITE, "fixture", "fixture", 1, self.work)
        stop.assert_called_once_with(process)


class PortableReportTests(unittest.TestCase):
    def test_running_cases_use_frozen_suite_bytes(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mathics-snapshot-test-") as temporary:
            suite = Path(temporary) / "suite.wl"
            suite.write_text("original complete suite", encoding="utf-8")
            output = Path(temporary) / "report.json"
            args = ["run_mathics_tests.py", "--source", str(suite), "--output", str(output)]

            def execute(command, source, test_id, group, timeout, work):
                frozen = Path(command[-1])
                self.assertNotEqual(frozen, suite)
                self.assertEqual(frozen.read_text(encoding="utf-8"), "original complete suite")
                suite.write_text("changed during development", encoding="utf-8")
                return {"Outcome": "Success", "TestID": test_id, "ElapsedSeconds": 0.1}

            with patch.object(sys, "argv", args), patch.object(runner, "SUITE", suite), \
                    patch.object(runner, "available_cases", return_value=[("first", "fixture"), ("second", "fixture")]), \
                    patch.object(runner, "run_case", side_effect=execute), redirect_stdout(io.StringIO()):
                self.assertEqual(runner.main(), 1)
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(report["Succeeded"], 2)
            self.assertFalse(report["SourcesUnchangedDuringRun"])

    def test_interrupted_run_preserves_completed_case_evidence(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mathics-report-test-") as temporary:
            output = Path(temporary) / "report.json"
            args = ["run_mathics_tests.py", "--source", str(runner.SUITE), "--output", str(output)]
            first = {"Outcome": "Success", "TestID": "first", "ElapsedSeconds": 0.1}
            with patch.object(sys, "argv", args), \
                    patch.object(runner, "available_cases", return_value=[("first", "fixture"), ("second", "fixture")]), \
                    patch.object(runner, "run_case", side_effect=[first, KeyboardInterrupt()]), \
                    redirect_stdout(io.StringIO()):
                with self.assertRaises(KeyboardInterrupt):
                    runner.main()
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertFalse(report["RunComplete"])
            self.assertEqual(report["Succeeded"], 1)
            self.assertEqual(report["Executed"], 1)
            self.assertEqual(report["NotRun"], 1)

    def test_changed_sources_force_failure_despite_successful_cases(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mathics-report-test-") as temporary:
            output = Path(temporary) / "report.json"
            args = ["run_mathics_tests.py", "--source", str(runner.SUITE), "--output", str(output)]
            result = {"Outcome": "Success", "TestID": "fixture", "ElapsedSeconds": 0.1}
            with patch.object(sys, "argv", args), \
                    patch.object(runner, "available_cases", return_value=[("fixture", "fixture")]), \
                    patch.object(runner, "run_case", return_value=result), \
                    patch.object(runner, "fingerprints", side_effect=[{"source": "before"},
                                 {"source": "before"}, {"source": "after"}, {"source": "after"}]), \
                    redirect_stdout(io.StringIO()):
                self.assertEqual(runner.main(), 1)
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertTrue(report["RunComplete"])
            self.assertFalse(report["SourcesUnchangedDuringRun"])
            self.assertEqual(report["Succeeded"], 1)


if __name__ == "__main__":
    unittest.main()
