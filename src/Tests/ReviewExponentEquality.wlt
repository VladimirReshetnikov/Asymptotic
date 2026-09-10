(* R13 A1 / C14: exact equality classes precede support counts, logarithmic
   frontier degrees, and inverse enumeration. The identity used below is
   Cosh[2 t]-1 = 2 Sinh[t]^2. No numerical closeness establishes equality. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
  FullSimplify[Sinh[1]^2 - (Cosh[2] - 1)/2],
  0, TestID -> "review-exponent-equality-independent-hyperbolic-identity"]

VerificationTest[
  Module[{x, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s},
    s = AsymptoticExpansion[x^a - x^b + x^2, {x, 0},
      SeriesTermGoal -> 1, "Backend" -> "Package"];
    If[FailureQ[s], s, {Normal[s] === x^2, s["Remainder"], s["ReturnedTermCount"]}]],
  {True, 0, 1}, TestID -> "review-exponent-equality-cancellation-before-term-goal"]

VerificationTest[
  Module[{x, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s},
    s = AsymptoticExpansion[x^a - x^b + x^2, {x, Infinity},
      SeriesTermGoal -> 1, "Backend" -> "Package"];
    If[FailureQ[s], s, {Normal[s] === x^2, s["Remainder"], s["ReturnedTermCount"]}]],
  {True, 0, 1}, TestID -> "review-exponent-equality-negative-local-weights-at-infinity"]

VerificationTest[
  Module[{x, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s, t},
    s = AsymptoticExpansion[1 + x^a + x^b Log[x]^3 + x^(2 a),
      {x, 0, 2 a}, "Backend" -> "Package"];
    t = SeriesMultiply[s, s];
    If[FailureQ[t], t, {FullSimplify[t["RemainderPower"] - 2 a],
      t["RemainderLogDegree"], Length[t["Terms"]],
      TrueQ[FullSimplify[Normal[t] == 1 + 2 x^a (1 + Log[x]^3), x > 0]]}]],
  {0, 6, 2, True}, TestID -> "review-exponent-equality-square-frontier-needs-log-degree-six"]

VerificationTest[
  Module[{x, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s, t},
    (* The surviving coefficient is Log[x]^2, so its square has degree 4. *)
    s = AsymptoticExpansion[1 + x^a (Log[x]^3 + Log[x]^2) -
      x^b Log[x]^3 + x^(2 a), {x, 0, 2 a}, "Backend" -> "Package"];
    t = SeriesMultiply[s, s];
    If[FailureQ[t], t, {FullSimplify[t["RemainderPower"] - 2 a],
      t["RemainderLogDegree"]}]],
  {0, 4}, TestID -> "review-exponent-equality-cancelled-log-degree-before-boundary-product"]

VerificationTest[
  Module[{x, y, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s},
    Table[s = AsymptoticInverse[x^a - x^b + x^2, {x, 0}, {y, 2},
        Method -> method, "MaxTerms" -> 8];
      If[FailureQ[s], s, {Normal[s] === Sqrt[y], s["Remainder"], s["Model"]["Gaps"]}],
      {method, {"Lagrange", "Newton", "GroupedLagrange"}}]],
  ConstantArray[{True, 0, {}}, 3],
  TestID -> "review-exponent-equality-no-zero-gap-inverse-enumeration-three-methods"]

VerificationTest[
  Module[{x, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, model},
    model = PowerLogModel[x^a - x^b + x^2, {x, 0}];
    If[FailureQ[model], model, {model["Rows"], model["LeadingPower"],
      model["LeadingCoefficient"], model["Gaps"], model["Polynomials"]}]],
  {{{2, 1}}, 2, 1, {}, {}},
  TestID -> "review-exponent-equality-model-normalization-before-leading-power"]

