#!/usr/bin/env python3
"""Static delimiter/string/nested-comment check. This is NOT a WL parser."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]

def check(path):
    text=path.read_text(); stack=[]; i=0; comments=0; string=False
    while i<len(text):
        if comments:
            if text.startswith('(*',i): comments+=1; i+=2
            elif text.startswith('*)',i): comments-=1; i+=2
            else: i+=1
            continue
        if string:
            if text[i]=='\\': i+=2
            elif text[i]=='"': string=False; i+=1
            else: i+=1
            continue
        if text.startswith('(*',i): comments=1; i+=2; continue
        if text[i]=='"': string=True; i+=1; continue
        ch=text[i]
        if ch in '([{': stack.append((ch,i))
        elif ch in ')]}':
            assert stack, f'{path}: unexpected {ch} at {i}'
            op,j=stack.pop()
            assert '([{'.index(op)==')]}'.index(ch),f'{path}: mismatch at {j}, {i}'
        i+=1
    assert not stack and not comments and not string, f'{path}: unclosed structure'
    return {'file':str(path.relative_to(ROOT)), 'balanced':True, 'bytes':len(text.encode())}

files=sorted([*ROOT.rglob('*.wl'),*ROOT.rglob('*.wls'),*ROOT.rglob('*.wlt'),*ROOT.rglob('*.m')])
report={'scope':'Static delimiter/string/nested-comment balance only; no Wolfram parsing or execution.',
        'files':[check(p) for p in files]}
(ROOT/'validation'/'wl_delimiter_report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
