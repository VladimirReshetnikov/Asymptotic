(* Delayed options, specialized constructors and retained replay context. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewAssumptionReplay.wlt"},
  "Output" -> "review-assumption-replay-tests.json", "Timeout" -> 600,
  "Scope" -> "Twelve supplemental delayed-option, specialized-constructor and retained-state regressions; complements CheckReviewAssumptions.wl without running the full package suite."|>]];
