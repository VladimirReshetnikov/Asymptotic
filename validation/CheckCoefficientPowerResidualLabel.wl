(* Focused coefficient power precedence, residual offset label, and their consumers. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewCoefficientPowerResidualLabel.wlt", "ReviewInverseCoefficientModel.wlt",
   "AsymptoticInverse.wlt", "ExpandedInputs.wlt", "ReviewAssumptions.wlt", "IncrementalRegressions.wlt"},
 "Output" -> "coefficient-power-residual-label-tests.json", "Timeout" -> 600,
 "Scope" -> "Six selected files: the new precedence and label tests, the coefficient-model admission suite, and ordinary inverse, expanded-input, assumption and incremental suites that read coefficients or residuals; no full package suite."|>]];
