(* Explicitly selected regression files; never discovers the full suite.
   Run: wolfram.exe -script validation/CheckFormatting.wl
   ASYMPTOTIC_VALIDATION_OUTPUT overrides the default JSON report path. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"Formatting.wlt"},
  "Output" -> "formatting-tests.json", "Timeout" -> 600,
  "Scope" -> "One explicitly selected formatting and Normal regression file; the full package suite was not run."|>]];
