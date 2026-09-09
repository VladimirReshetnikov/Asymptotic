#!/usr/bin/env python3
"""Generate or apply three narrowly scoped, UNVALIDATED Wolfram source fixes.

Default: verify the pinned source, generate a unified diff, change nothing.
The script does not download or execute repository code. Run native regressions
and the full repository suite before adopting the patch.

SPDX-License-Identifier: MIT-0
"""
from __future__ import annotations

import argparse
import difflib
import hashlib
import os
from pathlib import Path
import sys
import tempfile
from typing import Dict, Tuple

COMMIT = "07a9781212beb2eeb9ff16aa625b50ac27974078"
EXPECTED_GIT_BLOB = "ea9eaf4a11130e922ac4fb3faae37fd8e8d29643"
TARGET = Path("AsymptoticInverse/Kernel/AsymptoticInverse.wl")
DENSE_ANCHOR = "  coeffs = Table[0, {nmax - nmin}];"
DENSE_REPLACEMENT = '''  (* Audit proposal F01: refuse an optional dense export before allocation.
     This fixed cap is deliberately independent of the sparse-work budget.
     A public, lazy conversion API should replace this tactical safeguard. *)
  If[nmax - nmin > 20000,
    Return[Missing["DenseRepresentationTooLarge",
      <|"RequiredSlots" -> nmax - nmin, "Limit" -> 20000|>], Module]];
  coeffs = Table[0, {nmax - nmin}];'''
POWER_ANCHOR = '''  If[T === {},
   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],'''
POWER_REPLACEMENT = '''  If[T === {},
   (* Audit proposal F02: the branch check belongs in the shared primitive,
      including calls made from inside a compound SeriesObservable. *)
   If[P =!= Infinity && ! IntegerQ[rr],
    fail["UnknownLeadingTerm", "A pure remainder does not establish the real branch required by a noninteger power."]];
   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],'''
LABEL_ANCHOR = "f(g(y))/(a z^p) - 1"
LABEL_REPLACEMENT = "(f(g(y)) - y0)/(a z^p) - 1"


def git_blob_id(data: bytes) -> str:
    """Git's object identifier, not the bare SHA-1 of the file contents."""
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def transform(source: str) -> Tuple[str, Dict[str, int]]:
    """Transform LF-normalized text only when all exact anchor counts match."""
    patches = [
        ("F01", DENSE_ANCHOR, DENSE_REPLACEMENT, 2),
        ("F02", POWER_ANCHOR, POWER_REPLACEMENT, 1),
        ("F05", LABEL_ANCHOR, LABEL_REPLACEMENT, 2),
    ]
    # Check all anchors before making any change.
    for finding, old, _new, expected in patches:
        found = source.count(old)
        if found != expected:
            raise ValueError(f"{finding}: expected {expected} exact anchors, found {found}; refusing to patch")
    output = source
    counts: Dict[str, int] = {}
    for finding, old, new, expected in patches:
        output = output.replace(old, new)
        counts[finding] = expected
    return output, counts


def load_pinned(path: Path) -> Tuple[bytes, str, bytes]:
    raw = path.read_bytes()
    normalized = raw.replace(b"\r\n", b"\n")
    if b"\r" in normalized:
        raise ValueError("The source has bare CR line endings; refusing an ambiguous normalization")
    blob = git_blob_id(normalized)
    if blob != EXPECTED_GIT_BLOB:
        raise ValueError(
            f"Source is not the audited blob. Expected {EXPECTED_GIT_BLOB}, got {blob}. "
            f"Use a clean checkout of {COMMIT}; do not apply this patch blindly to a newer revision."
        )
    newline = b"\r\n" if b"\r\n" in raw else b"\n"
    return raw, normalized.decode("utf-8"), newline


def atomic_replace(path: Path, data: bytes) -> None:
    mode = path.stat().st_mode
    fd, temporary = tempfile.mkstemp(prefix=path.name + ".audit-", dir=str(path.parent))
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", type=Path, help="Local repository checkout at the exact audited commit")
    parser.add_argument("--output", type=Path, help="Write a unified diff instead of printing it")
    parser.add_argument("--apply", action="store_true", help="Explicitly modify the verified file; first save a non-overwriting backup")
    args = parser.parse_args()
    target = args.repo.resolve() / TARGET
    try:
        original_bytes, original, newline = load_pinned(target)
        proposed, counts = transform(original)
        diff = "".join(difflib.unified_diff(
            original.splitlines(keepends=True), proposed.splitlines(keepends=True),
            fromfile="a/" + TARGET.as_posix(), tofile="b/" + TARGET.as_posix(),
        ))
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(diff, encoding="utf-8")
        else:
            sys.stdout.write(diff)
        if args.apply:
            backup = target.with_name(target.name + ".before-audit-fixes")
            with backup.open("xb") as stream:
                stream.write(original_bytes)
            # Keep Windows checkouts in their original newline convention.
            payload = proposed.encode("utf-8").replace(b"\n", newline)
            atomic_replace(target, payload)
            print(f"Applied {counts}; backup: {backup}", file=sys.stderr)
            print("NEXT: regenerate the standalone package and execute native regressions/full tests. These proposals are not native-validated.", file=sys.stderr)
        else:
            print(f"Verified pinned source; proposed {counts}. No repository file was changed.", file=sys.stderr)
        return 0
    except (OSError, UnicodeError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
