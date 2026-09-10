(* UNEXECUTED integration probes, supplied for a fresh native Wolfram kernel.
   Usage: wolframscript -file native_probes.wl /absolute/path/AsymptoticAnalysis.wl
   Output is JSON with InputForm strings; a result is an observation, not a
   combined acceptance count. The module also loads the companion helpers.
   Do not relabel this file as a successful run without executing it. *)
Module[{args = Rest[$ScriptCommandLine], package, loaded, ownDirectory, records = {},
  observe, x, y, s, m, p, value},
 If[Length[args] =!= 1 || ! FileExistsQ[First[args]],
  Print["Supply exactly one existing local package path."]; Exit[2]];
 package = ExpandFileName[First[args]];
 loaded = Check[Get[package], $Failed];
 If[loaded === $Failed || Names["AsymptoticAnalysis`AsymptoticInverse"] === {},
  Print["Package load failed."]; Exit[2]];
 ownDirectory = DirectoryName[$InputFileName];
 Get[FileNameJoin[{ownDirectory, "ReviewDeltas.wl"}]];
 SetAttributes[observe, HoldRest];
 observe[id_, body_] := Module[{out},
  out = TimeConstrained[Check[body, $Failed], 30, $Aborted];
  AppendTo[records, <|"ID" -> id, "ResultInputForm" -> ToString[out, InputForm],
    "Aborted" -> (out === $Aborted), "FailedEvaluation" -> (out === $Failed)|>]];
 observe["F01-left-source", Module[{ss, cc},
   ss = AsymptoticAnalysis`AsymptoticInverse[x, {x, 0}, {y, 2}, Direction -> "FromBelow"];
   cc = AsymptoticAnalysis`InverseExpansionCoefficient[ss, {}];
   {Normal[ss], cc, AsymptoticReview`OrientedInverseContribution[ss, {}]}]];
 observe["F01-negative-infinity", Module[{ss},
   ss = AsymptoticAnalysis`AsymptoticInverse[x, {x, -Infinity}, {y, 2}];
   {Normal[ss], AsymptoticAnalysis`InverseExpansionCoefficient[ss, {}],
     AsymptoticReview`OrientedInverseContribution[ss, {}]}]];
 observe["F02-pole-model", Module[{mm},
   mm = AsymptoticAnalysis`PowerLogModel[1/x, {x, 0}];
   {mm, AsymptoticReview`DescribeModelLimit[mm]}]];
 observe["F02-regular-model-control", Module[{mm},
   mm = AsymptoticAnalysis`PowerLogModel[7+x, {x, 0}];
   {mm, AsymptoticReview`DescribeModelLimit[mm]}]];
 observe["F03-free-source-in-core", {
   AsymptoticAnalysis`PerturbativeInverse[x+y, x^2, {x,y}, 1],
   AsymptoticReview`PerturbativeInverseChecked[x+y, x^2, {x,y}, 1]}];
 observe["F03-valid-control", AsymptoticReview`PerturbativeInverseChecked[y, x^2, {x,y}, 3]];
 observe["E01-global-helper", AsymptoticAnalysis`Private`inverseBranchGlobalMonotonicity[
   x-2 x^3/3+x^5/5, x, True, True]];
 observe["E01-strict-slope-control", AsymptoticAnalysis`Private`inverseBranchGlobalMonotonicity[
   x+x^3, x, True, True]];
 Print[ExportString[<|"Scope" -> "Fresh-kernel observations; inspect each result independently",
   "Kernel" -> $Version, "PackagePath" -> package,
   "ExpectedReviewCommit" -> "8e859961d7d37f008b826f3a8cad406460271614",
   "PackageCommitIndependentlyVerified" -> False,
   "Records" -> records|>, "RawJSON"]]
];
