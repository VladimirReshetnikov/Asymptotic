"""Offline checks for failure reporting and owned interpreter cleanup.

Run: python -m unittest discover -s validation -p test_mathics_runner.py
No Mathics or Wolfram installation is required. Temporary Python children
exercise the same process cleanup used for interpreter timeouts.
"""

from __future__ import annotations

from contextlib import redirect_stderr, redirect_stdout
import argparse
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
import venv


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


class PortableInputValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="mathics-input-test-")
        self.addCleanup(temporary.cleanup)
        self.work = Path(temporary.name)

    def test_timeout_accepts_finite_positive_values_through_daily_limit(self) -> None:
        for value in ("0.125", 180, "86400"):
            with self.subTest(value=value):
                self.assertEqual(runner.case_timeout(value), float(value))

    def test_timeout_rejects_nonfinite_nonpositive_oversized_and_nonnumeric_values(self) -> None:
        for value in ("nan", "inf", "-inf", "1e100", "86400.1", "0", "-1", "text"):
            with self.subTest(value=value), self.assertRaises(argparse.ArgumentTypeError):
                runner.case_timeout(value)

    def test_invalid_cli_timeouts_never_launch_a_case(self) -> None:
        for value in ("nan", "inf", "-inf", "1e100", "86400.1", "0", "-1"):
            args = ["run_mathics_tests.py", f"--timeout={value}"]
            with self.subTest(value=value), patch.object(sys, "argv", args), \
                    patch.object(runner, "run_case") as execute, redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as failure:
                    runner.main()
                self.assertEqual(failure.exception.code, 2)
                execute.assert_not_called()

    def test_direct_case_invalid_timeout_is_rejected_before_process_creation(self) -> None:
        with patch.object(runner.subprocess, "Popen") as process:
            with self.assertRaises(argparse.ArgumentTypeError):
                runner.run_case([sys.executable], runner.SUITE, "fixture", "fixture",
                                float("nan"), self.work)
            process.assert_not_called()

    def test_existing_executable_is_absolute_without_resolving_symlinks(self) -> None:
        executable = self.work / "directory with spaces" / "python"
        executable.parent.mkdir()
        executable.write_text("synthetic launcher", encoding="utf-8")
        relative = os.path.relpath(executable)
        with patch.object(Path, "resolve", side_effect=AssertionError("Do not dereference the launcher")):
            self.assertEqual(runner.executable_path(relative), os.path.abspath(relative))

    def test_bare_path_command_is_preserved(self) -> None:
        self.assertEqual(runner.executable_path("synthetic-python-on-PATH"), "synthetic-python-on-PATH")

    def test_existing_symlink_keeps_its_lexical_executable_path(self) -> None:
        launcher = self.work / "linked python"
        try:
            launcher.symlink_to(sys.executable)
        except (OSError, NotImplementedError) as error:
            self.skipTest(f"Executable symlinks unavailable: {error}")
        self.assertNotEqual(launcher.resolve(), launcher.absolute())
        self.assertEqual(runner.executable_path(str(launcher)), str(launcher.absolute()))

    def test_selected_virtual_environment_keeps_its_prefix_and_private_module(self) -> None:
        environment = self.work / "environment with spaces"
        venv.EnvBuilder(with_pip=False, symlinks=os.name != "nt").create(environment)
        executable = environment / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
        selected = runner.executable_path(str(executable))
        query = "import json,sys,sysconfig; print(json.dumps([sys.prefix,sysconfig.get_path('purelib')]))"
        prefix, purelib = json.loads(subprocess.check_output(
            [selected, "-c", query], cwd=self.work, text=True, timeout=20))
        self.assertEqual(Path(prefix).resolve(), environment.resolve())
        (Path(purelib) / "portable_environment_fixture.py").write_text("MARKER = 731\n", encoding="utf-8")
        value = subprocess.check_output(
            [selected, "-c", "import portable_environment_fixture as fixture; print(fixture.MARKER)"],
            cwd=self.work, text=True, timeout=20)
        self.assertEqual(value.strip(), "731")

    def test_main_preserves_selected_python_default_python_and_wolfram_paths(self) -> None:
        executable = self.work / "selected launcher"
        executable.write_text("synthetic launcher", encoding="utf-8")
        expected = os.path.abspath(os.path.relpath(executable))
        for selector in ("--python", "--wolfram", None):
            args = ["run_mathics_tests.py", "--source", str(runner.SUITE),
                    "--output", str(self.work / "report.json")]
            if selector:
                args.extend([selector, os.path.relpath(executable)])
            result = {"Outcome": "Success", "TestID": "fixture", "ElapsedSeconds": 0.1}
            with self.subTest(selector=selector), patch.object(sys, "argv", args), \
                    patch.object(sys, "executable", os.path.relpath(executable)), \
                    patch.object(runner, "available_cases", return_value=[("fixture", "fixture")]), \
                    patch.object(runner, "run_case", return_value=result) as execute, \
                    redirect_stdout(io.StringIO()):
                self.assertEqual(runner.main(), 0)
                self.assertEqual(execute.call_args.args[0][0], expected)


class PortableOutputProtectionTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="mathics-output-test-")
        self.addCleanup(temporary.cleanup)
        self.work = Path(temporary.name)
        self.source = self.work / "input.wl"
        self.source.write_text("original input", encoding="utf-8")

    def test_direct_and_relative_aliases_are_rejected(self) -> None:
        directory = self.work / "subdirectory"
        directory.mkdir()
        for output in (self.source, directory / ".." / self.source.name):
            with self.subTest(output=output), self.assertRaisesRegex(ValueError, "fingerprinted input"):
                runner.protect_output_inputs(output, {self.source})
        self.assertEqual(self.source.read_text(encoding="utf-8"), "original input")

    def test_staging_file_cannot_be_a_fingerprinted_input(self) -> None:
        source = self.work / "receipt.json.tmp"
        source.write_text("input with tmp suffix", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "fingerprinted input"):
            runner.protect_output_inputs(self.work / "receipt.json", {source})

    def test_hard_link_aliases_of_both_report_targets_are_rejected(self) -> None:
        for suffix in ("", ".tmp"):
            output = self.work / ("hard-link" + ("-staging" if suffix else "") + ".json")
            target = output.with_name(output.name + suffix)
            try:
                os.link(self.source, target)
            except (OSError, NotImplementedError) as error:
                self.skipTest(f"Hard links unavailable: {error}")
            with self.subTest(suffix=suffix), self.assertRaisesRegex(ValueError, "fingerprinted input"):
                runner.protect_output_inputs(output, {self.source})

    def test_symlink_aliases_of_both_report_targets_are_rejected(self) -> None:
        for suffix in ("", ".tmp"):
            output = self.work / ("symbolic-link" + ("-staging" if suffix else "") + ".json")
            target = output.with_name(output.name + suffix)
            try:
                target.symlink_to(self.source)
            except (OSError, NotImplementedError) as error:
                self.skipTest(f"File symlinks unavailable: {error}")
            with self.subTest(suffix=suffix), self.assertRaisesRegex(ValueError, "fingerprinted input"):
                runner.protect_output_inputs(output, {self.source})

    def test_all_fingerprinted_inputs_are_protected_before_main_launch(self) -> None:
        kernel = self.work / "src/Kernel"
        kernel.mkdir(parents=True)
        source = kernel / "AsymptoticAnalysis.wl"
        module = kernel / "Companion.wl"
        suite = self.work / "MathicsTests.wl"
        script = self.work / "run_mathics_tests.py"
        for path in (source, module, suite, script):
            path.write_text("protected input", encoding="utf-8")
        for target in (source, module, suite, script):
            args = ["run_mathics_tests.py", "--source", str(source), "--output", str(target)]
            with self.subTest(target=target), patch.object(sys, "argv", args), \
                    patch.object(runner, "SUITE", suite), patch.object(runner, "__file__", str(script)), \
                    patch.object(runner, "available_cases", return_value=[("fixture", "fixture")]), \
                    patch.object(runner, "run_case") as execute, redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as failure:
                    runner.main()
                self.assertEqual(failure.exception.code, 2)
                execute.assert_not_called()
                self.assertEqual(target.read_text(encoding="utf-8"), "protected input")

    def test_main_staging_collision_is_rejected_before_launch(self) -> None:
        source = self.work / "receipt.json.tmp"
        source.write_text("protected staged input", encoding="utf-8")
        output = self.work / "receipt.json"
        args = ["run_mathics_tests.py", "--source", str(source), "--output", str(output)]
        with patch.object(sys, "argv", args), \
                patch.object(runner, "available_cases", return_value=[("fixture", "fixture")]), \
                patch.object(runner, "run_case") as execute, redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as failure:
                runner.main()
            self.assertEqual(failure.exception.code, 2)
            execute.assert_not_called()
        self.assertEqual(source.read_text(encoding="utf-8"), "protected staged input")
        self.assertFalse(output.exists())

    def test_alias_created_after_launch_is_rejected_before_report_write(self) -> None:
        output = self.work / "report.json"
        staging = output.with_name(output.name + ".tmp")
        args = ["run_mathics_tests.py", "--source", str(self.source), "--output", str(output)]

        def execute(*_args):
            try:
                os.link(self.source, staging)
            except (OSError, NotImplementedError) as error:
                self.skipTest(f"Hard links unavailable: {error}")
            return {"Outcome": "Success", "TestID": "fixture", "ElapsedSeconds": 0.1}

        with patch.object(sys, "argv", args), \
                patch.object(runner, "available_cases", return_value=[("fixture", "fixture")]), \
                patch.object(runner, "run_case", side_effect=execute), \
                redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as failure:
                runner.main()
            self.assertEqual(failure.exception.code, 2)
        self.assertEqual(self.source.read_text(encoding="utf-8"), "original input")
        self.assertFalse(json.loads(output.read_text(encoding="utf-8"))["RunComplete"])

    def test_unrelated_existing_output_can_be_replaced(self) -> None:
        output = self.work / "report.json"
        output.write_text("old report", encoding="utf-8")
        args = ["run_mathics_tests.py", "--source", str(self.source), "--output", str(output)]
        result = {"Outcome": "Success", "TestID": "fixture", "ElapsedSeconds": 0.1}
        with patch.object(sys, "argv", args), \
                patch.object(runner, "available_cases", return_value=[("fixture", "fixture")]), \
                patch.object(runner, "run_case", return_value=result), redirect_stdout(io.StringIO()):
            self.assertEqual(runner.main(), 0)
        self.assertTrue(json.loads(output.read_text(encoding="utf-8"))["SourcesUnchangedDuringRun"])
        self.assertEqual(self.source.read_text(encoding="utf-8"), "original input")


