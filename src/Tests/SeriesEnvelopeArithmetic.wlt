(* Composite fixtures specify e + O(R) directly. The expected bounds below
   follow from addition, multiplication, and first-order perturbation of a
   nonzero real base; they do not invoke another package series operation. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

seriesEnvelopeFixture[e_, r_, x_Symbol, point_: 0, direction_: "FromAbove"] :=
  GeneralizedSeries[<|"Kind" -> "Derived", "Scale" -> "Composite",
    "Expression" -> e, "Remainder" -> r, "Variable" -> x, "Assumptions" -> True,
    "TargetDomain" -> If[direction === "FromAbove", x > point, x < point],
    "SeriesApproach" -> <|"Variable" -> x, "Point" -> point, "Direction" -> direction|>|>];
seriesEnvelopeMatches[s_, expected_, bound_, assumptions_] :=
  MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[
    Normal[s] == expected && s["RemainderScaleExpression"] == bound, assumptions]];

VerificationTest[Module[{x, a, b, sum},
  a = seriesEnvelopeFixture[1 + x, PowerLogRemainder[x, 2, 0], x];
  b = seriesEnvelopeFixture[2 - x, PowerLogRemainder[x, 3, 0], x];
  sum = a + b;
  {seriesEnvelopeMatches[sum, 3, x^2 + x^3, x > 0], sum["Scale"] === "Composite",
    TrueQ[sum["TargetDomain"] /. x -> 1/2],
    (sum["TargetDomain"] /. x -> -1) === False,
    sum["MajorantContract"]["NumericCertificate"] === False}],
  {True, True, True, True, True}, TestID -> "envelope-addition-sums-errors-and-retains-the-real-domain"]

VerificationTest[Module[{x, a, b, product},
  a = seriesEnvelopeFixture[1 + x, PowerLogRemainder[x, 2, 0], x];
  b = seriesEnvelopeFixture[2 - x, PowerLogRemainder[x, 3, 0], x];
  product = a b;
  {seriesEnvelopeMatches[product, 2 + x - x^2,
      (1 + x) x^3 + (2 - x) x^2 + x^5, 0 < x < 1],
    ! FreeQ[product["Remainder"], PowerLogRemainder[x, 5, 0]],
    product["RemainderDerivativeOrder"] === 0}],
  {True, True, True}, TestID -> "envelope-product-transports-two-linear-errors-and-their-product"]

VerificationTest[Module[{x, a, b, product},
  a = seriesEnvelopeFixture[0, PowerLogRemainder[x, 2, 1], x];
  b = seriesEnvelopeFixture[0, PowerLogRemainder[x, 3, 2], x];
  product = a b;
  {seriesEnvelopeMatches[product, 0, x^5 (1 + Abs[Log[x]])^3, x > 0],
    product["Remainder"] === PowerLogRemainder[x, 5, 3]}],
  {True, True}, TestID -> "envelope-identical-coordinate-products-add-power-and-log-degree"]

VerificationTest[Module[{x, a, b, sum},
  a = seriesEnvelopeFixture[1, PowerLogRemainder[x, 2, 0], x];
  b = seriesEnvelopeFixture[x, PowerLogRemainder[x^2, 1, 0], x];
  sum = a + b;
  {seriesEnvelopeMatches[sum, 1 + x, 2 x^2, x > 0],
    ! FreeQ[sum["Remainder"], PowerLogRemainder[x, 2, 0]],
    ! FreeQ[sum["Remainder"], PowerLogRemainder[x^2, 1, 0]]}],
  {True, True, True}, TestID -> "envelope-different-positive-coordinates-share-one-target-approach"]

VerificationTest[Module[{x, y, gamma, shifted, core},
  gamma = AsymptoticInverse[LogGamma[x], {x, Infinity}, y, SeriesTermGoal -> 1];
  shifted = gamma + 1; core = y/ProductLog[y/E];
  {MatchQ[shifted, _GeneralizedSeries], shifted["Scale"] === "Composite",
    TrueQ[FullSimplify[Normal[shifted] == 1 + core, y > E]],
    shifted["Remainder"] === gamma["Remainder"],
    TrueQ[FullSimplify[shifted["TargetDomain"] == gamma["TargetDomain"]]]}],
  {True, True, True, True, True}, TestID -> "envelope-inverse-Gamma-plus-an-exact-constant-preserves-its-error"]

