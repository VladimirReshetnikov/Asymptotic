If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

inverseExpressionEqual[s_, expected_, ass_: True] :=
  MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[s] == expected, ass]];

(* Independent coefficients: substitute g=y+A(Log[y]) y^2+B(Log[y]) y^3
   into h(g)=g+g^2(1+Log[g])=y.  The y^2 equation gives A=-(1+L),
   and the y^3 equation gives B=2L^2+5L+3.  Arithmetic and composition
   oracles below follow by directly substituting this polynomial. *)
inverseExpressionLogOracle[y_] := y - y^2 (1 + Log[y]) + y^3 (2 Log[y]^2 + 5 Log[y] + 3);

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[# + #^2 (1 + Log[#]), Im[#] == 0] &][y], {y, 0, 4}];
  {inverseExpressionEqual[s, inverseExpressionLogOracle[y], y > 0],
    s["RemainderPower"], s["RemainderLogDegree"]}],
  {True, 4, 3}, TestID -> "inverse-expression-original-real-logarithmic-oracle"]

(* For h(t)=t+t^q, direct composition gives inverse coefficients
   1,-1,q,-q(3q-1)/2 at powers 1,q,2q-1,3q-2. *)
VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[# + #^Sqrt[2], # >= 0] &][y], {y, 0}, SeriesTermGoal -> 4];
  {inverseExpressionEqual[s, y - y^Sqrt[2] + Sqrt[2] y^(2 Sqrt[2] - 1) -
      (6 - Sqrt[2])/2 y^(3 Sqrt[2] - 2), y > 0],
    TrueQ[FullSimplify[s["RemainderPower"] == 4 Sqrt[2] - 3]], Length[s["Terms"]]}],
  {True, True, 4}, TestID -> "inverse-expression-original-irrational-four-block-oracle"]

VerificationTest[Module[{t, y, s},
  s = AsymptoticExpansion[InverseFunction[Function[t, t + t^2 (1 + Log[t])]][y], {y, 0, 4}];
  inverseExpressionEqual[s, inverseExpressionLogOracle[y], y > 0]],
  True, TestID -> "inverse-expression-named-single-parameter-function"]

VerificationTest[Module[{t, y, s},
  s = AsymptoticExpansion[InverseFunction[Function[{t}, t + t^2 (1 + Log[t])]][y], {y, 0, 4}];
  inverseExpressionEqual[s, inverseExpressionLogOracle[y], y > 0]],
  True, TestID -> "inverse-expression-named-parameter-list-function"]

