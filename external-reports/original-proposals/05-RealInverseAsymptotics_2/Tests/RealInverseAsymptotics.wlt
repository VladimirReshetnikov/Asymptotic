Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],
 "Kernel", "RealInverseAsymptotics.wl"}]];
Clear[x, y, L, a, c, eps, z1, z2];

VerificationTest[
 Expand[RealInverseAsymptotic[x + x^2 (1 + Log[x]), {x, 0}, {y, 0, 2}]["Expression"] -
  (y - y^2 (1 + Log[y]))],
 0, TestID -> "log-two-powers"]

VerificationTest[
 Expand[RealInverseAsymptotic[x + x^2 (1 + Log[x]), {x, 0}, {y, 0, 3}]["Expression"]],
 Expand[y - (1 + Log[y]) y^2 + (2 Log[y]^2 + 5 Log[y] + 3) y^3],
 TestID -> "log-third-block"]

VerificationTest[
 PowerLogInverseCoefficient[1, {{1, 1 + L}}, L, {3}],
 -5 L^3 - 41 L^2/2 - 27 L - 23/2, TestID -> "log-fourth-block"]

VerificationTest[
 PowerLogInverseCoefficient[1, {{1, 1 + L}}, L, {4}],
 14 L^4 + 241 L^3/3 + 335 L^2/2 + 151 L + 299/6,
 TestID -> "log-fifth-block"]

VerificationTest[
 With[{r = RealInverseAsymptotic[x + x^2 (1 + Log[x]), {x, 0}, {y, 0, 2}]},
  {r["FirstOmittedPower"], r["RemainderLogDegree"], r["RemainderScale"]}],
 {3, 2, y^3 (1 + Abs[Log[y]])^2}, TestID -> "log-remainder-is-not-bare-y-cubed"]

VerificationTest[
 FullSimplify[RealInverseAsymptotic[x + x^Sqrt[2], {x, 0},
   {y, 0, 3 Sqrt[2] - 2}]["Expression"] -
   (y - y^Sqrt[2] + Sqrt[2] y^(2 Sqrt[2] - 1) -
     (6 - Sqrt[2])/2 y^(3 Sqrt[2] - 2)), y > 0],
 0, TestID -> "question-irrational-four-terms"]

VerificationTest[
 RealInverseAsymptotic[x + x^Sqrt[2], {x, 0},
  {y, 0, 3 Sqrt[2] - 2}]["NumberOfMultiIndices"],
 4, TestID -> "exact-irrational-cutoff-includes-boundary"]

VerificationTest[
 FullSimplify[RealInverseAsymptotic[x + x^Sqrt[2], {x, 0},
   {y, 0, 3 Sqrt[2] - 2}]["FirstOmittedPower"] - (4 Sqrt[2] - 3)],
 0, TestID -> "exact-irrational-next-exponent"]

VerificationTest[
 Table[PowerLogInverseCoefficient[1, {{1, 1}}, L, {n}], {n, 0, 10}],
 Table[(-1)^n CatalanNumber[n], {n, 0, 10}], TestID -> "Catalan-cross-check"]

VerificationTest[
 Table[PowerLogInverseCoefficient[1, {{2/5, 1}}, L, {n}], {n, 1, 5}],
 {-1, 7/5, -56/25, 483/125, -7}, TestID -> "rational-noninteger-power"]

VerificationTest[
 Table[PowerLogInverseCoefficient[2, {{1, 1}}, L, {n}], {n, 0, 3}],
 {1, -1/2, 5/8, -1}, TestID -> "nonunit-leading-power"]

VerificationTest[
 FullSimplify[RealInverseAsymptotic[3 x^2 (1 + x), {x, 0}, {y, 0, 2}]["Expression"] -
  (Sqrt[y/3] - y/6 + 5/8 (y/3)^(3/2) - (y/3)^2), y > 0],
 0, TestID -> "leading-coefficient-and-y-order"]

VerificationTest[
 InversePowerLogModel[1, 1, {{1, 1}, {2, 2}}, L, {y, 0, 2}]["FirstOmittedCoefficient"],
 0, TestID -> "all-resonant-frontier-representations"]

VerificationTest[
 InversePowerLogModel[1, 1, {{Sqrt[2] - 1, 1}, {Sqrt[2] - 1, -1}},
  L, {y, 0, 3}]["RemainderScale"],
 0, TestID -> "cancelled-generators-give-exact-identity"]

VerificationTest[
 RealInverseAsymptotic[2 x^3, {x, 0}, {y, 0, 1}]["Expression"],
 (y/2)^(1/3), TestID -> "pure-leading-monomial"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x + x^1.4, {x, 0}, {y, 0, 2}], _Failure],
 True, TestID -> "reject-inexact-exponent"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x + 0.5 x^2, {x, 0}, {y, 0, 2}], _Failure],
 True, TestID -> "reject-inexact-coefficient"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[-x + x^2, {x, 0}, {y, 0, 2}], _Failure],
 True, TestID -> "reject-negative-leading-coefficient"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x Log[x], {x, 0}, {y, 0, 2}], _Failure],
 True, TestID -> "reject-leading-log"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x + Exp[-1/x], {x, 0}, {y, 0, 2}], _Failure],
 True, TestID -> "finite-model-parser-rejects-flat-input"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x + x^2 Log[Log[1/x]], {x, 0}, {y, 0, 2}], _Failure],
 True, TestID -> "reject-loglog-coefficient"]

