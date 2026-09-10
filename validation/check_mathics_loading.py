"""Exercise the portable suite's load gate in fresh real kernels.

python validation/check_mathics_loading.py --python .venv/mathics/Scripts/python.exe
python validation/check_mathics_loading.py --wolfram wolfram.exe --output native-loading.json

Incomplete or aborted package inputs must stop before a builtin-only
assertion. Real modular and standalone packages and a legitimate wrapper
returning a non-Null value must pass that assertion.
This integration check requires Mathics or Wolfram; it is not an offline unit
test and is intentionally separate from test discovery and the portable case
inventory. Each process uses the runner's owned timeout/cleanup machinery.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sys
import tempfile

import run_mathics_tests as runner


ROOT = Path(__file__).resolve().parents[1]
TEST_ID = "primitive-check-is-unpolluted"
LOAD_FAILED = runner.PREFIX + "LOAD_FAILED"
FAKE_SOURCES = {
    "failed-get": "$Failed\n",
    "empty-get": "Null\n",
    "registered-but-empty": 'BeginPackage["AsymptoticAnalysis`"]; EndPackage[]; Null\n',
    "registered-but-failed": 'BeginPackage["AsymptoticAnalysis`"]; EndPackage[]; $Failed\n',
    "missing-public-context-path": (
        'BeginPackage["AsymptoticAnalysis`"]; EndPackage[]; '
        '$ContextPath = {"System`", "Global`"}; Null\n'),
    "unreturned-package-context": 'BeginPackage["AsymptoticAnalysis`"]; Null\n',
}
PACKAGE_WRAPPERS = {
    "aborted-after-package-load": ("$Aborted", True),
    "abort-after-package-load": ("Abort[]", True),
    "non-null-package-wrapper": ("42", False),
}


def file_label(path: Path) -> str:
    return path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else str(path)


def source_hashes(files: set[Path]) -> dict[str, str]:
    return {file_label(path): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in sorted(files)}


def rejected_before_assertion(result: dict) -> bool:
    lines = result["KernelOutput"].splitlines()
    return (result["Outcome"] == "KernelError" and result["ExitCode"] == 2 and
            isinstance(result.get("Kernel"), str) and lines.count(LOAD_FAILED) == 1 and
            not any(line.startswith(runner.PREFIX + "RESULT\t") for line in lines))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    runtime = parser.add_mutually_exclusive_group()
    runtime.add_argument("--python", help="Python containing Mathics3 (default: current Python)")
    runtime.add_argument("--wolfram", metavar="EXECUTABLE", help="Use an official Wolfram kernel")
    parser.add_argument("--modular-source", type=Path,
                        default=ROOT / "src/Kernel/AsymptoticAnalysis.wl")
    parser.add_argument("--standalone-source", type=Path, default=ROOT / "AsymptoticAnalysis.wl")
    parser.add_argument("--timeout", type=runner.case_timeout, default=90,
                        help="Finite hard seconds per fresh kernel (0 < seconds <= 86400)")
    parser.add_argument("--output", type=Path, default=ROOT / "validation/mathics-loading-tests.json")
    args = parser.parse_args()
    modular, standalone = args.modular_source.resolve(), args.standalone_source.resolve()
    for source in (modular, standalone):
        if not source.is_file():
            parser.error(f"Package source does not exist: {source}")
    def input_files() -> set[Path]:
        return (runner.fingerprinted_inputs(modular) | runner.fingerprinted_inputs(standalone) |
                {Path(__file__).resolve(), ROOT / "validation/requirements-mathics.txt"})

    inputs = input_files()
    try:
        runner.protect_output_inputs(args.output, inputs)
    except ValueError as error:
        parser.error(str(error))
    before = source_hashes(inputs)
    suite_bytes = runner.SUITE.read_bytes()
    suite_hash = hashlib.sha256(suite_bytes).hexdigest()
    if suite_hash != before[file_label(runner.SUITE)]:
        parser.error("Portable suite changed while preparing its immutable copy")
    if (TEST_ID, "primitive") not in runner.CASE_PATTERN.findall(suite_bytes.decode("utf-8")):
        parser.error(f"The selected portable suite lacks {TEST_ID}")
    runtime_name = "Wolfram" if args.wolfram else "Mathics"
    executable = runner.executable_path(args.wolfram or args.python or sys.executable)
    command = ([executable, "-noinit", "-script"] if args.wolfram else
               [executable, "-m", "mathics", "--quiet", "--no-readline", "--file"])
    results = []
    selected = len(FAKE_SOURCES) + len(PACKAGE_WRAPPERS) + 2
    first_changed_sources = None
    suite_copy_changed = False
    frozen_suite = None

    def write_report(complete: bool) -> dict:
        nonlocal first_changed_sources, suite_copy_changed
        after = source_hashes(input_files())
        if before != after and first_changed_sources is None:
            first_changed_sources = after
        if frozen_suite is not None:
            suite_copy_changed |= (not frozen_suite.exists() or
                                   hashlib.sha256(frozen_suite.read_bytes()).hexdigest() != suite_hash)
        passed = sum(row["Accepted"] for row in results)
        report = {
            "Scope": "PortableSuiteLoadGateIntegration", "Runtime": runtime_name,
            "UTC": datetime.now(timezone.utc).isoformat(), "CommandPrefix": command,
            "PerCaseTimeoutSeconds": args.timeout, "FreshKernelPerCase": True,
            "SelectedPortableTestID": TEST_ID, "Selected": selected,
            "Executed": len(results), "Succeeded": passed, "Failed": len(results) - passed,
            "NotRun": selected - len(results), "RunComplete": complete,
            "TestedSourcesSHA256": before, "TestSuiteSnapshotSHA256": suite_hash,
            "TestSuiteCopyUnchangedDuringRun": not suite_copy_changed,
            "SourcesUnchangedDuringRun": first_changed_sources is None,
            "RequirementsEvidence": "Input file hash only; observed kernel strings record runtime versions.",
            "Results": results,
        }
        if first_changed_sources is not None:
            report["FirstObservedSourceDriftSHA256"] = first_changed_sources
            report["SourcesSHA256AfterRun"] = after
        try:
            runner.protect_output_inputs(args.output, inputs | input_files())
        except ValueError as error:
            parser.error(str(error))
        args.output.parent.mkdir(parents=True, exist_ok=True)
        temporary_output = args.output.with_name(args.output.name + ".tmp")
        temporary_output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        temporary_output.replace(args.output)
        return report

    write_report(False)
    with tempfile.TemporaryDirectory(prefix="asymptotic-loading-") as temporary:
        directory = Path(temporary)
        frozen_suite = directory / runner.SUITE.name
        frozen_suite.write_bytes(suite_bytes)
        cases = []
        for name, body in FAKE_SOURCES.items():
            source = directory / (name + ".wl")
            source.write_bytes(body.encode("utf-8"))
            cases.append((name, source, True, body))
        cases.extend((("real-modular", modular, False, None),
                      ("real-standalone", standalone, False, None)))
        for name, (last_expression, reject) in PACKAGE_WRAPPERS.items():
            body = f"Get[{json.dumps(modular.as_posix())}]; {last_expression}\n"
            source = directory / (name + ".wl")
            source.write_bytes(body.encode("utf-8"))
            cases.append((name, source, reject, body))
        for name, source, reject, body in cases:
            print(f"Running loading integration {name} ...", flush=True)
            result = runner.run_case(command + [str(frozen_suite)], source, TEST_ID,
                                     "primitive", args.timeout, directory)
            accepted = rejected_before_assertion(result) if reject else (
                result["Outcome"] == "Success" and result["ExitCode"] == 0 and
                result.get("ActualOutput") == result.get("ExpectedOutput") == "2" and
                LOAD_FAILED not in result["KernelOutput"].splitlines())
            if runtime_name == "Mathics":
                accepted &= result.get("KernelIterationLimit") == 1000000
            row = {"CaseID": name, "Source": str(source),
                   "Expected": "LoadGuardRejectionBeforeAssertion" if reject else "SuccessfulAssertion",
                   "Accepted": bool(accepted), "Result": result}
            if body is not None:
                row["SyntheticSource"] = body
                row["SyntheticSourceSHA256"] = hashlib.sha256(body.encode("utf-8")).hexdigest()
            results.append(row)
            write_report(False)
            print(f"  {'Success' if accepted else 'Failure'} ({result['ElapsedSeconds']:.3f}s)", flush=True)
            if result["Outcome"] == "LaunchError":
                break
        report = write_report(True)
    print(f"Succeeded: {report['Succeeded']}; failed: {report['Failed']}; not run: {report['NotRun']}", flush=True)
    print(f"Report: {args.output.resolve()}", flush=True)
    return 0 if (report["Succeeded"] == report["Selected"] and
                 report["SourcesUnchangedDuringRun"] and report["TestSuiteCopyUnchangedDuringRun"]) else 1


if __name__ == "__main__":
    raise SystemExit(main())
