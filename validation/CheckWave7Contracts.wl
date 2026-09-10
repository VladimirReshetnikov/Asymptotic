(* Focused wave-7 contract repairs and their nearest existing suites. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewWave7Contracts.wlt", "SeriesEnvelopeArithmetic.wlt", "SeriesEnvelopeFunctions.wlt",
   "EnvelopeRefactoring.wlt", "CorePerturbation.wlt", "CoreRefactoring.wlt", "SpecialFunctionRegressions.wlt",
   "InverseFunctionExpressions.wlt", "ReviewObservableIngress.wlt", "SeriesOperations.wlt",
   "CertificateRegressions.wlt", "AcceptanceCertificates.wlt"},
 "Output" -> "wave7-contract-tests.json", "Timeout" -> 900,
 "Scope" -> "Twelve selected files: the new wave-7 contract regressions and the composite-envelope, core-perturbation, special-function, inverse-function, observable, operation and certificate suites that share the changed code; no full package suite."|>]];
