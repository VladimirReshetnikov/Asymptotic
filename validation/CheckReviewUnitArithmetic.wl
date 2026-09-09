(* Input-limited nonlinear remainders and exact coefficient termination. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewUnitPrecision.wlt", "ReviewRecurrenceTermination.wlt",
    "SeriesArithmetic.wlt", "SeriesOperations.wlt", "AsymptoticInverse.wlt",
    "IncrementalRegressions.wlt", "RefinementRegressions.wlt",
    "ParameterizedSpecialFunctions.wlt", "NativeSpecialIngress.wlt"},
  "Output" -> "review-unit-arithmetic-tests.json", "Timeout" -> 600,
  "Scope" -> "Nine explicitly selected nonlinear remainder, recurrence, arithmetic, inverse, refinement and native-function regression files; the full package suite was not run."|>]];
