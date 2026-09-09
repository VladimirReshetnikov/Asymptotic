(* C07: complete coefficient reality and preservation of real special-function paths. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewRealCoefficients.wlt", "ReviewAssumptions.wlt", "ReviewAssumptionReplay.wlt",
    "AsymptoticInverse.wlt", "SeriesOperations.wlt", "SeriesArithmetic.wlt",
    "CorePerturbation.wlt", "SourceCoordinateRegressions.wlt", "NativeSpecialIngress.wlt",
    "ParameterizedSpecialFunctions.wlt", "SpecialFunctionForward.wlt"},
  "Output" -> "review-real-coefficients-tests.json", "Timeout" -> 600,
  "Scope" -> "Eleven explicitly selected coefficient-reality, assumptions, ordinary inverse, series arithmetic/operations, core/source coordinate and special-function regression files; the full package suite was not run."|>]];
