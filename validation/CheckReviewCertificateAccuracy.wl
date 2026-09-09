(* Review 18 N01 / C19 and adjacent exact certificate acceptance. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"ReviewCertificateAccuracy.wlt", "CertificateRegressions.wlt", "AcceptanceCertificates.wlt"},
  "Output" -> "review-certificate-accuracy-tests.json", "Timeout" -> 600,
  "Scope" -> "C19 certificate planning, arithmetic refinement, sharp bound, best-certificate retention, cap and budget semantics, with existing exact certificate regression and acceptance cases. The full package suite was not run."|>]];
