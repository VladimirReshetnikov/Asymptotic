"""Basic Wolfram text sanity only, NOT a native parser or syntax validator.

Understands nested (* ... *) comments and quoted strings, and checks balanced
(), [], {} outside them. Does not validate Wolfram grammar, evaluation, contexts,
options, or semantics. Python 3.10+, standard library only.
"""
from pathlib import Path
import json


def check(text: str) -> dict:
    stack: list[tuple[str, int]] = []
    pairs = {')': '(', ']': '[', '}': '{'}
    i, comment_depth, string = 0, 0, False
    while i < len(text):
        pair = text[i:i+2]
        c = text[i]
        if comment_depth:
            if pair == '(*':
                comment_depth += 1; i += 2; continue
            if pair == '*)':
                comment_depth -= 1; i += 2; continue
            i += 1; continue
        if string:
            if c == '\\':
                i += 2; continue
            if c == '"':
                string = False
            i += 1; continue
        if pair == '(*':
            comment_depth = 1; i += 2; continue
        if c == '"':
            string = True
        elif c in '([{':
            stack.append((c,i))
        elif c in ')]}':
            if not stack or stack[-1][0] != pairs[c]:
                return dict(ok=False, offset=i, error='mismatched closing delimiter')
            stack.pop()
        i += 1
    if string or comment_depth or stack:
        return dict(ok=False, error='unclosed string, comment, or delimiter',
                    string=string, comment_depth=comment_depth, stack=stack)
    return dict(ok=True)


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    paths = sorted(p for p in root.rglob('*') if p.suffix in {'.wl','.wls','.wlt'})
    rows = [dict(path=str(p.relative_to(root)), **check(p.read_text())) for p in paths]
    result = dict(scope='Text sanity only; no native parse/compile/evaluation', files=rows)
    (root/'evidence'/'wolfram_text_checks.json').write_text(json.dumps(result,indent=2)+'\n')
    for row in rows:
        print(('OK  ' if row['ok'] else 'FAIL'), row['path'])
    if not paths or not all(row['ok'] for row in rows):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
