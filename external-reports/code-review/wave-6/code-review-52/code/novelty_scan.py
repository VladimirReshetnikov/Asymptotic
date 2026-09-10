#!/usr/bin/env python3
"""Screen a LOCAL review archive; matches are candidates for manual review.

This is a reproducibility aid, not a semantic proof that an issue is new.
It does not download files or modify the checkout. Scans .tex and .md only.
"""
import argparse
import json
from pathlib import Path
import re
import sys

PATTERNS = {
    "N1-variable-constants": re.compile(
        r"numeric.{0,45}variab|variable.{0,45}numeric|"
        r"(?:variable|target).{0,45}\bPi\b|nonnumeric.{0,45}symbol", re.I | re.S),
    "N2-Fourier-residual": re.compile(r"FourierInverseResidual", re.I),
    "N3-conditional-dispatch": re.compile(r"ConditionalExpression", re.I),
}


def scan(root: Path) -> dict:
    archive = root / "external-reports" / "code-review"
    if not archive.is_dir():
        raise ValueError(f"Review archive does not exist: {archive}")
    files, matches = [], []
    for path in sorted(archive.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in {".tex", ".md"}:
            continue
        text = path.read_text(encoding="utf-8")
        relative = str(path.relative_to(root))
        files.append({"Path": relative, "Characters": len(text)})
        for key, regex in PATTERNS.items():
            for hit in regex.finditer(text):
                low, high = max(0, hit.start() - 350), min(len(text), hit.end() + 500)
                context = text[low:high]
                # Retain all conditional hits; broader matches reduce false absence.
                matches.append({"Candidate": key, "Path": relative,
                                "Line": text.count("\n", 0, hit.start()) + 1,
                                "Context": context})
    return {"Meaning": "Lexical screen only; inspect matches and review indexes manually.",
            "Files": files, "Matches": matches}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        data = json.dumps(scan(args.checkout.resolve(strict=True)), indent=2, ensure_ascii=False) + "\n"
        if args.output:
            with args.output.open("x", encoding="utf-8") as stream:
                stream.write(data)
        else:
            sys.stdout.write(data)
    except (OSError, ValueError) as exc:
        parser.exit(2, f"novelty_scan: {exc}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
