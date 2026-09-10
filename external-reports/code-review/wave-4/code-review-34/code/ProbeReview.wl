(* UNEXECUTED runtime characterization, not a record of passing tests.
   Set ASYMPTOTIC_REVIEW_SOURCE to a pinned modular or standalone entry file.
   Set ASYMPTOTIC_REVIEW_CASE to one case below and run each in a fresh process.
   This driver prints observations; it does not claim formal certification. *)
reviewSource = Environment["ASYMPTOTIC_REVIEW_SOURCE"];
reviewCase = Environment["ASYMPTOTIC_REVIEW_CASE"];
If[! StringQ[reviewSource] || ! FileExistsQ[reviewSource],
  Print["Set ASYMPTOTIC_REVIEW_SOURCE to an existing pinned package entry file."]; Exit[2]];
If[StringContainsQ[$Version, "Mathics"], $IterationLimit = 1000000];
Get[reviewSource];
Print["RUNTIME: ", $Version];
Print["CASE: ", reviewCase];
Clear[x, y, t, ell];
Switch[reviewCase,
 "productlog-principal-exact", Print[InputForm[ProductLog[0, E]]],
 "productlog-minus-one-exact", Print[InputForm[N[ProductLog[-1, -1/100], 30]]],
 "productlog-minus-one-inexact", Print[InputForm[ProductLog[-1, -0.01]]],
 "core-real-branch",
   reviewSeries = AsymptoticCoreInverse[-x Log[x], 0, {x, 0}, {y, 0}];
   Print[InputForm[reviewSeries]];
   If[Head[reviewSeries] === GeneralizedSeries,
     Print["NUMERICAL EXPRESSION: ", InputForm[N[Normal[reviewSeries] /. y -> 1/100, 30]]]],
 "limit-default",
   If[StringContainsQ[$Version, "Mathics"],
     Print[InputForm[{AsymptoticAnalysis`Mathics`Limit[Abs[t]/t, t -> 0],
       AsymptoticAnalysis`Mathics`Limit[Abs[t]/t, t -> 0, Direction -> "FromAbove"],
       AsymptoticAnalysis`Mathics`Limit[Abs[t]/t, t -> 0, Direction -> "FromBelow"]}]],
     Print[InputForm[{Limit[Abs[t]/t, t -> 0],
       Limit[Abs[t]/t, t -> 0, Direction -> "FromAbove"],
       Limit[Abs[t]/t, t -> 0, Direction -> "FromBelow"]}]]],
 "sparse-helper",
   Get[FileNameJoin[{DirectoryName[$InputFileName], "MathicsSparseHelpers.wl"}]];
   Print[InputForm[AsymptoticAudit`SparseUnivariateCoefficientRules[1 + ell^100000, ell]]],
 "fourier-amplitude",
   (* Small safe characterization. Do not start by benchmarking N=10^9. *)
   Print[InputForm[AsymptoticFourierInverse[x + x^2 (1 + Log[x]^20),
     {x, 0}, {y, 3}, "MaxTerms" -> 10, "MaxFrequencies" -> 1]]],
 _, Print["Unknown case. See the Switch labels in ProbeReview.wl."]; Exit[2]
];
Exit[0];
