#!/usr/bin/env python3
"""Emit a focused patch, or create a separate patched copy (never overwrite).

Target: AsymptoticAnalysis, revision 8cee870994f506b501bae3ea6bd4a3a7edb895c1.
The guard replacement was exercised in Wolfram 15.0.0 on the standalone file.
This utility's fixtures are independent Python tests, not package acceptance.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path
import sys

OLD = '! FreeQ[{shift, requested}, x]'
NEW = '! FreeQ[shift, x | y] || ! FreeQ[requested, x]'


def patch_text(text: str) -> str:
    """Replace exactly one audited anchor; refuse drift and repeated application."""
    if NEW in text:
        raise ValueError('The replacement is already present; inspect the current source.')
    count = text.count(OLD)
    if count != 1:
        raise ValueError(f'Expected exactly one original guard, found {count}.')
    return text.replace(OLD, NEW, 1)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path,
                        help='Canonical ExponentialCorePerturbation.wl or a standalone copy')
    parser.add_argument('--output', type=Path,
                        help='Create this separate patched file; it must not already exist')
    args = parser.parse_args(argv)
    try:
        with args.source.open('r', encoding='utf-8', newline='') as stream:
            before = stream.read()
        after = patch_text(before)
        if args.output is None:
            sys.stdout.writelines(difflib.unified_diff(
                before.splitlines(keepends=True), after.splitlines(keepends=True),
                fromfile=str(args.source), tofile=str(args.source) + '.patched'))
        else:
            if args.output.resolve() == args.source.resolve():
                raise ValueError('Refusing to replace the original source; choose a new output.')
            with args.output.open('x', encoding='utf-8', newline='') as stream:
                stream.write(after)
            print(f'Created {args.output}')
    except (OSError, UnicodeError, ValueError) as exc:
        print(f'Patch refused: {exc}', file=sys.stderr)
        return 2
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
