#!/usr/bin/env python3
"""Stage narrow audit candidates without modifying the supplied checkout.

Python >=3.10. No third-party dependencies. This is NOT a release patch.
The audited baseline is commit 8cee870994f506b501bae3ea6bd4a3a7edb895c1.
N1 covers the common source chart and the ordinary inverse constructor;
other public entry points still need the admission audit described in the article.
"""
from __future__ import annotations

import argparse
import difflib
import json
from pathlib import Path
import subprocess
import sys
from typing import Dict, List, Tuple

PIN = "8cee870994f506b501bae3ea6bd4a3a7edb895c1"

CHART = 'localCoordinate[x_, x0_, direction_] := Module[{dir = direction, u = Unique["u$"], sub, s},'
CHART_NEW = '''validSeriesVariableQ[v_] := MatchQ[v, _Symbol] && ! NumericQ[v] &&
  ! MemberQ[{"System`Glaisher", "System`Khinchin"}, Context[v] <> SymbolName[v]];

localCoordinate[x_, x0_, direction_] := Module[{dir = direction, u = Unique["u$"], sub, s},
  If[! validSeriesVariableQ[x], fail["InvalidVariable",
    "Use a nonnumeric symbol as the expansion variable."]];'''
PAIR = '  If[x === y, fail["InvalidVariables", "Source and target variables must be distinct symbols."]];'
PAIR_NEW = '''  If[! validSeriesVariableQ[x] || ! validSeriesVariableQ[y] || x === y,
    fail["InvalidVariables", "Source and target variables must be distinct nonnumeric symbols."]];'''
FOURIER = 'AsymptoticAnalysis`FourierInverseResidual[GeneralizedSeries[a_Association], cutoff_: Automatic, OptionsPattern[]]'
FOURIER_NEW = 'AsymptoticAnalysis`FourierInverseResidual[GeneralizedSeries[a_Association], cutoff : (Automatic | _?exactRealQ) : Automatic, OptionsPattern[]]'
OBSERVABLE = '''  j = seriesJetApply[body, x, d["Jet"], d, h, limit];
  result = seriesMake[Join[d, <|"Jet" -> j|>], {"Observable", {s}, e, x}, h];'''
OBSERVABLE_NEW = '''  result = Which[
    body === Log[x], seriesLog[s, OptionValue["Cutoff"], limit],
    body === Exp[x], seriesExp[s, OptionValue["Cutoff"], limit],
    Head[body] === Power && body[[1]] === x && FreeQ[body[[2]], x],
      seriesPower[s, body[[2]], OptionValue["Cutoff"], limit],
    True,
      j = seriesJetApply[body, x, d["Jet"], d, h, limit];
      seriesMake[Join[d, <|"Jet" -> j|>], {"Observable", {s}, e, x}, h]];
  result = GeneralizedSeries[Join[result[[1]],
    <|"SeriesRecipe" -> {"Observable", {s}, e, x}|>]];'''

REPLACEMENTS: Dict[str, List[Tuple[str, str, str]]] = {
    "src/Kernel/AsymptoticAnalysis.wl": [("N1-chart", CHART, CHART_NEW), ("N1-pair", PAIR, PAIR_NEW)],
    "src/Kernel/FourierCoefficients.wl": [("N2-signature", FOURIER, FOURIER_NEW)],
    "src/Kernel/SeriesOperations.wl": [("N3-dispatch", OBSERVABLE, OBSERVABLE_NEW)],
}


def transform(text: str, replacements: List[Tuple[str, str, str]]) -> Tuple[str, List[dict]]:
    """Reject stale/ambiguous anchors before changing any supplied text."""
    receipts = []
    for identifier, old, _ in replacements:
        count = text.count(old)
        if count != 1:
            raise ValueError(f"{identifier}: expected one exact source anchor, found {count}")
    for identifier, old, new in replacements:
        text = text.replace(old, new, 1)
        receipts.append({"Candidate": identifier, "MatchedAnchors": 1})
    return text, receipts


def stage(root: Path, output: Path, allow_unverified_revision: bool = False) -> dict:
    root = root.resolve(strict=True)
    output = output.resolve()
    if output == root or root in output.parents:
        raise ValueError("The output must be outside the input checkout.")
    if output.exists():
        raise FileExistsError("Use a new output directory; no existing data will be overwritten.")
    revision = None
    try:
        revision = subprocess.run(
            ["git", "-C", str(root), "rev-parse", "HEAD"], check=True,
            capture_output=True, text=True, timeout=15,
        ).stdout.strip()
    except (FileNotFoundError, subprocess.SubprocessError):
        if not allow_unverified_revision:
            raise ValueError("Cannot verify checkout revision; use --allow-unverified-revision for a source archive.")
    if revision != PIN and not allow_unverified_revision:
        raise ValueError(f"Expected {PIN}, got {revision!r}.")
    staged = []
    diffs = []
    records = []
    for relative, replacements in REPLACEMENTS.items():
        original = (root / relative).read_text(encoding="utf-8")
        revised, receipts = transform(original, replacements)
        staged.append((relative, revised))
        records.extend({"Path": relative, **receipt} for receipt in receipts)
        diffs.extend(difflib.unified_diff(
            original.splitlines(keepends=True), revised.splitlines(keepends=True),
            fromfile="a/" + relative, tofile="b/" + relative,
        ))
    # Only publish after all source anchors have been validated.
    output.mkdir(parents=True)
    for relative, revised in staged:
        target = output / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(revised, encoding="utf-8", newline="\n")
    (output / "candidate.patch").write_text("".join(diffs), encoding="utf-8")
    report = {
        "AuditedCommit": PIN, "InputRevision": revision,
        "Purpose": "Candidate source fragments and patch; not a complete package",
        "InputCheckoutModified": False, "Changes": records,
        "RuntimeValidation": "See the accompanying evidence; staging is not kernel acceptance.",
    }
    (output / "staging-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--allow-unverified-revision", action="store_true")
    args = parser.parse_args()
    try:
        report = stage(args.checkout, args.output, args.allow_unverified_revision)
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        parser.exit(2, f"candidate_patch: {exc}\n")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
