(* Focused finite-value guards in every numerical consumer and certificate helper. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewNumericalLocalCoordinate.wlt", "AsymptoticInverse.wlt", "GammaInverse.wlt",
   "BarnesGInverse.wlt", "GammaInverseOperations.wlt", "LogBarnesG.wlt", "SpecialFunctionRegressions.wlt",
   "SourceCoordinateRegressions.wlt", "CoordinateRegressions.wlt", "CertificateRegressions.wlt",
   "AcceptanceCertificates.wlt", "ExtendedIntegration.wlt", "NativeContracts.wlt"},
 "Output" -> "finite-numeric-guards-tests.json", "Timeout" -> 900,
 "Scope" -> "Thirteen selected files exercising every numerical check route (ordinary, Gamma/Barnes, coordinate, source-chart, special adapter) and the certificate helpers after the finiteNumericQ guards; no full package suite."|>]];
