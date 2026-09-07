#!/usr/bin/env python3
"""Static delimiter/string/comment checks only. This is NOT a WL evaluator."""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]

def check(path: Path) -> dict:
    s=path.read_text(); stack=[]; i=0; comment_depth=0; string=False
    pairs={')':'(',']':'[','}':'{'}
    while i<len(s):
        if comment_depth:
            if s.startswith('(*',i):comment_depth+=1;i+=2;continue
            if s.startswith('*)',i):comment_depth-=1;i+=2;continue
            i+=1;continue
        if string:
            if s[i]=='\\':i+=2;continue
            if s[i]=='"':string=False
            i+=1;continue
        if s.startswith('(*',i):comment_depth=1;i+=2;continue
        if s[i]=='"':string=True;i+=1;continue
        if s[i] in '([{':stack.append((s[i],i))
        elif s[i] in ')]}':
            assert stack and stack[-1][0]==pairs[s[i]], (str(path),i,s[max(0,i-30):i+30])
            stack.pop()
        i+=1
    assert not stack and not comment_depth and not string,str(path)
    return {'file':str(path.relative_to(ROOT)),'balanced_delimiters':True,
            'closed_strings_and_comments':True,'lines':len(s.splitlines())}

if __name__=='__main__':
    paths=[p for p in ROOT.rglob('*') if p.suffix in ('.wl','.wlt','.wls','.m')]
    report={'scope':'Static lexical checks only; no native evaluation',
            'files':[check(p) for p in sorted(paths)]}
    (ROOT/'validation/static_checks.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
