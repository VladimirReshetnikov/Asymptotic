(* Focused numerical-check local-coordinate repair and cross-family numerical controls. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewNumericalLocalCoordinate.wlt", "AsymptoticInverse.wlt", "ReviewRegressions.wlt",
   "LambertRegressions.wlt", "LambertExtendedRegressions.wlt", "InverseFunctionDomainEvidence.wlt",
   "SourceCoordinateRegressions.wlt", "CoordinateRegressions.wlt", "SpecialFunctionRegressions.wlt",
   "ExtendedIntegration.wlt", "NativeContracts.wlt", "PackageIdentity.wlt"},
 "Output" -> "numerical-local-coordinate-tests.json", "Timeout" -> 900,
 "Scope" -> "Twelve selected files: the new local-coordinate numerical checks and every existing suite that calls InverseNumericalCheck on ordinary, Lambert, coordinate, special-function and native results; no full package suite."|>]];
