(* Focused automatic series arithmetic regression milestone; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckSeriesArithmetic.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)

arithmeticValidationRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{arithmeticValidationRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]];
arithmeticValidationSuites = {"SeriesArithmetic.wlt", "SeriesEnvelopeArithmetic.wlt",
  "SeriesEnvelopeFunctions.wlt", "SeriesOperations.wlt", "Formatting.wlt",
  "GammaInverseOperations.wlt", "BarnesGInverse.wlt"};
arithmeticValidationResults = {};
arithmeticValidationSummary = {};
Do[
  Print["Checking: ", suite];
  timing = AbsoluteTiming[report = TimeConstrained[
    TestReport[FileNameJoin[{arithmeticValidationRoot, "AsymptoticInverse", "Tests", suite}],
      ProgressReporting -> False], 600, $Aborted]][[1]];
  If[Head[report] =!= TestReportObject,
    AppendTo[arithmeticValidationSummary, <|"Suite" -> suite, "Outcome" -> "Aborted",
      "Seconds" -> timing, "Succeeded" -> 0, "Failed" -> 1|>];
    Print["ABORTED: ", suite],
    AppendTo[arithmeticValidationSummary, <|"Suite" -> suite,
      "Succeeded" -> report["TestsSucceededCount"], "Failed" -> report["TestsFailedCount"],
      "Seconds" -> timing|>];
    Print["Succeeded: ", report["TestsSucceededCount"], "  Failed: ", report["TestsFailedCount"]];
    Do[
      AppendTo[arithmeticValidationResults, Join[<|"Suite" -> suite,
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
  {suite, arithmeticValidationSuites}];

arithmeticValidationSources = Join[
  FileNames["*.wl", FileNameJoin[{arithmeticValidationRoot, "AsymptoticInverse", "Kernel"}]],
  FileNameJoin[{arithmeticValidationRoot, "AsymptoticInverse", "Tests", #}] & /@ arithmeticValidationSuites,
  {$InputFileName}];
arithmeticValidationHashes = Association[(StringReplace[
    FileNameJoin[Drop[FileNameSplit[ExpandFileName[#]],
      Length[FileNameSplit[arithmeticValidationRoot]]]], "\\" -> "/"] ->
    IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ arithmeticValidationSources];
arithmeticValidationOutput = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[! StringQ[arithmeticValidationOutput] || StringLength[arithmeticValidationOutput] == 0,
  arithmeticValidationOutput = FileNameJoin[{arithmeticValidationRoot, "validation", "series-arithmetic-tests.json"}]];
arithmeticValidationFailed = Total[Lookup[arithmeticValidationSummary, "Failed"]];
Export[arithmeticValidationOutput, <|"Kernel" -> $Version,
  "Scope" -> "Seven explicitly selected automatic arithmetic, composite envelope and function, series operations, formatting, Gamma and Barnes regression files; the full package suite was not run.",
  "PerSuiteTimeConstraintSeconds" -> 600,
  "Suites" -> arithmeticValidationSuites, "SuiteResults" -> arithmeticValidationSummary,
  "Succeeded" -> Total[Lookup[arithmeticValidationSummary, "Succeeded"]],
  "Failed" -> arithmeticValidationFailed, "Results" -> arithmeticValidationResults,
  "TestedSourceSHA256" -> arithmeticValidationHashes|>, "RawJSON"];
Print["Kernel: ", $Version, "\nTotal succeeded: ", Total[Lookup[arithmeticValidationSummary, "Succeeded"]],
  "  Failed: ", arithmeticValidationFailed];
Exit[If[TrueQ[arithmeticValidationFailed == 0], 0, 1]];
