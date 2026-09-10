#!/usr/bin/env python3
"""Stage two narrowly scoped AsymptoticAnalysis dispatch fixes.

This program never overwrites the input. It accepts the pinned modular
NativeCompatibility.wl or the generated standalone file. When editing a
checkout, stage the modular file, review the diff, and regenerate the
standalone through the repository's builder. No checksum files are produced.

The two mechanisms were exercised separately on the pinned standalone in
Wolfram 15.0.0. This emitter and the combined patch are not a full upstream
acceptance run. See evidence/native_observations.json and README.md.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path

PINNED_COMMIT = "6687962f3c858a4f93623cfc496f33e35c6763d4"
DEFAULT_OLD = 'backend = If[values === {}, Automatic, ReleaseHold[First[values]]];'
DEFAULT_NEW = ('backend = If[values === {}, '
               'OptionValue[AsymptoticExpansion, {}, "Backend"], '
               'ReleaseHold[First[values]]];')
KEYS_OLD = 'nativeComputedArgumentQ[HoldComplete[_Rule | _RuleDelayed]] := False;'
KEYS_NEW = '''nativeLiteralOptionKeyQ[HoldComplete[_String]] := True;
nativeLiteralOptionKeyQ[HoldComplete[key_Symbol]] := OwnValues[key] === {};
nativeLiteralOptionKeyQ[_] := False;
nativeComputedArgumentQ[HoldComplete[(Rule | RuleDelayed)[key_, _]]] := ! nativeLiteralOptionKeyQ[HoldComplete[key]];'''


def patched_text(source: str, selection: str = "both") -> str:
    """Require unique original anchors and fail closed on changed source."""
    if selection not in {"default", "keys", "both"}:
        raise ValueError("selection must be default, keys, or both")
    replacements = []
    if selection in {"default", "both"}:
        replacements.append((DEFAULT_OLD, DEFAULT_NEW))
    if selection in {"keys", "both"}:
        replacements.append((KEYS_OLD, KEYS_NEW))
    for old, new in replacements:
        count = source.count(old)
        if count != 1:
            raise ValueError(f"Expected one original patch anchor, found {count}: {old!r}")
        if new in source:
            raise ValueError("Replacement already present; refusing an ambiguous patch")
    answer = source
    for old, new in replacements:
        answer = answer.replace(old, new, 1)
    return answer


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path, help="New file; must not already exist")
    parser.add_argument("--fix", choices=["default", "keys", "both"], default="both")
    args = parser.parse_args()
    if not args.source.is_file():
        parser.error("source is not a regular file")
    if args.source.resolve() == args.output.resolve() or args.output.exists():
        parser.error("output must be a new file different from the source")
    try:
        source = args.source.read_text(encoding="utf-8")
        changed = patched_text(source, args.fix)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        # Exclusive creation protects a file appearing after the earlier check.
        with args.output.open("x", encoding="utf-8", newline="\n") as stream:
            stream.write(changed)
    except (OSError, UnicodeError, ValueError) as exc:
        parser.exit(2, f"Patch not staged: {exc}\n")
    print("".join(difflib.unified_diff(source.splitlines(True), changed.splitlines(True),
                                     fromfile=str(args.source), tofile=str(args.output))), end="")
    print("\nStaged candidate only. Run focused native regression tests before integration.")

if __name__ == "__main__":
    main()
