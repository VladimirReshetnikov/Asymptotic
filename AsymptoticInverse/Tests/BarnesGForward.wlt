(* Independent Barnes G oracles from DLMF 5.17.5, after expanding its
   LogGamma term by Stirling's formula:
     Log[G(x+1)] = C(x) + Sum[B_(2k+2)/(2k(2k+2)x^(2k)), k >= 1].
   The correction starts -1/(240x^2)+1/(1008x^4)-1/(1440x^6).
   Subtracting LogGamma[x] gives Log[G(x)]. The rational exponential
   coefficients below were calculated independently with exact arithmetic,
   using n c_n = Sum[k a_k c_(n-k), {k,1,n}], c_0 = 1.
   References: https://dlmf.nist.gov/5.17.E5 and https://dlmf.nist.gov/5.17.E1.
   No native Series or package operation supplies an expected coefficient. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

barnesForwardLogCarrierPlus[z_] := (z^2/2 - 1/12) Log[z] - 3 z^2/4 +
  z Log[2 Pi]/2 + 1/12 - Log[Glaisher];
barnesForwardLogGammaCarrier[z_] := (z - 1/2) Log[z] - z + Log[2 Pi]/2;
barnesForwardLogCarrier[z_] := barnesForwardLogCarrierPlus[z] - barnesForwardLogGammaCarrier[z];
barnesForwardCoefficients = {1, -1/12, -1/1440, 157/51840, 65911/87091200};
barnesForwardPlusCoefficients = {1, -1/240, 269/268800,
  -405607/580608000, 40788235739/42918543360000};
barnesForwardGammaCoefficients = {1, 1/12, 1/288, -139/51840, -571/2488320};
barnesForwardCarrierEqual[s_, expected_, ass_] := MatchQ[s, _GeneralizedSeries] &&
  TrueQ[FullSimplify[Log[s["Prefactor"]] - expected, ass] === 0];
barnesForwardEqual[s_, expected_, ass_: True] := MatchQ[s, _GeneralizedSeries] &&
  TrueQ[FullSimplify[Normal[s] == expected, ass]];

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[BarnesG[x], x -> Infinity, SeriesTermGoal -> 5];
  {barnesForwardCarrierEqual[s, barnesForwardLogCarrier[x], x > 0],
    s["Terms"], s["RemainderPower"], s["RemainderLogDegree"],
    s["RequestedTermGoal"], s["ReturnedTermCount"], s["Exact"],
    TrueQ[FullSimplify[s["FrontierTerm"]/s["Prefactor"] ==
      -918227/(1045094400 x^5), x > 0]]}],
  {True, Transpose[{Range[0, 4], barnesForwardCoefficients}], 5, 0, 5, 5, False, True},
  TestID -> "barnes-g-user-five-independent-correction-coefficients-and-frontier"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[BarnesG[x + 1], x -> Infinity, SeriesTermGoal -> 5];
  {barnesForwardCarrierEqual[s, barnesForwardLogCarrierPlus[x], x > 0],
    s["Terms"], s["RemainderPower"], s["ReturnedTermCount"],
    TrueQ[FullSimplify[s["FrontierTerm"]/s["Prefactor"] ==
      -471777631535669/(223176425472000000 x^10), x > 0]],
    TrueQ[FullSimplify[s["RemainderScaleExpression"]/s["Prefactor"] == x^-10, x > 0]]}],
  {True, Transpose[{Range[0, 8, 2], barnesForwardPlusCoefficients}], 10, 5, True, True},
  TestID -> "barnes-g-unit-shift-needs-even-corrections-through-order-ten"]

VerificationTest[Module[{x, unshifted, shifted},
  unshifted = AsymptoticExpansion[Log[BarnesG[x]], x -> Infinity, SeriesTermGoal -> 5];
  shifted = AsymptoticExpansion[Log[BarnesG[x + 1]], x -> Infinity, SeriesTermGoal -> 5];
  {barnesForwardEqual[unshifted, barnesForwardLogCarrier[x] - 1/(12 x) - 1/(240 x^2), x > 0],
    unshifted["Terms"][[All, 1]], unshifted["RemainderPower"],
    TrueQ[FullSimplify[unshifted["FrontierTerm"] == 1/(360 x^3), x > 0]],
    barnesForwardEqual[shifted, barnesForwardLogCarrierPlus[x] - 1/(240 x^2) + 1/(1008 x^4), x > 0],
    shifted["Terms"][[All, 1]], shifted["RemainderPower"],
    TrueQ[FullSimplify[shifted["FrontierTerm"] == -1/(1440 x^6), x > 0]]}],
  {True, {-2, -1, 0, 1, 2}, 3, True, True, {-2, -1, 0, 2, 4}, 6, True},
  TestID -> "barnes-g-logarithms-count-complete-logarithmic-coefficient-blocks"]

