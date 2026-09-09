(* Run with wolframscript -file Tests/RunTests.wl from any directory. *)
Module[{root, report, properties, ok},
 root=DirectoryName[$InputFileName];
 Print["Kernel: ",$Version];
 report=TestReport[FileNameJoin[{root,"PowerLogInverse.wlt"}]];
 Print[report];
 properties=Quiet[Check[report["Properties"],{}]];
 ok=Which[
   MemberQ[properties,"ReportSucceeded"],TrueQ[report["ReportSucceeded"]],
   MemberQ[properties,"TestsFailedCount"] && MemberQ[properties,"TestsSucceededCount"],
     TrueQ[report["TestsFailedCount"]==0 && report["TestsSucceededCount"]>0],
   True,False];
 Put[<|"Kernel"->$Version,"Report"->report,"Success"->ok|>,
   FileNameJoin[{root,"native-test-report.wl"}]];
 If[!TrueQ[ok],Print["Tests failed, or the test-report API was not recognized."]];
 Exit[If[TrueQ[ok],0,1]]
];
