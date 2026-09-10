#!/usr/bin/env python3
"""Stage the complete condition-join candidate, without overwriting upstream.

Usage: python patch_conditions.py INPUT.wl OUTPUT.wl
Input: pinned modular SeriesOperations.wl or pinned generated standalone.
The exact sites are checked; this is NOT a general Wolfram Language parser.
Selected equivalent source substitutions were executed in Wolfram 15.0.0.
The complete staged file and Mathics integration remain to be validated.
"""
from __future__ import annotations
import argparse
from pathlib import Path
from patch_merge_only import patch_text as patch_merge, START

OLD_ALIGN = 'seriesAlign[a_, b_] := Join[b /. b["LogVariable"] -> a["LogVariable"],\n  <|"Assumptions" -> a["Assumptions"] && b["Assumptions"],\n    "Domain" -> Lookup[a, "Domain", True] && Lookup[b, "Domain", True]|>];'
NEW_ALIGN = '(* Join already-evaluated proof predicates structurally. Descend through\n   top-level conjunctions only; do not distribute Or, solve predicates,\n   discard distinct restrictions, or walk into held predicate arguments. *)\nseriesConditionClauses[c_And] := Flatten[seriesConditionClauses /@ (List @@ c), 1];\nseriesConditionClauses[True] := {};\nseriesConditionClauses[c_] := {c};\nseriesConditionJoin[a_, b_] := And @@ DeleteDuplicates[\n  Join[seriesConditionClauses[a], seriesConditionClauses[b]]];\n\nseriesAlign[a_, b_] := Join[b /. b["LogVariable"] -> a["LogVariable"],\n  <|"Assumptions" -> seriesConditionJoin[a["Assumptions"], b["Assumptions"]],\n    "Domain" -> seriesConditionJoin[Lookup[a, "Domain", True], Lookup[b, "Domain", True]]|>];'
ALIGN_START = 'seriesAlign[a_, b_] := Join['

def patch_text(text: str) -> str:
    if 'seriesConditionClauses[' in text or 'seriesConditionJoin[' in text:
        raise ValueError('Candidate helper already exists; reconcile source manually.')
    if text.count(ALIGN_START) != 1 or text.count(START) != 1:
        raise ValueError('Expected exactly one alignment and one binary definition.')
    begin = text.index(ALIGN_START)
    end = text.index(START)
    if begin >= end or text[begin:end].strip() != OLD_ALIGN:
        raise ValueError('Alignment definition or the following source boundary changed.')
    # Check both sites before changing either. patch_merge is itself scoped.
    merged = patch_merge(text)
    return merged[:begin] + NEW_ALIGN + '\n\n' + merged[end:]

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    try:
        source = args.source.resolve(strict=True)
        destination = args.destination.resolve()
        if source == destination:
            raise ValueError('Input and output must differ.')
        if destination.exists():
            raise ValueError('Destination already exists.')
        patched = patch_text(source.read_text(encoding='utf-8'))
        destination.parent.mkdir(parents=True, exist_ok=True)
        with destination.open('x', encoding='utf-8', newline='\n') as stream:
            stream.write(patched)
    except (OSError, ValueError, UnicodeError) as exc:
        parser.exit(2, f'Patch not staged: {exc}\n')
    print(f'Candidate written: {destination}')

if __name__ == '__main__':
    main()
