#!/usr/bin/env python3
"""Lexical delimiter audit only; NOT a WL parser or runtime test."""
from pathlib import Path
import hashlib, json
ROOT=Path(__file__).resolve().parent.parent

def audit(path):
    s=path.read_text(); i=0; stack=[]; comment=0; string=False
    while i<len(s):
        if comment:
            if s[i:i+2]=='(*': comment+=1; i+=2
            elif s[i:i+2]=='*)': comment-=1; i+=2
            else: i+=1
        elif string:
            if s[i]=='\\': i+=2
            elif s[i]=='"': string=False; i+=1
            else: i+=1
        elif s[i:i+2]=='(*': comment=1; i+=2
        elif s[i]=='"': string=True; i+=1
        elif s[i:i+2]=='<|': stack.append('|>'); i+=2
        elif s[i:i+2]=='|>':
            assert stack and stack.pop()=='|>',(path,i,'association'); i+=2
        elif s[i] in '[{(':
            stack.append({'[':']','{':'}','(':')'}[s[i]]); i+=1
        elif s[i] in ']})':
            assert stack and stack.pop()==s[i],(path,i,'delimiter'); i+=1
        else: i+=1
    assert not stack and not comment and not string,(path,'unclosed construct')
    return {'file':str(path.relative_to(ROOT)),'lexical_delimiters':'balanced',
            'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

paths=sorted(list(ROOT.rglob('*.wl'))+list(ROOT.rglob('*.wlt'))+list(ROOT.rglob('*.m')))
results=[audit(p) for p in paths]
report={'scope':'Lexical audit only; not a Wolfram Language parser, compiler or evaluator.',
        'files':results}
(ROOT/'Verification'/'static-check.json').write_text(json.dumps(report,indent=2)+'\n')
print(f'Balanced lexical delimiters in {len(results)} Wolfram source/test files.')
