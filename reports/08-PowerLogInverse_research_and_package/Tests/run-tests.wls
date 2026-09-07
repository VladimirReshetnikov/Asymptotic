#!/usr/bin/env wolframscript
(* Exit 0 iff all 40 native tests execute and succeed.
   TestReportObject property names differ across Wolfram versions. *)
report = TestReport[FileNameJoin[{DirectoryName[$InputFileName], "PowerLogInverse.wlt"}]];
Print[report];
properties = Quiet[Check[report["Properties"], {}]];
If[!ListQ[properties], properties = {}];
success = Which[
 MemberQ[properties, "ReportSucceeded"] && MemberQ[properties, "Results"],
  TrueQ[report["ReportSucceeded"]] && Length[report["Results"]] === 40,
 MemberQ[properties, "TestsFailedCount"] &&
  MemberQ[properties, "TestsSucceededCount"],
  report["TestsFailedCount"] === 0 && report["TestsSucceededCount"] === 40,
 True, False
];
Print["All 40 tests executed and succeeded: ", success];
If[TrueQ[success], Exit[0], Exit[1]];