VerificationTest[
  Module[{x, y, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s, expected},
    (* Inverting x (1+2 x^a) gives y-2 y^(1+a)+4(1+a)y^(1+2a). *)
    s = AsymptoticInverse[x (1 + x^a + x^b), {x, 0}, {y, 1 + 3 a}, "MaxTerms" -> 8];
    expected = y - 2 y^(1 + a) + 4 (1 + a) y^(1 + 2 a);
    If[FailureQ[s], s, {Length[s["Model"]["Gaps"]], s["Model"]["Polynomials"],
      Length[s["Terms"]], TrueQ[FullSimplify[Normal[s] == expected, y > 0]]}]],
  {1, {2}, 3, True},
  TestID -> "review-exponent-equality-nonzero-equal-gaps-share-one-enumeration-generator"]

VerificationTest[
  Module[{x, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s},
    s = AsymptoticExpansion[x^a - x^b, {x, 0}, SeriesTermGoal -> 1, "Backend" -> "Package"];
    If[FailureQ[s], s, {Normal[s], s["Remainder"], s["ReturnedTermCount"], s["Exact"]}]],
  {0, 0, 0, True}, TestID -> "review-exponent-equality-complete-zero-is-exact"]

VerificationTest[
  Module[{x, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s},
    s = AsymptoticExpansion[1 + x^a (Log[x]^5 + Log[x]^2) - x^b Log[x]^5,
      {x, 0, b}, "Backend" -> "Package"];
    If[FailureQ[s], s, {Normal[s], FullSimplify[s["RemainderPower"] - a],
      s["RemainderLogDegree"],
      TrueQ[FullSimplify[s["FrontierTerm"] == x^a Log[x]^2, x > 0]]}]],
  {1, 0, 2, True}, TestID -> "review-exponent-equality-exclusive-cutoff-keeps-complete-frontier-degree"]

