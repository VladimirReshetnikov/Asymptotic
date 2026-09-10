#!/usr/bin/env python3
"""Emit (do not apply) a fail-closed patch for the reviewed fwdAbs definition.

Usage: python code/abs_guard_patch.py /checkout/Asymptotic/src/Kernel/AsymptoticAnalysis.wl
The patch targets modular sources. Regenerate the standalone before testing it.
No repository files are changed. Native execution of this candidate is pending.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path
import sys

BASELINE = '''fwdAbs[j : {T_, P_, D_}, ell_, ass_] := Module[{q, c, degree},
  If[T === {}, Return[j, Module]];
  q = T[[1, 2]]; degree = polyDegree[q, ell];
  c = (-1)^degree Coefficient[q, ell, degree];
  Which[provablyPositive[c, ass], j, provablyNegative[c, ass], pScale[j, -1, ell, ass],
    True, fail["UnprovedSign", "The eventual sign of the absolute-value argument could not be proved."]]];'''

CANDIDATE = '''fwdAbs[j : {T_, P_, D_}, ell_, ass_] := Module[{q, c, degree},
  If[T === {}, Return[j, Module]];
  (* The sign shortcut applies to the complete FINITE approximation.
     Reality of its leading coefficient alone is not sufficient.
     The unknown error may be complex: the reverse triangle inequality
     still preserves its magnitude bound. This guard does not implement
     a complex-modulus coefficient expansion or a derivative theorem. *)
  If[! AllTrue[T, TrueQ[realPolynomialCondition[#[[2]], ell, ass]] &],
    fail["UnprovedAbsJetRealness",
      "The absolute-value sign shortcut requires every retained coefficient to be provably real.",
      <|"FiniteJet" -> T, "Assumptions" -> ass|>]];
  q = T[[1, 2]]; degree = polyDegree[q, ell];
  c = (-1)^degree Coefficient[q, ell, degree];
  Which[provablyPositive[c, ass], j, provablyNegative[c, ass], pScale[j, -1, ell, ass],
    True, fail["UnprovedSign", "The eventual sign of the absolute-value argument could not be proved."]]];'''


def patched_text(text: str) -> str:
    """Reject missing, duplicate, modified, and already-patched anchors."""
    if '"UnprovedAbsJetRealness"' in text:
        raise ValueError("candidate marker already present; refusing to patch")
    count = text.count(BASELINE)
    if count != 1:
        raise ValueError(f"expected one exact fwdAbs anchor, found {count}")
    return text.replace(BASELINE, CANDIDATE, 1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    try:
        original = args.source.read_text(encoding="utf-8-sig")
        changed = patched_text(original)
    except (OSError, UnicodeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    rel = "src/Kernel/AsymptoticAnalysis.wl"
    sys.stdout.writelines(difflib.unified_diff(
        original.splitlines(keepends=True), changed.splitlines(keepends=True),
        fromfile=f"a/{rel}", tofile=f"b/{rel}"))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
