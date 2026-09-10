(* Run: wolframscript -file Tests/RunTests.wls
   ReportSucceeded is the current documented property. The count fallback
   supports older MUnit reports where available; unknown formats fail closed. *)
report=TestReport[FileNameJoin[{DirectoryName[$InputFileName],"RealLogPowerInverse.wlt"}]];
Print[report];
props=Quiet[Check[report["Properties"],{}]];
ok=If[ListQ[props] && MemberQ[props,"ReportSucceeded"],
 TrueQ[report["ReportSucceeded"]],
 failed=Quiet[Check[report["TestsFailedCount"],$Failed]];
 succeeded=Quiet[Check[report["TestsSucceededCount"],$Failed]];
 IntegerQ[failed] && failed==0 && IntegerQ[succeeded] && succeeded>0
];
If[!TrueQ[ok],Print["Tests failed, or the report format was not recognized."]];
Exit[If[TrueQ[ok],0,1]];
