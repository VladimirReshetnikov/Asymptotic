(* Focused checks for the last register items: source admission (C16), the polynomial monotonicity certificate (43 E01) and the equivalent-request catalog (B04), with the inverse-function, native, request-resolution, operation, observable and special-function suites that share the generic native jet and the branch validator. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewSourceAdmission.wlt", "ReviewPolynomialMonotonicity.wlt", "ReviewEquivalentRequests.wlt",
   "InverseFunctionBranches.wlt", "InverseFunctionExpressions.wlt", "InverseFunctionSyntax.wlt", "InverseFunctionIntegration.wlt",
   "InverseFunctionDomainEvidence.wlt", "NativeCompatibility.wlt", "NativeAutomatic.wlt", "ReviewRequestResolution.wlt",
   "SeriesOperations.wlt", "ExpandedInputs.wlt", "ReviewObservableIngress.wlt", "ParameterizedSpecialFunctions.wlt",
   "DirichletSpecialFunctions.wlt", "ReviewProofContext.wlt", "CallableExpansion.wlt"},
 "Output" -> "remaining-items-tests.json", "Timeout" -> 900,
 "Scope" -> "Eighteen selected files: the three new suites (source admission, polynomial monotonicity certificate, equivalent-request catalog) and the inverse-function, native, request-resolution, operation, expanded-input, observable, special-function, proof-context and callable suites that share the generic native jet and the branch validator; no full package suite."|>]];
