(* Native runner supplied for future execution. NOT EXECUTED in this audit.
   ASYMPTOTIC_AUDIT_ROOT: local repository checkout (required).
   ASYMPTOTIC_AUDIT_OUTPUT: output JSON (optional).
   ASYMPTOTIC_AUDIT_FULL_SUITE=1: also discover all repository .wlt files.
   Run in a fresh kernel: wolframscript -file code/run_audit.wls *)
auditBundle = DirectoryName[DirectoryName[$InputFileName]];
root = Environment["ASYMPTOTIC_AUDIT_ROOT"];
If[! StringQ[root] || root === "", Print["Set ASYMPTOTIC_AUDIT_ROOT to a local checkout."]; Exit[2]];
root = ExpandFileName[root];
kernel = FileNameJoin[{root, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}];
If[! FileExistsQ[kernel], Print["Canonical kernel file not found: ", kernel]; Exit[2]];
If[$VersionNumber < 15, Print["The audited package declares Wolfram Language 15.0+."]; Exit[2]];
sourceFiles = Sort[FileNames["*.wl", DirectoryName[kernel]]];
sourceHash[] := Association[(# -> IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ sourceFiles];
before = sourceHash[];
If[Check[Get[kernel], $Failed] === $Failed || ! MemberQ[$Packages, "AsymptoticInverse`"],
 Print["Package load failed."]; Exit[2]];
suites = {FileNameJoin[{auditBundle, "tests", "audit_regressions.wlt"}]};
If[Environment["ASYMPTOTIC_AUDIT_FULL_SUITE"] === "1",
 suites = Join[Sort[FileNames["*.wlt", FileNameJoin[{root, "AsymptoticInverse", "Tests"}], Infinity]], suites]];
results = Table[
 Print["Running ", file];
 {elapsed, report} = AbsoluteTiming[TimeConstrained[TestReport[file, ProgressReporting -> False], 300, $Aborted]];
 If[Head[report] =!= TestReportObject,
  <|"Suite" -> file, "Succeeded" -> 0, "Failed" -> 1, "Seconds" -> elapsed, "Outcome" -> "AbortedOrInvalidReport"|>,
  <|"Suite" -> file, "Succeeded" -> report["TestsSucceededCount"],
   "Failed" -> report["TestsFailedCount"] + If[Length[report["TestResults"]] == 0, 1, 0], "Seconds" -> elapsed,
   "Results" -> Map[Function[t, <|"TestID" -> t["TestID"], "Outcome" -> t["Outcome"],
      "ExpectedOutput" -> ToString[t["ExpectedOutput"], InputForm],
      "ActualOutput" -> ToString[t["ActualOutput"], InputForm],
      "ActualMessages" -> ToString[t["ActualMessages"], InputForm]|>], Values[report["TestResults"]]]|>],
 {file, suites}];
unchanged = before === sourceHash[];
failed = Total[Lookup[results, "Failed"]] + If[unchanged, 0, 1];
output = Environment["ASYMPTOTIC_AUDIT_OUTPUT"];
If[! StringQ[output] || output === "", output = FileNameJoin[{auditBundle, "evidence", "native_audit_results.json"}]];
exported = Export[output, <|"Kernel" -> $Version, "SystemID" -> $SystemID,
 "AuditReferenceCommit" -> "07a9781212beb2eeb9ff16aa625b50ac27974078",
 "NativeWolframExecuted" -> True, "FullSuiteRequested" -> (Environment["ASYMPTOTIC_AUDIT_FULL_SUITE"] === "1"),
 "Note" -> "A01/A02/A04 tests target corrected behavior; A03-strict tests a proposed export policy. Source hashes identify the actual tested files, not necessarily the reference commit.",
 "SourcesUnchangedDuringRun" -> unchanged, "SourceSHA256" -> before,
 "Succeeded" -> Total[Lookup[results, "Succeeded"]], "Failed" -> failed, "Suites" -> results|>, "RawJSON"];
Print["Failures: ", failed, "; report: ", output];
Exit[If[failed == 0 && StringQ[exported], 0, 1]];
