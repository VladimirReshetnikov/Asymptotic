(* Independent coefficient oracles: convolve the classical Stirling
   coefficients to square Gamma, or expand the formal logarithm
     r/(12 x) - r/(360 x^3) + r/(1260 x^5) + ... .
   No package operation or native Series supplies the expected values. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

gammaPowersSquareCoefficients = {1, 1/6, 1/72, -31/6480,
  -139/155520, 9871/6531840};
gammaPowersRootCoefficients = {1, 1/24, 1/1152, -571/414720,
  -2299/39813120};
gammaPowersPrefactor[z_, r_] := (Sqrt[2 Pi] Exp[-z] z^(z - 1/2))^r;
gammaPowersBracket[z_, coefficients_List] :=
  Sum[coefficients[[k + 1]] z^-k, {k, 0, Length[coefficients] - 1}];
gammaPowersEqual[s_, expr_, ass_: True] :=
  MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[s] == expr, ass]];

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[x]^2, x -> Infinity, SeriesTermGoal -> 5];
  {gammaPowersEqual[s, gammaPowersPrefactor[x, 2]
      gammaPowersBracket[x, Take[gammaPowersSquareCoefficients, 5]], x > 0],
    s["Terms"], s["Kind"], s["Scale"], s["ExpansionPoint"],
    s["RemainderVariable"] === 1/x, s["RemainderPower"], s["RemainderLogDegree"],
    s["RequestedTermGoal"], s["ReturnedTermCount"]}],
  {True, Transpose[{Range[0, 4], Take[gammaPowersSquareCoefficients, 5]}],
    "Forward", "Factored", Infinity, True, 5, 0, 5, 5},
  TestID -> "gamma-powers-user-rule-square-five-independent-coefficients"]

VerificationTest[Module[{x, s, pref},
  s = AsymptoticExpansion[Gamma[x]^2, {x, Infinity}, SeriesTermGoal -> 5];
  pref = 2 Pi Exp[-2 x] x^(2 x - 1);
  {TrueQ[FullSimplify[s["Prefactor"] == pref, x > 0]],
    TrueQ[FullSimplify[s["Remainder"] == pref PowerLogRemainder[1/x, 5, 0], x > 0]],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^5, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == pref 9871/(6531840 x^5), x > 0]],
    s["GammaPower"], s["LogarithmicFunction"] === 2 LogGamma[x],
    s["Exact"], s["RemainderDerivativeOrder"]}],
  {True, True, True, True, 2, True, False, 0},
  TestID -> "gamma-powers-square-tracks-full-prefactor-frontier-and-logarithmic-source"]

VerificationTest[Module[{x, s, pref, coefficients},
  coefficients = {1, -1/6, 1/72, 31/6480, -139/155520};
  pref = Exp[2 x] x^(1 - 2 x)/(2 Pi);
  s = AsymptoticExpansion[Gamma[x]^-2, x -> Infinity, SeriesTermGoal -> 5];
  {gammaPowersEqual[s, pref gammaPowersBracket[x, coefficients], x > 0],
    s["Terms"], s["RemainderPower"],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^5, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == -pref 9871/(6531840 x^5), x > 0]]}],
  {True, Transpose[{Range[0, 4], {1, -1/6, 1/72, 31/6480, -139/155520}}],
    5, True, True},
  TestID -> "gamma-powers-reciprocal-square-retains-decaying-prefactor-and-error"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Sqrt[Gamma[x]], x -> Infinity, SeriesTermGoal -> 5];
  {gammaPowersEqual[s, gammaPowersPrefactor[x, 1/2]
      gammaPowersBracket[x, gammaPowersRootCoefficients], x > 0],
    s["Terms"], s["GammaPower"], s["RemainderPower"],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] ==
      gammaPowersPrefactor[x, 1/2]/x^5, x > 0]]}],
  {True, Transpose[{Range[0, 4], gammaPowersRootCoefficients}], 1/2, 5, True},
  TestID -> "gamma-powers-principal-square-root-has-independent-correction-coefficients"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[x]^Sqrt[2], x -> Infinity, SeriesTermGoal -> 3];
  {gammaPowersEqual[s, gammaPowersPrefactor[x, Sqrt[2]]
      (1 + Sqrt[2]/(12 x) + 1/(144 x^2)), x > 0],
    s["GammaPower"], s["RemainderPower"], Length[s["Terms"]]}],
  {True, Sqrt[2], 3, 3},
  TestID -> "gamma-powers-exact-irrational-constant-is-supported"]

