(* Focused certificate-interval diagnostics and certificate acceptance controls. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"CertificateRegressions.wlt", "AcceptanceCertificates.wlt"},
 "Output" -> "certificate-interval-tests.json", "Timeout" -> 600,
 "Scope" -> "Two selected certificate files covering the omitted/malformed interval refusals and existing certificate contracts; no full package suite."|>]];
