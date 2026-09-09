(* Run: wolframscript -file reproduce.wl [pinned-standalone.wl]
   Add --allow-modified to examine an experimental candidate.
   Four audit probes; not the full upstream suite. Each expensive operation
   is constrained. No billion-element allocation is attempted. *)

$AuditCallerPath = ExpandFileName[$InputFileName];
Get[FileNameJoin[{DirectoryName[$AuditCallerPath], "load_pinned.wl"}]];
ClearAll[AuditRun, AuditSummary];
SetAttributes[AuditRun, HoldAll];
AuditRun[e_] := Module[{value, peak, timing},
  timing = AbsoluteTiming[
    peak = MaxMemoryUsed[value = MemoryConstrained[
      TimeConstrained[e, 12, Failure["AuditTimeout", <|"Seconds" -> 12|>]],
      134217728, Failure["AuditMemoryLimit", <|"Bytes" -> 134217728|>]]]];
  <|"Seconds" -> timing[[1]], "AdditionalPeakBytes" -> peak, "Value" -> value|>
];
AuditSummary[s_AsymptoticInverse`GeneralizedSeries] := <|
  "Head" -> "GeneralizedSeries", "Expression" -> Normal[s],
  "Remainder" -> s["Remainder"], "Assumptions" -> s["Assumptions"],
  "TargetDomain" -> s["TargetDomain"], "ReturnedTermCount" -> s["ReturnedTermCount"]|>;
AuditSummary[e_] := e;

$AuditLoadResult = AuditLoadFromCommandLine[];
If[FailureQ[$AuditLoadResult], Print[InputForm[$AuditLoadResult]]; Exit[1]];
Clear[x, y, z, a];
$AuditAssumed = Assuming[a > 0,
  AsymptoticInverse`AsymptoticExpansion[Sqrt[a^2] + x, {x, 0, 2}]];
$AuditUncertain = AsymptoticInverse`AsymptoticExpansion[-x^4, {x, 0, 1}];
$AuditLoop = AuditRun[AsymptoticInverse`AsymptoticExpansion[
  Exp[x^(1/50)], {x, 0, 1}, "MaxTerms" -> 10]];
$AuditDense = Table[Module[{r},
  r = AuditRun[AsymptoticInverse`AsymptoticExpansion[
    x + x^(1 + 1/n) + x^2, {x, 0, 3/2}, "MaxTerms" -> 10]];
  Join[<|"N" -> n|>, r, <|"Value" -> AuditSummary[r["Value"]]|>]],
  {n, {1000, 100000, 1000000}}];
$AuditResult = <|
  "Environment" -> $AuditLoadResult,
  "AmbientAssumptions" -> AuditSummary[$AuditAssumed],
  "ActualAtNegativeParameter" -> (Sqrt[a^2] + x /. a -> -1),
  "ReturnedAtNegativeParameter" -> (Normal[$AuditAssumed] /. a -> -1),
  "DirectUncertainPower" -> AsymptoticInverse`SeriesPower[$AuditUncertain, 1/2],
  "WrappedUncertainPower" -> AuditSummary[
    AsymptoticInverse`SeriesObservable[$AuditUncertain, 1 + Sqrt[z], z]],
  "ActualWrappedObservable" -> FullSimplify[1 + Sqrt[-x^4], x > 0],
  "LoopBudget" -> Join[$AuditLoop, <|"Value" -> AuditSummary[$AuditLoop["Value"]]|>],
  "DenseGrid" -> $AuditDense|>;
Print[InputForm[$AuditResult]];
