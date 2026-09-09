(* Shared power-branch checks and selected forward/observable regressions. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewPowerBranches.wlt", "SeriesArithmetic.wlt", "SeriesOperations.wlt",
    "AsymptoticInverse.wlt", "ExpandedInputs.wlt", "ExponentialForward.wlt"},
  "Output" -> "review-power-branches-tests.json", "Timeout" -> 600,
  "Scope" -> "Six explicitly selected shared-power, arithmetic, observable and forward regression files; the full package suite was not run."|>]];
