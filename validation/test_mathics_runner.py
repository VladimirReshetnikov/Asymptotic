"""Offline checks for failure reporting and owned interpreter cleanup.

Run: python -m unittest discover -s validation -p test_mathics_runner.py
No Mathics or Wolfram installation is required. Temporary Python children
exercise the same process cleanup used for interpreter timeouts.
"""

from __future__ import annotations

from contextlib import redirect_stderr, redirect_stdout
import importlib.util
import io
import json
import os
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

    def test_native_timer_overflow_reports_failure_and_cleans_up_process(self) -> None:
        process = unittest.mock.Mock(returncode=-9)
        process.communicate.side_effect = [OverflowError("timer out of range"), (b"child diagnostic", None)]
        with patch.object(runner.subprocess, "Popen", return_value=process), \
                patch.object(runner, "stop_process_tree") as stop:
            result = runner.run_case(["fixture"], runner.SUITE, "fixture", "fixture",
                                     sys.float_info.max, self.work)
        stop.assert_called_once_with(process)
        self.assertEqual(result["Outcome"], "LaunchError")
        self.assertEqual(result["ExitCode"], -9)
        self.assertIn("child diagnostic", result["KernelOutput"])
        self.assertIn("Timer setup failed: OverflowError: timer out of range", result["KernelOutput"])
        self.assertEqual(process.communicate.call_args_list[-1], unittest.mock.call(timeout=10))


class PortableReportTests(unittest.TestCase):
    def test_output_cannot_overwrite_any_fingerprinted_input(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mathics-collision-test-") as temporary:
            directory = Path(temporary)
            kernel = directory / "src/Kernel"
            kernel.mkdir(parents=True)
            source = kernel / "AsymptoticAnalysis.wl"
            companion = kernel / "Companion.wl"
            suite = directory / "MathicsTests.wl"
            script = directory / "run_mathics_tests.py"
            protected = (source, companion, suite, script)
            for path in protected:
                path.write_bytes(b"protected input")
            for output in protected:
                with self.subTest(output=output.name):
                    args = ["run_mathics_tests.py", "--source", str(source), "--output", str(output)]
                    with patch.object(sys, "argv", args), patch.object(runner, "SUITE", suite), \
                            patch.object(runner, "__file__", str(script)), \
                            patch.object(runner, "available_cases", return_value=[("fixture", "fixture")]), \
                            patch.object(runner, "run_case") as run, \
                            patch.object(runner, "fingerprints") as fingerprints, redirect_stderr(io.StringIO()):
                        with self.assertRaises(SystemExit) as stopped:
                            runner.main()
                    self.assertEqual(stopped.exception.code, 2)
                    run.assert_not_called()
                    fingerprints.assert_not_called()
                    self.assertTrue(all(path.read_bytes() == b"protected input" for path in protected))

    def test_temporary_output_cannot_overwrite_source(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mathics-collision-test-") as temporary:
            output = Path(temporary) / "receipt"
            source = output.with_name(output.name + ".tmp")
            source.write_bytes(b"protected input")
            args = ["run_mathics_tests.py", "--source", str(source), "--output", str(output)]
            with patch.object(sys, "argv", args), patch.object(runner, "run_case") as run, \
                    redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as stopped:
                    runner.main()
            self.assertEqual(stopped.exception.code, 2)
            run.assert_not_called()
            self.assertEqual(source.read_bytes(), b"protected input")
            self.assertFalse(output.exists())

    def test_existing_hardlink_output_alias_is_protected(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mathics-collision-test-") as temporary:
            source = Path(temporary) / "source.wl"
            output = Path(temporary) / "report.json"
            source.write_bytes(b"protected input")
            try:
                os.link(source, output)
            except OSError as error:
                self.skipTest(f"Filesystem cannot create hardlinks: {error}")
            self.assertEqual(runner.report_input_collision(output, source), source)
            self.assertEqual(source.read_bytes(), b"protected input")

    def test_invalid_timeouts_fail_before_reporting_or_launching(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mathics-timeout-test-") as temporary:
            output = Path(temporary) / "report.json"
            for value in ("nan", "inf", "-inf", "0", "-1"):
                with self.subTest(timeout=value):
                    args = ["run_mathics_tests.py", "--timeout=" + value, "--output", str(output)]
                    errors = io.StringIO()
                    with patch.object(sys, "argv", args), patch.object(runner, "run_case") as run, \
                            patch.object(runner, "fingerprints") as fingerprints, redirect_stderr(errors):
                        with self.assertRaises(SystemExit) as stopped:
                            runner.main()
                    self.assertEqual(stopped.exception.code, 2)
                    self.assertIn("finite and positive", errors.getvalue())
                    run.assert_not_called()
                    fingerprints.assert_not_called()
                    self.assertFalse(output.exists())

    def test_relocated_modular_source_fingerprints_include_siblings(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mathics-fingerprint-test-") as temporary:
            kernel = Path(temporary) / "src/Kernel"
            kernel.mkdir(parents=True)
            source = kernel / "AsymptoticAnalysis.wl"
            source.write_text("entry", encoding="utf-8")
            module = kernel / "RefinementState.wl"
            module.write_text("original", encoding="utf-8")
            before = runner.fingerprints(source)
            module.write_text("modified", encoding="utf-8")
            after = runner.fingerprints(source)
            self.assertIn(str(module), before)
            self.assertNotEqual(before[str(module)], after[str(module)])
            self.assertEqual(before[str(source)], after[str(source)])

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

    def test_observed_source_change_remains_failure_after_restoration(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mathics-report-test-") as temporary:
            output = Path(temporary) / "report.json"
            args = ["run_mathics_tests.py", "--source", str(runner.SUITE), "--output", str(output)]
            result = {"Outcome": "Success", "TestID": "fixture", "ElapsedSeconds": 0.1}
            original, first_change, second_change = ({"source": value} for value in ("original", "first", "second"))
            with patch.object(sys, "argv", args), \
                    patch.object(runner, "available_cases", return_value=[("first", "fixture"), ("second", "fixture")]), \
                    patch.object(runner, "run_case", return_value=result), \
                    patch.object(runner, "fingerprints", side_effect=[original, original, first_change,
                                 second_change, original]), redirect_stdout(io.StringIO()):
                self.assertEqual(runner.main(), 1)
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertTrue(report["RunComplete"])
            self.assertFalse(report["SourcesUnchangedDuringRun"])
            self.assertEqual(report["Succeeded"], 2)
            self.assertEqual(report["FirstObservedChangedSourcesSHA256"], first_change)
            self.assertEqual(report["SourcesSHA256AfterRun"], original)


if __name__ == "__main__":
    unittest.main()
