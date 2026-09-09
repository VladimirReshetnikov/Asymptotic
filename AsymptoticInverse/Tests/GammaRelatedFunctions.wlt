(* The independent rational coefficient tables follow from Stirling's
   Bernoulli-polynomial logarithm and formal exponential convolution.
   Exact identities provide separate cancellation oracles. No native Series
   or package operation is used to obtain the expected coefficients. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

gammaRelatedStirling = {1, 1/12, 1/288, -139/51840, -571/2488320};
gammaRelatedBalanced = {1, -1/8, 1/128, 5/1024, -21/32768};
gammaRelatedBeta = {1, 1/8, 1/128, -5/1024, -21/32768};
gammaRelatedHalfShift = {1, -1/24, 1/1152, 1003/414720, -4027/39813120};
gammaRelatedBracket[z_, coefficients_List] :=
  Sum[coefficients[[k + 1]] z^-k, {k, 0, Length[coefficients] - 1}];
gammaRelatedGammaPrefactor[z_] := Sqrt[2 Pi] Exp[-z] z^(z - 1/2);
gammaRelatedFactorialPrefactor[z_] := Sqrt[2 Pi z] Exp[-z] z^z;
gammaRelatedEqual[s_, expr_, ass_: True] :=
  MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[s] == expr, ass]];

VerificationTest[Module[{x, s, pref},
  pref = gammaRelatedFactorialPrefactor[x];
  s = AsymptoticExpansion[Factorial[x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaRelatedEqual[s, pref gammaRelatedBracket[x, gammaRelatedStirling], x > 0],
    s["ReturnedTermCount"], s["Function"] === Factorial[x],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^5, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == pref 163879/(209018880 x^5), x > 0]]}],
  {True, 5, True, True, True},
  TestID -> "gamma-related-factorial-five-independent-Stirling-coefficients"]

VerificationTest[Module[{x, s, pref},
  pref = 4^x/Sqrt[Pi x];
  s = AsymptoticExpansion[Binomial[2 x, x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaRelatedEqual[s, pref gammaRelatedBracket[x, gammaRelatedBalanced], x > 0],
    s["ReturnedTermCount"], s["Function"] === Binomial[2 x, x],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^5, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == -pref 399/(262144 x^5), x > 0]]}],
  {True, 5, True, True, True},
  TestID -> "gamma-related-central-binomial-five-independent-coefficients"]

VerificationTest[Module[{x, s, pref},
  pref = 2 Sqrt[Pi] 4^-x/Sqrt[x];
  s = AsymptoticExpansion[Beta[x, x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaRelatedEqual[s, pref gammaRelatedBracket[x, gammaRelatedBeta], x > 0],
    s["ReturnedTermCount"], s["Function"] === Beta[x, x],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^5, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == pref 399/(262144 x^5), x > 0]]}],
  {True, 5, True, True, True},
  TestID -> "gamma-related-complete-beta-five-independent-coefficients"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Pochhammer[x, 1/2], x -> Infinity, SeriesTermGoal -> 5];
  {gammaRelatedEqual[s, Sqrt[x] gammaRelatedBracket[x, gammaRelatedBalanced], x > 0],
    s["ReturnedTermCount"], s["Function"] === Pochhammer[x, 1/2],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == x^(-9/2), x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == -399/(262144 x^(9/2)), x > 0]]}],
  {True, 5, True, True, True},
  TestID -> "gamma-related-fixed-length-pochhammer-cancels-Gamma-carriers"]

VerificationTest[Module[{x, s, pref},
  (* B_2(1/2)/2 = -1/24 and B_4(1/2)/12 = 7/2880;
     exponential convolution gives the table and independent frontier. *)
  pref = Sqrt[2] x^x Exp[-x];
  s = AsymptoticExpansion[Pochhammer[1/2, x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaRelatedEqual[s, pref gammaRelatedBracket[x, gammaRelatedHalfShift], x > 0],
    s["ReturnedTermCount"], s["Function"] === Pochhammer[1/2, x],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^5, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == -pref 5128423/(6688604160 x^5), x > 0]]}],
  {True, 5, True, True, True},
  TestID -> "gamma-related-variable-length-pochhammer-retains-growing-carrier"]

VerificationTest[Module[{x, s, pref, coefficients},
  pref = 3^(3 x + 1/2) x^(2 x) Exp[-2 x];
  coefficients = {1, -1/18, 1/648, 463/174960, -1867/12597120};
  s = AsymptoticExpansion[Factorial[3 x]/Factorial[x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaRelatedEqual[s, pref gammaRelatedBracket[x, coefficients], x > 0],
    s["ReturnedTermCount"], s["Function"] === Factorial[3 x]/Factorial[x],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^5, x > 0]]}],
  {True, 5, True, True},
  TestID -> "gamma-related-factorial-ratio-composes-lowering-and-products"]

