(* Uses the documented TestReportObject["ReportSucceeded"] property.
   Usage:
   Set ASYMPTOTIC_AUDIT_ROOT to a local checkout of the pinned repository.
   wolframscript -file code/RunAudit.wls
   Runs desired-behavior regressions; failures on the baseline are expected.
   The patch proposal does not implement F04, so that test remains a request. *)
auditRoot = Environment["ASYMPTOTIC_AUDIT_ROOT"];
If[! StringQ[auditRoot] || ! DirectoryQ[auditRoot],
 Print["Set ASYMPTOTIC_AUDIT_ROOT to a local repository checkout."]; Exit[2]];
auditHere = DirectoryName[$InputFileName];
auditPackage = FileNameJoin[{auditRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}];
If[! FileExistsQ[auditPackage], Print["Package entry not found: ", auditPackage]; Exit[2]];
Get[auditPackage];
auditReport = TestReport[FileNameJoin[{auditHere, "AuditRegressions.wlt"}]];
Put[<|"WolframVersion" -> $Version, "SystemID" -> $SystemID,
  "PackageFileSHA256" -> FileHash[auditPackage, "SHA256", "HexString"],
  "Report" -> auditReport|>, "audit-native-report.wl"];
Print[auditReport];
Get[FileNameJoin[{auditHere, "ProbeNativeTail.wls"}]];
Exit[If[TrueQ[auditReport["ReportSucceeded"]], 0, 1]];
