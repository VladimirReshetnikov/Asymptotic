"""Emit a candidate copy; never overwrite a source file.

Accepts either src/Kernel/InverseCertificates.wl or the standalone .wl. Each
anchor must occur exactly once. Edit the canonical module in a staging checkout
and use that checkout's normal standalone builder before integration.
"""
from __future__ import annotations
import argparse
from pathlib import Path

REPAIRS = (
    (
        '  If[q === 1, Return[{0, 0}, Module]];\n'
        '  exponent = IntegerLength[Numerator[q], 2]',
        '  If[q === 1, Return[{0, 0}, Module]];\n'
        '  If[q < 1, Return[certNeg[certLogPoint[1/q, ctx]], Module]];\n'
        '  exponent = IntegerLength[Numerator[q], 2]',
    ),
    (
        'certLogExpression[argument_, x_, interval_, ctx_] := Module[{candidate},\n'
        '  If[argument === E',
        'certLogExpression[argument_, x_, interval_, ctx_] := Module[{candidate},\n'
        '  If[MemberQ[{Plus, Times}, Head[argument]],\n'
        '    candidate = certAffineRange[argument, x, interval];\n'
        '    If[ListQ[candidate], Return[certLog[candidate, ctx], Module]]];\n'
        '  If[argument === E',
    ),
)


def patch_text(text: str, mode: str = 'both') -> str:
    choices = {'reciprocal': (0,), 'affine': (1,), 'both': (0, 1)}
    if mode not in choices:
        raise ValueError('mode must be reciprocal, affine, or both')
    for i in choices[mode]:
        before, after = REPAIRS[i]
        count = text.count(before)
        if count != 1:
            raise ValueError(f'repair {i+1}: expected one anchor, found {count}; no output written')
        text = text.replace(before, after, 1)
    return text


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--mode', choices=('reciprocal', 'affine', 'both'), default='both')
    args = parser.parse_args()
    if args.source.resolve() == args.destination.resolve():
        parser.error('source and destination must differ')
    if args.destination.exists():
        parser.error('destination already exists; refusing to overwrite')
    try:
        original = args.source.read_text(encoding='utf-8')
        result = patch_text(original, args.mode)
        args.destination.parent.mkdir(parents=True, exist_ok=True)
        with args.destination.open('x', encoding='utf-8', newline='\n') as stream:
            stream.write(result)
    except (OSError, ValueError) as exc:
        parser.exit(1, f'{exc}\n')
    print(f'Wrote candidate: {args.destination}')

if __name__ == '__main__':
    main()
