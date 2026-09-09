(* Focused native special-function regression milestone; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckSpecialFunctions.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)

specialValidationRoot = DirectoryName[DirectoryName[$InputFileName]];
specialValidationSuites = {"SpecialFunctionForward.wlt", "SpecialFunctionIdentities.wlt",
  "ParameterizedSpecialFunctions.wlt", "NativeSpecialIngress.wlt", "DirichletSpecialFunctions.wlt",
  "NormalExpressions.wlt", "GammaForward.wlt", "BarnesGForward.wlt", "ExponentialForward.wlt",
  "SeriesArithmetic.wlt", "SeriesEnvelopeArithmetic.wlt", "Formatting.wlt"};
specialValidationSources = Join[
  FileNames["*.wl", FileNameJoin[{specialValidationRoot, "AsymptoticInverse", "Kernel"}]],
  FileNameJoin[{specialValidationRoot, "AsymptoticInverse", "Tests", #}] & /@ specialValidationSuites,
  {$InputFileName}];
specialValidationSourceHashes[] := Association[(StringReplace[
    FileNameJoin[Drop[FileNameSplit[ExpandFileName[#]],
      Length[FileNameSplit[specialValidationRoot]]]], "\\" -> "/"] ->
    IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ specialValidationSources];
specialValidationHashes = specialValidationSourceHashes[];
Get[FileNameJoin[{specialValidationRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]];
specialValidationResults = {};
specialValidationSummary = {};
Do[
  Print["Checking: ", suite];
  timing = AbsoluteTiming[report = TimeConstrained[
    TestReport[FileNameJoin[{specialValidationRoot, "AsymptoticInverse", "Tests", suite}],
      ProgressReporting -> False], 900, $Aborted]][[1]];
  If[Head[report] =!= TestReportObject,
    AppendTo[specialValidationSummary, <|"Suite" -> suite, "Outcome" -> "Aborted",
      "Seconds" -> timing, "Succeeded" -> 0, "Failed" -> 1|>];
    Print["ABORTED: ", suite],
    AppendTo[specialValidationSummary, <|"Suite" -> suite,
      "Succeeded" -> report["TestsSucceededCount"], "Failed" -> report["TestsFailedCount"],
      "Seconds" -> timing|>];
    Print["Succeeded: ", report["TestsSucceededCount"], "  Failed: ", report["TestsFailedCount"]];
    Do[
      AppendTo[specialValidationResults, Join[<|"Suite" -> suite,
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
  {suite, specialValidationSuites}];

specialValidationSourcesUnchanged = specialValidationHashes === specialValidationSourceHashes[];
specialValidationOutput = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[! StringQ[specialValidationOutput] || StringLength[specialValidationOutput] == 0,
  specialValidationOutput = FileNameJoin[{specialValidationRoot, "validation", "special-functions-tests.json"}]];
specialValidationFailed = Total[Lookup[specialValidationSummary, "Failed"]] +
  If[specialValidationSourcesUnchanged, 0, 1];
Export[specialValidationOutput, <|"Kernel" -> $Version,
  "Scope" -> "Explicitly selected special-function expansion and exact-identity regression files; the full package suite was not run.",
  "PerSuiteTimeConstraintSeconds" -> 900,
  "Suites" -> specialValidationSuites, "SuiteResults" -> specialValidationSummary,
  "Succeeded" -> Total[Lookup[specialValidationSummary, "Succeeded"]],
  "Failed" -> specialValidationFailed, "Results" -> specialValidationResults,
  "SourcesUnchangedDuringRun" -> specialValidationSourcesUnchanged,
  "TestedSourceSHA256" -> specialValidationHashes|>, "RawJSON"];
Print["Kernel: ", $Version, "\nTotal succeeded: ", Total[Lookup[specialValidationSummary, "Succeeded"]],
  "  Failed: ", specialValidationFailed];
Exit[If[TrueQ[specialValidationFailed == 0], 0, 1]];
