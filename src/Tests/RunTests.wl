(* Run with:  wolfram -script src/Tests/RunTests.wl   (from the repository root or anywhere) *)
root = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Kernel", "AsymptoticAnalysis.wl"}]];
testFiles = FileNames["*.wlt", FileNameJoin[{root, "Tests"}]];
(* Headless progress rendering is noisy and can emit notebook-layout messages;
   the final report and exported per-test outcomes remain authoritative. *)
report = TestReport[testFiles, ProgressReporting -> False];
Print["Kernel: ", $Version];
Print["Succeeded: ", report["TestsSucceededCount"], "   Failed: ", report["TestsFailedCount"]];
Do[If[r["Outcome"] =!= "Success",
  Print["FAILED ", r["TestID"], "\n   expected: ", ToString[r["ExpectedOutput"], InputForm],
   "\n   actual:   ", ToString[r["ActualOutput"], InputForm],
   "\n   messages: ", ToString[r["ActualMessages"], InputForm]]], {r, Values[report["TestResults"]]}];
validationOutput = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[StringQ[validationOutput] && StringLength[validationOutput] > 0,
  Export[validationOutput, <|"Kernel" -> $Version,
    "Suites" -> (FileNameTake /@ testFiles),
    "Succeeded" -> report["TestsSucceededCount"], "Failed" -> report["TestsFailedCount"],
    "Results" -> (Join[<|"TestID" -> #["TestID"], "Outcome" -> #["Outcome"]|>,
      If[#["Outcome"] === "Success", <||>, <|
        "ExpectedOutput" -> ToString[#["ExpectedOutput"], InputForm],
        "ActualOutput" -> ToString[#["ActualOutput"], InputForm],
        "ActualMessages" -> ToString[#["ActualMessages"], InputForm]|>]] & /@ Values[report["TestResults"]])|>, "RawJSON"]];
Exit[If[TrueQ[report["TestsFailedCount"] == 0], 0, 1]];
