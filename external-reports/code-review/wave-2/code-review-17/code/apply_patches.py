#!/usr/bin/env python3
"""Apply two narrow audit patches to a local pinned checkout, never to a remote repo.

The default is a dry run. Each replacement must occur exactly once. The script
verifies git HEAD, preserves a .pre-delta-audit backup, and uses atomic writes.
Regenerate the upstream standalone file after patching the modular sources.
"""
from __future__ import annotations
import argparse
import hashlib
from pathlib import Path
import subprocess
import sys

PIN = "921387e5ba1239bfda96e63e64e89bf63d9c41e6"
ROOT = Path(__file__).resolve().parents[1]
PATCHES = {
    "certificate": "AsymptoticInverse/Kernel/InverseCertificates.wl",
    "flat_tail": "AsymptoticInverse/Kernel/FlatSectorOperations.wl",
}

def replace_once(text: str, old: str, new: str) -> str:
    count = text.count(old)
    if count != 1:
        raise ValueError(f"Expected one patch anchor; found {count}")
    return text.replace(old, new, 1)

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    parser.add_argument("--patch", choices=[*PATCHES, "all"], default="all")
    parser.add_argument("--write", action="store_true", help="Otherwise only validate")
    parser.add_argument("--allow-other-revision", action="store_true",
                        help="Explicitly waive HEAD pin; exact source anchors still required")
    args = parser.parse_args()
    root = args.checkout.resolve()
    try:
        sha = subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"],
                                      text=True, stderr=subprocess.STDOUT).strip()
        if sha != PIN and not args.allow_other_revision:
            raise ValueError(f"HEAD {sha} differs from audited {PIN}")
        names = list(PATCHES) if args.patch == "all" else [args.patch]
        changes = []
        for name in names:
            path = root / PATCHES[name]
            original = path.read_bytes()
            decoded = original.decode("utf-8")
            crlf = "\r\n" in decoded
            if "\r" in decoded.replace("\r\n", "") or (
                    crlf and decoded.count("\n") != decoded.count("\r\n")):
                raise ValueError(f"Unsupported mixed line endings: {path}")
            normalized = decoded.replace("\r\n", "\n")
            old = (ROOT / "patches" / f"{name}_old.txt").read_text().rstrip("\n")
            new = (ROOT / "patches" / f"{name}_new.txt").read_text().rstrip("\n")
            updated_text = replace_once(normalized, old, new)
            if crlf:
                updated_text = updated_text.replace("\n", "\r\n")
            updated = updated_text.encode("utf-8")
            backup = path.with_suffix(path.suffix + ".pre-delta-audit")
            if args.write and backup.exists():
                raise ValueError(f"Refusing to overwrite backup: {backup}")
            changes.append((path, backup, original, updated))
        for path, backup, original, updated in changes:
            print(f"{path}: SHA256 before={hashlib.sha256(original).hexdigest()} "
                  f"after={hashlib.sha256(updated).hexdigest()}")
            if args.write:
                backup.write_bytes(original)
                temp = path.with_suffix(path.suffix + ".delta-tmp")
                temp.write_bytes(updated)
                temp.replace(path)
        print("Written; regenerate standalone and run focused native tests."
              if args.write else "Dry run passed; no files changed.")
        return 0
    except (OSError, UnicodeError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"Patch refused: {exc}", file=sys.stderr)
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
