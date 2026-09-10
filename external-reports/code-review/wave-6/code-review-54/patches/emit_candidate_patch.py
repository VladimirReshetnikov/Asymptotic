#!/usr/bin/env python3
"""Emit narrow, UNVALIDATED WL candidate diffs without modifying a checkout.

Usage: python patches/emit_candidate_patch.py /path/to/Asymptotic [--which all]
Requires the reviewed HEAD unless --skip-commit-check is deliberately supplied.
Every old anchor must occur exactly once. This is not an installer or acceptance
runner. Rebuild the generated standalone package after separately applying edits.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path
import subprocess
import sys

PIN = '8cee870994f506b501bae3ea6bd4a3a7edb895c1'

POWER_ANCHOR = '  If[n < 0, base = certReciprocal[base, ctx]];'
POWER_NEW = '''  (* A real odd power is increasing, even across zero. Evaluate its
     endpoints with the existing bounded directed arithmetic, rather than
     multiplying independent copies of the whole zero-crossing interval. *)
  If[n > 1 && OddQ[n] && a[[1]] < 0 < a[[2]],
    Return[{certIntegerPower[{a[[1]], a[[1]]}, n, ctx][[1]],
      certIntegerPower[{a[[2]], a[[2]]}, n, ctx][[2]]}, Module]];
''' + POWER_ANCHOR

ASSUMPTION_ANCHOR = '  heads = Position[held, System`Element, {0, Infinity}, Heads -> True];'
ASSUMPTION_NEW = '''  (* Replace only actual two-argument membership application heads.
     A bare Element symbol can be data in an option program. This does not
     claim full semantic preservation of arbitrary quoted membership code. *)
  heads = (Append[#, 0] &) /@ Position[held,
    HoldPattern[System`Element[_, _]], {0, Infinity}, Heads -> False];'''

LOG_ANCHOR = '''mathicsNumericalSplitLog[factors_List] :=
  If[And @@ (TrueQ[N[#] > 0] & /@ factors), Total[Log /@ factors], Log[Times @@ factors]];'''
LOG_NEW = '''(* Exact positive grammar for the numerical recovery only. Unrecognized
   factors stay unsplit. A machine-precision sign is not a branch proof. *)
ClearAll[mathicsNumericalPositiveFactorQ];
mathicsNumericalPositiveFactorQ[e_] := Which[
  IntegerQ[e] || Head[e] === Rational, TrueQ[e > 0],
  e === Pi || e === E || e === System`Glaisher, True,
  Head[e] === Times, And @@ (mathicsNumericalPositiveFactorQ /@ List @@ e),
  Head[e] === Power &&
    (IntegerQ[e[[2]]] || Head[e[[2]]] === Rational),
      mathicsNumericalPositiveFactorQ[e[[1]]],
  True, False];
mathicsNumericalSplitLog[factors_List] :=
  If[And @@ (mathicsNumericalPositiveFactorQ /@ factors),
    Total[Log /@ factors], Log[Times @@ factors]];'''

LABEL_ANCHOR = '''"x = SourceOffset + SourceSide u; LocalRoot and LocalApproximation are values of u for Power 1 and of u^Power otherwise."'''
LABEL_NEW = '''"x = SourceOffset + SourceSide u. LocalRoot is always the positive source displacement u. LocalApproximation approximates u for Power 1, and (SourceSide u)^Power otherwise."'''

EDITS = {
    'power': ('src/Kernel/InverseCertificates.wl', POWER_ANCHOR, POWER_NEW),
    'assumptions': ('src/Kernel/MathicsInputAssumptions.wl', ASSUMPTION_ANCHOR, ASSUMPTION_NEW),
    'log': ('src/Kernel/MathicsNumerical.wl', LOG_ANCHOR, LOG_NEW),
    'label': ('src/Kernel/NumericalInverseChecks.wl', LABEL_ANCHOR, LABEL_NEW),
}


def transform(text: str, old: str, new: str) -> str:
    count = text.count(old)
    if count != 1:
        raise ValueError(f'expected exactly one old anchor; found {count}')
    return text.replace(old, new, 1)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('checkout', type=Path)
    p.add_argument('--which', choices=['all', *EDITS], default='all')
    p.add_argument('--skip-commit-check', action='store_true')
    args = p.parse_args(argv)
    root = args.checkout.resolve()
    try:
        if not args.skip_commit_check:
            head = subprocess.run(['git','-C',str(root),'rev-parse','HEAD'],
                                  check=True,capture_output=True,text=True).stdout.strip()
            if head != PIN:
                raise ValueError(f'HEAD is {head}, expected {PIN}')
        chosen = list(EDITS) if args.which == 'all' else [args.which]
        output = []
        for key in chosen:
            relative, old, new = EDITS[key]
            text = (root/relative).read_text(encoding='utf-8')
            revised = transform(text,old,new)
            output.extend(difflib.unified_diff(text.splitlines(True), revised.splitlines(True),
                          fromfile='a/'+relative, tofile='b/'+relative))
        # Do not print a partial diff if a later file failed validation.
        sys.stdout.writelines(output)
        return 0
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f'No diff emitted: {exc}',file=sys.stderr)
        return 2

if __name__ == '__main__':
    raise SystemExit(main())
