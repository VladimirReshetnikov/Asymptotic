#!/usr/bin/env python3
"""Emit, but do not apply, three narrow candidate repairs for the pinned source.

Run only on a disposable, clean checkout. The CLI has been tested with synthetic Git fixtures, not a complete local real
checkout. The same option and metadata replacements were subsequently executed
in a remotely loaded pinned standalone package on Wolfram 15; the Mathics-only
replacement remains unexecuted in Mathics. See evidence/native-observations.json.
The flat-tail scheduling proposal is intentionally NOT included in this patch.
"""
from __future__ import annotations

import argparse
import difflib
from pathlib import Path
import stat
import subprocess
import sys

PIN = "8cee870994f506b501bae3ea6bd4a3a7edb895c1"
EDITS = {
    "src/Kernel/AsymptoticAnalysis.wl": [(
        '   Module[{explicit = FilterRules[{opts}, "Power"], power},\n'
        '    power = If[explicit === {}, a["Power"], "Power" /. explicit];',
        '   Module[{power},\n'
        '    power = OptionValue[{"Power" :> a["Power"]}, Flatten[{opts}], "Power"];'
    )],
    "src/Kernel/MathicsNumerical.wl": [(
        '  If[And @@ (TrueQ[N[#] > 0] & /@ factors), Total[Log /@ factors], Log[Times @@ factors]];',
        '  If[And @@ (If[IntegerQ[#] || Head[#] === Rational,\n'
        '      TrueQ[# > 0], TrueQ[N[#] > 0]] & /@ factors),\n'
        '    Total[Log /@ factors], Log[Times @@ factors]];'
    )],
    "src/Kernel/NumericalInverseChecks.wl": [(
        '   "LocalRoot" -> N[localRoot, wp], "LocalApproximation" -> N[localApproximate, wp],',
        '   "LocalRoot" -> N[localRoot, wp], "LocalApproximation" -> N[localApproximate, wp],\n'
        '   "LocalReferenceObservable" -> N[observed, wp], "ObservablePower" -> power,'
    ), (
        '   "LocalCoordinate" -> "x = SourceOffset + SourceSide u; LocalRoot and LocalApproximation are values of u for Power 1 and of u^Power otherwise.",',
        '   "LocalCoordinate" -> "x = SourceOffset + SourceSide u; LocalRoot is always u. LocalApproximation and LocalReferenceObservable use u when ObservablePower is 1, and (SourceSide u)^ObservablePower otherwise.",'
    )]
}


def transform(path: str, text: str) -> str:
    for old, new in EDITS[path]:
        count = text.count(old)
        if count != 1:
            raise ValueError(f"{path}: expected one original anchor, found {count}")
        text = text.replace(old, new, 1)
    return text


def git(root: Path, *args: str) -> str:
    result = subprocess.run(["git", "-C", str(root), *args], text=True,
                            encoding="utf-8", capture_output=True, timeout=30,
                            check=False)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Git command failed")
    return result.stdout


def make_patch(root: Path, *, expected_pin: str = PIN) -> str:
    root = root.resolve(strict=True)
    if git(root, "rev-parse", "HEAD").strip() != expected_pin:
        raise ValueError("Checkout does not match the required pinned revision")
    top = Path(git(root, "rev-parse", "--show-toplevel").strip()).resolve()
    if top != root:
        raise ValueError("Pass the repository root, not a subdirectory")
    if git(root, "status", "--porcelain", "--untracked-files=no").strip():
        raise ValueError("Tracked working tree or index is not clean")
    patches = []
    for path in EDITS:
        file = root / path
        if file.is_symlink() or not stat.S_ISREG(file.stat().st_mode):
            raise ValueError(f"Not an ordinary source file: {path}")
        if not file.resolve().is_relative_to(root):
            raise ValueError(f"Source resolves outside checkout: {path}")
        original = git(root, "show", f"HEAD:{path}")
        changed = transform(path, original)
        patches.extend(difflib.unified_diff(
            original.splitlines(keepends=True), changed.splitlines(keepends=True),
            fromfile=f"a/{path}", tofile=f"b/{path}"))
    # Recheck rather than silently accepting an obvious concurrent edit.
    if git(root, "rev-parse", "HEAD").strip() != expected_pin or git(
            root, "status", "--porcelain", "--untracked-files=no").strip():
        raise ValueError("Checkout changed while reading; discard and retry")
    return "".join(patches)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    parser.add_argument("--output", type=Path, help="New patch file outside the checkout")
    args = parser.parse_args()
    try:
        root = args.checkout.resolve(strict=True)
        patch = make_patch(root)
        if args.output:
            output = args.output.resolve()
            if output.is_relative_to(root):
                raise ValueError("The patch output must be outside the checkout")
            with output.open("x", encoding="utf-8", newline="\n") as stream:
                stream.write(patch)
        else:
            sys.stdout.write(patch)
        return 0
    except (OSError, RuntimeError, ValueError, subprocess.TimeoutExpired) as error:
        print(f"Refused: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
