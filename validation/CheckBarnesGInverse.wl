(* Focused inverse-Barnes G regression milestone; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckBarnesGInverse.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)

barnesInverseValidationRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{barnesInverseValidationRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]];
barnesInverseValidationSuites = {"BarnesGInverse.wlt", "GammaInverse.wlt", "GammaInverseOperations.wlt",
  "InverseFunctionBranches.wlt", "InverseFunctionExpressions.wlt",
  "BarnesGForward.wlt"};
barnesInverseValidationResults = {};
barnesInverseValidationSummary = {};
Do[
  Print["Checking: ", suite];
  timing = AbsoluteTiming[report = TimeConstrained[
    TestReport[FileNameJoin[{barnesInverseValidationRoot, "AsymptoticInverse", "Tests", suite}],
      ProgressReporting -> False], 600, $Aborted]][[1]];
  If[Head[report] =!= TestReportObject,
    AppendTo[barnesInverseValidationSummary, <|"Suite" -> suite, "Outcome" -> "Aborted",
      "Seconds" -> timing, "Succeeded" -> 0, "Failed" -> 1|>];
    Print["ABORTED: ", suite],
    AppendTo[barnesInverseValidationSummary, <|"Suite" -> suite,
      "Succeeded" -> report["TestsSucceededCount"], "Failed" -> report["TestsFailedCount"],
      "Seconds" -> timing|>];
    Print["Succeeded: ", report["TestsSucceededCount"], "  Failed: ", report["TestsFailedCount"]];
    Do[
      AppendTo[barnesInverseValidationResults, Join[<|"Suite" -> suite,
        "TestID" -> result["TestID"], "Outcome" -> result["Outcome"]|>,
        If[result["Outcome"] === "Success", <||>, <|
          "ExpectedOutput" -> ToString[result["ExpectedOutput"], InputForm],
          "ActualOutput" -> ToString[result["ActualOutput"], InputForm],
          "ActualMessages" -> ToString[result["ActualMessages"], InputForm]|>]]];
      If[result["Outcome"] =!= "Success",
        Print["FAILED ", result["TestID"], "\n expected: ", ToString[result["ExpectedOutput"], InputForm],
          "\n actual: ", ToString[result["ActualOutput"], InputForm],
          "\n messages: ", ToString[result["ActualMessages"], InputForm]]],
      {result, Values[report["TestResults"]]}]],
  {suite, barnesInverseValidationSuites}];

barnesInverseValidationSources = Join[
  FileNames["*.wl", FileNameJoin[{barnesInverseValidationRoot, "AsymptoticInverse", "Kernel"}]],
  FileNameJoin[{barnesInverseValidationRoot, "AsymptoticInverse", "Tests", #}] & /@ barnesInverseValidationSuites,
  {$InputFileName}];
barnesInverseValidationHashes = Association[(StringReplace[
    FileNameJoin[Drop[FileNameSplit[ExpandFileName[#]],
      Length[FileNameSplit[barnesInverseValidationRoot]]]], "\\" -> "/"] ->
    IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ barnesInverseValidationSources];
barnesInverseValidationOutput = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[! StringQ[barnesInverseValidationOutput] || StringLength[barnesInverseValidationOutput] == 0,
  barnesInverseValidationOutput = FileNameJoin[{barnesInverseValidationRoot, "validation", "barnes-g-inverse-tests.json"}]];
barnesInverseValidationFailed = Total[Lookup[barnesInverseValidationSummary, "Failed"]];
Export[barnesInverseValidationOutput, <|"Kernel" -> $Version,
  "Scope" -> "Six explicitly selected inverse-Barnes G and adjacent regression files; the full package suite was not run.",
  "PerSuiteTimeConstraintSeconds" -> 600,
  "Suites" -> barnesInverseValidationSuites, "SuiteResults" -> barnesInverseValidationSummary,
  "Succeeded" -> Total[Lookup[barnesInverseValidationSummary, "Succeeded"]],
  "Failed" -> barnesInverseValidationFailed, "Results" -> barnesInverseValidationResults,
  "TestedSourceSHA256" -> barnesInverseValidationHashes|>, "RawJSON"];
Print["Kernel: ", $Version, "\nTotal succeeded: ", Total[Lookup[barnesInverseValidationSummary, "Succeeded"]],
  "  Failed: ", barnesInverseValidationFailed];
Exit[If[TrueQ[barnesInverseValidationFailed == 0], 0, 1]];
