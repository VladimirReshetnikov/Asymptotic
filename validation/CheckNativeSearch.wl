(* Two-backend native search and adjacent held-entry/native contracts. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"NativeSearch.wlt", "NativeAutomatic.wlt", "NativeCompatibility.wlt",
    "NativeContracts.wlt", "NativePresentation.wlt", "ReviewAssumptionReplay.wlt",
    "ReviewRealCoefficients.wlt", "InverseFunctionIntegration.wlt", "InverseFunctionSyntax.wlt"},
  "Output" -> "native-search-tests.json", "Timeout" -> 600,
  "Scope" -> "Nine explicitly selected files for compatible second-native-backend search, held and delayed evaluation, original/native request metadata, and adjacent automatic/native/analytic/inverse contracts. Direct native calls provide differential oracles. This does not prove exhaustive native input coverage; the full package suite was not run."|>]];