VerificationTest[Module[{f, t, y, s}, f[t_] := t + t^2 (1 + Log[t]);
  s = AsymptoticExpansion[InverseFunction[f][y], {y, 0, 4}];
  inverseExpressionEqual[s, inverseExpressionLogOracle[y], y > 0]],
  True, TestID -> "inverse-expression-defined-symbol-callable"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[2 InverseFunction[# + #^2 (1 + Log[#]) &][y] + y^2, {y, 0, 4}];
  inverseExpressionEqual[s, 2 inverseExpressionLogOracle[y] + y^2, y > 0]],
  True, TestID -> "inverse-expression-in-additive-arithmetic"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[# + #^2 (1 + Log[#]) &][y]^2, {y, 0, 4}];
  inverseExpressionEqual[s, y^2 - 2 y^3 (1 + Log[y]), y > 0]],
  True, TestID -> "inverse-expression-in-multiplicative-arithmetic"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[Sin[InverseFunction[# + #^2 (1 + Log[#]) &][y]], {y, 0, 4}];
  inverseExpressionEqual[s, inverseExpressionLogOracle[y] - y^3/6, y > 0]],
  True, TestID -> "inverse-expression-inside-analytic-observable"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[Log[1 + InverseFunction[# + #^2 (1 + Log[#]) &][y]], {y, 0, 4}];
  inverseExpressionEqual[s, y - y^2 (3/2 + Log[y]) +
    y^3 (2 Log[y]^2 + 6 Log[y] + 13/3), y > 0]],
  True, TestID -> "inverse-expression-inside-logarithmic-observable"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[# + #^2 (1 + Log[#]) &][y + y^2], {y, 0, 4}];
  inverseExpressionEqual[s, y - y^2 Log[y] + y^3 (2 Log[y]^2 + 3 Log[y]), y > 0]],
  True, TestID -> "inverse-expression-composes-a-nonlinear-target-argument"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[# + #^2 (1 + Log[#]) &][
    InverseFunction[# + #^2 (1 + Log[#]) &][y]], {y, 0, 4}];
  inverseExpressionEqual[s, y - 2 y^2 (1 + Log[y]) +
    y^3 (6 Log[y]^2 + 15 Log[y] + 9), y > 0]],
  True, TestID -> "inverse-expression-nested-inverse-composition-oracle"]

VerificationTest[Module[{t, y, s},
  s = AsymptoticExpansion[InverseFunction[InverseFunction[
    Function[t, t + t^2 (1 + Log[t])]]][y], {y, 0, 4}];
  {inverseExpressionEqual[s, y + y^2 (1 + Log[y]), y > 0], s["Remainder"]}],
  {True, 0}, TestID -> "inverse-expression-native-double-inverse-is-exact-forward-map"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[ConditionalExpression[
    # + #^2 (1 + Log[#]), 0 < # < 1] &][y], {y, 0, 4}];
  inverseExpressionEqual[s, inverseExpressionLogOracle[y], y > 0]],
  True, TestID -> "inverse-expression-accepts-compatible-local-source-condition"]

VerificationTest[Module[{y}, FailureQ[AsymptoticExpansion[
  InverseFunction[ConditionalExpression[# + #^2 (1 + Log[#]), # > 1] &][y], {y, 0, 3}]]],
  True, TestID -> "inverse-expression-rejects-source-condition-away-from-required-fiber"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[ConditionalExpression[
    InverseFunction[# + #^2 (1 + Log[#]) &][y], y > 0], {y, 0, 4}];
  inverseExpressionEqual[s, inverseExpressionLogOracle[y], y > 0]],
  True, TestID -> "inverse-expression-accepts-compatible-outer-target-condition"]

VerificationTest[Module[{y}, FailureQ[AsymptoticExpansion[ConditionalExpression[
    InverseFunction[# + #^2 (1 + Log[#]) &][y], y < 0], {y, 0, 3}]]],
  True, TestID -> "inverse-expression-rejects-incompatible-outer-target-condition"]

VerificationTest[Module[{t, y, s},
  s = Quiet[AsymptoticExpansion[InverseFunction[Function[t, t^2]][y], {y, 0, 2}]];
  {inverseExpressionEqual[s, -Sqrt[y], y > 0], s["Remainder"]}],
  {True, 0}, TestID -> "inverse-expression-preserves-native-unconditioned-square-branch"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[ConditionalExpression[#^2, # > 0] &][y], {y, 0, 2}];
  {inverseExpressionEqual[s, Sqrt[y], y > 0], s["Remainder"]}],
  {True, 0}, TestID -> "inverse-expression-preserves-native-positive-square-branch"]

VerificationTest[Module[{t, a, y, s},
  s = AsymptoticExpansion[InverseFunction[Function[{t, a},
    t + t^2 (1 + Log[t]) + a], 1, 2][y + 2, 2], {y, 0, 4}];
  inverseExpressionEqual[s, inverseExpressionLogOracle[y], y > 0]],
  True, TestID -> "inverse-expression-first-argument-inverse-with-frozen-parameter"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[
    #1 + #2 + #2^2 (1 + Log[#2]) &, 2, 2][2, y + 2], {y, 0, 4}];
  inverseExpressionEqual[s, inverseExpressionLogOracle[y], y > 0]],
  True, TestID -> "inverse-expression-second-argument-inverse-with-frozen-parameter"]

VerificationTest[Module[{y}, FailureQ[AsymptoticExpansion[InverseFunction[
    #1 + #2 + #2^2 (1 + Log[#2]) &, 2, 2][y, y], {y, 0, 3}]]],
  True, TestID -> "inverse-expression-varying-noninverted-parameter-fails-explicitly"]

VerificationTest[Module[{a, y, s},
  s = AsymptoticExpansion[InverseFunction[#1^2 + Log[#2] - 1 &, 2, 2][a, y],
    {y, 0, 4}, Assumptions -> Element[a, Reals]];
  inverseExpressionEqual[s, Exp[1 - a^2] (1 + y + y^2/2 + y^3/6),
    Element[a, Reals] && y > 0]],
  True, TestID -> "inverse-expression-user-eager-multiargument-exponential-with-outer-condition"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[# + #^2 (1 + Log[#]) &][y],
    {y, 0}, SeriesTermGoal -> 3];
  {inverseExpressionEqual[s, inverseExpressionLogOracle[y], y > 0], Length[s["Terms"]]}],
  {True, 3}, TestID -> "inverse-expression-term-goal-counts-complete-logarithmic-blocks"]

VerificationTest[Module[{y, s, refined},
  s = AsymptoticExpansion[InverseFunction[# + #^2 (1 + Log[#]) &][y], {y, 0, 3}];
  refined = SeriesRefine[s, 4];
  {inverseExpressionEqual[refined, inverseExpressionLogOracle[y], y > 0],
    refined["RemainderPower"], refined["RemainderLogDegree"]}],
  {True, 4, 3}, TestID -> "inverse-expression-refines-retained-forward-expression"]

VerificationTest[Module[{y, z, input, result},
  input = AsymptoticExpansion[Sin[y], {y, 0, 3}];
  result = SeriesObservable[input, InverseFunction[# + #^2 (1 + Log[#]) &][z], z, "Cutoff" -> 4];
  {inverseExpressionEqual[result, y - y^2 (1 + Log[y]), y > 0],
    result["RemainderPower"], result["Remainder"] =!= 0}],
  {True, 3, True}, TestID -> "inverse-expression-observable-does-not-invent-input-remainder-coefficients"]

VerificationTest[Module[{y, z, input, result},
  input = AsymptoticExpansion[Sin[y], {y, 0, 4}];
  result = SeriesObservable[input, InverseFunction[# + #^2 (1 + Log[#]) &][z], z, "Cutoff" -> 4];
  inverseExpressionEqual[result, inverseExpressionLogOracle[y] - y^3/6, y > 0]],
  True, TestID -> "inverse-expression-observable-composes-a-sufficiently-precise-input"]

VerificationTest[Module[{t, y, operator, branches, s, refined},
  operator = InverseFunction[Function[t, t^2 + t^4 (1 + Log[t^2])]];
  branches = Association[operator -> <|"SourcePoint" -> 0, "Direction" -> "FromAbove"|>];
  s = AsymptoticExpansion[operator[y], {y, 0, 1}, "InverseFunctionBranches" -> branches];
  refined = SeriesRefine[s, 2];
  {inverseExpressionEqual[refined, Sqrt[y] - y^(3/2) (1 + Log[y])/2, y > 0],
    refined["InverseFunctionBranches"] === branches}],
  {True, True}, TestID -> "inverse-expression-refinement-preserves-explicit-real-branch-selection"]
