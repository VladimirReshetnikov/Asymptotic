(* Shared loader. Run in a fresh kernel. The upstream package is not bundled. *)
ClearAll[AuditGitBlob, AuditLoadPinned];
AuditCommit = "921387e5ba1239bfda96e63e64e89bf63d9c41e6";
AuditExpectedStandaloneBlob = "609eaae41eac2a0f00c9c898b22265375add4306";
AuditGitBlob[path_String] := Module[{bytes, header, tmp, stream, hash},
  bytes = BinaryReadList[path, "Byte"];
  header = Join[ToCharacterCode["blob " <> ToString[Length[bytes]], "ASCII"], {0}];
  tmp = CreateTemporary[];
  stream = OpenWrite[tmp, BinaryFormat -> True];
  BinaryWrite[stream, Join[header, bytes], "Byte"]; Close[stream];
  hash = FileHash[tmp, "SHA1", "HexString"];
  DeleteFile[tmp]; hash
];
AuditLoadPinned[] := Module[{provided, path, downloaded, hash, permitted, result},
  provided = Environment["ASYMPTOTIC_AUDIT_SOURCE"];
  downloaded = !(StringQ[provided] && StringLength[provided] > 0);
  path = If[downloaded,
    Quiet@Check[URLDownload["https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/" <>
      AuditCommit <> "/AsymptoticInverse.wl"], $Failed], provided];
  If[! StringQ[path] || ! FileExistsQ[path], Print["Package acquisition failed."]; Return[$Failed]];
  hash = AuditGitBlob[path];
  permitted = Environment["ASYMPTOTIC_AUDIT_ALLOW_MODIFIED"] === "1";
  If[hash =!= AuditExpectedStandaloneBlob && ! permitted,
    Print["Standalone Git blob mismatch: ", hash];
    If[downloaded, DeleteFile[path]]; Return[$Failed]];
  Print[ExportString[<|"kernel" -> $Version, "pinned_commit" -> AuditCommit,
    "standalone_git_blob" -> hash, "modified_source_override" -> permitted|>, "RawJSON"]];
  result = Check[Get[path], $Failed];
  If[downloaded, DeleteFile[path]];
  If[result === $Failed, $Failed, True]
];
If[AuditLoadPinned[] =!= True, Abort[]];
