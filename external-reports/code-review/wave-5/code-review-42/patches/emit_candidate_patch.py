#!/usr/bin/env python3
"""Emit, never apply, two conservative candidate edits to SeriesOperations.wl.

Native-unverified. Requires the audited commit by default and unique exact
source anchors. Rebuild the standalone through the upstream builder after
reviewing/applying the diff. This tool does not modify the checkout.
"""
from __future__ import annotations
import argparse, difflib, subprocess, sys
from pathlib import Path

PIN='651f2029d0b2cd4da9e4dfdf1f4275a124d23b99'
REL='src/Kernel/SeriesOperations.wl'
ABS_ANCHOR='''  j = seriesJetApply[body, x, d["Jet"], d, h, limit];
  result = seriesMake[Join[d, <|"Jet" -> j|>], {"Observable", {s}, e, x}, h];'''
ABS_REPLACEMENT='''  j = seriesJetApply[body, x, d["Jet"], d, h, limit];
  (* Conservative regularity policy: a Lipschitz absolute-value transport
     does not prove classical differentiability of an unknown remainder.
     A later sign-aware implementation can preserve proved smooth cases. *)
  If[! FreeQ[body, _Abs] && j[[2]] =!= Infinity,
    d = Join[d, <|"RemainderDerivativeOrder" -> 0|>]];
  result = seriesMake[Join[d, <|"Jet" -> j|>], {"Observable", {s}, e, x}, h];'''
PREFIX_ANCHOR='''  removed = Select[before, ! MemberQ[after, #] &];
  If[! SubsetQ[before, after], Return[result, Module]];'''
PREFIX_REPLACEMENT='''  (* Trimming a canonical jet normally retains an identical prefix.
     Prove that cheap case structurally; preserve the old fallback otherwise. *)
  If[Length[after] <= Length[before] &&
      Take[before, Length[after]] === after,
    removed = Drop[before, Length[after]],
    removed = Select[before, ! MemberQ[after, #] &];
    If[! SubsetQ[before, after], Return[result, Module]]];'''

def transform(text: str, which: str='both') -> str:
    edits=[]
    if which in ('both','regularity'): edits.append((ABS_ANCHOR,ABS_REPLACEMENT))
    if which in ('both','prefix'): edits.append((PREFIX_ANCHOR,PREFIX_REPLACEMENT))
    if not edits: raise ValueError('unknown edit selection')
    for old,new in edits:
        count=text.count(old)
        if count!=1: raise ValueError(f'Expected exactly one source anchor, found {count}: {old.splitlines()[0]}')
        text=text.replace(old,new,1)
    return text

def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('repository',type=Path)
    p.add_argument('--which',choices=['both','regularity','prefix'],default='both')
    p.add_argument('--skip-commit-check',action='store_true',
                   help='Explicitly allow a source tree without matching Git HEAD; anchors still required')
    a=p.parse_args(); root=a.repository.resolve()
    if not a.skip_commit_check:
        try:
            commit=subprocess.run(['git','-C',str(root),'rev-parse','HEAD'],
                                  check=True,text=True,capture_output=True,timeout=10).stdout.strip()
        except (OSError,subprocess.SubprocessError) as exc:
            p.error(f'Cannot establish Git HEAD: {exc}')
        if commit!=PIN: p.error(f'HEAD is {commit}, not audited commit {PIN}')
    try:
        source=(root/REL).read_text(encoding='utf-8')
        changed=transform(source,a.which)
    except (OSError,UnicodeError,ValueError) as exc:
        p.error(str(exc))
    diff=''.join(difflib.unified_diff(source.splitlines(True),changed.splitlines(True),
                                    fromfile='a/'+REL,tofile='b/'+REL))
    sys.stdout.write(diff)
    return 0
if __name__=='__main__': raise SystemExit(main())
