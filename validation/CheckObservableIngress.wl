(* Selected observable precision, sided approach and surrounding calculus contracts. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewObservableIngress.wlt", "SeriesOperations.wlt", "ReviewUnitPrecision.wlt",
    "ReviewRealCoefficients.wlt", "ReviewRecurrenceTermination.wlt", "AcceptanceCoordinatesCalculus.wlt"},
  "Output" -> "observable-ingress-tests.json", "Timeout" -> 600,
  "Scope" -> "Six explicitly selected observable native ingress, arithmetic, unit-tail, realness, recurrence and coordinate/calculus files; no full package suite."|>]];
