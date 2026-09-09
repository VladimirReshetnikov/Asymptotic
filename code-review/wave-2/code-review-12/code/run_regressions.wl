(* wolframscript -file run_regressions.wl PACKAGE [REPORT.json] *)
Module[{args = Rest[$ScriptCommandLine], path, report, summary, destination, counts},
 If[Length[args] < 1 || Length[args] > 2, Print["Supply PACKAGE and optional REPORT.json."]; Exit[2]];
 path = ExpandFileName[args[[1]]];
 destination = If[Length[args] == 2, args[[2]], "regression-summary.json"];
 If[!FileExistsQ[path] || Check[Get[path]; True, False] =!= True, Exit[3]];
 report = TimeConstrained[TestReport[FileNameJoin[{DirectoryName[$InputFileName],
   "regressions.wlt"}]], 240, $TimedOut];
 If[Head[report] =!= TestReportObject, Print["No complete TestReportObject."]; Exit[4]];
 counts = Quiet[Check[{report["TestsSucceededCount"], report["TestsFailedCount"]}, $Failed]];
 If[!MatchQ[counts, {_Integer, _Integer}] || Total[counts] =!= 8,
   Print["Unexpected or empty test count."]; Exit[5]];
 summary = <|"Kernel" -> $Version, "Package" -> path, "ExpectedTests" -> 8,
   "Succeeded" -> counts[[1]], "Failed" -> counts[[2]]|>;
 If[Check[Export[destination, summary, "RawJSON"]; True, False] =!= True, Exit[6]];
 Print[summary]; Exit[If[counts[[2]] == 0, 0, 1]];
];
