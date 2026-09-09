(* Explicitly selected regression files; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckSeriesArithmetic.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"SeriesArithmetic.wlt", "SeriesEnvelopeArithmetic.wlt",
  "SeriesEnvelopeFunctions.wlt", "SeriesOperations.wlt", "Formatting.wlt",
  "GammaInverseOperations.wlt", "BarnesGInverse.wlt"},
  "Output" -> "series-arithmetic-tests.json", "Timeout" -> 600,
  "Scope" -> "Seven explicitly selected automatic arithmetic, composite envelope and function, series operations, formatting, Gamma and Barnes regression files; the full package suite was not run."|>]];
