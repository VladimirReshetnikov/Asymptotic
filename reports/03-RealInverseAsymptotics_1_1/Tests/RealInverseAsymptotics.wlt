(* Tests for a genuine Wolfram Language kernel. This file was authored but
   not executed in the delivery environment; see Verification/results.txt. *)
Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],
  "Kernel", "RealInverseAsymptotics.wl"}]];
Clear[x, y, z, a, c, alpha];

VerificationTest[
 RealInverseExpansion[x + x^2 (1 + Log[x]), {x, y}, 3]["Blocks"],
 {{1, 1}, {2, -1 - LogCoordinate}}, TestID -> "log-first-correction"]

VerificationTest[
 RealInverseExpansion[x + x^2 (1 + Log[x]), {x, y}, 4]["Blocks"][[3]],
 {3, 3 + 5 LogCoordinate + 2 LogCoordinate^2}, TestID -> "log-second-correction"]

VerificationTest[
 RealInverseExpansion[x + x^2 (1 + Log[x]), {x, y}, 5]["Blocks"][[4]],
 {4, -23/2 - 27 LogCoordinate - 41/2 LogCoordinate^2 - 5 LogCoordinate^3},
 TestID -> "log-third-correction"]

VerificationTest[
 With[{r = RealInverseExpansion[x + x^2 (1 + Log[x]), {x, y}, 3]},
  {r["RemainderExponent"], r["RemainderLogDegree"]}],
 {3, 2}, TestID -> "log-remainder-is-not-bare-cubic"]

VerificationTest[
 FullSimplify[
  RealInverseExpansion[x + x^Sqrt[2], {x, z}, 4 Sqrt[2] - 3]["Expression"] -
   (z - z^Sqrt[2] + Sqrt[2] z^(2 Sqrt[2] - 1) -
    (6 - Sqrt[2])/2 z^(3 Sqrt[2] - 2)), Assumptions -> z > 0],
 0, TestID -> "irrational-question-four-terms"]

VerificationTest[
 With[{r = RealInverseExpansion[x + x^Sqrt[2], {x, z}, 4 Sqrt[2] - 3]},
  {Length[r["Blocks"]], FullSimplify[r["RemainderExponent"] - (4 Sqrt[2] - 3)],
   r["RemainderLogDegree"]}], {4, 0, 0}, TestID -> "irrational-exclusive-boundary"]

VerificationTest[
 RealInverseExpansion[x + x^2, {x, y}, 7]["Blocks"],
 {{1, 1}, {2, -1}, {3, 2}, {4, -5}, {5, 14}, {6, -42}},
 TestID -> "catalan-exact-algebraic-case"]

VerificationTest[
 RealInverseExpansion[x + 2 x^(3/2) - 3 x^2, {x, y}, 5/2]["Blocks"],
 {{1, 1}, {3/2, -2}, {2, 9}}, TestID -> "resonant-exponents-aggregate"]

VerificationTest[
 RealInverseExpansion[x^2 + x^3, {x, y}, 3]["Blocks"],
 {{1/2, 1}, {1, -1/2}, {3/2, 5/8}, {2, -1}, {5/2, 231/128}},
 TestID -> "nonlinear-dominant-core"]

VerificationTest[
 RealInverseExpansion[3 x^2, {x, y}, 2]["Exact"], True,
 TestID -> "pure-monomial-exact"]

VerificationTest[
 FullSimplify[RealInverseExpansion[a x + x^2, {x, y}, 3,
   Assumptions -> a > 0]["Expression"] - (y/a - y^2/a^3),
  Assumptions -> a > 0 && y > 0], 0, TestID -> "symbolic-positive-slope"]

VerificationTest[
 RealInverseExpansion[x + c x^2, {x, y}, 4,
  Assumptions -> Element[c, Reals]]["Blocks"],
 {{1, 1}, {2, -c}, {3, 2 c^2}}, TestID -> "symbolic-real-coefficient"]

VerificationTest[
 InverseResidual[RealInverseExpansion[x + x^2 (1 + Log[x]), {x, y}, 7]]["VanishingBelowCutoff"],
 True, TestID -> "residual-log"]

VerificationTest[
 InverseResidual[RealInverseExpansion[x + x^Sqrt[2], {x, y}, 3]]["VanishingBelowCutoff"],
 True, TestID -> "residual-irrational"]

VerificationTest[
 InverseResidual[RealInverseExpansion[x + 2 x^Sqrt[2] + x^(3/2) (1 + Log[x]),
  {x, y}, 3]]["VanishingBelowCutoff"], True, TestID -> "residual-mixed"]

