"""Emit the minimal F01 patch for a local canonical source file; never write it.

Usage: python code/prepare_erfc_patch.py /path/to/Asymptotic > erfc.patch
Checks one exact anchor. Regenerate the standalone through upstream's builder
only after accepting the patch. This script does not claim to verify a commit.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path

RELATIVE = Path("src/Kernel/SpecialFunctionAdapters.wl")
OLD = '    "Adapter" -> "Erfc", "Expression" -> expression, "Terms" -> terms,\n'
NEW = OLD + ('    "FrontierTerm" -> If[MissingQ[innerData["FrontierTerm"]],\n'
             '      innerData["FrontierTerm"], sign innerData["FrontierTerm"]],\n')


def patched_text(text: str) -> str:
    count = text.count(OLD)
    if count != 1:
        raise ValueError(f"expected exactly one unmodified Erfc anchor, found {count}")
    if NEW in text:
        raise ValueError("the proposed insertion is already present")
    return text.replace(OLD, NEW, 1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    args = parser.parse_args()
    path = args.checkout / RELATIVE
    try:
        original = path.read_text(encoding="utf-8")
        revised = patched_text(original)
    except (OSError, UnicodeError, ValueError) as exc:
        parser.error(str(exc))
    print("".join(difflib.unified_diff(original.splitlines(keepends=True),
          revised.splitlines(keepends=True), fromfile="a/" + RELATIVE.as_posix(),
          tofile="b/" + RELATIVE.as_posix())), end="")


if __name__ == "__main__":
    main()
