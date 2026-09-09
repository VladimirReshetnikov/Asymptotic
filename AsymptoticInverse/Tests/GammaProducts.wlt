(* Independent coefficient oracles, using the Bernoulli form of Stirling's
   logarithm and n c_n = Sum[k a_k c_(n-k), {k, 1, n}], c_0 = 1.
   For Gamma[3 x]/Gamma[x], the logarithmic correction coefficients are
     a_1 = -1/18, a_3 = 13/4860, a_5 = -121/153090.
   For Gamma[x] Gamma[2 x], they are 1/8, -1/320, 11/13440.
   For Gamma[x + 1/2]/Gamma[x], they are -1/8, 1/192, -1/640.
   Expected values below use neither native Series nor package operations. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

gammaProductsRatioCoefficients = {1, -1/18, 1/648, 463/174960,
  -1867/12597120, -1247983/1587237120};
gammaProductsRatioPrefactor[z_] := 3^(3 z - 1/2) z^(2 z) Exp[-2 z];
gammaProductsStirlingPrefactor[z_] := Sqrt[2 Pi] Exp[-z] z^(z - 1/2);
gammaProductsBracket[z_, coefficients_List] :=
  Sum[coefficients[[k + 1]] z^-k, {k, 0, Length[coefficients] - 1}];
gammaProductsEqual[s_, expr_, ass_: True] :=
  MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[s] == expr, ass]];

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaProductsEqual[s, gammaProductsRatioPrefactor[x]
      gammaProductsBracket[x, Take[gammaProductsRatioCoefficients, 5]], x > 0],
    s["Terms"], s["Kind"], s["Scale"], s["ExpansionPoint"],
    s["RemainderVariable"] === 1/x, s["RemainderPower"], s["RemainderLogDegree"],
    s["RequestedTermGoal"], s["ReturnedTermCount"]}],
  {True, Transpose[{Range[0, 4], Take[gammaProductsRatioCoefficients, 5]}],
    "Forward", "Factored", Infinity, True, 5, 0, 5, 5},
  TestID -> "gamma-products-user-ratio-five-independent-coefficients"]

VerificationTest[Module[{x, s, pref},
  s = AsymptoticExpansion[Gamma[3 x]/Gamma[x], {x, Infinity}, SeriesTermGoal -> 5];
  pref = gammaProductsRatioPrefactor[x];
  {TrueQ[FullSimplify[s["Prefactor"] == pref, x > 0]],
    TrueQ[FullSimplify[s["Remainder"] == pref PowerLogRemainder[1/x, 5, 0], x > 0]],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^5, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] ==
      pref gammaProductsRatioCoefficients[[6]]/x^5, x > 0]],
    s["Function"] === Gamma[3 x]/Gamma[x],
    s["LogarithmicFunction"] === LogGamma[3 x] - LogGamma[x],
    s["Exact"], s["RemainderDerivativeOrder"]}],
  {True, True, True, True, True, True, False, 0},
  TestID -> "gamma-products-ratio-remainder-frontier-and-source"]

VerificationTest[Module[{x, s, normalizedRatio, normalizedApproximation, relativeError},
  s = AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
  (* Evaluate the independent Gamma oracle in the logarithmic domain at
     100 digits to avoid overflow and resolve the first omitted term. *)
  normalizedRatio = Exp[N[LogGamma[3000] - LogGamma[1000]
    - ((3000 - 1/2) Log[3] + 2000 Log[1000] - 2000), 100]];
  normalizedApproximation = N[FullSimplify[Normal[s]/s["Prefactor"], x > 0]
    /. x -> 1000, 100];
  relativeError = (normalizedRatio - normalizedApproximation) 1000^5/
    gammaProductsRatioCoefficients[[6]];
  TrueQ[0 < relativeError && Abs[relativeError - 1] < 1/100]],
  True,
  TestID -> "gamma-products-ratio-numerical-value-agrees-at-independent-omitted-scale"]

VerificationTest[Module[{x, s, coefficients, pref},
  coefficients = {1, 1/18, 1/648, -463/174960, -1867/12597120};
  pref = 1/gammaProductsRatioPrefactor[x];
  s = AsymptoticExpansion[Gamma[x]/Gamma[3 x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaProductsEqual[s, pref gammaProductsBracket[x, coefficients], x > 0],
    s["Terms"], s["RemainderPower"],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^5, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] ==
      -pref gammaProductsRatioCoefficients[[6]]/x^5, x > 0]]}],
  {True, Transpose[{Range[0, 4], {1, 1/18, 1/648, -463/174960, -1867/12597120}}],
    5, True, True},
  TestID -> "gamma-products-reciprocal-ratio-has-decaying-prefactor"]

VerificationTest[Module[{x, s, coefficients, pref},
  coefficients = {1, 1/8, 1/128, -43/15360, -187/491520};
  pref = gammaProductsStirlingPrefactor[x] gammaProductsStirlingPrefactor[2 x];
  s = AsymptoticExpansion[Gamma[x] Gamma[2 x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaProductsEqual[s, pref gammaProductsBracket[x, coefficients], x > 0],
    s["Terms"], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == pref 21863/(27525120 x^5), x > 0]]}],
  {True, Transpose[{Range[0, 4], {1, 1/8, 1/128, -43/15360, -187/491520}}], 5, True},
  TestID -> "gamma-products-positive-product-has-independent-coefficients"]

