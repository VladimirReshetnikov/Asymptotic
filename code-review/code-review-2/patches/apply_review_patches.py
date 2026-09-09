#!/usr/bin/env python3
"""Opt-in, hash-guarded source patches for Asymptotic commit 07a9781.

Default: preflight and show unified diffs, with NO writes.
--write: back up and replace canonical sources. Rebuild the standalone file
using the repository's own builder afterwards. Native WL validation is required.
These proposals have not been run in a native Wolfram kernel by this audit.
"""
from __future__ import annotations
import argparse
import difflib
import hashlib
import os
from pathlib import Path

COMMIT = "07a9781212beb2eeb9ff16aa625b50ac27974078"
CORE = "AsymptoticInverse/Kernel/AsymptoticInverse.wl"
FLAT = "AsymptoticInverse/Kernel/FlatSectors.wl"
HASHES = {CORE: "ea9eaf4a11130e922ac4fb3faae37fd8e8d29643",
          FLAT: "293450f13e3ede4b490680f9ac0dea2f39fa2183"}

OLD_PRECISION = '''  If[equal[c, cut] && less[cut, PU], {cut, Nn d},
   If[equal[c, PU] && less[PU, cut], {PU, DU}, {c, Max[Nn d, DU]}]]];'''
NEW_PRECISION = '''  (* Retained nonlinear powers can have an omitted block at PU.
     The active input ceiling does not remove that logarithmic boundary. *)
  If[less[cut, PU], {c, Nn d}, {c, Max[Nn d, DU]}]];'''
OLD_POWER = '''  If[T === {},
   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],'''
NEW_POWER = '''  If[T === {},
   If[less[0, rr],
    (* A magnitude-only remainder does not prove a real fractional branch.
       Exact zero (P===Infinity) is still admissible for positive powers. *)
    If[P =!= Infinity && ! IntegerQ[rr],
     fail["UnprovedPowerBranch", "A fractional power of a pure remainder requires a proved nonnegative source branch; refine the operand first."]];
    Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],'''
# These two snippets intentionally occur in BOTH outbound converters.
OLD_EXACT = '''  If[remData === None, Return[Missing["Exact"], Module]];'''
NEW_EXACT = '''  If[remData === None, Return[Missing["Exact"], Module]];
  If[remData[[2]] =!= 0, Return[Missing["LogarithmicRemainder"], Module]];'''
OLD_DENSE = '''  coeffs = Table[0, {nmax - nmin}];'''
NEW_DENSE = '''  (* Interim hard cap for eager interoperability; the intended API is
     lazy export with an independent configurable allocation budget. *)
  If[! IntegerQ[nmax - nmin] || nmax < nmin || nmax - nmin > 100000,
   Return[Missing["DenseSeriesDataBudget", <|"RequestedEntries" -> nmax - nmin,
     "MaximumEntries" -> 100000|>], Module]];
  coeffs = Table[0, {nmax - nmin}];'''
OLD_FLAT = ''' p = First[powers]; rates = rows[[All, 1]]; base = First[Sort[rates, leq]];
 degrees = canon[#/base] & /@ rates;
 If[! And @@ (IntegerQ[#] && # > 0 & /@ degrees),
  fail["IncommensurateFlatRates", "Every phase rate must be an integer multiple of the smallest rate."]];'''
NEW_FLAT = ''' p = First[powers]; rates = rows[[All, 1]]; base = First[Sort[rates, leq]];
 degrees = canon[#/base] & /@ rates;
 If[! And @@ ((IntegerQ[#] || Head[#] === Rational) && # > 0 & /@ degrees),
  fail["IncommensurateFlatRates", "Every phase-rate ratio must be a provably positive rational number."]];
 {base, degrees} = Module[{den = LCM @@ (Denominator /@ degrees), nums, common},
   nums = den degrees; common = GCD @@ nums;
   {canon[base common/den], nums/common}];
 If[Max[degrees] > limit,
  fail["ResourceLimit", "The normalized commensurate flat-sector lattice exceeds MaxTerms."]];'''

def git_blob_hash(text: str) -> str:
    data = text.encode("utf-8")
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()

def replace_checked(text: str, old: str, new: str, count: int, label: str) -> str:
    actual = text.count(old)
    if actual != count:
        raise ValueError(f"{label}: expected {count} source occurrence(s), found {actual}")
    return text.replace(old, new)

def transform_core(text: str) -> str:
    for old, new, count, label in (
        (OLD_PRECISION, NEW_PRECISION, 1, "F01 nonlinear frontier"),
        (OLD_POWER, NEW_POWER, 1, "F02 real fractional branch"),
        (OLD_EXACT, NEW_EXACT, 2, "F03 bound-preserving export"),
        (OLD_DENSE, NEW_DENSE, 2, "F04 dense allocation cap"),
    ):
        text = replace_checked(text, old, new, count, label)
    return text

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", type=Path, help="Local repository root")
    parser.add_argument("--write", action="store_true", help="Write after complete hash/anchor preflight")
    parser.add_argument("--include-flat-lattice", action="store_true", help="Also apply the F07 rational-rate extension")
    args = parser.parse_args()
    paths = [CORE] + ([FLAT] if args.include_flat_lattice else [])
    changes = []
    for relative in paths:
        path = args.repo / relative
        original_bytes = path.read_bytes()
        # Git for Windows may have checked out CRLF; verify canonical LF text.
        text = original_bytes.decode("utf-8").replace("\r\n", "\n")
        actual = git_blob_hash(text)
        if actual != HASHES[relative]:
            raise SystemExit(f"Refusing {relative}: expected pinned blob {HASHES[relative]}, got {actual}")
        new = transform_core(text) if relative == CORE else replace_checked(text, OLD_FLAT, NEW_FLAT, 1, "F07 flat lattice")
        backup = path.with_name(path.name + ".pre-audit.bak")
        if args.write and backup.exists():
            raise SystemExit(f"Refusing to overwrite backup: {backup}")
        changes.append((path, original_bytes, new, backup))
        print("".join(difflib.unified_diff(text.splitlines(True), new.splitlines(True),
                                         fromfile="a/" + relative, tofile="b/" + relative)))
    if not args.write:
        print("Preflight passed. Dry run: no files changed.")
        return
    replaced = []
    try:
        for path, original, new, backup in changes:
            with backup.open("xb") as f:
                f.write(original)
            temporary = path.with_name(path.name + ".audit-tmp")
            with temporary.open("w", encoding="utf-8", newline="\n") as f:
                f.write(new)
            os.replace(temporary, path)
            replaced.append((path, original))
    except Exception:
        for path, original in reversed(replaced):
            path.write_bytes(original)
        raise
    print("Canonical sources patched; backups retained. Now rebuild with:")
    print("  python validation/build_standalone.py")
    print("Then run the native regression candidates and the complete repository suite.")
    print("F05 refinement planning and F06 method scheduling are NOT changed by this patch.")

if __name__ == "__main__":
    main()
