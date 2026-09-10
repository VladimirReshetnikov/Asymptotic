(* Focused C18 composite target-chart derivation and D10 refinement policy with their neighbouring suites. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewCompositeApproach.wlt", "RefinementRegressions.wlt", "SeriesEnvelopeArithmetic.wlt",
   "SeriesEnvelopeFunctions.wlt", "EnvelopeRefactoring.wlt", "FlatSectorOperations.wlt",
   "SpecialFunctionRegressions.wlt", "ReviewRegressions.wlt"},
 "Output" -> "composite-approach-tests.json", "Timeout" -> 900,
 "Scope" -> "Eight selected files: the new composite-approach regressions, the refinement regressions including the lower-cutoff policy, and the envelope, flat-sector, special-function and review suites that share the composite fallback; no full package suite."|>]];
