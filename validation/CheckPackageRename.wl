(* Focused package/context rename acceptance, including the preceding native
   and certificate milestones. Historical reports use separate output files. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"PackageIdentity.wlt", "NativeAutomatic.wlt", "NativeCompatibility.wlt",
    "NativeContracts.wlt", "NativePresentation.wlt", "ReviewAssumptionReplay.wlt",
    "ReviewRealCoefficients.wlt", "InverseFunctionIntegration.wlt", "InverseFunctionSyntax.wlt",
    "ReviewCertificateAccuracy.wlt", "CertificateRegressions.wlt", "AcceptanceCertificates.wlt"},
  "Output" -> "package-rename-tests.json", "Timeout" -> 600,
  "Scope" -> "Twelve explicitly selected files covering renamed package/context identity, automatic and explicit native contracts, held evaluation, assumptions, coefficient reality, inverse callable syntax, and exact certificates. The public AsymptoticInverse function retains its name. The full package suite was not run."|>]];
