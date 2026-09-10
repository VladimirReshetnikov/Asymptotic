(* Focused desired-contract runner; not the upstream aggregate suite. *)
$ReviewCodeDirectory = DirectoryName[$InputFileName];
Get[FileNameJoin[{$ReviewCodeDirectory, "load_review.wl"}]];
$ReviewReport = TimeConstrained[
 TestReport[FileNameJoin[{$ReviewCodeDirectory, "regressions.wlt"}]], 120, $Failed];
If[Head[$ReviewReport] =!= TestReportObject,
 Print["No TestReportObject was produced."]; Exit[2]];
$ReviewPassed = $ReviewReport["TestsSucceededCount"];
$ReviewFailed = $ReviewReport["TestsFailedCount"];
If[!IntegerQ[$ReviewPassed] || !IntegerQ[$ReviewFailed] || $ReviewPassed+$ReviewFailed == 0,
 Print["Invalid or empty test report."]; Exit[2]];
Print[ExportString[<|"Kernel"->$Version, "Source"->$AuditSourceDescription,
 "Passed"->$ReviewPassed, "Failed"->$ReviewFailed|>, "RawJSON"]];
Exit[If[$ReviewFailed == 0, 0, 1]];
