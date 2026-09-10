"""Offline integrity checks for the separate real-kernel loading integration.

python -m unittest discover -s validation -p test_mathics_loading.py
These tests exercise input protection and evidence invalidation; they do not
claim that any package or synthetic input was evaluated in a kernel.
"""

from contextlib import ExitStack, redirect_stderr, redirect_stdout
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

import check_mathics_loading as loading


class LoadingEvidenceTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="loading-integrity-test-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.kernel = self.root / "src/Kernel"
        self.kernel.mkdir(parents=True)
        self.validation = self.root / "validation"
        self.validation.mkdir()
        self.modular = self.kernel / "AsymptoticAnalysis.wl"
        self.companion = self.kernel / "Companion.wl"
        self.standalone = self.root / "AsymptoticAnalysis.wl"
        self.suite = self.validation / "MathicsTests.wl"
        self.runner = self.validation / "run_mathics_tests.py"
        self.checker = self.validation / "check_mathics_loading.py"
        self.requirements = self.validation / "requirements-mathics.txt"
        self.inputs = (self.modular, self.companion, self.standalone, self.suite,
                       self.runner, self.checker, self.requirements)
        for path in self.inputs:
            path.write_bytes(b"original input")
        self.suite.write_bytes(b'portableTest["primitive-check-is-unpolluted", "primitive", 2, 2];\n')
        self.originals = {path: path.read_bytes() for path in self.inputs}
        self.output = self.validation / "receipt.json"
        stack = self.enterContext(ExitStack())
        stack.enter_context(patch.object(loading, "ROOT", self.root))
        stack.enter_context(patch.object(loading, "__file__", str(self.checker)))
        stack.enter_context(patch.object(loading.runner, "SUITE", self.suite))
        stack.enter_context(patch.object(loading.runner, "__file__", str(self.runner)))

    def result(self, command, source, test_id, group, timeout, work) -> dict:
        reject = source not in (self.modular, self.standalone)
        return {"Outcome": "KernelError" if reject else "Success",
                "ExitCode": 2 if reject else 0, "Kernel": "Mathics3 10.0.1",
                "KernelIterationLimit": 1000000, "ElapsedSeconds": 0.01,
                "ActualOutput": "2", "ExpectedOutput": "2",
                "KernelOutput": loading.LOAD_FAILED + "\n" if reject else "",
                "TestID": test_id, "Group": group}

    def run_main(self, side_effect=None, output=None) -> int:
        args = ["check_mathics_loading.py", "--modular-source", str(self.modular),
                "--standalone-source", str(self.standalone), "--output", str(output or self.output)]
        with patch.object(sys, "argv", args), \
                patch.object(loading.runner, "run_case", side_effect=side_effect or self.result), \
                redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            return loading.main()

    def test_report_cannot_overwrite_either_layout_or_validation_input(self) -> None:
        for destination in self.inputs:
            with self.subTest(destination=destination.name), \
                    patch.object(loading, "source_hashes") as hashes:
                def unexpected_launch(*args):
                    self.fail("An input collision must be rejected before launching a kernel")
                with self.assertRaises(SystemExit) as stopped:
                    self.run_main(unexpected_launch, destination)
                self.assertEqual(stopped.exception.code, 2)
                hashes.assert_not_called()
                self.assertEqual({path: path.read_bytes() for path in self.inputs}, self.originals)

    def test_temporary_report_destination_is_protected_too(self) -> None:
        self.standalone = self.root / "report.json.tmp"
        self.standalone.write_bytes(b"protected standalone")
        with self.assertRaises(SystemExit) as stopped:
            self.run_main(output=self.root / "report.json")
        self.assertEqual(stopped.exception.code, 2)
        self.assertEqual(self.standalone.read_bytes(), b"protected standalone")
        self.assertFalse((self.root / "report.json").exists())

    def test_observed_companion_change_stays_invalid_after_restoration(self) -> None:
        count = 0

        def execute(*args):
            nonlocal count
            count += 1
            if count == 1:
                self.companion.write_bytes(b"interim changed module")
            elif count == 2:
                self.companion.write_bytes(self.originals[self.companion])
            return self.result(*args)

        self.assertEqual(self.run_main(execute), 1)
        report = json.loads(self.output.read_bytes())
        self.assertEqual(report["Succeeded"], report["Selected"])
        self.assertFalse(report["SourcesUnchangedDuringRun"])
        self.assertEqual(report["SourcesSHA256AfterRun"], report["TestedSourcesSHA256"])
        self.assertNotEqual(report["FirstObservedChangedSourcesSHA256"], report["TestedSourcesSHA256"])

    def test_added_modular_input_invalidates_the_original_fingerprint(self) -> None:
        def execute(*args):
            (self.kernel / "NewModule.wl").write_bytes(b"new package input")
            return self.result(*args)

        self.assertEqual(self.run_main(execute), 1)
        report = json.loads(self.output.read_bytes())
        self.assertFalse(report["SourcesUnchangedDuringRun"])
        self.assertNotIn("src/Kernel/NewModule.wl", report["TestedSourcesSHA256"])
        self.assertIn("src/Kernel/NewModule.wl", report["FirstObservedChangedSourcesSHA256"])

    def test_temporary_suite_change_stays_invalid_after_restoration(self) -> None:
        count = 0

        def execute(command, *args):
            nonlocal count
            count += 1
            Path(command[-1]).write_bytes(b"changed suite" if count == 1 else self.originals[self.suite])
            return self.result(command, *args)

        self.assertEqual(self.run_main(execute), 1)
        report = json.loads(self.output.read_bytes())
        self.assertTrue(report["SourcesUnchangedDuringRun"])
        self.assertFalse(report["TestSuiteCopyUnchangedDuringRun"])
        self.assertEqual(report["Succeeded"], report["Selected"])


if __name__ == "__main__":
    unittest.main()
