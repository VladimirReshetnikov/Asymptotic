#!/usr/bin/env python3
"""Emit a pinned-source affine certificate patch. Never writes a repository.
Usage: python emit_affine_patch.py /path/to/Asymptotic > affine.diff
Review/apply the diff yourself; rebuild the standalone using the upstream builder.
"""
from __future__ import annotations
import argparse
import difflib
import hashlib
from pathlib import Path

RELATIVE = Path('AsymptoticInverse/Kernel/InverseCertificates.wl')
BLOB = 'c447755ab58f02aa8a80fa374329e00d6ff9641e'
HEADER = 'certEnclose[expression_, x_Symbol, interval_, ctx_] := Module[{args, base, exponent, upper},'
OLD = '''   Head[expression] === Plus,
    Fold[certAdd[#1, #2, ctx] &, {0, 0}, certEnclose[#, x, interval, ctx] & /@ (List @@ expression)],'''
NEW = '''   Head[expression] === Plus,
    upper = certAuditAffineRange[expression, x, interval, ctx];
    If[upper =!= $Failed, upper,
      Fold[certAdd[#1, #2, ctx] &, {0, 0}, certEnclose[#, x, interval, ctx] & /@ (List @@ expression)]],'''


def git_blob(data: bytes) -> str:
    return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()


def transform(text: str, helper: str) -> str:
    if text.count(HEADER) != 1 or text.count(OLD) != 1:
        raise ValueError('Missing or duplicate source anchor; no diff emitted')
    if 'certAuditAffinePair' in text:
        raise ValueError('Proposed helper already present')
    return text.replace(HEADER, helper.rstrip()+'\n\n'+HEADER, 1).replace(OLD, NEW, 1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('repository', type=Path)
    args = parser.parse_args()
    path = args.repository/RELATIVE
    data = path.read_bytes().replace(b'\r\n',b'\n')
    if git_blob(data) != BLOB:
        parser.error('File does not match the audited Git blob (LF-normalized); refusing a speculative patch')
    source = data.decode('utf-8')
    helper = Path(__file__).with_name('affine_helper.wl').read_text(encoding='utf-8')
    result = transform(source,helper)
    print(''.join(difflib.unified_diff(source.splitlines(keepends=True),
        result.splitlines(keepends=True),fromfile='a/'+RELATIVE.as_posix(),
        tofile='b/'+RELATIVE.as_posix())),end='')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
