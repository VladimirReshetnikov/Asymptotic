#!/usr/bin/env python3
"""Create patched copies; never overwrite a repository or touch its Git state.

Usage: python patch_certificate.py /path/to/Asymptotic --output /path/to/new-dir
Pinned Git blob identities are checked after CRLF->LF normalization. This is an
experimental source patch, not a claim of repository-wide validation. Rebuild the
standalone from the patched module in a real checkout before proposing a commit.
"""
from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path

FILES = {
    'AsymptoticInverse/Kernel/InverseCertificates.wl':
        'c447755ab58f02aa8a80fa374329e00d6ff9641e',
    'AsymptoticInverse.wl': '609eaae41eac2a0f00c9c898b22265375add4306',
}
OLD_ORDER = 'order = Max[wp + 10, digits + 15]'
NEW_ORDER = '''If[relative =!= Automatic,
    digits = Max[digits, Max[0, IntegerLength[Denominator[relative]] -
      IntegerLength[Numerator[relative]]]]];
  order = Max[wp + 10, digits + 15]'''
OLD_PROGRESS = 'knownRoot = True;'
NEW_PROGRESS = '''(* A certified interval need not meet the requested accuracy.
       Increase arithmetic precision on this path too. *)
    order = Min[2000, 2 order]; knownRoot = True;'''

def git_blob(data: bytes) -> str:
    return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()

def patch_text(text: str) -> str:
    for old in (OLD_ORDER, OLD_PROGRESS):
        if text.count(old) != 1:
            raise ValueError(f'Expected exactly one patch anchor: {old!r}')
    return text.replace(OLD_ORDER, NEW_ORDER).replace(OLD_PROGRESS, NEW_PROGRESS)

def main() -> None:
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('repository', type=Path)
    ap.add_argument('--output', type=Path, required=True)
    args=ap.parse_args()
    repo=args.repository.resolve(); dest=args.output.resolve()
    if dest==repo or repo in dest.parents:
        ap.error('Choose an output directory outside the repository')
    if dest.exists() and any(dest.iterdir()):
        ap.error('Output directory must be absent or empty')
    plan=[]
    for name,expected in FILES.items():
        data=(repo/name).read_bytes().replace(b'\r\n',b'\n')
        actual=git_blob(data)
        if actual!=expected:
            ap.error(f'{name}: Git blob {actual} differs from pinned {expected}')
        patched=patch_text(data.decode('utf-8')).encode('utf-8')
        plan.append((name,data,patched))
    dest.mkdir(parents=True,exist_ok=True)
    manifest=[]
    for name,data,patched in plan:
        target=dest/name; target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(patched)
        manifest.append({'path':name,'before_sha256':hashlib.sha256(data).hexdigest(),
                         'after_sha256':hashlib.sha256(patched).hexdigest()})
    (dest/'patch_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(f'Created {len(plan)} patched copies in {dest}; repository unchanged.')

if __name__=='__main__':
    main()
