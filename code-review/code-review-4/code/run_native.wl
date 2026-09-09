(* Run in a fresh native Wolfram kernel, not Mathics.
   Set ASYMPTOTIC_AUDIT_PACKAGE to an absolute modular or standalone .wl path.
   Optionally set ASYMPTOTIC_AUDIT_PATCHED=1 AFTER applying/rebuilding the patch.
   This script and its native tests were NOT RUN by the audit author. *)
Module[{path, root, files, report, payload, destination, text, patched, succeeded, failed, properties, groups, counts, allSucceeded, expected},
  path = Environment["ASYMPTOTIC_AUDIT_PACKAGE"];
  If[! StringQ[path] || ! FileExistsQ[path],
    Print["Set ASYMPTOTIC_AUDIT_PACKAGE to a local package file."]; Exit[2]];
  root = DirectoryName[DirectoryName[$InputFileName]];
  destination = FileNameJoin[{root, "evidence", "native-tests.json"}];
  patched = Environment["ASYMPTOTIC_AUDIT_PATCHED"] === "1";
  If[patched,
    text = Import[path, "Text"];
    If[! StringQ[text] || ! StringContainsQ[text, "Audit A02"] ||
       ! StringContainsQ[text, "DenseRepresentationTooLarge"],
      Print["Patched-only tests require the proposed A02 guard in the loaded file."]; Exit[2]]];
  Get[path];
  If[! MemberQ[$Packages, "AsymptoticInverse`"], Print["Package did not load."]; Exit[2]];
  files = {FileNameJoin[{root, "tests", "AuditRegressions.wlt"}]};
  If[patched, AppendTo[files, FileNameJoin[{root, "tests", "PatchedOnly.wlt"}]]];
  report = TimeConstrained[MemoryConstrained[TestReport[files], 512*1024^2, "MemoryLimit"], 180, "Timeout"];
  If[Head[report] =!= TestReportObject,
    Export[destination, <|"Status" -> "RunnerFailure", "Outcome" -> ToString[report, InputForm],
      "Version" -> $Version, "SystemID" -> $SystemID|>, "RawJSON"];
    Print["Suite did not finish: ", report]; Exit[2]];
  (* Use the current documented report contract; keep a legacy fallback. *)
  properties = report["Properties"];
  If[! ListQ[properties], Print["Cannot inspect TestReportObject properties."]; Exit[2]];
  If[MemberQ[properties, "ResultsByOutcome"],
    groups = report["ResultsByOutcome"];
    If[! AssociationQ[groups] || ! AllTrue[Values[groups], ListQ],
      Print["Unexpected ResultsByOutcome representation."]; Exit[2]];
    counts = Map[Length, groups];
    succeeded = Lookup[counts, "Success", 0] + Lookup[counts, "Succeeded", 0];
    failed = Total[Values[counts]] - succeeded,
    If[! And @@ (MemberQ[properties, #] & /@ {"TestsSucceededCount", "TestsFailedCount"}),
      Print["Unsupported native report schema."]; Exit[2]];
    succeeded = report["TestsSucceededCount"]; failed = report["TestsFailedCount"]];
  expected = If[patched, 11, 9];
  allSucceeded = TrueQ[succeeded === expected && failed === 0] &&
    If[MemberQ[properties, "ReportSucceeded"], TrueQ[report["ReportSucceeded"]], True];
  payload = <|"Version" -> $Version, "SystemID" -> $SystemID,
    "PackagePath" -> ExpandFileName[path],
    "LoadedEntrySHA256" -> IntegerString[FileHash[path, "SHA256"], 16, 64],
    "PatchedOnlyEnabled" -> patched, "ExpectedTestCount" -> expected, "TestsSucceededCount" -> succeeded,
    "TestsFailedCount" -> failed, "SuiteFiles" -> files,
    "Status" -> If[allSucceeded, "PASS", "FAIL"],
    "Scope" -> "Audit regression subset only; not the full upstream suite"|>;
  Export[destination, payload, "RawJSON"];
  Put[report, FileNameJoin[{root, "evidence", "native-tests.wl"}]];
  Print[payload];
  Exit[If[allSucceeded, 0, 1]]
]
