(* Shared loader for bounded audit scripts. Loading external source executes it;
   only the pinned hash is accepted unless the caller explicitly opts out. *)
ClearAll[AuditLoad, AuditLoadFromCommandLine];
$AuditCommit = "07a9781212beb2eeb9ff16aa625b50ac27974078";
$AuditSHA256 = "b2aebac8176649ff53634816f17e92c8f0ccb397f7606a5ac819b6f157b6d7ed";
AuditLoad[given_: Automatic, allowModified_: False] := Module[{path = given, hash},
  If[path === Automatic, path = Quiet[Check[Replace[TimeConstrained[
    URLDownload["https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/" <>
      $AuditCommit <> "/AsymptoticInverse.wl"], 45, $Failed], File[p_] :> p], $Failed]]];
  If[! StringQ[path] || ! FileExistsQ[path],
    Return[Failure["DownloadOrPath", <|"Path" -> path|>], Module]];
  hash = IntegerString[FileHash[path, "SHA256"], 16, 64];
  If[hash =!= $AuditSHA256 && ! TrueQ[allowModified],
    Return[Failure["UnexpectedSource", <|"SHA256" -> hash|>], Module]];
  Get[path];
  If[Length[DownValues[AsymptoticInverse`AsymptoticExpansion]] === 0,
    Return[Failure["PackageLoad", <|"Path" -> path|>], Module]];
  <|"Kernel" -> $Version, "SystemID" -> $SystemID, "SourcePath" -> path,
    "SourceSHA256" -> hash, "ReviewedSource" -> (hash === $AuditSHA256)|>
];
AuditLoadFromCommandLine[] := Module[{args, paths},
  args = If[ListQ[$ScriptCommandLine], $ScriptCommandLine, {}];
  paths = Select[args, StringQ[#] && ! StringStartsQ[#, "-"] &&
      ToLowerCase[FileExtension[#]] === "wl" &&
      ExpandFileName[#] =!= $AuditCallerPath &];
  If[Length[paths] > 1, Return[Failure["Arguments", <|
    "MessageTemplate" -> "Supply at most one local standalone .wl source.",
    "Paths" -> paths|>], Module]];
  AuditLoad[If[paths === {}, Automatic, First[paths]], MemberQ[args, "--allow-modified"]]
];
