(* Focused truncation bound transport, Dirichlet forward contracts and series operation controls. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"DirichletSpecialFunctions.wlt", "SeriesOperations.wlt", "NormalExpressions.wlt",
   "ExtendedIntegration.wlt"},
 "Output" -> "truncation-bounds-tests.json", "Timeout" -> 900,
 "Scope" -> "Four selected Dirichlet special-function, series-operation, normal-expression and extended-integration files covering bound transport through SeriesTruncate; no full package suite."|>]];
