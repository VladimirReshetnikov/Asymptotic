(* Selected Fourier composition termination, convolution, and ordinary recurrence controls. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewFourierTermination.wlt", "FourierRegressions.wlt",
    "FourierRefactoring.wlt", "ReviewRecurrenceTermination.wlt"},
  "Output" -> "fourier-termination-tests.json", "Timeout" -> 600,
  "Scope" -> "Four selected Fourier homogeneous termination, public residual, convolution and ordinary recurrence files; no full package suite."|>]];
