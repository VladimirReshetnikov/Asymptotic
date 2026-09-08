(* Focused Barnes G regression milestone; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckBarnesG.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)

barnesValidationRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{barnesValidationRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]];
barnesValidationSuites = {"BarnesGForward.wlt", "GammaLogarithms.wlt", "GammaProducts.wlt",
  "GammaPowers.wlt",
  "GammaVaryingPowers.wlt", "ExponentialForward.wlt"};
barnesValidationResults = {};
barnesValidationSummary = {};
Do[
  Print["Checking: ", suite];
  timing = AbsoluteTiming[report = TimeConstrained[
    TestReport[FileNameJoin[{barnesValidationRoot, "AsymptoticInverse", "Tests", suite}],
      ProgressReporting -> False], 600, $Aborted]][[1]];
  If[Head[report] =!= TestReportObject,
    AppendTo[barnesValidationSummary, <|"Suite" -> suite, "Outcome" -> "Aborted",
      "Seconds" -> timing, "Succeeded" -> 0, "Failed" -> 1|>];
    Print["ABORTED: ", suite],
    AppendTo[barnesValidationSummary, <|"Suite" -> suite,
      "Succeeded" -> report["TestsSucceededCount"], "Failed" -> report["TestsFailedCount"],
      "Seconds" -> timing|>];
    Print["Succeeded: ", report["TestsSucceededCount"], "  Failed: ", report["TestsFailedCount"]];
    Do[
      AppendTo[barnesValidationResults, Join[<|"Suite" -> suite,
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
  {suite, barnesValidationSuites}];

barnesValidationSources = Join[
  FileNames["*.wl", FileNameJoin[{barnesValidationRoot, "AsymptoticInverse", "Kernel"}]],
  FileNameJoin[{barnesValidationRoot, "AsymptoticInverse", "Tests", #}] & /@ barnesValidationSuites,
  {$InputFileName}];
barnesValidationHashes = Association[(StringReplace[
    FileNameJoin[Drop[FileNameSplit[ExpandFileName[#]],
      Length[FileNameSplit[barnesValidationRoot]]]], "\\" -> "/"] ->
    IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ barnesValidationSources];
barnesValidationOutput = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[! StringQ[barnesValidationOutput] || StringLength[barnesValidationOutput] == 0,
  barnesValidationOutput = FileNameJoin[{barnesValidationRoot, "validation", "barnes-g-tests.json"}]];
barnesValidationFailed = Total[Lookup[barnesValidationSummary, "Failed"]];
Export[barnesValidationOutput, <|"Kernel" -> $Version,
  "Scope" -> "Six explicitly selected Barnes G and adjacent regression files; the full package suite was not run.",
  "PerSuiteTimeConstraintSeconds" -> 600,
  "Suites" -> barnesValidationSuites, "SuiteResults" -> barnesValidationSummary,
  "Succeeded" -> Total[Lookup[barnesValidationSummary, "Succeeded"]],
  "Failed" -> barnesValidationFailed, "Results" -> barnesValidationResults,
  "TestedSourceSHA256" -> barnesValidationHashes|>, "RawJSON"];
Print["Kernel: ", $Version, "\nTotal succeeded: ", Total[Lookup[barnesValidationSummary, "Succeeded"]],
  "  Failed: ", barnesValidationFailed];
Exit[If[TrueQ[barnesValidationFailed == 0], 0, 1]];
