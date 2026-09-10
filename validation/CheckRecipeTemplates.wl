(* Focused P07 recipe-template check with the refinement, arithmetic and operation suites that share the recipe replay. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewProvenanceGrowth.wlt", "RefinementRegressions.wlt", "SeriesArithmetic.wlt", "SeriesOperations.wlt",
   "ReviewArithmeticBoundTransport.wlt", "ReviewCompositeApproach.wlt", "FlatSectorOperations.wlt",
   "SeriesEnvelopeArithmetic.wlt", "GeneralizedSeries.wlt", "ReviewCompositionScope.wlt", "CompositionRefactoring.wlt"},
 "Output" -> "recipe-template-tests.json", "Timeout" -> 900,
 "Scope" -> "Eleven selected files: the new provenance-growth regressions and the refinement, arithmetic, operation, bound-transport, composite, flat-sector, envelope, result and composition-scope suites that share the recipe replay and the scope walker; no full package suite."|>]];
