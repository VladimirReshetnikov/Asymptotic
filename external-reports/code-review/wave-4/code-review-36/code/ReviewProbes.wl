(* Focused characterization and acceptance probes. NOT executed by this review.
   Run one case per fresh kernel. Set these environment variables:
     ASYMPTOTIC_REVIEW_SOURCE = absolute package entry path
     ASYMPTOTIC_REVIEW_CASE   = one case ID below
   Mathics: python -m mathics --quiet --no-readline --file ReviewProbes.wl
   Wolfram: wolfram -noinit -script ReviewProbes.wl
   Use an external process deadline for performance cases.
   No early progress Print is issued, avoiding Mathics Check contamination.
*)
reviewSource = Environment["ASYMPTOTIC_REVIEW_SOURCE"];
reviewCase = Environment["ASYMPTOTIC_REVIEW_CASE"];
If[! StringQ[reviewSource] || ! StringQ[reviewCase], Exit[2]];
Get[reviewSource];
If[StringContainsQ[$Version, "Mathics"], $IterationLimit = 1000000];

reviewActual = Switch[reviewCase,
 "small-conditional-domain",
  Module[{x, s}, s = AsymptoticExpansion[
    ConditionalExpression[x + x^2, 0 < x < 1/1024], {x, 0, 3},
    "Backend" -> "Package"];
   {Head[s], If[Head[s] === GeneralizedSeries, Normal[s], s]}],
 "scaled-conditional-controls",
  Module[{x}, Table[AsymptoticExpansion[
    ConditionalExpression[x + x^2, 0 < x < 2^-k], {x, 0, 3},
    "Backend" -> "Package"], {k, {1, 5, 6, 7, 10}}]],
 "private-eventual-truth",
  Module[{u}, {AsymptoticAnalysis`Private`inverseFunctionEventually[
    0 < u < 1/1024, u, True],
   AsymptoticAnalysis`Private`inverseFunctionEventually[0 < u < 1/16, u, True]}],
 "terminating-pfq-public",
  Module[{x, s}, s = AsymptoticExpansion[
    System`HypergeometricPFQ[{-2, 1, 3}, {}, x], {x, 0, 3},
    "Backend" -> "Package"];
   {Head[s], If[Head[s] === GeneralizedSeries, Normal[s], s]}],
 "terminating-pfq-private",
  If[StringContainsQ[$Version, "Mathics"],
   Module[{t}, AsymptoticAnalysis`Mathics`mathicsDefiningTaylor[
     System`HypergeometricPFQ[{-2, 1, 3}, {}, t], {t, 0, 3}, True]],
   Missing["MathicsOnlyPrivateAdapter"]],
 "sparse-coefficient-cost",
  If[StringContainsQ[$Version, "Mathics"],
   Module[{q, answer}, Table[
    With[{timing = AbsoluteTiming[
      answer = AsymptoticAnalysis`Mathics`CoefficientRules[1 + q^d, q]]},
     {d, timing[[1]], Length[answer], answer}], {d, {100, 1000, 10000}}]],
   Missing["MathicsOnlyPrivateAdapter"]],
 "first-position-bounded-control",
  Module[{data = ConstantArray[1, 10000]},
   {FirstPosition[data, 1, Missing["None"], {1}, Heads -> False],
    Position[data, 1, {1}, 1, Heads -> False]}],
 "frontier-public-workload",
  Module[{x, y, s}, s = AsymptoticInverse[x + x^2 + x^3,
    {x, 0}, {y, 8}, Method -> "Lagrange"];
   Table[AbsoluteTiming[SeriesRefine[s, n]], {n, {12, 16, 24}}]],
 "native-comparison",
  Module[{x}, {Series[Exp[x], {x, 0, 3}],
    InverseSeries[Series[x + x^2, {x, 0, 5}]],
    AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Package"],
    AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"]}],
 _, Missing["UnknownReviewCase", reviewCase]
];
Print["REVIEW_KERNEL\t", $Version];
Print["REVIEW_CASE\t", reviewCase];
Print[ToString[reviewActual, InputForm]];
(* These are characterization probes, not a fabricated pass/fail suite. *)
