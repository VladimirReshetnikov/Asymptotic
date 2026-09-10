(* Selected principal-log normalization and shared finite-parser consumers. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewLogPowerNormalization.wlt", "AsymptoticInverse.wlt", "ReviewRegressions.wlt",
    "CorePerturbation.wlt", "ExponentialCorePerturbation.wlt", "FlatSectorRegressions.wlt",
    "FlatSectorOperations.wlt", "ReviewAssumptionReplay.wlt"},
  "Output" -> "log-power-normalization-tests.json", "Timeout" -> 600,
  "Scope" -> "Eight selected logarithm normalization, symbolic inverse, exact/exponential core, flat-sector and retained-assumption files; no full package suite."|>]];