VerificationTest[Module[{x, s, coefficients},
  coefficients = {1, -1/9, 1/162, 56/10935, -463/787320};
  s = AsymptoticExpansion[(Gamma[3 x]/Gamma[x])^2, x -> Infinity, SeriesTermGoal -> 5];
  {gammaProductsEqual[s, gammaProductsRatioPrefactor[x]^2
      gammaProductsBracket[x, coefficients], x > 0],
    s["Terms"], s["RemainderPower"], s["ReturnedTermCount"]}],
  {True, Transpose[{Range[0, 4], {1, -1/9, 1/162, 56/10935, -463/787320}}], 5, 5},
  TestID -> "gamma-products-powered-ratio-combines-fixed-Gamma-powers"]

VerificationTest[Module[{x, s, pref},
  pref = gammaProductsRatioPrefactor[x];
  s = AsymptoticExpansion[-2 x Gamma[3 x]/Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaProductsEqual[s, -2 x pref
      gammaProductsBracket[x, Take[gammaProductsRatioCoefficients, 5]], x > 0],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == 2 x pref/x^5, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] ==
      -2 x pref gammaProductsRatioCoefficients[[6]]/x^5, x > 0]],
    s["ReturnedTermCount"]}],
  {True, True, True, 5},
  TestID -> "gamma-products-signed-ordinary-factor-transports-absolute-error"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[x + 1]/Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaProductsEqual[s, x, x > 0], s["Remainder"], s["Exact"],
    Length[s["Terms"]]}],
  {True, 0, True, 1},
  TestID -> "gamma-products-shift-recurrence-terminates-exactly"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[x + 1/2]/Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaProductsEqual[s, Sqrt[x] (1 - 1/(8 x) + 1/(128 x^2)
      + 5/(1024 x^3) - 21/(32768 x^4)), x > 0],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == x^(-9/2), x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == -399/(262144 x^(9/2)), x > 0]],
    s["ReturnedTermCount"], s["Exact"]}],
  {True, True, True, 5, False},
  TestID -> "gamma-products-balanced-shifted-ratio-cancels-growing-carrier"]

VerificationTest[Module[{x, s, refined, truncated, pref},
  pref = gammaProductsRatioPrefactor[x];
  s = AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 6]; truncated = SeriesTruncate[refined, 3];
  {gammaProductsEqual[refined, pref gammaProductsBracket[x, gammaProductsRatioCoefficients], x > 0],
    refined["Function"] === Gamma[3 x]/Gamma[x], refined["RemainderPower"],
    Length[refined["Terms"]],
    gammaProductsEqual[truncated, pref (1 - 1/(18 x) + 1/(648 x^2)), x > 0],
    truncated["RemainderPower"],
    TrueQ[FullSimplify[truncated["RemainderScaleExpression"] == pref/x^3, x > 0]]}],
  {True, True, 6, 6, True, 3, True},
  TestID -> "gamma-products-refinement-replays-product-and-truncation-transports-error"]

VerificationTest[Module[{x, s, refined},
  s = AsymptoticExpansion[ConditionalExpression[Gamma[3 x]/Gamma[x], x > 2],
    x -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 5];
  {gammaProductsEqual[refined, gammaProductsRatioPrefactor[x]
      gammaProductsBracket[x, Take[gammaProductsRatioCoefficients, 5]], x > 2],
    TrueQ[(s["TargetDomain"] /. x -> 1) === False],
    TrueQ[(s["SeriesRepresentation"]["Domain"] /. x -> 1) === False],
    TrueQ[(refined["TargetDomain"] /. x -> 1) === False],
    TrueQ[refined["TargetDomain"] /. x -> 3], refined["RemainderPower"]}],
  {True, True, True, True, True, 5},
  TestID -> "gamma-products-conditional-domain-survives-representation-and-refinement"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[3/x]/Gamma[1/x], x -> 0, SeriesTermGoal -> 5];
  {gammaProductsEqual[s, gammaProductsRatioPrefactor[1/x]
      gammaProductsBracket[1/x, Take[gammaProductsRatioCoefficients, 5]], x > 0],
    s["RemainderVariable"] === x, s["RemainderPower"], s["Direction"]}],
  {True, True, 5, "FromAbove"},
  TestID -> "gamma-products-reciprocal-arguments-at-positive-finite-endpoint"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[3 x]/Gamma[x], {x, Infinity, 7/2}];
  {gammaProductsEqual[s, gammaProductsRatioPrefactor[x]
      gammaProductsBracket[x, Take[gammaProductsRatioCoefficients, 4]], x > 0],
    s["Cutoff"], s["RemainderPower"], Length[s["Terms"]]}],
  {True, 7/2, 4, 4},
  TestID -> "gamma-products-rational-relative-cutoff-retains-complete-blocks"]

VerificationTest[Module[{x},
  Quiet[{
    FailureQ[AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity, SeriesTermGoal -> 0]],
    FailureQ[AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity,
      SeriesTermGoal -> 5, "MaxTerms" -> 1]],
    FailureQ[AsymptoticExpansion[Gamma[3 x]/Gamma[x], {x, Infinity, 3.5}]],
    FailureQ[AsymptoticExpansion[Gamma[3 x]^I/Gamma[x], x -> Infinity, SeriesTermGoal -> 5]],
    FailureQ[AsymptoticExpansion[Gamma[3 x]^2.5/Gamma[x], x -> Infinity, SeriesTermGoal -> 5]]}]],
  {True, True, True, True, True},
  TestID -> "gamma-products-invalid-goals-budgets-cutoffs-and-powers-fail"]

VerificationTest[Module[{x},
  Quiet[{
    FailureQ[AsymptoticExpansion[Gamma[3 x]/Gamma[-x], x -> Infinity, SeriesTermGoal -> 5]],
    FailureQ[AsymptoticExpansion[ConditionalExpression[Gamma[3 x]/Gamma[x], x < 0],
      x -> Infinity, SeriesTermGoal -> 5]]}]],
  {True, True},
  TestID -> "gamma-products-rejects-negative-tail-factor-and-incompatible-domain"]
