(* From the repository root: wolfram.exe -noinit -script src/Tests/RunTests.wl
   From another directory, supply the absolute path to this script.
   Package and test discovery are relative to the script's own location.
   Each discovered .wlt file is reported separately, as in the focused
   validation runner. The exit code is 0 only when test files were
   discovered, the package loaded, every file produced a report with at least
   one executed test, no test failed, and any requested JSON export succeeded.
   An empty or aborted run is a failure, not a vacuous pass. *)
root = DirectoryName[DirectoryName[$InputFileName]];
Print["Kernel: ", $Version];
If[Check[Get[FileNameJoin[{root, "Kernel", "AsymptoticAnalysis.wl"}]], $Failed] === $Failed ||
    ! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Print["Package loading failed; no test suites were run."]; Exit[1]];
testFiles = FileNames["*.wlt", FileNameJoin[{root, "Tests"}]];
If[testFiles === {}, Print["No .wlt test files were discovered; nothing was run."]; Exit[1]];
(* Headless progress rendering is noisy and can emit notebook-layout messages;
   the final report and exported per-test outcomes remain authoritative. *)
runOne[file_] := Module[{report, results},
  report = Check[TestReport[file, ProgressReporting -> False], $Failed];
  If[Head[report] =!= TestReportObject,
    Print["ABORTED ", FileNameTake[file], ": no report object was produced."];
    Return[<|"Suite" -> FileNameTake[file], "Outcome" -> "Aborted",
      "Succeeded" -> 0, "Failed" -> 1, "Results" -> {}|>]];
  results = Values[report["TestResults"]];
  If[results === {},
    Print["NO TESTS ", FileNameTake[file], ": the file executed no VerificationTest."];
    Return[<|"Suite" -> FileNameTake[file], "Outcome" -> "Empty",
      "Succeeded" -> 0, "Failed" -> 1, "Results" -> {}|>]];
  Do[If[r["Outcome"] =!= "Success",
    Print["FAILED ", r["TestID"], "\n   expected: ", ToString[r["ExpectedOutput"], InputForm],
     "\n   actual:   ", ToString[r["ActualOutput"], InputForm],
     "\n   messages: ", ToString[r["ActualMessages"], InputForm]]], {r, results}];
  <|"Suite" -> FileNameTake[file],
    "Outcome" -> If[TrueQ[report["TestsFailedCount"] == 0], "Success", "Failure"],
    "Succeeded" -> report["TestsSucceededCount"], "Failed" -> report["TestsFailedCount"],
    "Results" -> (Join[<|"TestID" -> #["TestID"], "Outcome" -> #["Outcome"]|>,
      If[#["Outcome"] === "Success", <||>, <|
        "ExpectedOutput" -> ToString[#["ExpectedOutput"], InputForm],
        "ActualOutput" -> ToString[#["ActualOutput"], InputForm],
        "ActualMessages" -> ToString[#["ActualMessages"], InputForm]|>]] & /@ results)|>];
suiteResults = runOne /@ testFiles;
succeeded = Total[#["Succeeded"] & /@ suiteResults];
failed = Total[#["Failed"] & /@ suiteResults];
(* Map instead of Lookup: Lookup on an empty list yields Missing, not {}. *)
executed = Total[Length[#["Results"]] & /@ suiteResults];
rejected = Select[suiteResults, MemberQ[{"Aborted", "Empty"}, #["Outcome"]] &];
Print["Discovered files: ", Length[testFiles], "   Executed tests: ", executed,
  "   Empty or aborted files: ", Length[rejected]];
Print["Succeeded: ", succeeded, "   Failed: ", failed];
exportFailed = False;
validationOutput = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[StringQ[validationOutput] && StringLength[validationOutput] > 0,
  exported = Check[Export[validationOutput, <|"Kernel" -> $Version,
    "Suites" -> (FileNameTake /@ testFiles), "ExecutedTests" -> executed,
    "RejectedSuites" -> (#["Suite"] & /@ rejected),
    "SuiteResults" -> (KeyDrop[#, "Results"] & /@ suiteResults),
    "Succeeded" -> succeeded, "Failed" -> failed,
    "Results" -> Join @@ (#["Results"] & /@ suiteResults)|>, "RawJSON"], $Failed];
  If[! StringQ[exported] || ! FileExistsQ[exported],
    Print["Exporting the validation record failed: ", validationOutput]; exportFailed = True]];
Exit[If[TrueQ[failed == 0] && executed > 0 && rejected === {} && ! exportFailed, 0, 1]];
