(* Selected arithmetic, inverse, Fourier, logarithmic and assumption neighbors
   of the R13/C14 exponent and C15 composition-scope repairs. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewExponentEquality.wlt", "ReviewCompositionScope.wlt",
    "ReviewUnitPrecision.wlt", "AsymptoticInverse.wlt", "GeneralizedSeries.wlt",
    "SeriesOperations.wlt", "SeriesArithmetic.wlt", "CompositionRefactoring.wlt",
    "FourierRefactoring.wlt", "FourierRegressions.wlt", "LogarithmicRefactoring.wlt",
    "ReciprocalLogOperations.wlt", "ReviewAssumptionReplay.wlt", "ReviewRealCoefficients.wlt",
    "NativeSpecialIngress.wlt"},
  "Output" -> "review-normalization-tests.json", "Timeout" -> 600,
  "Scope" -> "Fifteen explicitly selected files for exact equal-exponent collection, fixed-parameter composition scope, and affected ordinary/inverse/Fourier/logarithmic/native-special ingress paths. No full package suite or exhaustive native-coverage claim."|>]];
