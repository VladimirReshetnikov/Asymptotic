(* Explicitly selected regression files; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckBarnesG.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"BarnesGForward.wlt", "GammaLogarithms.wlt", "GammaProducts.wlt",
  "GammaPowers.wlt",
  "GammaVaryingPowers.wlt", "ExponentialForward.wlt"},
  "Output" -> "barnes-g-tests.json", "Timeout" -> 600,
  "Scope" -> "Six explicitly selected Barnes G and adjacent regression files; the full package suite was not run."|>]];
