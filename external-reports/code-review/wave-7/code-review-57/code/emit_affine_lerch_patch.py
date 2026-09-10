#!/usr/bin/env python3
"""Emit a narrowly scoped candidate diff; never modify the checkout.

Integration has NOT been executed in Wolfram or Mathics. Anchor fixture tests
are not equivalent to applying this to an actual checkout. The expected commit
is checked independently of all text anchors.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path
import subprocess

PIN = '8f280847bf8fd1f6488834cadf1542867292ce10'
REL = 'src/Kernel/DirichletSpecialFunctions.wl'
START = 'dirichletLerchForward[f_'
END = '\ndirichletSpecialForwardExpansion['
OLD_VARS = '    expression, exactSource, bound, conditions, charged, metadata},'
NEW_VARS = '    expression, exactSource, bound, conditions, charged, metadata, atomRho, frontierTerm},'
OLD_RHO = '  rho = If[frontier === None, Infinity, frontier[[1]]];\n  w = 1/argument; domain = ass && argument > 0;'
NEW_RHO = '''  rho = If[frontier === None, Infinity, frontier[[1]]];
  atomRho = rho;
  frontierTerm = If[frontier === None, 0, alpha frontier[[2]] argument^(-atomRho)];
  w = 1/argument; domain = ass && argument > 0;'''
OLD_CHARGE = '''  If[charged =!= 0,
    (* A charged constant lies above the cutoff, hence below the remainder
       scale on the bound's domain a >= 1, where a^(-rho) >= 1. *)
    boundConstant = boundConstant + Abs[charged]; bound = boundConstant argument^(-rho)];'''
NEW_CHARGE = '''  If[charged =!= 0,
    (* An omitted constant has weight zero. The requested cutoff bounds
       retention, not the first omitted atom weight. Join the two grades
       before constructing either the asymptotic or quantitative bound. *)
    rho = If[atomRho === Infinity, 0, minOf[atomRho, 0]];
    boundConstant = boundConstant + Abs[charged];
    bound = boundConstant argument^(-rho);
    frontierTerm = Which[
      atomRho === Infinity || less[0, atomRho], charged,
      equal[atomRho, 0], frontierTerm + charged,
      True, frontierTerm]];'''
OLD_META = '''    "RemainderScaleExpression" -> If[frontier === None, 0, argument^(-rho)],
    "FrontierTerm" -> If[frontier === None, 0, alpha frontier[[2]] argument^(-rho)],'''
NEW_META = '''    "RemainderScaleExpression" -> If[rho === Infinity, 0, argument^(-rho)],
    "FrontierTerm" -> frontierTerm,'''
OLD_JOIN = '  If[alpha =!= 1 || beta =!= 0,\n    metadata = Join[metadata, <|"AffineCoefficients" -> {alpha, beta}, "SpecialFunctionAtom" -> LerchPhi[z, s, argument],'
NEW_JOIN = '''  If[charged =!= 0,
    metadata = Join[metadata, <|"AtomRemainderPower" -> atomRho,
      "OmittedAffineConstant" -> charged|>]];
  If[alpha =!= 1 || beta =!= 0,
    metadata = Join[metadata, <|"AffineCoefficients" -> {alpha, beta}, "SpecialFunctionAtom" -> LerchPhi[z, s, argument],'''
EDITS = ((OLD_VARS,NEW_VARS),(OLD_RHO,NEW_RHO),(OLD_CHARGE,NEW_CHARGE),
         (OLD_META,NEW_META),(OLD_JOIN,NEW_JOIN))


def patch_text(text: str) -> str:
    if text.count(START) != 1 or text.count(END) != 1:
        raise ValueError('Expected exactly one Lerch function and following dispatcher')
    start=text.index(START); end=text.index(END,start)
    body=text[start:end]
    for old,new in EDITS:
        if body.count(old) != 1:
            raise ValueError(f'Anchor mismatch; expected one occurrence: {old[:90]!r}')
        body=body.replace(old,new,1)
    return text[:start]+body+text[end:]


def main() -> None:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True,help='new .patch file; must not exist')
    a=p.parse_args()
    root=a.repo.resolve(strict=True)
    commit=subprocess.run(['git','-C',str(root),'rev-parse','HEAD'],
        text=True,capture_output=True,check=True,timeout=15).stdout.strip()
    if commit != PIN:
        raise SystemExit(f'Refusing revision {commit}; expected {PIN}. Rebase by source review, not by disabling checks.')
    original=(root/REL).read_text(encoding='utf-8')
    corrected=patch_text(original)
    diff=''.join(difflib.unified_diff(original.splitlines(keepends=True),
        corrected.splitlines(keepends=True),fromfile='a/'+REL,tofile='b/'+REL))
    out=a.output.resolve()
    if out==root/REL or root in out.parents:
        raise SystemExit('Write the candidate patch outside the reviewed checkout.')
    out.parent.mkdir(parents=True,exist_ok=True)
    with out.open('x',encoding='utf-8') as f: f.write(diff)
    print(f'Wrote candidate diff to {out}; checkout unchanged. Kernel validation still required.')

if __name__=='__main__': main()
