(* Shared runner support. No network retrieval; review and supply a local package.
   Native runners were NOT executed during this audit. *)
auditRoot = DirectoryName[DirectoryName[$InputFileName]];
auditPackage = Environment["ASYMPTOTIC_AUDIT_PACKAGE"];
If[! StringQ[auditPackage] || ! FileExistsQ[auditPackage],
  Print["Set ASYMPTOTIC_AUDIT_PACKAGE to an existing local standalone or modular kernel entry."]; Exit[2]];
auditPackage = ExpandFileName[auditPackage];
auditLoad = TimeConstrained[MemoryConstrained[Check[Get[auditPackage];
  MemberQ[$Packages, "AsymptoticInverse`"], False], 1024^3, False], 90, False];
If[! TrueQ[auditLoad], Print["Package load failed or exceeded the audit load budget."]; Exit[2]];
Get[FileNameJoin[{auditRoot, "proposals", "AuditSupport.wl"}]];
SetAttributes[auditProbe, HoldAllComplete];
auditProbe[id_String, expression_] := Module[{value, elapsed, messages},
  Block[{$Assumptions = True, $MessageList = {}},
    {elapsed, value} = AbsoluteTiming[TimeConstrained[
      MemoryConstrained[expression, 512*1024^2,
        Failure["AuditMemoryLimit", <||>]], 45,
      Failure["AuditTimeLimit", <||>]]];
    messages = ToString[#, InputForm] & /@ $MessageList];
  <|"ID" -> id, "Seconds" -> elapsed, "Result" -> ToString[value, InputForm, PageWidth -> Infinity],
    "Messages" -> messages|>];
auditMetadata[] := <|"ExpectedCommit" -> "921387e5ba1239bfda96e63e64e89bf63d9c41e6",
  "CommitVerified" -> False, "PackageEntry" -> auditPackage,
  "EntrySHA256" -> IntegerString[FileHash[auditPackage, "SHA256"], 16, 64],
  "EntryHashScope" -> "Only this file; modular companion files are not attested by this hash.",
  "Version" -> $Version, "SystemID" -> $SystemID, "Date" -> DateString[]|>;
auditWrite[name_, value_] := Module[{dest = FileNameJoin[{auditRoot, "evidence", name}]},
  If[FileExistsQ[dest], Print["Refusing to overwrite ", dest]; Exit[2]];
  If[Export[dest, value, "RawJSON"] === $Failed, Exit[2]];
  Print[dest]];
auditApproach[s_] := AsymptoticInverse`Private`catch[
  AsymptoticInverse`Private`seriesEnvelopeApproach[s[[1]], 20000]];
auditTail[s_] := Cases[s["SectorRemainder"],
  AsymptoticInverse`PowerLogRemainder[_, p_, d_] :> {p, d}, {0, Infinity}];
