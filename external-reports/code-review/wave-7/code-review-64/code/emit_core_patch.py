"""Emit the N01 patch without modifying the repository.

Usage: python code/emit_core_patch.py /path/to/Asymptotic --output fix.patch
Exact anchors fail closed on source drift. The emitter is tested on synthetic
fixtures only; the entire repository was not available in this review runtime.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path

RELATIVE_PATH = Path("src/Kernel/CorePerturbation.wl")
REPLACEMENTS = (
    ("  validateInput[core + perturbation, limit];",
     "  validateInput[{core, perturbation}, limit];"),
    ('  If[x === y || ! FreeQ[core + perturbation, y], fail["InvalidVariables", "Use distinct source and target symbols, with no target symbol in the forward data."]];',
     '  If[x === y || ! FreeQ[{core, perturbation}, y], fail["InvalidVariables", "Use distinct source and target symbols, with no target symbol in either core or perturbation."]];'),
)


def patched_text(text: str) -> str:
    for old, _ in REPLACEMENTS:
        if text.count(old) != 1:
            raise ValueError("expected exactly one unchanged source anchor: " + old)
    for old, new in REPLACEMENTS:
        text = text.replace(old, new, 1)
    return text


def patch_for(text: str) -> str:
    changed = patched_text(text)
    path = RELATIVE_PATH.as_posix()
    return "".join(difflib.unified_diff(
        text.splitlines(keepends=True), changed.splitlines(keepends=True),
        fromfile="a/"+path, tofile="b/"+path))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    source = args.repository / RELATIVE_PATH
    try:
        text = source.read_text(encoding="utf-8")
        patch = patch_for(text)
        if args.output:
            if args.output.resolve() == source.resolve():
                raise ValueError("output must not overwrite the source")
            args.output.write_text(patch, encoding="utf-8", newline="\n")
        else:
            print(patch, end="")
    except (OSError, ValueError) as exc:
        parser.error(str(exc))


if __name__ == "__main__":
    main()
