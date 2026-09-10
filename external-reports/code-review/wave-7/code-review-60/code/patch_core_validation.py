#!/usr/bin/env python3
"""Emit the narrow canonical-source repair. Never overwrite an existing file.

Usage: python patch_core_validation.py /checkout/src/Kernel/CorePerturbation.wl
       python patch_core_validation.py SOURCE --output NEW_FILE
The default output is a unified diff. This utility does not edit a checkout,
rebuild a standalone package, execute Wolfram code, or verify a Git revision.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path
import sys

REPLACEMENTS = (
    ("validateInput[core + perturbation, limit];",
     "validateInput[{core, perturbation}, limit];"),
    ("If[x === y || ! FreeQ[core + perturbation, y],",
     "If[x === y || ! FreeQ[{core, perturbation}, y],"),
)


def transform(source: str) -> str:
    for old, new in REPLACEMENTS:
        count = source.count(old)
        if count != 1 or new in source:
            raise ValueError("Refusing source drift, missing/duplicate anchors, or an already-patched file: "
                             + repr(old) + f" (old occurrences: {count})")
    for old, new in REPLACEMENTS:
        source = source.replace(old, new, 1)
    return source


def prepare(source_path: Path, output: Path | None = None) -> str:
    source = source_path.read_text(encoding="utf-8")
    patched = transform(source)
    if output is not None:
        # 'x' is deliberately exclusive, including existing files and symlinks.
        with output.open("x", encoding="utf-8", newline="\n") as stream:
            stream.write(patched)
    return "".join(difflib.unified_diff(
        source.splitlines(keepends=True), patched.splitlines(keepends=True),
        fromfile="a/src/Kernel/CorePerturbation.wl",
        tofile="b/src/Kernel/CorePerturbation.wl"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--output", type=Path, help="Create a NEW separate patched file")
    args = parser.parse_args(argv)
    try:
        diff = prepare(args.source, args.output)
    except (OSError, UnicodeError, ValueError) as exc:
        print(f"Patch refused: {exc}", file=sys.stderr)
        return 2
    sys.stdout.write(diff)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
