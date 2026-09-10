(* Focused wave-5 contract repairs and their nearest existing suites. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewWave5Contracts.wlt", "ReviewCoefficientPowerResidualLabel.wlt",
   "ReviewNumericalLocalCoordinate.wlt", "InverseCheckRefactoring.wlt", "ReviewInverseCoefficientModel.wlt",
   "GammaInverseOperations.wlt", "SpecialFunctionRegressions.wlt", "DirichletSpecialFunctions.wlt",
   "SeriesArithmetic.wlt", "AsymptoticInverse.wlt"},
 "Output" -> "wave5-contract-tests.json", "Timeout" -> 900,
 "Scope" -> "Ten selected files: the new wave-5 contract regressions and the coefficient, numerical-check, inverse-model, Gamma-operation, special-function, Dirichlet, arithmetic and ordinary-inverse suites that share the changed code; no full package suite."|>]];
