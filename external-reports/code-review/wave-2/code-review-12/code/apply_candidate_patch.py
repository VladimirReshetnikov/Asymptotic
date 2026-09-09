#!/usr/bin/env python3
"""Create an experimental modular-source patch without modifying the checkout.

Usage: python apply_candidate_patch.py /path/to/Asymptotic --output /new/empty/path
The expected commit is checked when git metadata is available; exact unique
anchors are mandatory even when the input is an exported source directory.
This is not a release patch. Review the article's validation limits first.
"""
from __future__ import annotations
import argparse
import difflib
import hashlib
import json
from pathlib import Path
import subprocess

PIN = '921387e5ba1239bfda96e63e64e89bf63d9c41e6'

def transform(text: str, rules: list[dict[str, str]]) -> str:
    for rule in rules:
        count = text.count(rule['old'])
        if count != 1:
            raise ValueError(f"{rule['id']}: expected exactly one anchor, found {count}")
        text = text.replace(rule['old'], rule['new'], 1)
    return text

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('checkout', type=Path)
    ap.add_argument('--output', type=Path, required=True)
    ns = ap.parse_args()
    root, out = ns.checkout.resolve(), ns.output.resolve()
    if not root.is_dir():
        ap.error('checkout must be an existing directory')
    if out == root or root in out.parents:
        ap.error('output must be outside the input checkout')
    if out.exists():
        ap.error('output must not already exist')
    git_version = None
    if (root / '.git').exists():
        git_version = subprocess.run(['git', '-C', str(root), 'rev-parse', 'HEAD'],
            check=True, capture_output=True, text=True).stdout.strip()
        if git_version != PIN:
            ap.error(f'checkout is {git_version}, expected {PIN}')
    rules = json.loads(Path(__file__).with_name('patch_rules.json').read_text())
    records, staged, diffs = [], {}, []
    for filename in dict.fromkeys(r['file'] for r in rules):
        raw = (root / filename).read_bytes()
        original = raw.decode('utf-8').replace('\r\n', '\n')
        result = transform(original, [r for r in rules if r['file'] == filename])
        staged[filename] = result
        records.append({'file': filename, 'original_sha256': hashlib.sha256(raw).hexdigest(),
                        'patched_utf8_sha256': hashlib.sha256(result.encode()).hexdigest()})
        diffs.extend(difflib.unified_diff(original.splitlines(True), result.splitlines(True),
                     fromfile='a/' + filename, tofile='b/' + filename))
    # Write only after all inputs and unique anchors have passed validation.
    out.mkdir(parents=True)
    for filename, result in staged.items():
        dest = out / filename
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(result, encoding='utf-8')
    (out / 'candidate.patch').write_text(''.join(diffs), encoding='utf-8')
    (out / 'patch_manifest.json').write_text(json.dumps({'expected_commit': PIN,
        'observed_commit': git_version, 'files': records}, indent=2) + '\n')
    print(f'Created candidate patch and modular source copies in {out}')
    print('The original checkout and its generated standalone file were not changed.')
    print('After review/application, regenerate the standalone distribution with the repository builder.')

if __name__ == '__main__':
    main()
