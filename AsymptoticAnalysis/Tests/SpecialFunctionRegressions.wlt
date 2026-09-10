(* Exact threshold oracles and original-function checks of finite Poincare models. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];
If[DownValues[AsymptoticAnalysis`AsymptoticCoreInverse] === {},
  Begin["AsymptoticAnalysis`Private`"];
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "CorePerturbation.wl"}]];
  End[]];
If[DownValues[AsymptoticAnalysis`AsymptoticSpecialInverse] === {},
  Begin["AsymptoticAnalysis`Private`"];
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "SpecialFunctionAdapters.wl"}]];
  End[]];

VerificationTest[
  Module[{x, y, s, v, expected},
    s = AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 2}];
    v = -Log[Sqrt[Pi] y];
    expected = Sqrt[v] - Log[v]/(4 Sqrt[v]) + (-Log[v]^2 + 4 Log[v] - 8)/(32 v^(3/2));
    {TrueQ[FullSimplify[Normal[s] == expected, 0 < y < Exp[-2]/Sqrt[Pi]]],
     s["ExactModel"], s["ForwardRemainderContract"][["ConvergentForwardSeries"]]}],
  {True, False, False}, TestID -> "special-erfc-independent-three-term-inverse"]

VerificationTest[
  Module[{x, y, s, ratios},
    s = AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 2}, "ModelTerms" -> 3];
    ratios = Table[N[Abs[Erfc[x] - s["ForwardModel"]]/s["ForwardRemainderBound"] /. x -> a, 70], {a, {1, 2, 5, 10}}];
    And @@ (TrueQ[0 < # < 1] & /@ ratios)],
  True, TestID -> "special-erfc-first-neglected-term-forward-bounds"]

VerificationTest[
  Module[{x, y, s, normalized, derivativeError, bound},
    s = AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 2}, "ModelTerms" -> 3];
    normalized = Sqrt[Pi] x Exp[x^2] Erfc[x];
    derivativeError = Abs[D[normalized - s["NormalizedTailPolynomial"], x]];
    bound = s["NormalizedTailDerivativeRemainderBound"];
    And @@ (TrueQ[N[(derivativeError/bound) /. x -> #, 70] < 1] & /@ {2, 5, 10})],
  True, TestID -> "special-erfc-matching-derivative-remainder-bound"]

VerificationTest[
  Module[{x, y, s, check},
    s = AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 3}];
    check = SpecialInverseNumericalCheck[s, Erfc[10], WorkingPrecision -> 60];
    {TrueQ[Abs[check[["ReferenceRoot"]] - 10] < 10^-55], TrueQ[check[["Error"]] > 0], check[["Certified"]]}],
  {True, True, False}, TestID -> "special-erfc-original-equation-numerical-reference"]

VerificationTest[
  Module[{x, y, low, high, a, b},
    low = AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 2}];
    high = AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 3}];
    a = N[Abs[(Normal[low] /. y -> Erfc[10]) - 10], 70];
    b = N[Abs[(Normal[high] /. y -> Erfc[10]) - 10], 70];
    TrueQ[0 < b < a]],
  True, TestID -> "special-erfc-neighboring-model-order-overlap"]

VerificationTest[
  Module[{x, y, s, check},
    s = AsymptoticSpecialInverse["Erfc", {x, -Infinity}, {y, 2}, "TargetOffset" -> 7, "TargetScale" -> -2];
    check = SpecialInverseNumericalCheck[s, 7 - 2 Erfc[-8], WorkingPrecision -> 50];
    {s["Limit"], TrueQ[Abs[check[["ReferenceRoot"]] + 8] < 10^-45], s["Direction"]}],
  {3, True, "FromAbove"}, TestID -> "special-erfc-reflected-signed-offset-tail"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 3}, "ModelTerms" -> 1], Failure["InsufficientModelOrder", _]]],
  True, TestID -> "special-erfc-insufficient-forward-model-rejected"]

VerificationTest[
  Module[{x, y, s, phi},
    s = AsymptoticSpecialInverse["LogGamma", {x, Infinity}, {y, 1}, "ModelTerms" -> 1];
    phi = s["CoreInverse"];
    {TrueQ[FullSimplify[Normal[s] == phi + 1/2 - Log[2 Pi]/(2 Log[phi]), y > 0]],
     ! FreeQ[phi, ProductLog[0, _] | ProductLog[_]], s["RemainderPower"], s["ExactModel"]}],
  {True, True, 1, False}, TestID -> "special-Stirling-exact-Lambert-core-first-correction"]

