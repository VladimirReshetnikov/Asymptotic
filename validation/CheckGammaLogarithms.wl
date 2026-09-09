(* Explicitly selected regression files; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckGammaLogarithms.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"GammaLogarithms.wlt", "GammaProducts.wlt",
  "GammaPowers.wlt", "GammaRelatedFunctions.wlt",
  "GammaVaryingPowers.wlt", "ExponentialForward.wlt"},
  "Output" -> "gamma-logarithms-tests.json", "Timeout" -> 600,
  "Scope" -> "Six explicitly selected logarithmic Gamma and adjacent regression files; the full package suite was not run."|>]];
