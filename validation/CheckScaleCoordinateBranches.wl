(* Focused W3-12 scale-coordinate branch selection with the arithmetic, operation, envelope, special-function and refinement suites that share the coordinate rule. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewScaleCoordinateBranches.wlt", "SeriesArithmetic.wlt", "SeriesOperations.wlt",
   "SeriesEnvelopeArithmetic.wlt", "SeriesEnvelopeFunctions.wlt", "DirichletSpecialFunctions.wlt",
   "ReviewCompositeApproach.wlt", "FlatSectorOperations.wlt", "RefinementRegressions.wlt",
   "ReviewCompositionScope.wlt", "SpecialFunctionRegressions.wlt", "ReviewArithmeticBoundTransport.wlt"},
 "Output" -> "scale-coordinate-branch-tests.json", "Timeout" -> 900,
 "Scope" -> "Twelve selected files: the new scale-coordinate branch regressions and the arithmetic, operation, envelope, Dirichlet, composite, flat-sector, refinement, composition-scope, special-function and bound-transport suites that share the coordinate rule; no full package suite."|>]];
