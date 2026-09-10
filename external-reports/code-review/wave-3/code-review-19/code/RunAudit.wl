(* Usage: wolframscript -file RunAudit.wl /absolute/path/package.wl /absolute/path/report.txt
   Runs ONLY this audit's desired-contract file. Baseline failures are expected.
   This complete runner was not executed during the audit; individual probes were.
   Use a fresh kernel. Test-local option changes are not guaranteed to be restored
   after an external abort, so do not run in a valuable interactive session. *)
scriptArguments = Rest[$ScriptCommandLine];
If[Length[scriptArguments] < 1,
 Print["Usage: wolframscript -file RunAudit.wl package.wl [report.txt]"]; Exit[2]];
packagePath = ExpandFileName[scriptArguments[[1]]];
auditDirectory = DirectoryName[$InputFileName];
reportPath = If[Length[scriptArguments] >= 2, ExpandFileName[scriptArguments[[2]]],
 FileNameJoin[{Directory[], "audit-native-report.txt"}]];
If[! FileExistsQ[packagePath], Print["Package file does not exist."]; Exit[2]];
Get[packagePath];
If[Names["AsymptoticAnalysis`AsymptoticExpansion"] === {},
 Print["Expected package was not loaded."]; Exit[2]];
report = TestReport[FileNameJoin[{auditDirectory, "DesiredContracts.wlt"}]];
exported = Export[reportPath,
 "Kernel: " <> $Version <> "\nPackage: " <> packagePath <>
 "\nScope: audit desired-contract specifications only; not the upstream suite.\n\n" <>
 ToString[report, InputForm, PageWidth -> 120], "Text"];
If[exported === $Failed, Print["Could not export report."]; Exit[2]];
Print[report]; Print["Report written to ", reportPath];
(* Require the complete intended file, not a vacuous or partial success.
   Current documented properties: Results, ReportSucceeded; inspect each outcome. *)
If[! MatchQ[report, _TestReportObject], Exit[2]];
results = report["Results"];
If[! ListQ[results] || Length[results] =!= 14, Exit[2]];
Exit[If[TrueQ[report["ReportSucceeded"]] &&
 AllTrue[results, TrueQ[#["Outcome"] === "Succeeded"] &], 0, 1]];
