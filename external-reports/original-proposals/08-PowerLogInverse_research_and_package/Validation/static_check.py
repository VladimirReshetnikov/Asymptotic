#!/usr/bin/env python3
"""Lexical delimiter audit for WL files (NOT a Wolfram parser/executor)."""
from pathlib import Path
import json

def audit(path):
    s=path.read_text(); stack=[]; i=0; comment=0; string=False; line=1
    pairs={']':'[','}':'{',')':'(','|>':'<|'}
    while i<len(s):
        ch=s[i]; nxt=s[i:i+2]
        if ch=='\n':line+=1
        if comment:
            if nxt=='(*':comment+=1;i+=2;continue
            if nxt=='*)':comment-=1;i+=2;continue
            i+=1;continue
        if string:
            if ch=='\\':i+=2;continue
            if ch=='"':string=False
            i+=1;continue
        if nxt=='(*':comment=1;i+=2;continue
        if ch=='"':string=True;i+=1;continue
        if nxt=='<|':stack.append(('<|',line));i+=2;continue
        if nxt=='|>':
            assert stack and stack[-1][0]=='<|',(path,line,'bad association closer',stack[-4:])
            stack.pop();i+=2;continue
        if ch in '[{(':stack.append((ch,line))
        elif ch in ']})':
            assert stack and stack[-1][0]==pairs[ch],(path,line,'bad closer',stack[-4:])
            stack.pop()
        i+=1
    assert not stack and not string and not comment,(path,stack,string,comment)
    return {'file':str(path.relative_to(path.parents[1])),'balanced':True,
            'native_parser_executed':False}

def main():
    root=Path(__file__).resolve().parents[1]
    files=sorted([*root.glob('Kernel/*.wl'),*root.glob('Kernel/*.m'),
                  *root.glob('Tests/*.wlt'),*root.glob('Tests/*.wls'),
                  *root.glob('Examples/*.wls')])
    results=[audit(f) for f in files]
    (root/'Validation/static-results.json').write_text(json.dumps(results,indent=2)+'\n')
    print(f'{len(results)} WL files passed lexical delimiter checks (not native execution).')
    print('Native test definitions:',(root/'Tests/PowerLogInverse.wlt').read_text().count('VerificationTest['))

if __name__=='__main__':main()
