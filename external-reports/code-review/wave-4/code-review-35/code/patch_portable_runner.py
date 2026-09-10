#!/usr/bin/env python3
"""Make a candidate copy of the pinned portable runner; never edit the input.

Fixes N01 (remember every observed source mismatch) and N02 (finite timeout).
This does not freeze the live package modules or detect unsampled edits.
"""
from __future__ import annotations
import argparse
import difflib
import hashlib
from pathlib import Path

PINNED_BLOB = "df59971aad4757130a5b6f826cf71d10961c525b"


def patched_source(data: bytes) -> bytes:
    identity = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
    if identity != PINNED_BLOB:
        raise ValueError("Input is not the reviewed runner. Reconcile changes before applying this candidate.")
    text = data.decode("utf-8")
    substitutions = [
        ("import json\n", "import json\nimport math\n"),
        ('if args.timeout <= 0:\n        parser.error("--timeout must be positive")',
         'if not math.isfinite(args.timeout) or args.timeout <= 0:\n        parser.error("--timeout must be finite and positive")'),
        ('    results = []\n\n    def write_report(complete: bool) -> dict:\n        after = fingerprints(source)\n',
         '    results = []\n    source_drift_observed = False\n    source_drift_observations = []\n\n'
         '    def write_report(complete: bool) -> dict:\n'
         '        nonlocal source_drift_observed\n'
         '        after = fingerprints(source)\n'
         '        if before != after:\n'
         '            source_drift_observed = True\n'
         '            changed = sorted(key for key in before.keys() | after.keys()\n'
         '                             if before.get(key) != after.get(key))\n'
         '            observation = {"Executed": len(results), "ChangedPaths": changed}\n'
         '            if not source_drift_observations or source_drift_observations[-1] != observation:\n'
         '                source_drift_observations.append(observation)\n'),
        ('"SourcesUnchangedDuringRun": before == after,',
         '"SourcesUnchangedDuringRun": not source_drift_observed,\n'
         '            "SourceDriftObserved": source_drift_observed,\n'
         '            "SourceDriftObservations": source_drift_observations,\n'
         '            "SourceCheckScope": "Boundary samples, not continuous monitoring",'),
    ]
    for old, new in substitutions:
        if text.count(old) != 1:
            raise ValueError("Expected one patch anchor; refusing an ambiguous edit.")
        text = text.replace(old, new)
    return text.encode("utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--diff", type=Path)
    args = parser.parse_args()
    if args.input.resolve() == args.output.resolve():
        parser.error("Use a distinct output path. The original is never overwritten.")
    original = args.input.read_bytes()
    try:
        candidate = patched_source(original)
    except ValueError as exc:
        parser.error(str(exc))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(candidate)
    if args.diff:
        args.diff.write_text("".join(difflib.unified_diff(
            original.decode().splitlines(True), candidate.decode().splitlines(True),
            fromfile="a/validation/run_mathics_tests.py", tofile="b/validation/run_mathics_tests.py")), encoding="utf-8")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