VerificationTest[Module[{x, square, reciprocal},
  square = AsymptoticExpansion[BarnesG[x + 1]^2, x -> Infinity, SeriesTermGoal -> 3];
  reciprocal = AsymptoticExpansion[1/BarnesG[x + 1], x -> Infinity, SeriesTermGoal -> 3];
  {barnesForwardCarrierEqual[square, 2 barnesForwardLogCarrierPlus[x], x > 0],
    square["Terms"], square["RemainderPower"],
    barnesForwardCarrierEqual[reciprocal, -barnesForwardLogCarrierPlus[x], x > 0],
    reciprocal["Terms"], reciprocal["RemainderPower"],
    TrueQ[FullSimplify[reciprocal["FrontierTerm"]/reciprocal["Prefactor"] ==
      400807/(580608000 x^6), x > 0]]}],
  {True, {{0, 1}, {2, -1/120}, {4, 407/201600}}, 6,
    True, {{0, 1}, {2, 1/240}, {4, -793/806400}}, 6, True},
  TestID -> "barnes-g-square-and-reciprocal-preserve-relative-even-order"]

VerificationTest[Module[{x, s, quadraticPower},
  s = AsymptoticExpansion[BarnesG[x + 1]^x, x -> Infinity, SeriesTermGoal -> 3];
  quadraticPower = AsymptoticExpansion[BarnesG[x + 1]^(x^2),
    x -> Infinity, SeriesTermGoal -> 3];
  {barnesForwardCarrierEqual[s, x barnesForwardLogCarrierPlus[x], x > 0],
    s["Terms"], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"]/s["Prefactor"] ==
      (1/1008 - 1/82944000)/x^3, x > 0]],
    barnesForwardCarrierEqual[quadraticPower,
      x^2 barnesForwardLogCarrierPlus[x] - 1/240, x > 0],
    quadraticPower["Terms"], quadraticPower["RemainderPower"],
    TrueQ[FullSimplify[quadraticPower["FrontierTerm"]/quadraticPower["Prefactor"] ==
      319827367/(337983528960 x^6), x > 0]]}],
  {True, {{0, 1}, {1, -1/240}, {2, 1/115200}}, 3, True,
    True, {{0, 1}, {2, 1/1008}, {4, -7051/10160640}}, 6, True},
  TestID -> "barnes-g-varying-real-power-shifts-logarithmic-error-before-exponentiation"]

VerificationTest[Module[{x, r, s, coefficients},
  s = AsymptoticExpansion[BarnesG[x + 1]^r, x -> Infinity,
    Assumptions -> Element[r, Reals], SeriesTermGoal -> 3];
  coefficients = {1, -r/240, r/1008 + r^2/115200};
  {barnesForwardCarrierEqual[s, r barnesForwardLogCarrierPlus[x], x > 0 && Element[r, Reals]],
    s["Terms"][[All, 1]],
    TrueQ[FullSimplify[s["Terms"][[All, 2]] == coefficients, Element[r, Reals]]],
    s["RemainderPower"],
    Quiet[FailureQ[AsymptoticExpansion[BarnesG[x]^r, x -> Infinity, SeriesTermGoal -> 3]]]}],
  {True, {0, 2, 4}, True, 6, True},
  TestID -> "barnes-g-symbolic-power-retains-exact-real-parameter-assumptions"]

VerificationTest[Module[{x, s, coefficients},
  coefficients = {1, 1/12, -1/1440, -157/51840, 65911/87091200};
  s = AsymptoticExpansion[BarnesG[x + 1] Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
  {barnesForwardCarrierEqual[s,
      barnesForwardLogCarrierPlus[x] + barnesForwardLogGammaCarrier[x], x > 0],
    s["Terms"], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"]/s["Prefactor"] ==
      918227/(1045094400 x^5), x > 0]]}],
  {True, Transpose[{Range[0, 4], {1, 1/12, -1/1440, -157/51840, 65911/87091200}}], 5, True},
  TestID -> "barnes-g-mixed-Gamma-product-combines-independent-logarithmic-corrections"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[BarnesG[x] Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
  {barnesForwardCarrierEqual[s, barnesForwardLogCarrierPlus[x], x > 0],
    s["Terms"], s["RemainderPower"], s["ReturnedTermCount"]}],
  {True, Transpose[{Range[0, 8, 2], barnesForwardPlusCoefficients}], 10, 5},
  TestID -> "barnes-g-mixed-recurrence-product-cancels-odd-corrections-before-term-goal"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[BarnesG[x + 1]/BarnesG[x], x -> Infinity, SeriesTermGoal -> 5];
  {barnesForwardCarrierEqual[s, barnesForwardLogGammaCarrier[x], x > 0],
    s["Terms"], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"]/s["Prefactor"] ==
      163879/(209018880 x^5), x > 0]]}],
  {True, Transpose[{Range[0, 4], barnesForwardGammaCoefficients}], 5, True},
  TestID -> "barnes-g-recurrence-ratio-recovers-independent-Gamma-Stirling-series"]

