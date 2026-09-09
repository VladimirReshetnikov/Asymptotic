(* Explicit regression selection for the public result-head rename and
   coordinate, Fourier, exponential and inverse-check simplification. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"GeneralizedSeries.wlt", "CoordinateRefactoring.wlt",
    "FourierRefactoring.wlt", "InverseCheckRefactoring.wlt", "Formatting.wlt",
    "SeriesOperations.wlt", "SeriesArithmetic.wlt", "SeriesEnvelopeArithmetic.wlt",
    "CallableExpansion.wlt", "InverseFunctionExpressions.wlt", "SourceCoordinateRegressions.wlt",
    "FourierRegressions.wlt", "GammaInverse.wlt", "GammaInverseOperations.wlt",
    "BarnesGInverse.wlt", "ExponentialForward.wlt", "GammaVaryingPowers.wlt",
    "NormalExpressions.wlt"},
  "Output" -> "generalized-series-tests.json", "Timeout" -> 600,
  "Scope" -> "Eighteen explicitly selected result-head, simplification and adjacent regression files; the full package suite was not run."|>]];
