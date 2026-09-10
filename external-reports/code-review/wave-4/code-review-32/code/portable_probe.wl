(* Characterization probes. An exit code of zero means completed, not passed.
   Each probe is intended for a fresh kernel. The review did not run them. *)
If[StringQ[$Version] && StringContainsQ[$Version, "Mathics"], $IterationLimit = 1000000];
reviewSource = Environment["ASYMPTOTIC_REVIEW_SOURCE"];
If[! StringQ[reviewSource] || ! FileExistsQ[reviewSource], Print["Missing ASYMPTOTIC_REVIEW_SOURCE"]; Exit[2]];
Get[reviewSource];
reviewCase = Environment["ASYMPTOTIC_REVIEW_CASE"];
Clear[x, y, t, a, u, q];
reviewResult = Switch[reviewCase,
  "lambert-source", {
    AsymptoticAnalysis`AsymptoticExpansion[x + ProductLog[0, E], {x, 0, 3}, "Backend" -> "Package"],
    AsymptoticAnalysis`AsymptoticExpansion[x + ProductLog[E], {x, 0, 3}, "Backend" -> "Package"]},
  "lambert-core",
    reviewSeries = AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
      Exp[x]/x, 0, {x, Infinity}, {y, 0}];
    {Head[reviewSeries], reviewSeries["LambertBranch"], Normal[reviewSeries],
      reviewSeries[N[E^2/2, 30]]},
  "parameter-domain", {
    AsymptoticAnalysis`AsymptoticExpansion[
      InverseFunction[Function[t, a t + t^3]], {y, 0, 6},
      Assumptions -> a > 0, "Backend" -> "Package"],
    AsymptoticAnalysis`AsymptoticInverse[a x + x^3, {x, 0}, {y, 6}, Assumptions -> a > 0]},
  "narrow-neighborhood", {
    AsymptoticAnalysis`AsymptoticExpansion[
      ConditionalExpression[x, x < 1/1000], {x, 0, 3}, "Backend" -> "Package"],
    AsymptoticAnalysis`AsymptoticExpansion[
      ConditionalExpression[x, x < 1], {x, 0, 3}, "Backend" -> "Package"]},
  "sparse-small",
    If[StringContainsQ[$Version, "Mathics"],
      AsymptoticAnalysis`Mathics`CoefficientRules[1 + q^1000, q],
      System`CoefficientRules[1 + q^1000, q]],
  "limit-default",
    If[StringContainsQ[$Version, "Mathics"],
      {AsymptoticAnalysis`Mathics`Limit[Abs[u]/u, u -> 0],
       AsymptoticAnalysis`Mathics`Limit[Abs[u]/u, u -> 0, Direction -> "FromAbove"],
       AsymptoticAnalysis`Mathics`Limit[Abs[u]/u, u -> 0, Direction -> "FromBelow"]},
      {System`Limit[Abs[u]/u, u -> 0],
       System`Limit[Abs[u]/u, u -> 0, Direction -> "FromAbove"],
       System`Limit[Abs[u]/u, u -> 0, Direction -> "FromBelow"]}],
  "terminating-hypergeometric",
    AsymptoticAnalysis`AsymptoticExpansion[
      HypergeometricPFQ[{-2, 3, 4}, {5}, x], {x, 0, 4}, "Backend" -> "Package"],
  _, Print["Unknown review case"]; Exit[2]
];
(* Keep diagnostics after the computation: Mathics Check/message state has
   known evaluation-level sensitivities. No success assertion is inferred. *)
Print["REVIEW_KERNEL\t", $Version];
Print["REVIEW_CASE\t", reviewCase];
Print["REVIEW_OUTPUT_BEGIN"];
Print[InputForm[reviewResult]];
Print["REVIEW_OUTPUT_END"];
Exit[0];
