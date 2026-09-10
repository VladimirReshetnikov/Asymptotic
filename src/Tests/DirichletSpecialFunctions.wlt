(* Independent low-order formulas and pointwise defining-sum tail checks.
   Explicit helper calls cover exact Lerch cases that native evaluation may
   already simplify before the public dispatcher sees their original head. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

dirichletExpandAt[f_, x_, point_: Infinity, cut_: Automatic, goal_: 3, ass_: True, limit_: 20000] :=
  AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`dirichletSpecialForwardExpansion[
    f, x, point, cut, ass, AsymptoticAnalysis`Private`localCoordinate[x, point, Automatic], goal, limit]];
dirichletLerchAt[z_, s_, a_, x_, point_: Infinity, cut_: Automatic, goal_: 3, ass_: True, limit_: 20000] :=
  AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`dirichletLerchForward[
    LerchPhi[z, s, a], z, s, a, x, point, cut, ass,
    AsymptoticAnalysis`Private`localCoordinate[x, point, Automatic], goal, limit]];
dirichletEqual[result_, expected_, ass_: True] := MatchQ[result, _GeneralizedSeries] &&
  TrueQ[FullSimplify[Normal[result] == expected, ass]];

VerificationTest[Module[{x, s, refined},
  s = AsymptoticExpansion[Zeta[2 x + 1], x -> Infinity, SeriesTermGoal -> 3];
  refined = SeriesRefine[s, Log[5]];
  {dirichletEqual[s, 1 + 2^(-2 x - 1) + 3^(-2 x - 1), x > 1],
    dirichletEqual[refined, Sum[n^(-2 x - 1), {n, 1, 4}], x > 1],
    refined["RemainderVariable"] === Exp[-2 x - 1]}],
  {True, True, True}, TestID -> "dirichlet-public-zeta-dispatch-and-refinement-preserve-the-exponential-coordinate"]

VerificationTest[Module[{x, s, refined},
  s = AsymptoticExpansion[LerchPhi[1/2, 2, x], x -> Infinity, SeriesTermGoal -> 3];
  refined = SeriesRefine[s, 6];
  {dirichletEqual[s, 2/x^2 - 4/x^3 + 18/x^4, x > 0],
    dirichletEqual[refined, 2/x^2 - 4/x^3 + 18/x^4 - 104/x^5, x > 0],
    refined["RemainderPower"]}],
  {True, True, 6}, TestID -> "dirichlet-public-lerch-dispatch-and-source-refinement"]

VerificationTest[Module[{x, s},
  s = dirichletExpandAt[Zeta[x], x, Infinity, Automatic, 5];
  {dirichletEqual[s, 1 + 2^-x + 3^-x + 4^-x + 5^-x, x > 1],
    s["RemainderPower"], s["RemainderVariable"] === Exp[-x], s["ReturnedTermCount"],
    s["FirstOmittedInteger"], s["Kind"], s["Exact"]}],
  {True, Log[6], True, 5, 6, "Forward", False},
  TestID -> "dirichlet-zeta-five-terms-include-one-and-use-exponential-coordinate"]

VerificationTest[Module[{x, strict, above},
  strict = dirichletExpandAt[Zeta[x], x, Infinity, Log[4]];
  above = dirichletExpandAt[Zeta[x], x, Infinity, Log[4] + 1/100];
  {dirichletEqual[strict, 1 + 2^-x + 3^-x, x > 1], strict["FirstOmittedInteger"],
    dirichletEqual[above, 1 + 2^-x + 3^-x + 4^-x, x > 1], above["FirstOmittedInteger"]}],
  {True, 4, True, 5}, TestID -> "dirichlet-zeta-explicit-cutoff-is-exclusive-at-logarithmic-weights"]

VerificationTest[Module[{x, s},
  s = dirichletExpandAt[Zeta[x], x, Infinity, 0];
  {Normal[s], s["ReturnedTermCount"], s["RemainderPower"], s["FirstOmittedInteger"],
    s["Exact"], TrueQ[FullSimplify[s["AbsoluteRemainderBound"] == 1 + 1/(x - 1), x > 1]]}],
  {0, 0, 0, 1, False, True}, TestID -> "dirichlet-zeta-cutoff-zero-retains-a-genuine-pure-order-remainder"]

VerificationTest[Module[{x, positive, negative},
  positive = dirichletExpandAt[Zeta[2 x + 3], x];
  negative = dirichletExpandAt[Zeta[-3 x + 2], x, -Infinity];
  {dirichletEqual[positive, 1 + 2^(-2 x - 3) + 3^(-2 x - 3), x > 0],
    positive["RemainderVariable"] === Exp[-2 x - 3],
    dirichletEqual[negative, 1 + 2^(3 x - 2) + 3^(3 x - 2), x < 0],
    negative["ExpansionPoint"]}],
  {True, True, True, -Infinity}, TestID -> "dirichlet-zeta-affine-arguments-support-both-real-infinity-approaches"]

