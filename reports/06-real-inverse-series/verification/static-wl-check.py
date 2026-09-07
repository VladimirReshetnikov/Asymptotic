#!/usr/bin/env python3
"""Check delimiter/string/nested-comment balance, NOT Wolfram syntax or semantics.

This intentionally modest lexical check needs only Python's standard library.
Native execution remains necessary; a PASS here is not a Wolfram test pass.
"""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def check(path: Path) -> dict:
    text = path.read_text(encoding='utf-8')
    stack: list[tuple[str,int]] = []
    comment = 0
    quoted = False
    i = 0
    line = 1
    pairs = {')': '(', ']': '[', '}': '{'}
    while i < len(text):
        a = text[i]
        b = text[i:i+2]
        if a == '\n':
            line += 1
        if quoted:
            if a == '\\':
                i += 2
                continue
            if a == '"':
                quoted = False
        elif comment:
            if b == '(*':
                comment += 1
                i += 2
                continue
            if b == '*)':
                comment -= 1
                i += 2
                continue
        elif b == '(*':
            comment = 1
            i += 2
            continue
        elif a == '"':
            quoted = True
        elif a in '([{':
            stack.append((a, line))
        elif a in ')]}':
            if not stack or stack[-1][0] != pairs[a]:
                raise ValueError(f'{path}:{line}: mismatched {a}')
            stack.pop()
        i += 1
    if quoted or comment or stack:
        raise ValueError(f'{path}: incomplete string/comment/delimiters: {quoted,comment,stack}')
    return {'file': str(path.relative_to(ROOT)), 'balanced': True, 'lines': text.count('\n')}


def main() -> None:
    paths = sorted(p for folder in ['Kernel', 'Tests', 'Examples']
                   for p in (ROOT/folder).iterdir() if p.suffix in {'.wl','.wlt','.m'})
    results = [check(p) for p in paths]
    test_count = (ROOT/'Tests'/'RealInverseSeries.wlt').read_text().count('VerificationTest[')
    assert test_count == 33, test_count
    report = {'check': 'lexical delimiter, string, and nested-comment balance only',
              'native_wolfram_execution': False, 'files': results,
              'native_test_count': test_count}
    (ROOT/'verification'/'static-wl-report.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