VerificationTest[
  Module[{x, y, s, valueRatios, derivativeRatios},
    s = AsymptoticSpecialInverse["LogGamma", {x, Infinity}, {y, 2}, "ModelTerms" -> 3];
    valueRatios = Table[N[Abs[LogGamma[x] - s["ForwardModel"]]/s["ForwardRemainderBound"] /. x -> a, 70], {a, {1/2, 2, 10}}];
    derivativeRatios = Table[N[Abs[PolyGamma[0, x] - D[s["ForwardModel"], x]]/s["ForwardDerivativeRemainderBound"] /. x -> a, 70], {a, {1/2, 2, 10}}];
    And @@ (TrueQ[0 < # < 1] & /@ Join[valueRatios, derivativeRatios])],
  True, TestID -> "special-Stirling-value-and-digamma-remainder-bounds"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticSpecialInverse["LogGamma", {x, Infinity}, {y, 3}, "ModelTerms" -> 1];
    {s["RemainderPower"], s["AccuracyFloor"][["Power"]], s["MarkerDepth"]}],
  {1, 1, 3}, TestID -> "special-Stirling-model-floor-is-preserved"]

VerificationTest[
  Module[{x, y, s, check},
    s = AsymptoticSpecialInverse["LogGamma", {x, Infinity}, {y, 3}];
    check = SpecialInverseNumericalCheck[s, LogGamma[100], WorkingPrecision -> 60];
    {TrueQ[Abs[check[["ReferenceRoot"]] - 100] < 10^-54], check[["Certified"]]}],
  {True, False}, TestID -> "special-LogGamma-original-equation-reference"]

VerificationTest[
  Module[{x, y, low, high, a, b},
    low = AsymptoticSpecialInverse["LogGamma", {x, Infinity}, {y, 1}];
    high = AsymptoticSpecialInverse["LogGamma", {x, Infinity}, {y, 3}];
    a = N[Abs[(Normal[low] /. y -> LogGamma[100]) - 100], 70];
    b = N[Abs[(Normal[high] /. y -> LogGamma[100]) - 100], 70];
    TrueQ[0 < b < a]],
  True, TestID -> "special-Stirling-neighboring-depth-overlap"]

VerificationTest[
  Module[{x, y, s, check},
    s = AsymptoticSpecialInverse["Gamma", {x, Infinity}, {y, 2}];
    check = SpecialInverseNumericalCheck[s, Exp[10000], WorkingPrecision -> 50];
    {TrueQ[N[Abs[LogGamma[check[["ReferenceRoot"]]] - 10000], 40] < 10^-35],
     TrueQ[Simplify[s["TargetCoordinateExpression"] /. y -> Exp[10000]] == 10000]}],
  {True, True}, TestID -> "special-Gamma-large-target-logarithmic-stability"]

VerificationTest[
  Module[{x, y, s, t, expected},
    s = AsymptoticSpecialInverse["LambertThreshold", {x, -1}, {y, 5/2}];
    expected = -1 + t - t^2/3 + 11 t^3/72 - 43 t^4/540;
    {TrueQ[FullSimplify[(Normal[s] /. y -> (t^2/2 - 1)/E) == expected, 0 < t < 1]], s["ThresholdBranch"]}],
  {True, 0}, TestID -> "special-Lambert-threshold-independent-Puiseux-coefficients"]

VerificationTest[
  Module[{x, y, s, t, expected},
    s = AsymptoticSpecialInverse["LambertThreshold", {x, -1}, {y, 5/2}, "LambertBranch" -> -1];
    expected = -1 - t - t^2/3 - 11 t^3/72 - 43 t^4/540;
    {TrueQ[FullSimplify[(Normal[s] /. y -> (t^2/2 - 1)/E) == expected, 0 < t < 1]], s["Direction"]}],
  {True, "FromBelow"}, TestID -> "special-Lambert-lower-threshold-branch-signs"]

VerificationTest[
  Module[{x, y, s, check},
    s = AsymptoticSpecialInverse["LambertThreshold", {x, -1}, {y, 3}, "LambertBranch" -> -1];
    check = SpecialInverseNumericalCheck[s, -1/E + 1/10000, WorkingPrecision -> 60];
    {TrueQ[check[["ReferenceRoot"]] < -1], TrueQ[0 < check[["Error"]] < 10^-10]}],
  {True, True}, TestID -> "special-Lambert-threshold-overlap-with-exact-ProductLog"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticSpecialInverse["LambertThreshold", {x, -1}, {y, 2}, Direction -> "FromAbove", "LambertBranch" -> -1], Failure["ConflictingBranch", _]]],
  True, TestID -> "special-Lambert-conflicting-real-branch-rejected"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticSpecialInverse["LambertThreshold", {x, -1}, {y, 2}];
    MatchQ[SpecialInverseNumericalCheck[s, -1/E - 1/100], Failure["OutsideBranch", _]]],
  True, TestID -> "special-Lambert-target-below-real-threshold-rejected"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticSpecialInverse["QuadraticThreshold", {x, 3}, {y, 2}, "TargetOffset" -> 7, "TargetScale" -> -2, "QuadraticCoefficient" -> 3];
    {TrueQ[FullSimplify[Normal[s] == 3 + Sqrt[(7 - y)/6], y < 7]], s["Remainder"], s["ThresholdTarget"]}],
  {True, 0, 7}, TestID -> "special-exact-shifted-scaled-quadratic-threshold"]

VerificationTest[
  Module[{x, y, mu, plus, minus},
    plus = AsymptoticSpecialInverse["QuadraticThreshold", {x, 0}, {y, 1}, "TargetOffset" -> -mu, Assumptions -> mu > 0];
    minus = AsymptoticSpecialInverse["QuadraticThreshold", {x, 0}, {y, 1}, "TargetOffset" -> -mu, Assumptions -> mu > 0, Direction -> "FromBelow"];
    {TrueQ[FullSimplify[(Normal[plus] - Normal[minus] /. y -> 0) == 2 Sqrt[mu], mu > 0]],
     plus["Remainder"], minus["Remainder"]}],
  {True, 0, 0}, TestID -> "special-quadratic-coalescing-branches-retain-direction"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticSpecialInverse["Erfc", {x, 0}, {y, 2}], Failure["UnsupportedEndpoint", _]]],
  True, TestID -> "special-tail-adapter-does-not-claim-finite-endpoint"]

VerificationTest[
  Module[{x, y, b},
    MatchQ[AsymptoticSpecialInverse["Gamma", {x, Infinity}, {y, 2}, "TargetOffset" -> b], Failure["UnprovedSign", _]]],
  True, TestID -> "special-target-offset-must-be-provably-real"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 2}, "ModelTerms" -> 10, "MaxTerms" -> 3], Failure["ResourceLimit", _]]],
  True, TestID -> "special-forward-model-resource-budget"]
