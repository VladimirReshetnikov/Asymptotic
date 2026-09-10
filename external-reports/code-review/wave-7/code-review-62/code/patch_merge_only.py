#!/usr/bin/env python3
"""INCOMPLETE mechanism: fixes the redundant merge, NOT scalar condition growth.

Stage the narrowly scoped domain-merge candidate; never overwrite its input.

Usage: python patch_merge_only.py INPUT.wl OUTPUT.wl
Both the modular SeriesOperations.wl and the generated standalone are supported.
The expected source is efa1aeec4845a9c35e140963a0333d0c9ec33b05. This is a
candidate, not an upstream fix. No network access or checksum files are used.
"""
from __future__ import annotations
import argparse
from pathlib import Path

START = 'seriesBinary[op_, s_, t_, cut_, limit_] := Module['
END = 'AsymptoticAnalysis`SeriesAdd[s_GeneralizedSeries, t_GeneralizedSeries'
OLD = '''  d = Join[d, <|"Assumptions" -> a["Assumptions"] && b["Assumptions"],
    "Domain" -> Lookup[a, "Domain", True] && Lookup[b, "Domain", True], "RemainderDerivativeOrder" -> order|>];'''
NEW = '''  (* seriesAlign already put BOTH operands' conditions in b.
     Re-merging a here doubles the left condition tree at every operation. *)
  d = Join[d, <|"Assumptions" -> b["Assumptions"],
    "Domain" -> Lookup[b, "Domain", True], "RemainderDerivativeOrder" -> order|>];'''


def patch_text(text: str) -> str:
    """Fail closed when the expected definition or exact patch site has changed."""
    if text.count(START) != 1:
        raise ValueError("Expected exactly one seriesBinary definition.")
    begin = text.index(START)
    try:
        end = text.index(END, begin)
    except ValueError as exc:
        raise ValueError("Expected following public SeriesAdd definition is absent.") from exc
    body = text[begin:end]
    if body.count(OLD) != 1:
        raise ValueError("Expected merge site changed, is duplicated, or is already patched.")
    return text[:begin] + body.replace(OLD, NEW, 1) + text[end:]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    source = args.source.resolve(strict=True)
    destination = args.destination.resolve()
    if source == destination:
        parser.error("Input and output must differ; stage a candidate instead of overwriting upstream.")
    if destination.exists():
        parser.error("Destination already exists; choose a new candidate path.")
    try:
        text = source.read_text(encoding="utf-8")
        patched = patch_text(text)
        destination.parent.mkdir(parents=True, exist_ok=True)
        with destination.open("x", encoding="utf-8", newline="\n") as stream:
            stream.write(patched)
    except (OSError, ValueError, UnicodeError) as exc:
        parser.exit(2, f"Patch not staged: {exc}\n")
    print(f"Candidate written: {destination}")


if __name__ == "__main__":
    main()
