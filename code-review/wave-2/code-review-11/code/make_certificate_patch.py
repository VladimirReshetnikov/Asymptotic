#!/usr/bin/env python3
"""Generate a review-only, source-pinned candidate. Never edit the input file.

Only the certificate Refine call is changed. This is NOT a complete repair of
all ambient-assumption behavior, and native integration remains unverified.
"""
from __future__ import annotations
import argparse
import difflib
import hashlib
import json
from pathlib import Path

COMMIT = '921387e5ba1239bfda96e63e64e89bf63d9c41e6'
EXPECTED_BLOB = 'c447755ab58f02aa8a80fa374329e00d6ff9641e'
ANCHOR = 'Refine[condition, Element[x, Reals]]'
REPLACEMENT = 'Refine[condition, Element[x, Reals], Assumptions -> True]'
SOURCE_PATH = 'AsymptoticInverse/Kernel/InverseCertificates.wl'


def git_blob(data: bytes) -> str:
    return hashlib.sha1(b'blob ' + str(len(data)).encode('ascii') + b'\0' + data).hexdigest()


def candidate(data: bytes, expected_blob: str = EXPECTED_BLOB) -> tuple[bytes, dict]:
    # A CRLF checkout is accepted only when its LF-normalized Git blob matches.
    normalized = data.replace(b'\r\n', b'\n')
    text = normalized.decode('utf-8', errors='strict')
    actual = git_blob(normalized)
    if actual != expected_blob:
        raise ValueError(f'Source mismatch: expected {expected_blob}, received {actual}')
    if text.count(ANCHOR) != 1:
        raise ValueError('Expected exactly one certificate Refine anchor')
    result = text.replace(ANCHOR, REPLACEMENT).encode('utf-8')
    return result, {
        'commit': COMMIT, 'source_path': SOURCE_PATH,
        'original_git_blob_lf': actual,
        'input_newlines_normalized': normalized != data,
        'candidate_sha256': hashlib.sha256(result).hexdigest(),
        'replacement_count': 1,
        'native_patch_execution': 'not completed in this audit',
        'scope': 'Isolate this Refine call from ambient $Assumptions only',
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path, help='Pinned canonical InverseCertificates.wl')
    parser.add_argument('--out', required=True, type=Path, help='New output directory')
    args = parser.parse_args()
    raw = args.source.read_bytes()
    patched, metadata = candidate(raw)
    args.out.mkdir(parents=True, exist_ok=False)
    (args.out/'InverseCertificates.wl').write_bytes(patched)
    old = raw.replace(b'\r\n',b'\n').decode('utf-8')
    diff = ''.join(difflib.unified_diff(old.splitlines(True), patched.decode().splitlines(True),
        fromfile='a/'+SOURCE_PATH, tofile='b/'+SOURCE_PATH))
    (args.out/'certificate-assumptions.patch').write_text(diff, encoding='utf-8')
    (args.out/'manifest.json').write_text(json.dumps(metadata, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(metadata, indent=2))

if __name__ == '__main__':
    main()
