(* N01 desired-behavior regression specification.
   Load AsymptoticAnalysis.wl before Get of this file. This file does not Exit.
   Uses explicit public contexts and a small runner instead of requiring MUnit.
   The complete file was NOT run by this audit on either evaluator.
   Focused equivalent cases were run on Wolfram 15; see native-observations.json.
   Baseline false-predicate cases are expected to FAIL this desired contract.
*)
Module[{x, z, a, source, zero, cases = {}, check, refused, exactOne,
    condition, result, m, h, validConditions, report},
  check[name_String, passed_] := AppendTo[cases, {name, TrueQ[passed]}];
  refused[r_] := MatchQ[r, Failure["IncompatibleObservableCondition", _Association]];
  exactOne[r_] := MatchQ[r, AsymptoticAnalysis`GeneralizedSeries[_Association]] &&
    r["Expression"] === 1 && r["Remainder"] === 0 && TrueQ[r["Exact"]];
  source = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 3},
    Assumptions -> a == I, "Backend" -> "Package"];
  check["exact-real-source", MatchQ[source, AsymptoticAnalysis`GeneralizedSeries[_Association]] &&
    source["Expression"] === x && source["Remainder"] === 0];
  Do[
    condition = Element[a (Exp[z] - Sum[z^k/k!, {k, 0, m}]), Reals];
    Do[
      result = AsymptoticAnalysis`SeriesObservable[source,
        ConditionalExpression[1, condition], z, "Cutoff" -> h];
      check["false-Taylor-tail-m=" <> ToString[m] <> "-h=" <> ToString[h], refused[result]],
      {h, {m + 1, m + 2}}], {m, 0, 4}];
  validConditions = {Element[z, Reals], Element[z^2, Reals]};
  Do[
    result = AsymptoticAnalysis`SeriesObservable[source,
      ConditionalExpression[1, condition], z, "Cutoff" -> 2];
    check["exact-real-control-" <> ToString[condition, InputForm], exactOne[result]],
    {condition, validConditions}];
  result = AsymptoticAnalysis`SeriesObservable[source,
    ConditionalExpression[1, Element[a z^2, Reals]], z, "Cutoff" -> 1];
  check["exact-nonreal-polynomial-refused", refused[result]];
  zero = AsymptoticAnalysis`AsymptoticExpansion[0, {x, 0, 3},
    Assumptions -> a == I, "Backend" -> "Package"];
  result = AsymptoticAnalysis`SeriesObservable[zero,
    ConditionalExpression[1, Element[a (Exp[z] - 1 - z), Reals]], z, "Cutoff" -> 1];
  check["exact-zero-must-not-be-confused-with-pure-remainder", exactOne[result]];
  report = <|"Kernel" -> $Version, "Cases" -> cases,
    "Passed" -> Count[cases, {_, True}], "Failed" -> Count[cases, {_, False}]|>;
  Print[report]; report
]
