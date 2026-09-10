#!/usr/bin/env python3
"""Reproduce a lexical (NOT semantic) novelty screen of the pinned review corpus.
Network access is required. No result from this complete script was used as
execution evidence; the audit used a corresponding Wolfram evaluation.
"""
from __future__ import annotations
import argparse
import json
import time
import urllib.error
import urllib.request
from pathlib import Path
from stage_patches import REVISION

TREE = "44b58728c73c241574923a2083c02d4e686b2a57"
BASE = f"https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/{REVISION}/"
TERMS = ["SetOptions", "NativeCompatibility", "seriesCoordinateRule",
         "option key", "option-key", "Euler recurrence"]

def fetch(url: str) -> str:
    error = None
    for attempt in range(3):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": "AsymptoticDeltaAudit/1"})
            with urllib.request.urlopen(request, timeout=30) as response:
                return response.read().decode("utf-8-sig")
        except (OSError, UnicodeError, urllib.error.URLError) as exc:
            error = exc
            time.sleep(attempt + 1)
    raise RuntimeError(f"Unable to fetch {url}: {error}")

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--output", type=Path, required=True)
    args = ap.parse_args()
    tree = json.loads(fetch(f"https://api.github.com/repos/VladimirReshetnikov/Asymptotic/git/trees/{TREE}?recursive=1"))
    if tree.get("truncated"):
        raise RuntimeError("Refusing to describe a truncated tree as complete.")
    paths = sorted(row["path"] for row in tree["tree"] if row["path"].startswith("external-reports/code-review/")
                   and row["path"].endswith(".tex") and "standalone" not in row["path"])
    records = []
    for path in paths:
        text = fetch(BASE + path)
        hits = [{"line": i, "text": line} for i, line in enumerate(text.splitlines(), 1)
                if any(term in line for term in TERMS)]
        records.append({"path": path, "characters": len(text), "hits": hits})
    result = {"revision": REVISION, "scope": "Case-sensitive lexical screening only",
              "terms": TERMS, "file_count": len(records), "records": records}
    args.output.write_text(json.dumps(result, indent=2), encoding="utf-8")

if __name__ == "__main__":
    main()
