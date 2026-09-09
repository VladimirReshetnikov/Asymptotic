(* Native LogBarnesG is the logarithmic Barnes function on the positive
   real branch. Independent coefficients below follow from DLMF 5.17.5.
   For inverse target Y, H(X)=X^2(Log[X]-3/2)/2=Y, q=1/(Log[X]-1).
   Taylor substitution of 1+X+A+B/X+C/X^2 gives the polynomial coefficients.
   Expected values are not supplied by native Series or package reversion. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

logBarnesInverseCore[y_] := Sqrt[4 y/ProductLog[4 y/Exp[3]]];
logBarnesInverseCoefficients[q_] := Module[{a = Log[2 Pi]/2, g = Log[Glaisher]},
  {1 - a q, 1/12 + g q + a^2 q^2 (1 - q)/2,
    a g q^3 + a^3 (2 q^4/3 - q^5/2)}];
logBarnesInverseOracle[y_, count_Integer] := Module[{core, coefficients},
  core = logBarnesInverseCore[y];
  coefficients = logBarnesInverseCoefficients[1/(Log[core] - 1)];
  core + Sum[coefficients[[j + 1]]/core^j, {j, 0, count - 2}]];
logBarnesSquareOracle[y_] := Module[{core, a, b, c},
  core = logBarnesInverseCore[y];
  {a, b, c} = logBarnesInverseCoefficients[1/(Log[core] - 1)];
  core^2 + 2 a core + a^2 + 2 b];
logBarnesEqual[actual_, expected_] := TrueQ[Together[actual - expected] === 0];
logBarnesInverseEqual[s_, expected_] := MatchQ[s, _GeneralizedSeries] &&
  logBarnesEqual[Normal[s], expected];
logBarnesForwardEqual[s_, expected_, ass_] := MatchQ[s, _GeneralizedSeries] &&
  TrueQ[FullSimplify[Normal[s] == expected, ass]];
logBarnesCarrierPlus[x_] := (x^2/2 - 1/12) Log[x] - 3 x^2/4 +
  x Log[2 Pi]/2 + 1/12 - Log[Glaisher];
logBarnesCarrier[x_] := logBarnesCarrierPlus[x] -
  ((x - 1/2) Log[x] - x + Log[2 Pi]/2);

VerificationTest[Module[{x, z, s, source, core, q, coefficients},
  s = AsymptoticExpansion[InverseFunction[
    x |-> ConditionalExpression[LogBarnesG[x], x > 3]][z],
    z -> Infinity, SeriesTermGoal -> 3];
  If[! MatchQ[s, _GeneralizedSeries], Return[s, Module]];
  source = s["SourceVariable"]; core = logBarnesInverseCore[z]; q = s["CoefficientVariable"];
  coefficients = logBarnesInverseCoefficients[q];
  {logBarnesInverseEqual[s, logBarnesInverseOracle[z, 3]],
    logBarnesEqual[s["CoreInverse"], core], s["Kind"], s["BarnesFamily"],
    s["Terms"][[All, 1]],
    And @@ MapThread[logBarnesEqual, {s["Terms"][[All, 2]], Prepend[Take[coefficients, 2], 1]}],
    s["ReturnedTermCount"], s["RemainderPower"], s["RemainderInverseLogPower"],
    logBarnesEqual[s["FrontierTerm"],
      (coefficients[[3]] /. q -> 1/(Log[core] - 1))/core^2],
    s["ExactTransformedFunction"] === LogBarnesG[source],
    s["InverseFunctionBranch"]["ConditionalDomainVerified"],
    TrueQ[(s["TargetDomain"] /. z -> -1) === False], TrueQ[s["TargetDomain"] /. z -> 1]}],
  {True, True, "BarnesGInverse", "LogBarnesG", {-1, 0, 1}, True, 3, 2, 3,
    True, True, True, True, True},
  TestID -> "log-barnes-g-native-user-inverse-uses-unlogged-target-and-independent-three-blocks"]

VerificationTest[Module[{x, t, z, direct, named, unapplied},
  direct = AsymptoticInverse[LogBarnesG[x], {x, Infinity}, z, SeriesTermGoal -> 2];
  named = AsymptoticExpansion[InverseFunction[
    Function[t, ConditionalExpression[LogBarnesG[t], t > 3]]][z],
    z -> Infinity, SeriesTermGoal -> 2];
  unapplied = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[LogBarnesG[#], # > 3] &],
    {z, Infinity}, SeriesTermGoal -> 2];
  {logBarnesInverseEqual[direct, logBarnesInverseOracle[z, 2]],
    logBarnesInverseEqual[named, logBarnesInverseOracle[z, 2]],
    logBarnesInverseEqual[unapplied, logBarnesInverseOracle[z, 2]],
    FreeQ[Normal[named], t], direct["ExactTransformedFunction"] === LogBarnesG[x]}],
  {True, True, True, True, True},
  TestID -> "log-barnes-g-direct-named-and-unapplied-callables-agree"]

VerificationTest[Module[{x, z, s},
  s = AsymptoticInverse[7 - 2 LogBarnesG[3 - 2 x], {x, -Infinity}, z, SeriesTermGoal -> 3];
  {logBarnesInverseEqual[s, (3 - logBarnesInverseOracle[(7 - z)/2, 3])/2],
    s["ExactTransformedFunction"] === LogBarnesG[3 - 2 x],
    s["Direction"], s["RemainderPower"],
    TrueQ[(s["SourceDomain"] /. x -> 0) === False], TrueQ[s["SourceDomain"] /. x -> -1],
    TrueQ[(s["TargetDomain"] /. z -> 7) === False], TrueQ[s["TargetDomain"] /. z -> 6]}],
  {True, True, "FromAbove", 2, True, True, True, True},
  TestID -> "log-barnes-g-native-inverse-transports-signed-affine-source-and-target"]

VerificationTest[Module[{x, z, applied, direct},
  applied = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[LogBarnesG[#], # > 3] &][z]^2,
    z -> Infinity, SeriesTermGoal -> 3];
  direct = AsymptoticInverse[LogBarnesG[x], {x, Infinity}, z,
    "Power" -> 2, SeriesTermGoal -> 3];
  {logBarnesInverseEqual[applied, logBarnesSquareOracle[z]],
    logBarnesInverseEqual[direct, logBarnesSquareOracle[z]],
    applied["ReturnedTermCount"], applied["RemainderPower"], direct["RemainderPower"]}],
  {True, True, 3, 1, 1},
  TestID -> "log-barnes-g-powered-applied-inverse-and-constructor-observable-agree"]

VerificationTest[Module[{z, s, refined, source},
  s = AsymptoticExpansion[ConditionalExpression[InverseFunction[
    ConditionalExpression[LogBarnesG[#], # > 100] &][z], z > 1000],
    z -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 3]; source = refined["SourceVariable"];
  {logBarnesInverseEqual[refined, logBarnesInverseOracle[z, 4]], refined["RemainderPower"],
    ! FreeQ[refined["Function"], _LogBarnesG],
    TrueQ[(refined["SourceDomain"] /. source -> 100) === False],
    TrueQ[refined["SourceDomain"] /. source -> 101],
    TrueQ[(refined["TargetDomain"] /. z -> 1000) === False],
    TrueQ[refined["TargetDomain"] /. z -> 1001]}],
  {True, 3, True, True, True, True, True},
  TestID -> "log-barnes-g-refinement-preserves-native-source-and-both-conditional-domains"]

VerificationTest[Module[{x, z, s, shortened, raised},
  s = AsymptoticInverse[LogBarnesG[x], {x, Infinity}, z, SeriesTermGoal -> 3];
  shortened = SeriesTruncate[s, 1]; raised = SeriesTruncate[shortened, 10];
  {logBarnesInverseEqual[shortened, logBarnesInverseOracle[z, 2]],
    shortened["RemainderPower"], shortened["RemainderInverseLogPower"],
    logBarnesInverseEqual[raised, Normal[shortened]], raised["RemainderPower"],
    shortened["ExactTransformedFunction"] === LogBarnesG[x]}],
  {True, 1, 0, True, 1, True},
  TestID -> "log-barnes-g-truncation-keeps-native-exact-phase-and-existing-precision"]

VerificationTest[Module[{x, z, s, target, check, largeCheck, phase, residual},
  s = AsymptoticInverse[LogBarnesG[x], {x, Infinity}, z, SeriesTermGoal -> 3];
  target = LogBarnesG[100]; check = InverseNumericalCheck[s, target, WorkingPrecision -> 60];
  phase = N[LogBarnesG[check["ApproximationSourceRoot"]] - target, 60];
  largeCheck = InverseNumericalCheck[s, LogBarnesG[1000], WorkingPrecision -> 60];
  residual = InverseResidual[s];
  {AssociationQ[check], check["Certified"], TrueQ[Abs[check["ReferenceRoot"] - 100] < 10^-45],
    TrueQ[Abs[check["PhaseResidual"] - phase] < 10^-45],
    TrueQ[Abs[check["PhaseResidual"]] < Abs[check["SeedPhaseResidual"]]],
    AssociationQ[largeCheck], TrueQ[Abs[largeCheck["ReferenceRoot"] - 1000] < 10^-45],
    residual["ZeroBelowCutoff"], residual["ResidualBlocks"], residual["ExactModel"]}],
  {True, False, True, True, True, True, True, True, {}, False},
  TestID -> "log-barnes-g-exact-native-numerical-target-and-finite-model-residual"]

VerificationTest[Module[{x, s, expected},
  s = AsymptoticExpansion[LogBarnesG[x], x -> Infinity, SeriesTermGoal -> 5];
  expected = logBarnesCarrier[x] - 1/(12 x) - 1/(240 x^2);
  {logBarnesForwardEqual[s, expected, x > 0], s["Terms"][[All, 1]], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == 1/(360 x^3), x > 0]],
    ! FreeQ[s["Function"], _LogBarnesG]}],
  {True, {-2, -1, 0, 1, 2}, 3, True, True},
  TestID -> "log-barnes-g-native-forward-five-blocks-have-independent-Barnes-coefficients"]

VerificationTest[Module[{x, s, expected},
  s = AsymptoticExpansion[LogBarnesG[x + 1], x -> Infinity, SeriesTermGoal -> 5];
  expected = logBarnesCarrierPlus[x] - 1/(240 x^2) + 1/(1008 x^4);
  {logBarnesForwardEqual[s, expected, x > 0], s["Terms"][[All, 1]], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == -1/(1440 x^6), x > 0]]}],
  {True, {-2, -1, 0, 2, 4}, 6, True},
  TestID -> "log-barnes-g-native-unit-shift-retains-sparse-even-corrections"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[LogBarnesG[1 + x], {x, 0, 3}];
  {logBarnesForwardEqual[s, (Log[2 Pi] - 1) x/2 - (1 + EulerGamma) x^2/2, x > 0],
    s["RemainderPower"], TrueQ[FullSimplify[s["FrontierTerm"] == Pi^2 x^3/18, x > 0]]}],
  {True, 3, True},
  TestID -> "log-barnes-g-native-finite-positive-Taylor-series-matches-defining-product"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[LogBarnesG[x + 1] - LogBarnesG[x] - LogGamma[x],
    x -> Infinity, SeriesTermGoal -> 5];
  {logBarnesForwardEqual[s, 0, x > 0], s["Remainder"], s["Exact"]}],
  {True, 0, True},
  TestID -> "log-barnes-g-native-shift-recurrence-cancels-exactly-before-finite-tails"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[LogBarnesG[x] - Log[BarnesG[x]],
    x -> Infinity, SeriesTermGoal -> 5];
  {logBarnesForwardEqual[s, 0, x > 0], s["Remainder"], s["Exact"]}],
  {True, 0, True},
  TestID -> "log-barnes-g-native-and-real-wrapped-logarithms-cancel-exactly"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[LogBarnesG[x]], x -> Infinity, SeriesTermGoal -> 3];
  {TrueQ[FullSimplify[Log[s["Prefactor"]] == logBarnesCarrier[x], x > 0]],
    s["Terms"], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"]/s["Prefactor"] == 157/(51840 x^3), x > 0]]}],
  {True, {{0, 1}, {1, -1/12}, {2, -1/1440}}, 3, True},
  TestID -> "log-barnes-g-native-logarithm-inside-exponential-recovers-Barnes-relative-corrections"]

