(* Native runner, supplied but NOT EXECUTED in this audit.
   Set ASYMPTOTIC_REPO to the local repository checkout.
   Optional ASYMPTOTIC_AUDIT_OUTPUT selects the output JSON.
   SPDX-License-Identifier: MIT-0 *)

root = Environment["ASYMPTOTIC_REPO"];
If[! StringQ[root] || root === "", Print["Set ASYMPTOTIC_REPO to the local checkout."]; Exit[2]];
entry = FileNameJoin[{root, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}];
suite = FileNameJoin[{DirectoryName[$InputFileName], "AuditRegressions.wlt"}];
If[! FileExistsQ[entry] || ! FileExistsQ[suite], Print["Missing package or audit suite."]; Exit[2]];
files = Join[FileNames["*.wl", DirectoryName[entry]], {suite, $InputFileName}];
hashes[] := Association[(# -> IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ files];
before = hashes[];
loaded = Check[Get[entry]; MemberQ[$Packages, "AsymptoticInverse`"], False];
If[! TrueQ[loaded], Print["The package did not load cleanly."]; Exit[2]];
{seconds, report} = AbsoluteTiming[TimeConstrained[
 TestReport[suite, ProgressReporting -> False], 600, $Aborted]];
output = Environment["ASYMPTOTIC_AUDIT_OUTPUT"];
If[! StringQ[output] || output === "", output = FileNameJoin[{DirectoryName[$InputFileName], "native-audit-results.json"}]];
If[Head[report] =!= TestReportObject,
 Export[output, <|"Status" -> "Aborted", "Kernel" -> $Version, "Seconds" -> seconds,
   "SourcesBefore" -> before|>, "RawJSON"]; Print["Suite aborted."]; Exit[1]];
results = Values[report["TestResults"]];
rows = (<|"TestID" -> #["TestID"], "Outcome" -> #["Outcome"],
  "ActualOutput" -> ToString[#["ActualOutput"], InputForm],
  "ExpectedOutput" -> ToString[#["ExpectedOutput"], InputForm],
  "ActualMessages" -> ToString[#["ActualMessages"], InputForm]|> &) /@ results;
unchanged = before === hashes[];
exported = Export[output, <|"Status" -> "Executed", "Kernel" -> $Version,
 "SystemID" -> $SystemID, "AuditSnapshot" -> "07a9781212beb2eeb9ff16aa625b50ac27974078",
 "Scope" -> "Eleven audit-specific native regressions; not the repository's complete suite.",
 "Seconds" -> seconds, "Succeeded" -> report["TestsSucceededCount"],
 "Failed" -> report["TestsFailedCount"], "Results" -> rows,
 "SourcesUnchangedDuringRun" -> unchanged, "SourceSHA256" -> before|>, "RawJSON"];
Print["Succeeded: ", report["TestsSucceededCount"], "; failed: ", report["TestsFailedCount"], "; output: ", output];
Exit[If[Length[results] > 0 && report["TestsFailedCount"] === 0 && unchanged && StringQ[exported], 0, 1]];
