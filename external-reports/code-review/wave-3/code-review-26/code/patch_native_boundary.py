#!/usr/bin/env python3
"""Apply a bounded native-boundary candidate to the audited repository revision.

Dry-run (default) emits a unified diff. --apply writes only the canonical module.
Regenerate the standalone file with the repository's own build_standalone.py.
No network access, checksum files, or upstream mutation is performed.
"""
from __future__ import annotations
import argparse
import difflib
import json
from pathlib import Path
import subprocess
import sys

PIN = '6687962f3c858a4f93623cfc496f33e35c6763d4'

def apply_text(text: str, spec: dict) -> str:
    """Fail closed on every unexpected anchor; never perform a partial edit."""
    if '$nativeBoundaryExpansionDefaults =' in text:
        raise ValueError('Candidate already present; refusing a second application.')
    for edit in spec['replacements']:
        actual = text.count(edit['old'])
        if actual != edit['count']:
            raise ValueError(f"Anchor mismatch: expected {edit['count']}, found {actual}: {edit['old']!r}")
    for edit in spec['replacements']:
        text = text.replace(edit['old'], edit['new'])
    return text.rstrip() + '\n' + spec['append'].lstrip('\n')

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('repository', type=Path)
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--allow-other-revision', action='store_true',
                    help='Allow a different HEAD; exact source-anchor checks still apply.')
    args = ap.parse_args()
    root = args.repository.resolve()
    try:
        head = subprocess.run(['git', '-C', str(root), 'rev-parse', 'HEAD'],
                              check=True, capture_output=True, text=True).stdout.strip()
        if head != PIN and not args.allow_other_revision:
            raise ValueError(f'Expected HEAD {PIN}; found {head}.')
        spec = json.loads(Path(__file__).with_name('native_boundary_patch.json').read_text())
        target = root / spec['source_path']
        before = target.read_text(encoding='utf-8')
        after = apply_text(before, spec)
        print(''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True),
                                          fromfile='a/' + spec['source_path'],
                                          tofile='b/' + spec['source_path'])), end='')
        if args.apply:
            # Replace atomically; no source is overwritten before validation.
            temp = target.with_suffix(target.suffix + '.audit-tmp')
            temp.write_text(after, encoding='utf-8', newline='\n')
            temp.replace(target)
            print('\nApplied candidate. Regenerate standalone and run focused tests.', file=sys.stderr)
        return 0
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as exc:
        print(f'Patch refused: {exc}', file=sys.stderr)
        return 2

if __name__ == '__main__':
    raise SystemExit(main())