VerificationTest[Module[{x, z},
  Quiet[{FailureQ[AsymptoticExpansion[LogBarnesG[-x], x -> Infinity, SeriesTermGoal -> 3]],
    FailureQ[AsymptoticExpansion[ConditionalExpression[LogBarnesG[x], x < 0],
      x -> Infinity, SeriesTermGoal -> 3]],
    FailureQ[AsymptoticInverse[LogBarnesG[x], {x, Infinity}, z, SeriesTermGoal -> 0]],
    FailureQ[AsymptoticInverse[LogBarnesG[x], {x, Infinity}, {z, 3.5}]],
    FailureQ[AsymptoticInverse[LogBarnesG[x], {x, Infinity}, z, "Power" -> I, SeriesTermGoal -> 3]]}]],
  {True, True, True, True, True},
  TestID -> "log-barnes-g-validates-positive-tail-conditions-and-exact-inverse-options"]

VerificationTest[Module[{x, y, parameter, constant, ass, gamma, logarithm, gammaCore, logCore},
  constant = LogBarnesG[parameter]; ass = Element[constant, Reals];
  gamma = AsymptoticInverse[Gamma[x + constant], {x, Infinity}, y,
    Assumptions -> ass, SeriesTermGoal -> 2];
  logarithm = AsymptoticInverse[LogGamma[x + constant], {x, Infinity}, y,
    Assumptions -> ass, SeriesTermGoal -> 2];
  gammaCore = Log[y]/ProductLog[Log[y]/E]; logCore = y/ProductLog[y/E];
  {gamma["Kind"], gamma["GammaFamily"], logarithm["Kind"], logarithm["GammaFamily"],
    gamma["ExactTransformedFunction"] === LogGamma[x + constant],
    logarithm["ExactTransformedFunction"] === LogGamma[x + constant],
    logBarnesInverseEqual[gamma, gammaCore + 1/2 - Log[2 Pi]/(2 Log[gammaCore]) - constant],
    logBarnesInverseEqual[logarithm, logCore + 1/2 - Log[2 Pi]/(2 Log[logCore]) - constant]}],
  {"GammaInverse", "Gamma", "GammaInverse", "LogGamma", True, True, True, True},
  TestID -> "log-barnes-g-native-valued-affine-constant-does-not-reclassify-Gamma-inverse"]