VerificationTest[Module[{x, unit, linear},
  unit = AsymptoticExpansion[BarnesG[x + 1]/(Gamma[x] BarnesG[x]),
    x -> Infinity, SeriesTermGoal -> 5];
  linear = AsymptoticExpansion[BarnesG[x + 2] BarnesG[x]/BarnesG[x + 1]^2,
    x -> Infinity, SeriesTermGoal -> 5];
  {barnesForwardEqual[unit, 1, x > 0], unit["Remainder"], unit["Exact"],
    barnesForwardEqual[linear, x, x > 0], linear["Remainder"], linear["Exact"]}],
  {True, 0, True, True, 0, True},
  TestID -> "barnes-g-exact-first-and-second-recurrence-ratios-terminate"]

VerificationTest[Module[{x, s, expected},
  s = AsymptoticExpansion[Log[BarnesG[x + 1]] - Log[BarnesG[x]],
    x -> Infinity, SeriesTermGoal -> 5];
  expected = barnesForwardLogGammaCarrier[x] + 1/(12 x) - 1/(360 x^3) + 1/(1260 x^5);
  {barnesForwardEqual[s, expected, x > 0], s["Terms"][[All, 1]], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == -1/(1680 x^7), x > 0]]}],
  {True, {-1, 0, 1, 3, 5}, 7, True},
  TestID -> "barnes-g-separate-logarithms-cancel-to-log-Gamma-before-expansion"]

VerificationTest[Module[{x, s, refined, truncated},
  s = AsymptoticExpansion[ConditionalExpression[BarnesG[x], x > 2],
    x -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 5]; truncated = SeriesTruncate[refined, 7/2];
  {barnesForwardCarrierEqual[refined, barnesForwardLogCarrier[x], x > 2],
    refined["Terms"], refined["RemainderPower"], ! FreeQ[refined["Function"], _BarnesG],
    TrueQ[(refined["TargetDomain"] /. x -> 1) === False],
    TrueQ[refined["TargetDomain"] /. x -> 3],
    truncated["Terms"], truncated["Cutoff"], truncated["RemainderPower"]}],
  {True, Transpose[{Range[0, 4], barnesForwardCoefficients}], 5, True, True, True,
    Transpose[{Range[0, 3], Take[barnesForwardCoefficients, 4]}], 7/2, 4},
  TestID -> "barnes-g-refinement-and-rational-relative-truncation-preserve-source-domain"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[BarnesG[1 + 1/x], x -> 0, SeriesTermGoal -> 3];
  {barnesForwardCarrierEqual[s, barnesForwardLogCarrierPlus[1/x], x > 0],
    s["Terms"], s["RemainderVariable"] === x, s["RemainderPower"], s["Direction"]}],
  {True, {{0, 1}, {2, -1/240}, {4, 269/268800}}, True, 6, "FromAbove"},
  TestID -> "barnes-g-positive-growing-composition-at-zero-uses-local-coordinate"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[BarnesG[2 x + 1], x -> Infinity, SeriesTermGoal -> 3];
  {barnesForwardCarrierEqual[s, barnesForwardLogCarrierPlus[2 x], x > 0],
    s["Terms"], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"]/s["Prefactor"] ==
      -405607/(580608000 (2 x)^6), x > 0]]}],
  {True, {{0, 1}, {2, -1/960}, {4, 269/4300800}}, 6, True},
  TestID -> "barnes-g-affine-positive-argument-scales-every-correction"]

VerificationTest[Module[{x, s},
  (* The defining Weierstrass product gives the first two logarithmic
     Taylor coefficients at G(1)=1 without a large-argument expansion. *)
  s = AsymptoticExpansion[Log[BarnesG[1 + x]], {x, 0, 3}];
  {barnesForwardEqual[s, (Log[2 Pi] - 1) x/2 - (1 + EulerGamma) x^2/2, x > 0],
    s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == Pi^2 x^3/18, x > 0]]}],
  {True, 3, True},
  TestID -> "barnes-g-finite-positive-logarithm-keeps-ordinary-Taylor-semantics"]

