#!/usr/bin/env python3
"""Stage bounded dispatcher repairs; never edit the supplied source in place.

Input: pinned NativeCompatibility.wl, or the generated standalone package.
Output: a NEW candidate file. Every source anchor must occur exactly once.
The primary function owns defaults in this candidate; independent mutable
AsymptoticExpand defaults and the quadratic parser are deliberately not fixed.
Python 3.9+, standard library only.
"""
from __future__ import annotations
import argparse
import difflib
import sys
from pathlib import Path
from typing import List, Sequence, Tuple

PIN = "6687962f3c858a4f93623cfc496f33e35c6763d4"
FIXES = ("defaults", "option-keys", "callable-role")

KEY_HELPER = r'''(* Audit candidate N02: evaluate option keys once, without releasing
   immediate or delayed option values or descending into those values.
   A prepared container already contains evaluated immediate keys. *)
nativeResolveOptionKeys[HoldComplete[Rule[key_, value_]]] :=
  With[{resolved = ReleaseHold[HoldComplete[key]]},
    HoldComplete[Rule[resolved, value]]];
nativeResolveOptionKeys[HoldComplete[RuleDelayed[key_, value_]]] :=
  With[{resolved = ReleaseHold[HoldComplete[key]]},
    HoldComplete[RuleDelayed[resolved, value]]];
nativeResolveOptionKeys[held : HoldComplete[(container : List | Sequence)[args___]]] /;
    nativeOptionTreeQ[held] :=
  Replace[nativeHeldJoin[nativeResolveOptionKeys /@
      nativeHeldArguments[HoldComplete[args]]],
    HoldComplete[kept___] :> HoldComplete[container[kept]]];
nativeResolveOptionKeys[held_HoldComplete] := held;

'''

PREPARATION_MARKER = "(* Resolve computed trailing argument containers before selecting a backend,"
SELECTOR_LINE = "  values = Flatten[nativeSelectorValues /@ Rest[parts], 1];\n"
PREPARATION_END = "      expansionPreparedEntry[sourceRequest, HoldComplete[f], args]], Module]];\n"
DEFAULT_OLD = '  backend = If[values === {}, Automatic, ReleaseHold[First[values]]];'
DEFAULT_NEW = '  backend = If[values === {}, OptionValue[AsymptoticExpansion, {}, "Backend"], ReleaseHold[First[values]]];'
PROTECTION_OLD = '''automaticProtectedQ[request_HoldComplete, original_HoldComplete] :=
  ! FreeQ[First[nativeHeldArguments[original]], _InverseFunction | _Function | _ConditionalExpression | _GeneralizedSeries | _PowerLogRemainder] ||
  ! FreeQ[First[nativeHeldArguments[request]], _InverseFunction | _Function | _ConditionalExpression | _forwardCallable | _GeneralizedSeries | _PowerLogRemainder] ||'''
PROTECTION_NEW = '''automaticProtectedQ[request_HoldComplete, original_HoldComplete] :=
  MatchQ[First[nativeHeldArguments[original]], HoldComplete[_Function]] ||
  MatchQ[First[nativeHeldArguments[request]], HoldComplete[_Function]] ||
  ! FreeQ[First[nativeHeldArguments[original]], _InverseFunction | _ConditionalExpression | _GeneralizedSeries | _PowerLogRemainder] ||
  ! FreeQ[First[nativeHeldArguments[request]], _InverseFunction | _ConditionalExpression | _forwardCallable | _GeneralizedSeries | _PowerLogRemainder] ||'''

class PatchError(ValueError):
    """Source does not have the exact expected, unique anchors."""


def replace_once(text: str, old: str, new: str, name: str) -> str:
    count = text.count(old)
    if count != 1:
        raise PatchError("{}: expected one source anchor, found {}".format(name, count))
    return text.replace(old, new, 1)


def patch_text(text: str, fixes: Sequence[str] = FIXES) -> Tuple[str, List[str]]:
    unknown = set(fixes).difference(FIXES)
    if unknown:
        raise PatchError("Unknown fixes: " + ", ".join(sorted(unknown)))
    if len(set(fixes)) != len(fixes):
        raise PatchError("Duplicate fix names")
    # Work on logical lines, then preserve a consistently CRLF source.
    crlf = "\r\n" in text and "\n" not in text.replace("\r\n", "")
    result = text.replace("\r\n", "\n")
    changed = []
    if "defaults" in fixes:
        result = replace_once(result, DEFAULT_OLD, DEFAULT_NEW, "N01 default lookup")
        changed.append("N01: consult the primary function's effective Backend default")
    if "option-keys" in fixes:
        result = replace_once(result, PREPARATION_MARKER, KEY_HELPER + PREPARATION_MARKER,
                              "N02 helper insertion")
        result = replace_once(result, SELECTOR_LINE, "", "N02 defer selector discovery")
        result = replace_once(result, PREPARATION_END,
            PREPARATION_END +
            "  parts = Prepend[nativeResolveOptionKeys /@ Rest[parts], First[parts]];\n" +
            SELECTOR_LINE, "N02 canonicalize option keys")
        changed.append("N02: canonicalize option keys before selector discovery")
    if "callable-role" in fixes:
        result = replace_once(result, PROTECTION_OLD, PROTECTION_NEW, "N03 source-role guard")
        changed.append("N03: distinguish top-level callables from functions inside scalar programs")
    return (result.replace("\n", "\r\n") if crlf else result), changed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Pinned modular or standalone source")
    parser.add_argument("output", type=Path, help="New candidate path (must not exist)")
    parser.add_argument("--fix", action="append", choices=FIXES, dest="fixes",
                        help="Select a fix; repeat to combine. Default: all three.")
    parser.add_argument("--diff", type=Path, help="Also write a new unified diff file")
    args = parser.parse_args()
    try:
        if args.source.resolve() == args.output.resolve():
            raise PatchError("Refusing an in-place source edit")
        if args.diff and args.diff.resolve() in {args.source.resolve(), args.output.resolve()}:
            raise PatchError("The diff must have a distinct output path")
        if args.output.exists() or (args.diff and args.diff.exists()):
            raise PatchError("Refusing to overwrite an existing output")
        raw = args.source.read_bytes().decode("utf-8")
        patched, changes = patch_text(raw, args.fixes or FIXES)
        # Preflight every anchor before creating any output file.
        args.output.parent.mkdir(parents=True, exist_ok=True)
        if args.diff:
            args.diff.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("xb") as stream:
            stream.write(patched.encode("utf-8"))
        if args.diff:
            diff = "".join(difflib.unified_diff(raw.splitlines(True), patched.splitlines(True),
                fromfile=str(args.source), tofile=str(args.output)))
            with args.diff.open("x", encoding="utf-8", newline="") as stream:
                stream.write(diff)
        for change in changes:
            print(change)
        print("Candidate staged at {}. Native focused validation is still required.".format(args.output))
        return 0
    except (OSError, UnicodeError, PatchError) as error:
        print("Patch refused: {}".format(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