VerificationTest[Module[{x, z, ordinary, wrapped},
  ordinary = AsymptoticInverse[BarnesG[2 x + 3], {x, Infinity}, z, SeriesTermGoal -> 2];
  wrapped = AsymptoticInverse[Log[BarnesG[x]], {x, Infinity}, z, SeriesTermGoal -> 2];
  {logBarnesInverseEqual[ordinary, (logBarnesInverseOracle[Log[z], 2] - 3)/2],
    ordinary["ExactTransformedFunction"] === LogBarnesG[2 x + 3],
    logBarnesInverseEqual[wrapped, logBarnesInverseOracle[z, 2]],
    wrapped["ExactTransformedFunction"] === LogBarnesG[x]}],
  {True, True, True, True},
  TestID -> "log-barnes-g-existing-Barnes-and-wrapped-inverses-retain-native-exact-logarithmic-phase"]

VerificationTest[Module[{x, shifted, constant},
  shifted = AsymptoticExpansion[LogBarnesG[7/5] + x, {x, 0, 2}];
  constant = AsymptoticExpansion[LogBarnesG[7/5], {x, 0, 2}];
  {logBarnesForwardEqual[shifted, LogBarnesG[7/5] + x, x > 0], shifted["Remainder"],
    logBarnesForwardEqual[constant, LogBarnesG[7/5], x > 0], constant["Remainder"],
    FreeQ[{Normal[shifted], Normal[constant]}, _AsymptoticInverse`Private`barnesLog]}],
  {True, 0, True, 0, True},
  TestID -> "log-barnes-g-forward-native-constant-remains-exact-without-private-logarithm-leak"]
