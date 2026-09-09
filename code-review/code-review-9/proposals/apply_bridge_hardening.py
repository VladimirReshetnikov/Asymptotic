#!/usr/bin/env python3
"""Proposed, opt-in bridge hardening for the pinned 1.8.0 source.

Default: print a diff, do not write. --write changes ONLY the canonical kernel
file after a Git-blob hash check. Rebuild the standalone distribution afterward.
This proposal has fixture-level Python tests; it has NOT been run in a Wolfram
kernel or applied to a downloaded complete source file during this audit.
"""
from __future__ import annotations
import argparse
import difflib
import hashlib
from pathlib import Path

EXPECTED_BLOB = "ea9eaf4a11130e922ac4fb3faae37fd8e8d29643"
SOURCE_PATH = Path("AsymptoticInverse/Kernel/AsymptoticInverse.wl")


def git_blob_sha(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def replace_exact(text: str, old: str, new: str, count: int) -> str:
    actual = text.count(old)
    if actual != count:
        raise ValueError(f"patch precondition failed: expected {count} occurrence(s), found {actual}: {old[:70]!r}")
    return text.replace(old, new)


def harden_text(text: str, max_coefficients: int = 100_000) -> str:
    if not isinstance(max_coefficients, int) or isinstance(max_coefficients, bool) or max_coefficients < 1:
        raise ValueError("max_coefficients must be a positive integer")
    text = replace_exact(text,
        "Module[{exps, den, nmin, nmax, coeffs, ptx, dirSign},",
        "Module[{exps, den, nmin, nmax, coeffs, ptx, dirSign, denseLength},", 1)
    text = replace_exact(text,
        "Module[{exps, den, nmin, nmax, coeffs},",
        "Module[{exps, den, nmin, nmax, coeffs, denseLength},", 1)
    text = replace_exact(text,
        'If[remData === None, Return[Missing["Exact"], Module]];',
        'If[remData === None, Return[Missing["Exact"], Module]];\n'
        '  (* A native O term does not carry this logarithmic envelope. *)\n'
        '  If[remData[[2]] =!= 0, Return[Missing["LogarithmicRemainder"], Module]];', 2)
    text = replace_exact(text,
        "coeffs = Table[0, {nmax - nmin}];",
        '(* Store only through the last retained coefficient; trailing zeros\n'
        '     up to nmax are implicit in SeriesData. Guard actual dense span. *)\n'
        '  denseLength = If[exps === {}, 0, Max[exps] den - nmin + 1];\n'
        '  If[! IntegerQ[denseLength] || denseLength < 0 ||\n'
        f'      denseLength > {max_coefficients},\n'
        '    Return[Missing["DenseSeriesDataBudget",\n'
        '      <|"RequiredCoefficients" -> denseLength,\n'
        f'        "MaxCoefficients" -> {max_coefficients}|>], Module]];\n'
        '  coeffs = ConstantArray[0, denseLength];', 2)
    return text


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", required=True, type=Path)
    parser.add_argument("--max-native-coefficients", type=int, default=100_000)
    parser.add_argument("--write", action="store_true", help="apply after printing the diff; default is read-only")
    args = parser.parse_args()
    source = args.repo / SOURCE_PATH
    try:
        data = source.read_bytes().replace(b"\r\n", b"\n")
        actual = git_blob_sha(data)
        if actual != EXPECTED_BLOB:
            raise ValueError(f"source blob mismatch: expected {EXPECTED_BLOB}, got {actual}; refusing to patch")
        old = data.decode("utf-8")
        new = harden_text(old, args.max_native_coefficients)
        print("".join(difflib.unified_diff(old.splitlines(True), new.splitlines(True),
              fromfile="a/" + SOURCE_PATH.as_posix(), tofile="b/" + SOURCE_PATH.as_posix())), end="")
        if args.write:
            temporary = source.with_suffix(source.suffix + ".audit-tmp")
            temporary.write_bytes(new.encode("utf-8"))
            temporary.replace(source)
            print("\nCanonical source changed. Regenerate the standalone file and run native tests before release.")
        else:
            print("\nDry run only: no files changed.")
        return 0
    except (OSError, UnicodeError, ValueError) as exc:
        parser.exit(2, f"bridge hardening refused: {exc}\n")

if __name__ == "__main__":
    raise SystemExit(main())
