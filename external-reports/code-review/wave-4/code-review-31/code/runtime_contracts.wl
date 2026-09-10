(* CHARACTERIZATION ONLY: NOT EXECUTED IN THE ARTICLE'S ENVIRONMENT.
   One selected case per fresh kernel. Get is a separate streamed expression
   so public names bind after package loading. Driver enforces time/output caps. *)
reviewSource = Environment["ASYMPTOTIC_REVIEW_SOURCE"];
reviewSelection = Environment["ASYMPTOTIC_REVIEW_CASE"];
If[! StringQ[reviewSource] || ! StringQ[reviewSelection], Exit[2]];
Get[reviewSource];
If[StringContainsQ[$Version, "Mathics"], $IterationLimit = 1000000];

SetAttributes[reviewCase, HoldAll];
reviewCase[id_String, body_] := If[id === reviewSelection,
  reviewValue = body;
  Print["REVIEW_KERNEL\t", $Version];
  Print["REVIEW_CASE\t", id];
  Print["REVIEW_VALUE_BEGIN"];
  Print[ToString[reviewValue, InputForm]];
  Print["REVIEW_VALUE_END"];
  Exit[0]];

reviewCase["first-position-count",
  Module[{count = 0, result, data = Range[100]},
    result = If[StringContainsQ[$Version, "Mathics"],
      AsymptoticAnalysis`Mathics`FirstPosition[
        data, _?(Function[z, count++; z === 1]), Missing["NoMatch"], {1}, Heads -> False],
      FirstPosition[data, _?(Function[z, count++; z === 1]), Missing["NoMatch"], {1}, Heads -> False]];
    {result, count}]];

reviewCase["bounded-position-support",
  Module[{count = 0, result},
    result = System`Position[Range[100], _?(Function[z, count++; z === 1]), {1}, 1, Heads -> False];
    {result, count}]];

reviewCase["limit-default",
  If[StringContainsQ[$Version, "Mathics"],
    {AsymptoticAnalysis`Mathics`Limit[Abs[x]/x, x -> 0],
     AsymptoticAnalysis`Mathics`Limit[Abs[x]/x, x -> 0, Direction -> "FromAbove"],
     AsymptoticAnalysis`Mathics`Limit[Abs[x]/x, x -> 0, Direction -> "FromBelow"]},
    {System`Limit[Abs[x]/x, x -> 0],
     System`Limit[Abs[x]/x, x -> 0, Direction -> "FromAbove"],
     System`Limit[Abs[x]/x, x -> 0, Direction -> "FromBelow"]}]];

reviewCase["empty-lookup-nested",
  Module[{b},
    b = If[StringContainsQ[$Version, "Mathics"],
      AsymptoticAnalysis`Mathics`Lookup[<||>, {}], System`Lookup[<||>, {}]];
    {b, 2, 0}]];

reviewCase["empty-association-list-lookup",
  Module[{b},
    b = If[StringContainsQ[$Version, "Mathics"],
      AsymptoticAnalysis`Mathics`Lookup[{}, "key"], System`Lookup[{}, "key"]];
    {b, 2, 0}]];

reviewCase["public-ordinary-control",
  Module[{s = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}]},
    {Normal[s], s["Remainder"], s["TargetDomain"]}]];

reviewCase["loggamma-control",
  Module[{s = AsymptoticExpansion[LogGamma[1/x], {x, 0, 4}, "Backend" -> "Package"]},
    {Normal[s], s["Remainder"], s["Assumptions"]}]];

reviewCase["special-origin-controls",
  {Normal[AsymptoticExpansion[Hypergeometric1F1[1, 2, x], {x, 0, 4}, "Backend" -> "Package"]],
   Normal[AsymptoticExpansion[Hypergeometric2F1[1, 1, 2, x], {x, 0, 4}, "Backend" -> "Package"]],
   Normal[AsymptoticExpansion[PolyLog[2, x^2], {x, 0, 7}, "Backend" -> "Package"]]}];
Exit[3];
