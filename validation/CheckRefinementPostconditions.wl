(* Focused C08/W3-07 refinement postconditions and P01/P05 budget checks with the suites that share replay, integer powers and logarithm canonicalization. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewRefinementPostconditions.wlt", "ReviewCanonicalBudgets.wlt", "RefinementRegressions.wlt",
   "ReviewProvenanceGrowth.wlt", "SeriesOperations.wlt", "SeriesArithmetic.wlt", "GeneralizedSeries.wlt",
   "AsymptoticInverse.wlt", "ReviewExponentEquality.wlt", "ReviewUnitPrecision.wlt", "CoreRefactoring.wlt",
   "FourierRegressions.wlt", "LogarithmicRefactoring.wlt", "ReviewLogPowerNormalization.wlt", "ReviewWave5Contracts.wlt",
   "DirichletSpecialFunctions.wlt", "ReviewArithmeticBoundTransport.wlt", "ReviewCompositionScope.wlt"},
 "Output" -> "refinement-postcondition-tests.json", "Timeout" -> 900,
 "Scope" -> "Eighteen selected files: the new refinement-postcondition and canonical-budget regressions and the refinement, provenance, operation, arithmetic, result, inverse, exponent, unit-precision, core, Fourier, logarithmic, normalization, wave-5, Dirichlet, bound-transport and composition-scope suites that share recipe replay, integer powers and logarithm canonicalization; no full package suite."|>]];
