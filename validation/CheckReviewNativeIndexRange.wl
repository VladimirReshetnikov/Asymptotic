(* Selected optional-native-view and ordinary representation contracts only. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewNativeIndexRange.wlt", "ReviewNativeExport.wlt", "ReviewNativeTailExport.wlt", "GeneralizedSeries.wlt"},
  "Output" -> "review-native-index-range-tests.json", "Timeout" -> 600,
  "Scope" -> "Four explicitly selected native index-range, sparse export, logarithmic tail and generalized-series files; the full package suite was not run."|>]];
