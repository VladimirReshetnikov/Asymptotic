#!/usr/bin/env python3
"""Print a guarded unified diff; never apply edits or write to the checkout."""
from __future__ import annotations
import argparse
import difflib
import json
from pathlib import Path
import subprocess
import sys

PIN = "efa1aeec4845a9c35e140963a0333d0c9ec33b05"
EDITS_FILE = Path(__file__).with_name("edits.json")


def emit(root: Path, finding: str = "all", verify_revision: bool = True) -> str:
    root = root.resolve(strict=True)
    if verify_revision:
        try:
            head = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"],
                                  check=True, text=True, capture_output=True, timeout=10).stdout.strip()
        except (OSError, subprocess.SubprocessError) as exc:
            raise ValueError(f"cannot verify checkout revision: {exc}") from exc
        if head != PIN:
            raise ValueError(f"expected {PIN}, found {head}; review the new revision first")
    edits = json.loads(EDITS_FILE.read_text(encoding="utf-8"))
    edits = [e for e in edits if finding == "all" or e["id"].startswith(finding)]
    if not edits:
        raise ValueError(f"unknown finding selection {finding!r}")
    originals: dict[str, str] = {}
    changed: dict[str, str] = {}
    for edit in edits:
        relative = edit["file"]
        path = (root/relative).resolve(strict=True)
        if not path.is_relative_to(root):
            raise ValueError(f"source escapes checkout: {relative}")
        if relative not in originals:
            # read_bytes avoids platform newline translation in the guarded anchors.
            originals[relative] = path.read_bytes().decode("utf-8")
            changed[relative] = originals[relative]
        old = edit["old"]
        count = changed[relative].count(old)
        if count != 1:
            raise ValueError(f"{edit['id']}: expected one exact anchor in {relative}, found {count}")
        changed[relative] = changed[relative].replace(old, edit["new"], 1)
    return "".join("".join(difflib.unified_diff(originals[name].splitlines(True),
                      changed[name].splitlines(True), fromfile="a/"+name, tofile="b/"+name))
                   for name in originals)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", type=Path)
    parser.add_argument("--finding", choices=("all", "N01", "N02"), default="all")
    parser.add_argument("--allow-other-revision", action="store_true",
                        help="skip Git pin verification; exact-anchor checks remain mandatory")
    args = parser.parse_args()
    try:
        patch = emit(args.repository, args.finding, not args.allow_other_revision)
    except (OSError, UnicodeError, ValueError) as exc:
        print(f"refusing to emit patch: {exc}", file=sys.stderr)
        return 2
    sys.stdout.write(patch)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
