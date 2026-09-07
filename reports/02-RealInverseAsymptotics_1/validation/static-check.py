#!/usr/bin/env python3
"""Conservative text-level checks, NOT a Wolfram parser or interpreter.

Checks strings, nested comments, bracket balance, and native-test identifiers.
Does not execute Wolfram code or establish its syntactic or semantic validity.
"""
from __future__ import annotations
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def scan(path: Path) -> dict:
    text = path.read_text(encoding='utf-8')
    stack: list[tuple[str, int]] = []
    line = 1
    i = 0
    comment_depth = 0
    in_string = False
    escaped = False
    problems: list[str] = []
    pairs = {')': '(', ']': '[', '}': '{'}
    while i < len(text):
        ch = text[i]
        nxt = text[i:i+2]
        if ch == '\n':
            line += 1
        if comment_depth:
            if nxt == '(*':
                comment_depth += 1
                i += 2
                continue
            if nxt == '*)':
                comment_depth -= 1
                i += 2
                continue
        elif in_string:
            if escaped:
                escaped = False
            elif ch == '\\':
                escaped = True
            elif ch == '"':
                in_string = False
        elif nxt == '(*':
            comment_depth = 1
            i += 2
            continue
        elif ch == '"':
            in_string = True
        elif ch in '([{':
            stack.append((ch, line))
        elif ch in pairs:
            if not stack or stack[-1][0] != pairs[ch]:
                problems.append(f'Line {line}: unmatched {ch!r}')
            else:
                stack.pop()
        i += 1
    if in_string:
        problems.append('Unclosed string')
    if comment_depth:
        problems.append(f'Unclosed nested comment (depth {comment_depth})')
    for bracket, start_line in stack:
        problems.append(f'Unclosed {bracket!r} opened on line {start_line}')
    return {'path': str(path.relative_to(ROOT)),
            'balanced_delimiters_strings_comments': not problems,
            'problems': problems}


def main() -> int:
    paths = sorted(p for p in ROOT.rglob('*')
                   if p.is_file() and p.suffix in {'.wl', '.wlt', '.wls', '.m'})
    checks = [scan(p) for p in paths]
    suite = (ROOT/'Tests/RealInverseAsymptotics.wlt').read_text(encoding='utf-8')
    identifiers = re.findall(r'TestID\s*->\s*"([^"]+)"', suite)
    test_count = suite.count('VerificationTest[')
    unique = len(set(identifiers)) == len(identifiers) == test_count
    output = {
        'kind': 'Text-only static scan; NOT a Wolfram parser or evaluator',
        'files': checks,
        'native_test_definitions': test_count,
        'native_test_identifiers_unique': unique,
        'native_test_execution_status': 'NOT RUN',
        'passed': all(c['balanced_delimiters_strings_comments'] for c in checks) and unique,
    }
    (ROOT/'validation/static-results.json').write_text(
        json.dumps(output, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(output, indent=2))
    return 0 if output['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
