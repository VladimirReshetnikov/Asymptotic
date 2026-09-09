(* Explicitly selected regression files; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckSpecialFunctions.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"SpecialFunctionForward.wlt", "SpecialFunctionIdentities.wlt",
  "ParameterizedSpecialFunctions.wlt", "NativeSpecialIngress.wlt", "DirichletSpecialFunctions.wlt",
  "NormalExpressions.wlt", "GammaForward.wlt", "BarnesGForward.wlt", "ExponentialForward.wlt",
  "SeriesArithmetic.wlt", "SeriesEnvelopeArithmetic.wlt", "Formatting.wlt"},
  "Output" -> "special-functions-tests.json", "Timeout" -> 900,
  "Scope" -> "Explicitly selected special-function expansion and exact-identity regression files; the full package suite was not run."|>]];