VerificationTest[Module[{x, y, flat, ordinary, sum},
  flat = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 1}];
  ordinary = AsymptoticExpansion[y^2, {y, 0, 3}];
  sum = flat + ordinary;
  {seriesEnvelopeMatches[sum, y + y^2 - Exp[-1/y], Exp[-2/y]/y^2, y > 0],
    sum["Scale"] === "Composite", sum["Remainder"] =!= 0}],
  {True, True, True}, TestID -> "envelope-flat-and-ordinary-series-retain-the-complete-flat-tail"]

VerificationTest[Module[{x, above, below, shifted},
  above = seriesEnvelopeFixture[1, PowerLogRemainder[x, 2, 0], x];
  below = seriesEnvelopeFixture[1, PowerLogRemainder[-x, 2, 0], x, 0, "FromBelow"];
  shifted = seriesEnvelopeFixture[1, PowerLogRemainder[x - 1, 2, 0], x, 1];
  {FailureQ[above + below], FailureQ[above below], FailureQ[above + shifted]}],
  {True, True, True}, TestID -> "envelope-rejects-opposite-sides-and-different-target-endpoints"]

VerificationTest[Module[{x, a, product},
  a = seriesEnvelopeFixture[2 + x, PowerLogRemainder[x, 2, 0], x];
  product = a ConditionalExpression[Sqrt[1 - x], 0 < x < 1];
  {seriesEnvelopeMatches[product, (2 + x) Sqrt[1 - x], x^2 Sqrt[1 - x], 0 < x < 1],
    TrueQ[product["TargetDomain"] /. x -> 1/2],
    (product["TargetDomain"] /. x -> 2) === False,
    (product["TargetDomain"] /. x -> -1) === False}],
  {True, True, True, True}, TestID -> "envelope-eventually-real-scalar-functions-retain-their-conditions"]

VerificationTest[Module[{x, a, b, cancelled},
  a = seriesEnvelopeFixture[1 + x, PowerLogRemainder[x, 2, 0], x];
  b = seriesEnvelopeFixture[-1 - x, PowerLogRemainder[x, 3, 0], x];
  cancelled = a + b;
  {seriesEnvelopeMatches[cancelled, 0, x^2 + x^3, x > 0],
    cancelled["Remainder"] =!= 0, cancelled["Exact"] === False}],
  {True, True, True}, TestID -> "envelope-cancellation-of-finite-expressions-does-not-cancel-independent-errors"]

VerificationTest[Module[{x, a, cube, reciprocal, root},
  a = seriesEnvelopeFixture[2 + x, PowerLogRemainder[x, 2, 0], x];
  cube = a^3; reciprocal = 1/a; root = Sqrt[a];
  {seriesEnvelopeMatches[cube, (2 + x)^3, 3 (2 + x)^2 x^2 + 3 (2 + x) x^4 + x^6, x > 0],
    seriesEnvelopeMatches[reciprocal, 1/(2 + x), x^2/(2 + x)^2, x > 0],
    seriesEnvelopeMatches[root, Sqrt[2 + x], x^2/Sqrt[2 + x], x > 0]}],
  {True, True, True}, TestID -> "envelope-fixed-real-powers-transport-a-proved-small-relative-error"]

VerificationTest[Module[{x, negative, inverseSquare},
  negative = seriesEnvelopeFixture[-2 - x, PowerLogRemainder[x, 2, 0], x];
  inverseSquare = negative^(-2);
  {seriesEnvelopeMatches[inverseSquare, 1/(2 + x)^2, x^2/(2 + x)^3, x > 0],
    FailureQ[Sqrt[negative]], FailureQ[negative^(-1/2)]}],
  {True, True, True}, TestID -> "envelope-negative-real-base-allows-integer-but-not-fractional-powers"]

