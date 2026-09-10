(* UNRUN baseline/candidate characterization. Every printed result is produced
   only by a future actual execution of this script, not predicted transcripts.
   wolframscript -file code/Characterize.wl /absolute/path/to/package.wl
   No network or output files. Messages are intentionally left visible. *)
Module[{args = Rest[$ScriptCommandLine], package, loaded},
 If[Length[args] =!= 1 || MemberQ[$Packages, "AsymptoticAnalysis`"],
  Print["Supply one package path in a fresh kernel."]; Exit[2]];
 package = ExpandFileName[First[args]];
 If[! FileExistsQ[package], Print["Package file missing."]; Exit[2]];
 Print["$Version = ", $Version]; Print["Package = ", package];
 loaded = Check[Get[package]; True, False];
 If[! TrueQ[loaded] || ! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Print["Package load failed or emitted a message."]; Exit[2]];
];

ClearAll[auditShow]; SetAttributes[auditShow, HoldRest];
auditShow[label_, expression_] := Module[{result},
 Print["\nCASE: ", label];
 result = TimeConstrained[expression, 120, $Aborted];
 Print["Result: ", InputForm[result]];
 If[MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries],
  Print["Normal: ", InputForm[Normal[result]]];
  Print["Selected metadata: ", InputForm[Association@Table[
    key -> result[key], {key, {"Kind", "Scale", "Cutoff", "Remainder", "Exact",
      "Assumptions", "TargetDomain"}}]]]];
 result];

auditShow["F01 direct constructor", Module[{a, x},
 AsymptoticAnalysis`AsymptoticExpansion[
  Abs[1 + a x] + Abs[1 - a x] - 2, {x, 0, 4},
  Assumptions -> a^2 == -1, "Backend" -> "Package"]]];
auditShow["F01 observable", Module[{a, x, z, s},
 s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4},
  Assumptions -> a^2 == -1, "Backend" -> "Package"];
 AsymptoticAnalysis`SeriesObservable[s, Abs[1 + a z] + Abs[1 - a z] - 2,
  z, "Cutoff" -> 4]]];
auditShow["F01 private helper", Module[{ell},
 AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fwdAbs[
  {{{0, 1}, {1, I}}, Infinity, 0}, ell, True]]]];
auditShow["F02 parameter includes zero", Module[{a, x, s},
 s = AsymptoticAnalysis`AsymptoticExpansion[a x, {x, 0, 3},
  Assumptions -> Element[a, Reals], "Backend" -> "Package"];
 AsymptoticAnalysis`SeriesPower[s, 0]]];
auditShow["F02 unsigned nonzero control", Module[{a, x, s},
 s = AsymptoticAnalysis`AsymptoticExpansion[a x, {x, 0, 3},
  Assumptions -> (Element[a, Reals] && a != 0), "Backend" -> "Package"];
 AsymptoticAnalysis`SeriesPower[s, 0]]];
auditShow["F03 Gamma cutoff zero", Module[{x, y, s},
 s = AsymptoticAnalysis`AsymptoticInverse[Gamma[x], {x, Infinity}, {y, 1}];
 AsymptoticAnalysis`SeriesPower[s, 0, "Cutoff" -> 0]]];
auditShow["F03 Gamma cutoff two", Module[{x, y, s},
 s = AsymptoticAnalysis`AsymptoticInverse[Gamma[x], {x, Infinity}, {y, 1}];
 AsymptoticAnalysis`SeriesPower[s, 0, "Cutoff" -> 2]]];
auditShow["F03 Barnes cutoff zero", Module[{x, y, s},
 s = AsymptoticAnalysis`AsymptoticInverse[System`BarnesG[x], {x, Infinity}, {y, 1}];
 AsymptoticAnalysis`SeriesPower[s, 0, "Cutoff" -> 0]]];
