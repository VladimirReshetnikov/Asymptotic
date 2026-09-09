(* Constructor assumption capture and isolation of saved proof contexts. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewAssumptions.wlt", "SeriesArithmetic.wlt", "SeriesOperations.wlt",
    "AsymptoticInverse.wlt", "IncrementalRegressions.wlt", "RefinementRegressions.wlt",
    "ParameterizedSpecialFunctions.wlt", "InverseFunctionExpressions.wlt"},
  "Output" -> "review-assumptions-tests.json", "Timeout" -> 600,
  "Scope" -> "Eight explicitly selected assumption, arithmetic, operation, inverse, refinement, parameter and branch regression files; the full package suite was not run."|>]];
