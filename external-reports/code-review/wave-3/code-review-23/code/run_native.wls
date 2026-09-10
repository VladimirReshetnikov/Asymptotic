(* Fresh-kernel, local-checkout-only runner. NOT EXECUTED in this audit.
   Set ASYMPTOTIC_AUDIT_REPO to a checkout of revision 6687962.
   Uses modular source deliberately; does not regenerate or edit the checkout. *)
scriptDirectory = DirectoryName[$InputFileName];
repo = Environment["ASYMPTOTIC_AUDIT_REPO"];
If[! StringQ[repo] || ! DirectoryQ[repo],
 Print["Set ASYMPTOTIC_AUDIT_REPO to the local pinned checkout."]; Exit[2]];
If[MemberQ[$Packages, "AsymptoticAnalysis`"],
 Print["Use a fresh kernel; the package is already loaded."]; Exit[2]];
entry = FileNameJoin[{repo, "src", "Kernel", "AsymptoticAnalysis.wl"}];
If[! FileExistsQ[entry], Print["Missing modular entry point: ", entry]; Exit[2]];
Get[entry];
If[! MemberQ[$Packages, "AsymptoticAnalysis`"], Print["Package load failed."]; Exit[2]];
report = TestReport[FileNameJoin[{scriptDirectory, "focused_regressions.wlt"}],
 TimeConstraint -> 45, MemoryConstraint -> 1024^3];
If[Head[report] =!= TestReportObject, Print["No TestReportObject was produced."]; Exit[2]];
properties = report["Properties"];
results = Which[
 MemberQ[properties, "ResultList"], report["ResultList"],
 MemberQ[properties, "TestResults"], Values[report["TestResults"]],
 True, Print["Unknown report schema: ", properties]; Exit[2]];
If[! ListQ[results], Print["No test-result list."]; Exit[2]];
outcomes = #["Outcome"] & /@ results;
summary = <|"KernelVersion" -> $Version, "SystemID" -> $SystemID,
 "ReferenceRevision" -> "6687962f3c858a4f93623cfc496f33e35c6763d4",
 "CheckoutPath" -> repo, "LoadedEntryPoint" -> entry,
 "SourceState" -> "Caller-supplied local checkout; may contain proposed edits",
 "ExpectedTests" -> 9, "TestsReturned" -> Length[results],
 "Outcomes" -> (ToString[#, InputForm] & /@ outcomes),
 "AllExpectedTestsSucceeded" -> (Length[results] == 9 && AllTrue[outcomes, # === "Success" &])|>;
outputDirectory = FileNameJoin[{scriptDirectory, "..", "results"}];
If[! DirectoryQ[outputDirectory], CreateDirectory[outputDirectory]];
Export[FileNameJoin[{outputDirectory, "native_summary.json"}], summary, "RawJSON"];
Put[report, FileNameJoin[{outputDirectory, "native_report.wl"}]];
Print[summary];
Exit[If[TrueQ[summary["AllExpectedTestsSucceeded"]], 0, 1]];
