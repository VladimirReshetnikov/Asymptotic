(* Independent binomial and residual oracles for the ordered inverse-Gamma
   scale.  Write the source inverse as X+a+b/X+c/X^2+d/X^3+e/X^4.
   The coefficients below come from Taylor substitution into Stirling's
   logarithm; powers use the finite binomial formula. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

gammaInverseOpsCoefficients[l_] := Module[{a, b, c, d, e},
  a = 1/2 - Log[2 Pi]/(2 l);
  b = Together[(a/2 - a^2/2 - 1/12)/l];
  c = Together[((1/2 - a) b + a/12 - a^2/4 + a^3/6)/l];
  d = Together[((1/2 - a) c - b^2/2 +
    (a^2/2 - a/2 + 1/12) b - a^4/12 + a^3/6 - a^2/12 + 1/360)/l];
  e = Together[((1/2 - a) d + (a^2/2 - a/2 + 1/12 - b) c +
    (a/2 - 1/4) b^2 + (-a^3/3 + a^2/2 - a/6) b +
    a^5/20 - a^4/8 + a^3/12 - a/120)/l];
  {a, b, c, d, e}];

gammaInverseOpsCore[z_] := z/ProductLog[z/E];
gammaInverseOpsPowerOracle[z_, r_, count_Integer] := Module[{core, a, b, c, d, e, coefficients},
  core = gammaInverseOpsCore[z];
  {a, b, c, d, e} = gammaInverseOpsCoefficients[Log[core]];
  coefficients = {1, r a, r b + r (r - 1) a^2/2,
    r c + r (r - 1) a b + r (r - 1) (r - 2) a^3/6,
    r d + r (r - 1) (2 a c + b^2)/2 +
      r (r - 1) (r - 2) a^2 b/2 + r (r - 1) (r - 2) (r - 3) a^4/24};
  Sum[core^(r - j) coefficients[[j + 1]], {j, 0, count - 1}]];
gammaInverseOpsEqual[a_, b_] := TrueQ[Together[a - b] === 0];
gammaInverseOpsExpansionEqual[s_, expected_] :=
  MatchQ[s, _GeneralizedSeries] && gammaInverseOpsEqual[Normal[s], expected];

VerificationTest[Module[{x, y, s, below, beyond, q, omitted},
  s = AsymptoticInverse[Gamma[x], {x, Infinity}, y, SeriesTermGoal -> 5];
  below = InverseResidual[s]; beyond = InverseResidual[s, 6];
  q = beyond["CoefficientVariable"];
  omitted = Last[gammaInverseOpsCoefficients[1/q]];
  (* The omitted source correction is e/X^4.  Dividing its leading phase
     error by X Log[X] gives -e/X^5 in the retained approximation's residual. *)
  {below["ZeroBelowCutoff"], below["Cutoff"], below["ExactModel"],
    beyond["ZeroBelowCutoff"], Length[beyond["ResidualBlocks"]],
    beyond["ResidualBlocks"][[1, 1]],
    gammaInverseOpsEqual[beyond["ResidualBlocks"][[1, 2]], -omitted],
    beyond["ModelRemainderPower"]}],
  {True, 5, False, False, 1, 5, True, 6},
  TestID -> "gamma-inverse-operations-residual-exposes-independent-first-omitted-coefficient"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticInverse[Gamma[x], {x, Infinity}, y,
    SeriesTermGoal -> 3, "Power" -> 2];
  Quiet[MatchQ[InverseResidual[s], Failure["UnsupportedObservable", _Association]]]],
  True, TestID -> "gamma-inverse-operations-residual-does-not-invert-powered-approximation"]

VerificationTest[Module[{x, y, s, check, actualPhase},
  s = AsymptoticInverse[Gamma[x], {x, Infinity}, y, SeriesTermGoal -> 5];
  check = InverseNumericalCheck[s, Exp[10000], WorkingPrecision -> 100];
  actualPhase = N[LogGamma[check["ApproximationSourceRoot"]] - 10000, 90];
  {AssociationQ[check], check["Certified"],
    TrueQ[Abs[LogGamma[check["ReferenceRoot"]] - 10000] < 10^-85],
    TrueQ[Abs[check["ApproximationSourceRoot"] - check["Approximation"]] < 10^-90],
    TrueQ[Abs[check["PhaseResidual"] - actualPhase] < 10^-80],
    TrueQ[Abs[check["PhaseResidual"]] < Abs[check["SeedPhaseResidual"]]],
    TrueQ[Abs[check["RootSeed"] - check["ApproximationSourceRoot"]] > 1/10]}],
  {True, False, True, True, True, True, True},
  TestID -> "gamma-inverse-operations-huge-exact-target-distinguishes-seed-and-approximation"]

VerificationTest[Module[{x, y, s, check},
  s = AsymptoticInverse[Gamma[x], {x, Infinity}, y,
    SeriesTermGoal -> 3, "Power" -> 2];
  check = InverseNumericalCheck[s, Gamma[100], WorkingPrecision -> 60];
  {gammaInverseOpsExpansionEqual[s, gammaInverseOpsPowerOracle[Log[y], 2, 3]],
    s["RemainderPower"],
    TrueQ[Abs[check["ReferenceRoot"] - 100] < 10^-50],
    TrueQ[Abs[check["ReferenceObservable"] - 10000] < 10^-45],
    KeyExistsQ[check, "RootSeed"], KeyExistsQ[check, "SeedPhaseResidual"],
    KeyExistsQ[check, "ApproximationSourceRoot"], KeyExistsQ[check, "PhaseResidual"]}],
  {True, 1, True, True, True, True, False, False},
  TestID -> "gamma-inverse-operations-square-observable-and-source-root-have-distinct-meaning"]

VerificationTest[Module[{x, y, reciprocal, irrational},
  reciprocal = AsymptoticInverse[Gamma[x], {x, Infinity}, y,
    SeriesTermGoal -> 3, "Power" -> -1];
  irrational = AsymptoticInverse[Gamma[x], {x, Infinity}, y,
    SeriesTermGoal -> 3, "Power" -> Sqrt[2]];
  {gammaInverseOpsExpansionEqual[reciprocal, gammaInverseOpsPowerOracle[Log[y], -1, 3]],
    reciprocal["RemainderPower"],
    gammaInverseOpsExpansionEqual[irrational, gammaInverseOpsPowerOracle[Log[y], Sqrt[2], 3]],
    gammaInverseOpsEqual[irrational["RemainderPower"], 3 - Sqrt[2]]}],
  {True, 4, True, True},
  TestID -> "gamma-inverse-operations-reciprocal-and-irrational-observables-use-binomial-coefficients"]

VerificationTest[Module[{x, y, s, shortened, raised, core, coefficients},
  s = AsymptoticInverse[Gamma[x], {x, Infinity}, y, SeriesTermGoal -> 5];
  shortened = SeriesTruncate[s, 3/2]; raised = SeriesTruncate[shortened, 10];
  core = gammaInverseOpsCore[Log[y]];
  coefficients = gammaInverseOpsCoefficients[Log[core]];
  {gammaInverseOpsExpansionEqual[shortened, gammaInverseOpsPowerOracle[Log[y], 1, 3]],
    shortened["RemainderPower"],
    gammaInverseOpsEqual[shortened["FrontierTerm"], coefficients[[3]]/core^2],
    gammaInverseOpsExpansionEqual[raised, Normal[shortened]], raised["RemainderPower"],
    Quiet[MatchQ[SeriesTruncate[s, 1, "MaxTerms" -> 0], Failure["InvalidOption", _Association]]]}],
  {True, 2, True, True, 2, True},
  TestID -> "gamma-inverse-operations-truncation-retains-frontier-and-validates-budget"]

VerificationTest[Module[{x, y, s, squared, requested, refined},
  s = AsymptoticInverse[Gamma[x], {x, Infinity}, y, SeriesTermGoal -> 3];
  squared = SeriesPower[s, 2]; requested = SeriesPower[s, 2, 4];
  refined = SeriesRefine[squared, 3];
  {gammaInverseOpsExpansionEqual[squared, gammaInverseOpsPowerOracle[Log[y], 2, 3]],
    squared["RemainderPower"],
    gammaInverseOpsExpansionEqual[requested, Normal[squared]], requested["RemainderPower"],
    gammaInverseOpsExpansionEqual[refined, gammaInverseOpsPowerOracle[Log[y], 2, 5]],
    refined["RemainderPower"]}],
  {True, 1, True, 1, True, 3},
  TestID -> "gamma-inverse-operations-power-transports-input-ceiling-and-refinement-improves-it"]

VerificationTest[Module[{x, y, s, reciprocal},
  s = AsymptoticInverse[Gamma[x], {x, Infinity}, y, SeriesTermGoal -> 3];
  reciprocal = SeriesPower[s, -1];
  {gammaInverseOpsExpansionEqual[reciprocal, gammaInverseOpsPowerOracle[Log[y], -1, 3]],
    reciprocal["RemainderPower"]}],
  {True, 4}, TestID -> "gamma-inverse-operations-SeriesPower-reciprocal-shifts-absolute-precision"]

VerificationTest[Module[{x, y, square},
  square = AsymptoticInverse[Gamma[-x], {x, -Infinity}, y,
    SeriesTermGoal -> 3, "Power" -> 2];
  {MatchQ[square, _GeneralizedSeries],
    Quiet[FailureQ[SeriesPower[square, 1/2]]],
    Quiet[FailureQ[AsymptoticInverse[Gamma[-x], {x, -Infinity}, y,
      SeriesTermGoal -> 3, "Power" -> 1/2]]]}],
  {True, True, True},
  TestID -> "gamma-inverse-operations-negative-source-square-root-cannot-replay-wrong-sign"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[1/Gamma[#], # > 2] &][y],
    y -> 0, SeriesTermGoal -> 3];
  {gammaInverseOpsExpansionEqual[s, gammaInverseOpsPowerOracle[-Log[y], 1, 3]],
    s["RemainderPower"], TrueQ[s["TargetDomain"] /. y -> 1/100],
    TrueQ[(s["TargetDomain"] /. y -> -1/100) === False]}],
  {True, 2, True, True},
  TestID -> "gamma-inverse-operations-reciprocal-Gamma-inverse-at-zero-keeps-upper-source-branch"]

VerificationTest[Module[{x, y, s, check},
  s = AsymptoticInverse[7 - 2 LogGamma[3 - 2 x], {x, -Infinity}, y,
    SeriesTermGoal -> 3];
  check = InverseNumericalCheck[s, 7 - 2 LogGamma[100], WorkingPrecision -> 60];
  {gammaInverseOpsExpansionEqual[s,
      (3 - gammaInverseOpsPowerOracle[(7 - y)/2, 1, 3])/2],
    s["Direction"], TrueQ[Abs[check["ReferenceRoot"] + 97/2] < 10^-50],
    TrueQ[s["TargetDomain"] /. y -> -100]}],
  {True, "FromAbove", True, True},
  TestID -> "gamma-inverse-operations-LogGamma-affine-negative-source-and-signed-target"]

VerificationTest[Module[{z, s},
  s = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[Gamma[#], # > 2] &][z]^2,
    z -> Infinity, SeriesTermGoal -> 5];
  {gammaInverseOpsExpansionEqual[s, gammaInverseOpsPowerOracle[Log[z], 2, 5]],
    s["ReturnedTermCount"], s["RemainderPower"]}],
  {True, 5, 3},
  TestID -> "gamma-inverse-operations-powered-applied-callable-counts-final-observable-blocks"]

VerificationTest[Module[{z, s, refined, source},
  s = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[Gamma[#], # > 100] &][z]^2,
    z -> Infinity, SeriesTermGoal -> 3];
  refined = SeriesRefine[s, 3]; source = refined["SourceVariable"];
  {gammaInverseOpsExpansionEqual[refined, gammaInverseOpsPowerOracle[Log[z], 2, 5]],
    refined["RemainderPower"],
    TrueQ[(refined["SourceDomain"] /. source -> 100) === False],
    TrueQ[refined["SourceDomain"] /. source -> 101]}],
  {True, 3, True, True},
  TestID -> "gamma-inverse-operations-powered-callable-refinement-retains-observable-and-condition"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticInverse[Gamma[x], {x, Infinity}, y, SeriesTermGoal -> 2];
  Quiet[MatchQ[InverseNumericalCheck[s, N[Exp[10000], 30], WorkingPrecision -> 100],
    Failure["InsufficientPrecision", _Association]]]],
  True, TestID -> "gamma-inverse-operations-numerical-check-rejects-insufficient-target-precision"]

VerificationTest[Module[{z, s, powered, refined},
  s = AsymptoticExpansion[ConditionalExpression[InverseFunction[
    ConditionalExpression[Gamma[#], # > 2] &][z], z > 1000],
    z -> Infinity, SeriesTermGoal -> 3];
  powered = SeriesPower[s, 2]; refined = SeriesRefine[powered, 3];
  {gammaInverseOpsExpansionEqual[refined, gammaInverseOpsPowerOracle[Log[z], 2, 5]],
    TrueQ[(powered["TargetDomain"] /. z -> 1000) === False],
    TrueQ[(refined["TargetDomain"] /. z -> 1000) === False],
    TrueQ[refined["TargetDomain"] /. z -> 1001]}],
  {True, True, True, True},
  TestID -> "gamma-inverse-operations-powered-refinement-preserves-outer-target-condition"]

VerificationTest[Module[{z, s, zeroPower, refined},
  s = AsymptoticExpansion[ConditionalExpression[InverseFunction[
    ConditionalExpression[Gamma[#], # > 2] &][z], z > 1000],
    z -> Infinity, SeriesTermGoal -> 3];
  zeroPower = SeriesPower[s, 0]; refined = SeriesRefine[zeroPower, 3];
  {gammaInverseOpsExpansionEqual[zeroPower, 1], zeroPower["Remainder"],
    gammaInverseOpsExpansionEqual[refined, 1], refined["Remainder"],
    TrueQ[(zeroPower["TargetDomain"] /. z -> 1000) === False],
    TrueQ[(refined["TargetDomain"] /. z -> 1000) === False],
    TrueQ[refined["TargetDomain"] /. z -> 1001]}],
  {True, 0, True, 0, True, True, True},
  TestID -> "gamma-inverse-operations-zero-power-exact-refinement-preserves-target-condition"]