VerificationTest[Module[{x, a, b, s},
  s = dirichletExpandAt[Zeta[a x + b], x, Infinity, Automatic, 2, a > 0 && Element[b, Reals]];
  {dirichletEqual[s, 1 + 2^(-a x - b), a > 0 && Element[{b, x}, Reals]],
    TrueQ[FullSimplify[s["TargetDomain"] == (a > 0 && Element[b, Reals] && a x + b > 1)]]}],
  {True, True}, TestID -> "dirichlet-zeta-fixed-symbolic-affine-parameters-require-real-positive-growth"]

VerificationTest[Module[{x, s, error, upper, lower},
  s = dirichletExpandAt[Zeta[x], x, Infinity, Automatic, 2];
  error = N[Zeta[10] - (Normal[s] /. x -> 10), 60];
  upper = N[s["AbsoluteRemainderBound"] /. x -> 10, 60];
  lower = N[s["RemainderLowerBound"] /. x -> 10, 60];
  0 < lower <= error <= upper],
  True, TestID -> "dirichlet-zeta-actual-defining-sum-tail-satisfies-independent-integral-bounds"]

VerificationTest[Module[{x},
  MatchQ[dirichletExpandAt[Zeta[x], x, Infinity, Log[100], 3, True, 20],
    Failure["ResourceLimit", _Association]]],
  True, TestID -> "dirichlet-zeta-large-cutoff-fails-before-exponential-enumeration"]

VerificationTest[Module[{x},
  {dirichletExpandAt[Zeta[-x], x], dirichletExpandAt[Zeta[x^2], x],
    dirichletExpandAt[Sin[x], x]}],
  {$Failed, $Failed, $Failed}, TestID -> "dirichlet-zeta-declines-wrong-ray-and-outside-affine-scope"]

VerificationTest[Module[{x, s},
  s = dirichletExpandAt[LerchPhi[1/2, 2, x], x];
  {dirichletEqual[s, 2/x^2 - 4/x^3 + 18/x^4, x > 0], s["RemainderPower"],
    s["FirstOmittedMoment"], s["RemainderBoundConstant"],
    s["FrontierTerm"] === -104/x^5, s["Exact"], s["RemainderDerivativeOrder"]}],
  {True, 5, 3, 104, True, False, 0}, TestID -> "dirichlet-lerch-three-terms-and-first-omitted-moment-bound"]

VerificationTest[Module[{x, s},
  s = dirichletExpandAt[LerchPhi[1/2, 2, x], x, Infinity, Automatic, 5];
  {dirichletEqual[s, 2/x^2 - 4/x^3 + 18/x^4 - 104/x^5 + 750/x^6, x > 0],
    s["RemainderPower"], s["ReturnedTermCount"], s["RemainderBoundConstant"]}],
  {True, 7, 5, 6492}, TestID -> "dirichlet-lerch-five-terms-match-independent-geometric-moments"]

VerificationTest[Module[{x, s},
  s = dirichletExpandAt[LerchPhi[-1/2, 2, x], x];
  {dirichletEqual[s, 2/(3 x^2) + 4/(9 x^3) - 2/(9 x^4), x > 0],
    s["RemainderBoundConstant"], s["RemainderPower"]}],
  {True, 104, 5}, TestID -> "dirichlet-lerch-negative-geometric-weight-uses-absolute-weight-in-tail-bound"]

VerificationTest[Module[{x, s},
  s = dirichletExpandAt[LerchPhi[1/2, -1/2, x], x, Infinity, Automatic, 2];
  {dirichletEqual[s, 2 Sqrt[x] + 1/Sqrt[x], x > 0],
    s["RemainderPower"], s["RemainderBoundConstant"]}],
  {True, 3/2, 3/4}, TestID -> "dirichlet-lerch-negative-noninteger-order-retains-growing-leading-block"]

VerificationTest[Module[{x, s},
  s = dirichletExpandAt[LerchPhi[1/2, -5/2, x], x, Infinity, Automatic, 1];
  {dirichletEqual[s, 2 x^(5/2), x > 0], s["RemainderPower"],
    s["RemainderBoundConstant"], TrueQ[FullSimplify[s["AbsoluteRemainderBound"] == 100 x^(3/2), x > 0]]}],
  {True, -3/2, 100, True}, TestID -> "dirichlet-lerch-tail-accounts-for-growth-of-the-Taylor-derivative"]

