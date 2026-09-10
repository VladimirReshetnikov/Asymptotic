#!/usr/bin/env python3
"""Delimiter/string/nested-comment check ONLY. Not native WL validation."""
from pathlib import Path
import importlib.util
import json

ROOT=Path(__file__).resolve().parents[1]

def check(text: str) -> dict:
    stack=[]; i=0; comments=0; quoted=False
    while i<len(text):
        pair=text[i:i+2]; c=text[i]
        if comments:
            if pair=='(*': comments+=1; i+=2; continue
            if pair=='*)': comments-=1; i+=2; continue
            i+=1; continue
        if quoted:
            if c=='\\':
                if i+1>=len(text): raise ValueError('unterminated string escape')
                i+=2; continue
            if c=='"': quoted=False
            i+=1; continue
        if pair=='(*': comments=1; i+=2; continue
        if c=='"': quoted=True; i+=1; continue
        if pair=='<|': stack.append(('<|',i)); i+=2; continue
        if pair=='|>':
            if not stack or stack.pop()[0]!='<|': raise ValueError(f'bad association close at {i}')
            i+=2; continue
        if c in '[{(': stack.append((c,i))
        elif c in ']})':
            expected={']':'[','}':'{',')':'('}[c]
            if not stack or stack.pop()[0]!=expected: raise ValueError(f'bad close at {i}')
        i+=1
    if comments or quoted or stack: raise ValueError('unterminated construct')
    return {'balanced':True,'native_semantics_checked':False}

def main():
    results={str(p.relative_to(ROOT)):check(p.read_text())
             for p in [ROOT/'code/native_probe.wl',ROOT/'code/desired_regressions.wlt']}
    spec=importlib.util.spec_from_file_location('audit_candidates',ROOT/'patches/emit_candidate_patch.py')
    module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    for key,(_,_,new) in module.EDITS.items(): results['candidate_fragment:'+key]=check(new)
    out={'check':'lexical delimiter/string/comment balance only','results':results,
         'wolfram_execution':False,'mathics_execution':False}
    (ROOT/'evidence/wl-lexical-check.json').write_text(json.dumps(out,indent=2)+'\n')
    print(json.dumps(out,indent=2))

if __name__=='__main__': main()
