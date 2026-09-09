#!/usr/bin/env python3
"""Download (but never execute) the audited standalone source, verifying its Git blob.
Requires internet access. Not executed in the audit environment.
"""
from __future__ import annotations
import argparse
import hashlib
from pathlib import Path
import urllib.error
import urllib.request

COMMIT = '07a9781212beb2eeb9ff16aa625b50ac27974078'
BLOB = '65363f73158c3d01e10fa274385341f9585c1efc'
URL = f'https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/{COMMIT}/AsymptoticInverse.wl'
LIMIT = 4 * 1024 * 1024


def blob_hash(data: bytes) -> str:
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=Path('source/AsymptoticInverse.wl'))
    args = parser.parse_args()
    try:
        if args.output.exists():
            data = args.output.read_bytes()
            if blob_hash(data) != BLOB:
                raise ValueError('destination already exists with different contents; refusing to overwrite')
            print(f'Already verified: {args.output}')
            return 0
        request = urllib.request.Request(URL, headers={'User-Agent': 'AsymptoticSourceAudit/1.0'})
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read(LIMIT + 1)
        if len(data) > LIMIT:
            raise ValueError('download exceeded the safety limit')
        if blob_hash(data) != BLOB:
            raise ValueError('download does not match the audited Git blob; refusing to save')
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open('xb') as handle:
            handle.write(data)
        print(f'Verified {len(data)} bytes at {args.output}')
        print('SHA256:', hashlib.sha256(data).hexdigest())
        print('No Wolfram code was executed.')
        return 0
    except (OSError, ValueError, urllib.error.URLError) as exc:
        parser.exit(2, f'download failed: {exc}\n')

if __name__ == '__main__':
    raise SystemExit(main())
