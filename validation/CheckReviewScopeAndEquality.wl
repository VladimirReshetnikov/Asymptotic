(* Focused R13 equal-exponent and parameter-scope regression acceptance. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewExponentEquality.wlt", "ReviewCompositionScope.wlt"},
  "Output" -> "review-scope-and-equality-tests.json", "Timeout" -> 600,
  "Scope" -> "R13/C14 exact equal-exponent collection and C15 composition with captured parameters. Independent exact identities and explicit diagonal examples; two selected files only. The full package suite was not run."|>]];