VerificationTest[Module[{x},
  Quiet[{FailureQ[AsymptoticExpansion[BarnesG[-x], x -> Infinity, SeriesTermGoal -> 3]],
    FailureQ[AsymptoticExpansion[Log[-BarnesG[x]], x -> Infinity, SeriesTermGoal -> 3]],
    FailureQ[AsymptoticExpansion[BarnesG[x]^I, x -> Infinity, SeriesTermGoal -> 3]],
    FailureQ[AsymptoticExpansion[BarnesG[x]^2.5, x -> Infinity, SeriesTermGoal -> 3]],
    FailureQ[AsymptoticExpansion[ConditionalExpression[BarnesG[x], x < 0],
      x -> Infinity, SeriesTermGoal -> 3]]}]],
  {True, True, True, True, True},
  TestID -> "barnes-g-rejects-negative-tail-invalid-real-powers-and-incompatible-domain"]

VerificationTest[Module[{x},
  Quiet[{FailureQ[AsymptoticExpansion[BarnesG[x], x -> Infinity, SeriesTermGoal -> 0]],
    FailureQ[AsymptoticExpansion[BarnesG[x], x -> Infinity, SeriesTermGoal -> 5, "MaxTerms" -> 1]],
    FailureQ[AsymptoticExpansion[BarnesG[x], {x, Infinity, 3.5}]]}]],
  {True, True, True},
  TestID -> "barnes-g-validates-term-goal-resource-budget-and-exact-cutoff"]

VerificationTest[Module[{x, s, expected},
  s = AsymptoticExpansion[Log[BarnesG[x + 1]] - barnesForwardLogCarrierPlus[x],
    x -> Infinity, SeriesTermGoal -> 5];
  expected = -1/(240 x^2) + 1/(1008 x^4) - 1/(1440 x^6) +
    1/(1056 x^8) - 691/(327600 x^10);
  {barnesForwardEqual[s, expected, x > 0], s["Terms"][[All, 1]], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == 1/(144 x^12), x > 0]]}],
  {True, {2, 4, 6, 8, 10}, 12, True},
  TestID -> "barnes-g-log-carrier-cancellation-demands-additional-Bernoulli-orders"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[BarnesG[x + 3/2]/
      (BarnesG[x + 1/2] Gamma[x + 1/2]), x -> Infinity, SeriesTermGoal -> 5];
  {barnesForwardEqual[s, 1, x > 0], s["Remainder"], s["Exact"], Length[s["Terms"]]}],
  {True, 0, True, 1},
  TestID -> "barnes-g-half-integer-shift-recurrence-terminates-exactly"]

VerificationTest[Module[{x, b, s},
  s = AsymptoticExpansion[BarnesG[x + b + 1]/
      (BarnesG[x + b] Gamma[x + b]), x -> Infinity,
    Assumptions -> Element[b, Reals], SeriesTermGoal -> 5];
  {barnesForwardEqual[s, 1, x + b > 0 && Element[b, Reals]],
    s["Remainder"], s["Exact"], Length[s["Terms"]]}],
  {True, 0, True, 1},
  TestID -> "barnes-g-symbolic-real-shift-recurrence-terminates-exactly"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Log[BarnesG[3 - x]], {x, 0, 2}];
  {MatchQ[s, _GeneralizedSeries],
    TrueQ[(s["TargetDomain"] /. x -> 1) === False],
    TrueQ[s["TargetDomain"] /. x -> 1/2]}],
  {True, True, True},
  TestID -> "barnes-g-finite-shift-normalization-retains-positive-canonical-argument-domain"]

VerificationTest[Module[{x, rootArgument, squareArgument},
  rootArgument = AsymptoticExpansion[BarnesG[1 + Sqrt[x]],
    x -> Infinity, SeriesTermGoal -> 3];
  squareArgument = AsymptoticExpansion[BarnesG[1 + x^2],
    x -> Infinity, SeriesTermGoal -> 3];
  {barnesForwardCarrierEqual[rootArgument, barnesForwardLogCarrierPlus[Sqrt[x]], x > 0],
    rootArgument["Terms"], rootArgument["RemainderPower"],
    TrueQ[FullSimplify[rootArgument["FrontierTerm"]/rootArgument["Prefactor"] ==
      -405607/(580608000 x^3), x > 0]],
    barnesForwardCarrierEqual[squareArgument, barnesForwardLogCarrierPlus[x^2], x > 0],
    squareArgument["Terms"], squareArgument["RemainderPower"],
    TrueQ[FullSimplify[squareArgument["FrontierTerm"]/squareArgument["Prefactor"] ==
      -405607/(580608000 x^12), x > 0]]}],
  {True, {{0, 1}, {1, -1/240}, {2, 269/268800}}, 3, True,
    True, {{0, 1}, {4, -1/240}, {8, 269/268800}}, 12, True},
  TestID -> "barnes-g-power-compositions-scale-Bernoulli-working-order-and-frontier"]