VerificationTest[
 InverseResidual[RealInverseExpansion[x^2 + x^3, {x, y}, 3]]["Cutoff"],
 7/2, TestID -> "residual-cutoff-transport"]

VerificationTest[
 InverseResidual[RealInverseExpansion[x^2 + x^3, {x, y}, 3]]["VanishingBelowCutoff"],
 True, TestID -> "residual-power-core"]

VerificationTest[
 InverseResidual[RealInverseExpansion[3 x^(3/2) + x^(5/2) (1 + 2 Log[x]),
  {x, y}, 3]]["VanishingBelowCutoff"], True, TestID -> "residual-scaled-log-core"]

VerificationTest[
 InverseResidual[RealInverseExpansion[5 x^(2/3), {x, y}, 4]]["VanishingBelowCutoff"],
 True, TestID -> "residual-pure-core"]

VerificationTest[
 Module[{r = RealInverseExpansion[x + x^2, {x, y}, 4]},
  r = Join[r, <|"Blocks" -> {{1, 1}, {2, 0}, {3, 2}}|>];
  InverseResidual[r]["VanishingBelowCutoff"]],
 False, TestID -> "residual-detects-corruption"]

VerificationTest[
 Expand[LagrangeInverseTruncation[x^2 (1 + Log[x]), {x, y}, 2] -
  (y - y^2 (1 + Log[y]) + y^3 (3 + 5 Log[y] + 2 Log[y]^2))],
 0, TestID -> "derivative-helper-log"]

VerificationTest[
 FullSimplify[LagrangeInverseTruncation[x^2, {x, y}, 2, "OutputPower" -> 1/2] -
   (y^(1/2) - y^(3/2)/2 + 7 y^(5/2)/8), Assumptions -> y > 0],
 0, TestID -> "observable-power-helper"]

VerificationTest[
 LagrangeInverseTruncation[x^2, {x, y}, 0], y,
 TestID -> "zero-correction-order"]

VerificationTest[
 MatchQ[RealInverseExpansion[x Log[x], {x, y}, 3], _Failure],
 True, TestID -> "reject-logarithmic-leading-core"]

VerificationTest[
 MatchQ[RealInverseExpansion[-x + x^2, {x, y}, 3], _Failure],
 True, TestID -> "reject-negative-leading-coefficient"]

VerificationTest[
 MatchQ[RealInverseExpansion[x + 0.5 x^2, {x, y}, 3], _Failure],
 True, TestID -> "reject-inexact-coefficient"]

VerificationTest[
 MatchQ[RealInverseExpansion[x + x^alpha, {x, y}, 3, Assumptions -> alpha > 1], _Failure],
 True, TestID -> "reject-unordered-symbolic-exponent"]

VerificationTest[
 MatchQ[RealInverseExpansion[x + x^2/Log[x], {x, y}, 3], _Failure],
 True, TestID -> "reject-inverse-logarithms"]

VerificationTest[
 MatchQ[RealInverseExpansion[x + Sin[x], {x, y}, 3], _Failure],
 True, TestID -> "reject-unexpanded-elementary-function"]

VerificationTest[
 MatchQ[RealInverseExpansion[x + x^2, {x, x}, 3], _Failure],
 True, TestID -> "reject-identical-variables"]

VerificationTest[
 MatchQ[RealInverseExpansion[x + x^2, {x, y}, 1], _Failure],
 True, TestID -> "reject-cutoff-at-leading-power"]

VerificationTest[
 MatchQ[RealInverseExpansion[x + x^2 + x^3, {x, y}, 10,
  "MaxMultiIndices" -> 2], _Failure], True, TestID -> "enumeration-resource-limit"]

VerificationTest[
 MatchQ[RealInverseExpansion[x + x^(101/100), {x, y}, 3,
  "MaxTotalOrder" -> 10], _Failure], True, TestID -> "perturbation-resource-limit"]

VerificationTest[
 Module[{r = RealInverseExpansion[x + x^Sqrt[2], {x, y}, 3], approximation, root},
  approximation = N[r["Expression"] /. y -> 10^-8, 70];
  root = x /. FindRoot[x + x^Sqrt[2] == 10^-8,
     {x, N[10^-8, 80]}, WorkingPrecision -> 80];
  Abs[(approximation - root)/root] < 10^-14],
 True, TestID -> "numeric-irrational-80-digits"]
