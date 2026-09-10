"""POSIX runtime characterization driver. Requires an installed interpreter.

Examples:
  python code/run_runtime_probes.py --source /repo/src/Kernel/AsymptoticAnalysis.wl --python /repo/.venv/bin/python --output /tmp/mathics.json
  python code/run_runtime_probes.py --source /repo/AsymptoticAnalysis.wl --wolfram /path/to/WolframKernel --output /tmp/native.json

Exit 0 means every selected process produced a complete characterization
frame, NOT that all mathematical contracts or proposed fixes passed.
"""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import sys
from bounded_process import bounded_run
from runner_fixes import interpreter_path, finite_positive_seconds

CASES=("first-position-count","bounded-position-support","limit-default",
       "empty-lookup-nested","empty-association-list-lookup","public-ordinary-control",
       "loggamma-control","special-origin-controls")

def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    runtime=parser.add_mutually_exclusive_group(required=True)
    runtime.add_argument("--python")
    runtime.add_argument("--wolfram")
    parser.add_argument("--source",required=True,type=Path)
    parser.add_argument("--output",required=True,type=Path)
    parser.add_argument("--case",action="append",choices=CASES)
    parser.add_argument("--timeout",type=finite_positive_seconds,default=300)
    parser.add_argument("--max-output-bytes",type=int,default=1048576)
    args=parser.parse_args()
    if os.name != "posix": parser.error("the supplied bounded driver prototype is POSIX-only")
    source=args.source.resolve()
    if not source.is_file(): parser.error("source must be an existing entry file")
    script=Path(__file__).with_name("runtime_contracts.wl").absolute()
    if args.python:
        command=[interpreter_path(args.python),"-m","mathics","--quiet","--no-readline","--file",str(script)]
        runtime_name="Mathics"
    else:
        command=[interpreter_path(args.wolfram),"-noinit","-script",str(script)]
        runtime_name="Wolfram"
    report=dict(Runtime=runtime_name, Source=str(source), CharacterizationOnly=True,
                MathematicalAcceptanceAsserted=False, Results=[])
    for case in args.case or CASES:
        env=dict(os.environ,ASYMPTOTIC_REVIEW_SOURCE=str(source),ASYMPTOTIC_REVIEW_CASE=case,
                 PYTHONIOENCODING="utf-8",PYTHONUNBUFFERED="1")
        for key in list(env):
            if key.upper() in {"WOLFRAMINIT","MATHKERNELINIT"}: del env[key]
        result=bounded_run(command, timeout=args.timeout,max_output_bytes=args.max_output_bytes,
                           cwd=script.parent,env=env)
        lines=result["Output"].splitlines()
        complete=(result["Outcome"] == "Exited" and lines.count("REVIEW_CASE\t"+case)==1 and
                  lines.count("REVIEW_VALUE_BEGIN")==lines.count("REVIEW_VALUE_END")==1)
        result.update(Case=case,CompleteFrame=complete)
        report["Results"].append(result)
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(json.dumps(report,indent=2)+"\n")
        print(case,result["Outcome"],"complete frame:",complete)
    return 0 if all(row["CompleteFrame"] for row in report["Results"]) else 1

if __name__ == "__main__": raise SystemExit(main())