VerificationTest[Module[{x, s},
  (* Beta[x,x] Binomial[2x,x] = Gamma[x]^2/Gamma[2x]
     Gamma[2x+1]/Gamma[x+1]^2 = 2/x on the positive approach. *)
  s = AsymptoticExpansion[Beta[x, x] Binomial[2 x, x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaRelatedEqual[s, 2/x, x > 0], s["Remainder"], s["Exact"], Length[s["Terms"]]}],
  {True, 0, True, 1},
  TestID -> "gamma-related-mixed-head-identity-terminates-exactly"]

VerificationTest[Module[{x, binomial, pochhammer, refinedBinomial, refinedPochhammer},
  binomial = AsymptoticExpansion[Binomial[2 x, x], x -> Infinity, SeriesTermGoal -> 2];
  pochhammer = AsymptoticExpansion[Pochhammer[1/2, x], x -> Infinity, SeriesTermGoal -> 2];
  refinedBinomial = SeriesRefine[binomial, 5];
  refinedPochhammer = SeriesRefine[pochhammer, 5];
  {gammaRelatedEqual[refinedBinomial, 4^x/Sqrt[Pi x]
      gammaRelatedBracket[x, gammaRelatedBalanced], x > 0],
    gammaRelatedEqual[refinedPochhammer, Sqrt[2] x^x Exp[-x]
      gammaRelatedBracket[x, gammaRelatedHalfShift], x > 0],
    refinedBinomial["Function"] === Binomial[2 x, x],
    refinedPochhammer["Function"] === Pochhammer[1/2, x],
    Length[refinedBinomial["Terms"]], Length[refinedPochhammer["Terms"]]}],
  {True, True, True, True, 5, 5},
  TestID -> "gamma-related-refinement-retains-original-special-function-heads"]

VerificationTest[Module[{x, s},
  (* LogGamma[1+t] = -EulerGamma t + Zeta[2] t^2/2 + O[t^3]. *)
  s = AsymptoticExpansion[Gamma[1 + 1/x]/Gamma[1 + 2/x], x -> Infinity, SeriesTermGoal -> 3];
  {gammaRelatedEqual[s, 1 + EulerGamma/x + (EulerGamma^2/2 - Pi^2/4)/x^2, x > 0],
    s["RemainderPower"], Length[s["Terms"]]}],
  {True, 3, 3},
  TestID -> "gamma-related-finite-Gamma-arguments-use-regular-expansion"]

VerificationTest[Module[{x, s, pref, a},
  pref = gammaRelatedGammaPrefactor[x]; a = EulerGamma + 1/12;
  s = AsymptoticExpansion[Gamma[x]/Gamma[1 + 1/x], x -> Infinity, SeriesTermGoal -> 3];
  {gammaRelatedEqual[s, pref (1 + a/x + (a^2/2 - Pi^2/12)/x^2), x > 0],
    s["ReturnedTermCount"],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^3, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] ==
      pref (a^3/6 - a Pi^2/12 + Zeta[3]/3 - 1/360)/x^3, x > 0]]}],
  {True, 3, True, True},
  TestID -> "gamma-related-mixed-growing-and-positive-finite-Gamma-arguments"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Beta[x, 1/2], x -> Infinity, SeriesTermGoal -> 5];
  {gammaRelatedEqual[s, Sqrt[Pi/x] gammaRelatedBracket[x, gammaRelatedBeta], x > 0],
    s["ReturnedTermCount"],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == Sqrt[Pi] x^(-11/2), x > 0]]}],
  {True, 5, True},
  TestID -> "gamma-related-beta-with-positive-constant-argument"]

VerificationTest[Module[{x, s, refined},
  s = AsymptoticExpansion[ConditionalExpression[Factorial[x], x > 2],
    x -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 5];
  {gammaRelatedEqual[refined, gammaRelatedFactorialPrefactor[x]
      gammaRelatedBracket[x, gammaRelatedStirling], x > 2],
    TrueQ[(s["TargetDomain"] /. x -> 1) === False],
    TrueQ[(s["SeriesRepresentation"]["Domain"] /. x -> 1) === False],
    TrueQ[(refined["TargetDomain"] /. x -> 1) === False],
    TrueQ[refined["TargetDomain"] /. x -> 3]}],
  {True, True, True, True, True},
  TestID -> "gamma-related-conditional-domain-survives-lowering-and-refinement"]

VerificationTest[Module[{x, s, pref},
  pref = 4^x Sqrt[x]/(2 Sqrt[Pi]);
  s = AsymptoticExpansion[1/Beta[x, x], x -> Infinity, SeriesTermGoal -> 3];
  {gammaRelatedEqual[s, pref (1 - 1/(8 x) + 1/(128 x^2)), x > 0],
    s["ReturnedTermCount"],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^3, x > 0]]}],
  {True, 3, True},
  TestID -> "gamma-related-reciprocal-beta-distributes-into-Gamma-powers"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Factorial[1/x], x -> 0, SeriesTermGoal -> 3];
  {gammaRelatedEqual[s, gammaRelatedFactorialPrefactor[1/x]
      (1 + x/12 + x^2/288), x > 0],
    s["RemainderVariable"] === x, s["Direction"], s["ReturnedTermCount"]}],
  {True, True, "FromAbove", 3},
  TestID -> "gamma-related-factorial-at-positive-reciprocal-endpoint"]

VerificationTest[Module[{x},
  Quiet[{
    FailureQ[AsymptoticExpansion[Factorial[-x], x -> Infinity, SeriesTermGoal -> 5]],
    FailureQ[AsymptoticExpansion[Beta[1/3, x, x], x -> Infinity, SeriesTermGoal -> 5]],
    FailureQ[AsymptoticExpansion[Binomial[2 x, x]^I, x -> Infinity, SeriesTermGoal -> 5]],
    FailureQ[AsymptoticExpansion[Beta[x, x]^2.5, x -> Infinity, SeriesTermGoal -> 5]]}]],
  {True, True, True, True},
  TestID -> "gamma-related-rejects-negative-tail-incomplete-beta-and-unsupported-powers"]
