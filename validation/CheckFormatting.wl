(* Focused series formatting regression milestone; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckFormatting.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)

formattingValidationRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{formattingValidationRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]];
formattingValidationSuites = {"Formatting.wlt"};
formattingValidationResults = {};
formattingValidationSummary = {};
Do[
  Print["Checking: ", suite];
  timing = AbsoluteTiming[report = TimeConstrained[
    TestReport[FileNameJoin[{formattingValidationRoot, "AsymptoticInverse", "Tests", suite}],
      ProgressReporting -> False], 600, $Aborted]][[1]];
  If[Head[report] =!= TestReportObject,
    AppendTo[formattingValidationSummary, <|"Suite" -> suite, "Outcome" -> "Aborted",
      "Seconds" -> timing, "Succeeded" -> 0, "Failed" -> 1|>];
    Print["ABORTED: ", suite],
    AppendTo[formattingValidationSummary, <|"Suite" -> suite,
      "Succeeded" -> report["TestsSucceededCount"], "Failed" -> report["TestsFailedCount"],
      "Seconds" -> timing|>];
    Print["Succeeded: ", report["TestsSucceededCount"], "  Failed: ", report["TestsFailedCount"]];
    Do[
      AppendTo[formattingValidationResults, Join[<|"Suite" -> suite,
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
  {suite, formattingValidationSuites}];

formattingValidationSources = Join[
  FileNames["*.wl", FileNameJoin[{formattingValidationRoot, "AsymptoticInverse", "Kernel"}]],
  FileNameJoin[{formattingValidationRoot, "AsymptoticInverse", "Tests", #}] & /@ formattingValidationSuites,
  {$InputFileName}];
formattingValidationHashes = Association[(StringReplace[
    FileNameJoin[Drop[FileNameSplit[ExpandFileName[#]],
      Length[FileNameSplit[formattingValidationRoot]]]], "\\" -> "/"] ->
    IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ formattingValidationSources];
formattingValidationOutput = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[! StringQ[formattingValidationOutput] || StringLength[formattingValidationOutput] == 0,
  formattingValidationOutput = FileNameJoin[{formattingValidationRoot, "validation", "formatting-tests.json"}]];
formattingValidationFailed = Total[Lookup[formattingValidationSummary, "Failed"]];
Export[formattingValidationOutput, <|"Kernel" -> $Version,
  "Scope" -> "One explicitly selected formatting and Normal regression file; the full package suite was not run.",
  "PerSuiteTimeConstraintSeconds" -> 600,
  "Suites" -> formattingValidationSuites, "SuiteResults" -> formattingValidationSummary,
  "Succeeded" -> Total[Lookup[formattingValidationSummary, "Succeeded"]],
  "Failed" -> formattingValidationFailed, "Results" -> formattingValidationResults,
  "TestedSourceSHA256" -> formattingValidationHashes|>, "RawJSON"];
Print["Kernel: ", $Version, "\nTotal succeeded: ", Total[Lookup[formattingValidationSummary, "Succeeded"]],
  "  Failed: ", formattingValidationFailed];
Exit[If[TrueQ[formattingValidationFailed == 0], 0, 1]];
