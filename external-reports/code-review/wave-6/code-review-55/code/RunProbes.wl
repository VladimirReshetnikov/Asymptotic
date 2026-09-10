(* Run in a fresh kernel. Set AuditPackagePath to an existing, local standalone
   before Get-ing this file. No network, downloads, or repository mutation.
   Example:
   AuditPackagePath = "/repo/AsymptoticAnalysis.wl";
   Get["/audit/code/RunProbes.wl"];
   Optional: AuditOutputPath = "/tmp/observations.wl" before loading.
   This uses plain records rather than TestReport, for Mathics portability.
   The complete packaged runner has not been run on Mathics in this review. *)

If[! StringQ[Global`AuditPackagePath] || ! FileExistsQ[Global`AuditPackagePath],
  Print["Set AuditPackagePath to an existing local AsymptoticAnalysis.wl."]; Abort[]];
Global`AuditCodeDirectory = DirectoryName[$InputFileName];
Get[Global`AuditPackagePath];
Get[FileNameJoin[{Global`AuditCodeDirectory, "AffineDirichletExpansion.wl"}]];

ClearAll[Global`auditX, Global`auditBrief, Global`auditObserve];
Global`auditBrief[s_AsymptoticAnalysis`GeneralizedSeries] :=
  {"Series", Normal[s], s["Remainder"], s["ReturnedTermCount"],
    s["RequestedTermGoal"], s["AbsoluteRemainderBound"]};
Global`auditBrief[other_] := {"Other", other};
SetAttributes[Global`auditObserve, HoldRest];
Global`auditObserve[name_, expression_] := Module[{result, elapsed},
  {elapsed, result} = AbsoluteTiming[TimeConstrained[expression, 20, "AuditTimeout"]];
  {name, elapsed, Global`auditBrief[result]}];

Global`AuditObservations = {
  {"Kernel", $Version},
  {"PackagePath", Global`AuditPackagePath},
  Global`auditObserve["N01-Zeta-bare",
    AsymptoticAnalysis`AsymptoticExpansion[Zeta[Global`auditX],
      {Global`auditX, Infinity, 2}, "Backend" -> "Package"]],
  Global`auditObserve["N01-Zeta-translated",
    AsymptoticAnalysis`AsymptoticExpansion[Zeta[Global`auditX]-1,
      {Global`auditX, Infinity, 2}, "Backend" -> "Package"]],
  Global`auditObserve["N01-Lerch-bare",
    AsymptoticAnalysis`AsymptoticExpansion[LerchPhi[1/2,1,Global`auditX],
      {Global`auditX, Infinity, 2}, "Backend" -> "Package"]],
  Global`auditObserve["N01-Lerch-translated",
    AsymptoticAnalysis`AsymptoticExpansion[1+LerchPhi[1/2,1,Global`auditX],
      {Global`auditX, Infinity, 2}, "Backend" -> "Package"]],
  Global`auditObserve["N02-Zeta-combined-constraints",
    AsymptoticAnalysis`AsymptoticExpansion[Zeta[Global`auditX],
      {Global`auditX, Infinity, Log[4]}, SeriesTermGoal -> 1, "Backend" -> "Package"]],
  Global`auditObserve["N02-Lerch-combined-constraints",
    AsymptoticAnalysis`AsymptoticExpansion[LerchPhi[1/2,1,Global`auditX],
      {Global`auditX, Infinity, 4}, SeriesTermGoal -> 1, "Backend" -> "Package"]],
  Global`auditObserve["N02-ordinary-control",
    AsymptoticAnalysis`AsymptoticExpansion[1+1/Global`auditX+1/Global`auditX^2,
      {Global`auditX, Infinity, 4}, SeriesTermGoal -> 1, "Backend" -> "Package"]],
  Global`auditObserve["N02-small-goal-large-cutoff",
    AsymptoticAnalysis`AsymptoticExpansion[Zeta[Global`auditX],
      {Global`auditX, Infinity, 1000000}, SeriesTermGoal -> 1,
      "MaxTerms" -> 100, "Backend" -> "Package"]],
  Global`auditObserve["N01-prototype-Zeta",
    AsymptoticAudit`AffineDirichletExpansion[Zeta[Global`auditX]-1,
      {Global`auditX, Infinity, Log[3]}]],
  Global`auditObserve["N01-prototype-Lerch",
    AsymptoticAudit`AffineDirichletExpansion[1+LerchPhi[1/2,1,Global`auditX],
      {Global`auditX, Infinity, 3}]],
  Global`auditObserve["N01-prototype-refusal-quadratic",
    AsymptoticAudit`AffineDirichletExpansion[Zeta[Global`auditX]^2,
      {Global`auditX, Infinity, 2}]],
  Global`auditObserve["N01-prototype-refusal-inexact",
    AsymptoticAudit`AffineDirichletExpansion[0.5 Zeta[Global`auditX],
      {Global`auditX, Infinity, 2}]]
};
Print[InputForm[Global`AuditObservations]];
If[StringQ[Global`AuditOutputPath],
  Export[Global`AuditOutputPath, ToString[InputForm[Global`AuditObservations]], "Text"]];
