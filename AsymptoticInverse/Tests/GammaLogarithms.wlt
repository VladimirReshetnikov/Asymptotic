(* Independent logarithmic Stirling coefficients:
   1/12, -1/360, 1/1260, -1/1680, 1/1188, -691/360360.
   Tests count complete power-log blocks, not the separate summands inside
   their logarithmic polynomial coefficients. Negative finite arguments
   also guard the distinction between real Log[Gamma] and LogGamma. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

gammaLogarithmsStirling5[x_] := (x - 1/2) Log[x] - x + Log[2 Pi]/2 +
  1/(12 x) - 1/(360 x^3) + 1/(1260 x^5);
gammaLogarithmsEqual[s_, expected_, ass_: True] :=
  MatchQ[s, _PowerLogSeries] && TrueQ[FullSimplify[Normal[s] == expected, ass]];

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Log[Gamma[x]], x -> Infinity, SeriesTermGoal -> 5];
  {gammaLogarithmsEqual[s, gammaLogarithmsStirling5[x], x > 0],
    s["Terms"][[All, 1]], s["RemainderPower"], s["RemainderLogDegree"],
    s["Remainder"] === PowerLogRemainder[1/x, 7, 0],
    TrueQ[FullSimplify[s["FrontierTerm"] == -1/(1680 x^7), x > 0]],
    s["Exact"]}],
  {True, {-1, 0, 1, 3, 5}, 7, 0, True, True, False},
  TestID -> "gamma-logarithms-user-five-complete-blocks-and-independent-frontier"]

VerificationTest[Module[{x, one, two},
  one = AsymptoticExpansion[Log[Gamma[x]], x -> Infinity, SeriesTermGoal -> 1];
  two = AsymptoticExpansion[Log[Gamma[x]], x -> Infinity, SeriesTermGoal -> 2];
  {gammaLogarithmsEqual[one, x (Log[x] - 1), x > 0], Length[one["Terms"]],
    one["RemainderPower"], one["RemainderLogDegree"],
    gammaLogarithmsEqual[two, x (Log[x] - 1) + (Log[2 Pi] - Log[x])/2, x > 0],
    Length[two["Terms"]], two["RemainderPower"]}],
  {True, 1, 0, 1, True, 2, 1},
  TestID -> "gamma-logarithms-term-goal-retains-complete-equal-power-logarithmic-polynomials"]

VerificationTest[Module[{x, square, reciprocal},
  square = AsymptoticExpansion[Log[Gamma[x]^2], x -> Infinity, SeriesTermGoal -> 5];
  reciprocal = AsymptoticExpansion[Log[Gamma[x]^-2], x -> Infinity, SeriesTermGoal -> 5];
  {gammaLogarithmsEqual[square, 2 gammaLogarithmsStirling5[x], x > 0],
    gammaLogarithmsEqual[reciprocal, -2 gammaLogarithmsStirling5[x], x > 0],
    square["RemainderPower"], reciprocal["RemainderPower"]}],
  {True, True, 7, 7},
  TestID -> "gamma-logarithms-positive-Gamma-square-and-reciprocal-use-real-log-identities"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Log[Gamma[x]^x], x -> Infinity, SeriesTermGoal -> 5];
  {gammaLogarithmsEqual[s, x gammaLogarithmsStirling5[x], x > 0],
    s["Terms"][[All, 1]], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == -1/(1680 x^6), x > 0]]}],
  {True, {-2, -1, 0, 2, 4}, 6, True},
  TestID -> "gamma-logarithms-varying-real-power-shifts-absolute-Stirling-order"]

VerificationTest[Module[{x, s, expected},
  s = AsymptoticExpansion[Log[Gamma[3 x]/Gamma[x]], x -> Infinity, SeriesTermGoal -> 5];
  expected = 2 x Log[x] + (3 Log[3] - 2) x - Log[3]/2 -
    1/(18 x) + 13/(4860 x^3) - 121/(153090 x^5);
  {gammaLogarithmsEqual[s, expected, x > 0], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == 1093/(1837080 x^7), x > 0]]}],
  {True, 7, True},
  TestID -> "gamma-logarithms-ratio-combines-independent-scaled-Bernoulli-coefficients"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Log[Gamma[x + 1]/Gamma[x]],
    x -> Infinity, SeriesTermGoal -> 5];
  {gammaLogarithmsEqual[s, Log[x], x > 0], s["Remainder"], Length[s["Terms"]]}],
  {True, 0, 1},
  TestID -> "gamma-logarithms-exact-recurrence-terminates-before-term-goal"]

