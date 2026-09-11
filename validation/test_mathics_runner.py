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
import re
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

    def test_output_overflow_is_terminal_even_after_a_success_record(self) -> None:
        # The kernel prints a complete success record and then floods stdout.
        # The bound stops it, keeps only the prefix, and the case cannot pass.
        flood = (f"print({record()!r}, flush=True)\n"
                 "import sys\n"
                 "while True:\n"
                 "    sys.stdout.write('x' * 65536)\n"
                 "    sys.stdout.flush()\n")
        started = time.monotonic()
        result = runner.run_case([sys.executable, "-c", flood], runner.SUITE, "fixture", "fixture",
                                 30, self.work, 200_000)
        self.assertEqual(result["Outcome"], "OutputOverflow")
        self.assertLess(time.monotonic() - started, 20)
        self.assertIn("Fixture kernel", result["KernelOutput"])
        self.assertIn("exceeded 200000 bytes", result["KernelOutput"])
        self.assertLess(len(result["KernelOutput"]), 200_000 + 200)

    def test_output_within_the_bound_is_kept_completely(self) -> None:
        command = [sys.executable, "-c", f"print('y' * 150_000); print({record()!r})"]
        result = runner.run_case(command, runner.SUITE, "fixture", "fixture", 30, self.work, 200_000)
        self.assertEqual(result["Outcome"], "Success", result["KernelOutput"][-500:])
        self.assertIn("y" * 150_000, result["KernelOutput"])

    def test_output_bound_must_be_a_positive_integer(self) -> None:
        for value in (0, -1, "abc", None):
            with self.subTest(value=value), patch.object(runner.subprocess, "Popen") as launch:
                with self.assertRaises(argparse.ArgumentTypeError):
                    runner.run_case([sys.executable], runner.SUITE, "fixture", "fixture", 1, self.work, value)
                launch.assert_not_called()

    def test_interrupt_cleans_up_the_owned_process_tree(self) -> None:
        process = unittest.mock.Mock(stdout=io.BytesIO(b""))
        process.wait.side_effect = [KeyboardInterrupt(), None]
        with patch.object(runner.subprocess, "Popen", return_value=process), \
                patch.object(runner, "stop_process_tree") as stop:
            with self.assertRaises(KeyboardInterrupt):
                runner.run_case(["fixture"], runner.SUITE, "fixture", "fixture", 1, self.work)
        stop.assert_called_once_with(process)

    def test_native_timer_overflow_reports_failure_and_cleans_up_process(self) -> None:
        process = unittest.mock.Mock(returncode=-9, stdout=io.BytesIO(b"child diagnostic"))
        process.wait.side_effect = [OverflowError("timer out of range"), None]
        with patch.object(runner.subprocess, "Popen", return_value=process), \
                patch.object(runner, "stop_process_tree") as stop:
            result = runner.run_case(["fixture"], runner.SUITE, "fixture", "fixture",
                                     180, self.work)
        stop.assert_called_once_with(process)
        self.assertEqual(result["Outcome"], "LaunchError")
        self.assertEqual(result["ExitCode"], -9)
        self.assertIn("child diagnostic", result["KernelOutput"])
        self.assertIn("Timer setup failed: OverflowError: timer out of range", result["KernelOutput"])
        self.assertEqual(process.wait.call_args_list[-1], unittest.mock.call(timeout=10))


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

    def test_invalid_cli_output_bounds_never_launch_a_case(self) -> None:
        output = self.work / "report.json"
        for value in ("0", "-5", "2.5", "many"):
            args = ["run_mathics_tests.py", f"--max-output-bytes={value}", "--output", str(output)]
            with self.subTest(value=value), patch.object(sys, "argv", args), \
                    patch.object(runner, "run_case") as execute, \
                    patch.object(runner, "fingerprints") as fingerprints, redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as failure:
                    runner.main()
                self.assertEqual(failure.exception.code, 2)
                execute.assert_not_called()
                fingerprints.assert_not_called()
                self.assertFalse(output.exists())

    def test_invalid_cli_timeouts_never_launch_a_case(self) -> None:
        output = self.work / "report.json"
        for value in ("nan", "inf", "-inf", "1e100", "86400.1", "0", "-1"):
            args = ["run_mathics_tests.py", f"--timeout={value}", "--output", str(output)]
            with self.subTest(value=value), patch.object(sys, "argv", args), \
                    patch.object(runner, "run_case") as execute, \
                    patch.object(runner, "fingerprints") as fingerprints, redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as failure:
                    runner.main()
                self.assertEqual(failure.exception.code, 2)
                execute.assert_not_called()
                fingerprints.assert_not_called()
                self.assertFalse(output.exists())

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
                    patch.object(runner, "run_case") as execute, \
                    patch.object(runner, "fingerprints") as fingerprints, redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as failure:
                    runner.main()
                self.assertEqual(failure.exception.code, 2)
                execute.assert_not_called()
                fingerprints.assert_not_called()
                self.assertTrue(all(path.read_text(encoding="utf-8") == "protected input"
                                    for path in (source, module, suite, script)))

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
        args = ["run_mathics_tests.py", "--source", str(self.source), "--output", str(output),
                "--max-output-bytes", "12345"]
        result = {"Outcome": "Success", "TestID": "fixture", "ElapsedSeconds": 0.1}
        with patch.object(sys, "argv", args), \
                patch.object(runner, "available_cases", return_value=[("fixture", "fixture")]), \
                patch.object(runner, "run_case", return_value=result) as execute, redirect_stdout(io.StringIO()):
            self.assertEqual(runner.main(), 0)
        report = json.loads(output.read_text(encoding="utf-8"))
        self.assertTrue(report["SourcesUnchangedDuringRun"])
        # The configured bound reaches every case and is recorded in the receipt.
        self.assertEqual(execute.call_args.args[-1], 12345)
        self.assertEqual(report["MaxOutputBytesPerCase"], 12345)
        self.assertEqual(self.source.read_text(encoding="utf-8"), "original input")


