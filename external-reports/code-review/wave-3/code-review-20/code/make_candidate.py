#!/usr/bin/env python3
"""Produce a review candidate from the pinned, clean canonical module.

This never edits the checkout. No checksum files are created. The five edits
are deliberately narrow; see the article for their remaining design limits.
"""
from __future__ import annotations
import argparse
import difflib
import json
from pathlib import Path
import subprocess

PIN = '6687962f3c858a4f93623cfc496f33e35c6763d4'
MODULE = Path('src/Kernel/NativeCompatibility.wl')


def patch_rules() -> list[dict]:
    return json.loads(Path(__file__).with_name('patch_rules.json').read_text(encoding='utf-8'))


def apply_rules(text: str, rules: list[dict] | None = None) -> str:
    """Validate all original anchors before applying any edits."""
    rules = patch_rules() if rules is None else rules
    for rule in rules:
        actual = text.count(rule['old'])
        if actual != rule['count']:
            raise ValueError(f"{rule['id']}: expected {rule['count']} anchors; found {actual}")
    for rule in rules:
        text = text.replace(rule['old'], rule['new'])
    return text


def git(repo: Path, *args: str) -> str:
    try:
        return subprocess.run(['git', '-C', str(repo), *args], check=True,
                              capture_output=True, text=True).stdout.strip()
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        raise ValueError(f'Cannot establish checkout provenance: {exc}') from exc


def build(repo: Path, output: Path) -> None:
    repo = repo.resolve()
    if git(repo, 'rev-parse', 'HEAD') != PIN:
        raise ValueError(f'Checkout must be pinned to {PIN}; use a separate worktree.')
    if git(repo, 'status', '--porcelain', '--', MODULE.as_posix()):
        raise ValueError('The canonical target module has uncommitted changes.')
    source = repo / MODULE
    before = source.read_text(encoding='utf-8')
    after = apply_rules(before)
    # Do not overwrite or partly populate an existing output directory.
    output.mkdir(parents=True, exist_ok=False)
    (output / MODULE.name).write_text(after, encoding='utf-8')
    diff = ''.join(difflib.unified_diff(before.splitlines(keepends=True),
                 after.splitlines(keepends=True), fromfile='a/'+MODULE.as_posix(),
                 tofile='b/'+MODULE.as_posix()))
    (output / 'native-compatibility-candidate.patch').write_text(diff, encoding='utf-8')
    receipt = {'base_commit': PIN, 'target': MODULE.as_posix(),
               'edits': [r['id'] for r in patch_rules()],
               'status': 'Review candidate; groups tested separately, combined integration not established',
               'upstream_checkout_changed': False}
    (output / 'candidate_record.json').write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(receipt, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('repository', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    try:
        build(args.repository, args.out)
    except (ValueError, OSError) as exc:
        parser.exit(2, f'Candidate not produced: {exc}\n')

if __name__ == '__main__':
    main()
