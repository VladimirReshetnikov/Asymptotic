#!/usr/bin/env python3
"""Emit (never apply) three narrow candidate patches for a pinned checkout.

The Wolfram code has NOT been executed in a kernel by the audit author.
Text transformations were tested only against small synthetic anchor fixtures.
Python 3.9+. No network requests and no checksum files.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path
import subprocess
import sys
from typing import Dict, Mapping

COMMIT = "8e859961d7d37f008b826f3a8cad406460271614"
CORE = "src/Kernel/AsymptoticAnalysis.wl"
OPS = "src/Kernel/SeriesOperations.wl"
GAMMA = "src/Kernel/GammaInverseOperations.wl"

ABS_OLD = '''fwdAbs[j : {T_, P_, D_}, ell_, ass_] := Module[{q, c, degree},
  If[T === {}, Return[j, Module]];
  q = T[[1, 2]]; degree = polyDegree[q, ell];'''
ABS_NEW = '''fwdAbs[j : {T_, P_, D_}, ell_, ass_] := Module[{q, c, degree},
  If[T === {}, Return[j, Module]];
  (* A sign of the leading coefficient is not a real-axis proof for all
     retained terms. Complex errors beyond the jet remain harmless here
     by the reverse triangle inequality; complex retained terms do not. *)
  If[! And @@ (realPolynomialQ[#[[2]], ell, ass] & /@ T),
    fail["UnprovedAbsArgument",
      "The sign-based absolute-value expansion requires real retained coefficients; use an exact modulus identity or supply sufficient assumptions."]];
  q = T[[1, 2]]; degree = polyDegree[q, ell];'''
POWER_HEAD = '''seriesPower[s_, r_, cut_, limit_, truncate_: True] := Module[{d, flat, ell, ass, h, j, alpha},'''
POWER_HELPER = '''(* Sufficient, deliberately conservative nonvanishing test for a
   zeroth power in the ordinary precision-jet path. It does not choose a
   sign and therefore admits a real parameter proved nonzero but unsigned. *)
seriesZerothPowerNonzeroQ[d_] := Module[{j = d["Jet"], ell = d["LogVariable"], q, degree, c},
  If[j[[1]] === {}, Return[False, Module]];
  q = j[[1, 1, 2]]; degree = polyDegree[q, ell];
  c = Coefficient[q, ell, degree];
  TrueQ[FullSimplify[c != 0 && d["Prefactor"] != 0, seriesAss[d]]]];

'''
ZERO_OLD = '''  If[r === 0 && d["Jet"][[1]] === {}, fail["IndeterminatePower", "A zeroth power requires a known nonzero leading term."]];'''
ZERO_NEW = ZERO_OLD + '''
  If[r === 0 && ! seriesZerothPowerNonzeroQ[d],
    fail["UnprovedNonzeroBase",
      "A zeroth power requires a nonvanishing leading coefficient and exact prefactor on the retained parameter domain."]];'''
GAMMA_OLD = '''    result = forwardCore[1, y, a["Limit"], 1, Assumptions -> ass,
      Direction -> direction, "MaxTerms" -> limit];'''
GAMMA_NEW = '''    result = forwardCore[1, y, a["Limit"], If[cut === Automatic, 1, cut], Assumptions -> ass,
      Direction -> direction, "MaxTerms" -> limit];'''
MEANING_OLD = '''        "PrecisionMeaning" -> "The constant observable is exact and independent of the operand remainder."|>|>]], Module]];'''
MEANING_NEW = '''        "PrecisionMeaning" -> "The source observable is the exact constant one, independent of the operand remainder; the requested cutoff may omit its term."|>|>]], Module]];'''

EDITS = {
    CORE: [(ABS_OLD, ABS_NEW)],
    OPS: [(POWER_HEAD, POWER_HELPER + POWER_HEAD), (ZERO_OLD, ZERO_NEW)],
    GAMMA: [(GAMMA_OLD, GAMMA_NEW), (MEANING_OLD, MEANING_NEW)],
}

def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        raise ValueError(f"{label}: candidate already present")
    count = text.count(old)
    if count != 1:
        raise ValueError(f"{label}: expected one anchor, found {count}")
    return text.replace(old, new, 1)

def transform_sources(sources: Mapping[str, str]) -> Dict[str, str]:
    """Pure text transformation; validates all edits before returning anything."""
    staged: Dict[str, str] = {}
    for path, edits in EDITS.items():
        if path not in sources:
            raise ValueError(f"Missing input: {path}")
        text = sources[path]
        # Reject the inserted helper even when an earlier edit is partly undone.
        if path == OPS and "seriesZerothPowerNonzeroQ[d_] :=" in text:
            raise ValueError("SeriesOperations.wl: candidate helper already present")
        for index, (old, new) in enumerate(edits, 1):
            text = replace_once(text, old, new, f"{path} edit {index}")
        staged[path] = text
    return staged

def make_diff(before: Mapping[str, str], after: Mapping[str, str]) -> str:
    return "".join("".join(difflib.unified_diff(
        before[p].splitlines(keepends=True), after[p].splitlines(keepends=True),
        fromfile="a/" + p, tofile="b/" + p)) for p in EDITS)

def git(repo: Path, *args: str) -> str:
    p = subprocess.run(["git", "-C", str(repo), *args], capture_output=True,
                       text=True, check=False, timeout=30)
    if p.returncode:
        raise ValueError(p.stderr.strip() or "Git command failed")
    return p.stdout.strip()

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    parser.add_argument("--output", type=Path, help="New patch file OUTSIDE checkout; default stdout")
    args = parser.parse_args()
    try:
        root = args.checkout.resolve(strict=True)
        if git(root, "rev-parse", "HEAD") != COMMIT:
            raise ValueError("HEAD is not the reviewed commit")
        if git(root, "status", "--porcelain", "--untracked-files=no"):
            raise ValueError("Tracked worktree changes exist; use a clean scratch checkout")
        sources = {}
        for rel in EDITS:
            path = root / rel
            if path.is_symlink() or not path.resolve(strict=True).is_relative_to(root):
                raise ValueError(f"Unexpected symlink or escaped source path: {rel}")
            sources[rel] = path.read_text(encoding="utf-8")
        staged = transform_sources(sources)
        patch = make_diff(sources, staged)
        if not patch:
            raise ValueError("No patch produced")
        if args.output:
            out = args.output.resolve()
            if out.is_relative_to(root):
                raise ValueError("Output must be outside the source checkout")
            with out.open("x", encoding="utf-8", newline="\n") as handle:
                handle.write(patch)
            print(f"Wrote unvalidated Wolfram candidate patch: {out}")
        else:
            sys.stdout.write(patch)
        return 0
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f"Refused: {exc}", file=sys.stderr)
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
