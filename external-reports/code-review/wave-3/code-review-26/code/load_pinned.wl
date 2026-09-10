(* Set $AuditPackageFile to a local standalone file before Get to work offline.
   This is explicit code loading: use only a trusted, inspected source. *)
$AuditCommit = "6687962f3c858a4f93623cfc496f33e35c6763d4";
$AuditBase = "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/" <> $AuditCommit <> "/";
If[! ValueQ[$AuditPackageFile],
  $AuditPackageFile = FileNameJoin[{$TemporaryDirectory, "AuditAsymptoticAnalysis.wl"}];
  With[{text = Import[$AuditBase <> "AsymptoticAnalysis.wl", "Text"]},
    If[! StringQ[text] || StringLength[text] < 500000,
      Print["Pinned source download failed or was incomplete."]; Abort[]];
    Export[$AuditPackageFile, text, "Text"]]];
Get[$AuditPackageFile];
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Print["Package loading did not establish the expected context."]; Abort[]];
