(* Focused special-function ingress regressions.
   Coefficients below come from defining series, differential equations,
   integration by parts, and standard connection formulas. The native Series
   implementation used by the ingress is not used as the expected-value oracle.
   Numerical checks are evidence at selected points, not certifications.
   Load the package before evaluating this file, as in the focused runners. *)

specialForwardEqual[s_, expected_, ass_: True] :=
  MatchQ[s, _GeneralizedSeries] &&
    TrueQ[FullSimplify[Normal[s] == expected, ass]];

specialForwardBound[s_GeneralizedSeries] := s["Remainder"] /.
  PowerLogRemainder[w_, p_, d_] :> w^p (1 + Abs[Log[w]])^d;

specialForwardNonzeroError[s_] :=
  MatchQ[s, _GeneralizedSeries] && ! TrueQ[s["Remainder"] === 0];

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[BesselJ[0, x], x -> 0, SeriesTermGoal -> 5];
  {specialForwardEqual[s, 1 - x^2/4 + x^4/64 - x^6/2304 + x^8/147456, x > 0],
    s["RemainderPower"], s["RemainderLogDegree"]}],
  {True, 10, 0}, TestID -> "special-forward-bessel-j-zero-sparse-defining-series"]

VerificationTest[Module[{x, nu = Sqrt[2], s, expected},
  s = AsymptoticExpansion[BesselJ[nu, x], x -> 0, SeriesTermGoal -> 3];
  expected = (x/2)^nu/Gamma[1 + nu]
    (1 - x^2/(4 (1 + nu)) + x^4/(32 (1 + nu) (2 + nu)));
  specialForwardEqual[s, expected, x > 0] && specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-bessel-j-irrational-leading-prefactor"]

VerificationTest[Module[{x, s, ell},
  ell = EulerGamma + Log[x/2];
  s = AsymptoticExpansion[BesselK[0, x], x -> 0, SeriesTermGoal -> 3];
  {specialForwardEqual[s, -ell (1 + x^2/4 + x^4/64) + x^2/4 + 3 x^4/128, x > 0],
    s["RemainderPower"], s["RemainderLogDegree"]}],
  {True, 6, 1}, TestID -> "special-forward-bessel-k-logarithmic-singularity"]

VerificationTest[Module[{x, a, b},
  a = AsymptoticExpansion[AiryAi[x], {x, 0, 5}];
  b = AsymptoticExpansion[AiryBi[x], {x, 0, 5}];
  (* y''=x y fixes a2=0, a3=a0/6, a4=a1/12. *)
  {specialForwardEqual[a, AiryAi[0] (1 + x^3/6) + AiryAiPrime[0] (x + x^4/12), x > 0],
   specialForwardEqual[b, AiryBi[0] (1 + x^3/6) + AiryBiPrime[0] (x + x^4/12), x > 0]}],
  {True, True}, TestID -> "special-forward-airy-finite-ode-coefficients"]

VerificationTest[Module[{x, f, g, d},
  f = AsymptoticExpansion[Erf[x], {x, 0, 7}];
  g = AsymptoticExpansion[Erfi[x], {x, 0, 7}];
  d = AsymptoticExpansion[DawsonF[x], {x, 0, 7}];
  {specialForwardEqual[f, 2/Sqrt[Pi] (x - x^3/3 + x^5/10), x > 0],
   specialForwardEqual[g, 2/Sqrt[Pi] (x + x^3/3 + x^5/10), x > 0],
   specialForwardEqual[d, x - 2 x^3/3 + 4 x^5/15, x > 0]}],
  {True, True, True}, TestID -> "special-forward-error-functions-regular-origin"]

VerificationTest[Module[{x, ei, e1},
  ei = AsymptoticExpansion[ExpIntegralEi[x], {x, 0, 4}];
  e1 = AsymptoticExpansion[ExpIntegralE[1, x], {x, 0, 4}];
  {specialForwardEqual[ei, EulerGamma + Log[x] + x + x^2/4 + x^3/18, x > 0],
   specialForwardEqual[e1, -EulerGamma - Log[x] + x - x^2/4 + x^3/18, x > 0]}],
  {True, True}, TestID -> "special-forward-exponential-integral-logarithmic-origin"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[3/2, 0, x], x -> 0, SeriesTermGoal -> 3];
  specialForwardEqual[s, 2 x^(3/2)/3 - 2 x^(5/2)/5 + x^(7/2)/7, x > 0] &&
    specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-lower-incomplete-gamma-puiseux-origin"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Zeta[1 + x], {x, 0, 3}];
  specialForwardEqual[s, 1/x + EulerGamma - StieltjesGamma[1] x + StieltjesGamma[2] x^2/2,
    x > 0] && specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-zeta-pole-independent-stieltjes-coefficients"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[PolyLog[2, x], {x, 0, 5}];
  {specialForwardEqual[s, x + x^2/4 + x^3/9 + x^4/16, 0 < x < 1],
    s["RemainderPower"]}],
  {True, 5}, TestID -> "special-forward-polylog-defining-series"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[PolyLog[2, 1 - x], {x, 0, 4}];
  specialForwardEqual[s, Pi^2/6 + x (Log[x] - 1) + x^2 (Log[x]/2 - 1/4) +
    x^3 (Log[x]/3 - 1/9), 0 < x < 1] && specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-dilogarithm-logarithmic-endpoint"]

VerificationTest[Module[{x, f, g, expected},
  f = AsymptoticExpansion[Hypergeometric0F1[3/2, x], {x, 0, 4}];
  g = AsymptoticExpansion[Hypergeometric2F1[1/3, 2/3, 5/4, x], {x, 0, 4}];
  expected = Sum[Pochhammer[1/3, k] Pochhammer[2/3, k]/
    (Pochhammer[5/4, k] k!) x^k, {k, 0, 3}];
  {specialForwardEqual[f, 1 + 2 x/3 + 2 x^2/15 + 4 x^3/315, 0 < x < 1],
    specialForwardEqual[g, expected, 0 < x < 1]}],
  {True, True}, TestID -> "special-forward-hypergeometric-fixed-parameter-series"]

VerificationTest[Module[{x, k, e},
  k = AsymptoticExpansion[EllipticK[x], {x, 0, 4}];
  e = AsymptoticExpansion[EllipticE[x], {x, 0, 4}];
  (* Wolfram uses parameter m, not the DLMF modulus k: m=k^2. *)
  {specialForwardEqual[k, Pi/2 (1 + x/4 + 9 x^2/64 + 25 x^3/256), 0 < x < 1],
   specialForwardEqual[e, Pi/2 (1 - x/4 - 3 x^2/64 - 5 x^3/256), 0 < x < 1]}],
  {True, True}, TestID -> "special-forward-complete-elliptic-parameter-convention"]

VerificationTest[Module[{x, s, ell},
  ell = Log[4] - Log[x]/2;
  s = AsymptoticExpansion[EllipticK[1 - x], x -> 0, SeriesTermGoal -> 3];
  specialForwardEqual[s, ell + x (ell - 1)/4 + 9 x^2 (ell - 7/6)/64, 0 < x < 1] &&
    specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-elliptic-logarithmic-threshold"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[BesselI[0, x], x -> Infinity, SeriesTermGoal -> 3];
  specialForwardEqual[s, Exp[x]/Sqrt[2 Pi x] (1 + 1/(8 x) + 9/(128 x^2)), x > 0] &&
    specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-bessel-i-positive-tail"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[BesselK[0, x], x -> Infinity, SeriesTermGoal -> 3];
  specialForwardEqual[s, Sqrt[Pi/(2 x)] Exp[-x] (1 - 1/(8 x) + 9/(128 x^2)), x > 0] &&
    specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-bessel-k-positive-tail"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[AiryAi[x], x -> Infinity, SeriesTermGoal -> 3];
  specialForwardEqual[s, Exp[-2 x^(3/2)/3]/(2 Sqrt[Pi] x^(1/4))
    (1 - 5/(48 x^(3/2)) + 385/(4608 x^3)), x > 0] && specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-airy-ai-fractional-gap-decaying-tail"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[AiryBi[x], x -> Infinity, SeriesTermGoal -> 3];
  specialForwardEqual[s, Exp[2 x^(3/2)/3]/(Sqrt[Pi] x^(1/4))
    (1 + 5/(48 x^(3/2)) + 385/(4608 x^3)), x > 0] && specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-airy-bi-fractional-gap-growing-tail"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Erfc[x], x -> Infinity, SeriesTermGoal -> 3];
  specialForwardEqual[s, Exp[-x^2]/(Sqrt[Pi] x) (1 - 1/(2 x^2) + 3/(4 x^4)), x > 0] &&
    specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-erfc-independent-tail-coefficients"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Erf[x], x -> Infinity, SeriesTermGoal -> 3];
  MatchQ[s, _GeneralizedSeries] && FreeQ[Normal[s], _Erf | _Erfc] &&
    !(TrueQ[Normal[s] === 1] && TrueQ[s["Remainder"] === 0])],
  True, TestID -> "special-forward-erf-flat-tail-is-not-exact-limiting-constant"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Erfi[x], x -> Infinity, SeriesTermGoal -> 3];
  specialForwardEqual[s, Exp[x^2]/(Sqrt[Pi] x) (1 + 1/(2 x^2) + 3/(4 x^4)), x > 0] &&
    specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-erfi-growing-tail"]

VerificationTest[Module[{x, ei, e2},
  ei = AsymptoticExpansion[ExpIntegralEi[x], x -> Infinity, SeriesTermGoal -> 3];
  e2 = AsymptoticExpansion[ExpIntegralE[2, x], x -> Infinity, SeriesTermGoal -> 3];
  {specialForwardEqual[ei, Exp[x]/x (1 + 1/x + 2/x^2), x > 0],
   specialForwardEqual[e2, Exp[-x]/x (1 - 2/x + 6/x^2), x > 0]}],
  {True, True}, TestID -> "special-forward-exponential-integral-opposite-tails"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Gamma[3/2, x], x -> Infinity, SeriesTermGoal -> 3];
  specialForwardEqual[s, Exp[-x] Sqrt[x] (1 + 1/(2 x) - 1/(4 x^2)), x > 0] &&
    specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-upper-incomplete-gamma-fixed-shape-tail"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Zeta[2, x], x -> Infinity, SeriesTermGoal -> 5];
  specialForwardEqual[s, 1/x + 1/(2 x^2) + 1/(6 x^3) - 1/(30 x^5) + 1/(42 x^7), x > 0] &&
    specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-hurwitz-zeta-euler-maclaurin-tail"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[PolyLog[2, -x], x -> Infinity, SeriesTermGoal -> 3];
  specialForwardEqual[s, -Log[x]^2/2 - Pi^2/6 + 1/x - 1/(4 x^2), x > 1] &&
    specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-dilogarithm-negative-large-argument-real-branch"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[HypergeometricU[3/2, 1/2, x], x -> Infinity, SeriesTermGoal -> 3];
  specialForwardEqual[s, x^(-3/2) (1 - 3/x + 45/(4 x^2)), x > 0] &&
    specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-hypergeometric-u-algebraic-tail"]

VerificationTest[Module[{x, k, i},
  k = AsymptoticExpansion[BesselK[1/2, x], x -> Infinity, SeriesTermGoal -> 3];
  i = AsymptoticExpansion[BesselI[1/2, x], x -> Infinity, SeriesTermGoal -> 3];
  {specialForwardEqual[k, Sqrt[Pi/(2 x)] Exp[-x], x > 0] && k["Remainder"] === 0,
   MatchQ[i, _GeneralizedSeries] &&
     (specialForwardNonzeroError[i] || specialForwardEqual[i, Sqrt[2/(Pi x)] Sinh[x], x > 0])}],
  {True, True}, TestID -> "special-forward-half-integer-exact-versus-subdominant-exponential"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[BesselI[0, x] BesselK[0, x], x -> Infinity, SeriesTermGoal -> 3];
  specialForwardEqual[s, (1 + 1/(8 x^2) + 27/(128 x^4))/(2 x), x > 0] &&
    specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-bessel-product-cancels-exponential-carriers"]

VerificationTest[Module[{x, scale, shift},
  scale = AsymptoticExpansion[Erfc[2 x], x -> Infinity, SeriesTermGoal -> 3];
  shift = AsymptoticExpansion[AiryAi[1 + x], {x, 0, 3}];
  {specialForwardEqual[scale, Exp[-4 x^2]/(2 Sqrt[Pi] x)
      (1 - 1/(8 x^2) + 3/(64 x^4)), x > 0],
   specialForwardEqual[shift, AiryAi[1] (1 + x^2/2) + AiryAiPrime[1] x, x > 0]}],
  {True, True}, TestID -> "special-forward-positive-scaling-and-finite-translation"]

VerificationTest[Module[{x}, Quiet[
  {FailureQ[AsymptoticExpansion[BesselJ[Sqrt[2], -x], x -> 0, SeriesTermGoal -> 3]],
   FailureQ[AsymptoticExpansion[EllipticK[1 + x], x -> 0, SeriesTermGoal -> 3]],
   FailureQ[AsymptoticExpansion[BesselK[0, -x], x -> Infinity, SeriesTermGoal -> 3]]}]],
  {True, True, True}, TestID -> "special-forward-principal-complex-branches-not-declared-real"]

VerificationTest[Module[{x, s, refined, sum},
  s = AsymptoticExpansion[BesselJ[0, x], {x, 0, 4}];
  refined = SeriesRefine[s, 8]; sum = s + s;
  {specialForwardEqual[refined, 1 - x^2/4 + x^4/64 - x^6/2304, x > 0],
   specialForwardEqual[sum, 2 - x^2/2, x > 0] && specialForwardNonzeroError[sum]}],
  {True, True}, TestID -> "special-forward-source-refinement-and-ordinary-arithmetic"]

VerificationTest[Module[{x, y, e, j, p},
  e = AsymptoticInverse[Erf[x], {x, 0}, y, SeriesTermGoal -> 3];
  j = AsymptoticInverse[BesselJ[1, x], {x, 0}, y, SeriesTermGoal -> 3];
  p = AsymptoticInverse[PolyLog[2, x], {x, 0}, {y, 4}];
  {specialForwardEqual[e, Sqrt[Pi] y/2 + Pi^(3/2) y^3/24 + 7 Pi^(5/2) y^5/960, y > 0],
   specialForwardEqual[j, 2 y + y^3 + 4 y^5/3, y > 0],
   specialForwardEqual[p, y - y^2/4 + y^3/72, y > 0]}],
  {True, True, True}, TestID -> "special-forward-reused-by-local-special-function-inverses"]

VerificationTest[Module[{x, s, ratios, boundRatios, normalized},
  s = AsymptoticExpansion[BesselK[0, x], x -> Infinity, SeriesTermGoal -> 3];
  If[! MatchQ[s, _GeneralizedSeries], Return[False, Module]];
  normalized = Exp[x] Sqrt[2 x/Pi] BesselK[0, x];
  ratios = Table[N[Abs[normalized - (1 - 1/(8 x) + 9/(128 x^2))]/
      (225/(3072 x^3)) /. x -> a, 70], {a, {10, 20, 40}}];
  boundRatios = Table[N[Abs[BesselK[0, x] - Normal[s]]/specialForwardBound[s] /. x -> a, 70],
    {a, {10, 20, 40}}];
  And @@ (TrueQ[0 < # < 1] & /@ ratios) &&
    And @@ (TrueQ[0 <= # < 10] & /@ boundRatios)],
  True, TestID -> "special-forward-bessel-tail-numerical-evidence-not-certificate"]

VerificationTest[Module[{x, s, theta, expected, ratios},
  theta = x - Pi/4;
  expected = Sqrt[2/(Pi x)] (Cos[theta] + Sin[theta]/(8 x) - 9 Cos[theta]/(128 x^2));
  s = AsymptoticExpansion[BesselJ[0, x], x -> Infinity, SeriesTermGoal -> 3];
  If[! specialForwardEqual[s, expected, x > 0], Return[False, Module]];
  ratios = Table[N[Abs[BesselJ[0, x] - Normal[s]]/specialForwardBound[s] /. x -> a, 60],
    {a, {20, 40, 80}}];
  specialForwardNonzeroError[s] && And @@ (TrueQ[0 <= # < 10] & /@ ratios)],
  True, TestID -> "special-forward-bessel-j-oscillatory-absolute-error"]

VerificationTest[Module[{x, s, theta, expected},
  theta = 2 x^(3/2)/3 + Pi/4;
  expected = (Sin[theta] - 5 Cos[theta]/(48 x^(3/2)) -
    385 Sin[theta]/(4608 x^3))/(Sqrt[Pi] x^(1/4));
  s = AsymptoticExpansion[AiryAi[-x], x -> Infinity, SeriesTermGoal -> 3];
  specialForwardEqual[s, expected, x > 0] && specialForwardNonzeroError[s]],
  True, TestID -> "special-forward-airy-negative-oscillatory-tail"]

VerificationTest[Module[{x, fc, fs, si, ci, theta},
  theta = Pi x^2/2;
  fc = AsymptoticExpansion[FresnelC[x], x -> Infinity, SeriesTermGoal -> 3];
  fs = AsymptoticExpansion[FresnelS[x], x -> Infinity, SeriesTermGoal -> 3];
  si = AsymptoticExpansion[SinIntegral[x], x -> Infinity, SeriesTermGoal -> 3];
  ci = AsymptoticExpansion[CosIntegral[x], x -> Infinity, SeriesTermGoal -> 3];
  {specialForwardEqual[fc, 1/2 + Sin[theta]/(Pi x) - Cos[theta]/(Pi^2 x^3), x > 0],
   specialForwardEqual[fs, 1/2 - Cos[theta]/(Pi x) - Sin[theta]/(Pi^2 x^3), x > 0],
   specialForwardEqual[si, Pi/2 - Cos[x]/x - Sin[x]/x^2, x > 0],
   specialForwardEqual[ci, Sin[x]/x - Cos[x]/x^2 - 2 Sin[x]/x^3, x > 0]}],
  {True, True, True, True}, TestID -> "special-forward-fresnel-and-trigonometric-integral-tails"]
