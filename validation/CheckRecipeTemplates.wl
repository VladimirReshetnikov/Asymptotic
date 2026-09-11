(* Focused P07 recipe-template check with the refinement, arithmetic and operation suites that share the recipe replay. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewProvenanceGrowth.wlt", "RefinementRegressions.wlt", "SeriesArithmetic.wlt", "SeriesOperations.wlt",
   "ReviewArithmeticBoundTransport.wlt", "ReviewCompositeApproach.wlt", "FlatSectorOperations.wlt",
   "SeriesEnvelopeArithmetic.wlt", "GeneralizedSeries.wlt", "ReviewCompositionScope.wlt", "CompositionRefactoring.wlt",
   "ReviewProofContext.wlt", "DirichletSpecialFunctions.wlt", "GammaForward.wlt", "ReviewAssumptions.wlt"},
 "Output" -> "recipe-template-tests.json", "Timeout" -> 900,
 "Scope" -> "Fifteen selected files: the provenance-growth and proof-context regressions and the refinement, arithmetic, operation, bound-transport, composite, flat-sector, envelope, result, composition-scope, Dirichlet, Gamma and assumption suites that share the recipe replay, the scope walker and the proof context; no full package suite."|>]];
