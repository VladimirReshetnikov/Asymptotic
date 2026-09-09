(* C07: ordinary coefficients, including target offsets and constant
   observables, must be provably real under the recorded assumptions.
   Reality is a property of the complete normalized coefficient. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

reviewRealCoefficientFailureQ[value_] := MatchQ[value, Failure["UnprovedRealCoefficient", _Association]];
reviewRealCoefficientEqual[s_, expected_, assumptions_: True] := MatchQ[s, _GeneralizedSeries] &&
  Block[{$Assumptions = True},
    TrueQ[FullSimplify[Normal[s] == expected, Assumptions -> assumptions]]];

VerificationTest[
  Module[{x, a},
    And @@ (reviewRealCoefficientFailureQ[#] & /@ {
      AsymptoticExpansion[Log[-a], {x, 0, 2}, Assumptions -> a > 0],
      AsymptoticExpansion[Log[-a] + x, {x, 0, 2}, Assumptions -> a > 0]})],
  True, TestID -> "review-real-coefficients-reject-complex-constant-and-forward-offset"]

VerificationTest[
  Module[{x},
    And @@ (reviewRealCoefficientFailureQ[#] & /@ {
      AsymptoticExpansion[ArcSin[2 + x], {x, 0, 3}],
      AsymptoticExpansion[ArcCos[2 + x], {x, 0, 3}]})],
  True, TestID -> "review-real-coefficients-native-inverse-trigonometric-complex-branches-rejected"]

VerificationTest[
  Module[{x, a},
    reviewRealCoefficientFailureQ[
      PowerLogModel[Log[-a] + x, {x, 0}, Assumptions -> a > 0]]],
  True, TestID -> "review-real-coefficients-model-validates-constant-target-offset"]

VerificationTest[
  Module[{x, y, a},
    reviewRealCoefficientFailureQ[
      AsymptoticInverse[Log[-a] + x + x^2, {x, 0}, {y, 3}, Assumptions -> a > 0]]],
  True, TestID -> "review-real-coefficients-inverse-rejects-complex-target-offset"]

VerificationTest[
  Module[{x, z, a, s},
    s = AsymptoticExpansion[1 + x, {x, 0, 3}, Assumptions -> a > 0];
    reviewRealCoefficientFailureQ[SeriesObservable[s, Log[-a], z]]],
  True, TestID -> "review-real-coefficients-constant-observable-cannot-bypass-realness-check"]

VerificationTest[
  Module[{x, z, a, s},
    s = AsymptoticExpansion[1 + x, {x, 0, 3}, Assumptions -> a > 0];
    reviewRealCoefficientFailureQ[SeriesObservable[s, Log[-a] z, z]]],
  True, TestID -> "review-real-coefficients-observable-multiplier-must-be-real"]

VerificationTest[
  Module[{x, a},
    And @@ (reviewRealCoefficientFailureQ[#] & /@ {
      AsymptoticExpansion[a + x, {x, 0, 2}, Assumptions -> True],
      AsymptoticExpansion[a x, {x, 0, 2}, Assumptions -> True]})],
  True, TestID -> "review-real-coefficients-undeclared-parameter-is-not-assumed-real"]

VerificationTest[
  Module[{x, z, a, s, observable},
    s = AsymptoticExpansion[a + Sin[a] x, {x, 0, 2}, Assumptions -> Element[a, Reals]];
    observable = SeriesObservable[s, Sin[a], z];
    reviewRealCoefficientEqual[s, a + Sin[a] x, Element[a, Reals]] &&
      reviewRealCoefficientEqual[observable, Sin[a], Element[a, Reals]] &&
      s["Remainder"] === 0 && observable["Remainder"] === 0],
  True, TestID -> "review-real-coefficients-declared-real-parameter-and-constant-observable-remain-supported"]

VerificationTest[
  Module[{x, a},
    reviewRealCoefficientFailureQ[
      AsymptoticExpansion[ArcSin[a] + x, {x, 0, 2}, Assumptions -> Element[a, Reals]]]],
  True, TestID -> "review-real-coefficients-real-argument-alone-does-not-prove-real-arcsine"]

VerificationTest[
  Module[{x, a, sine, cosine},
    sine = AsymptoticExpansion[ArcSin[a + x], {x, 0, 2}, Assumptions -> -1 < a < 1];
    cosine = AsymptoticExpansion[ArcCos[a + x], {x, 0, 2}, Assumptions -> -1 < a < 1];
    reviewRealCoefficientEqual[sine, ArcSin[a] + x/Sqrt[1 - a^2], -1 < a < 1] &&
      reviewRealCoefficientEqual[cosine, ArcCos[a] - x/Sqrt[1 - a^2], -1 < a < 1]],
  True, TestID -> "review-real-coefficients-proved-interior-inverse-trigonometric-branches-remain-supported"]

VerificationTest[
  Module[{x, s},
    And @@ Table[
      s = AsymptoticExpansion[c + x, {x, 0, 2}];
      reviewRealCoefficientEqual[s, c + x] && s["Remainder"] === 0,
      {c, {Pi, EulerGamma, Log[2], Gamma[1/3], Zeta[3]}}]],
  True, TestID -> "review-real-coefficients-exact-real-transcendental-constants-remain-supported"]

VerificationTest[
  Module[{x, a, s},
    s = AsymptoticExpansion[Log[-a] + x, {x, 0, 2}, Assumptions -> a < 0];
    reviewRealCoefficientEqual[s, Log[-a] + x, a < 0] && s["Remainder"] === 0],
  True, TestID -> "review-real-coefficients-negative-parameter-makes-negated-log-argument-positive"]

VerificationTest[
  Module[{x},
    MatchQ[AsymptoticExpansion[Log[-x], {x, 0, 2}], Failure["NonpositiveBase", _Association]]],
  True, TestID -> "review-real-coefficients-existing-variable-logarithm-branch-failure-remains-specific"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[ArcCos[1 - x^Sqrt[2]], {x, 0, 3}];
    reviewRealCoefficientEqual[s,
      Sqrt[2] x^(1/Sqrt[2]) + x^(3/Sqrt[2])/(6 Sqrt[2]), x > 0]],
  True, TestID -> "review-real-coefficients-real-puiseux-branch-with-irrational-argument-remains-supported"]

