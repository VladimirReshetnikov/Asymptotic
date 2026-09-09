#!/usr/bin/env python3
"""Generate a conservative patch for the pinned Asymptotic 1.8.0 kernel.

Default: print a unified diff; never modify a checkout. --output writes a new
file, which is NOT independently loadable without the companion kernel modules.
This prototype has NOT been run in a native Wolfram kernel. It addresses audit
A01, A02, and A03, but NOT the cross-cutting ambient-assumption issue A04.
"""
from __future__ import annotations
import argparse
import difflib
import hashlib
from pathlib import Path

COMMIT = "07a9781212beb2eeb9ff16aa625b50ac27974078"
EXPECTED_GIT_BLOB = "ea9eaf4a11130e922ac4fb3faae37fd8e8d29643"
KERNEL_PATH = Path("AsymptoticInverse/Kernel/AsymptoticInverse.wl")


def git_blob_sha(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def replace_once(text: str, old: str, new: str) -> str:
    count = text.count(old)
    if count != 1:
        raise ValueError(f"Expected exactly one patch anchor; found {count}: {old[:100]!r}")
    return text.replace(old, new, 1)


def transform(text: str, max_slots: int = 20000) -> str:
    """Pure transformation, separately testable on a synthetic source fixture."""
    if not isinstance(max_slots, int) or isinstance(max_slots, bool) or max_slots < 1:
        raise ValueError("max_slots must be a positive integer")
    anchor = '  If[T === {},\n   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],'
    replacement = (
        '  (* Audit A01: unknown magnitude does not establish a real power branch. *)\n'
        '  If[T === {} && P =!= Infinity && ! IntegerQ[rr],\n'
        '   fail["UnknownLeadingTerm", "A pure remainder does not establish the real branch required by a noninteger power; increase the working order."]];\n'
        + anchor)
    text = replace_once(text, anchor, replacement)
    for name, variable in (("makeSeriesData", "x"), ("makeInverseSeriesData", "y")):
        start_marker = name + "[terms_,"
        if text.count(start_marker) != 1:
            raise ValueError(f"Unexpected number of definitions for {name}")
        start = text.index(start_marker)
        end = text.find("\n\n", start)
        if end == -1:
            end = len(text)
        block = text[start:end]
        rem_anchor = '  If[remData === None, Return[Missing["Exact"], Module]];'
        rem_new = rem_anchor + (
            '\n  (* Audit A03: strict export of the power-series data part only. *)'
            '\n  If[remData[[2]] =!= 0, Return[Missing["LogarithmicRemainder"], Module]];'
            f'\n  If[! And @@ (FreeQ[#[[2]], {variable}] & /@ terms),'
            '\n   Return[Missing["VariableDependentCoefficients"], Module]];')
        block = replace_once(block, rem_anchor, rem_new)
        allocation = '  coeffs = Table[0, {nmax - nmin}];'
        guarded = (
            '  (* Audit A02: cap eager dense export before any allocation. *)\n'
            f'  If[! IntegerQ[nmax - nmin] || nmax - nmin < 0 || nmax - nmin > {max_slots},\n'
            '   Return[Missing["SeriesDataSizeLimit", <|"RequiredSlots" -> nmax - nmin, '
            f'"MaximumSlots" -> {max_slots}|>], Module]];\n' + allocation)
        block = replace_once(block, allocation, guarded)
        text = text[:start] + block + text[end:]
    return text


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Repository root or canonical kernel file")
    parser.add_argument("--output", type=Path, help="Write a NEW proposed kernel file instead of printing a diff")
    parser.add_argument("--max-slots", type=int, default=20000)
    args = parser.parse_args()
    source = args.source / KERNEL_PATH if args.source.is_dir() else args.source
    try:
        data = source.read_bytes().replace(b"\r\n", b"\n")
        if git_blob_sha(data) != EXPECTED_GIT_BLOB:
            raise ValueError("Source blob does not match the pinned audit revision. Refusing to patch.")
        original = data.decode("utf-8")
        proposed = transform(original, args.max_slots)
        if args.output:
            if args.output.resolve() == source.resolve() or args.output.exists():
                raise ValueError("Output must be a new path; existing files are never overwritten.")
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(proposed, encoding="utf-8", newline="\n")
            print(args.output)
        else:
            print("".join(difflib.unified_diff(original.splitlines(True), proposed.splitlines(True),
                fromfile=str(KERNEL_PATH), tofile=str(KERNEL_PATH)+".proposed")), end="")
    except (OSError, UnicodeError, ValueError) as exc:
        parser.exit(2, f"Patch not generated: {exc}\n")

if __name__ == "__main__":
    main()