VerificationTest[Module[{x, s, truncated},
  s = dirichletLerchAt[1/2, -2, x, x, Infinity, Automatic, 5];
  truncated = dirichletLerchAt[1/2, -2, x, x, Infinity, Automatic, 1];
  {dirichletEqual[s, 2 x^2 + 4 x + 6, x > 0], s["Exact"], s["RemainderPower"],
    s["AbsoluteRemainderBound"], s["ReturnedTermCount"],
    dirichletEqual[truncated, 2 x^2, x > 0], truncated["Exact"], truncated["RemainderPower"],
    truncated["RemainderBoundConstant"]}],
  {True, True, Infinity, 0, 3, True, False, -1, 16},
  TestID -> "dirichlet-lerch-nonpositive-integer-order-is-exact-only-after-all-polynomial-blocks"]

VerificationTest[Module[{x, zero, constant, omitted},
  zero = dirichletLerchAt[0, Sqrt[2], x, x];
  constant = dirichletLerchAt[1/2, 0, x, x];
  omitted = dirichletLerchAt[0, Sqrt[2], x, x, Infinity, 1];
  {dirichletEqual[zero, x^-Sqrt[2], x > 0], zero["Exact"], zero["RemainderPower"],
    Normal[constant], constant["Exact"], Normal[omitted], omitted["Exact"],
    omitted["RemainderPower"], omitted["RemainderBoundConstant"]}],
  {True, True, Infinity, 2, True, 0, False, Sqrt[2], 1},
  TestID -> "dirichlet-lerch-zero-weight-and-zero-order-exact-cases-preserve-truncation-errors"]

VerificationTest[Module[{x, s},
  s = dirichletExpandAt[LerchPhi[1/2, 2, x], x, Infinity, 4];
  {dirichletEqual[s, 2/x^2 - 4/x^3, x > 0], s["RemainderPower"],
    s["FirstOmittedMoment"], s["RemainderBoundConstant"]}],
  {True, 4, 2, 18}, TestID -> "dirichlet-lerch-cutoff-is-exclusive-in-absolute-reciprocal-argument-exponents"]

VerificationTest[Module[{x, affine, finite},
  affine = dirichletExpandAt[LerchPhi[1/2, 2, 2 x + 1], x];
  finite = dirichletExpandAt[LerchPhi[1/2, 2, 1/x], x, 0];
  {dirichletEqual[affine, 2/(2 x + 1)^2 - 4/(2 x + 1)^3 + 18/(2 x + 1)^4, x > 0],
    affine["RemainderVariable"] === 1/(2 x + 1),
    dirichletEqual[finite, 2 x^2 - 4 x^3 + 18 x^4, x > 0],
    finite["RemainderVariable"] === x, finite["ExpansionPoint"]}],
  {True, True, True, True, 0}, TestID -> "dirichlet-lerch-keeps-scaled-argument-and-supports-a-large-argument-at-a-finite-endpoint"]

VerificationTest[Module[{x, s, error, bound},
  s = dirichletExpandAt[LerchPhi[1/2, 2, x], x];
  error = Abs[N[LerchPhi[1/2, 2, 10] - (Normal[s] /. x -> 10), 60]];
  bound = N[s["AbsoluteRemainderBound"] /. x -> 10, 60];
  0 < error <= bound],
  True, TestID -> "dirichlet-lerch-actual-defining-sum-error-is-below-the-derived-Taylor-bound"]

VerificationTest[Module[{x, s},
  s = dirichletExpandAt[LerchPhi[-1/2, -5/2, x], x, Infinity, Automatic, 2];
  And @@ Table[Abs[N[LerchPhi[-1/2, -5/2, value] - (Normal[s] /. x -> value), 50]] <=
    N[s["AbsoluteRemainderBound"] /. x -> value, 50], {value, {1, 4, 20}}]],
  True, TestID -> "dirichlet-lerch-growing-alternating-source-obeys-bound-down-to-positive-unit-argument"]

VerificationTest[Module[{x, s},
  s = dirichletExpandAt[LerchPhi[1/2, 2, x], x];
  {TrueQ[FullSimplify[s["TargetDomain"] == (x > 0)]],
    TrueQ[FullSimplify[s["RemainderBoundConditions"] == (x >= 1)]],
    s["SeriesRepresentation"]["Jet"][[2]], s["SeriesRepresentation"]["ScaleVariable"] === 1/x,
    s["ForwardRemainderContract"]["ConvergentForwardSeries"]}],
  {True, True, 5, True, False}, TestID -> "dirichlet-lerch-domain-ordered-representation-and-Poincare-contract-are-preserved"]

