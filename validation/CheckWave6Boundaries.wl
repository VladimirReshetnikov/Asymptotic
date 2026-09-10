(* Focused wave-6 public-boundary repairs and their nearest existing suites. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewWave6Boundaries.wlt", "ReviewCoefficientPowerResidualLabel.wlt",
   "ExponentialCorePerturbation.wlt", "ReviewNumericalLocalCoordinate.wlt", "FourierRegressions.wlt",
   "SeriesOperations.wlt", "DirichletSpecialFunctions.wlt", "ExpandedInputs.wlt",
   "InverseFunctionExpressions.wlt", "ReviewObservableIngress.wlt"},
 "Output" -> "wave6-boundaries-tests.json", "Timeout" -> 900,
 "Scope" -> "Ten selected files: the new wave-6 boundary regressions and the coefficient, exponential-core, numerical-check, Fourier, observable, Dirichlet, expanded-input and inverse-function suites that share their code paths; no full package suite."|>]];
