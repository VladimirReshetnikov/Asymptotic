"""Emit a narrow candidate diff; never modify an input file.

Usage: python emit_core_guard_patch.py /path/to/src/Kernel/CorePerturbation.wl
Tested only against exact-anchor synthetic fixtures, not a local checkout.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path

OLD = '''  validateInput[core + perturbation, limit];
  If[x === y || ! FreeQ[core + perturbation, y], fail["InvalidVariables", "Use distinct source and target symbols, with no target symbol in the forward data."]];'''
NEW = '''  validateInput[{core, perturbation}, limit];
  If[x === y || ! FreeQ[{core, perturbation}, y], fail["InvalidVariables", "Use distinct source and target symbols; the core and perturbation must each be independent of the target symbol."]];'''


def replace_guard(text: str) -> str:
    if not isinstance(text, str):
        raise TypeError('text must be a string')
    if text.count(OLD) != 1 or NEW in text:
        raise ValueError('Expected exactly one unpatched guard anchor; refusing')
    return text.replace(OLD, NEW, 1)


def unified_diff(text: str) -> str:
    changed = replace_guard(text)
    return ''.join(difflib.unified_diff(text.splitlines(keepends=True),
        changed.splitlines(keepends=True),
        fromfile='a/src/Kernel/CorePerturbation.wl',
        tofile='b/src/Kernel/CorePerturbation.wl'))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    args = parser.parse_args()
    try:
        # newline=None intentionally normalizes CRLF for the diff.
        print(unified_diff(args.source.read_text(encoding='utf-8')), end='')
    except (OSError, ValueError) as exc:
        parser.exit(2, f'{exc}\n')


if __name__ == '__main__':
    main()