VerificationTest[
  Module[{x, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s, t, sums},
    s = AsymptoticExpansion[1 + x^a Log[x], {x, 0, 4}, "Backend" -> "Package"];
    t = AsymptoticExpansion[1 - x^b Log[x], {x, 0, 4}, "Backend" -> "Package"];
    sums = {SeriesAdd[s, t], SeriesAdd[t, s]};
    ({Normal[#], #["Remainder"], Length[#["Terms"]]} &) /@ sums],
  {{2, 0, 1}, {2, 0, 1}}, TestID -> "review-exponent-equality-cancellation-across-separate-objects-both-orders"]

VerificationTest[
  Module[{ell, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, rows},
    And @@ Flatten[Table[
      rows = AsymptoticAnalysis`Private`jetMerge[
        {{a, ell^p + ell^q}, {b, -ell^p + 2}}, ell, True];
      Length[rows] === 1 && FullSimplify[rows[[1, 1]] - a] === 0 &&
        Expand[rows[[1, 2]] - (ell^q + 2)] === 0,
      {p, {0, 1, 3}}, {q, {0, 2, 4}}]]],
  True, TestID -> "review-exponent-equality-polynomial-cancellation-nine-degree-pairs"]

VerificationTest[
  Module[{ell, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, rows},
    And @@ Table[
      rows = AsymptoticAnalysis`Private`jetMerge[permutation, ell, True];
      Length[rows] === 2 && FullSimplify[rows[[1, 1]] - a] === 0 &&
        rows[[1, 2]] === 3 && rows[[2]] === {3, 4},
      {permutation, Permutations[{{a, 1}, {b, 2}, {3, 4}}]}]],
  True, TestID -> "review-exponent-equality-input-order-does-not-change-complete-support"]

VerificationTest[
  Module[{ell, epsilon = 10^-200, rows},
    rows = AsymptoticAnalysis`Private`jetMerge[{{1 + epsilon, -1}, {1, 1}}, ell, True];
    {Length[rows], rows[[All, 2]], rows[[2, 1]] - rows[[1, 1]] === epsilon}],
  {2, {1, -1}, True}, TestID -> "review-exponent-equality-close-distinct-rational-powers-remain-distinct"]

VerificationTest[
  Module[{ell, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, epsilon = 10^-100, rows},
    rows = AsymptoticAnalysis`Private`jetMerge[
      {{a, 3}, {b, 4}, {b + epsilon, -1}, {b - epsilon, 2}}, ell, True];
    {Length[rows], rows[[All, 2]],
      FullSimplify[rows[[All, 1]] - {a - epsilon, a, a + epsilon}]}],
  {3, {2, 7, -1}, {0, 0, 0}},
  TestID -> "review-exponent-equality-close-transcendental-powers-surround-one-equal-class"]

VerificationTest[
  Module[{a, b, result},
    result = AsymptoticAnalysis`Private`catch[
      AsymptoticAnalysis`Private`orderedWeightGroups[{{a, 1}, {b, 2}}]];
    MatchQ[result, Failure["UndecidableOrder", _Association]]],
  True, TestID -> "review-exponent-equality-unknown-order-is-not-an-equality-proof"]

VerificationTest[
  Module[{ell, alpha},
    (* A structural cancellation needs no relation between alpha and 2. *)
    AsymptoticAnalysis`Private`jetMerge[{{alpha, 1}, {alpha, -1}, {2, 1}}, ell, True]],
  {{2, 1}}, TestID -> "review-exponent-equality-cancelled-structural-block-needs-no-order-proof"]

VerificationTest[
  Module[{proofCalls = 0, groups},
    Block[{AsymptoticAnalysis`Private`compare},
      AsymptoticAnalysis`Private`compare[_, _] := (proofCalls++; 0);
      groups = AsymptoticAnalysis`Private`orderedWeightGroups[Table[{1, k}, {k, 2000}]]];
    {Length[groups], Length[First[groups]], proofCalls}],
  {1, 2000, 0}, TestID -> "review-exponent-equality-identical-keys-need-no-additional-order-proofs"]

VerificationTest[
  Module[{ell, a = Sinh[1]^2, b = (Cosh[2] - 1)/2},
    AsymptoticAnalysis`Private`logarithmicMerge[
      {{a, Sqrt[ell]}, {b, -Sqrt[ell]}, {2, Log[ell]}}, ell > 0] /. ell -> \[FormalL]],
  {{2, Log[\[FormalL]]}},
  TestID -> "review-exponent-equality-generalized-logarithmic-coefficients-cancel"]

VerificationTest[
  Module[{u, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, sectors},
    sectors = AsymptoticAnalysis`Private`specialNativeSectors[
      Exp[-1/u] (u^a Sin[1/u] - u^b Sin[1/u] + u^2), u, True];
    {Length[sectors], sectors[[1]]["LeadingPower"], sectors[[1]]["Rows"],
      sectors[[1]]["Oscillatory"]}],
  {1, 2, {{0, 1, 0}}, False},
  TestID -> "review-exponent-equality-native-amplitude-cancellation-before-leading-power"]

VerificationTest[
  Module[{ell, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, rows},
    rows = AsymptoticAnalysis`Private`fourierMerge[{{a, 1}, {b, 2}}, ell, True, 1];
    {Length[rows], FullSimplify[rows[[1, 1]] - a], rows[[1, 2]]}],
  {1, 0, 3}, TestID -> "review-exponent-equality-fourier-resonance-counts-one-frequency"]

VerificationTest[
  Module[{ell, result},
    result = AsymptoticAnalysis`Private`catch[
      AsymptoticAnalysis`Private`fourierMerge[{{1, 1}, {1 + 10^-200, 1}}, ell, True, 1]];
    MatchQ[result, Failure["FrequencyLimit", _Association]]],
  True, TestID -> "review-exponent-equality-distinct-frequencies-still-enforce-budget"]

VerificationTest[
  Module[{ell, result},
    result = AsymptoticAnalysis`Private`catch[
      AsymptoticAnalysis`Private`jetMul[{{0, 1}, {1, 1}}, {{0, 1}, {1, 1}}, 2, ell, True, 2]];
    MatchQ[result, Failure["ResourceLimit", _Association]]],
  True, TestID -> "review-exponent-equality-sparse-product-candidate-budget-is-unchanged"]
