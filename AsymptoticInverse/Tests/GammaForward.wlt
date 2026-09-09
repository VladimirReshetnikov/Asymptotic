(* Stirling's multiplicative coefficients below are an independent oracle
   (DLMF 5.11.3-5.11.4), not obtained by calling the package or native Series.
   The exact prefactor is separated from the ordinary inverse-power bracket. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

gammaForwardCoefficients = {1, 1/12, 1/288, -139/51840,
  -571/2488320, 163879/209018880};
gammaForwardPrefactor[z_] := Sqrt[2 Pi] Exp[-z] z^(z - 1/2);
gammaForwardBracket[z_, count_Integer] :=
  Sum[gammaForwardCoefficients[[k + 1]] z^-k, {k, 0, count - 1}];
gammaForwardEqual[s_, expr_, ass_: True] :=
  MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[s] == expr, ass]];

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaForwardEqual[s, gammaForwardPrefactor[x] gammaForwardBracket[x, 5], x > 0],
    s["Terms"], s["Kind"], s["Scale"], s["ExpansionPoint"],
    s["RemainderVariable"] === 1/x, s["RemainderPower"], s["RemainderLogDegree"]}],
  {True, Transpose[{Range[0, 4], Take[gammaForwardCoefficients, 5]}],
    "Forward", "Factored", Infinity, True, 5, 0},
  TestID -> "gamma-forward-user-rule-five-independent-Stirling-coefficients"]

VerificationTest[Module[{x, s, pref},
  s = AsymptoticExpansion[Gamma[x], {x, Infinity}, SeriesTermGoal -> 5];
  pref = gammaForwardPrefactor[x];
  {TrueQ[FullSimplify[s["Prefactor"] == pref, x > 0]],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^5, x > 0]],
    TrueQ[FullSimplify[s["Remainder"] ==
      Abs[pref] PowerLogRemainder[1/x, 5, 0], x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == pref gammaForwardCoefficients[[6]]/x^5, x > 0]],
    s["Exact"], s["RemainderDerivativeOrder"]}],
  {True, True, True, True, False, 0},
  TestID -> "gamma-forward-remainder-includes-exact-growing-prefactor"]

VerificationTest[Module[{x, s, normalizedGamma, normalizedApproximation, ratio},
  s = AsymptoticExpansion[Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
  (* Evaluate in the logarithmic domain with ample precision: Gamma[1000]
     and its prefactor are both enormous, while their ratio is near one. *)
  normalizedGamma = Exp[N[LogGamma[1000] -
    ((1000 - 1/2) Log[1000] - 1000 + Log[2 Pi]/2), 100]];
  normalizedApproximation = N[FullSimplify[Normal[s]/s["Prefactor"], x > 0] /. x -> 1000, 100];
  ratio = (normalizedGamma - normalizedApproximation) 1000^5/
    gammaForwardCoefficients[[6]];
  TrueQ[0 < ratio && Abs[ratio - 1] < 1/100]],
  True, TestID -> "gamma-forward-native-numerical-value-agrees-at-first-omitted-scale"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[x], x -> Infinity, SeriesTermGoal -> 1];
  {gammaForwardEqual[s, gammaForwardPrefactor[x], x > 0],
    s["Terms"], s["RemainderPower"]}],
  {True, {{0, 1}}, 1}, TestID -> "gamma-forward-one-term-counts-normalized-leading-one"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[x], x -> Infinity, SeriesTermGoal -> 6];
  {gammaForwardEqual[s, gammaForwardPrefactor[x] gammaForwardBracket[x, 6], x > 0],
    s["Terms"], s["RemainderPower"]}],
  {True, Transpose[{Range[0, 5], gammaForwardCoefficients}], 6},
  TestID -> "gamma-forward-sixth-coefficient-is-independent-first-omitted-oracle"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[x], {x, Infinity, 7/2}];
  {gammaForwardEqual[s, gammaForwardPrefactor[x] gammaForwardBracket[x, 4], x > 0],
    s["Cutoff"], s["RemainderPower"], Length[s["Terms"]]}],
  {True, 7/2, 4, 4},
  TestID -> "gamma-forward-rational-relative-cutoff-retains-complete-blocks"]

VerificationTest[Module[{x, s, refined},
  s = AsymptoticExpansion[Gamma[x], x -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 6];
  {gammaForwardEqual[refined, gammaForwardPrefactor[x] gammaForwardBracket[x, 6], x > 0],
    refined["Kind"], refined["RemainderPower"], Length[refined["Terms"]]}],
  {True, "Forward", 6, 6},
  TestID -> "gamma-forward-refinement-replays-original-Gamma-function"]

