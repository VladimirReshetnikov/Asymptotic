(* Independent inverse-Stirling coefficient oracle.  Put z=Log[y] for
   Gamma, z=y for LogGamma, X=z/ProductLog[z/E], and L=Log[X].
   Substituting X+c0+c1/X+... into
     (x-1/2) Log[x]-x+Log[2 Pi]/2+1/(12 x)-1/(360 x^3)
   and comparing source powers gives the five coefficients below.  No
   package inverse, native inverse series, or numerical fit supplies them. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

gammaInverseOracleCoefficients[l_] := Module[{a, b, c, d, e},
  a = 1/2 - Log[2 Pi]/(2 l);
  b = Together[(a/2 - a^2/2 - 1/12)/l];
  c = Together[((1/2 - a) b + a/12 - a^2/4 + a^3/6)/l];
  d = Together[((1/2 - a) c - b^2/2 +
      (a^2/2 - a/2 + 1/12) b - a^4/12 + a^3/6 - a^2/12 + 1/360)/l];
  e = Together[((1/2 - a) d + (a^2/2 - a/2 + 1/12 - b) c +
      (a/2 - 1/4) b^2 + (-a^3/3 + a^2/2 - a/6) b +
      a^5/20 - a^4/8 + a^3/12 - a/120)/l];
  {a, b, c, d, e}];

gammaInverseOracleCore[z_] := z/ProductLog[z/E];
gammaInverseOracle[z_, count_Integer] := Module[{core, coefficients},
  core = gammaInverseOracleCore[z];
  coefficients = gammaInverseOracleCoefficients[Log[core]];
  core + Sum[coefficients[[k + 1]]/core^k, {k, 0, count - 2}]];

gammaInverseEqual[actual_, expected_] := TrueQ[Together[actual - expected] === 0];
gammaInverseExpansionEqual[s_, expected_] :=
  MatchQ[s, _GeneralizedSeries] && gammaInverseEqual[Normal[s], expected];

gammaInverseTermsEqual[s_, count_Integer] := Module[{q, expected, actual},
  If[! MatchQ[s, _GeneralizedSeries], Return[False, Module]];
  q = s["CoefficientVariable"];
  expected = Prepend[MapIndexed[{First[#2] - 1, #1} &,
    Take[gammaInverseOracleCoefficients[1/q], count - 1]], {-1, 1}];
  actual = s["Terms"];
  ListQ[actual] && Length[actual] === count &&
    And @@ MapThread[(#1[[1]] === #2[[1]] && gammaInverseEqual[#1[[2]], #2[[2]]]) &,
      {actual, expected}]];

VerificationTest[Module[{x, s, source, core, coefficients},
  s = AsymptoticExpansion[InverseFunction[
    x |-> ConditionalExpression[Gamma[x], x > 2]],
    x -> Infinity, SeriesTermGoal -> 5];
  If[! MatchQ[s, _GeneralizedSeries], Return[s, Module]];
  source = s["SourceVariable"]; core = gammaInverseOracleCore[Log[x]];
  coefficients = gammaInverseOracleCoefficients[Log[core]];
  {gammaInverseExpansionEqual[s, gammaInverseOracle[Log[x], 5]],
    gammaInverseTermsEqual[s, 5], gammaInverseEqual[s["CoreInverse"], core],
    s["Scale"], s["Kind"], s["ReturnedTermCount"], s["RemainderPower"],
    s["RemainderInverseLogPower"],
    gammaInverseEqual[s["FrontierTerm"], coefficients[[5]]/core^4],
    s["InverseFunctionBranch"]["SourcePoint"],
    s["InverseFunctionBranch"]["ConditionalDomainVerified"],
    TrueQ[(s["SourceDomain"] /. source -> 2) === False],
    TrueQ[s["SourceDomain"] /. source -> 3]}],
  {True, True, True, "GammaInverse", "GammaInverse", 5, 4, 2,
    True, Infinity, True, True, True},
  TestID -> "gamma-inverse-user-callable-five-independent-blocks-and-frontier"]

VerificationTest[Module[{t, y, named, applied},
  named = AsymptoticExpansion[InverseFunction[
    Function[{t}, ConditionalExpression[Gamma[t], t > 2]]],
    {y, Infinity}, SeriesTermGoal -> 2];
  applied = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[Gamma[#], # > 2] &][y], {y, Infinity, 3/2}];
  {gammaInverseExpansionEqual[named, gammaInverseOracle[Log[y], 2]],
    FreeQ[Normal[named], t],
    gammaInverseExpansionEqual[applied, gammaInverseOracle[Log[y], 3]],
    applied["RemainderPower"], applied["ReturnedTermCount"]}],
  {True, True, True, 2, 3},
  TestID -> "gamma-inverse-callable-bindings-and-exclusive-fractional-cutoff"]

VerificationTest[Module[{x, y, gamma, logarithm},
  gamma = AsymptoticInverse[Gamma[x], {x, Infinity}, y, SeriesTermGoal -> 3];
  logarithm = AsymptoticInverse[LogGamma[x], {x, Infinity}, y, SeriesTermGoal -> 5];
  {gammaInverseExpansionEqual[gamma, gammaInverseOracle[Log[y], 3]],
    gammaInverseExpansionEqual[logarithm, gammaInverseOracle[y, 5]],
    gammaInverseTermsEqual[logarithm, 5],
    gamma["RemainderPower"], logarithm["RemainderPower"]}],
  {True, True, True, 2, 4},
  TestID -> "gamma-inverse-direct-Gamma-and-LogGamma-use-original-target-coordinate"]

VerificationTest[Module[{x, y, s, core, firstCorrection},
  s = AsymptoticInverse[Gamma[x], {x, Infinity}, y, SeriesTermGoal -> 1];
  core = gammaInverseOracleCore[Log[y]];
  firstCorrection = 1/2 - Log[2 Pi]/(2 Log[core]);
  {gammaInverseExpansionEqual[s, core], s["ReturnedTermCount"],
    s["RemainderPower"], gammaInverseEqual[s["FrontierTerm"], firstCorrection],
    s["Remainder"] =!= 0}],
  {True, 1, 0, True, True},
  TestID -> "gamma-inverse-one-block-retains-nonzero-constant-correction-tail"]

VerificationTest[Module[{y, s, refined, source, refinedSource},
  s = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[Gamma[#], # > 100] &],
    y -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 4];
  source = s["SourceVariable"]; refinedSource = refined["SourceVariable"];
  {gammaInverseExpansionEqual[refined, gammaInverseOracle[Log[y], 5]],
    refined["RemainderPower"], refined["ReturnedTermCount"],
    TrueQ[(s["SourceDomain"] /. source -> 100) === False],
    TrueQ[(refined["SourceDomain"] /. refinedSource -> 100) === False],
    TrueQ[refined["SourceDomain"] /. refinedSource -> 101]}],
  {True, 4, 5, True, True, True},
  TestID -> "gamma-inverse-refinement-preserves-callable-and-strict-source-condition"]

VerificationTest[Module[{x, y, s, refined},
  s = AsymptoticInverse[Gamma[x], {x, Infinity}, {y, 1}];
  refined = SeriesRefine[s, 4];
  {gammaInverseExpansionEqual[refined, gammaInverseOracle[Log[y], 5]],
    gammaInverseTermsEqual[refined, 5], refined["RemainderPower"]}],
  {True, True, 4},
  TestID -> "gamma-inverse-direct-refinement-obtains-new-source-power-blocks"]

VerificationTest[Module[{y, low, high, check, lowError, highError},
  low = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[Gamma[#], # > 2] &],
    y -> Infinity, SeriesTermGoal -> 2];
  high = SeriesRefine[low, 4];
  check = InverseNumericalCheck[high, Gamma[100], WorkingPrecision -> 60];
  lowError = N[Abs[(Normal[low] /. y -> Gamma[100]) - 100], 60];
  highError = N[Abs[(Normal[high] /. y -> Gamma[100]) - 100], 60];
  {AssociationQ[check], TrueQ[Abs[check["ReferenceRoot"] - 100] < 10^-50],
    TrueQ[0 < highError < lowError],
    TrueQ[Abs[check["Error"] - highError] < 10^-45]}],
  {True, True, True, True},
  TestID -> "gamma-inverse-exact-Gamma-target-independent-root-and-refinement-improvement"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[Gamma[#], # > 100] &],
    y -> Infinity, SeriesTermGoal -> 3];
  Quiet[MatchQ[InverseNumericalCheck[s, Gamma[10], WorkingPrecision -> 50],
    Failure["OutsideBranch", _Association]]]],
  True, TestID -> "gamma-inverse-numerical-reference-respects-retained-source-condition"]

VerificationTest[Module[{y, s, refined},
  s = AsymptoticExpansion[ConditionalExpression[InverseFunction[
    ConditionalExpression[Gamma[#], # > 2] &][y], y > 1000],
    y -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 2];
  {gammaInverseExpansionEqual[refined, gammaInverseOracle[Log[y], 3]],
    TrueQ[(s["TargetDomain"] /. y -> 1000) === False],
    TrueQ[(refined["TargetDomain"] /. y -> 1000) === False],
    TrueQ[refined["TargetDomain"] /. y -> 1001]}],
  {True, True, True, True},
  TestID -> "gamma-inverse-outer-target-condition-survives-refinement"]

VerificationTest[Module[{y},
  Quiet[FailureQ[AsymptoticExpansion[InverseFunction[
    ConditionalExpression[Gamma[#], 2 < # < 3] &],
    y -> Infinity, SeriesTermGoal -> 3]]]],
  True, TestID -> "gamma-inverse-bounded-source-domain-has-no-infinite-target-germ"]

VerificationTest[Module[{y},
  Quiet[MatchQ[AsymptoticExpansion[InverseFunction[
    ConditionalExpression[Gamma[#], # > 0] &],
    y -> Infinity, SeriesTermGoal -> 3],
    Failure["AmbiguousInverseFunctionBranch", _Association]]]],
  True, TestID -> "gamma-inverse-positive-domain-keeps-zero-and-infinity-branches-distinct"]

VerificationTest[Module[{t, y, operator, selected, incompatible},
  operator = InverseFunction[Function[t, ConditionalExpression[Gamma[t], t > 0]]];
  selected = AsymptoticExpansion[operator[y], y -> Infinity, SeriesTermGoal -> 2,
    "InverseFunctionBranches" -> Association[
      operator -> <|"SourcePoint" -> Infinity, "Direction" -> "FromBelow"|>]];
  operator = InverseFunction[Function[t, ConditionalExpression[Gamma[t], t > 2]]];
  incompatible = Quiet[AsymptoticExpansion[operator[y], y -> Infinity,
    SeriesTermGoal -> 2, "InverseFunctionBranches" -> Association[
      operator -> <|"SourcePoint" -> 0, "Direction" -> "FromAbove"|>]]];
  {gammaInverseExpansionEqual[selected, gammaInverseOracle[Log[y], 2]],
    FailureQ[incompatible]}],
  {True, True},
  TestID -> "gamma-inverse-explicit-upper-branch-still-validates-source-domain"]

VerificationTest[Module[{t, y, s},
  s = AsymptoticExpansion[InverseFunction[
    Function[t, ConditionalExpression[LogGamma[t], t > 2]]],
    y -> Infinity, SeriesTermGoal -> 3];
  {gammaInverseExpansionEqual[s, gammaInverseOracle[y, 3]],
    gammaInverseTermsEqual[s, 3], s["RemainderPower"]}],
  {True, True, 2},
  TestID -> "gamma-inverse-callable-LogGamma-retains-unlogged-target"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticInverse[Gamma[2 x + 3], {x, Infinity}, y, SeriesTermGoal -> 3];
  gammaInverseExpansionEqual[s, (gammaInverseOracle[Log[y], 3] - 3)/2]],
  True, TestID -> "gamma-inverse-affine-source-argument-reconstructs-original-source"]

VerificationTest[Module[{x, y, s, z},
  s = AsymptoticInverse[7 - 2 Gamma[x]^2, {x, Infinity}, y, SeriesTermGoal -> 3];
  z = Log[(7 - y)/2]/2;
  {gammaInverseExpansionEqual[s, gammaInverseOracle[z, 3]],
    TrueQ[s["TargetDomain"] /. y -> -100],
    TrueQ[(s["TargetDomain"] /. y -> 7) === False]}],
  {True, True, True},
  TestID -> "gamma-inverse-powered-Gamma-signed-affine-target-keeps-logarithmic-equation"]

VerificationTest[Module[{x, y},
  Quiet[{FailureQ[AsymptoticInverse[Gamma[x], {x, Infinity}, y, SeriesTermGoal -> 0]],
    FailureQ[AsymptoticInverse[Gamma[x], {x, Infinity}, {y, 2.5}]],
    FailureQ[AsymptoticInverse[Gamma[x], {x, Infinity}, y,
      SeriesTermGoal -> 3, "MaxTerms" -> 0]],
    FailureQ[AsymptoticInverse[Gamma[x]^I, {x, Infinity}, y, SeriesTermGoal -> 3]]}]],
  {True, True, True, True},
  TestID -> "gamma-inverse-invalid-count-inexact-cutoff-budget-and-nonreal-power-rejected"]
