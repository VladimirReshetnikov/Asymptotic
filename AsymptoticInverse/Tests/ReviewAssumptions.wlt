(* Review 8 F01: constructor defaults capture the ambient assumptions;
   explicit options replace them. Operations use recorded assumptions only.
   Every result is inspected after leaving the Assuming scope that made it. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

reviewAssumptionsEquivalent[actual_, expected_, assumptions_: True] := Block[{$Assumptions = True},
  TrueQ[FullSimplify[Equivalent[actual, expected], Assumptions -> assumptions]]];
reviewAssumptionsExpressionEqual[actual_, expected_, assumptions_: True] :=
  Block[{$Assumptions = True},
    TrueQ[FullSimplify[actual == expected, Assumptions -> assumptions]]];
reviewAssumptionsStored[s_, expected_] := MatchQ[s, _GeneralizedSeries] &&
  reviewAssumptionsEquivalent[s["Assumptions"], expected];

VerificationTest[
  Module[{x, a, s, condition},
    And @@ Table[
      condition = sign a > 0;
      s = Assuming[condition, AsymptoticExpansion[Sqrt[a^2] + x, {x, 0, 2}]];
      reviewAssumptionsStored[s, condition] &&
        reviewAssumptionsExpressionEqual[Normal[s], sign a + x, condition],
      {sign, {-1, 1}}]],
  True, TestID -> "review-assumptions-forward-captures-positive-and-negative-ambient-branches"]

VerificationTest[
  Module[{x, a, b, s},
    s = Assuming[a > 0, Assuming[b > 0,
      AsymptoticExpansion[Abs[a] + Abs[b] x, {x, 0, 2}]]];
    reviewAssumptionsStored[s, a > 0 && b > 0] &&
      reviewAssumptionsExpressionEqual[Normal[s], a + b x]],
  True, TestID -> "review-assumptions-nested-ambient-scopes-are-captured-together"]

VerificationTest[
  Module[{x, y, a, s},
    s = Assuming[a > 0, AsymptoticInverse[a x + x^2, {x, 0}, {y, 3}]];
    reviewAssumptionsStored[s, a > 0] &&
      reviewAssumptionsExpressionEqual[Normal[s], y/a - y^2/a^3, a > 0 && y > 0]],
  True, TestID -> "review-assumptions-inverse-retains-the-sign-used-in-its-coefficients"]

VerificationTest[
  Module[{x, y, a, forward, inverse},
    forward = Assuming[a < 0,
      AsymptoticExpansion[Abs[a] + x, {x, 0, 2}, Assumptions -> a > 0]];
    inverse = Assuming[a < 0,
      AsymptoticInverse[a x + x^2, {x, 0}, {y, 3}, Assumptions -> a > 0]];
    reviewAssumptionsStored[forward, a > 0] &&
      reviewAssumptionsStored[inverse, a > 0] &&
      reviewAssumptionsExpressionEqual[Normal[forward], a + x] &&
      reviewAssumptionsExpressionEqual[Normal[inverse], y/a - y^2/a^3, a > 0 && y > 0]],
  True, TestID -> "review-assumptions-explicit-constructor-option-replaces-conflicting-ambient"]

VerificationTest[
  Module[{x, y, a},
    Assuming[a > 0, FailureQ[
      AsymptoticInverse[a x + x^2, {x, 0}, {y, 3}, Assumptions -> True]]]],
  True, TestID -> "review-assumptions-explicit-true-cannot-borrow-ambient-inverse-sign"]

VerificationTest[
  Module[{x, a, s},
    s = Assuming[a > 0,
      AsymptoticExpansion[Abs[a] + x, {x, 0, 2}, Assumptions -> True]];
    reviewAssumptionsStored[s, True] &&
      reviewAssumptionsExpressionEqual[Normal[s], Abs[a] + x] &&
      (Normal[s] /. {a -> -2, x -> 0}) === 2],
  True, TestID -> "review-assumptions-explicit-true-preserves-unspecialized-forward-coefficients"]

VerificationTest[
  Module[{x, a, s},
    s = Assuming[a > 0 && 0 < x < 1,
      AsymptoticExpansion[Abs[a] + x, {x, 0, 2}]];
    reviewAssumptionsStored[s, a > 0] &&
      reviewAssumptionsExpressionEqual[Normal[s], a + x] &&
      reviewAssumptionsEquivalent[s["TargetDomain"], 0 < x < 1,
        a > 0 && Element[x, Reals]]],
  True, TestID -> "review-assumptions-primary-forward-separates-ambient-parameter-and-approach-conditions"]

VerificationTest[
  Module[{x, y, a, s, refined},
    s = Assuming[a > 0, AsymptoticInverse[a x + x^2, {x, 0}, {y, 3}]];
    refined = Assuming[a < 0, SeriesRefine[s, 5]];
    reviewAssumptionsStored[refined, a > 0] &&
      reviewAssumptionsExpressionEqual[Normal[refined],
        y/a - y^2/a^3 + 2 y^3/a^5 - 5 y^4/a^7, a > 0 && y > 0] &&
      reviewAssumptionsStored[s, a > 0]],
  True, TestID -> "review-assumptions-inverse-refinement-uses-stored-context-under-conflicting-ambient"]

VerificationTest[
  Module[{x, a, s, refined},
    s = Assuming[Element[a, Reals],
      AsymptoticExpansion[Sqrt[a^2] + Sin[x], {x, 0, 2}]];
    refined = Assuming[a > 0, SeriesRefine[s, 4]];
    reviewAssumptionsStored[refined, Element[a, Reals]] &&
      reviewAssumptionsExpressionEqual[Normal[refined], Abs[a] + x - x^3/6,
        Element[a, Reals]] &&
      (Normal[refined] /. {a -> -2, x -> 0}) === 2],
  True, TestID -> "review-assumptions-forward-refinement-does-not-specialize-under-new-ambient-sign"]

VerificationTest[
  Module[{x, z, a, s, result},
    s = AsymptoticExpansion[a + x, {x, 0, 3}, Assumptions -> a > 0];
    result = Assuming[a == 1, SeriesObservable[s, 1 + z^2, z, "Cutoff" -> 3]];
    reviewAssumptionsStored[result, a > 0] &&
      reviewAssumptionsExpressionEqual[Normal[result], 1 + a^2 + 2 a x + x^2]],
  True, TestID -> "review-assumptions-observable-coefficients-ignore-unrecorded-ambient-equalities"]

VerificationTest[
  Module[{x, a, b, s, t, result},
    s = AsymptoticExpansion[a + x, {x, 0, 3}, Assumptions -> a > 0];
    t = AsymptoticExpansion[b + x^2, {x, 0, 3}, Assumptions -> b > 0];
    result = Assuming[a == 1 && b == 1, s + t];
    reviewAssumptionsStored[result, a > 0 && b > 0] &&
      reviewAssumptionsExpressionEqual[Normal[result], a + b + x + x^2]],
  True, TestID -> "review-assumptions-automatic-arithmetic-merges-stored-contexts-without-ambient-specialization"]

VerificationTest[
  Module[{x, b, plain, declared, rejected, accepted},
    plain = AsymptoticExpansion[1 + x, {x, 0, 2}];
    declared = AsymptoticExpansion[1 + x, {x, 0, 2}, Assumptions -> Element[b, Reals]];
    rejected = Assuming[Element[b, Reals], SeriesMultiply[plain, b]];
    accepted = Assuming[b == 1, SeriesMultiply[declared, b]];
    FailureQ[rejected] && reviewAssumptionsStored[accepted, Element[b, Reals]] &&
      reviewAssumptionsExpressionEqual[Normal[accepted], b (1 + x)]],
  True, TestID -> "review-assumptions-scalar-operation-uses-declared-reality-not-ambient-reality"]

VerificationTest[
  Module[{x, r, s},
    s = Assuming[r > 0,
      AsymptoticExpansion[Gamma[x]^r, x -> Infinity, SeriesTermGoal -> 2]];
    reviewAssumptionsStored[s, r > 0] &&
      reviewAssumptionsExpressionEqual[s["Terms"], {{0, 1}, {1, r/12}}] &&
      s["RemainderPower"] === 2],
  True, TestID -> "review-assumptions-gamma-dispatch-captures-symbolic-power-context"]

VerificationTest[
  Module[{x, y, b, s},
    s = Assuming[Element[b, Reals],
      AsymptoticLogarithmicInverse[x (1 + b/Log[x]), {x, 0}, {y, 3}]];
    reviewAssumptionsStored[s, Element[b, Reals]] &&
      reviewAssumptionsExpressionEqual[Cases[s["Terms"], {1, c_} :> c], {b}]],
  True, TestID -> "review-assumptions-logarithmic-constructor-captures-real-coefficient-context"]

VerificationTest[
  Module[{x, y, b, s},
    s = Assuming[Element[b, Reals],
      AsymptoticFlatInverse[b + x + Exp[-1/x], {x, 0}, {y, 1}]];
    reviewAssumptionsStored[s, Element[b, Reals]] &&
      reviewAssumptionsExpressionEqual[Normal[s], y - b - Exp[-1/(y - b)],
        Element[b, Reals] && y > b]],
  True, TestID -> "review-assumptions-flat-constructor-captures-real-target-offset-context"]

VerificationTest[
  Module[{x, y, b, s},
    s = Assuming[Element[b, Reals],
      AsymptoticFourierInverse[x + b x^2 Sin[Log[x]], {x, 0}, {y, 3}]];
    reviewAssumptionsStored[s, Element[b, Reals]] &&
      reviewAssumptionsExpressionEqual[Normal[s], y - b y^2 Sin[Log[y]],
        Element[b, Reals] && y > 0]],
  True, TestID -> "review-assumptions-fourier-constructor-captures-real-amplitude-context"]

VerificationTest[
  Module[{x, a, model, coefficient},
    model = Assuming[Element[a, Reals], PowerLogModel[x + Abs[a] x^2, {x, 0}]];
    coefficient = Assuming[a > 0, InverseExpansionCoefficient[model, {1}]];
    AssociationQ[model] && AssociationQ[coefficient] &&
      reviewAssumptionsEquivalent[Lookup[model, "Assumptions", Missing["Absent"]], Element[a, Reals]] &&
      reviewAssumptionsExpressionEqual[coefficient["Coefficient"], -Abs[a], Element[a, Reals]] &&
      coefficient["Exponent"] === 2 &&
      (coefficient["Coefficient"] /. a -> -2) === -2],
  True, TestID -> "review-assumptions-finite-model-and-later-coefficient-use-recorded-context"]
