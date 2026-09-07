(* Run from a Wolfram kernel, e.g. wolframscript -file Tests/run-tests.wl. *)
root = FileNameJoin[{DirectoryName[$InputFileName], ".."}];
Get[FileNameJoin[{root, "Kernel", "RealInverseSeries.wl"}]];
report = TestReport[FileNameJoin[{root, "Tests", "RealInverseSeries.wlt"}]];
Print[$Version];
Print[report];
properties = report["Properties"];
(* Current kernels expose ReportSucceeded; earlier MUnit reports expose counts. *)
succeeded = Which[
 MemberQ[properties, "ReportSucceeded"], TrueQ[report["ReportSucceeded"]],
 MemberQ[properties, "TestsFailedCount"],
  TrueQ[report["TestsFailedCount"] == 0] &&
   TrueQ[report["TestsSucceededCount"] == 33],
 True, False
];
Print["Native suite succeeded: ", succeeded];
Export[FileNameJoin[{root, "verification", "native-test-report.txt"}],
 ToString[<|"KernelVersion"->$Version, "Succeeded"->succeeded,
   "Properties"->properties, "Report"->report|>, InputForm], "Text"];
If[succeeded, Exit[0], Exit[1]];
