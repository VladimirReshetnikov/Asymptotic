(* Run with:  wolfram -script AsymptoticInverse/Tests/RunTests.wl   (from the repository root or anywhere) *)
root = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Kernel", "AsymptoticInverse.wl"}]];
testFiles = FileNames["*.wlt", FileNameJoin[{root, "Tests"}]];
report = TestReport[testFiles];
Print["Kernel: ", $Version];
Print["Succeeded: ", report["TestsSucceededCount"], "   Failed: ", report["TestsFailedCount"]];
Do[If[r["Outcome"] =!= "Success",
  Print["FAILED ", r["TestID"], "\n   expected: ", ToString[r["ExpectedOutput"], InputForm],
   "\n   actual:   ", ToString[r["ActualOutput"], InputForm]]], {r, Values[report["TestResults"]]}];
validationOutput = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[StringQ[validationOutput] && StringLength[validationOutput] > 0,
  Export[validationOutput, <|"Kernel" -> $Version,
    "Suites" -> (FileNameTake /@ testFiles),
    "Succeeded" -> report["TestsSucceededCount"], "Failed" -> report["TestsFailedCount"],
    "Results" -> (<|"TestID" -> #["TestID"], "Outcome" -> #["Outcome"]|> & /@ Values[report["TestResults"]])|>, "RawJSON"]];
Exit[If[TrueQ[report["TestsFailedCount"] == 0], 0, 1]];
