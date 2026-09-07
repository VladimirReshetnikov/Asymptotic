(* Run with:  wolfram -script AsymptoticInverse/Tests/RunTests.wl   (from the repository root or anywhere) *)
root = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Kernel", "AsymptoticInverse.wl"}]];
report = TestReport[FileNameJoin[{root, "Tests", "AsymptoticInverse.wlt"}]];
Print["Kernel: ", $Version];
Print["Succeeded: ", report["TestsSucceededCount"], "   Failed: ", report["TestsFailedCount"]];
Do[If[r["Outcome"] =!= "Success",
  Print["FAILED ", r["TestID"], "\n   expected: ", ToString[r["ExpectedOutput"], InputForm],
   "\n   actual:   ", ToString[r["ActualOutput"], InputForm]]], {r, Values[report["TestResults"]]}];
Exit[If[TrueQ[report["TestsFailedCount"] == 0], 0, 1]];
