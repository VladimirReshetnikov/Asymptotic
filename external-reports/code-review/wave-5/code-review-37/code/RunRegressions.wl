(* UNRUN convenience driver; targets current Wolfram 15+ TestReport properties.
   wolframscript -file code/RunRegressions.wl /absolute/path/to/package.wl
   Fresh kernel only. No files are downloaded or written by this driver. *)
Module[{args = Rest[$ScriptCommandLine], package, suite, loaded, smoke,
  report, properties, results, success, required = 14},
 If[Length[args] =!= 1,
  Print["Usage: wolframscript -file RunRegressions.wl /path/to/package.wl"]; Exit[2]];
 If[MemberQ[$Packages, "AsymptoticAnalysis`"],
  Print["Refused: start a fresh kernel."]; Exit[2]];
 package = ExpandFileName[First[args]];
 suite = FileNameJoin[{DirectoryName[$InputFileName], "Regressions.wlt"}];
 If[! FileExistsQ[package] || ! FileExistsQ[suite],
  Print["Refused: package or regression file missing."]; Exit[2]];
 Print["Runtime: ", $Version]; Print["Package path: ", package];
 loaded = Check[Get[package]; True, False];
 If[! TrueQ[loaded] || ! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Print["Refused: package loading was not clean."]; Exit[2]];
 smoke = Module[{x},
  AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 2}, "Backend" -> "Package"]];
 If[! MatchQ[smoke, _AsymptoticAnalysis`GeneralizedSeries],
  Print["Refused: mandatory constructor smoke probe failed: ", InputForm[smoke]]; Exit[2]];
 report = TestReport[suite];
 Print[report];
 If[! MatchQ[report, _TestReportObject], Exit[2]];
 properties = report["Properties"];
 If[! ListQ[properties] || ! MemberQ[properties, "Results"] ||
    ! MemberQ[properties, "ReportSucceeded"],
  Print["Unsupported TestReport properties; inspect the report manually."]; Exit[2]];
 results = report["Results"];
 If[! ListQ[results] || Length[results] =!= required,
  Print["Refused: expected exactly ", required, " executed test records."]; Exit[2]];
 success = TrueQ[report["ReportSucceeded"]];
 Print["Tests: ", Length[results], "; ReportSucceeded: ", success];
 Exit[If[success, 0, 1]]
]