VerificationTest[Module[{x, s, coefficients},
  (* At r = 12/Sqrt[5], r^3/10368 - r/360 is exactly zero.
     The term goal must skip that vanished degree-three block. *)
  coefficients = {1, 1/Sqrt[5], 1/10, -1/200, 137/(21000 Sqrt[5])};
  s = AsymptoticExpansion[Gamma[x]^(12/Sqrt[5]), x -> Infinity, SeriesTermGoal -> 5];
  {gammaPowersEqual[s, gammaPowersPrefactor[x, 12/Sqrt[5]]
      (1 + 1/(Sqrt[5] x) + 1/(10 x^2) - 1/(200 x^4)
        + 137/(21000 Sqrt[5] x^5)), x > 0],
    s["Terms"][[All, 1]],
    TrueQ[FullSimplify[s["Terms"][[All, 2]] == coefficients]],
    s["RemainderPower"], s["ReturnedTermCount"]}],
  {True, {0, 1, 2, 4, 5}, True, 6, 5},
  TestID -> "gamma-powers-term-goal-counts-nonzero-blocks-after-exact-cancellation"]

VerificationTest[Module[{x, s, refined, truncated},
  s = AsymptoticExpansion[Gamma[x]^2, x -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 6]; truncated = SeriesTruncate[refined, 3];
  {gammaPowersEqual[refined, gammaPowersPrefactor[x, 2]
      gammaPowersBracket[x, gammaPowersSquareCoefficients], x > 0],
    refined["GammaPower"], refined["RemainderPower"], Length[refined["Terms"]],
    gammaPowersEqual[truncated, gammaPowersPrefactor[x, 2]
      (1 + 1/(6 x) + 1/(72 x^2)), x > 0],
    truncated["RemainderPower"],
    TrueQ[FullSimplify[truncated["RemainderScaleExpression"] ==
      gammaPowersPrefactor[x, 2]/x^3, x > 0]]}],
  {True, 2, 6, 6, True, 3, True},
  TestID -> "gamma-powers-refinement-replays-power-and-truncation-transports-error"]

VerificationTest[Module[{x, s, refined},
  s = AsymptoticExpansion[ConditionalExpression[Gamma[x]^2, x > 2],
    x -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 5];
  {gammaPowersEqual[refined, gammaPowersPrefactor[x, 2]
      gammaPowersBracket[x, Take[gammaPowersSquareCoefficients, 5]], x > 2],
    TrueQ[(s["TargetDomain"] /. x -> 1) === False],
    TrueQ[(s["SeriesRepresentation"]["Domain"] /. x -> 1) === False],
    TrueQ[(refined["TargetDomain"] /. x -> 1) === False],
    TrueQ[refined["TargetDomain"] /. x -> 3], refined["GammaPower"], refined["RemainderPower"]}],
  {True, True, True, True, True, 2, 5},
  TestID -> "gamma-powers-conditional-domain-survives-representation-and-refinement"]

VerificationTest[Module[{x, s, varying},
  s = AsymptoticExpansion[Gamma[x]^2, {x, 1, 3}];
  varying = AsymptoticExpansion[Gamma[x]^x, {x, 1, 3}];
  {gammaPowersEqual[s, 1 - 2 EulerGamma (x - 1)
      + (2 EulerGamma^2 + Pi^2/6) (x - 1)^2], s["RemainderPower"],
    gammaPowersEqual[varying, 1 - EulerGamma (x - 1)
      + (EulerGamma^2/2 + Pi^2/12 - EulerGamma) (x - 1)^2],
    varying["RemainderPower"]}],
  {True, 3, True, 3},
  TestID -> "gamma-powers-regular-finite-expansion-remains-supported"]

VerificationTest[Module[{x},
  Quiet[{
    FailureQ[AsymptoticExpansion[Gamma[x]^I, x -> Infinity, SeriesTermGoal -> 5]],
    FailureQ[AsymptoticExpansion[Gamma[x]^2.5, x -> Infinity, SeriesTermGoal -> 5]]}]],
  {True, True},
  TestID -> "gamma-powers-rejects-nonreal-and-inexact-exponents"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[2 x]^2, x -> Infinity, SeriesTermGoal -> 5];
  {gammaPowersEqual[s, gammaPowersPrefactor[2 x, 2]
      gammaPowersBracket[2 x, Take[gammaPowersSquareCoefficients, 5]], x > 0],
    s["RemainderPower"], s["ReturnedTermCount"], s["GammaPower"]}],
  {True, 5, 5, 2},
  TestID -> "gamma-powers-positive-scaled-argument"]

VerificationTest[Module[{x, s, normalizedGammaSquared, normalizedApproximation, ratio},
  s = AsymptoticExpansion[Gamma[x]^2, x -> Infinity, SeriesTermGoal -> 5];
  (* Keep the numerical oracle in the logarithmic domain: both Gamma[1000]^2
     and its exact prefactor are huge, but their ratio is near one. *)
  normalizedGammaSquared = Exp[N[2 (LogGamma[1000]
    - ((1000 - 1/2) Log[1000] - 1000 + Log[2 Pi]/2)), 100]];
  normalizedApproximation = N[FullSimplify[Normal[s]/s["Prefactor"], x > 0]
    /. x -> 1000, 100];
  ratio = (normalizedGammaSquared - normalizedApproximation) 1000^5/(9871/6531840);
  TrueQ[0 < ratio && Abs[ratio - 1] < 1/100]],
  True,
  TestID -> "gamma-powers-numerical-square-agrees-at-independent-first-omitted-scale"]
