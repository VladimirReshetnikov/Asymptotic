(* Selected exporter, ordinary-series and refinement contracts only. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewNativeExport.wlt", "AsymptoticInverse.wlt",
    "RefinementRegressions.wlt", "GeneralizedSeries.wlt", "SeriesOperations.wlt"},
  "Output" -> "review-native-export-tests.json", "Timeout" -> 600,
  "Scope" -> "Five explicitly selected native export, ordinary-series, refinement and operation files; the full package suite was not run."|>]];