VerificationTest[Module[{x, s, truncated},
  s = AsymptoticExpansion[Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
  truncated = SeriesTruncate[s, 3];
  {gammaForwardEqual[truncated, gammaForwardPrefactor[x] gammaForwardBracket[x, 3], x > 0],
    truncated["RemainderPower"],
    TrueQ[FullSimplify[truncated["RemainderScaleExpression"] == gammaForwardPrefactor[x]/x^3, x > 0]]}],
  {True, 3, True}, TestID -> "gamma-forward-truncation-transports-relative-error-prefactor"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[2 x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaForwardEqual[s, gammaForwardPrefactor[2 x] gammaForwardBracket[2 x, 5], x > 0],
    s["RemainderPower"], Length[s["Terms"]]}],
  {True, 5, 5}, TestID -> "gamma-forward-positive-scaled-argument"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[x^2], x -> Infinity, SeriesTermGoal -> 5];
  {gammaForwardEqual[s, gammaForwardPrefactor[x^2] gammaForwardBracket[x^2, 5], x > 0],
    s["Terms"][[All, 1]], s["RemainderPower"]}],
  {True, {0, 2, 4, 6, 8}, 10},
  TestID -> "gamma-forward-ramified-argument-counts-sparse-nonzero-blocks"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[1/x], x -> 0, SeriesTermGoal -> 5];
  {gammaForwardEqual[s, gammaForwardPrefactor[1/x] gammaForwardBracket[1/x, 5], x > 0],
    s["RemainderVariable"] === x, s["RemainderPower"], s["Direction"]}],
  {True, True, 5, "FromAbove"},
  TestID -> "gamma-forward-reciprocal-argument-at-positive-finite-endpoint"]

VerificationTest[Module[{x, a, s},
  s = AsymptoticExpansion[Gamma[a x], x -> Infinity,
    Assumptions -> a > 0, SeriesTermGoal -> 3];
  {gammaForwardEqual[s, gammaForwardPrefactor[a x] gammaForwardBracket[a x, 3], a > 0 && x > 0],
    s["Assumptions"] === (a > 0), s["RemainderPower"]}],
  {True, True, 3}, TestID -> "gamma-forward-parameter-positivity-justifies-argument-branch"]

VerificationTest[Module[{x, s, refined},
  s = AsymptoticExpansion[ConditionalExpression[Gamma[x], x > 2],
    x -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 5];
  {gammaForwardEqual[refined, gammaForwardPrefactor[x] gammaForwardBracket[x, 5], x > 2],
    TrueQ[(s["TargetDomain"] /. x -> 1) === False],
    TrueQ[(s["SeriesRepresentation"]["Domain"] /. x -> 1) === False],
    TrueQ[(refined["TargetDomain"] /. x -> 1) === False],
    TrueQ[refined["TargetDomain"] /. x -> 3], refined["RemainderPower"]}],
  {True, True, True, True, True, 5},
  TestID -> "gamma-forward-conditional-domain-survives-representation-and-refinement"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[x], {x, 1, 3}];
  {gammaForwardEqual[s, 1 - EulerGamma (x - 1) +
      (EulerGamma^2/2 + Pi^2/12) (x - 1)^2], s["RemainderPower"]}],
  {True, 3}, TestID -> "gamma-forward-regular-finite-Gamma-expansion-remains-supported"]

VerificationTest[Module[{x},
  {FailureQ[AsymptoticExpansion[Gamma[x], x -> Infinity, SeriesTermGoal -> 0]],
    FailureQ[AsymptoticExpansion[Gamma[x], x -> Infinity, SeriesTermGoal -> 5, "MaxTerms" -> 0]],
    FailureQ[AsymptoticExpansion[Gamma[x], x -> Infinity, SeriesTermGoal -> 5, "MaxTerms" -> 1]],
    FailureQ[AsymptoticExpansion[Gamma[x], {x, Infinity, 3.5}]]}],
  {True, True, True, True},
  TestID -> "gamma-forward-invalid-goals-budgets-and-inexact-cutoffs-fail"]

VerificationTest[Module[{x},
  {Quiet[FailureQ[AsymptoticExpansion[Gamma[-x], x -> Infinity, SeriesTermGoal -> 5]]],
    FailureQ[AsymptoticExpansion[ConditionalExpression[Gamma[x], x < 0],
      x -> Infinity, SeriesTermGoal -> 5]]}],
  {True, True}, TestID -> "gamma-forward-rejects-pole-filled-negative-tail-and-incompatible-domain"]

VerificationTest[Module[{x, s, logarithm},
  s = AsymptoticExpansion[Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
  logarithm = SeriesLog[s, 5];
  {gammaForwardEqual[logarithm,
      (x - 1/2) Log[x] - x + Log[2 Pi]/2 + 1/(12 x) - 1/(360 x^3), x > 0],
    logarithm["RemainderPower"]}],
  {True, 5}, TestID -> "gamma-forward-SeriesLog-recovers-additive-Stirling-expansion"]

VerificationTest[Module[{x, s, doubled, reciprocal},
  s = AsymptoticExpansion[Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
  doubled = SeriesMultiply[2, s];
  reciprocal = SeriesPower[s, -1, 3];
  {gammaForwardEqual[doubled, 2 gammaForwardPrefactor[x] gammaForwardBracket[x, 5], x > 0],
    gammaForwardEqual[reciprocal,
      (1 - 1/(12 x) + 1/(288 x^2))/gammaForwardPrefactor[x], x > 0],
    reciprocal["RemainderPower"],
    TrueQ[FullSimplify[reciprocal["RemainderScaleExpression"] ==
      1/(gammaForwardPrefactor[x] x^3), x > 0]]}],
  {True, True, 3, True},
  TestID -> "gamma-forward-scalar-product-and-reciprocal-preserve-prefactor-calculus"]
