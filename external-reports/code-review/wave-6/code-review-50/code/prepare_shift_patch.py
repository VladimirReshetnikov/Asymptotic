#!/usr/bin/env python3
"""Emit a candidate unified diff; never modify the supplied checkout.

Tested only on source-fragment fixtures in this delivery. The upstream WL
package and the modified package have not been executed in this session.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path

RELATIVE = Path("src/Kernel/ExponentialCorePerturbation.wl")
ANCHOR = '  If[! IntegerQ[depth] || depth < 0, fail["InvalidDepth", "Exponential sector depth must be a nonnegative integer."]];\n'
INSERT = '''  If[! FreeQ[shift, y],
    fail["TargetDependentSourceShift",
      "SourceShift must be independent of the target variable; the remainder theorem assumes a fixed source chart.",
      <|"SourceShift" -> shift, "TargetVariable" -> y|>]];
'''

def changed(text: str) -> str:
    if '"TargetDependentSourceShift"' in text:
        raise ValueError("the proposed guard is already present; no patch emitted")
    if text.count(ANCHOR) != 1:
        raise ValueError("expected one exact constructor anchor; inspect source drift")
    if 'exponentialCoreConstruct[' not in text:
        raise ValueError("the source does not contain exponentialCoreConstruct")
    return text.replace(ANCHOR, INSERT + ANCHOR, 1)

def make_diff(text: str) -> str:
    new = changed(text)
    path = RELATIVE.as_posix()
    return ''.join(difflib.unified_diff(text.splitlines(True), new.splitlines(True),
                                      fromfile='a/'+path, tofile='b/'+path))

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    args = parser.parse_args()
    try:
        text = (args.checkout / RELATIVE).read_text(encoding="utf-8")
        print(make_diff(text), end="")
    except (OSError, ValueError) as error:
        parser.exit(2, f"patch not emitted: {error}\n")
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
