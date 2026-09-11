(* Focused checks for Simplify and FullSimplify on result objects, with the object, formatting, operation, refinement and inverse-expression suites that share the object accessors. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewSeriesSimplification.wlt", "GeneralizedSeries.wlt", "Formatting.wlt", "SeriesOperations.wlt",
   "RefinementRegressions.wlt", "InverseFunctionExpressions.wlt", "NativeCompatibility.wlt", "ExponentialCorePerturbation.wlt"},
 "Output" -> "series-simplification-tests.json", "Timeout" -> 900,
 "Scope" -> "Eight selected files: the new simplification suite and the object, formatting, operation, refinement, inverse-expression, native and exponential-core suites that share the object accessors; no full package suite."|>]];
