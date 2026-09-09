(* Usage: set ASYMPTOTIC_REPO to a LOCAL checkout, then start a fresh kernel:
   wolframscript -file code/RunNativeAudit.wl
   or wolfram.exe -noinit -script code/RunNativeAudit.wl
   No network fetch, installation, or repository mutation is performed.
   NOT EXECUTED by this audit. The tests specify corrected behavior, so some
   baseline failures and the unimplemented F05/F06 failures are expected. *)
Module[{repo, here, loader, tests, sources, hashes, before, after, report,
        passed, failed, summary, out, exported, reportPath},
 repo = Environment["ASYMPTOTIC_REPO"];
 If[! StringQ[repo] || ! DirectoryQ[repo],
  Print["Set ASYMPTOTIC_REPO to a local checkout of the reviewed commit."]; Exit[2]];
 If[MemberQ[$Packages, "AsymptoticInverse`"],
  Print["Start a fresh kernel: the package is already loaded."]; Exit[2]];
 here = DirectoryName[$InputFileName];
 loader = FileNameJoin[{repo, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}];
 tests = FileNameJoin[{here, "RegressionCandidates.wlt"}];
 If[! FileExistsQ[loader] || ! FileExistsQ[tests], Print["Required file missing."]; Exit[2]];
 sources = Sort[Join[FileNames["*.wl", DirectoryName[loader]], {tests}]];
 hashes[] := AssociationMap[FileHash[#, "SHA256", "HexString"] &, sources];
 before = hashes[];
 Get[loader];
 If[! MemberQ[$Packages, "AsymptoticInverse`"], Print["Package failed to load."]; Exit[2]];
 report = TestReport[tests];
 passed = report["TestsSucceededCount"]; failed = report["TestsFailedCount"];
 If[! IntegerQ[passed] || ! IntegerQ[failed] || passed + failed == 0,
  Print["No usable nonempty test report was returned."]; Exit[2]];
 after = hashes[];
 summary = <|"WolframVersion" -> $Version, "SystemID" -> $SystemID,
   "ReviewedBaselineCommit" -> "07a9781212beb2eeb9ff16aa625b50ac27974078",
   "PinMeaning" -> "Reference baseline; hashes below identify the files actually executed, including any local patches",
   "SourceHashesBefore" -> before, "SourceHashesAfter" -> after,
   "HashesUnchanged" -> (before === after),
   "TestsSucceeded" -> passed, "TestsFailed" -> failed,
   "Scope" -> "Audit regression candidates; not the repository full test suite"|>;
 out = FileNameJoin[{here, "..", "results", "native-audit-summary.json"}];
 exported = Export[out, summary, "RawJSON"];
 reportPath = FileNameJoin[{here, "..", "results", "native-audit-report.wl"}];
 Put[report, reportPath];
 If[! StringQ[exported] || ! FileExistsQ[out] || ! FileExistsQ[reportPath],
  Print["Failed to write the native audit results."]; Exit[2]];
 Print[summary];
 Exit[If[failed === 0 && before === after, 0, 1]]
];
