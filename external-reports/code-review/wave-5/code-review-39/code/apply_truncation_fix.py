#!/usr/bin/env python3
"""Opt-in, source-matched candidate patch for finding N01.

Default: print a unified diff only. With --write: modify the modular source
atomically. Rebuild the standalone file using the repository's own builder.
No checksums or checksum files are produced.
"""
from __future__ import annotations
import argparse
import difflib
import os
from pathlib import Path
import stat
import tempfile

RELATIVE = Path("src/Kernel/SeriesOperations.wl")
OLD = '''  keys = {"AbsoluteRemainderBound", "RemainderBoundConditions", "RemainderLowerBound",
    "RemainderBoundConstant", "ForwardRemainderContract", "FirstOmittedInteger", "FiniteSourceExpansion"};'''
NEW = '''  keys = {"AbsoluteRemainderBound", "RemainderBoundConditions", "RemainderLowerBound",
    "RemainderBoundConstant", "ForwardRemainderContract", "FirstOmittedInteger", "FiniteSourceExpansion",
    "TruncationDiscardedPart"};'''



def patched_bytes(data: bytes) -> bytes:
    text = data.decode("utf-8")
    newline = "\r\n" if "\r\n" in text and "\n" not in text.replace("\r\n", "") else "\n"
    normalized = text.replace("\r\n", "\n")
    if normalized.count(OLD) != 1:
        raise ValueError("Expected exactly one pinned-source companion-key list; refusing an unmatched patch")
    return normalized.replace(OLD, NEW, 1).replace("\n", newline).encode("utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", type=Path, help="local repository root")
    parser.add_argument("--write", action="store_true", help="actually modify the modular source")
    args = parser.parse_args()
    target = args.repo / RELATIVE
    try:
        info = target.lstat()
        if not stat.S_ISREG(info.st_mode) or target.is_symlink():
            raise ValueError("Target must be a regular non-symlink file")
        before = target.read_bytes()
        after = patched_bytes(before)
        print("".join(difflib.unified_diff(before.decode("utf-8").splitlines(True),
            after.decode("utf-8").splitlines(True), fromfile="a/"+RELATIVE.as_posix(),
            tofile="b/"+RELATIVE.as_posix())), end="")
        if args.write:
            temporary = None
            try:
                with tempfile.NamedTemporaryFile(dir=target.parent, prefix=".n01-", delete=False) as stream:
                    temporary = Path(stream.name)
                    stream.write(after)
                    stream.flush()
                    os.fsync(stream.fileno())
                os.chmod(temporary, stat.S_IMODE(info.st_mode))
                # A last content check prevents overwriting an observed concurrent edit.
                # This is not a filesystem lock or a defense against hostile races.
                if target.read_bytes() != before:
                    raise ValueError("Source changed while preparing the patch")
                os.replace(temporary, target)
            finally:
                if temporary is not None and temporary.exists():
                    temporary.unlink()
            print("Applied modular-source patch. Rebuild AsymptoticAnalysis.wl before standalone use.")
        return 0
    except (OSError, UnicodeError, ValueError) as exc:
        parser.exit(2, f"{exc}\n")

if __name__ == "__main__":
    raise SystemExit(main())
