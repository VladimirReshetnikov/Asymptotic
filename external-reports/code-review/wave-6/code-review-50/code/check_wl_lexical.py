#!/usr/bin/env python3
"""Limited WL delimiter/string/comment check, NOT a parser or evaluator."""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def check(text: str) -> dict:
    stack: list[tuple[str,int]] = []
    comment = 0
    string = False
    escaped = False
    pairs = {')':'(', ']':'[', '}':'{'}
    line = 1
    i = 0
    while i < len(text):
        c = text[i]; pair = text[i:i+2]
        if c == '\n': line += 1
        if comment:
            if pair == '(*': comment += 1; i += 2; continue
            if pair == '*)': comment -= 1; i += 2; continue
        elif string:
            if escaped: escaped = False
            elif c == '\\': escaped = True
            elif c == '"': string = False
        else:
            if pair == '(*': comment = 1; i += 2; continue
            if c == '"': string = True
            elif c in '([{': stack.append((c,line))
            elif c in ')]}':
                if not stack or stack[-1][0] != pairs[c]:
                    return {'balanced':False,'reason':f'unmatched {c} at line {line}'}
                stack.pop()
        i += 1
    return {'balanced':not (stack or comment or string), 'open_delimiters':stack,
            'comment_depth':comment,'open_string':string}

if __name__ == '__main__':
    files = sorted(list((ROOT/'code').glob('*.wl'))+list((ROOT/'code').glob('*.wlt')))
    results = {str(p.relative_to(ROOT)):check(p.read_text(encoding='utf-8')) for p in files}
    record = {'scope':'Balanced delimiters, nested comments and strings only. NOT WL syntax validation or execution.',
              'files':results,'success':all(v['balanced'] for v in results.values())}
    (ROOT/'evidence'/'wl-lexical-check.json').write_text(json.dumps(record,indent=2)+'\n')
    print(json.dumps(record,indent=2))
    raise SystemExit(0 if record['success'] else 1)