class PortableInventoryTests(unittest.TestCase):
    def test_unrecognized_declarations_are_rejected_not_omitted(self) -> None:
        definition = 'portableTest[id_String, group_String, actual_, expected_] := Null;\n'
        good = 'portableTest["good-case", "loading", True, True];\n'
        self.assertEqual(runner.suite_inventory(definition + good), [("good-case", "loading")])
        for bad in ('portableTest["Bad-Case", "loading", True, True];\n',
                    'portableTest[ "spaced-case", "loading", True, True];\n',
                    'portableTest["multi-line",\n  "loading", True, True];\n',
                    'portableTest["numeric-group", "group2", True, True];\n'):
            with self.subTest(bad=bad), self.assertRaisesRegex(ValueError, "Unrecognized portableTest declarations at lines \\[3\\]"):
                runner.suite_inventory(definition + good + bad)
        with self.assertRaisesRegex(ValueError, "unique test IDs"):
            runner.suite_inventory(definition + good + good)
        # A commented declaration is neither a case nor an error: it does not
        # start its line.
        self.assertEqual(runner.suite_inventory(definition + good + '(* portableTest["x", "y", 1, 1]; *)\n'),
                         [("good-case", "loading")])

    def test_workflow_shards_partition_the_suite_groups_exactly(self) -> None:
        # The CI matrix must run every group of the maintained suite exactly
        # once per layout: no group may be omitted, duplicated, or unknown.
        workflow = (runner.ROOT / ".github" / "workflows" / "mathics.yml").read_text(encoding="utf-8")
        shards = re.findall(r"^\s+([a-z]+)\) groups=\(([^)]*)\) ;;", workflow, re.MULTILINE)
        matrix = re.search(r"^\s+suite: \[([^\]]*)\]", workflow, re.MULTILINE)
        self.assertIsNotNone(matrix)
        self.assertEqual([name for name, _ in shards], [s.strip() for s in matrix.group(1).split(",")])
        assigned = [group for _, groups in shards for group in groups.split()]
        self.assertEqual(len(assigned), len(set(assigned)), f"A group is run twice: {assigned}")
        self.assertEqual(set(assigned), {group for _, group in runner.available_cases()})


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

            def execute(command, source, test_id, group, timeout, work, output_limit):
                frozen = Path(command[-1])
                self.assertNotEqual(frozen, suite)
                self.assertEqual(frozen.read_text(encoding="utf-8"), "original complete suite")
                suite.write_text("changed during development", encoding="utf-8")
                return {"Outcome": "Success", "TestID": test_id, "ElapsedSeconds": 0.1}

            with patch.object(sys, "argv", args), patch.object(runner, "SUITE", suite), \
                    patch.object(runner, "available_cases", return_value=[("first", "fixture"), ("second", "fixture")]), \
                    patch.object(runner, "run_case", side_effect=execute), redirect_stdout(io.StringIO()):
                self.assertEqual(runner.main(), 0)
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(report["Succeeded"], 2)
            # The kernels read the frozen suite and the frozen source copy, so
            # the live edit is reported but does not contaminate the evidence.
            self.assertTrue(report["SourcesUnchangedDuringRun"])
            self.assertTrue(report["LiveSourcesChangedDuringRun"])
            self.assertTrue(report["SourceSnapshot"])

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

            def execute(command, selected_source, test_id, group, timeout, work, output_limit):
                contents = {"first": "changed-first", "second": "changed-second", "third": "original"}
                selected_source.write_text(contents[test_id], encoding="utf-8")
                return {"Outcome": "Success", "TestID": test_id, "ElapsedSeconds": 0.1}

            with patch.object(sys, "argv", args), \
                    patch.object(runner, "available_cases", return_value=[("first", "fixture"), ("second", "fixture"), ("third", "fixture")]), \
                    patch.object(runner, "run_case", side_effect=execute), redirect_stdout(io.StringIO()):
                self.assertEqual(runner.main(), 1)
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertTrue(report["RunComplete"])
            self.assertEqual(report["Succeeded"], 3)
            self.assertFalse(report["SourcesUnchangedDuringRun"])
            self.assertEqual(report["TestedSourcesSHA256"], report["SourcesSHA256AfterRun"])
            self.assertNotEqual(report["TestedSourcesSHA256"], report["FirstObservedSourceDriftSHA256"])
            self.assertEqual(report["FirstObservedSourceDriftSHA256"][str(source)],
                             runner.hashlib.sha256(b"changed-first").hexdigest())
            self.assertEqual(report["Executed"], 3)
            self.assertEqual(report["NotRun"], 0)

    def test_live_source_change_is_reported_without_mixing_the_executed_snapshot(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mathics-live-drift-test-") as temporary:
            source = Path(temporary) / "source.wl"
            source.write_text("original", encoding="utf-8")
            output = Path(temporary) / "report.json"
            args = ["run_mathics_tests.py", "--source", str(source), "--output", str(output)]
            seen = []

            def execute(command, selected_source, test_id, group, timeout, work, output_limit):
                seen.append((selected_source, selected_source.read_text(encoding="utf-8")))
                source.write_text("edited during the run", encoding="utf-8")
                return {"Outcome": "Success", "TestID": test_id, "ElapsedSeconds": 0.1}

            with patch.object(sys, "argv", args), \
                    patch.object(runner, "available_cases", return_value=[("first", "fixture"), ("second", "fixture")]), \
                    patch.object(runner, "run_case", side_effect=execute), redirect_stdout(io.StringIO()):
                self.assertEqual(runner.main(), 0)
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertTrue(report["RunComplete"])
            self.assertEqual(report["Succeeded"], 2)
            self.assertTrue(report["SourcesUnchangedDuringRun"])
            self.assertTrue(report["LiveSourcesChangedDuringRun"])
            self.assertEqual(report["LiveSourcesSHA256AfterRun"][str(source)],
                             runner.hashlib.sha256(b"edited during the run").hexdigest())
            self.assertEqual(report["FirstObservedLiveSourceDriftSHA256"], report["LiveSourcesSHA256AfterRun"])
            self.assertNotIn("SourcesSHA256AfterRun", report)
            # Every kernel received the same frozen copy of the original bytes.
            self.assertEqual({path for path, _ in seen}, {Path(report["ExecutedSource"])})
            self.assertEqual({text for _, text in seen}, {"original"})
            self.assertEqual(report["ExecutedSourcesSHA256"], {"source.wl": runner.hashlib.sha256(b"original").hexdigest()})
            self.assertEqual(report["TestedSourcesSHA256"][str(source)], runner.hashlib.sha256(b"original").hexdigest())

    def test_modular_snapshot_copies_siblings_and_records_the_attempted_case(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mathics-modular-snapshot-test-") as temporary:
            kernel = Path(temporary) / "src/Kernel"
            kernel.mkdir(parents=True)
            source = kernel / "AsymptoticAnalysis.wl"
            source.write_text("entry", encoding="utf-8")
            (kernel / "RefinementState.wl").write_text("sibling", encoding="utf-8")
            (kernel / "init.m").write_text("init", encoding="utf-8")
            output = Path(temporary) / "report.json"
            args = ["run_mathics_tests.py", "--source", str(source), "--output", str(output)]
            observed = {}

            def execute(command, selected_source, test_id, group, timeout, work, output_limit):
                observed["entry"] = selected_source
                observed["files"] = sorted(path.name for path in selected_source.parent.iterdir())
                observed["in_progress"] = json.loads(output.read_text(encoding="utf-8")).get("InProgressCase")
                raise KeyboardInterrupt()

            with patch.object(sys, "argv", args), \
                    patch.object(runner, "available_cases", return_value=[("only", "fixture")]), \
                    patch.object(runner, "run_case", side_effect=execute), redirect_stdout(io.StringIO()):
                with self.assertRaises(KeyboardInterrupt):
                    runner.main()
            self.assertNotEqual(observed["entry"], source)
            self.assertEqual(observed["entry"].parent.name, "Kernel")
            self.assertEqual(observed["files"], ["AsymptoticAnalysis.wl", "RefinementState.wl", "init.m"])
            self.assertEqual(observed["in_progress"], "only")
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertFalse(report["RunComplete"])
            self.assertEqual(report["ExecutedSourcesSHA256"], {
                "AsymptoticAnalysis.wl": runner.hashlib.sha256(b"entry").hexdigest(),
                "RefinementState.wl": runner.hashlib.sha256(b"sibling").hexdigest()})

if __name__ == "__main__":
    unittest.main()
