#!/usr/bin/env python3
"""Execute the unmodified upstream Python runner against a MOCK protocol peer.

No Wolfram Language code is evaluated. Every changed file is inside an owned
TemporaryDirectory. The exact upstream runner is supplied in ../upstream/.
"""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "code"))
from patch_portable_runner import patched_source

MOCK = r'''import json, os, sys
from pathlib import Path
case = os.environ["ASYMPTOTIC_PORTABLE_CASE"]
mode = os.environ["AUDIT_MODE"]
source = Path(os.environ["ASYMPTOTIC_PORTABLE_SOURCE"])
module = source.parent / "ProbeModule.wl"
with Path(os.environ["AUDIT_LAUNCH_LOG"]).open("a") as out:
    out.write(case + "\n")
if case == "drift-first" and mode in {"restore", "persistent"}:
    module.write_text("(* CHANGED DURING RUN *)\n")
if case == "drift-second" and mode == "restore":
    report = json.loads(Path(os.environ["AUDIT_REPORT"]).read_text())
    print("CHECKPOINT_MATCH_BEFORE_RESTORE=" + str(report["SourcesUnchangedDuringRun"]).lower())
    print("SECOND_CASE_READ_CHANGED_SOURCE=" + str("CHANGED" in module.read_text()).lower())
    module.write_text("(* ORIGINAL *)\n")
prefix = "ASYMPTOTIC_PORTABLE_"
print(prefix + "KERNEL\tMOCK protocol peer: NOT Mathics or Wolfram")
print(prefix + "ACTUAL_BEGIN")
print("1")
print(prefix + "ACTUAL_END")
print(prefix + "EXPECTED_BEGIN")
print("1")
print(prefix + "EXPECTED_END")
print(prefix + "RESULT\t" + case + "\tSuccess")
'''


def experiment(patched: bool, mode: str = "healthy", timeout: str = "5") -> dict:
    with tempfile.TemporaryDirectory(prefix="asymptotic-review-fixture-") as directory:
        root = Path(directory)
        validation = root / "validation"
        kernel = root / "src" / "Kernel"
        validation.mkdir(); kernel.mkdir(parents=True)
        original = (ROOT / "upstream" / "run_mathics_tests.py").read_bytes()
        runner = validation / "run_mathics_tests.py"
        runner.write_bytes(patched_source(original) if patched else original)
        (validation / "MathicsTests.wl").write_text(
            'portableTest["drift-first", "loading", 1, 1];\n'
            'portableTest["drift-second", "loading", 1, 1];\n')
        source = kernel / "AsymptoticAnalysis.wl"
        source.write_text("(* MOCK fixture, not the package *)\n")
        (kernel / "ProbeModule.wl").write_text("(* ORIGINAL *)\n")
        mock = root / "mock_kernel.py"
        mock.write_text("#!" + sys.executable + " -S\n" + MOCK)
        mock.chmod(0o700)
        output = root / "results.json"
        launches = root / "launches.txt"
        env = dict(os.environ, AUDIT_MODE=mode, AUDIT_REPORT=str(output), AUDIT_LAUNCH_LOG=str(launches))
        command = [sys.executable, "-S", str(runner), "--python", str(mock), "--source", str(source),
                   "--timeout=" + timeout, "--output", str(output)]
        started = time.monotonic()
        completed = subprocess.run(command, capture_output=True, text=True, env=env, timeout=15)
        report_text = output.read_text() if output.exists() else ""
        report = json.loads(report_text) if report_text else None
        rows = [] if not report else report.get("Results", [])
        answer = {
            "CandidatePatched": patched, "Mode": mode, "TimeoutArgument": timeout,
            "ExitCode": completed.returncode, "ElapsedSeconds": round(time.monotonic() - started, 4),
            "Peer": "Python mock; no WL evaluation", "ReportExists": report is not None,
            "KernelLaunchCount": len(launches.read_text().splitlines()) if launches.exists() else 0,
            "FinalSourcesUnchangedDuringRun": None if report is None else report["SourcesUnchangedDuringRun"],
            "NonfiniteNumericTokenInReport": ("NaN" if "NaN" in report_text else "Infinity" if "Infinity" in report_text else None),
            "RunComplete": None if report is None else report["RunComplete"],
            "Succeeded": None if report is None else report["Succeeded"],
            "ObservedMismatchBeforeRestore": any("CHECKPOINT_MATCH_BEFORE_RESTORE=false" in row["KernelOutput"] for row in rows),
            "SecondPeerReadChangedSource": any("SECOND_CASE_READ_CHANGED_SOURCE=true" in row["KernelOutput"] for row in rows),
            "SourceDriftObserved": None if report is None else report.get("SourceDriftObserved"),
            "Transcript": completed.stdout + completed.stderr,
            "PerCase": [{key: row[key] for key in ("TestID", "Outcome", "Kernel", "KernelOutput") if key in row} for row in rows],
        }
        # Reports contain only our fixture paths. Normalize ephemeral roots to
        # keep the published evidence readable; preserve every outcome.
        answer["Transcript"] = answer["Transcript"].replace(str(root), "<FIXTURE>")
        return answer


def run_all() -> list[dict]:
    results = [experiment(patched, mode) for patched in (False, True)
               for mode in ("healthy", "persistent", "restore")]
    results += [experiment(patched, timeout=value) for patched in (False, True)
                for value in ("nan", "inf", "0", "-1")]
    index = {(r["CandidatePatched"], r["Mode"], r["TimeoutArgument"]): r for r in results}
    for patched in (False, True):
        assert index[patched, "healthy", "5"]["ExitCode"] == 0
        assert index[patched, "persistent", "5"]["ExitCode"] == 1
    before, after = index[False, "restore", "5"], index[True, "restore", "5"]
    assert before["ExitCode"] == 0 and before["FinalSourcesUnchangedDuringRun"] is True
    assert before["ObservedMismatchBeforeRestore"] and before["SecondPeerReadChangedSource"]
    assert after["ExitCode"] == 1 and after["FinalSourcesUnchangedDuringRun"] is False
    assert after["SourceDriftObserved"] is True
    for value in ("nan", "inf", "0", "-1"):
        result = index[True, "healthy", value]
        assert result["ExitCode"] == 2 and result["KernelLaunchCount"] == 0
    return results


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "evidence" / "runner_experiments.json")
    args = parser.parse_args()
    results = run_all()
    record = {"EvidenceType": "Actual upstream Python runner with mocked external-kernel protocol",
              "WolframPackageExecuted": False, "MathicsPackageExecuted": False,
              "Python": sys.version, "Platform": platform.platform(),
              "UpstreamCommit": "7d1bc832895cc90a9b2a978b7b7684acab908bd2",
              "ScenarioCount": len(results), "AssertionsPassed": True, "Results": results}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(record, indent=2) + "\n")
    for row in results:
        print(row["CandidatePatched"], row["Mode"], row["TimeoutArgument"],
              "exit", row["ExitCode"], "match", row["FinalSourcesUnchangedDuringRun"],
              "launches", row["KernelLaunchCount"])
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
