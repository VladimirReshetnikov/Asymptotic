(* Focused C22 arithmetic bound transport with the truncation, Dirichlet and arithmetic suites. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewArithmeticBoundTransport.wlt", "DirichletSpecialFunctions.wlt", "SeriesArithmetic.wlt",
   "SeriesOperations.wlt", "SeriesEnvelopeArithmetic.wlt", "NormalExpressions.wlt", "CertificateRegressions.wlt"},
 "Output" -> "arithmetic-bound-transport-tests.json", "Timeout" -> 900,
 "Scope" -> "Seven selected files: the new arithmetic bound-transport regressions, the Dirichlet, arithmetic, operation, envelope and normal-expression suites that share the binary operation path, and the certificate regressions including the affine memo; no full package suite."|>]];