VerificationTest[Module[{x},
  {dirichletLerchAt[1, 2, x, x], dirichletLerchAt[-1, 2, x, x],
    dirichletLerchAt[2, 2, x, x], dirichletLerchAt[x/2, 2, x, x],
    dirichletLerchAt[1/2, x, x, x], dirichletLerchAt[1/2, 2, -x, x]}],
  ConstantArray[$Failed, 6], TestID -> "dirichlet-lerch-declines-boundary-weights-varying-parameters-and-negative-ray"]

VerificationTest[Module[{x},
  MatchQ[dirichletLerchAt[1/2, -1000/3, x, x, Infinity, Automatic, 1, True, 100],
    Failure["ResourceLimit", _Association]]],
  True, TestID -> "dirichlet-lerch-remainder-moment-degree-is-resource-bounded"]

VerificationTest[Module[{x, s, t, error, upper},
  s = dirichletExpandAt[Zeta[x], x, Infinity, Automatic, 3];
  t = SeriesTruncate[s, Log[3]];
  error = N[Zeta[10] - (Normal[t] /. x -> 10), 60];
  upper = N[t["AbsoluteRemainderBound"] /. x -> 10, 60];
  {dirichletEqual[t, 1 + 2^-x, x > 1],
    TrueQ[FullSimplify[t["AbsoluteRemainderBound"] == s["AbsoluteRemainderBound"] + 3^-x, x > 1]],
    TrueQ[FullSimplify[t["TruncationDiscardedPart"] == 3^-x, x > 1]],
    t["RemainderBoundConditions"] === s["RemainderBoundConditions"],
    KeyExistsQ[t[[1]], "RemainderLowerBound"], KeyExistsQ[t[[1]], "FirstOmittedInteger"],
    t["ForwardRemainderContract"]["Type"],
    t["ForwardRemainderContract"]["OriginalContract"] === s["ForwardRemainderContract"],
    0 < error <= upper}],
  {True, True, True, True, False, False, "TransportedThroughTruncation", True, True},
  TestID -> "dirichlet-zeta-truncation-transports-the-absolute-tail-bound-and-drops-the-signed-lower-bound"]

VerificationTest[Module[{x, s, u},
  s = dirichletExpandAt[Zeta[x], x, Infinity, Automatic, 3];
  u = SeriesTruncate[s, s["Cutoff"]];
  {dirichletEqual[u, Normal[s], x > 1], u["AbsoluteRemainderBound"] === s["AbsoluteRemainderBound"],
    u["RemainderLowerBound"] === s["RemainderLowerBound"],
    u["RemainderBoundConditions"] === s["RemainderBoundConditions"],
    u["FirstOmittedInteger"] === s["FirstOmittedInteger"],
    u["ForwardRemainderContract"] === s["ForwardRemainderContract"],
    KeyExistsQ[u[[1]], "TruncationDiscardedPart"], u["SeriesRecipe"][[1]]}],
  {True, True, True, True, True, True, False, "Truncate"},
  TestID -> "dirichlet-zeta-no-op-truncation-retains-every-quantitative-bound-field"]

VerificationTest[Module[{x, l, lt, value, tail, upper},
  l = dirichletLerchAt[1/2, 2, x, x, Infinity, Automatic, 3];
  lt = SeriesTruncate[l, l["Cutoff"] - 1];
  value = 10; tail = N[Abs[LerchPhi[1/2, 2, value] - (Normal[lt] /. x -> value)], 50];
  upper = N[lt["AbsoluteRemainderBound"] /. x -> value, 50];
  {l["RemainderBoundConstant"] =!= Missing["KeyAbsent", "RemainderBoundConstant"],
    KeyExistsQ[lt[[1]], "RemainderBoundConstant"],
    TrueQ[FullSimplify[lt["AbsoluteRemainderBound"] == l["AbsoluteRemainderBound"] + Abs[lt["TruncationDiscardedPart"]], x > 1]],
    lt["RemainderBoundConditions"] === l["RemainderBoundConditions"],
    Length[lt["Blocks"]] + 1 === Length[l["Blocks"]], tail <= upper}],
  {True, False, True, True, True, True},
  TestID -> "dirichlet-lerch-truncation-transports-the-bound-without-its-constant-form"]

VerificationTest[Module[{x, v},
  v = SeriesTruncate[AsymptoticExpansion[Exp[x], {x, 0, 3}], 2];
  {Expand[Normal[v] - (1 + x)], KeyExistsQ[v[[1]], "AbsoluteRemainderBound"], KeyExistsQ[v[[1]], "TruncationDiscardedPart"]}],
  {0, False, False},
  TestID -> "ordinary-truncation-does-not-invent-a-quantitative-bound"]
