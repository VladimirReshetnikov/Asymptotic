(* Run in a fresh official kernel:
     wolframscript -file code/probe_native.wls /absolute/path/AsymptoticAnalysis.wl
   Use a checkout of 651f2029d0b2cd4da9e4dfdf1f4275a124d23b99.
   The script records the supplied path; it does not attest the bytes/revision.
   Native helper counters are instrumentation, NOT package acceptance tests. *)

If[Length[$ScriptCommandLine] < 2,
  Print["Supply an absolute modular or standalone package-entry path."]; Exit[2]];
entry = Last[$ScriptCommandLine];
loaded = Check[Get[entry], $Failed];
If[loaded === $Failed || Length[DownValues[AsymptoticAnalysis`AsymptoticExpansion]] == 0,
  Print["Package load failed or expected export is absent."]; Exit[2]];
ClearAll[auditX];
s = AsymptoticAnalysis`AsymptoticExpansion[Zeta[auditX],
  {auditX, Infinity, Log[4]}, "Backend" -> "Package"];
t = AsymptoticAnalysis`SeriesTruncate[s, Log[2]];
u = AsymptoticAnalysis`SeriesTruncate[t, Log[2]];
If[!And @@ (MatchQ[#, _AsymptoticAnalysis`GeneralizedSeries] & /@ {s,t,u}),
  Print["Witness did not construct all three objects."]; Exit[2]];

n01 = <|"IntermediateDiscardedPart" -> ToString[t["TruncationDiscardedPart"], InputForm],
  "NoOpDiscardedPart" -> ToString[u["TruncationDiscardedPart"], InputForm],
  "BoundUnchanged" -> (t["AbsoluteRemainderBound"] === u["AbsoluteRemainderBound"]),
  "NoOpContractType" -> u["ForwardRemainderContract"]["Type"],
  "ExpressionUnchanged" -> (Normal[t] === Normal[u])|>;

original = DownValues[AsymptoticAnalysis`Private`certAffinePair];
visits = 0;
DownValues[AsymptoticAnalysis`Private`certAffinePair] = original /.
  Verbatim[RuleDelayed][lhs_, rhs_] :> RuleDelayed[lhs, (visits++; rhs)];
ctx = <|"Bits" -> 32, "SeriesOrder" -> 8, "ExponentMagnitudeLimit" -> 100000|>;
counts = CheckAbort[Table[
  expr = Nest[auditX (1 + #) &, auditX, n]; visits = 0;
  interval = AsymptoticAnalysis`Private`certEnclose[expr, auditX, {1/4, 1/2}, ctx];
  <|"Depth" -> n, "AffineVisits" -> visits, "PredictedVisits" -> 4 n (n + 1),
    "Enclosure" -> ToString[interval, InputForm]|>, {n, {1,2,4,8,16}}],
  DownValues[AsymptoticAnalysis`Private`certAffinePair] = original; Abort[]];
DownValues[AsymptoticAnalysis`Private`certAffinePair] = original;
Print[ExportString[<|"KernelVersion" -> $Version, "SourcePath" -> entry,
  "ExpectedReviewCommit" -> "651f2029d0b2cd4da9e4dfdf1f4275a124d23b99",
  "SourcePinVerifiedByThisScript" -> False, "N01" -> n01, "N02Instrumentation" -> counts|>, "RawJSON"]];