VerificationTest[
 MatchQ[InversePowerLogModel[1, 1, {{0, 1}}, L, {y, 0, 2}], _Failure],
 True, TestID -> "reject-zero-weight-generator"]

VerificationTest[
 MatchQ[InversePowerLogModel[1, 1, {{1/1000, 1}}, L, {y, 0, 2},
   "MaxMultiIndices" -> 10], _Failure],
 True, TestID -> "resource-limit-not-partial-result"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[Sqrt[x], {x, 0}, {y, 0, 1}], _Failure],
 True, TestID -> "reject-cutoff-below-leading-inverse"]

VerificationTest[
 MatchQ[InversePowerLogModel[1, 1, {{1, a}}, L, {y, 0, 2}], _Failure],
 True, TestID -> "symbolic-realness-not-guessed"]

VerificationTest[
 Expand[InversePowerLogModel[c, 1, {{1, a + L}}, L, {y, 0, 2},
  Assumptions -> c > 0 && Element[a, Reals]]["Expression"]],
 Expand[y/c - (y/c)^2 (a + Log[y] - Log[c])],
 TestID -> "symbolic-coefficients-with-assumptions"]

VerificationTest[
 Module[{u = 1 + Sum[PowerLogInverseCoefficient[1, {{1, 1 + L}}, L, {n}] eps^n,
     {n, 1, 5}]},
  Expand[Normal[Series[u (1 + eps u (1 + L + Log[u])) - 1, {eps, 0, 5}]]]],
 0, TestID -> "independent-epsilon-residual-log"]

VerificationTest[
 Module[{u = 1 + Sum[PowerLogInverseCoefficient[1, {{Sqrt[2] - 1, 1}}, L, {n}] eps^n,
     {n, 1, 5}]},
  FullSimplify[Normal[Series[u + eps u^Sqrt[2] - 1, {eps, 0, 5}]]]],
 0, TestID -> "independent-epsilon-residual-irrational"]

VerificationTest[
 Expand[LagrangeInverseBlocks[x^2 (1 + Log[x]), {x, 0}, {y, 0}, 3]["Expression"] -
  RealInverseAsymptotic[x + x^2 (1 + Log[x]), {x, 0}, {y, 0, 4}]["Expression"]],
 0, TestID -> "general-block-engine-agrees-with-weighted-engine"]

VerificationTest[
 LagrangeInverseBlocks[x^2 Sin[Log[x]], {x, 0}, {y, 0}, 3,
  "DerivativeScale" -> {1, 0}]["RemainderScale"],
 y^5, TestID -> "nonpolynomial-log-conditional-scale"]

VerificationTest[
 FullSimplify[LagrangeInverseBlocks[Exp[-1/x], {x, 0}, {y, 0}, 2]["Expression"] -
  (y - Exp[-1/y] + Exp[-2/y]/y^2), y > 0],
 0, TestID -> "flat-exponential-blocks"]

VerificationTest[
 MatchQ[InversePowerLogJet[1, 1, {{1, 1}}, L, {y, 0, 3}, {2, 0}], _Failure],
 True, TestID -> "jet-does-not-invent-unknown-boundary-coefficient"]

VerificationTest[
 TrueQ[InversePowerLogJet[1, 1, {{1, 1}}, L, {y, 0, 2}, {3, 0}]["SourceIsJet"]],
 True, TestID -> "jet-is-explicitly-conditional"]

VerificationTest[
 MatchQ[InverseResidual[InversePowerLogJet[1, 1, {{1, 1}}, L,
  {y, 0, 2}, {3, 0}]], _Failure],
 True, TestID -> "jet-model-residual-not-mislabelled"]

VerificationTest[
 MatchQ[EvaluateInverseAsymptotic[RealInverseAsymptotic[x + x^2, {x, 0},
  {y, 0, 3}], 0.001, WorkingPrecision -> 50], _Failure],
 True, TestID -> "no-fabricated-precision"]

VerificationTest[
 ResidualErrorBound[x + x^2, {x, 0, 1}, y, y - y^2, 1]["VerificationStatus"],
 "Conditional: hypotheses have not been automatically proved",
 TestID -> "conditional-bound-not-claimed-certified"]

VerificationTest[
 MatchQ[ResidualErrorBound[x + x^2, {x, 1/100, 1}, y, y - y^2, 0], _Failure],
 True, TestID -> "reject-zero-derivative-lower-bound"]

VerificationTest[
 MatchQ[ResidualErrorBound[x + x^2, {x, 1/100, 1}, y, y - y^2, 1 + x], _Failure],
 True, TestID -> "reject-variable-dependent-derivative-bound"]
