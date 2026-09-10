#!/usr/bin/env python3
"""Stage review candidates without modifying the source file.

Targets the pinned standalone distribution or the corresponding modular file.
Exact, unique textual anchors are mandatory. This is not an AST patcher.
No downloading, kernel execution, repository writes, or checksum generation.
"""
from __future__ import annotations

import argparse
import difflib
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

REVISION = "6687962f3c858a4f93623cfc496f33e35c6763d4"

@dataclass(frozen=True)
class Patch:
    name: str
    before: str
    after: str
    native_scope: str

DEFAULT_BEFORE = 'backend = If[values === {}, Automatic, ReleaseHold[First[values]]];'
DEFAULT_AFTER = ('backend = If[values === {}, OptionValue[AsymptoticExpansion, {}, '
                 '"Backend"], ReleaseHold[First[values]]];')
KEYS_BEFORE = 'nativeComputedArgumentQ[HoldComplete[_Rule | _RuleDelayed]] := False;'
KEYS_AFTER = '''nativeComputedArgumentQ[HoldComplete[(Rule | RuleDelayed)[key_Symbol, _]]] := OwnValues[key] =!= {};
nativeComputedArgumentQ[HoldComplete[(Rule | RuleDelayed)[_String, _]]] := False;
nativeComputedArgumentQ[HoldComplete[_Rule | _RuleDelayed]] := True;'''
FOURIER_BEFORE = '''   If[k >= limit, fail["ResourceLimit", "Fourier unit composition exceeded MaxTerms iterations."]];
   product = fourierJetMul[product, u, cutoff, ell, ass, limit, frequencyLimit];
   If[product === {}, Break[]];
   coefficient = fourierScale[fourierAdd[fourierEuler[coefficient, ell, ass, frequencyLimit],
       fourierScale[coefficient, power - k, ell, ass, frequencyLimit], ell, ass, frequencyLimit],
     1/(k + 1), ell, ass, frequencyLimit];
   If[coefficient === {}, Break[]];'''
FOURIER_AFTER = '''   If[! less[product[[1, 1]] + u[[1, 1]], cutoff], Break[]];
   coefficient = fourierScale[fourierAdd[fourierEuler[coefficient, ell, ass, frequencyLimit],
       fourierScale[coefficient, power - k, ell, ass, frequencyLimit], ell, ass, frequencyLimit],
     1/(k + 1), ell, ass, frequencyLimit];
   If[coefficient === {}, Break[]];
   If[k >= limit, fail["ResourceLimit", "Fourier unit composition exceeded MaxTerms iterations."]];
   product = fourierJetMul[product, u, cutoff, ell, ass, limit, frequencyLimit];
   If[product === {}, Break[]];'''

PATCHES = {
    p.name: p for p in (
        Patch("backend-default", DEFAULT_BEFORE, DEFAULT_AFTER,
              "Two selected canonical-entry observations passed on a temporary standalone; alias defaults remain unresolved."),
        Patch("computed-keys", KEYS_BEFORE, KEYS_AFTER,
              "Isolated Wolfram parser mechanisms evaluated; complete patched package not successfully executed."),
        Patch("fourier-termination", FOURIER_BEFORE, FOURIER_AFTER,
              "Private helper witness and one public inverse-residual control passed on a temporary standalone."),
    )
}

class PatchError(ValueError):
    """An unknown, repeated, missing or nonunique patch anchor."""

def apply_patches(source: str, names: Iterable[str]) -> str:
    names = tuple(names)
    if not names:
        raise PatchError("Select at least one candidate explicitly.")
    if len(set(names)) != len(names):
        raise PatchError("Repeated patch names are not allowed.")
    unknown = set(names) - PATCHES.keys()
    if unknown:
        raise PatchError("Unknown candidates: " + ", ".join(sorted(unknown)))
    # Preflight all anchors before making any change.
    for name in names:
        count = source.count(PATCHES[name].before)
        if count != 1:
            raise PatchError(f"{name}: expected exactly one baseline anchor, found {count}.")
    result = source
    for name in names:
        p = PATCHES[name]
        result = result.replace(p.before, p.after, 1)
    return result

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--patches", nargs="+", choices=tuple(PATCHES), required=True)
    parser.add_argument("--diff", type=Path, help="Optional ordinary unified diff, not a checksum file")
    args = parser.parse_args()
    try:
        if args.source.resolve() == args.output.resolve():
            raise PatchError("Refusing to overwrite the input source.")
        if args.output.exists():
            raise PatchError("Output already exists; choose a fresh candidate path.")
        if args.diff and (args.diff.exists() or args.diff.resolve() in
                          {args.source.resolve(), args.output.resolve()}):
            raise PatchError("Diff output must be a distinct, nonexistent path.")
        source = args.source.read_text(encoding="utf-8-sig").replace("\r\n", "\n")
        candidate = apply_patches(source, args.patches)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("x", encoding="utf-8", newline="\n") as stream:
            stream.write(candidate)
        if args.diff:
            args.diff.parent.mkdir(parents=True, exist_ok=True)
            diff = "".join(difflib.unified_diff(source.splitlines(True), candidate.splitlines(True),
                          fromfile=str(args.source), tofile=str(args.output)))
            with args.diff.open("x", encoding="utf-8") as stream:
                stream.write(diff)
        print(f"Staged {len(args.patches)} candidate(s) in {args.output}.")
        print("The combined candidate has NOT been validated by this staging action.")
        for name in args.patches:
            print(name + ": " + PATCHES[name].native_scope)
        return 0
    except (OSError, UnicodeError, PatchError) as exc:
        print(f"Staging failed: {exc}", file=sys.stderr)
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
