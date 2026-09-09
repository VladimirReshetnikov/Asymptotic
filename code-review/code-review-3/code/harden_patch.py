#!/usr/bin/env python3
"""Generate (or explicitly apply) narrow hardening changes for audited 1.8.0.

Usage: python harden_patch.py /path/to/Asymptotic [--apply]
Default: print unified diff; no repository modifications.
Always regenerate the standalone distribution after applying to canonical source.
This is a targeted review patch, not a replacement for the full regression suite.
"""
from __future__ import annotations
import argparse
import difflib
import os
import tempfile
from pathlib import Path
import sys

RELATIVE = Path('AsymptoticInverse/Kernel/AsymptoticInverse.wl')
PATCHES = [
    ('fractional-power-reality',
     '  If[T === {},\n   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],',
     '  If[T === {} && P =!= Infinity && ! IntegerQ[rr],\n'
     '   fail["UnknownLeadingTerm", "A pure remainder cannot establish the real branch of a noninteger power; refine the argument first."]];\n'
     '  If[T === {},\n   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],', 1),
    ('capture-ambient-assumptions',
     '  clauses = If[Head[ass] === And, List @@ ass, {ass}];',
     '  clauses = With[{effective = ass && $Assumptions},\n'
     '    If[Head[effective] === And, List @@ effective, {effective}]];', 1),
    ('preserve-logarithmic-tail-contract',
     '  den = LCM @@ (Denominator /@ Append[exps, remData[[1]]]);',
     '  If[remData[[2]] =!= 0,\n'
     '   Return[Missing["LogarithmicRemainderNotRepresentable"], Module]];\n'
     '  den = LCM @@ (Denominator /@ Append[exps, remData[[1]]]);', 2),
    ('bound-dense-native-export',
     '  coeffs = Table[0, {nmax - nmin}];',
     '  If[nmax - nmin > 100000,\n'
     '   Return[Missing["DenseRepresentationTooLarge",\n'
     '     <|"RequestedSlots" -> nmax - nmin, "SlotLimit" -> 100000|>], Module]];\n'
     '  coeffs = Table[0, {nmax - nmin}];', 2),
]

def patch_source(source: str) -> str:
    """All-or-nothing anchor validation; also usable on the pinned standalone."""
    for name, old, _, expected in PATCHES:
        found = source.count(old)
        if found != expected:
            raise ValueError(f'{name}: expected {expected} anchors, found {found}; source version mismatch')
    for _, old, new, _ in PATCHES:
        source = source.replace(old, new)
    return source

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('checkout', type=Path)
    parser.add_argument('--apply', action='store_true', help='modify canonical source after creating a non-overwriting backup')
    args = parser.parse_args()
    source_path = args.checkout / RELATIVE
    try:
        original_bytes = source_path.read_bytes()
        original = original_bytes.decode('utf-8').replace('\r\n', '\n')
        changed = patch_source(original)
        diff = ''.join(difflib.unified_diff(original.splitlines(True), changed.splitlines(True),
                                          fromfile='a/' + RELATIVE.as_posix(), tofile='b/' + RELATIVE.as_posix()))
        sys.stdout.write(diff)
        if args.apply:
            backup = source_path.with_suffix('.wl.pre-audit-hardening')
            with backup.open('xb') as out:
                out.write(original_bytes)
            temporary = None
            try:
                with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', newline='\n',
                                                 dir=source_path.parent, delete=False) as out:
                    temporary = Path(out.name)
                    out.write(changed)
                os.chmod(temporary, source_path.stat().st_mode)
                os.replace(temporary, source_path)
            finally:
                if temporary is not None and temporary.exists():
                    temporary.unlink()
            print('\nApplied. Rebuild standalone and run native regressions; see README.', file=sys.stderr)
        return 0
    except (OSError, ValueError) as exc:
        print(f'Not applied: {exc}', file=sys.stderr)
        return 2

if __name__ == '__main__':
    raise SystemExit(main())
