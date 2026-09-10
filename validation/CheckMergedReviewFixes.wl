(* Recheck affected native contracts after merging the Mathics-only bootstrap.
   Explicit union of the normalization and native-search selections, plus
   package identity; no discovery or full regression-suite invocation. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"PackageIdentity.wlt", "ReviewExponentEquality.wlt", "ReviewCompositionScope.wlt",
    "ReviewUnitPrecision.wlt", "AsymptoticInverse.wlt", "GeneralizedSeries.wlt",
    "SeriesOperations.wlt", "SeriesArithmetic.wlt", "CompositionRefactoring.wlt",
    "FourierRefactoring.wlt", "FourierRegressions.wlt", "LogarithmicRefactoring.wlt",
    "ReciprocalLogOperations.wlt", "ReviewAssumptionReplay.wlt", "ReviewRealCoefficients.wlt",
    "NativeSpecialIngress.wlt", "NativeSearch.wlt", "NativeAutomatic.wlt",
    "NativeCompatibility.wlt", "NativeContracts.wlt", "NativePresentation.wlt",
    "InverseFunctionIntegration.wlt", "InverseFunctionSyntax.wlt"},
  "Output" -> "review-normalization-merge-tests.json", "Timeout" -> 600,
  "Scope" -> "Twenty-three selected native Wolfram suites after merging the Mathics-only bootstrap. Deduplicated union of normalization/composition and native-search tests plus package identity. Mathics execution and full native input coverage are not established; the full package suite was not run."|>]];
