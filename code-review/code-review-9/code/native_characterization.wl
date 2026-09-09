(* Native characterization probes. NOT EXECUTED in the audit session.
   Set ASYMPTOTIC_AUDIT_PACKAGE to the pinned standalone file or modular entry.
   No network download and no repository writes are performed by this runner. *)
package = Environment["ASYMPTOTIC_AUDIT_PACKAGE"];
If[! StringQ[package] || ! FileExistsQ[package],
  Print["Set ASYMPTOTIC_AUDIT_PACKAGE to a local pinned package file."]; Exit[2]];
Get[package];
If[Length[DownValues[AsymptoticInverse`AsymptoticExpansion]] == 0,
  Print["Package loading failed."]; Exit[2]];
Clear[x, y, a, f];

compactResult[result_] := Which[
  MatchQ[result, AsymptoticInverse`GeneralizedSeries[_Association]],
    <|"Status" -> "GeneralizedSeries", "Expression" -> ToString[Normal[result], InputForm],
      "Remainder" -> ToString[result["Remainder"], InputForm],
      "RemainderPower" -> ToString[result["RemainderPower"], InputForm],
      "Cutoff" -> ToString[result["Cutoff"], InputForm],
      "TargetDomain" -> ToString[result["TargetDomain"], InputForm],
      "Kind" -> ToString[result["Kind"], InputForm]|>,
  FailureQ[result], <|"Status" -> "Failure", "Result" -> ToString[result, InputForm]|>,
  True, <|"Status" -> "Other", "Result" -> ToString[result, InputForm]|>];

probe[id_, held_HoldComplete] := Module[{r, elapsed, messages},
  Block[{$MessageList = {}},
    {elapsed, r} = AbsoluteTiming[TimeConstrained[
      MemoryConstrained[ReleaseHold[held], 256 1024^2,
        Failure["AuditMemoryLimit", <||>]], 20,
      Failure["AuditTimeLimit", <||>]]];
    messages = ToString[#, InputForm] & /@ $MessageList];
  Join[<|"ID" -> id, "Input" -> ToString[held, InputForm],
    "Seconds" -> elapsed, "Messages" -> messages|>, compactResult[r]]];

cases = {
  {"baseline-inverse", HoldComplete[
    AsymptoticInverse`AsymptoticInverse[x + x^2, {x, 0}, {y, 5}]]},
  {"F01-small-dense-bridge", HoldComplete[
    AsymptoticInverse`AsymptoticExpansion[1 + x^(1/997) + x, {x, 0, 1}]]},
  {"F02-integer-power-low-cutoff", HoldComplete[
    AsymptoticInverse`AsymptoticExpansion[(1 + x)^256, {x, 0, 3}, "MaxTerms" -> 200]]},
  {"F03-Newton-index-budget", HoldComplete[
    AsymptoticInverse`AsymptoticInverse[x (1 + Sum[x^(1 + j/1000), {j, 1, 24}]),
      {x, 0}, {y, 5}, Method -> "Newton"]]},
  {"F03-grouped-index-budget", HoldComplete[
    AsymptoticInverse`AsymptoticInverse[x (1 + Sum[x^(1 + j/1000), {j, 1, 24}]),
      {x, 0}, {y, 5}, Method -> "GroupedLagrange"]]},
  {"F04-symbolic-realness", HoldComplete[
    AsymptoticInverse`AsymptoticExpansion[a + x, {x, 0, 2}]]},
  {"F04-nonreal-elementary-branch", HoldComplete[
    AsymptoticInverse`AsymptoticExpansion[ArcCos[2 + x], {x, 0, 3}]]},
  {"F05-refinement-shortfall", HoldComplete[Module[{s, t},
    s = AsymptoticInverse`AsymptoticExpansion[1/(1 + x), {x, 0, 3}];
    t = AsymptoticInverse`AsymptoticExpansion[x^-10, {x, 0, 3}];
    AsymptoticInverse`SeriesRefine[AsymptoticInverse`SeriesMultiply[s, t], 5]]]},
  {"F06-logarithmic-bridge", HoldComplete[Module[{s},
    s = AsymptoticInverse`AsymptoticExpansion[1 + x Log[x], {x, 0, 1}];
    {s["Remainder"], s["SeriesData"]}]]},
  {"derivative-contract-control", HoldComplete[Module[{s},
    s = AsymptoticInverse`AsymptoticExpansion[Sin[x], {x, 0, 4}];
    AsymptoticInverse`SeriesDifferentiate[s]]]},
  {"certificate-control", HoldComplete[Module[{s},
    s = AsymptoticInverse`AsymptoticInverse[x + x^2, {x, 0}, {y, 5}];
    AsymptoticInverse`InverseCertificate[s, 1/10,
      "Interval" -> {1/20, 3/20}, "Center" -> 1/10,
      "RefineExpansion" -> False]]]},
  {"native-Series-control", HoldComplete[Series[(1 + x)^256, {x, 0, 2}]]},
  {"native-InverseSeries-control", HoldComplete[InverseSeries[Series[x + x^2, {x, 0, 4}]]]},
  {"native-AsymptoticSolve-control", HoldComplete[
    AsymptoticSolve[x + x^2 == y, {x, 0}, {y, 0, 4}]]}
};
report = <|"AuditCommitExpected" -> "07a9781212beb2eeb9ff16aa625b50ac27974078",
  "KernelVersion" -> $Version, "SystemID" -> $SystemID,
  "PackagePath" -> ExpandFileName[package],
  "PackageSHA256" -> IntegerString[FileHash[package, "SHA256"], 16, 64],
  "Mode" -> "Characterization, not a pass/fail suite",
  "Results" -> (probe @@ # & /@ cases)|>;
output = Environment["ASYMPTOTIC_AUDIT_OUTPUT"];
If[! StringQ[output] || StringLength[output] == 0, output = "native-characterization.json"];
If[Export[output, report, "RawJSON"] === $Failed, Exit[2]];
Print["Wrote ", output];
Exit[0];