VerificationTest[Module[{x, wrapped, analytic},
  wrapped = AsymptoticExpansion[Log[Gamma[x + 1]] - Log[Gamma[x]],
    x -> Infinity, SeriesTermGoal -> 5];
  analytic = AsymptoticExpansion[LogGamma[x + 1] - LogGamma[x],
    x -> Infinity, SeriesTermGoal -> 5];
  {gammaLogarithmsEqual[wrapped, Log[x], x > 0], wrapped["Remainder"],
    gammaLogarithmsEqual[analytic, Log[x], x > 0], analytic["Remainder"]}],
  {True, 0, True, 0},
  TestID -> "gamma-logarithms-separate-logarithms-and-LogGamma-recurrence-stay-exact"]

VerificationTest[Module[{x, s, expected},
  s = AsymptoticExpansion[Log[Gamma[x]] - (x - 1/2) Log[x] + x - Log[2 Pi]/2,
    x -> Infinity, SeriesTermGoal -> 5];
  expected = 1/(12 x) - 1/(360 x^3) + 1/(1260 x^5) - 1/(1680 x^7) + 1/(1188 x^9);
  {gammaLogarithmsEqual[s, expected, x > 0], s["Terms"][[All, 1]],
    s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == -691/(360360 x^11), x > 0]]}],
  {True, {1, 3, 5, 7, 9}, 11, True},
  TestID -> "gamma-logarithms-dominant-block-cancellation-requests-more-Stirling-data"]

VerificationTest[Module[{x, binomial, beta, binomialExpected, betaExpected},
  binomial = AsymptoticExpansion[Log[Binomial[2 x, x]], x -> Infinity, SeriesTermGoal -> 5];
  beta = AsymptoticExpansion[Log[Beta[x, x]], x -> Infinity, SeriesTermGoal -> 5];
  binomialExpected = x Log[4] - Log[Pi x]/2 - 1/(8 x) + 1/(192 x^3) - 1/(640 x^5);
  betaExpected = -x Log[4] + Log[2 Sqrt[Pi]] - Log[x]/2 + 1/(8 x) - 1/(192 x^3) + 1/(640 x^5);
  {gammaLogarithmsEqual[binomial, binomialExpected, x > 0],
    gammaLogarithmsEqual[beta, betaExpected, x > 0],
    binomial["RemainderPower"], beta["RemainderPower"]}],
  {True, True, 7, 7},
  TestID -> "gamma-logarithms-complete-Beta-and-Binomial-use-positive-Gamma-products"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Log[Factorial[x]], x -> Infinity, SeriesTermGoal -> 5];
  {gammaLogarithmsEqual[s, gammaLogarithmsStirling5[x] + Log[x], x > 0],
    s["Terms"][[All, 1]], s["RemainderPower"]}],
  {True, {-1, 0, 1, 3, 5}, 7},
  TestID -> "gamma-logarithms-Factorial-shift-keeps-correct-logarithmic-constant-block"]

VerificationTest[Module[{x, s, pole},
  s = AsymptoticExpansion[Log[Gamma[1/x]], x -> 0, SeriesTermGoal -> 5];
  pole = AsymptoticExpansion[Log[Gamma[x]], {x, 0, 2}];
  {gammaLogarithmsEqual[s, gammaLogarithmsStirling5[1/x], x > 0],
    s["RemainderVariable"] === x, s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == -x^7/1680, x > 0]],
    gammaLogarithmsEqual[pole, -Log[x] - EulerGamma x, x > 0],
    pole["RemainderPower"]}],
  {True, True, 7, True, True, 2},
  TestID -> "gamma-logarithms-zero-approach-distinguishes-growing-argument-and-Gamma-pole"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Log[Gamma[1 + x]], {x, 0, 4}];
  {gammaLogarithmsEqual[s, -EulerGamma x + Pi^2 x^2/12 - Zeta[3] x^3/3],
    s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == Pi^4 x^4/360]]}],
  {True, 4, True},
  TestID -> "gamma-logarithms-finite-positive-Gamma-argument-keeps-analytic-Taylor-series"]

