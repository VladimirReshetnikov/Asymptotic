(* Independent coefficients, branch conditions, two scales, and original equations. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];
If[DownValues[AsymptoticInverse`AsymptoticLogarithmicInverse] === {},
  Begin["AsymptoticInverse`Private`"];
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "LogarithmicScales.wl"}]];
  End[]];

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, 5}];
    {s["Terms"], s["RemainderPower"], s["RemainderLogDegree"], s["LogarithmicLevels"]}],
  {{{0, 1}, {1, 1}, {2, 1}, {3, 2}, {4, 7/2}}, 5, 0, 1},
  TestID -> "logs-reciprocal-unit-independent-five-coefficients-at-zero"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x + x/Log[x], {x, Infinity}, {y, 5}];
    {s["Terms"], TrueQ[FullSimplify[s["RemainderVariable"] == 1/Log[y], y > 1]]}],
  {{{0, 1}, {1, -1}, {2, 1}, {3, -2}, {4, 7/2}}, True},
  TestID -> "logs-reciprocal-unit-infinity-observable-sign"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, 5}];
    LogarithmicInverseResidual[s][["Vanishes"]]],
  True, TestID -> "logs-reciprocal-unit-formal-equation-residual"]

VerificationTest[
  Module[{x, y, s, core},
    core = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, 4}];
    s = AsymptoticLogarithmicInverse[x + x/Log[x] + x^2, {x, 0}, {y, 4}];
    {s["Terms"] === core["Terms"], s["LeadingCoreOnly"], s["ExactModel"],
     s["BeyondLogarithmicRemainderScale"] =!= 0, s["RemainderPower"]}],
  {True, True, False, True, 4}, TestID -> "logs-mixed-power-sector-distinguished-from-log-tail"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x + x/Log[x] - x/(1 + Log[x]), {x, 0}, {y, 4}];
    {FreeQ[s["Terms"][[All, 1]], 1], Cases[s["Terms"], {2, c_} :> c]}],
  {True, {-1}}, TestID -> "logs-cancelled-first-reciprocal-log-correction"]

VerificationTest[
  Module[{x, y, b, s},
    s = AsymptoticLogarithmicInverse[x (1 + b/Log[x]), {x, 0}, {y, 3}, Assumptions -> Element[b, Reals]];
    TrueQ[Simplify[Cases[s["Terms"], {1, c_} :> c] == {b}, Element[b, Reals]]]],
  True, TestID -> "logs-real-symbolic-reciprocal-coefficient"]

VerificationTest[
  Module[{x, y, b},
    MatchQ[AsymptoticLogarithmicInverse[x (1 + b/Log[x]), {x, 0}, {y, 3}], Failure["UnsupportedLogarithmicScale", _]]],
  True, TestID -> "logs-unproved-real-coefficient-rejected"]

VerificationTest[
  Module[{x, y, s, expected},
    s = AsymptoticLogarithmicInverse[x + x^2 Sqrt[-Log[x]], {x, 0}, {y, 4}];
    expected = y - y^2 Sqrt[-Log[y]] + y^3 (-2 Log[y] - 1/2);
    {TrueQ[FullSimplify[Normal[s] == expected, 0 < y < Exp[-2]]],
     s["RemainderPower"], s["RemainderLogDegree"], s["Scale"]}],
  {True, 4, 3, "GeneralizedLogarithmicCoefficients"},
  TestID -> "logs-square-root-log-coefficient-independent-inverse"]

VerificationTest[
  Module[{x, y, s, t, expected},
    s = AsymptoticLogarithmicInverse[x + x^2 Log[-Log[x]], {x, 0}, {y, 4}];
    t = -Log[y]; expected = y - y^2 Log[t] + y^3 (2 Log[t]^2 - Log[t]/t);
    {TrueQ[FullSimplify[Normal[s] == expected, 0 < y < Exp[-E]]], s["LogarithmicLevels"]}],
  {True, 2}, TestID -> "logs-iterated-log-coefficient-independent-inverse"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x^2 + x^3 Sqrt[-Log[x]], {x, 0}, {y, 3/2}];
    TrueQ[FullSimplify[Normal[s] == Sqrt[y] - y Sqrt[-Log[y]/2]/2, 0 < y < Exp[-2]]]],
  True, TestID -> "logs-nonunit-core-uses-target-power-cutoff"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x + x^Sqrt[2] Sqrt[-Log[x]], {x, 0}, {y, 3/2}];
    TrueQ[FullSimplify[Normal[s] == y - y^Sqrt[2] Sqrt[-Log[y]], 0 < y < Exp[-2]]]],
  True, TestID -> "logs-irrational-positive-power-gap"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x + Sqrt[Log[x]]/x, {x, Infinity}, {y, 2}];
    {TrueQ[FullSimplify[Normal[s] == y - Sqrt[Log[y]]/y, y > Exp[2]]], s["RemainderPower"]}],
  {True, 3}, TestID -> "logs-infinite-source-generalized-coefficient-error"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x - 3 + (x - 3)^2 Sqrt[-Log[x - 3]], {x, 3}, {y, 3}];
    TrueQ[FullSimplify[Normal[s] == 3 + y - y^2 Sqrt[-Log[y]], 0 < y < Exp[-2]]]],
  True, TestID -> "logs-shifted-source-distance-preserved"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[-x + x^2 Sqrt[-Log[-x]], {x, 0}, {y, 3}, Direction -> "FromBelow"];
    TrueQ[FullSimplify[Normal[s] == -y + y^2 Sqrt[-Log[y]], 0 < y < Exp[-2]]]],
  True, TestID -> "logs-from-below-real-hierarchy-preserved"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticLogarithmicInverse[x + x^2 Sqrt[Log[x]], {x, 0}, {y, 3}], Failure["UnsupportedLogarithmicScale", _]]],
  True, TestID -> "logs-negative-square-root-log-domain-rejected"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticLogarithmicInverse[x + x^2 Log[-Log[x]], {x, 0}, {y, 3}, "LogarithmicLevels" -> 1], Failure["UnsupportedLogarithmicScale", _]]],
  True, TestID -> "logs-declared-hierarchy-depth-is-enforced"]

VerificationTest[
  Module[{x, y, s, b},
    s = AsymptoticLogarithmicInverse[x Log[Log[x]], {x, Infinity}, {y, 3}];
    b = Log[Log[y]];
    {TrueQ[FullSimplify[s["Prefactor"] == y/b, y > Exp[E]]],
     TrueQ[FullSimplify[Cases[s["Terms"], {1, c_} :> c] == {Log[b]/b}, y > Exp[E]]],
     s["Scale"], s["LogarithmicLevels"]}],
  {True, True, "LeadingLogMonomial", 2}, TestID -> "logs-leading-iterated-log-core-first-correction"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x Log[Log[x]], {x, Infinity}, {y, 4}];
    LogarithmicInverseResidual[s][["Vanishes"]]],
  True, TestID -> "logs-leading-iterated-log-core-formal-residual"]

VerificationTest[
  Module[{x, y, low, high},
    low = AsymptoticLogarithmicInverse[x Log[Log[x]], {x, Infinity}, {y, 2}];
    high = AsymptoticLogarithmicInverse[x Log[Log[x]], {x, Infinity}, {y, 4}];
    {TrueQ[FullSimplify[low["Terms"] == Take[high["Terms"], Length[low["Terms"]]], y > Exp[E]]],
     low["RemainderPower"] < high["RemainderPower"]}],
  {True, True}, TestID -> "logs-two-logarithmic-cutoffs-preserve-prior-blocks"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x Log[x] Log[Log[x]], {x, Infinity}, {y, 3}];
    {LogarithmicInverseResidual[s][["Vanishes"]],
     TrueQ[FullSimplify[s["Prefactor"] == y/(Log[y] Log[Log[y]]), y > Exp[E]]]}],
  {True, True}, TestID -> "logs-product-of-leading-log-levels"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x Sqrt[Log[Log[x]]], {x, Infinity}, {y, 3}];
    LogarithmicInverseResidual[s][["Vanishes"]]],
  True, TestID -> "logs-real-power-of-leading-iterated-log"]

VerificationTest[
  Module[{u, l1, l2, c, chain, direct},
    c = Sqrt[l1]/l2^2;
    chain = AsymptoticInverse`Private`logarithmicEuler[c, {l1, l2}] /. {l1 -> -Log[u], l2 -> Log[-Log[u]]};
    direct = u D[Sqrt[-Log[u]]/Log[-Log[u]]^2, u];
    TrueQ[FullSimplify[chain == direct, 0 < u < Exp[-E]]]],
  True, TestID -> "logs-generalized-coefficient-Euler-derivative-closure"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, 5}, "MaxTerms" -> 3], Failure["ResourceLimit", _]]],
  True, TestID -> "logs-logarithmic-iteration-budget"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, 3}, "InputRemainder" -> {2, 0}], Failure["UnsupportedOption", _]]],
  True, TestID -> "logs-untransported-input-error-rejected"]

VerificationTest[
  Module[{x, y, s, xx, yy, error, bound},
    s = AsymptoticLogarithmicInverse[x + x/Log[x] + x^2, {x, 0}, {y, 5}];
    xx = N[Exp[-40], 90]; yy = xx + xx/Log[xx] + xx^2;
    error = Abs[N[Normal[s] /. y -> yy, 70] - xx];
    bound = N[s["RemainderScaleExpression"] /. y -> yy, 70];
    TrueQ[0 < error < 20 bound]],
  True, TestID -> "logs-mixed-unit-original-equation-numerical-oracle"]

VerificationTest[
  Module[{x, y, s, xx, yy, error, bound},
    s = AsymptoticLogarithmicInverse[x + x^2 Log[-Log[x]], {x, 0}, {y, 4}];
    xx = N[Exp[-20], 100]; yy = xx + xx^2 Log[-Log[xx]];
    error = Abs[N[Normal[s] /. y -> yy, 80] - xx];
    bound = N[s["RemainderScaleExpression"] /. y -> yy, 80];
    TrueQ[0 < error < bound]],
  True, TestID -> "logs-iterated-coefficient-original-equation-numerical-oracle"]

VerificationTest[
  Module[{x, y, s, xx, yy, error, bound},
    s = AsymptoticLogarithmicInverse[x Log[Log[x]], {x, Infinity}, {y, 4}];
    xx = N[Exp[50], 100]; yy = xx Log[Log[xx]];
    error = Abs[N[Normal[s] /. y -> yy, 80] - xx];
    bound = N[s["RemainderScaleExpression"] /. y -> yy, 80];
    TrueQ[0 < error < bound]],
  True, TestID -> "logs-leading-nested-core-original-equation-numerical-oracle"]

(* Block goals skip cancellations and leave exponent cutoffs unchanged. *)
VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x + x/Log[x] - x/(1 + Log[x]), {x, 0}, y, SeriesTermGoal -> 3];
    {s["Terms"], s["RequestedTermGoal"], s["ReturnedTermCount"],
      s["TermGoalReached"], LogarithmicInverseResidual[s]["Vanishes"]}],
  {{{0, 1}, {2, -1}, {3, -1}}, 3, 3, True, True},
  TestID -> "logs-term-goal-skips-cancelled-reciprocal-block"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x + x/Log[x] - x/(1 + Log[x]),
      {x, Infinity}, y, SeriesTermGoal -> 3];
    {s["Terms"], s["ReturnedTermCount"]}],
  {{{0, 1}, {2, -1}, {3, 1}}, 3},
  TestID -> "logs-term-goal-at-infinity-counts-observable-blocks"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x + x/Log[x] - x/(1 + Log[x]),
      {x, 0}, y, SeriesTermGoal -> 3, "Power" -> 2];
    {s["Terms"], s["ReturnedTermCount"], s["Power"]}],
  {{{0, 1}, {2, -2}, {3, -2}}, 3, 2},
  TestID -> "logs-term-goal-counts-requested-power-after-cancellation"]

VerificationTest[
  Module[{x, y, s, explicit},
    s = AsymptoticLogarithmicInverse[x Log[Log[x]], {x, Infinity}, y, SeriesTermGoal -> 3];
    explicit = AsymptoticLogarithmicInverse[x Log[Log[x]], {x, Infinity}, {y, 3}];
    {s["ReturnedTermCount"], TrueQ[FullSimplify[Normal[s] == Normal[explicit], y > Exp[E]]],
      LogarithmicInverseResidual[s]["Vanishes"]}],
  {3, True, True}, TestID -> "logs-term-goal-leading-nested-core"]

VerificationTest[
  Module[{x, y, s, ell},
    s = AsymptoticLogarithmicInverse[x + x^2 Sqrt[-Log[x]], {x, 0}, y, SeriesTermGoal -> 3];
    ell = -Log[y];
    {s["ReturnedTermCount"], TrueQ[FullSimplify[
      Normal[s] == y - y^2 Sqrt[ell] + y^3 (2 ell - 1/2), 0 < y < Exp[-2]]]}],
  {3, True}, TestID -> "logs-term-goal-generalized-coefficients-independent-oracle"]

VerificationTest[
  Module[{x, y, s, ell, expected},
    s = AsymptoticLogarithmicInverse[
      x + x^2 Sqrt[-Log[x]] + x^3 (-2 Log[x] - 1/2), {x, 0}, y, SeriesTermGoal -> 3];
    ell = -Log[y];
    expected = y - y^2 Sqrt[ell] + y^4 (5 ell^(3/2) - 11 Sqrt[ell]/4 + 1/(8 Sqrt[ell]));
    {s["Terms"][[All, 1]], s["ReturnedTermCount"],
      TrueQ[FullSimplify[Normal[s] == expected, 0 < y < Exp[-2]]]}],
  {{1, 2, 4}, 3, True}, TestID -> "logs-term-goal-merges-resonance-before-counting"]

VerificationTest[
  Module[{x, y, s, ell},
    s = AsymptoticLogarithmicInverse[x + x^Sqrt[2] Sqrt[-Log[x]], {x, 0}, y, SeriesTermGoal -> 3];
    ell = -Log[y];
    {s["ReturnedTermCount"], TrueQ[FullSimplify[
      Normal[s] == y - y^Sqrt[2] Sqrt[ell] + y^(2 Sqrt[2] - 1) (Sqrt[2] ell - 1/2),
      0 < y < Exp[-2]]]}],
  {3, True}, TestID -> "logs-term-goal-irrational-weight-independent-oracle"]

VerificationTest[
  Module[{x, y, s, refined},
    s = AsymptoticLogarithmicInverse[x + Sqrt[x] Sqrt[Log[x]], {x, Infinity}, y, SeriesTermGoal -> 1];
    refined = SeriesRefine[s, -1/4];
    {s["Cutoff"] < 0, Normal[s] === y, Length[refined["Blocks"]],
      TrueQ[FullSimplify[Normal[refined] == y - Sqrt[y] Sqrt[Log[y]], y > Exp[2]]]}],
  {True, True, 2, True}, TestID -> "logs-negative-target-power-goal-cutoff-can-be-refined"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x (1 + 1/Log[x]^100), {x, 0}, y,
      SeriesTermGoal -> 2, "MaxTerms" -> 8];
    {MatchQ[s, Failure["ResourceLimit", _]],
      MatchQ[s[[2, "BestExpansion"]], GeneralizedSeries[_Association]],
      s[[2, "BestExpansion"]]["Remainder"] =!= 0}],
  {True, True, True}, TestID -> "logs-zero-prefix-never-falsely-certifies-termination"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x + x/Log[x] - x/(1 + Log[x]),
      {x, 0}, {y, 3}, SeriesTermGoal -> 20];
    {s["Terms"], s["Cutoff"]}],
  {{{0, 1}, {2, -1}}, 3}, TestID -> "logs-explicit-cutoff-is-not-replaced-by-term-goal"]

VerificationTest[
  Module[{x, y},
    {MatchQ[AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, y, SeriesTermGoal -> 0], Failure["InvalidCutoff", _]],
      MatchQ[AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, y, SeriesTermGoal -> 9,
        "MaxTerms" -> 8], Failure["ResourceLimit", _]],
      MatchQ[AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, -1}], Failure["InvalidCutoff", _]],
      MatchQ[AsymptoticLogarithmicInverse[x + Sqrt[x] Sqrt[Log[x]], {x, Infinity}, {y, -1}],
        Failure["CutoffTooSmall", _]]}],
  {True, True, True, True}, TestID -> "logs-term-goal-and-scale-specific-cutoff-validation"]

VerificationTest[
  Module[{x, y, u, result, certificate},
    (* The exact-composition checker must distinguish the source sign from
       the approach direction: +Infinity is approached FromBelow. *)
    result = GeneralizedSeries[<|"ExactModel" -> True, "Function" -> x^2,
      "Expression" -> Sqrt[y], "Variables" -> {x, y}, "Power" -> 1,
      "ExpansionPoint" -> Infinity, "Direction" -> "FromBelow",
      "LocalSubstitution" -> (x -> 1/u), "LocalVariable" -> u,
      "TargetDomain" -> y > 1, "Blocks" -> {{0, 1}}, "Remainder" -> y^-1|>];
    certificate = AsymptoticInverse`Private`logarithmicGoalTermination[result];
    {certificate["Remainder"], certificate["ExactTerminationCertificate"]["Verified"],
      TrueQ[FullSimplify[certificate["ExactTerminationCertificate"]["Candidate"] == Sqrt[y], y > 1]]}],
  {0, True, True}, TestID -> "logs-exact-termination-reconstructs-positive-infinite-source"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x + (x Log[x])^(2/3), {x, Infinity}, y, SeriesTermGoal -> 2];
    {s["ReturnedTermCount"], TrueQ[FullSimplify[
      Normal[s] == y - (y Log[y])^(2/3), y > Exp[2]]]}],
  {2, True}, TestID -> "logs-positive-monomial-factor-extracted-from-real-power"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticLogarithmicInverse[x + x^2 Sqrt[-Log[x] Log[-Log[x]]],
      {x, 0}, y, SeriesTermGoal -> 2];
    {s["ReturnedTermCount"], TrueQ[FullSimplify[
      Normal[s] == y - y^2 Sqrt[-Log[y] Log[-Log[y]]], 0 < y < Exp[-E]]]}],
  {2, True}, TestID -> "logs-positive-level-products-inside-square-root"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticLogarithmicInverse[x + x^2 Sqrt[Log[x] Log[-Log[x]]],
      {x, 0}, y, SeriesTermGoal -> 2], Failure["UnsupportedLogarithmicScale", _]]],
  True, TestID -> "logs-negative-level-product-square-root-remains-rejected"]
