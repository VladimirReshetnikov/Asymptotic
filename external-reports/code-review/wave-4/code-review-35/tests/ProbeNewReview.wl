(* UNEXECUTED regression/diagnostic specifications. Run in a fresh process.
   Set ASYMPTOTIC_REVIEW_SOURCE to the pinned package entry file.
   Set ASYMPTOTIC_REVIEW_CANDIDATES to code/ReviewPrimitives.wl (optional).
   This script prints observations; it is not a release acceptance suite. *)
source = Environment["ASYMPTOTIC_REVIEW_SOURCE"];
If[! StringQ[source] || source === "", Print["Set ASYMPTOTIC_REVIEW_SOURCE."]; Quit[2]];
Get[source];
If[StringContainsQ[$Version, "Mathics"], $IterationLimit = 1000000];
Clear[x, y, u, ell];
SetAttributes[reviewObserve, HoldRest];
reviewObserve[id_String, expression_] := Module[{value},
 value = Quiet[TimeConstrained[Check[expression, $Failed], 30, $Aborted]];
 Print[id, "\t", ToString[value, InputForm]]];
reviewSummary[value_AsymptoticAnalysis`GeneralizedSeries] :=
 {value["Kind"], Normal[value], value["Remainder"]};
reviewSummary[value_] := value;
Print["KERNEL\t", $Version];
reviewObserve["control-inverse-polynomial",
 reviewSummary[AsymptoticAnalysis`AsymptoticInverse[x + x^2, {x, 0}, {y, 5}]]];
reviewObserve["N05-condition-wide",
 reviewSummary[AsymptoticAnalysis`AsymptoticExpansion[
  ConditionalExpression[x + x^2, 0 < x < 1], {x, 0, 4}, "Backend" -> "Package"]]];
reviewObserve["N05-condition-small",
 reviewSummary[AsymptoticAnalysis`AsymptoticExpansion[
  ConditionalExpression[x + x^2, 0 < x < 2^-100], {x, 0, 4}, "Backend" -> "Package"]]];
reviewObserve["N05-inverse-small",
 reviewSummary[AsymptoticAnalysis`AsymptoticInverse[
  ConditionalExpression[x + x^2, 0 < x < 2^-100], {x, 0}, {y, 5}]]];
reviewObserve["native-explicit-series",
 reviewSummary[AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 4}, "Backend" -> "Series"]]];
If[StringContainsQ[$Version, "Mathics"],
 reviewObserve["N03-sparse-helper-safe-degree",
  AsymptoticAnalysis`Mathics`CoefficientRules[1 + ell^1000, ell]]
];
If[StringContainsQ[$Version, "Mathics"],
 reviewObserve["N04-first-position-control",
  AsymptoticAnalysis`Mathics`FirstPosition[{1, 1, 1}, 1]]
];
If[StringContainsQ[$Version, "Mathics"],
 reviewObserve["N05-eventual-helper-small",
  AsymptoticAnalysis`Private`inverseFunctionEventually[u < 2^-100, u, True]]
];
If[StringContainsQ[$Version, "Mathics"],
 reviewObserve["N06-default-local-limit",
  AsymptoticAnalysis`Mathics`Limit[u/Abs[u], u -> 0]]
];
If[StringContainsQ[$Version, "Mathics"],
 reviewObserve["N06-local-limit-above",
  AsymptoticAnalysis`Mathics`Limit[u/Abs[u], u -> 0, Direction -> "FromAbove"]]
];
If[StringContainsQ[$Version, "Mathics"],
 reviewObserve["N06-local-limit-below",
  AsymptoticAnalysis`Mathics`Limit[u/Abs[u], u -> 0, Direction -> "FromBelow"]]
];
candidateSource = Environment["ASYMPTOTIC_REVIEW_CANDIDATES"];
If[StringQ[candidateSource] && candidateSource =!= "", Get[candidateSource]];
If[Length[DownValues[AsymptoticReview`SparseMonomialRules]] > 0,
 reviewObserve["candidate-sparse-billion",
  AsymptoticReview`SparseMonomialRules[1 + ell^1000000000, ell, 10]]
];
If[Length[DownValues[AsymptoticReview`SparseMonomialRules]] > 0,
 reviewObserve["candidate-unexpanded-refusal",
  AsymptoticReview`SparseMonomialRules[(1 + ell)^1000000000, ell, 10]]
];
If[Length[DownValues[AsymptoticReview`SparseMonomialRules]] > 0,
 reviewObserve["candidate-exact-radius",
  AsymptoticReview`AffineRadius[{{-2^-100, 1, "<"}}]]
];
If[Length[DownValues[AsymptoticReview`SparseMonomialRules]] > 0,
 reviewObserve["candidate-bilateral-refusal",
  AsymptoticReview`ConservativeRealLimit[u/Abs[u], u -> 0]]
];
If[Length[DownValues[AsymptoticReview`SparseMonomialRules]] > 0,
 reviewObserve["candidate-continuous-limit",
  AsymptoticReview`ConservativeRealLimit[u^2, u -> 0]]
];