VerificationTest[Module[{x, s, delta, expected},
  s = AsymptoticExpansion[Log[Gamma[x]], {x, -3/2, 3}];
  delta = x + 3/2;
  expected = Log[4 Sqrt[Pi]/3] + (8/3 - EulerGamma - 2 Log[2]) delta +
    (Pi^2/4 + 20/9) delta^2;
  {gammaLogarithmsEqual[s, expected, -3/2 < x < -1], s["RemainderPower"],
    TrueQ[FullSimplify[Im[Normal[s]] == 0, -3/2 < x < -1]]}],
  {True, 3, True},
  TestID -> "gamma-logarithms-negative-finite-positive-Gamma-value-keeps-real-log-branch"]

VerificationTest[Module[{x, s, expected},
  s = AsymptoticExpansion[Log[Gamma[x]^2], {x, -1/2, 2}];
  expected = Log[4 Pi] + 2 (2 - EulerGamma - 2 Log[2]) (x + 1/2);
  {gammaLogarithmsEqual[s, expected, -1/2 < x < 0], s["RemainderPower"]}],
  {True, 2},
  TestID -> "gamma-logarithms-square-of-negative-finite-Gamma-retains-positive-log-argument"]

VerificationTest[Module[{x},
  Quiet[{FailureQ[AsymptoticExpansion[Log[-Gamma[x]], x -> Infinity, SeriesTermGoal -> 3]],
    FailureQ[AsymptoticExpansion[Log[Gamma[x]], x -> -Infinity, SeriesTermGoal -> 3]],
    FailureQ[AsymptoticExpansion[Log[Gamma[x]], {x, -1/2, 2}]],
    FailureQ[AsymptoticExpansion[ConditionalExpression[Log[Gamma[x]], x < 0],
      x -> Infinity, SeriesTermGoal -> 3]]}]],
  {True, True, True, True},
  TestID -> "gamma-logarithms-negative-sign-pole-filled-tail-and-incompatible-domains-fail"]

VerificationTest[Module[{x, s, refined},
  s = AsymptoticExpansion[ConditionalExpression[Log[Gamma[x]], x > 100],
    x -> Infinity, SeriesTermGoal -> 3];
  refined = SeriesRefine[s, 7];
  {gammaLogarithmsEqual[refined, gammaLogarithmsStirling5[x], x > 100],
    refined["RemainderPower"], ! FreeQ[refined["Function"], _Gamma],
    TrueQ[(refined["TargetDomain"] /. x -> 100) === False],
    TrueQ[refined["TargetDomain"] /. x -> 101]}],
  {True, 7, True, True, True},
  TestID -> "gamma-logarithms-refinement-replays-original-expression-and-target-condition"]

VerificationTest[Module[{x, r, s},
  s = AsymptoticExpansion[Log[Gamma[x]^r], x -> Infinity,
    Assumptions -> Element[r, Reals], SeriesTermGoal -> 5];
  {gammaLogarithmsEqual[s, r gammaLogarithmsStirling5[x], x > 0 && Element[r, Reals]],
    s["RemainderPower"],
    Quiet[FailureQ[AsymptoticExpansion[Log[Gamma[x]^r], x -> Infinity, SeriesTermGoal -> 3]]]}],
  {True, 7, True},
  TestID -> "gamma-logarithms-symbolic-power-needs-explicit-real-assumptions"]

VerificationTest[Module[{x, s, expected},
  s = AsymptoticExpansion[Log[Gamma[x]/Gamma[1 + 1/x]],
    x -> Infinity, SeriesTermGoal -> 5];
  expected = (x - 1/2) Log[x] - x + Log[2 Pi]/2 +
    (EulerGamma + 1/12)/x - Pi^2/(12 x^2) + (Zeta[3]/3 - 1/360)/x^3;
  {gammaLogarithmsEqual[s, expected, x > 0], s["Terms"][[All, 1]],
    s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == -Pi^4/(360 x^4), x > 0]]}],
  {True, {-1, 0, 1, 2, 3}, 4, True},
  TestID -> "gamma-logarithms-mixed-growing-and-finite-Gamma-arguments-include-zeta-corrections"]
