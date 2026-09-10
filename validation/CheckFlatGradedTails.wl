(* Focused graded flat-sector product tails and every flat-operation suite. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewFlatGradedTails.wlt", "FlatSectorOperations.wlt", "FlatSectorRegressions.wlt",
   "ExtendedIntegration.wlt", "NormalExpressions.wlt"},
 "Output" -> "flat-graded-tails-tests.json", "Timeout" -> 900,
 "Scope" -> "Five selected files: the new graded-tail tests, both flat-sector operation suites, and the integration and presentation suites that construct flat products; no full package suite."|>]];
