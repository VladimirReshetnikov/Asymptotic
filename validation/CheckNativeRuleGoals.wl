(* Focused native rule-goal and existing dispatch/evaluation contracts. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"NativeRuleGoals.wlt", "NativeSearch.wlt", "NativeAutomatic.wlt", "NativeCompatibility.wlt", "ReviewAssumptions.wlt"},
  "Output" -> "native-rule-goal-tests.json", "Timeout" -> 600,
  "Scope" -> "Five explicitly selected native rule-goal, search, automatic dispatch, explicit compatibility and assumption-scope files; no full package suite."|>]];
