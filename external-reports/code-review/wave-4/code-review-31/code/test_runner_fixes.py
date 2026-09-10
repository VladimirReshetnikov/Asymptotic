"""Run with: python -m unittest discover -s code -p 'test_*.py' -v"""
from __future__ import annotations
import argparse
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import venv

from runner_fixes import interpreter_path, finite_positive_seconds
from apply_runner_patch import transform, CHANGES

class TimeoutValidation(unittest.TestCase):
    def test_positive_numbers(self):
        for value in (0.125, 1, "300", "1e3"):
            self.assertEqual(finite_positive_seconds(value), float(value))
    def test_nan_is_rejected(self):
        for value in ("nan", "NaN", float("nan")):
            with self.assertRaises(argparse.ArgumentTypeError): finite_positive_seconds(value)
    def test_infinities_are_rejected(self):
        for value in ("inf", "+Infinity", "-inf", float("inf"), -float("inf")):
            with self.assertRaises(argparse.ArgumentTypeError): finite_positive_seconds(value)
    def test_nonpositive_is_rejected(self):
        for value in (0, -1, -0.0, "-3"):
            with self.assertRaises(argparse.ArgumentTypeError): finite_positive_seconds(value)
    def test_bad_text_is_rejected(self):
        with self.assertRaises(argparse.ArgumentTypeError): finite_positive_seconds("not-a-timeout")
    def test_large_finite_timeout_rejected(self):
        for value in ("1e100", 86400.001):
            with self.assertRaises(argparse.ArgumentTypeError): finite_positive_seconds(value)
        self.assertEqual(finite_positive_seconds(86400), 86400)
    def test_original_guard_accepts_nonfinite(self):
        self.assertFalse(float("nan") <= 0)
        self.assertFalse(float("inf") <= 0)

class ExecutableSelection(unittest.TestCase):
    def test_path_lookup_is_preserved(self):
        self.assertEqual(interpreter_path("certainly-not-a-local-executable-42819"),
                         "certainly-not-a-local-executable-42819")
    def test_empty_rejected(self):
        with self.assertRaises(ValueError): interpreter_path("")
    def test_relative_path_and_spaces(self):
        with tempfile.TemporaryDirectory() as directory:
            old = os.getcwd()
            try:
                os.chdir(directory)
                Path("python with spaces").write_text("fixture")
                self.assertEqual(interpreter_path("python with spaces"),
                                 str(Path(directory) / "python with spaces"))
            finally: os.chdir(old)
    @unittest.skipUnless(os.name == "posix", "POSIX virtual-environment regression")
    def test_venv_identity_and_venv_only_import(self):
        with tempfile.TemporaryDirectory(prefix="asymptotic-venv-") as directory:
            env = Path(directory) / "env"
            venv.EnvBuilder(with_pip=False, symlinks=True).create(env)
            executable = env / "bin/python"
            self.assertTrue(executable.is_symlink())
            identify = ('import json,sys,sysconfig; print(json.dumps(dict('
                        'prefix=sys.prefix,base=sys.base_prefix,site=sysconfig.get_path("purelib"))))')
            def run(exe, script):
                return subprocess.run([str(exe), "-I", "-c", script], capture_output=True,
                                      text=True, timeout=10)
            selected = run(interpreter_path(str(executable)), identify)
            resolved = run(executable.resolve(), identify)
            self.assertEqual(selected.returncode, 0)
            self.assertEqual(resolved.returncode, 0)
            chosen = json.loads(selected.stdout); lost = json.loads(resolved.stdout)
            self.assertEqual(Path(chosen["prefix"]), env)
            self.assertNotEqual(Path(lost["prefix"]), env)
            site = Path(chosen["site"]); site.mkdir(parents=True, exist_ok=True)
            (site / "asymptotic_venv_only_witness.py").write_text("VALUE = 731\n")
            script = "import asymptotic_venv_only_witness as m; print(m.VALUE)"
            self.assertEqual(run(interpreter_path(str(executable)), script).stdout.strip(), "731")
            self.assertNotEqual(run(executable.resolve(), script).returncode, 0)

class PatchShape(unittest.TestCase):
    def fixture(self): return '\n'.join(before for before, after in CHANGES) + '\n'
    def test_each_correction_staged(self):
        result = transform(self.fixture())
        for before, after in CHANGES:
            self.assertIn(after, result)
    def test_changed_source_fails_closed(self):
        with self.assertRaises(ValueError): transform("changed implementation\n")
    def test_duplicate_fragment_fails_closed(self):
        with self.assertRaises(ValueError): transform(self.fixture() + "import json\n")
    def test_already_patched_fails_closed(self):
        with self.assertRaises(ValueError): transform(transform(self.fixture()))

if __name__ == "__main__": unittest.main()
