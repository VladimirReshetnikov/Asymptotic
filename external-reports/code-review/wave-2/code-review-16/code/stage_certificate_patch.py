#!/usr/bin/env python3
"""Stage (do not install) two experimental certificate fixes on the pinned file.

Usage: python stage_certificate_patch.py /path/to/Asymptotic --output-dir staged
No network, no modification of the input checkout, and no claim of native
validation. Rebuild the generated standalone by the repository's documented
builder after testing a modular change. The script requires the pinned blob.
"""
from __future__ import annotations
import argparse
import hashlib
import difflib
from pathlib import Path
import re

EXPECTED = 'c447755ab58f02aa8a80fa374329e00d6ff9641e'
RELATIVE = Path('AsymptoticInverse/Kernel/InverseCertificates.wl')


def git_blob_hash(data: bytes) -> str:
    return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()


def transform(text: str) -> str:
    # The option form overrides $Assumptions; a positional assumption does not.
    out, count = re.subn(r'Refine\[condition,\s*Element\[x,\s*Reals\]\]',
                        'Refine[condition, Assumptions -> Element[x, Reals]]', text)
    if count != 1:
        raise ValueError(f'expected exactly one domain-Refine anchor, found {count}')
    old = 'If[AssociationQ[result] && ! fixed,\n    knownRoot = True;'
    new = ('If[AssociationQ[result] && ! fixed,\n'
           '    (* A successful root proof need not meet the requested accuracy.\n'
           '       Raise arithmetic precision as well as contracting its bracket. *)\n'
           '    order = Min[2000, 2 order];\n'
           '    knownRoot = True;')
    if out.count(old) != 1:
        raise ValueError('adaptive-enclosure anchor is absent or ambiguous')
    return out.replace(old, new)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('repository', type=Path)
    ap.add_argument('--output-dir', type=Path, required=True)
    args = ap.parse_args()
    source = args.repository / RELATIVE
    raw = source.read_bytes()
    canonical = raw.replace(b'\r\n', b'\n')
    if git_blob_hash(canonical) != EXPECTED:
        raise SystemExit('Refusing: input does not match the reviewed Git blob (after CRLF normalization).')
    target = args.output_dir.resolve() / RELATIVE
    if target == source.resolve():
        raise SystemExit('Refusing to overwrite the checkout; use a separate staging directory.')
    target.parent.mkdir(parents=True, exist_ok=True)
    diff_path = args.output_dir.resolve() / 'certificate-fixes.diff'
    if target.exists() or diff_path.exists():
        raise SystemExit('Refusing to overwrite an existing staged file or diff.')
    original = canonical.decode('utf-8')
    changed = transform(original)
    diff = ''.join(difflib.unified_diff(original.splitlines(keepends=True),
        changed.splitlines(keepends=True), fromfile='a/' + RELATIVE.as_posix(),
        tofile='b/' + RELATIVE.as_posix()))
    target.write_text(changed, encoding='utf-8')
    diff_path.write_text(diff, encoding='utf-8')
    print(f'Staged experimental change: {target}')
    print('Native tests have NOT been executed by this audit. Review and test before installation.')

if __name__ == '__main__':
    main()
