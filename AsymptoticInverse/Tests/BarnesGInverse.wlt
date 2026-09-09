(* Independent inversion of the logarithmic Barnes expansion in DLMF 5.17.5.
   Put Y=Log[y], X=Sqrt[4Y/ProductLog[4Y/Exp[3]]], q=1/(Log[X]-1),
   a=Log[2Pi]/2, g=Log[Glaisher]. Writing the Barnes argument as
     1+X+A+B/X+C/X^2+D/X^3
   and Taylor-expanding its logarithm at X gives the coefficients below.
   Exact symbolic Taylor substitution independently verifies the equations
   through the fourth correction. Neither package reversion nor numerical
   fitting supplies expected coefficients. The numerical target G[100]
   has independently known source root 100 by its defining recurrence. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

barnesInverseOracleCore[y_] := Sqrt[4 y/ProductLog[4 y/Exp[3]]];
barnesInverseOracleCoefficients[q_] := Module[{a, g, aa, b, c, d},
  a = Log[2 Pi]/2; g = Log[Glaisher]; aa = -a q;
  b = 1/12 + g q + a^2 q^2 (1 - q)/2;
  c = a g q^3 + a^3 (2 q^4/3 - q^5/2);
  d = Together[-q (aa c + (1 + 1/q) b^2/2 + aa^2 b/2 - aa^4/24 -
      b/12 + aa^2/24 - 1/240)];
  {1 + aa, b, c, d}];
barnesInverseOracle[y_, count_Integer] := Module[{core, coefficients},
  core = barnesInverseOracleCore[y];
  coefficients = barnesInverseOracleCoefficients[1/(Log[core] - 1)];
  core + Sum[coefficients[[j + 1]]/core^j, {j, 0, count - 2}]];
barnesInversePowerOracle[y_, r_, count_Integer] := Module[{core, a, b, c, d, coefficients},
  core = barnesInverseOracleCore[y];
  {a, b, c, d} = barnesInverseOracleCoefficients[1/(Log[core] - 1)];
  coefficients = {1, r a, r b + r (r - 1) a^2/2,
    r c + r (r - 1) a b + r (r - 1) (r - 2) a^3/6,
    r d + r (r - 1) (a c + b^2/2) + r (r - 1) (r - 2) a^2 b/2 +
      r (r - 1) (r - 2) (r - 3) a^4/24};
  Sum[coefficients[[j + 1]] core^(r - j), {j, 0, count - 1}]];
barnesInverseEqual[actual_, expected_] := Module[{difference = Together[actual - expected]},
  TrueQ[difference === 0] ||
    TrueQ[TimeConstrained[FullSimplify[difference], 15, $Aborted] === 0]];
barnesInverseExpansionEqual[s_, expected_] := MatchQ[s, _PowerLogSeries] &&
  barnesInverseEqual[Normal[s], expected];
barnesInverseTermsEqual[s_, count_Integer] := Module[{q, expected, actual},
  If[! MatchQ[s, _PowerLogSeries], Return[False, Module]];
  q = s["CoefficientVariable"];
  expected = Prepend[MapIndexed[{First[#2] - 1, #1} &,
    Take[barnesInverseOracleCoefficients[q], count - 1]], {-1, 1}];
  actual = s["Terms"];
  ListQ[actual] && Length[actual] === count &&
    And @@ MapThread[(#1[[1]] === #2[[1]] && barnesInverseEqual[#1[[2]], #2[[2]]]) &,
      {actual, expected}]];

VerificationTest[Module[{x, z, s, source, core, q, coefficients},
  s = AsymptoticExpansion[InverseFunction[
    x |-> ConditionalExpression[BarnesG[x], x > 3]][z], z -> Infinity, SeriesTermGoal -> 3];
  If[! MatchQ[s, _PowerLogSeries], Return[s, Module]];
  source = s["SourceVariable"]; core = barnesInverseOracleCore[Log[z]];
  q = s["CoefficientVariable"];
  coefficients = barnesInverseOracleCoefficients[1/(Log[core] - 1)];
  {barnesInverseExpansionEqual[s, barnesInverseOracle[Log[z], 3]],
    barnesInverseTermsEqual[s, 3], barnesInverseEqual[s["CoreInverse"], core],
    s["Kind"], s["Scale"], s["ReturnedTermCount"], s["RemainderPower"],
    s["RemainderInverseLogPower"],
    barnesInverseEqual[s["CoreLogExpression"], Log[core] - 1],
    barnesInverseEqual[q /. s["CoefficientSubstitution"], 1/(Log[core] - 1)],
    barnesInverseEqual[s["FrontierTerm"], coefficients[[3]]/core^2],
    s["InverseFunctionBranch"]["ConditionalDomainVerified"],
    TrueQ[(s["SourceDomain"] /. source -> 3) === False],
    TrueQ[s["SourceDomain"] /. source -> 4]}],
  {True, True, True, "BarnesGInverse", "BarnesGInverse", 3, 2, 3,
    True, True, True, True, True, True},
  TestID -> "barnes-g-inverse-user-three-independent-blocks-and-shifted-inverse-log-frontier"]

VerificationTest[Module[{t, y, named, applied},
  named = AsymptoticExpansion[InverseFunction[
    Function[{t}, ConditionalExpression[BarnesG[t], t > 3]]],
    {y, Infinity}, SeriesTermGoal -> 2];
  applied = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[BarnesG[#], # > 3] &][y], {y, Infinity, 3/2}];
  {barnesInverseExpansionEqual[named, barnesInverseOracle[Log[y], 2]], FreeQ[Normal[named], t],
    barnesInverseExpansionEqual[applied, barnesInverseOracle[Log[y], 3]],
    applied["ReturnedTermCount"], applied["RemainderPower"]}],
  {True, True, True, 3, 2},
  TestID -> "barnes-g-inverse-named-and-applied-callables-preserve-bindings-and-fractional-cutoff"]

VerificationTest[Module[{x, y, barnes, logarithm},
  barnes = AsymptoticInverse[BarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 3];
  logarithm = AsymptoticInverse[Log[BarnesG[x]], {x, Infinity}, y, SeriesTermGoal -> 3];
  {barnesInverseExpansionEqual[barnes, barnesInverseOracle[Log[y], 3]],
    barnesInverseExpansionEqual[logarithm, barnesInverseOracle[y, 3]],
    barnesInverseTermsEqual[logarithm, 3], barnes["RemainderPower"], logarithm["RemainderPower"]}],
  {True, True, True, 2, 2},
  TestID -> "barnes-g-inverse-direct-Barnes-and-logarithm-use-original-target-coordinate"]

VerificationTest[Module[{x, y, one, two, core, coefficients},
  one = AsymptoticInverse[BarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 1];
  two = AsymptoticInverse[BarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 2];
  core = barnesInverseOracleCore[Log[y]];
  coefficients = barnesInverseOracleCoefficients[1/(Log[core] - 1)];
  {barnesInverseExpansionEqual[one, core], one["RemainderPower"], one["RemainderInverseLogPower"],
    barnesInverseEqual[one["FrontierTerm"], coefficients[[1]]],
    barnesInverseExpansionEqual[two, core + coefficients[[1]]],
    two["RemainderPower"], two["RemainderInverseLogPower"],
    barnesInverseEqual[two["FrontierTerm"], coefficients[[2]]/core]}],
  {True, 0, 0, True, True, 1, 0, True},
  TestID -> "barnes-g-inverse-one-and-two-block-goals-retain-correct-nonzero-tails"]

VerificationTest[Module[{x, y, s, shortened, raised},
  s = AsymptoticInverse[BarnesG[x], {x, Infinity}, {y, 3/2}];
  shortened = SeriesTruncate[s, 1]; raised = SeriesTruncate[shortened, 10];
  {barnesInverseExpansionEqual[s, barnesInverseOracle[Log[y], 3]], s["RemainderPower"],
    barnesInverseExpansionEqual[shortened, barnesInverseOracle[Log[y], 2]],
    shortened["RemainderPower"], shortened["RemainderInverseLogPower"],
    barnesInverseExpansionEqual[raised, Normal[shortened]], raised["RemainderPower"],
    Quiet[MatchQ[SeriesTruncate[s, 1, "MaxTerms" -> 0], Failure["InvalidOption", _Association]]]}],
  {True, 2, True, 1, 0, True, 1, True},
  TestID -> "barnes-g-inverse-exclusive-truncation-cannot-recover-discarded-blocks"]

VerificationTest[Module[{x, y, s, refined, core, coefficients},
  s = AsymptoticInverse[BarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 3]; core = barnesInverseOracleCore[Log[y]];
  coefficients = barnesInverseOracleCoefficients[1/(Log[core] - 1)];
  {barnesInverseExpansionEqual[refined, barnesInverseOracle[Log[y], 4]],
    barnesInverseTermsEqual[refined, 4], refined["RemainderPower"], refined["RemainderInverseLogPower"],
    barnesInverseEqual[refined["FrontierTerm"], coefficients[[4]]/core^3]}],
  {True, True, 3, 0, True},
  TestID -> "barnes-g-inverse-refinement-computes-fourth-block-and-independent-next-coefficient"]

VerificationTest[Module[{y, s, refined, source},
  s = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[BarnesG[#], # > 100] &], y -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 3]; source = refined["SourceVariable"];
  {barnesInverseExpansionEqual[refined, barnesInverseOracle[Log[y], 4]],
    TrueQ[(refined["SourceDomain"] /. source -> 100) === False],
    TrueQ[refined["SourceDomain"] /. source -> 101]}],
  {True, True, True},
  TestID -> "barnes-g-inverse-refinement-preserves-strict-callable-source-condition"]

VerificationTest[Module[{y, s, refined},
  s = AsymptoticExpansion[ConditionalExpression[InverseFunction[
    ConditionalExpression[BarnesG[#], # > 3] &][y], y > 1000],
    y -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 2];
  {barnesInverseExpansionEqual[refined, barnesInverseOracle[Log[y], 3]],
    TrueQ[(s["TargetDomain"] /. y -> 1000) === False],
    TrueQ[(refined["TargetDomain"] /. y -> 1000) === False],
    TrueQ[refined["TargetDomain"] /. y -> 1001]}],
  {True, True, True, True},
  TestID -> "barnes-g-inverse-outer-target-condition-survives-source-replay"]

VerificationTest[Module[{x, y, s, shifted},
  s = AsymptoticInverse[BarnesG[2 x + 3], {x, Infinity}, y, SeriesTermGoal -> 3];
  shifted = AsymptoticInverse[BarnesG[x + 1], {x, Infinity}, y, SeriesTermGoal -> 3];
  {barnesInverseExpansionEqual[s, (barnesInverseOracle[Log[y], 3] - 3)/2],
    s["RemainderPower"], TrueQ[(s["SourceDomain"] /. x -> 0) === False],
    TrueQ[s["SourceDomain"] /. x -> 1],
    barnesInverseExpansionEqual[shifted, barnesInverseOracle[Log[y], 3] - 1]}],
  {True, 2, True, True, True},
  TestID -> "barnes-g-inverse-affine-source-transports-the-unit-Barnes-shift"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticInverse[7 - 2 Log[BarnesG[3 - 2 x]], {x, -Infinity}, y, SeriesTermGoal -> 3];
  {barnesInverseExpansionEqual[s, (3 - barnesInverseOracle[(7 - y)/2, 3])/2],
    s["Direction"], s["RemainderPower"],
    TrueQ[(s["SourceDomain"] /. x -> 0) === False], TrueQ[s["SourceDomain"] /. x -> -1]}],
  {True, "FromAbove", 2, True, True},
  TestID -> "barnes-g-inverse-logarithmic-signed-target-and-negative-affine-source"]

VerificationTest[Module[{x, y, powered, reciprocal},
  powered = AsymptoticInverse[7 - 2 BarnesG[x]^2, {x, Infinity}, y, SeriesTermGoal -> 3];
  reciprocal = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[1/BarnesG[#], # > 3] &][y], y -> 0, SeriesTermGoal -> 3];
  {barnesInverseExpansionEqual[powered, barnesInverseOracle[Log[(7 - y)/2]/2, 3]],
    barnesInverseExpansionEqual[reciprocal, barnesInverseOracle[-Log[y], 3]],
    reciprocal["RemainderPower"], TrueQ[reciprocal["TargetDomain"] /. y -> 1/100],
    TrueQ[(reciprocal["TargetDomain"] /. y -> -1/100) === False]}],
  {True, True, 2, True, True},
  TestID -> "barnes-g-inverse-fixed-forward-power-and-reciprocal-target-at-zero"]

VerificationTest[Module[{x, y, square, reciprocal, irrational},
  square = AsymptoticInverse[BarnesG[x], {x, Infinity}, y, "Power" -> 2, SeriesTermGoal -> 3];
  reciprocal = AsymptoticInverse[BarnesG[x], {x, Infinity}, y, "Power" -> -1, SeriesTermGoal -> 3];
  irrational = AsymptoticInverse[BarnesG[x], {x, Infinity}, y, "Power" -> Sqrt[2], SeriesTermGoal -> 3];
  {barnesInverseExpansionEqual[square, barnesInversePowerOracle[Log[y], 2, 3]], square["RemainderPower"],
    barnesInverseExpansionEqual[reciprocal, barnesInversePowerOracle[Log[y], -1, 3]], reciprocal["RemainderPower"],
    barnesInverseExpansionEqual[irrational, barnesInversePowerOracle[Log[y], Sqrt[2], 3]],
    barnesInverseEqual[irrational["RemainderPower"], 3 - Sqrt[2]]}],
  {True, 1, True, 4, True, True},
  TestID -> "barnes-g-inverse-source-observables-use-independent-binomial-coefficients"]

VerificationTest[Module[{x, y, s, square, reciprocal, refined},
  s = AsymptoticInverse[BarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 3];
  square = SeriesPower[s, 2, 4]; reciprocal = SeriesPower[s, -1];
  refined = SeriesRefine[square, 2];
  {barnesInverseExpansionEqual[square, barnesInversePowerOracle[Log[y], 2, 3]], square["RemainderPower"],
    barnesInverseExpansionEqual[reciprocal, barnesInversePowerOracle[Log[y], -1, 3]], reciprocal["RemainderPower"],
    barnesInverseExpansionEqual[refined, barnesInversePowerOracle[Log[y], 2, 4]], refined["RemainderPower"]}],
  {True, 1, True, 4, True, 2},
  TestID -> "barnes-g-inverse-SeriesPower-respects-input-ceiling-and-refines-exact-source"]

VerificationTest[Module[{y, s, refined},
  s = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[BarnesG[#], # > 3] &][y]^2, y -> Infinity, SeriesTermGoal -> 3];
  refined = SeriesRefine[s, 2];
  {barnesInverseExpansionEqual[s, barnesInversePowerOracle[Log[y], 2, 3]],
    s["ReturnedTermCount"], s["RemainderPower"],
    barnesInverseExpansionEqual[refined, barnesInversePowerOracle[Log[y], 2, 4]], refined["RemainderPower"]}],
  {True, 3, 1, True, 2},
  TestID -> "barnes-g-inverse-powered-applied-callable-counts-complete-observable-blocks"]

VerificationTest[Module[{x, y, s, check, target, signedError, frontier},
  s = AsymptoticInverse[BarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 3];
  target = BarnesG[100]; check = InverseNumericalCheck[s, target, WorkingPrecision -> 60];
  signedError = N[100 - (Normal[s] /. y -> target), 60];
  frontier = N[s["FrontierTerm"] /. y -> target, 60];
  {AssociationQ[check], check["Certified"], TrueQ[Abs[check["ReferenceRoot"] - 100] < 10^-45],
    TrueQ[0 < signedError], TrueQ[95/100 < signedError/frontier < 105/100],
    TrueQ[Abs[check["Error"] - Abs[signedError]] < 10^-45]}],
  {True, False, True, True, True, True},
  TestID -> "barnes-g-inverse-exact-integer-target-confirms-root-and-first-omitted-scale"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[BarnesG[#], # > 100] &], y -> Infinity, SeriesTermGoal -> 3];
  Quiet[{MatchQ[InverseNumericalCheck[s, BarnesG[30], WorkingPrecision -> 60],
      Failure["OutsideBranch", _Association]],
    MatchQ[InverseNumericalCheck[s, N[BarnesG[100], 20], WorkingPrecision -> 60],
      Failure["InsufficientPrecision", _Association]]}]],
  {True, True},
  TestID -> "barnes-g-inverse-numerical-evidence-validates-source-domain-and-target-precision"]

VerificationTest[Module[{x, y, s, check, extended, q, c},
  s = AsymptoticInverse[BarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 3];
  check = InverseResidual[s]; extended = InverseResidual[s, 4];
  q = s["CoefficientVariable"]; c = barnesInverseOracleCoefficients[q][[3]];
  {check["ZeroBelowCutoff"], check["ResidualBlocks"], check["ExactModel"],
    extended["ZeroBelowCutoff"], extended["ResidualBlocks"][[All, 1]],
    barnesInverseEqual[extended["ResidualBlocks"][[1, 2]], -c]}],
  {True, {}, False, False, {3}, True},
  TestID -> "barnes-g-inverse-finite-model-residual-exposes-first-omitted-source-block"]

VerificationTest[Module[{x, y, negativeSquare},
  negativeSquare = AsymptoticInverse[BarnesG[-x], {x, -Infinity}, y,
    "Power" -> 2, SeriesTermGoal -> 3];
  Quiet[{FailureQ[AsymptoticInverse[BarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 0]],
    FailureQ[AsymptoticInverse[BarnesG[x], {x, Infinity}, {y, -1}]],
    FailureQ[AsymptoticInverse[BarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 3, "MaxTerms" -> 1]],
    FailureQ[AsymptoticInverse[BarnesG[x], {x, Infinity}, y, "Power" -> I, SeriesTermGoal -> 3]],
    MatchQ[negativeSquare, _PowerLogSeries], FailureQ[SeriesPower[negativeSquare, 1/2]]}]],
  {True, True, True, True, True, True},
  TestID -> "barnes-g-inverse-validates-orders-resources-and-negative-source-power-branches"]

VerificationTest[Module[{t, y, operator, s, source, original},
  operator = InverseFunction[Function[t, ConditionalExpression[BarnesG[t], t > 0]]];
  s = AsymptoticExpansion[operator[y], y -> Infinity, SeriesTermGoal -> 3,
    "InverseFunctionBranches" -> Association[
      operator -> <|"SourcePoint" -> Infinity, "Direction" -> "FromBelow"|>]];
  If[! MatchQ[s, _PowerLogSeries], Return[s, Module]];
  source = s["SourceVariable"]; original = s["InverseFunctionBranch"]["OriginalCondition"];
  {barnesInverseExpansionEqual[s, barnesInverseOracle[Log[y], 3]],
    s["InverseFunctionBranch"]["SourcePoint"],
    TrueQ[(original /. source -> 0) === False], TrueQ[original /. source -> 1],
    TrueQ[(s["SourceDomain"] /. source -> 3) === False],
    TrueQ[s["SourceDomain"] /. source -> 4]}],
  {True, Infinity, True, True, True, True},
  TestID -> "barnes-g-inverse-explicit-infinity-selection-preserves-broader-original-condition"]

VerificationTest[Module[{t, y, operator},
  operator = InverseFunction[Function[t, ConditionalExpression[BarnesG[t], t > 3]]];
  Quiet[FailureQ[AsymptoticExpansion[operator[y], y -> Infinity, SeriesTermGoal -> 3,
    "InverseFunctionBranches" -> Association[
      operator -> <|"SourcePoint" -> Infinity, "Direction" -> "FromAbove"|>]]]]],
  True,
  TestID -> "barnes-g-inverse-explicit-positive-infinity-direction-must-approach-from-below"]

VerificationTest[Module[{t, y, operator},
  operator = InverseFunction[Function[t, ConditionalExpression[BarnesG[t], t < 3]]];
  Quiet[FailureQ[AsymptoticExpansion[operator[y], y -> Infinity, SeriesTermGoal -> 3,
    "InverseFunctionBranches" -> Association[
      operator -> <|"SourcePoint" -> Infinity, "Direction" -> "FromBelow"|>]]]]],
  True,
  TestID -> "barnes-g-inverse-explicit-infinity-branch-rejects-eventually-false-source-condition"]

VerificationTest[Module[{y, s, zeroPower, refined},
  s = AsymptoticExpansion[ConditionalExpression[InverseFunction[
    ConditionalExpression[BarnesG[#], # > 3] &][y], y > 1000],
    y -> Infinity, SeriesTermGoal -> 3];
  zeroPower = SeriesPower[s, 0]; refined = SeriesRefine[zeroPower, 3];
  {barnesInverseExpansionEqual[zeroPower, 1], zeroPower["Remainder"],
    barnesInverseExpansionEqual[refined, 1], refined["Remainder"],
    TrueQ[(zeroPower["TargetDomain"] /. y -> 1000) === False],
    TrueQ[(refined["TargetDomain"] /. y -> 1000) === False],
    TrueQ[refined["TargetDomain"] /. y -> 1001]}],
  {True, 0, True, 0, True, True, True},
  TestID -> "barnes-g-inverse-zero-power-and-refinement-retain-exact-value-and-target-domain"]

VerificationTest[Module[{x, y, s, doubled, shifted},
  s = AsymptoticInverse[BarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 3];
  doubled = SeriesAdd[s, s]; shifted = SeriesAdd[s, 1];
  {MatchQ[doubled, _PowerLogSeries], MatchQ[shifted, _PowerLogSeries],
    Expand[Normal[doubled] - 2 Normal[s]] === 0, Normal[shifted] === 1 + Normal[s],
    doubled["Scale"] === "Composite", shifted["Remainder"] =!= 0}],
  {True, True, True, True, True, True},
  TestID -> "barnes-g-inverse-addition-retains-a-composite-bound-for-inverse-log-coefficients"]

VerificationTest[Module[{x, y, parameter, constant, ass, gamma, logarithm, core, logCore},
  constant = BarnesG[parameter]; ass = Element[constant, Reals];
  gamma = AsymptoticInverse[Gamma[x + constant], {x, Infinity}, y,
    Assumptions -> ass, SeriesTermGoal -> 2];
  logarithm = AsymptoticInverse[LogGamma[x + constant], {x, Infinity}, y,
    Assumptions -> ass, SeriesTermGoal -> 2];
  core = Log[y]/ProductLog[Log[y]/E]; logCore = y/ProductLog[y/E];
  {gamma["Kind"], gamma["GammaFamily"], logarithm["Kind"], logarithm["GammaFamily"],
    gamma["ExactTransformedFunction"] === LogGamma[x + constant],
    logarithm["ExactTransformedFunction"] === LogGamma[x + constant],
    barnesInverseExpansionEqual[gamma, core - constant + 1/2 - Log[2 Pi]/(2 Log[core])],
    barnesInverseExpansionEqual[logarithm,
      logCore - constant + 1/2 - Log[2 Pi]/(2 Log[logCore])]}],
  {"GammaInverse", "Gamma", "GammaInverse", "LogGamma", True, True, True, True},
  TestID -> "barnes-g-inverse-extension-preserves-Gamma-family-with-Barnes-affine-constants"]
