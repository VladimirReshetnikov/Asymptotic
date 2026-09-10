(* Loader for a fresh Wolfram Language 15.0+ kernel.
   Loading downloaded/local WL code executes it. Review the source first. *)
$AuditCommit = "6687962f3c858a4f93623cfc496f33e35c6763d4";
$AuditURL = "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/" <>
  $AuditCommit <> "/AsymptoticAnalysis.wl";
$AuditLocalSource = Environment["ASYMPTOTIC_AUDIT_SOURCE"];
If[StringQ[$AuditLocalSource] && StringLength[$AuditLocalSource] > 0,
  If[!FileExistsQ[$AuditLocalSource], Print["Local source not found."]; Exit[2]];
  $AuditSourceDescription = <|"LocalSource" -> $AuditLocalSource,
    "VersionVerifiedByLoader" -> False|>;
  Get[$AuditLocalSource],
  $AuditText = TimeConstrained[Import[$AuditURL, "Text"], 30, $Failed];
  If[!StringQ[$AuditText] || StringLength[$AuditText] < 1000,
    Print["Pinned source download did not complete."]; Exit[2]];
  $AuditTemporary = CreateTemporary[];
  Export[$AuditTemporary, $AuditText, "Text"];
  Get[$AuditTemporary]; DeleteFile[$AuditTemporary];
  $AuditSourceDescription = <|"URL" -> $AuditURL, "Commit" -> $AuditCommit|>];
If[DownValues[AsymptoticAnalysis`AsymptoticExpansion] === {},
  Print["Package entry point was not loaded."]; Exit[2]];
Clear[$AuditText];
