#!/usr/bin/env python3
"""Stage source-anchored audit candidates in a NEW directory; never edit input.

Native Wolfram execution of these changes was unavailable during this audit.
The exact anchors fail closed when a different revision changes the text.
Do not interpret fixture tests as package integration validation.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import shutil
import subprocess

COMMIT = '6687962f3c858a4f93623cfc496f33e35c6763d4'
NATIVE = Path('src/Kernel/NativeCompatibility.wl')
OPS = Path('src/Kernel/SeriesOperations.wl')

KEY_HELPERS = '''(* Audit candidate: option identity follows OptionValue, without evaluating keys. *)
nativeOptionName[HoldComplete[name_String]] := name;
nativeOptionName[HoldComplete[name_Symbol]] := SymbolName[Unevaluated[name]];
nativeOptionName[_] := Missing["InvalidOptionName"];
nativeCanonicalOptionKey[key_HoldComplete] := Module[{name, candidates},
  name = nativeOptionName[key];
  candidates = Select[HoldComplete /@ (First /@ Options[AsymptoticExpansion]),
    nativeOptionName[#] === name &];
  If[candidates === {}, key, First[candidates]]];

'''
EXACT_HELPER = '''(* Audit candidate: exact derived values need no information from an ancestor.
   Only a request retaining every known block takes this path; lower-cutoff
   retargeting, native objects and nonordinary representations are unchanged. *)
exactDerivedRefinementNoOp[s : GeneralizedSeries[a_Association], h_, limit_] := Module[
  {d, j, stats},
  If[Lookup[a, "Kind", None] =!= "Derived" ||
     ! AssociationQ[Lookup[a, "SeriesRepresentation", None]], Return[$Failed, Module]];
  d = seriesData[s, limit]; j = d["Jet"];
  If[j[[2]] =!= Infinity ||
     (j[[1]] =!= {} && ! less[Last[j[[1]]][[1]], h]), Return[$Failed, Module]];
  stats = <|"Strategy" -> "ExactValueNoOp", "RequestedCutoff" -> h,
    "SourceCutoff" -> Lookup[a, "Cutoff", Missing["NotAvailable"]],
    "AchievedPrecision" -> Infinity, "SourceReplayRequired" -> False,
    "ModelReused" -> True, "ReusedBlocks" -> Length[j[[1]]],
    "NewCoefficientEvaluations" -> 0,
    "Evidence" -> "Existing exact ordinary representation; all retained blocks remain below the requested cutoff."|>;
  GeneralizedSeries[Join[a, <|"Cutoff" -> h,
    "SeriesRepresentation" -> Join[d, <|"Cutoff" -> h|>],
    "RefinementStatistics" -> stats,
    "RefinementHistory" -> Append[Lookup[a, "RefinementHistory", {}], stats]|>]]];

'''

PATCHES: list[tuple[Path,str,str,str]] = [
(NATIVE, 'N01-default',
 '  backend = If[values === {}, Automatic, ReleaseHold[First[values]]];',
 '  backend = If[values === {}, OptionValue[AsymptoticExpansion, {}, "Backend"], ReleaseHold[First[values]]];'),
(NATIVE, 'N02-function-role',
 '''  ! FreeQ[First[nativeHeldArguments[original]], _InverseFunction | _Function | _ConditionalExpression | _GeneralizedSeries | _PowerLogRemainder] ||
  ! FreeQ[First[nativeHeldArguments[request]], _InverseFunction | _Function | _ConditionalExpression | _forwardCallable | _GeneralizedSeries | _PowerLogRemainder] ||''',
 '''  MatchQ[First[nativeHeldArguments[original]], HoldComplete[_Function]] ||
  MatchQ[First[nativeHeldArguments[request]], HoldComplete[_Function | _forwardCallable]] ||
  ! FreeQ[First[nativeHeldArguments[original]], _InverseFunction | _ConditionalExpression | _GeneralizedSeries | _PowerLogRemainder] ||
  ! FreeQ[First[nativeHeldArguments[request]], _InverseFunction | _ConditionalExpression | _GeneralizedSeries | _PowerLogRemainder] ||'''),
(NATIVE, 'N03-name-helpers',
 '(* Only option containers are traversed.',
 KEY_HELPERS+'(* Only option containers are traversed.'),
(NATIVE, 'N03-selector',
 'nativeSelectorValues[HoldComplete[(Rule | RuleDelayed)["Backend", value_]]] := {HoldComplete[value]};',
 '''nativeSelectorValues[HoldComplete[(Rule | RuleDelayed)[key_, value_]]] /;
  nativeOptionName[HoldComplete[key]] === "Backend" := {HoldComplete[value]};'''),
(NATIVE, 'N03-strip',
 'nativeStripSelector[HoldComplete[(Rule | RuleDelayed)["Backend", _]]] := HoldComplete[Sequence[]];',
 '''nativeStripSelector[HoldComplete[(Rule | RuleDelayed)[key_, _]]] /;
  nativeOptionName[HoldComplete[key]] === "Backend" := HoldComplete[Sequence[]];'''),
(NATIVE, 'N03-specification',
 '  ! MemberQ[First /@ Options[AsymptoticExpansion], Unevaluated[key]];',
 '''  ! MemberQ[nativeOptionName /@ (HoldComplete /@ (First /@ Options[AsymptoticExpansion])),
    nativeOptionName[HoldComplete[key]]];'''),
(NATIVE, 'N03-package-contract',
 'nativePackageOption[HoldComplete[(Rule | RuleDelayed)[key : ("MaxTerms" | "InverseFunctionBranches"), _]]] := {key};',
 '''nativePackageOption[HoldComplete[(Rule | RuleDelayed)[key_, _]]] /;
  MemberQ[{"MaxTerms", "InverseFunctionBranches"}, nativeOptionName[HoldComplete[key]]] :=
    {nativeOptionName[HoldComplete[key]]};'''),
(NATIVE, 'N03-request-keys',
 'nativeOptionKeys[HoldComplete[(Rule | RuleDelayed)[key_, _]]] := {HoldComplete[key]};',
 'nativeOptionKeys[HoldComplete[(Rule | RuleDelayed)[key_, _]]] := {nativeCanonicalOptionKey[HoldComplete[key]]};'),
(OPS, 'D01-native-order',
 '''      (* The completed observable is checked by seriesMake after collection;
         separate analytic summands can have cancelling imaginary parts. *)''',
 '''      If[! less[n, native[[5]]/native[[6]]],
        fail["InsufficientNativeOrder", "The observable Taylor probe does not cover the coefficient order required by composition.",
          <|"RequiredCoefficientOrder" -> n,
            "NativeEndpoint" -> native[[5]]/native[[6]],
            "NativeResult" -> native|>]];
      (* The completed observable is checked by seriesMake after collection;
         separate analytic summands can have cancelling imaginary parts. *)'''),
(OPS, 'D02-exact-helper',
 'AsymptoticAnalysis`SeriesRefine[s : GeneralizedSeries[a_Association], h_, opts : OptionsPattern[]] := catch[seriesRefinementResult[Module[',
 EXACT_HELPER+'AsymptoticAnalysis`SeriesRefine[s : GeneralizedSeries[a_Association], h_, opts : OptionsPattern[]] := catch[seriesRefinementResult[Module['),
(OPS, 'D02-exact-entry',
 '  If[! exactRealQ[h], fail["InvalidCutoff", "The refinement cutoff must be an exact real number."]];',
 '''  If[! exactRealQ[h], fail["InvalidCutoff", "The refinement cutoff must be an exact real number."]];
  r = exactDerivedRefinementNoOp[s, h, limit];
  If[r =!= $Failed, Return[r, Module]];'''),
]

OLD_README = '''`AsymptoticExpand` is a held alias of `AsymptoticExpansion`. Both currently use
the package engines under `"Backend" -> Automatic`; `"Package"` explicitly
selects that same path. Explicit `"Series"` and `"Asymptotic"` modes are
implemented with [130 passing focused checks](validation/native-compatibility-tests.json)
across eight selected files, with no failures. The
[compatibility plan](docs/development/NATIVE_COMPATIBILITY.md) tracks required
automatic fallback and remaining coverage evidence. Existing analytic
special-function tests do not validate this new native result contract.'''
NEW_README = '''`AsymptoticExpand` is a held alias of `AsymptoticExpansion`. `Automatic`
retains successful package expansions and routes selected native input forms,
options and representation failures to a native backend. `"Package"` disables
that delegation and requires the real analytic engines. Explicit `"Series"`
and `"Asymptotic"` select native order and result conventions.
The [compatibility plan](docs/development/NATIVE_COMPATIBILITY.md) records the
remaining full-coverage obligations and the exact snapshots and scope of
focused validation. Historical test totals are not validation of subsequent
renames or of the candidate changes supplied with this audit.'''
PATCHES.append((Path('README.md'),'N04-readme',OLD_README,NEW_README))


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise ValueError(f'{label}: expected one source anchor, found {count}; no edit made')
    return text.replace(old,new,1)


def patch_texts(texts: dict[Path,str]) -> dict[Path,str]:
    out = dict(texts)
    for path,label,old,new in PATCHES:
        if path not in out:
            raise ValueError(f'{label}: missing file {path}')
        out[path] = replace_once(out[path],old,new,label)
    return out


def main() -> None:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True)
    p.add_argument('--no-git-check',action='store_true',help='For a separately verified archive; exact text anchors still required.')
    a=p.parse_args(); repo=a.repo.resolve(); out=a.out.resolve()
    if out==repo or repo in out.parents or out in repo.parents:
        p.error('output and input must be separate, nonnested directories')
    if out.exists(): p.error('output must not already exist')
    if not a.no_git_check:
        revision=subprocess.run(['git','-C',str(repo),'rev-parse','HEAD'],check=True,capture_output=True,text=True).stdout.strip()
        if revision!=COMMIT: p.error(f'expected snapshot {COMMIT}, found {revision}')
    paths=sorted({item[0] for item in PATCHES})
    texts={path:(repo/path).read_text(encoding='utf-8') for path in paths}
    # Validate ALL anchors before creating an output directory.
    changed=patch_texts(texts)
    shutil.copytree(repo/'src'/'Kernel',out/'src'/'Kernel')
    for path,text in changed.items():
        (out/path).parent.mkdir(parents=True,exist_ok=True)
        (out/path).write_text(text,encoding='utf-8')
    (out/'PATCH_STATUS.md').write_text(
        '# Candidate audit staging\n\nNative validation has NOT been performed. '
        'Load src/Kernel/AsymptoticAnalysis.wl for focused checks. '
        'The standalone distribution is intentionally not copied or regenerated. '
        'Do not publish this directory as an accepted release.\n',encoding='utf-8')
    print(f'Staged {len(PATCHES)} anchored changes in {len(paths)} files at {out}')

if __name__=='__main__': main()
