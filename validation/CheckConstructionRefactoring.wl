(* Only logarithmic construction and envelope arithmetic changed. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"LogarithmicRefactoring.wlt", "EnvelopeRefactoring.wlt",
    "LogarithmicScales.wlt", "ReciprocalLogOperations.wlt", "SeriesEnvelopeArithmetic.wlt",
    "SeriesEnvelopeFunctions.wlt", "SeriesArithmetic.wlt", "GeneralizedSeries.wlt"},
  "Output" -> "construction-refactoring-tests.json", "Timeout" -> 600,
  "Scope" -> "Eight explicitly selected logarithmic, envelope and adjacent regression files; the full package suite was not run."|>]];
