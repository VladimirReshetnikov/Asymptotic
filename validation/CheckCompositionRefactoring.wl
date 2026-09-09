(* Selected real-composition and numerical-adapter regressions only. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"CompositionRefactoring.wlt", "ParameterizedSpecialFunctions.wlt",
    "SpecialFunctionRegressions.wlt", "NativeSpecialIngress.wlt",
    "SpecialFunctionForward.wlt", "SpecialFunctionIdentities.wlt"},
  "Output" -> "composition-refactoring-tests.json", "Timeout" -> 600,
  "Scope" -> "Six explicitly selected composition, branch and numerical-adapter regression files; the full package suite was not run."|>]];