class PortableReportTests(unittest.TestCase):
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

    def test_observed_source_change_stays_latched_after_restoration(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mathics-source-drift-test-") as temporary:
            source = Path(temporary) / "source.wl"
            source.write_text("original", encoding="utf-8")
            output = Path(temporary) / "report.json"
            args = ["run_mathics_tests.py", "--source", str(source), "--output", str(output)]

            def execute(command, selected_source, test_id, group, timeout, work):
                selected_source.write_text("changed" if test_id == "first" else "original", encoding="utf-8")
                return {"Outcome": "Success", "TestID": test_id, "ElapsedSeconds": 0.1}

            with patch.object(sys, "argv", args), \
                    patch.object(runner, "available_cases", return_value=[("first", "fixture"), ("second", "fixture")]), \
                    patch.object(runner, "run_case", side_effect=execute), redirect_stdout(io.StringIO()):
                self.assertEqual(runner.main(), 1)
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertTrue(report["RunComplete"])
            self.assertEqual(report["Succeeded"], 2)
            self.assertFalse(report["SourcesUnchangedDuringRun"])
            self.assertEqual(report["TestedSourcesSHA256"], report["SourcesSHA256AfterRun"])
            self.assertNotEqual(report["TestedSourcesSHA256"], report["FirstObservedSourceDriftSHA256"])
            self.assertEqual(report["Executed"], 2)
            self.assertEqual(report["NotRun"], 0)

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
