(* Native formal orders must preserve the package's analytic error bounds. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewNativeTailExport.wlt", "ReviewNativeTailImport.wlt",
    "ReviewNativeExport.wlt", "NativeSpecialIngress.wlt", "AsymptoticInverse.wlt",
    "SeriesOperations.wlt", "ParameterizedSpecialFunctions.wlt", "SpecialFunctionForward.wlt",
    "RefinementRegressions.wlt"},
  "Output" -> "review-native-tail-tests.json", "Timeout" -> 600,
  "Scope" -> "Nine explicitly selected native export/import, special-function, ordinary inverse, operation and refinement regression files; the full package suite was not run."|>]];
