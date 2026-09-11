(* Focused W3-01/W3-02 request-resolution checks with the native routing, contract, ingress and refinement suites that share the held entry. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewRequestResolution.wlt", "NativeAutomatic.wlt", "NativeRuleGoals.wlt", "NativeContracts.wlt",
   "NativeSearch.wlt", "NativeCompatibility.wlt", "NativeSpecialIngress.wlt", "NativePresentation.wlt",
   "ReviewObservableIngress.wlt", "ReviewAssumptions.wlt", "RefinementRegressions.wlt", "SeriesOperations.wlt",
   "ReviewCompositionScope.wlt", "InverseFunctionExpressions.wlt"},
 "Output" -> "request-resolution-tests.json", "Timeout" -> 900,
 "Scope" -> "Fourteen selected files: the new request-resolution regressions and the native routing, rule-goal, contract, search, compatibility, special-ingress, presentation, observable, assumption, refinement, operation, composition-scope and inverse-function suites that share the held expansion entry; no full package suite."|>]];
