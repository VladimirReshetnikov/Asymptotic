(* Exact identity checks use closed low-order formulas, not an asymptotic
   approximation as an oracle. The subdominant exponential is checked too. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

specialIdentityNormalizeAt[f_, x_, point_: Infinity, ass_: True] :=
  AsymptoticInverse`Private`specialFunctionNormalize[f, x,
    AsymptoticInverse`Private`localCoordinate[x, point, Automatic], ass, 20000];
specialIdentityEqual[result_, expected_, ass_] := AssociationQ[result] &&
  TrueQ[FullSimplify[result["Expression"] == expected, ass]];

VerificationTest[Module[{x, orders, actual, expected},
  orders = {1/2, -1/2, 3/2, -3/2};
  actual = AsymptoticInverse`Private`specialFunctionHalfBessel[BesselI, #, x, 20000] & /@ orders;
  expected = {Exp[x] - Exp[-x], Exp[x] + Exp[-x],
    Exp[x] (1 - 1/x) + Exp[-x] (1 + 1/x),
    Exp[x] (1 - 1/x) - Exp[-x] (1 + 1/x)}/Sqrt[2 Pi x];
  And @@ MapThread[TrueQ[FullSimplify[#1 == #2, x > 0]] &, {actual, expected}]],
  True, TestID -> "identities-half-integer-Bessel-I-preserves-both-exponentials-and-negative-orders"]

VerificationTest[Module[{x, actual, expected},
  actual = AsymptoticInverse`Private`specialFunctionHalfBessel[BesselK, #, x, 20000] & /@ {3/2, -3/2, 5/2};
  expected = Sqrt[Pi/(2 x)] Exp[-x] {1 + 1/x, 1 + 1/x, 1 + 3/x + 3/x^2};
  And @@ MapThread[TrueQ[FullSimplify[#1 == #2, x > 0]] &, {actual, expected}]],
  True, TestID -> "identities-half-integer-Bessel-K-is-an-exact-finite-exponential-polynomial"]

VerificationTest[Module[{x, s, c, bessel},
  s = specialIdentityNormalizeAt[Sinh[x], x]; c = specialIdentityNormalizeAt[Cosh[x], x];
  bessel = specialIdentityNormalizeAt[BesselI[3/2, 3 x + 1], x];
  {specialIdentityEqual[s, (Exp[x] - Exp[-x])/2, x > 0],
    specialIdentityEqual[c, (Exp[x] + Exp[-x])/2, x > 0],
    s["Changed"], c["Changed"], FreeQ[{s["Expression"], c["Expression"], bessel["Expression"]}, _Sinh | _Cosh | _BesselI],
    specialIdentityEqual[bessel,
      (Exp[3 x + 1] (1 - 1/(3 x + 1)) + Exp[-3 x - 1] (1 + 1/(3 x + 1)))/Sqrt[2 Pi (3 x + 1)], x > 0]}],
  {True, True, True, True, True, True},
  TestID -> "identities-normalize-native-hyperbolic-evaluation-of-half-integer-Bessel-I"]

VerificationTest[Module[{x, result},
  result = specialIdentityNormalizeAt[Exp[-x] Sinh[x], x];
  {specialIdentityEqual[result, (1 - Exp[-2 x])/2, x > 0],
    ! FreeQ[result["Expression"], Power[E, -x] | Power[E, -2 x]], result["Changed"]}],
  {True, True, True}, TestID -> "identities-exponential-cancellation-retains-the-smaller-exact-sector"]

VerificationTest[Module[{x, one, two, general},
  one = AsymptoticInverse`Private`specialFunctionTerminatingHypergeometric[{-2}, {3}, x, False, True, 20000];
  two = AsymptoticInverse`Private`specialFunctionTerminatingHypergeometric[{-2, 3}, {5}, x, False, True, 20000];
  general = AsymptoticInverse`Private`specialFunctionTerminatingHypergeometric[{-2, 3}, {5, 7}, x, False, True, 20000];
  {specialIdentityEqual[one, 1 - 2 x/3 + x^2/12, True],
    specialIdentityEqual[two, 1 - 6 x/5 + 2 x^2/5, True],
    specialIdentityEqual[general, 1 - 6 x/35 + x^2/140, True]}],
  {True, True, True}, TestID -> "identities-terminating-hypergeometric-defining-sums"]

VerificationTest[Module[{x, regularized, ordinary},
  regularized = AsymptoticInverse`Private`specialFunctionTerminatingHypergeometric[{-2}, {0}, x, True, True, 20000];
  ordinary = AsymptoticInverse`Private`specialFunctionTerminatingHypergeometric[{-2}, {0}, x, False, True, 20000];
  {specialIdentityEqual[regularized, x^2 - 2 x, True], ordinary === $Failed}],
  {True, True}, TestID -> "identities-regularized-parameters-use-reciprocal-Gamma-and-ordinary-poles-are-rejected"]

VerificationTest[Module[{x, b, unproved, proved},
  unproved = AsymptoticInverse`Private`specialFunctionTerminatingHypergeometric[{-1}, {b}, x, False, True, 20000];
  proved = AsymptoticInverse`Private`specialFunctionTerminatingHypergeometric[{-1}, {b}, x, False, b > 0, 20000];
  {unproved === $Failed, specialIdentityEqual[proved, 1 - x/b, b > 0],
    TrueQ[FullSimplify[proved["Domain"], b > 0]]}],
  {True, True, True}, TestID -> "identities-symbolic-denominator-parameters-require-proved-pole-exclusion"]

VerificationTest[Module[{x, b, a, polynomial, power},
  polynomial = specialIdentityNormalizeAt[HypergeometricU[-2, b, x], x, Infinity, Element[b, Reals]];
  power = specialIdentityNormalizeAt[HypergeometricU[a, a + 1, x], x, Infinity, a > 0];
  {specialIdentityEqual[polynomial, x^2 - 2 (b + 1) x + b (b + 1), x > 0 && Element[b, Reals]],
    specialIdentityEqual[power, x^(-a), x > 0 && a > 0]}],
  {True, True}, TestID -> "identities-Tricomi-polynomial-and-exact-power-cases"]

VerificationTest[Module[{x, results, expected},
  results = specialIdentityNormalizeAt[Hypergeometric1F1[#, # + 1, x], x] & /@ {1, 2, 3};
  expected = {(Exp[x] - 1)/x, 2 (Exp[x] (x - 1) + 1)/x^2,
    (3 Exp[x] (x^2 - 2 x + 2) - 6)/x^3};
  And @@ MapThread[specialIdentityEqual[#1, #2, x > 0] &, {results, expected}]],
  True, TestID -> "identities-Kummer-integer-integrals-keep-the-endpoint-contribution"]

VerificationTest[Module[{x, a, b, exponential, power, logarithm},
  exponential = specialIdentityNormalizeAt[Hypergeometric1F1[a, a, x], x, Infinity, a > 0];
  power = specialIdentityNormalizeAt[Hypergeometric2F1[a, b, a, -x], x, Infinity, a > 0 && b > 0];
  logarithm = specialIdentityNormalizeAt[Hypergeometric2F1[1, 1, 2, -x], x];
  {specialIdentityEqual[exponential, Exp[x], x > 0 && a > 0],
    specialIdentityEqual[power, (1 + x)^(-b), x > 0 && a > 0 && b > 0],
    specialIdentityEqual[logarithm, Log[1 + x]/x, x > 0]}],
  {True, True, True}, TestID -> "identities-Kummer-and-Gauss-elementary-cases-on-the-real-branch"]

VerificationTest[Module[{x, gamma, integral},
  gamma = specialIdentityNormalizeAt[Gamma[4, x], x];
  integral = specialIdentityNormalizeAt[ExpIntegralE[-2, x], x];
  {specialIdentityEqual[gamma, Exp[-x] (x^3 + 3 x^2 + 6 x + 6), x > 0],
    specialIdentityEqual[integral, Exp[-x] (1/x + 2/x^2 + 2/x^3), x > 0]}],
  {True, True}, TestID -> "identities-integer-incomplete-Gamma-and-exponential-integral-finite-sums"]

VerificationTest[Module[{x, exponentialIntegral, erf, erfc, erfi},
  exponentialIntegral = specialIdentityNormalizeAt[ExpIntegralEi[-x], x];
  erf = specialIdentityNormalizeAt[Erf[-x], x];
  erfc = specialIdentityNormalizeAt[Erfc[-x], x];
  erfi = specialIdentityNormalizeAt[Erfi[-x], x];
  {specialIdentityEqual[exponentialIntegral, -ExpIntegralE[1, x], x > 0],
    specialIdentityEqual[erf, -Erf[x], x > 0], specialIdentityEqual[erfc, 2 - Erfc[x], x > 0],
    specialIdentityEqual[erfi, -Erfi[x], x > 0]}],
  {True, True, True, True}, TestID -> "identities-reflected-real-error-and-exponential-integral-branches"]

VerificationTest[Module[{x, held, bound, conditional, results},
  held = HoldComplete[Erfc[-x], BesselI[1/2, x], Sinh[x]];
  bound = Function[{x}, Sinh[x]];
  conditional = ConditionalExpression[Sinh[x], x > 1];
  results = specialIdentityNormalizeAt[#, x] & /@ {held, bound, conditional};
  {results[[1]]["Expression"] === held, results[[2]]["Expression"] === bound,
    results[[3]]["Expression"] === conditional, And @@ (! #["Changed"] & /@ results)}],
  {True, True, True, True}, TestID -> "identities-respect-held-bound-and-conditional-subexpressions"]

VerificationTest[Module[{x, source, result},
  source = HypergeometricU[1/3, 5/4, -x]; result = specialIdentityNormalizeAt[source, x];
  {result["Expression"] === source, result["Domain"] === True,
    result["Changed"] === False, result["References"] === {}}],
  {True, True, True, True}, TestID -> "identities-unsupported-negative-branch-remains-unchanged"]

VerificationTest[Module[{x, oversized, invalid},
  oversized = AsymptoticInverse`Private`specialFunctionHalfBessel[BesselI, 101/2, x, 20000];
  invalid = AsymptoticInverse`Private`catch[AsymptoticInverse`Private`specialFunctionNormalize[Sinh[x], x,
    AsymptoticInverse`Private`localCoordinate[x, Infinity, Automatic], True, 0]];
  {oversized === $Failed, MatchQ[invalid, Failure["InvalidOption", _]]}],
  {True, True}, TestID -> "identities-bounded-orders-and-resource-option-validation"]
