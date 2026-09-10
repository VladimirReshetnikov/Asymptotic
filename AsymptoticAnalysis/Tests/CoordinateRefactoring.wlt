(* Common-coordinate inverses and preservation of conditional input semantics. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
  Module[{x, u, charts, expected, actual},
   charts = {x, x - 2, 2 - x, x - Sqrt[2], Sqrt[2] - x, 1/x, -1/x};
   expected = {x -> u, x -> u + 2, x -> 2 - u, x -> u + Sqrt[2],
     x -> Sqrt[2] - u, x -> 1/u, x -> -1/u};
   actual = AsymptoticAnalysis`Private`seriesCoordinateRule[
       <|"Variable" -> x, "ScaleVariable" -> #|>, u] & /@ charts;
   {actual === expected,
    And @@ MapThread[TrueQ[FullSimplify[(#1 /. #2) == u, u > 0]] &, {charts, actual}]}],
  {True, True}, TestID -> "coordinate-common-real-charts-have-exact-inverse-rules"]

VerificationTest[
  Module[{x, u, rule},
   rule = AsymptoticAnalysis`Private`seriesCoordinateRule[
     <|"Variable" -> x, "ScaleVariable" -> x/(1 + x)|>, u];
   {MatchQ[rule, _Rule],
    TrueQ[FullSimplify[(x /. rule) == u/(1 - u), 0 < u < 1]]}],
  {True, True}, TestID -> "coordinate-nonlinear-unique-real-inverse-keeps-solver-fallback"]

VerificationTest[
  Module[{x, u},
   AsymptoticAnalysis`Private`seriesCoordinateRule[
       <|"Variable" -> x, "ScaleVariable" -> #|>, u] & /@ {x^2, 3}],
  {$Failed, $Failed}, TestID -> "coordinate-ambiguous-and-constant-charts-remain-rejected"]

VerificationTest[
  Module[{x, u, a, charts, actual, solved},
   (* Nonreal and parameter-dependent offsets retain the real solver's
      acceptance boundary instead of being treated as unconditional charts. *)
   charts = {x - I, x + a};
   actual = AsymptoticAnalysis`Private`seriesCoordinateRule[
       <|"Variable" -> x, "ScaleVariable" -> #|>, u] & /@ charts;
   solved = Quiet[Solve[# == u, x, Reals]] & /@ charts;
   solved = If[ListQ[#] && Length[#] === 1 && MatchQ[First[#], {_Rule}],
       First[First[#]], $Failed] & /@ solved;
   actual === solved],
  True, TestID -> "coordinate-offset-shortcuts-preserve-real-solver-branch-checks"]

VerificationTest[
  Module[{x, charts, points, directions},
   charts = {x - 2, 2 - x, 1/x, -1/x};
   points = {2, 2, Infinity, -Infinity};
   directions = {"FromAbove", "FromBelow", Automatic, Automatic};
   Table[With[{w = charts[[k]], point = points[[k]], direction = directions[[k]]},
     Module[{s, sum, product},
      s = AsymptoticExpansion[Sin[w], {x, point, 4}, Direction -> direction];
      sum = SeriesAdd[s, x]; product = SeriesMultiply[s, 1/w];
      {TrueQ[FullSimplify[Normal[sum] == x + w - w^3/6, w > 0]],
       TrueQ[FullSimplify[Normal[product] == 1 - w^2/6, w > 0]],
       sum["RemainderPower"] === s["RemainderPower"],
       product["RemainderPower"] === s["RemainderPower"] - 1,
       sum["RemainderVariable"] === w, product["RemainderVariable"] === w}]],
    {k, Length[charts]}]],
  ConstantArray[ConstantArray[True, 6], 4],
  TestID -> "coordinate-public-arithmetic-transports-finite-and-infinite-chart-errors"]

VerificationTest[
  Module[{x, a, parts},
   parts = AsymptoticAnalysis`Private`splitApproachInput[
     ConditionalExpression[x + x^2, x < 1], x, a > 0 && x > 0];
   {parts[[1]] === x + x^2, parts[[2]] === (a > 0),
    TrueQ[FullSimplify[Equivalent[parts[[3]], 0 < x < 1], Element[x, Reals]]]}],
  {True, True, True}, TestID -> "coordinate-outer-conditions-and-parameter-conjuncts-split-once"]

VerificationTest[
  Module[{x, a, parts},
   parts = AsymptoticAnalysis`Private`splitApproachInput[x, x, a > 0 || x < 0];
   parts === {x, True, a > 0 || x < 0}],
  True, TestID -> "coordinate-mixed-disjunction-remains-one-approach-condition"]

VerificationTest[
  Module[{x, t, held, bound},
   held = HoldComplete[ConditionalExpression[x, x < 0]];
   bound = Function[t, ConditionalExpression[t + x, t > 0]];
   {AsymptoticAnalysis`Private`splitApproachInput[held, x, True] === {held, True, True},
    AsymptoticAnalysis`Private`splitApproachInput[bound, x, True] === {bound, True, True}}],
  {True, True}, TestID -> "coordinate-condition-split-does-not-cross-held-or-binding-scopes"]

VerificationTest[
  Module[{x, a, s, refined},
   s = AsymptoticExpansion[ConditionalExpression[a (1 + x + x^2), x < 1],
     {x, 0, 3}, Assumptions -> a > 0 && x > 0];
   refined = SeriesRefine[s, 5];
   {Expand[Normal[s] - a (1 + x + x^2)] === 0,
    Expand[Normal[refined] - a (1 + x + x^2)] === 0,
    s["Assumptions"] === (a > 0), refined["Assumptions"] === (a > 0),
    And @@ (TrueQ[FullSimplify[Equivalent[#["TargetDomain"], 0 < x < 1],
           a > 0 && Element[x, Reals]]] & /@ {s, refined})}],
  {True, True, True, True, True},
  TestID -> "coordinate-forward-parameter-assumptions-and-domain-survive-refinement"]

VerificationTest[
  Module[{x, y, a, s, refined},
   s = AsymptoticInverse[ConditionalExpression[a (x + x^2), x < 1],
     {x, 0}, {y, 3}, Assumptions -> a > 0 && x > 0];
   refined = SeriesRefine[s, 5];
   {Together[Normal[s] - y/a + y^2/a^2] === 0,
    Together[Normal[refined] - y/a + y^2/a^2 - 2 y^3/a^3 + 5 y^4/a^4] === 0,
    And @@ (TrueQ[FullSimplify[Equivalent[#["SourceDomain"], 0 < x < 1],
           a > 0 && Element[x, Reals]]] & /@ {s, refined}),
    KeyExistsQ[refined[[1]], "ConditionalSourceReplay"]}],
  {True, True, True, True},
  TestID -> "coordinate-inverse-quadratic-oracle-and-source-condition-survive-refinement"]

VerificationTest[
  Module[{x, a, model},
   model = PowerLogModel[ConditionalExpression[a x + a x^2, x < 1],
     {x, 0}, Assumptions -> a > 0 && x > 0];
   {model["LeadingCoefficient"] === a, model["LeadingPower"], model["Gaps"],
    model["Polynomials"],
    TrueQ[FullSimplify[Equivalent[model["SourceDomain"], 0 < x < 1], Element[x, Reals]]]}],
  {True, 1, {1}, {1}, True}, TestID -> "coordinate-finite-model-keeps-coefficients-and-source-domain"]

VerificationTest[
  Module[{x, y, results},
   results = {
     AsymptoticExpansion[ConditionalExpression[1.5 + x, x < 0], {x, 0, 3}],
     AsymptoticInverse[ConditionalExpression[1.5 + x, x < 0], {x, 0}, {y, 3}],
     PowerLogModel[ConditionalExpression[1.5 + x, x < 0], {x, 0}]};
   If[FailureQ[#], #[[1]], "UnexpectedSuccess"] & /@ results],
  {"IncompatibleTargetCondition", "IncompatibleSourceCondition", "InexactInput"},
  TestID -> "coordinate-refactoring-preserves-entry-specific-validation-order"]
