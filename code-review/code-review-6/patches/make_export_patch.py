#!/usr/bin/env python3
"""Generate a conservative exporter patch for the reviewed core blob.
Default: print a unified diff, without changing the repository.
With --in-place: back up and atomically replace ONLY the canonical core file.
The modified Wolfram code has not been run in a native kernel in this audit.
After applying: rebuild the standalone distribution and run native tests.
"""
from __future__ import annotations
import argparse
import difflib
import hashlib
from pathlib import Path
import os
import tempfile

EXPECTED_BLOB = 'ea9eaf4a11130e922ac4fb3faae37fd8e8d29643'
LIMIT = 200000
MARK = '(* Asymptotic audit: preserve remainder metadata and bound dense export. *)'

def git_blob_sha(data: bytes) -> str:
    return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()

def patch_text(text: str) -> str:
    if MARK in text:
        raise ValueError('Audit patch is already present')
    for name in ('makeSeriesData', 'makeInverseSeriesData'):
        start=text.find('\n'+name+'[terms_')
        if start < 0:
            raise ValueError(f'Expected definition not found: {name}')
        start += 1
        end=text.find('\n\n',start)
        if end < 0:
            end=len(text)
        body=text[start:end]
        denline='  den = LCM @@ (Denominator /@ Append[exps, remData[[1]]]);'
        alloc='  coeffs = Table[0, {nmax - nmin}];'
        if body.count(denline)!=1 or body.count(alloc)!=1:
            raise ValueError(f'Unexpected source layout in {name}; manual review required')
        body=body.replace(denline, '  '+MARK+'\n'
            '  If[remData[[2]] =!= 0, Return[Missing["LogarithmicRemainder"], Module]];\n'+denline)
        body=body.replace(alloc,
            f'  If[nmax - nmin > {LIMIT}, Return[Missing["DenseRepresentationBudget", nmax - nmin], Module]];\n'+alloc)
        text=text[:start]+body+text[end:]
    return text

def main() -> None:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('core_file',type=Path)
    parser.add_argument('--in-place',action='store_true')
    args=parser.parse_args()
    p=args.core_file.resolve()
    original=p.read_bytes()
    data=original.replace(b'\r\n',b'\n')
    sha=git_blob_sha(data)
    if sha!=EXPECTED_BLOB:
        raise SystemExit(f'Refusing source drift: expected blob {EXPECTED_BLOB}, got {sha}')
    text=data.decode('utf-8'); changed=patch_text(text)
    if not args.in_place:
        print(''.join(difflib.unified_diff(text.splitlines(True),changed.splitlines(True),
            fromfile=str(p),tofile=str(p)+' (proposed)')),end='')
        return
    backup=p.with_name(p.name+'.pre-audit')
    with backup.open('xb') as out:
        out.write(original)
    fd,temp=tempfile.mkstemp(prefix=p.name+'.',dir=p.parent)
    try:
        with os.fdopen(fd,'w',encoding='utf-8',newline='\n') as out:
            out.write(changed)
        os.chmod(temp,p.stat().st_mode)
        os.replace(temp,p)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)
    print(f'Patched {p}; backup: {backup}. Rebuild standalone and run native tests.')

if __name__=='__main__':
    main()
