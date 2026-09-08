(* Focused logarithmic Gamma regression milestone; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckGammaLogarithms.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)

gammaValidationRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{gammaValidationRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]];
gammaValidationSuites = {"GammaLogarithms.wlt", "GammaProducts.wlt",
  "GammaPowers.wlt", "GammaRelatedFunctions.wlt",
  "GammaVaryingPowers.wlt", "ExponentialForward.wlt"};
gammaValidationResults = {};
gammaValidationSummary = {};
Do[
  Print["Checking: ", suite];
  timing = AbsoluteTiming[report = TimeConstrained[
    TestReport[FileNameJoin[{gammaValidationRoot, "AsymptoticInverse", "Tests", suite}],
      ProgressReporting -> False], 600, $Aborted]][[1]];
  If[Head[report] =!= TestReportObject,
    AppendTo[gammaValidationSummary, <|"Suite" -> suite, "Outcome" -> "Aborted",
      "Seconds" -> timing, "Succeeded" -> 0, "Failed" -> 1|>];
    Print["ABORTED: ", suite],
    AppendTo[gammaValidationSummary, <|"Suite" -> suite,
      "Succeeded" -> report["TestsSucceededCount"], "Failed" -> report["TestsFailedCount"],
      "Seconds" -> timing|>];
    Print["Succeeded: ", report["TestsSucceededCount"], "  Failed: ", report["TestsFailedCount"]];
    Do[
      AppendTo[gammaValidationResults, Join[<|"Suite" -> suite,
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
  {suite, gammaValidationSuites}];

gammaValidationSources = Join[
  FileNames["*.wl", FileNameJoin[{gammaValidationRoot, "AsymptoticInverse", "Kernel"}]],
  FileNameJoin[{gammaValidationRoot, "AsymptoticInverse", "Tests", #}] & /@ gammaValidationSuites,
  {$InputFileName}];
gammaValidationHashes = Association[(StringReplace[
    FileNameJoin[Drop[FileNameSplit[ExpandFileName[#]],
      Length[FileNameSplit[gammaValidationRoot]]]], "\\" -> "/"] ->
    IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ gammaValidationSources];
gammaValidationOutput = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[! StringQ[gammaValidationOutput] || StringLength[gammaValidationOutput] == 0,
  gammaValidationOutput = FileNameJoin[{gammaValidationRoot, "validation", "gamma-logarithms-tests.json"}]];
gammaValidationFailed = Total[Lookup[gammaValidationSummary, "Failed"]];
Export[gammaValidationOutput, <|"Kernel" -> $Version,
  "Scope" -> "Six explicitly selected logarithmic Gamma and adjacent regression files; the full package suite was not run.",
  "PerSuiteTimeConstraintSeconds" -> 600,
  "Suites" -> gammaValidationSuites, "SuiteResults" -> gammaValidationSummary,
  "Succeeded" -> Total[Lookup[gammaValidationSummary, "Succeeded"]],
  "Failed" -> gammaValidationFailed, "Results" -> gammaValidationResults,
  "TestedSourceSHA256" -> gammaValidationHashes|>, "RawJSON"];
Print["Kernel: ", $Version, "\nTotal succeeded: ", Total[Lookup[gammaValidationSummary, "Succeeded"]],
  "  Failed: ", gammaValidationFailed];
Exit[If[TrueQ[gammaValidationFailed == 0], 0, 1]];
