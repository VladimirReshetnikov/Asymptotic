"""Candidate delimiter-aware Mathics bootstrap splitter.

This is a narrowly scoped source-preprocessing prototype, NOT a full Wolfram
Language parser. It retains the reference builder's semicolon-terminated
statement convention. Its runtime-generated WL has NOT been run in either
Wolfram or Mathics. Standalone Python tests exercise the splitter only.

Supported grouping tokens: (), [], {}, and association delimiters in ASCII,
long-name, and U+F113/U+F114 form. Strings/comments are masked without changing
positions. Box syntax and other matchfix forms require a proper parser.
"""
from __future__ import annotations
import json
from bootstrap_reference import executable_text

# Wolfram documentation identifies LeftAssociation as F113 and Right as F114.
_OPEN = {
    '(': ')', '[': ']', '{': '}',
    '<|': 'ASSOCIATION', r'\[LeftAssociation]': 'ASSOCIATION',
    '\uf113': 'ASSOCIATION',
}
_CLOSE = {')': ')', ']': ']', '}': '}',
          '|>': 'ASSOCIATION', r'\[RightAssociation]': 'ASSOCIATION',
          '\uf114': 'ASSOCIATION'}
_TOKENS = tuple(sorted(set(_OPEN) | set(_CLOSE), key=len, reverse=True))


def split_statements(source: str) -> list[str]:
    if not isinstance(source, str):
        raise TypeError('source must be a string')
    code = executable_text(source)
    # These tokens are outside this prototype's declared source grammar.
    for unsupported in (r'\(', r'\)', r'\[LeftDoubleBracket]',
                        r'\[RightDoubleBracket]', '\u301a', '\u301b'):
        if unsupported in code:
            raise ValueError('Unsupported grouping syntax; use a WL parser')
    stack: list[tuple[str, int]] = []
    statements: list[str] = []
    start = i = 0
    while i < len(code):
        # These are operators, not CompoundExpression delimiters.
        if code[i:i + 2] in {'/;', ';;'}:
            i += 2
            continue
        token = next((t for t in _TOKENS if code.startswith(t, i)), None)
        if token is not None:
            if token in _OPEN:
                stack.append((_OPEN[token], i))
            else:
                expected = _CLOSE[token]
                if not stack or stack[-1][0] != expected:
                    raise ValueError(f'Mismatched closing token at offset {i}: {token}')
                stack.pop()
            i += len(token)
            continue
        if code[i] == ';' and not stack:
            statements.append(source[start:i + 1])
            start = i + 1
        i += 1
    if stack:
        raise ValueError(f'Unclosed grouping token at offset {stack[-1][1]}')
    if code[start:].strip():
        statements.append(source[start:])
    return statements


def mathics_bootstrap(source: str) -> str:
    quoted = ',\n'.join(json.dumps(s, ensure_ascii=False)
                         for s in split_statements(source))
    return ('If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {\n'
            + quoted + '\n}]];')
