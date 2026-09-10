(* Characterization, not an acceptance test. Load the package first.
   This file leaves the kernel alive and returns observations without deciding
   whether they are correct. The article supplies the independent proof.
*)
Module[{x, z, a, s, observations = {}, m, h, condition, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 3},
    Assumptions -> a == I, "Backend" -> "Package"];
  Do[
    condition = Element[a (Exp[z] - Sum[z^k/k!, {k, 0, m}]), Reals];
    Do[
      r = AsymptoticAnalysis`SeriesObservable[s,
        ConditionalExpression[1, condition], z, "Cutoff" -> h];
      AppendTo[observations, {m, h,
        If[MatchQ[r, AsymptoticAnalysis`GeneralizedSeries[_Association]],
          {r["Expression"], r["Remainder"], r["Exact"], r["Assumptions"]}, r]}],
      {h, {m + 1, m + 2}}], {m, 0, 4}];
  <|"Kernel" -> $Version, "Source" -> s, "Observations" -> observations|>
]
