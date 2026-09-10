#!/usr/bin/env python3
"""Emit a narrowly scoped, fail-closed observable native-order patch.

This is a source transformation candidate, not a validated Wolfram hotfix.
It does not modify the source path. With no --output, it prints a unified diff.
The exact sentinel is from Asymptotic revision 6687962f3c858a4f93623cfc496f33e35c6763d4.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path
import sys

ANCHOR = '''      (* The completed observable is checked by seriesMake after collection;
         separate analytic summands can have cancelling imaginary parts. *)'''
PRECONDITION = '''      If[! MatchQ[native, _SeriesData] || native[[4]] < 0 || native[[6]] =!= 1 || ! FreeQ[native[[3]], u],
        fail["UnsupportedObservable", "The observable must have a regular Taylor expansion at the limiting argument."]];'''
INSERT = '''      (* Review T01: only native coefficients strictly below the returned
         endpoint are known. n is Ceil[workingCutoff/innerValuation], so
         endpoint >= n suffices for this regular, exclusive-cutoff path. *)
      If[native[[1]] =!= u || native[[2]] =!= 0,
        fail["UnsupportedObservableNativeCoordinate",
          "The native Taylor result does not use the requested local coordinate."]];
      If[! IntegerQ[native[[4]]] || ! IntegerQ[native[[5]]] ||
          ! TrueQ[native[[5]] >= n],
        fail["InsufficientObservableNativeOrder",
          "The native Taylor result leaves coefficients unknown below the required observable cutoff.",
          <|"RequiredTaylorEndpoint" -> n,
            "ReturnedTaylorEndpoint" -> native[[5]],
            "NativeResult" -> native|>]];
'''

def transform(source: str) -> str:
    """Reject changed, ambiguous or already-patched source instead of guessing."""
    if "Review T01:" in source:
        raise ValueError("Source already contains the T01 candidate guard.")
    if source.count(ANCHOR) != 1 or source.count(PRECONDITION) != 1:
        raise ValueError("Expected source sentinels are absent or nonunique; review the new revision manually.")
    if PRECONDITION + "\n" + ANCHOR not in source:
        raise ValueError("Native regularity guard and insertion point are no longer adjacent.")
    return source.replace(ANCHOR, INSERT + ANCHOR, 1)

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Canonical src/Kernel/SeriesOperations.wl")
    parser.add_argument("--output", type=Path, help="Write a candidate copy, never the original path")
    ns = parser.parse_args()
    try:
        original = ns.source.read_text(encoding="utf-8")
        proposed = transform(original)
        if ns.output:
            if ns.output.resolve() == ns.source.resolve():
                raise ValueError("Refusing to overwrite the source. Use a separate candidate path.")
            if ns.output.exists():
                raise ValueError("Refusing to overwrite an existing candidate file.")
            ns.output.write_text(proposed, encoding="utf-8")
            print(f"Wrote unvalidated candidate: {ns.output}", file=sys.stderr)
        else:
            sys.stdout.writelines(difflib.unified_diff(
                original.splitlines(keepends=True), proposed.splitlines(keepends=True),
                fromfile="a/src/Kernel/SeriesOperations.wl",
                tofile="b/src/Kernel/SeriesOperations.wl"))
        return 0
    except (OSError, ValueError) as exc:
        print(f"Patch not emitted: {exc}", file=sys.stderr)
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
