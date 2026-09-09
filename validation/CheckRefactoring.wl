(* Selected coverage for shared sparse arithmetic, family normalization,
   native ingress, flat sectors and inverse refinement. Never discovers
   the full suite. ASYMPTOTIC_VALIDATION_OUTPUT overrides the report path. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"PerformanceRegressions.wlt", "CoreRefactoring.wlt",
    "IncrementalRegressions.wlt", "RefinementRegressions.wlt",
    "ReviewRegressions.wlt", "AsymptoticInverse.wlt", "NativeRefactoring.wlt",
    "NativeSpecialIngress.wlt", "SpecialFunctionForward.wlt", "FlatSectorOperations.wlt",
    "FamilyRefactoring.wlt", "GammaProducts.wlt", "GammaVaryingPowers.wlt",
    "GammaLogarithms.wlt", "BarnesGForward.wlt", "LogBarnesG.wlt", "Formatting.wlt"},
  "Output" -> "refactoring-tests.json", "Timeout" -> 600,
  "Scope" -> "Seventeen explicitly selected refactoring and adjacent regression files; the full package suite was not run."|>]];