VerificationTest[Module[{x, unresolved, pure},
  unresolved = seriesEnvelopeFixture[x, PowerLogRemainder[x, 1, 0], x];
  pure = seriesEnvelopeFixture[0, PowerLogRemainder[x, 2, 0], x];
  {FailureQ[1/unresolved], FailureQ[Sqrt[unresolved]],
    FailureQ[1/pure], FailureQ[pure^(-1/2)]}],
  {True, True, True, True}, TestID -> "envelope-powers-reject-an-unproved-relative-error-or-leading-term"]

VerificationTest[Module[{x, pure, squared},
  pure = seriesEnvelopeFixture[0, PowerLogRemainder[x, 2, 1], x];
  squared = pure^2;
  seriesEnvelopeMatches[squared, 0, x^4 (1 + Abs[Log[x]])^2, x > 0]],
  True, TestID -> "envelope-positive-integer-powers-admit-a-pure-remainder"]

VerificationTest[Module[{x, a},
  a = seriesEnvelopeFixture[1 + x, PowerLogRemainder[x, 2, 0], x];
  {MatchQ[SeriesNormalize[a + 1, "Cutoff" -> 3], Failure["UnsupportedCompositeCutoff", _]],
    MatchQ[SeriesPower[a, 2, "Cutoff" -> 3], Failure["UnsupportedCompositeCutoff", _]],
    MatchQ[SeriesNormalize[a + 1], _GeneralizedSeries]}],
  {True, True, True}, TestID -> "envelope-explicit-single-exponent-cutoffs-are-rejected"]

VerificationTest[Module[{x, ordinary, composite, sum},
  ordinary = SeriesAdd[AsymptoticExpansion[Sin[x], {x, 0, 3}], 1];
  composite = seriesEnvelopeFixture[2, PowerLogRemainder[x, 2, 0], x];
  sum = ordinary + composite;
  {AssociationQ[ordinary["SeriesRepresentation"]],
    seriesEnvelopeMatches[sum, 3 + x, x^2 + x^3, x > 0],
    sum["SeriesApproach"]["Point"] === 0,
    sum["SeriesApproach"]["Direction"] === "FromAbove"}],
  {True, True, True, True}, TestID -> "envelope-recovers-a-derived-ordinary-series-target-from-its-coordinate"]

VerificationTest[Module[{x, zero, constant, unknown, squared, reciprocal, annihilated},
  zero = seriesEnvelopeFixture[0, 0, x]; constant = seriesEnvelopeFixture[2, 0, x];
  unknown = seriesEnvelopeFixture[1 + x, PowerLogRemainder[x, 2, 0], x];
  squared = zero^2; reciprocal = 1/constant; annihilated = SeriesNormalize[0 unknown];
  {seriesEnvelopeMatches[squared, 0, 0, x > 0], squared["Exact"] === True,
    seriesEnvelopeMatches[reciprocal, 1/2, 0, x > 0],
    seriesEnvelopeMatches[annihilated, 0, 0, x > 0],
    TrueQ[annihilated["TargetDomain"] /. x -> 1],
    (annihilated["TargetDomain"] /. x -> -1) === False,
    FailureQ[SeriesNormalize[zero^0]], FailureQ[1/zero]}],
  {True, True, True, True, True, True, True, True},
  TestID -> "envelope-exact-zero-and-constant-arithmetic-keep-domain-and-indeterminacy"]

VerificationTest[Module[{x, a},
  a = seriesEnvelopeFixture[1 + x, PowerLogRemainder[x, 2, 0], x];
  {FailureQ[a I], FailureQ[a 1.0],
    FailureQ[a ConditionalExpression[x, x < 0]],
    MatchQ[SeriesNormalize[a a, "MaxTerms" -> 1], Failure["ResourceLimit", _]]}],
  {True, True, True, True}, TestID -> "envelope-invalid-scalars-domains-and-resource-budgets-do-not-pass-through"]
