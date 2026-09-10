(* wolframscript -file RunAudit.wl PACKAGE.wl NEW-RESULTS.json
   This runner executes only NovelRegressions.wlt. It refuses empty reports,
   aborted runs, and overwriting a result file. No checksum file is created. *)
Module[{args = Rest[$ScriptCommandLine], source, output, tests, before, report,
    rows, summary, exported, unchanged, succeeded, failed},
  If[Length[args] =!= 2,
    Print["Usage: wolframscript -file RunAudit.wl PACKAGE.wl NEW-RESULTS.json"]; Exit[2]];
  {source, output} = ExpandFileName /@ args;
  tests = FileNameJoin[{DirectoryName[$InputFileName], "NovelRegressions.wlt"}];
  If[!FileExistsQ[source] || !FileExistsQ[tests] || FileExistsQ[output],
    Print["Missing input/test file or output already exists."]; Exit[2]];
  before = BinaryReadList[source];
  If[Check[Get[source], $Failed] === $Failed ||
      !MemberQ[$Packages, "AsymptoticAnalysis`"],
    Print["Package loading failed."]; Exit[2]];
  report = TimeConstrained[TestReport[tests, ProgressReporting -> False], 180, $Aborted];
  If[Head[report] =!= TestReportObject || Length[report["TestResults"]] === 0,
    Print["The selected suite aborted or returned no test results."]; Exit[2]];
  unchanged = FileExistsQ[source] && SameQ[before, BinaryReadList[source]];
  succeeded = report["TestsSucceededCount"]; failed = report["TestsFailedCount"];
  rows = ( <|"TestID" -> #["TestID"], "Outcome" -> #["Outcome"],
      "ExpectedOutput" -> ToString[#["ExpectedOutput"], InputForm],
      "ActualOutput" -> ToString[#["ActualOutput"], InputForm],
      "ActualMessages" -> ToString[#["ActualMessages"], InputForm]|> & ) /@
    Values[report["TestResults"]];
  summary = <|"Kernel" -> $Version, "SystemID" -> $SystemID,
    "SourceFile" -> source, "EntryFileUnchangedDuringRun" -> unchanged,
    "Scope" -> "Only this audit's desired-behavior suite; not the upstream full suite.",
    "Succeeded" -> succeeded, "Failed" -> failed, "Results" -> rows|>;
  exported = Quiet[Check[Export[output, summary, "RawJSON"], $Failed]];
  Print["Succeeded: ", succeeded, "; failed: ", failed,
    "; entry unchanged: ", unchanged];
  Exit[If[IntegerQ[succeeded] && succeeded > 0 && failed === 0 && unchanged &&
    StringQ[exported] && FileExistsQ[exported], 0, 1]]];
