(* Explicitly selected regression files; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckLogBarnesG.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"LogBarnesG.wlt", "BarnesGInverse.wlt", "GammaInverse.wlt",
  "GammaLogarithms.wlt", "InverseFunctionBranches.wlt",
  "BarnesGForward.wlt"},
  "Output" -> "log-barnes-g-tests.json", "Timeout" -> 600,
  "Scope" -> "Six explicitly selected native LogBarnesG and adjacent regression files; the full package suite was not run."|>]];
