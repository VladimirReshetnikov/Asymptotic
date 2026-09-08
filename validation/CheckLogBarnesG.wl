(* Focused native LogBarnesG regression milestone; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckLogBarnesG.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)

logBarnesValidationRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{logBarnesValidationRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]];
logBarnesValidationSuites = {"LogBarnesG.wlt", "BarnesGInverse.wlt", "GammaInverse.wlt",
  "GammaLogarithms.wlt", "InverseFunctionBranches.wlt",
  "BarnesGForward.wlt"};
logBarnesValidationResults = {};
logBarnesValidationSummary = {};
Do[
  Print["Checking: ", suite];
  timing = AbsoluteTiming[report = TimeConstrained[
    TestReport[FileNameJoin[{logBarnesValidationRoot, "AsymptoticInverse", "Tests", suite}],
      ProgressReporting -> False], 600, $Aborted]][[1]];
  If[Head[report] =!= TestReportObject,
    AppendTo[logBarnesValidationSummary, <|"Suite" -> suite, "Outcome" -> "Aborted",
      "Seconds" -> timing, "Succeeded" -> 0, "Failed" -> 1|>];
    Print["ABORTED: ", suite],
    AppendTo[logBarnesValidationSummary, <|"Suite" -> suite,
      "Succeeded" -> report["TestsSucceededCount"], "Failed" -> report["TestsFailedCount"],
      "Seconds" -> timing|>];
    Print["Succeeded: ", report["TestsSucceededCount"], "  Failed: ", report["TestsFailedCount"]];
    Do[
      AppendTo[logBarnesValidationResults, Join[<|"Suite" -> suite,
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
  {suite, logBarnesValidationSuites}];

logBarnesValidationSources = Join[
  FileNames["*.wl", FileNameJoin[{logBarnesValidationRoot, "AsymptoticInverse", "Kernel"}]],
  FileNameJoin[{logBarnesValidationRoot, "AsymptoticInverse", "Tests", #}] & /@ logBarnesValidationSuites,
  {$InputFileName}];
logBarnesValidationHashes = Association[(StringReplace[
    FileNameJoin[Drop[FileNameSplit[ExpandFileName[#]],
      Length[FileNameSplit[logBarnesValidationRoot]]]], "\\" -> "/"] ->
    IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ logBarnesValidationSources];
logBarnesValidationOutput = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[! StringQ[logBarnesValidationOutput] || StringLength[logBarnesValidationOutput] == 0,
  logBarnesValidationOutput = FileNameJoin[{logBarnesValidationRoot, "validation", "log-barnes-g-tests.json"}]];
logBarnesValidationFailed = Total[Lookup[logBarnesValidationSummary, "Failed"]];
Export[logBarnesValidationOutput, <|"Kernel" -> $Version,
  "Scope" -> "Six explicitly selected native LogBarnesG and adjacent regression files; the full package suite was not run.",
  "PerSuiteTimeConstraintSeconds" -> 600,
  "Suites" -> logBarnesValidationSuites, "SuiteResults" -> logBarnesValidationSummary,
  "Succeeded" -> Total[Lookup[logBarnesValidationSummary, "Succeeded"]],
  "Failed" -> logBarnesValidationFailed, "Results" -> logBarnesValidationResults,
  "TestedSourceSHA256" -> logBarnesValidationHashes|>, "RawJSON"];
Print["Kernel: ", $Version, "\nTotal succeeded: ", Total[Lookup[logBarnesValidationSummary, "Succeeded"]],
  "  Failed: ", logBarnesValidationFailed];
Exit[If[TrueQ[logBarnesValidationFailed == 0], 0, 1]];
