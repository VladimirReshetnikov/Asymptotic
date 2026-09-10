"""Fresh-kernel, fail-closed execution of the supplied (previously unrun) probes.

Example (from the bundle directory):
  python code/run_probes.py --repo C:\\src\\Asymptotic --python C:\\venv\\Scripts\\python.exe
  python code/run_probes.py --repo C:\\src\\Asymptotic --wolfram wolfram.exe

No downloads, source edits, or remote actions are performed. A timeout kills
only this runner's process tree. Results are runtime observations, not a full
upstream acceptance report. SPDX-License-Identifier: MIT-0
"""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
PROBES = {
    "bridge-principal": "{ProductLog[0, E], ProductLog[E]} === {1, 1}",
    "bridge-minus-one": '''Module[{s, value},
  s = AsymptoticCoreInverse[-x Log[x], 0, {x, 0}, {y, 0}];
  If[Head[s] =!= GeneralizedSeries, False,
    value = N[s[1/10], 40];
    {TrueQ[NumericQ[value]], TrueQ[Abs[Im[value]] < 10^-25],
     TrueQ[0 < Re[value] < 1/E],
     TrueQ[Abs[-value Log[value] - 1/10] < 10^-25]} ===
      {True, True, True, True}]]''',
    "empty-index-reuse": '''Module[{model, index = {}, coefficient, reuse},
  model = PowerLogModel[x, {x, 0}];
  coefficient = InverseExpansionCoefficient[model, index];
  reuse = {index, 2, 0};
  {coefficient["Coefficient"], reuse} === {1, {{}, 2, 0}}]''',
    "limit-default-contract": '''Module[{answer},
  answer = If[StringContainsQ[$Version, "Mathics"],
    AsymptoticAnalysis`Mathics`Limit[Abs[x]/x, x -> 0],
    System`Limit[Abs[x]/x, x -> 0]];
  answer === Indeterminate]''',
    "first-position-short-circuit": '''Module[{calls = 0, answer, probePredicate},
  probePredicate[z_] := (calls++; IntegerQ[z]);
  answer = If[StringContainsQ[$Version, "Mathics"],
    AsymptoticAnalysis`Mathics`FirstPosition[Range[32],
      _?probePredicate, Missing["NotFound"], {1}, Heads -> False],
    System`FirstPosition[Range[32], _?probePredicate,
      Missing["NotFound"], {1}, Heads -> False]];
  {answer, calls} === {{1}, 1}]''',
}


def stop_tree(process: subprocess.Popen) -> None:
    if os.name == "nt":
        subprocess.run(["taskkill.exe", "/PID", str(process.pid), "/T", "/F"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       timeout=10, check=False)
    else:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    if process.poll() is None:
        process.kill()


def script_for(expression: str) -> str:
    # Separate top-level input expressions intentionally: Mathics 10 Check can
    # be polluted by Print in the same input evaluation. Print only afterwards.
    return '''probeSource = Environment["ASYMPTOTIC_REVIEW_SOURCE"];
If[StringContainsQ[$Version, "Mathics"], $IterationLimit = 1000000];
probeLoad = Check[Get[probeSource], $Failed];
If[probeLoad === $Failed, Print["REVIEW_LOAD_ERROR"]; Exit[2]];
probeActual = (''' + expression + ''');
Print["REVIEW_KERNEL\\t", $Version];
Print["REVIEW_ACTUAL\\t", ToString[probeActual, InputForm]];
Print["REVIEW_RESULT\\t", If[TrueQ[probeActual], "PASS", "FAIL"]];
Exit[If[TrueQ[probeActual], 0, 1]];
'''


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", required=True, type=Path)
    runtime = parser.add_mutually_exclusive_group()
    runtime.add_argument("--python", default=None)
    runtime.add_argument("--wolfram", default=None)
    parser.add_argument("--entry", choices=["modular", "standalone"], default="modular")
    parser.add_argument("--case", action="append", choices=sorted(PROBES))
    parser.add_argument("--timeout", type=float, default=180)
    parser.add_argument("--output", type=Path, default=ROOT/"evidence"/"local-probe-run.json")
    args=parser.parse_args()
    if args.timeout <= 0:
        parser.error("timeout must be positive")
    source=args.repo.resolve() / ("src/Kernel/AsymptoticAnalysis.wl"
                                 if args.entry == "modular" else "AsymptoticAnalysis.wl")
    if not source.is_file():
        parser.error(f"source not found: {source}")
    program=args.wolfram or args.python or sys.executable
    executable=shutil.which(program) or (str(Path(program).resolve()) if Path(program).is_file() else None)
    if executable is None:
        parser.error(f"executable not found: {program}")
    cases=args.case or list(PROBES)
    records=[]
    with tempfile.TemporaryDirectory(prefix="asymptotic-review-") as temporary:
        for case in cases:
            script=Path(temporary)/(case+".wl")
            script.write_text(script_for(PROBES[case]),encoding="utf-8")
            command=([executable,"-noinit","-script",str(script)] if args.wolfram else
                     [executable,"-m","mathics","--quiet","--no-readline","--file",str(script)])
            env=dict(os.environ, ASYMPTOTIC_REVIEW_SOURCE=str(source),
                     PYTHONIOENCODING="utf-8", PYTHONUNBUFFERED="1")
            for key in list(env):
                if key.upper() in {"WOLFRAMINIT", "MATHKERNELINIT"}:
                    del env[key]
            start=time.monotonic()
            output=""; code=None; outcome="LaunchError"
            try:
                process=subprocess.Popen(command,cwd=temporary,env=env,
                                         stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
                                         start_new_session=os.name != "nt")
                try:
                    captured,_=process.communicate(timeout=args.timeout)
                    output=captured.decode("utf-8",errors="replace"); code=process.returncode
                    records_in_output=[line for line in output.splitlines()
                                       if line.startswith("REVIEW_RESULT\t")]
                    if "REVIEW_LOAD_ERROR" in output:
                        outcome="LoadError"
                    elif code == 0 and records_in_output == ["REVIEW_RESULT\tPASS"]:
                        outcome="Pass"
                    elif code == 1 and records_in_output == ["REVIEW_RESULT\tFAIL"]:
                        outcome="Fail"
                    else:
                        outcome="KernelOrProtocolError"
                except subprocess.TimeoutExpired:
                    stop_tree(process); captured,_=process.communicate(timeout=10)
                    output=captured.decode("utf-8",errors="replace")
                    code=process.returncode; outcome="Timeout"
                except BaseException:
                    stop_tree(process); process.communicate(timeout=10); raise
            except OSError as error:
                output=str(error)
            records.append({"case":case,"outcome":outcome,"exit_code":code,
                            "elapsed_seconds":round(time.monotonic()-start,3),"output":output})
            print(case, outcome, flush=True)
            args.output.parent.mkdir(parents=True,exist_ok=True)
            args.output.write_text(json.dumps({"source":str(source),
                "runtime":"Wolfram" if args.wolfram else "Mathics",
                "selected":cases,"completed":len(records),"results":records,
                "scope":"Focused review probes, not the full package suite"},indent=2)+"\n",encoding="utf-8")
    return 0 if all(row["outcome"] == "Pass" for row in records) else 1


if __name__ == "__main__":
    raise SystemExit(main())
