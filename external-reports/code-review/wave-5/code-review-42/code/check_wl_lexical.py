#!/usr/bin/env python3
"""Check delimiter, string and nested-comment balance only; NOT a WL parser.

Checks the supplied native runner and the two candidate replacement snippets.
No Wolfram/Mathics code is executed and no semantic correctness is inferred.
"""
from __future__ import annotations
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def check(text: str) -> dict:
    stack: list[tuple[str, int]] = []
    comments = 0
    string = False
    line = 1
    i = 0
    while i < len(text):
        c = text[i]
        pair = text[i:i + 2]
        if c == '\n':
            line += 1
        if comments:
            if pair == '(*':
                comments += 1
                i += 2
            elif pair == '*)':
                comments -= 1
                i += 2
            else:
                i += 1
            continue
        if string:
            if c == '\\':
                if i + 1 < len(text) and text[i + 1] == '\n':
                    line += 1
                i += 2
            else:
                if c == '"':
                    string = False
                i += 1
            continue
        if pair == '(*':
            comments = 1
            i += 2
            continue
        if c == '"':
            string = True
            i += 1
            continue
        if pair == '<|':
            stack.append(('|>', line))
            i += 2
            continue
        if pair == '|>':
            if not stack or stack[-1][0] != '|>':
                raise ValueError(f'Unmatched association close at line {line}')
            stack.pop()
            i += 2
            continue
        if c in '([{':
            stack.append(({'(': ')', '[': ']', '{': '}'}[c], line))
        elif c in ')]}':
            if not stack or stack[-1][0] != c:
                raise ValueError(f'Unexpected {c!r} at line {line}')
            stack.pop()
        i += 1
    if comments or string or stack:
        raise ValueError(f'Unclosed syntax: comment depth={comments}, string={string}, delimiters={stack}')
    return {'balanced': True, 'lines': line, 'characters': len(text)}


def main() -> int:
    path = ROOT / 'patches/emit_candidate_patch.py'
    spec = importlib.util.spec_from_file_location('candidate_emitter_lexical', path)
    if spec is None or spec.loader is None:
        raise RuntimeError('Cannot load the candidate-emitter module')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    sources = {
        'code/run_native.wls': (ROOT / 'code/run_native.wls').read_text(),
        'candidate regularity replacement': module.ABS_REPLACEMENT,
        'candidate prefix replacement': module.PREFIX_REPLACEMENT,
    }
    result = {
        'scope': 'Lexical balance only. Not a Wolfram parser or native execution.',
        'checks': {name: check(text) for name, text in sources.items()},
    }
    destination = ROOT / 'evidence/wl_lexical_check.json'
    destination.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
