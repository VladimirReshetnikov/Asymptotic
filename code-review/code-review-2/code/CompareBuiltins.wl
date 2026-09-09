(* Experimental comparison runner; NOT EXECUTED by this audit.
   Run in a fresh kernel. Set ASYMPTOTIC_REPO to the pinned local checkout.
   Every returned expression and remainder must be checked before comparing
   times: equal-looking orders do NOT imply equal asymptotic precision. *)
Module[{repo, loader, here, cases, one, all, rounds = 3, seconds = 30,
        bytes = 512*1024^2, x, y, sources, hashes, before, after, out, exported},
 repo = Environment["ASYMPTOTIC_REPO"];
 If[! StringQ[repo] || ! DirectoryQ[repo], Print["Set ASYMPTOTIC_REPO."]; Exit[2]];
 If[MemberQ[$Packages, "AsymptoticInverse`"], Print["Start a fresh kernel: package already loaded."]; Exit[2]];
 here = DirectoryName[$InputFileName];
 loader = FileNameJoin[{repo, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}];
 If[! FileExistsQ[loader], Print["Package source missing."]; Exit[2]];
 sources = Sort[FileNames["*.wl", DirectoryName[loader]]];
 hashes[] := AssociationMap[FileHash[#, "SHA256", "HexString"] &, sources];
 before = hashes[];
 Get[loader];
 If[! MemberQ[$Packages, "AsymptoticInverse`"], Print["Package failed to load."]; Exit[2]];
 cases = <|
  "native-analytic-series" -> HoldComplete[System`Series[Sin[x], {x, 0, 9}]],
  "package-analytic-series" -> HoldComplete[AsymptoticInverse`AsymptoticExpansion[Sin[x], {x, 0, 10}]],
  "native-log-series" -> HoldComplete[System`Series[Log[1 + x Log[x]], {x, 0, 4}]],
  "package-log-series" -> HoldComplete[AsymptoticInverse`AsymptoticExpansion[Log[1 + x Log[x]], {x, 0, 5}]],
  "native-irrational-forward" -> HoldComplete[System`Asymptotic[Exp[x^Sqrt[2] + x^Sqrt[3]], x -> 0, SeriesTermGoal -> 6]],
  "package-irrational-forward" -> HoldComplete[AsymptoticInverse`AsymptoticExpansion[Exp[x^Sqrt[2] + x^Sqrt[3]], {x, 0}, SeriesTermGoal -> 6]],
  "native-quadratic-inverse" -> HoldComplete[System`InverseSeries[System`Series[x + x^2, {x, 0, 6}], y]],
  "package-quadratic-inverse" -> HoldComplete[AsymptoticInverse`AsymptoticInverse[x + x^2, {x, 0}, {y, 7}]],
  "native-irrational-inverse" -> HoldComplete[System`AsymptoticSolve[x + x^Sqrt[2] + x^Sqrt[3] == y, x -> 0, {y, 0, 5}, Reals]],
  "package-irrational-inverse" -> HoldComplete[AsymptoticInverse`AsymptoticInverse[x + x^Sqrt[2] + x^Sqrt[3], {x, 0}, y, SeriesTermGoal -> 5]],
  "native-gamma-ratio" -> HoldComplete[System`Asymptotic[Gamma[x + 1/3]/Gamma[x + 2/3], x -> Infinity, SeriesTermGoal -> 4]],
  "package-gamma-ratio" -> HoldComplete[AsymptoticInverse`AsymptoticExpansion[Gamma[x + 1/3]/Gamma[x + 2/3], {x, Infinity}, SeriesTermGoal -> 4]],
  "native-gamma-inverse" -> HoldComplete[System`AsymptoticSolve[LogGamma[x] == y, x -> Infinity, {y, Infinity, 3}, Reals]],
  "package-gamma-inverse" -> HoldComplete[AsymptoticInverse`AsymptoticInverse[LogGamma[x], {x, Infinity}, y, SeriesTermGoal -> 3]],
  "native-bessel" -> HoldComplete[System`Asymptotic[BesselJ[0, x], x -> Infinity, SeriesTermGoal -> 4]],
  "package-bessel" -> HoldComplete[AsymptoticInverse`AsymptoticExpansion[BesselJ[0, x], {x, Infinity}, SeriesTermGoal -> 4]]
 |>;
 one[held_] := Module[{value, elapsed, status, messages},
  Block[{$MessageList = {}},
   {elapsed, value} = AbsoluteTiming[
    TimeConstrained[MemoryConstrained[ReleaseHold[held], bytes, "AuditMemoryLimit"], seconds, "AuditTimeLimit"]];
   messages = ToString[#, InputForm] & /@ $MessageList];
  status = Which[value === "AuditTimeLimit", "TimeLimit",
   value === "AuditMemoryLimit", "MemoryLimit", FailureQ[value], "Failure",
   ! FreeQ[value, _System`Series | _System`Asymptotic | _System`AsymptoticSolve | _System`InverseSeries], "Unresolved",
   True, "ReturnedRequiresInspection"];
  <|"Seconds" -> elapsed, "Status" -> status, "Messages" -> messages,
    "LeafCount" -> LeafCount[value], "ByteCount" -> ByteCount[value],
    "ValueInputForm" -> ToString[value, InputForm],
    "NormalInputForm" -> ToString[Normal[value], InputForm],
    "RemainderInputForm" -> If[MatchQ[value, _AsymptoticInverse`GeneralizedSeries],
      ToString[value["Remainder"], InputForm], "Inspect native result"]|>];
 all = Association[KeyValueMap[Function[{name, held},
   name -> <|"Warmup" -> one[held], "Measured" -> Table[one[held], {rounds}]|>], cases]];
 after = hashes[];
 out = FileNameJoin[{here, "..", "results", "native-comparison.json"}];
 exported = Export[out,
  <|"Version" -> $Version, "SystemID" -> $SystemID,
    "ReviewedBaselineCommit" -> "07a9781212beb2eeb9ff16aa625b50ac27974078",
    "SourceHashesBefore" -> before, "SourceHashesAfter" -> after,
    "HashesUnchanged" -> (before === after),
    "Warning" -> "Unmatched order conventions; inspect semantic equality before timing comparisons",
    "SecondsPerCaseLimit" -> seconds, "BytesPerCaseLimit" -> bytes, "Cases" -> all|>, "RawJSON"];
 If[! StringQ[exported] || ! FileExistsQ[out], Print["Failed to export results."]; Exit[2]];
 Print["Wrote results/native-comparison.json"];
 Exit[If[before === after, 0, 1]]
];
