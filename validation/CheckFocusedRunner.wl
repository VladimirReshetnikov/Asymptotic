(* Exercise real MUnit success, failure, timeout and provenance failure paths
   without running any package regression suites. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
runnerCheckRoot = CreateDirectory[];
CreateDirectory[FileNameJoin[{runnerCheckRoot, "AsymptoticInverse", "Kernel"}], CreateIntermediateDirectories -> True];
CreateDirectory[FileNameJoin[{runnerCheckRoot, "AsymptoticInverse", "Tests"}]];
CreateDirectory[FileNameJoin[{runnerCheckRoot, "validation"}]];
runnerCheckKernel = FileNameJoin[{runnerCheckRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}];
Export[runnerCheckKernel, "BeginPackage[\"AsymptoticInverse`\"]; EndPackage[];", "Text"];
runnerCheckEntry = FileNameJoin[{runnerCheckRoot, "validation", "entry.wl"}];
Export[runnerCheckEntry, "(* Self-check entry. *)", "Text"];
runnerCheckEnvironment = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
SetEnvironment["ASYMPTOTIC_VALIDATION_OUTPUT" -> None];

runnerCheck[name_, body_, expectedExit_, expectedCounts_, unchanged_, timeout_: 30] := Module[{code, report},
  Export[FileNameJoin[{runnerCheckRoot, "AsymptoticInverse", "Tests", name <> ".wlt"}], body, "Text"];
  code = FocusedValidation`Run[runnerCheckRoot, runnerCheckEntry, <|
    "Suites" -> {name <> ".wlt"}, "Output" -> name <> ".json", "Timeout" -> timeout,
    "Scope" -> "Synthetic runner behavior check; no package suite."|>];
  report = Import[FileNameJoin[{runnerCheckRoot, "validation", name <> ".json"}], "RawJSON"];
  <|"Check" -> name, "Passed" -> (code === expectedExit &&
    Lookup[report, {"Succeeded", "Failed"}] === expectedCounts &&
    report["SourcesUnchangedDuringRun"] === unchanged &&
    Length[report["TestedSourceSHA256"]] === 4)|>];

runnerChecks = {
  runnerCheck["success", "VerificationTest[2 + 2, 4, TestID -> \"success\"]", 0, {1, 0}, True],
  runnerCheck["failure", "VerificationTest[2 + 2, 5, TestID -> \"failure\"]", 1, {0, 1}, True],
  runnerCheck["timeout", "Pause[5]; VerificationTest[1, 1]", 1, {0, 1}, True, 1],
  runnerCheck["empty-suite", "(* No registered tests. *)", 1, {0, 1}, True],
  runnerCheck["changed-source", "VerificationTest[PutAppend[\"changed\", " <>
    ToString[runnerCheckKernel, InputForm] <> "]; True, True, TestID -> \"mutates-source\"]",
    1, {1, 1}, False],
  <|"Check" -> "missing-suite", "Passed" -> (FocusedValidation`Run[runnerCheckRoot, runnerCheckEntry,
    <|"Suites" -> {"missing.wlt"}|>] === 1)|>,
  <|"Check" -> "empty-selection", "Passed" -> (FocusedValidation`Run[runnerCheckRoot, runnerCheckEntry,
    <|"Suites" -> {}|>] === 1)|>,
  <|"Check" -> "failed-load", "Passed" -> (
    Export[runnerCheckKernel, "BeginPackage[", "Text"];
    Quiet[FocusedValidation`Run[runnerCheckRoot, runnerCheckEntry,
      <|"Suites" -> {"success.wlt"}|>]] === 1)|>
};
SetEnvironment["ASYMPTOTIC_VALIDATION_OUTPUT" -> If[StringQ[runnerCheckEnvironment], runnerCheckEnvironment, None]];
Export[FileNameJoin[{DirectoryName[$InputFileName], "focused-runner-tests.json"}],
  <|"Kernel" -> $Version, "Results" -> runnerChecks,
    "TestedSourceSHA256" -> Association[("validation/" <> FileNameTake[#] ->
      IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@
        {$InputFileName, FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]}],
    "Succeeded" -> Count[Lookup[runnerChecks, "Passed"], True],
    "Failed" -> Count[Lookup[runnerChecks, "Passed"], Except[True]]|>, "RawJSON"];
Print[runnerChecks];
Exit[If[And @@ Lookup[runnerChecks, "Passed"], 0, 1]];