(* Both forms have the same real complete coefficient. Checking each
   logarithm or each Times factor before grouping would reject them. *)
VerificationTest[
  Module[{x, a, b, constant, weighted, assumptions},
    assumptions = a > 0 && b > 0;
    constant = AsymptoticExpansion[Log[-a] - Log[-b] + x, {x, 0, 3}, Assumptions -> assumptions];
    weighted = AsymptoticExpansion[x Log[-a] - x Log[-b] + x^2, {x, 0, 3}, Assumptions -> assumptions];
    reviewRealCoefficientEqual[constant, Log[a] - Log[b] + x, assumptions] &&
      reviewRealCoefficientEqual[weighted, x (Log[a] - Log[b]) + x^2, assumptions] &&
      constant["Remainder"] === 0 && weighted["Remainder"] === 0],
  True, TestID -> "review-real-coefficients-complete-constant-and-weighted-logarithmic-cancellations-remain-real"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[ArcSin[2 + x] + ArcCos[2 + x], {x, 0, 3}];
    reviewRealCoefficientEqual[s, Pi/2, x > 0]],
  True, TestID -> "review-real-coefficients-complete-inverse-trigonometric-identity-cancels-complex-branches"]

VerificationTest[
  Module[{x, nu = Sqrt[2], s},
    s = AsymptoticExpansion[BesselJ[nu, x], {x, 0, 5}];
    reviewRealCoefficientEqual[s,
      (x/2)^nu/Gamma[1 + nu] (1 - x^2/(4 (1 + nu))), x > 0]],
  True, TestID -> "review-real-coefficients-parameterized-real-frobenius-coefficients-remain-supported"]

VerificationTest[
  Module[{x, s, phase},
    phase = x - Pi/4;
    s = AsymptoticExpansion[BesselJ[0, x], x -> Infinity, SeriesTermGoal -> 2];
    reviewRealCoefficientEqual[s,
      Sqrt[2/(Pi x)] (Cos[phase] + Sin[phase]/(8 x)), x > 0]],
  True, TestID -> "review-real-coefficients-real-native-special-function-projection-keeps-bessel-phase"]

VerificationTest[
  Module[{x, z, a, b, s, result, assumptions},
    assumptions = a > 0 && b > 0;
    s = AsymptoticExpansion[1 + x, {x, 0, 3}, Assumptions -> assumptions];
    result = SeriesObservable[s, Log[-a] - Log[-b], z];
    reviewRealCoefficientEqual[result, Log[a] - Log[b], assumptions] &&
      result["Remainder"] === 0],
  True, TestID -> "review-real-coefficients-constant-observable-checks-complete-logarithmic-cancellation"]

VerificationTest[
  Module[{x, z, s, result},
    s = AsymptoticExpansion[Sin[x], {x, 0, 3}];
    result = SeriesObservable[s, ArcSin[2 + z] + ArcCos[2 + z], z];
    reviewRealCoefficientEqual[result, Pi/2, x > 0]],
  True, TestID -> "review-real-coefficients-observable-checks-complete-inverse-trigonometric-cancellation"]
