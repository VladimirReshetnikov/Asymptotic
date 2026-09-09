#!/usr/bin/env python3
"""Emit a review-only patch for the pinned AsymptoticInverse core.

Does not modify the checkout. The complete source must match its Git blob hash.
The native Wolfram code emitted here has NOT been executed by the audit author.
"""
from __future__ import annotations

import argparse
import difflib
import hashlib
import json
from pathlib import Path

COMMIT = "07a9781212beb2eeb9ff16aa625b50ac27974078"
CORE_BLOB = "ea9eaf4a11130e922ac4fb3faae37fd8e8d29643"
CORE_PATH = "AsymptoticInverse/Kernel/AsymptoticInverse.wl"

BRANCH_OLD = '''  If[T === {},
   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],'''
BRANCH_NEW = '''  If[T === {},
   (* Audit A01: a magnitude-only remainder supplies no real power branch. *)
   If[! IntegerQ[rr] && P =!= Infinity,
    fail["UnknownLeadingTerm", "A pure remainder does not establish the real branch required by a noninteger power."]];
   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],'''

DENSE_OLD = '''  coeffs = Table[0, {nmax - nmin}];'''
DENSE_NEW = '''  (* Audit A02: native interoperability must not densify an enormous lattice.
     This fixed safety cap is a stopgap, not a complete global budget API. *)
  If[nmax - nmin > 20000,
   Return[Missing["DenseRepresentationTooLarge",
    <|"RequiredSlots" -> nmax - nmin, "SlotLimit" -> 20000|>], Module]];
  coeffs = Table[0, {nmax - nmin}];'''

STOP_OLD = '''   If[polyZeroQ[Q, ell, ass], Continue[]];'''
STOP_NEW = '''   (* Audit A03: the homogeneous coefficient recurrence stays zero. *)
   If[polyZeroQ[Q, ell, ass], Break[]];'''


def git_blob_sha1(raw: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(raw)).encode("ascii") + b"\0" + raw).hexdigest()


def replace_exact(text: str, old: str, new: str, count: int, label: str) -> str:
    actual = text.count(old)
    if actual != count:
        raise ValueError(f"{label}: expected {count} exact source anchors, found {actual}; refusing patch")
    return text.replace(old, new)


def rewrite(text: str) -> str:
    text = replace_exact(text, BRANCH_OLD, BRANCH_NEW, 1, "A01")
    text = replace_exact(text, DENSE_OLD, DENSE_NEW, 2, "A02")
    return replace_exact(text, STOP_OLD, STOP_NEW, 1, "A03")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path,
                        help="New directory, outside the checkout, for proposed source and diff")
    args = parser.parse_args()
    root = args.repository.resolve()
    out = args.output.resolve()
    if out == root or root in out.parents:
        parser.error("--output must be outside the checkout")
    if out.exists():
        parser.error("--output must not already exist; no files will be overwritten")
    original = (root / CORE_PATH).read_bytes()
    # Handle CRLF worktrees without changing the tracked LF blob's identity.
    normalized = original.replace(b"\r\n", b"\n")
    if git_blob_sha1(normalized) != CORE_BLOB:
        parser.error("Core source does not match the pinned reviewed Git blob; refusing to guess")
    old = normalized.decode("utf-8")
    try:
        new = rewrite(old)
    except ValueError as exc:
        parser.error(str(exc))
    patch = "".join(difflib.unified_diff(
        old.splitlines(keepends=True), new.splitlines(keepends=True),
        fromfile="a/" + CORE_PATH, tofile="b/" + CORE_PATH, n=5))
    out.mkdir(parents=True)
    (out / "core-audit.patch").write_text(patch, encoding="utf-8")
    (out / "AsymptoticInverse.wl").write_text(new, encoding="utf-8")
    (out / "patch-manifest.json").write_text(json.dumps({
        "reviewed_commit": COMMIT,
        "reviewed_core_git_blob": CORE_BLOB,
        "input_sha256_lf": hashlib.sha256(normalized).hexdigest(),
        "output_sha256_lf": hashlib.sha256(new.encode()).hexdigest(),
        "findings": ["A01", "A02", "A03"],
        "checkout_modified": False,
        "native_validation": "NOT RUN by audit author; run regression and complete upstream suites",
        "next_steps": ["Review core-audit.patch", "git apply core-audit.patch in a disposable checkout",
                       "python validation/build_standalone.py", "Run fresh native kernels and all tests"]
    }, indent=2) + "\n", encoding="utf-8")
    print(out / "core-audit.patch")


if __name__ == "__main__":
    main()
