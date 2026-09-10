"""Print narrowly scoped candidate diffs; do not edit the checkout.

Usage: python code/emit_candidate_patch.py /path/to/Asymptotic --which all
N01 remains Mathics-unverified. Review the article before applying anything.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path
import subprocess
import sys

PIN = "8cee870994f506b501bae3ea6bd4a3a7edb895c1"
OLD_LABEL = "x = SourceOffset + SourceSide u; LocalRoot and LocalApproximation are values of u for Power 1 and of u^Power otherwise."
NEW_LABEL = "x = SourceOffset + SourceSide u; LocalRoot is u. LocalApproximation is u for Power 1 and (SourceSide u)^Power otherwise."


def replace_once(source: str, old: str, new: str) -> str:
    if source.count(old) != 1:
        raise ValueError("Expected exactly one unchanged source anchor")
    return source.replace(old, new, 1)


def changes(root: Path, which: str):
    if which in {"all", "diagnostics"}:
        rel = "src/Kernel/NumericalInverseChecks.wl"
        original = (root / rel).read_text(encoding="utf-8")
        yield rel, original, replace_once(original, OLD_LABEL, NEW_LABEL)
    if which in {"all", "assumptions"}:
        rel = "src/Kernel/MathicsInputAssumptions.wl"
        original = (root / rel).read_text(encoding="utf-8")
        start = "mathicsProtectInputAssumptions[held_HoldComplete] :="
        stop = "\n\nIf[DownValues[mathicsOriginalInputCatch] === {},"
        if original.count(start) != 1 or original.count(stop) != 1:
            raise ValueError("Assumption protector boundaries have changed")
        i, j = original.index(start), original.index(stop)
        if j <= i:
            raise ValueError("Assumption protector boundary order is invalid")
        candidate = (Path(__file__).with_name("candidate_assumption_protector.wl")
                     .read_text(encoding="utf-8"))
        signature = "AsymptoticReview`ProtectInputAssumptions[held_HoldComplete] :="
        candidate = candidate[candidate.index(signature):].strip()
        candidate = candidate.replace("AsymptoticReview`ProtectInputAssumptions", "mathicsProtectInputAssumptions")
        yield rel, original, original[:i] + candidate + original[j:]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("--which", choices=["all", "assumptions", "diagnostics"], default="all")
    parser.add_argument("--skip-commit-check", action="store_true",
                        help="Explicitly allow a different or unversioned source tree")
    args = parser.parse_args()
    try:
        if not args.skip_commit_check:
            head = subprocess.run(["git", "-C", str(args.root), "rev-parse", "HEAD"],
                                  check=True, text=True, capture_output=True).stdout.strip()
            if head != PIN:
                raise ValueError(f"Expected the audited revision {PIN}; found {head}")
            subprocess.run(["git", "-C", str(args.root), "diff", "--quiet", "HEAD", "--",
                            "src/Kernel/MathicsInputAssumptions.wl",
                            "src/Kernel/NumericalInverseChecks.wl"], check=True)
        # Materialize/validate all proposed edits before emitting any partial diff.
        edits = list(changes(args.root, args.which))
        for rel, old, new in edits:
            sys.stdout.writelines(difflib.unified_diff(old.splitlines(True), new.splitlines(True),
                                                     fromfile="a/" + rel, tofile="b/" + rel))
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"No patch emitted: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
