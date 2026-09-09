#!/usr/bin/env python3
"""Hash-guarded source repair. Dry-run by default; --apply edits one modular file.
SPDX-License-Identifier: MIT-0
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil

PINNED_COMMIT = "921387e5ba1239bfda96e63e64e89bf63d9c41e6"
PINNED_BLOB = "e01210c050dc923215c08d808db52fab140a7c4a"
RELATIVE_PATH = Path("AsymptoticInverse/Kernel/AsymptoticInverse.wl")
ANCHOR = b'  groups = GatherBy[{canon[#[[1]]], #[[2]]} & /@ terms, First];'
REPLACEMENT = b'''  (* Canonical syntax does not identify every equal transcendental weight.
     Establish equality classes before relying on unique increasing support. *)
  groups = Split[
    Sort[{canon[#[[1]]], #[[2]]} & /@ terms,
      less[#1[[1]], #2[[1]]] &],
    equal[#1[[1]], #2[[1]]] &];'''

def git_blob_hash(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()

def patch_bytes(data: bytes, expected_blob: str = PINNED_BLOB) -> bytes:
    actual = git_blob_hash(data)
    if actual != expected_blob:
        raise ValueError(f"Wrong source snapshot: expected blob {expected_blob}, got {actual}")
    if data.count(ANCHOR) != 1:
        raise ValueError("Expected exactly one semantic-merge source anchor")
    return data.replace(ANCHOR, REPLACEMENT, 1)

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", type=Path, help="Local Asymptotic checkout root")
    parser.add_argument("--apply", action="store_true", help="Write patch and preserve a backup")
    args = parser.parse_args()
    path = args.repository.resolve() / RELATIVE_PATH
    try:
        before = path.read_bytes()
        after = patch_bytes(before)
        record = {"file": str(path), "commit": PINNED_COMMIT,
                  "before_git_blob": git_blob_hash(before),
                  "after_git_blob": git_blob_hash(after), "applied": args.apply}
        if args.apply:
            backup = path.with_suffix(path.suffix + ".before-semantic-merge")
            temporary = path.with_suffix(path.suffix + ".audit-tmp")
            if backup.exists() or temporary.exists():
                raise ValueError("Backup or temporary path already exists; refusing to overwrite it")
            shutil.copy2(path, backup)
            try:
                temporary.write_bytes(after)
                shutil.copymode(path, temporary)
                os.replace(temporary, path)
            finally:
                if temporary.exists():
                    temporary.unlink()
            record["backup"] = str(backup)
        print(json.dumps(record, indent=2))
        print("Load the modular kernel for testing. The generated root standalone file was not changed.")
        return 0
    except (OSError, ValueError) as exc:
        parser.exit(2, f"Patch refused: {exc}\n")

if __name__ == "__main__":
    raise SystemExit(main())
