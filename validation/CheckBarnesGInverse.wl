(* Explicitly selected regression files; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckBarnesGInverse.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"BarnesGInverse.wlt", "GammaInverse.wlt", "GammaInverseOperations.wlt",
  "InverseFunctionBranches.wlt", "InverseFunctionExpressions.wlt",
  "BarnesGForward.wlt"},
  "Output" -> "barnes-g-inverse-tests.json", "Timeout" -> 600,
  "Scope" -> "Six explicitly selected inverse-Barnes G and adjacent regression files; the full package suite was not run."|>]];
