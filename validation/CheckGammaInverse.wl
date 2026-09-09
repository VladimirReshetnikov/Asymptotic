(* Explicitly selected regression files; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckGammaInverse.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"GammaInverse.wlt", "GammaInverseOperations.wlt",
  "InverseFunctionBranches.wlt", "InverseFunctionExpressions.wlt",
  "SpecialFunctionRegressions.wlt", "GammaProducts.wlt"},
  "Output" -> "gamma-inverse-tests.json", "Timeout" -> 600,
  "Scope" -> "Six explicitly selected inverse-Gamma and adjacent regression files; the full package suite was not run."|>]];
