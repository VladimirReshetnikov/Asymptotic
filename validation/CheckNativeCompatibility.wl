(* Explicit native delegation, result contracts, and existing public behavior. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"NativeCompatibility.wlt", "NativeContracts.wlt", "NativePresentation.wlt", "GeneralizedSeries.wlt",
    "NormalExpressions.wlt", "SeriesArithmetic.wlt", "ReviewAssumptionReplay.wlt",
    "ReviewRealCoefficients.wlt"},
  "Output" -> "native-compatibility-tests.json", "Timeout" -> 600,
  "Scope" -> "Explicit native Series/Asymptotic differential cases and Native result contract guards, with selected existing formatting, Normal, arithmetic, assumption replay and real-coefficient regressions. The full package suite was not run."|>]];
