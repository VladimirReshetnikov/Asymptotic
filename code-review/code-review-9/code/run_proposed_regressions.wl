(* Run in a fresh kernel. This is a post-fix acceptance suite, not a claim
   that the original package passes it. Native execution was unavailable. *)
p = Environment["ASYMPTOTIC_AUDIT_PACKAGE"];
If[! StringQ[p] || ! FileExistsQ[p], Print["Missing ASYMPTOTIC_AUDIT_PACKAGE"]; Exit[2]];
Get[p];
If[Length[DownValues[AsymptoticInverse`AsymptoticExpansion]] == 0, Exit[2]];
suite = FileNameJoin[{DirectoryName[$InputFileName], "proposed_regressions.wlt"}];
report = TimeConstrained[MemoryConstrained[TestReport[suite], 512 1024^2, $Failed], 180, $Failed];
If[report === $Failed || Head[report] =!= TestReportObject, Print["Suite did not complete."]; Exit[2]];
Print[report];
If[report["TestsSucceededCount"] + report["TestsFailedCount"] == 0, Exit[2]];
Exit[If[report["TestsFailedCount"] == 0, 0, 1]];
