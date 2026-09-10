"""Run portable package regressions in fresh Mathics or Wolfram kernels.

Install Mathics in an isolated environment with validation/requirements-mathics.txt, then:
  python validation/run_mathics_tests.py --python .venv/Scripts/python.exe
  python validation/run_mathics_tests.py --case 'inverse-*' --timeout 180
  python validation/run_mathics_tests.py --wolfram wolfram.exe --output native.json

The suite uses independent exact expected values on both kernels; explicitly
documented runtime-contract cases cover different native pre-evaluation of
InverseFunction. No MUnit or Mathics JSON exporter is needed. Every case has an
OS-enforced timeout and a fresh kernel, so an interpreter crash or unsupported operation cannot hide later
results. Failures, crashes, timeouts, protocol errors, and observed source changes
all produce a nonzero exit status. Timeouts must be finite, positive, and at most
86400 seconds. --list never starts a kernel.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import fnmatch
import hashlib
import json
import math
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]
SUITE = Path(__file__).with_name("MathicsTests.wl")
PREFIX = "ASYMPTOTIC_PORTABLE_"
MAX_CASE_TIMEOUT_SECONDS = 86400.0
CASE_PATTERN = re.compile(r'^portableTest\["([a-z0-9-]+)", "([a-z]+)",', re.MULTILINE)


def available_cases() -> list[tuple[str, str]]:
    cases = CASE_PATTERN.findall(SUITE.read_text(encoding="utf-8"))
    if not cases or len({name for name, _ in cases}) != len(cases):
        raise ValueError("The portable suite must declare unique test IDs")
    return cases


def fingerprinted_inputs(source: Path) -> set[Path]:
    files = {source, SUITE, Path(__file__).resolve()}
    if source.name == "AsymptoticAnalysis.wl" and source.parent.name == "Kernel":
        # --source can select a relocated modular tree, including an untouched
        # Wolfram baseline. Its sibling modules are part of the tested input.
        files.update(source.parent.glob("*.wl"))
    return files


def fingerprints(source: Path) -> dict[str, str]:
    return {
        path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else str(path):
        hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(fingerprinted_inputs(source))
    }


def executable_path(value: str) -> str:
    """Anchor an existing launcher without following a virtualenv symlink."""
    return os.path.abspath(value) if Path(value).is_file() else value


def case_timeout(value: str | float) -> float:
    try:
        seconds = float(value)
    except (ValueError, TypeError, OverflowError) as error:
        raise argparse.ArgumentTypeError("--timeout must be a number") from error
    if not math.isfinite(seconds) or not 0 < seconds <= MAX_CASE_TIMEOUT_SECONDS:
        raise argparse.ArgumentTypeError("--timeout must be finite and in (0, 86400] seconds")
    return seconds


def protect_output_inputs(output: Path, inputs: set[Path]) -> None:
    """Neither the report nor its staging file may alias a tested input."""
    for target in (output, output.with_name(output.name + ".tmp")):
        canonical = target.resolve()
        for source in inputs:
            # resolve covers relative paths and symlinks; samefile also covers
            # hard links, whose inode would be overwritten by write_text.
            if canonical == source.resolve() or (
                    target.exists() and source.exists() and target.samefile(source)):
                raise ValueError(f"Report target {target} aliases fingerprinted input {source}")


def as_text(output: bytes | str | None) -> str:
    return output.decode("utf-8", errors="replace") if isinstance(output, bytes) else output or ""


def parse_output(output: str, test_id: str, returncode: int | None) -> dict:
    """Only an explicit complete matching record can count as a success."""
    lines = output.splitlines()
    records = [line[len(PREFIX + "RESULT\t"):].split("\t") for line in lines
               if line.startswith(PREFIX + "RESULT\t")]
    result: dict = {}
    kernel = [line[len(PREFIX + "KERNEL\t"):] for line in lines
              if line.startswith(PREFIX + "KERNEL\t")]
    if kernel:
        result["Kernel"] = kernel[-1]
    iteration_limits = [line[len(PREFIX + "ITERATION_LIMIT\t"):] for line in lines
                        if line.startswith(PREFIX + "ITERATION_LIMIT\t")]
    if len(iteration_limits) == 1:
        text_limit = iteration_limits[0]
        result["KernelIterationLimit"] = int(text_limit) if text_limit.isdigit() else text_limit
    if returncode not in (0, 1):
        result["Outcome"] = "KernelError"
    elif len(records) != 1 or records[0][0] != test_id or len(records[0]) != 2:
        result["Outcome"] = "KernelError" if returncode else "ProtocolError"
    elif records[0][1] not in {"Success", "Failure"}:
        result["Outcome"] = "ProtocolError"
    elif returncode != (0 if records[0][1] == "Success" else 1):
        result["Outcome"] = "KernelError"
    else:
        result["Outcome"] = records[0][1]
    for field in ("Actual", "Expected"):
        start = PREFIX + field.upper() + "_BEGIN"
        end = PREFIX + field.upper() + "_END"
        if lines.count(start) == lines.count(end) == 1:
            first, last = lines.index(start), lines.index(end)
            if first < last:
                result[field + "Output"] = "\n".join(lines[first + 1:last])
    if result["Outcome"] in {"Success", "Failure"} and (
            len(kernel) != 1 or "ActualOutput" not in result or "ExpectedOutput" not in result):
        result["Outcome"] = "ProtocolError"
    return result


def run_case(command: list[str], source: Path, test_id: str, group: str,
             timeout: float, work: Path) -> dict:
    timeout = case_timeout(timeout)
    env = dict(os.environ, ASYMPTOTIC_PORTABLE_SOURCE=str(source),
               ASYMPTOTIC_PORTABLE_CASE=test_id, PYTHONIOENCODING="utf-8",
               PYTHONUNBUFFERED="1")
    for key in list(env):
        if key.upper() in {"WOLFRAMINIT", "MATHKERNELINIT"}:
            del env[key]
    started = time.monotonic()
    try:
        process = subprocess.Popen(command, cwd=work, env=env,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   start_new_session=os.name != "nt")
        try:
            captured, _ = process.communicate(timeout=timeout)
            output = as_text(captured)
            result = parse_output(output, test_id, process.returncode)
            result["ExitCode"] = process.returncode
        except subprocess.TimeoutExpired:
            # Windows virtual-environment Python is a redirector that launches
            # the real interpreter. Killing only the redirector leaves the
            # evaluation running and its stdout pipe open indefinitely.
            stop_process_tree(process)
            captured, _ = process.communicate(timeout=10)
            output = as_text(captured)
            result = {"Outcome": "Timeout", "ExitCode": process.returncode}
        except OverflowError as error:
            # A finite float can exceed the platform's native timer range.
            # Keep that configuration failure in the report and clean up the
            # process already launched before communicate rejected its timer.
            stop_process_tree(process)
            captured, _ = process.communicate(timeout=10)
            output = as_text(captured) + f"\nTimer setup failed: {type(error).__name__}: {error}\n"
            result = {"Outcome": "LaunchError", "ExitCode": process.returncode}
        except BaseException:
            stop_process_tree(process)
            process.communicate(timeout=10)
            raise
    except OSError as error:
        output = str(error)
        result = {"Outcome": "LaunchError", "ExitCode": None}
    result.update(TestID=test_id, Group=group,
                  ElapsedSeconds=round(time.monotonic() - started, 3))
    # Keep complete diagnostics; they are essential when Mathics leaves a
    # builtin unevaluated or raises a Python exception before a WL assertion.
    result["KernelOutput"] = output
    return result


def stop_process_tree(process: subprocess.Popen) -> None:
    """Terminate only the process group/tree owned by this test invocation."""
    if os.name == "nt":
        # Do this while the launcher still exists, so taskkill can discover its
        # descendants. No shell is involved and the PID comes directly from
        # Popen, never from a broad process-name match.
        subprocess.run(["taskkill.exe", "/PID", str(process.pid), "/T", "/F"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       check=False, timeout=10)
    else:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    if process.poll() is None:
        process.kill()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    runtime = parser.add_mutually_exclusive_group()
    runtime.add_argument("--python", default=None, help="Python containing Mathics3 (default: current Python)")
    runtime.add_argument("--wolfram", metavar="EXECUTABLE", help="Run the identical suite in an official kernel")
    parser.add_argument("--source", type=Path, default=ROOT / "src/Kernel/AsymptoticAnalysis.wl",
                        help="Package entry file; pass AsymptoticAnalysis.wl for the generated single file")
    parser.add_argument("--case", action="append", default=[], help="Test ID or shell wildcard; repeat to select several")
    parser.add_argument("--group", action="append", default=[], help="Select groups (see --list); repeat to select several")
    parser.add_argument("--timeout", type=case_timeout, default=180,
                        help="Finite hard seconds per fresh kernel, including startup (0 < seconds <= 86400; default: 180)")
    parser.add_argument("--output", type=Path, default=ROOT / "validation/mathics-tests.json")
    parser.add_argument("--list", action="store_true", help="List selected IDs and groups without running Mathics")
    args = parser.parse_args()
    all_cases = available_cases()
    unknown_groups = set(args.group) - {group for _, group in all_cases}
    unmatched_patterns = [pattern for pattern in args.case
                          if not any(fnmatch.fnmatchcase(name, pattern) for name, _ in all_cases)]
    if unknown_groups or unmatched_patterns:
        parser.error(f"Unknown groups: {sorted(unknown_groups)}; unmatched case patterns: {unmatched_patterns}")
    cases = [(name, group) for name, group in all_cases
             if (not args.group or group in args.group) and
             (not args.case or any(fnmatch.fnmatchcase(name, pattern) for pattern in args.case))]
    if not cases:
        parser.error("No cases selected")
    if args.list:
        for name, group in cases:
            print(f"{group}\t{name}")
        return 0
    source = args.source.resolve()
    if not source.is_file():
        parser.error(f"Package source does not exist: {source}")
    if args.wolfram:
        executable = executable_path(args.wolfram)
        command = [executable, "-noinit", "-script", str(SUITE)]
        runtime_name = "Wolfram"
    else:
        executable = executable_path(args.python or sys.executable)
        command = [executable, "-m", "mathics", "--quiet", "--no-readline", "--file", str(SUITE)]
        runtime_name = "Mathics"
    initial_inputs = fingerprinted_inputs(source)
    try:
        protect_output_inputs(args.output, initial_inputs)
    except ValueError as error:
        parser.error(str(error))
    before = fingerprints(source)
    suite_snapshot = SUITE.read_bytes()
    results = []
    first_source_drift = None

    def write_report(complete: bool) -> dict:
        nonlocal first_source_drift
        after = fingerprints(source)
        # The package tree remains live. Latch every observed mismatch; later
        # restoration cannot turn a mixed-source run into passing evidence.
        # Changes wholly between observations still require a frozen tree to
        # detect or prevent and are not certified by these comparisons.
        if after != before and first_source_drift is None:
            first_source_drift = after
        succeeded = sum(result["Outcome"] == "Success" for result in results)
        report = {
            "Runtime": runtime_name, "Command": command,
            "UTC": datetime.now(timezone.utc).isoformat(), "Source": str(source),
            "PerCaseTimeoutSeconds": args.timeout, "FreshKernelPerCase": True,
            "MathicsIterationLimitConfiguredBySuite": 1000000 if runtime_name == "Mathics" else None,
            "FullPackageSuiteRun": False, "RunComplete": complete, "Selected": len(cases),
            "TestSuiteSnapshotSHA256": hashlib.sha256(suite_snapshot).hexdigest(),
            "Executed": len(results), "Succeeded": succeeded, "Failed": len(results) - succeeded,
            "NotRun": len(cases) - len(results), "SourcesUnchangedDuringRun": first_source_drift is None,
            "TestedSourcesSHA256": before, "Results": results,
        }
        if first_source_drift is not None:
            report["SourcesSHA256AfterRun"] = after
            report["FirstObservedSourceDriftSHA256"] = first_source_drift
        # Recheck aliases before every write, including inputs added during a
        # run. This is an observed-path guard, not a hostile-filesystem lock.
        try:
            protect_output_inputs(args.output, initial_inputs | fingerprinted_inputs(source))
        except ValueError as error:
            parser.error(str(error))
        args.output.parent.mkdir(parents=True, exist_ok=True)
        temporary_output = args.output.with_name(args.output.name + ".tmp")
        temporary_output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        temporary_output.replace(args.output)
        return report

    write_report(False)
    with tempfile.TemporaryDirectory(prefix="asymptotic-portable-") as temporary:
        frozen_suite = Path(temporary) / SUITE.name
        frozen_suite.write_bytes(suite_snapshot)
        # Mathics streams the input file. Replacing an open file during test
        # development changes its byte offsets and can produce bogus syntax
        # failures. Use a private suite copy for this invocation, while the
        # original-source fingerprints still invalidate a changed-source run.
        frozen_command = command[:-1] + [str(frozen_suite)]
        for test_id, group in cases:
            print(f"Running {test_id} ...", flush=True)
            result = run_case(frozen_command, source, test_id, group, args.timeout, Path(temporary))
            results.append(result)
            write_report(False)
            print(f"  {result['Outcome']} ({result['ElapsedSeconds']:.3f}s)", flush=True)
            if result["Outcome"] == "LaunchError":
                # Repeating an absent executable cannot provide additional evidence.
                break
    report = write_report(True)
    succeeded = report["Succeeded"]
    print(f"Succeeded: {succeeded}; failed: {report['Failed']}; not run: {report['NotRun']}", flush=True)
    print(f"Report: {args.output.resolve()}", flush=True)
    return 0 if succeeded == len(cases) and report["SourcesUnchangedDuringRun"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
