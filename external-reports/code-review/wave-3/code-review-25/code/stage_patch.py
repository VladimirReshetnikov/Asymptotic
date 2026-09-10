#!/usr/bin/env python3
"""Stage a narrow candidate patch without modifying the checkout.

Usage: python stage_patch.py PATH_TO_CHECKOUT OUTPUT_DIRECTORY
Only exact, unique source anchors are accepted. All preconditions are checked
before any output file is written. The source checkout is never modified.
The output contains ONLY changed modular files, not a complete package.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
from typing import Any


def transform(sources: dict[str, str], spec: dict[str, Any]) -> dict[str, str]:
    result = dict(sources)
    for edit in spec['edits']:
        path, old, new = edit['path'], edit['old'], edit['new']
        if path not in result:
            raise ValueError(f'Missing source: {path}')
        count = result[path].count(old)
        if count != 1:
            raise ValueError(f"{edit['id']}: expected exactly one anchor in {path}; found {count}")
        result[path] = result[path].replace(old, new, 1)
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('checkout', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    checkout, output = args.checkout.resolve(), args.output.resolve()
    if output == checkout or checkout in output.parents:
        parser.error('Choose an output directory outside the source checkout.')
    if output.exists():
        parser.error('The output directory must not already exist.')
    spec = json.loads(Path(__file__).with_name('patch_spec.json').read_text(encoding='utf-8'))
    paths = sorted({edit['path'] for edit in spec['edits']})
    try:
        sources = {path: (checkout / path).read_text(encoding='utf-8') for path in paths}
        result = transform(sources, spec)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    output.mkdir(parents=True)
    for path, text in result.items():
        destination = output / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        with destination.open('w', encoding='utf-8', newline='\n') as stream:
            stream.write(text)
    (output / 'STAGING-NOTE.txt').write_text(
        'Candidate modular files only. Review the diff, apply to a separate checkout, '
        'regenerate the standalone with validation/build_standalone.py, and run focused '
        'native tests. Exact anchor matches are not proof of whole-snapshot identity.\n',
        encoding='utf-8')
    print(f'Staged {len(result)} changed files under {output}')


if __name__ == '__main__':
    main()
