"""Exercise the aggregate test runner's empty/aborted/export gates in isolation.

The runner src/Tests/RunTests.wl must exit nonzero when no .wlt file is
discovered, when a discovered file executes no test, when a test fails, or
when a requested JSON export cannot be written. It exits 0 only for a run
whose every file executed at least one passing test. This check copies the
kernel and the runner into a temporary tree with synthetic fixture files, so
it never touches the repository's own test suites and never runs them.

Run from the repository root:
  python validation/check_run_tests_gate.py [--wolfram wolfram] [--output receipt.json]
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "src" / "Tests" / "RunTests.wl"
KERNEL = ROOT / "src" / "Kernel"
PASSING = 'VerificationTest[1 + 1, 2, TestID -> "gate-fixture-pass"]\n'
FAILING = 'VerificationTest[1 + 1, 3, TestID -> "gate-fixture-fail"]\n'
EMPTY = "(* A test file without any VerificationTest. *)\n"

FIXTURES = [
    ("no-test-files", {}, None, 1),
    ("single-empty-file", {"Empty.wlt": EMPTY}, None, 1),
    ("single-passing-file", {"Pass.wlt": PASSING}, None, 0),
    ("passing-and-empty-files", {"Pass.wlt": PASSING, "Empty.wlt": EMPTY}, None, 1),
    ("passing-and-failing-files", {"Pass.wlt": PASSING, "Fail.wlt": FAILING}, None, 1),
    ("passing-with-export", {"Pass.wlt": PASSING}, "record.json", 0),
    ("passing-and-empty-with-export", {"Pass.wlt": PASSING, "Empty.wlt": EMPTY}, "record.json", 1),
    ("export-to-unavailable-drive", {"Pass.wlt": PASSING}, "Q:/asymptotic-no-such-drive/record.json", 1),
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run_fixture(wolfram: str, tree: Path, name: str, files: dict, export, expected: int) -> dict:
    tests = tree / "src" / "Tests"
    for old in tests.glob("*.wlt"):
        old.unlink()
    for filename, text in files.items():
        (tests / filename).write_text(text, encoding="utf-8")
    env = dict(os.environ)
    env.pop("ASYMPTOTIC_VALIDATION_OUTPUT", None)
    record_path = None
    if export:
        record_path = export if ":" in export[:3] else str(tree / export)
        env["ASYMPTOTIC_VALIDATION_OUTPUT"] = record_path
        if not export.startswith("Q:") and Path(record_path).exists():
            Path(record_path).unlink()
    proc = subprocess.run([wolfram, "-noinit", "-script", str(tests / "RunTests.wl")],
                          capture_output=True, text=True, env=env, timeout=600, cwd=str(tree))
    tail = [line for line in proc.stdout.splitlines() if line.strip()][-4:]
    record = None
    if record_path and Path(record_path).exists():
        with open(record_path, encoding="utf-8") as handle:
            data = json.load(handle)
        record = {key: data.get(key) for key in ("ExecutedTests", "RejectedSuites", "Succeeded", "Failed")}
    return {"Fixture": name, "Files": sorted(files), "Export": export, "ExpectedExitCode": expected,
            "ExitCode": proc.returncode, "Passed": proc.returncode == expected,
            "OutputTail": tail, "Record": record}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--wolfram", default="wolfram", help="Wolfram kernel executable (default: wolfram)")
    parser.add_argument("--output", default=None, help="Write a JSON receipt to this path")
    args = parser.parse_args()
    before = {"src/Tests/RunTests.wl": sha256(RUNNER)}
    with tempfile.TemporaryDirectory(prefix="asymptotic-gate-") as temp:
        tree = Path(temp)
        shutil.copytree(KERNEL, tree / "src" / "Kernel")
        (tree / "src" / "Tests").mkdir()
        shutil.copy(RUNNER, tree / "src" / "Tests" / "RunTests.wl")
        version = subprocess.run([args.wolfram, "-noinit", "-run", "Print[$Version]; Exit[]"],
                                 capture_output=True, text=True, timeout=300).stdout.strip().splitlines()[-1]
        results = [run_fixture(args.wolfram, tree, *fixture) for fixture in FIXTURES]
    unchanged = before == {"src/Tests/RunTests.wl": sha256(RUNNER)}
    passed = sum(r["Passed"] for r in results)
    receipt = {"Kernel": version, "Scope": "Synthetic runner-gate fixtures in a temporary tree; no repository test suite was run.",
               "Fixtures": results, "Passed": passed, "Failed": len(results) - passed,
               "RunnerUnchangedDuringRun": unchanged, "RunnerSHA256": before}
    for result in results:
        print(f"{'ok ' if result['Passed'] else 'BAD'} {result['Fixture']}: exit {result['ExitCode']} (expected {result['ExpectedExitCode']})")
    print(f"Kernel: {version}\nPassed: {passed}  Failed: {len(results) - passed}")
    if args.output:
        Path(args.output).write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    return 0 if passed == len(results) and unchanged else 1


if __name__ == "__main__":
    sys.exit(main())
