(* Automatic arithmetic is checked against independent low-order Taylor
   coefficients and transported bounds. No oracle expands the displayed
   finite polynomial while discarding its unknown remainder. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

seriesArithmeticMatches[s_, expected_, power_] :=
  MatchQ[s, _GeneralizedSeries] && Expand[Normal[s] - expected] === 0 &&
    s["RemainderPower"] === power && s["Remainder"] =!= 0;

VerificationTest[Module[{x, a, b},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  b = AsymptoticExpansion[Cos[x], {x, 0, 4}];
  {seriesArithmeticMatches[a + b, 1 + x - x^2/2 - x^3/6, 4],
    seriesArithmeticMatches[a - b, -1 + x + x^2/2 - x^3/6, 4]}],
  {True, True}, TestID -> "arithmetic-add-and-subtract-retain-common-precision"]

VerificationTest[Module[{x, a, b},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  b = AsymptoticExpansion[Cos[x], {x, 0, 4}];
  {seriesArithmeticMatches[a b, x - 2 x^3/3, 5],
    seriesArithmeticMatches[a^2, x^2 - x^4/3, 6],
    seriesArithmeticMatches[1/a, 1/x + x/6, 3]}],
  {True, True, True}, TestID -> "arithmetic-products-powers-and-reciprocals-transport-valuations"]

VerificationTest[Module[{x, a, b, sums, products},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  b = AsymptoticExpansion[Cos[x], {x, 0, 4}];
  sums = {2 + a + b, b + (a + 2), (2 + b) + a};
  products = {3 a b, b (3 a), (3 b) a};
  {And @@ (seriesArithmeticMatches[#, 3 + x - x^2/2 - x^3/6, 4] & /@ sums),
    And @@ (seriesArithmeticMatches[#, 3 x - 2 x^3, 5] & /@ products)}],
  {True, True}, TestID -> "arithmetic-nary-orderless-and-grouped-expressions-agree"]

VerificationTest[Module[{x, a, quotient},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  quotient = (1 + a)/(1 - a);
  seriesArithmeticMatches[quotient,
    1 + 2 x + 2 x^2 + 5 x^3/3 + 4 x^4/3, 5]],
  True, TestID -> "arithmetic-division-of-units-retains-all-justified-coefficients"]

VerificationTest[Module[{x, positive, negative},
  positive = AsymptoticExpansion[Cos[x], {x, 0, 4}];
  negative = AsymptoticExpansion[-Cos[x], {x, 0, 4}];
  {seriesArithmeticMatches[Sqrt[positive], 1 - x^2/4, 4],
    seriesArithmeticMatches[negative^2, 1 - x^2, 4],
    FailureQ[Sqrt[negative]]}],
  {True, True, True}, TestID -> "arithmetic-fractional-powers-require-the-real-positive-branch"]

VerificationTest[Module[{x, a},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  {seriesArithmeticMatches[x a, x^2 - x^4/6, 6],
    seriesArithmeticMatches[a/x, 1 - x^2/6, 4],
    seriesArithmeticMatches[Sin[x] a, x^2 - x^4/3, 6],
    seriesArithmeticMatches[Exp[x] a, x + x^2 + x^3/3, 5]}],
  {True, True, True, True},
  TestID -> "arithmetic-exact-variable-dependent-factors-carry-their-own-local-orders"]

VerificationTest[Module[{x, c, a, result},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}, Assumptions -> Element[c, Reals]];
  result = Pi + c a;
  {seriesArithmeticMatches[result, Pi + c x - c x^3/6, 5],
    TrueQ[Simplify[result["Assumptions"], Element[c, Reals]]]}],
  {True, True}, TestID -> "arithmetic-real-symbolic-scalars-use-retained-assumptions"]

VerificationTest[Module[{x, a},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  {FailureQ[1.0 a], FailureQ[a + 1.0], FailureQ[a^1.0]}],
  {True, True, True}, TestID -> "arithmetic-inexact-inputs-fail-without-an-exactness-claim"]

VerificationTest[Module[{x, y, above, below, other},
  above = AsymptoticExpansion[Sin[x], {x, 0, 5}, Direction -> "FromAbove"];
  below = AsymptoticExpansion[Sin[x], {x, 0, 5}, Direction -> "FromBelow"];
  other = AsymptoticExpansion[Sin[y], {y, 0, 5}];
  {FailureQ[above + other], FailureQ[above other], FailureQ[above + below]}],
  {True, True, True}, TestID -> "arithmetic-rejects-different-variables-and-disjoint-one-sided-domains"]

VerificationTest[Module[{x, uncertain, exact, difference},
  uncertain = AsymptoticExpansion[Sin[x], {x, 0, 3}];
  exact = AsymptoticExpansion[x, {x, 0, 3}];
  difference = uncertain - exact;
  {seriesArithmeticMatches[difference, 0, 3],
    difference["RemainderLogDegree"] === 0}],
  {True, True}, TestID -> "arithmetic-cancelled-displayed-terms-retain-the-unknown-tail"]

VerificationTest[Module[{x, a, b, shortened, unchangedPrecision},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  b = AsymptoticExpansion[Cos[x], {x, 0, 4}];
  shortened = SeriesNormalize[a + b, "Cutoff" -> 3];
  unchangedPrecision = SeriesNormalize[a, "Cutoff" -> 9];
  {seriesArithmeticMatches[shortened, 1 + x - x^2/2, 3],
    seriesArithmeticMatches[unchangedPrecision, x - x^3/6, 5]}],
  {True, True}, TestID -> "arithmetic-normalization-cutoff-truncates-without-refining-unknown-coefficients"]

VerificationTest[Module[{x, pure},
  pure = AsymptoticExpansion[x^3, {x, 0, 2}];
  {FailureQ[1/pure], FailureQ[pure^(-2)]}],
  {True, True}, TestID -> "arithmetic-negative-powers-reject-an-unknown-leading-term"]

VerificationTest[Module[{x, a, sine, logarithm, exponential},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  sine = SeriesNormalize[Sin[a], "Cutoff" -> 5];
  logarithm = SeriesNormalize[Log[1 + a], "Cutoff" -> 5];
  exponential = SeriesNormalize[Exp[a], "Cutoff" -> 5];
  {seriesArithmeticMatches[sine, x - x^3/3, 5],
    seriesArithmeticMatches[logarithm, x - x^2/2 + x^3/6 - x^4/12, 5],
    seriesArithmeticMatches[exponential, 1 + x + x^2/2 - x^4/8, 5]}],
  {True, True, True}, TestID -> "arithmetic-explicit-normalization-composes-regular-unary-functions"]

VerificationTest[Module[{x, a, normalized},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  normalized = SeriesNormalize[Sin[a] + Log[1 + a] + Exp[a], "Cutoff" -> 4];
  seriesArithmeticMatches[normalized, 1 + 3 x - x^3/6, 4]],
  True, TestID -> "arithmetic-normalization-options-govern-the-complete-nested-expression"]

VerificationTest[Module[{x, original, normalized},
  original = AsymptoticExpansion[ConditionalExpression[Sin[x], x > 0], {x, 0, 5}];
  normalized = SeriesNormalize[original];
  {normalized === original, SeriesNormalize[normalized] === normalized,
    Normal[normalized] === x - x^3/6}],
  {True, True, True}, TestID -> "arithmetic-bare-object-normalization-is-idempotent-and-preserves-provenance"]

VerificationTest[Module[{x, a},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  {FailureQ[SeriesNormalize[a, "MaxTerms" -> 0]],
    FailureQ[SeriesNormalize[a, "MaxTerms" -> 3/2]],
    FailureQ[SeriesNormalize[a, "Cutoff" -> 2.0]]}],
  {True, True, True}, TestID -> "arithmetic-normalization-validates-options-even-for-a-bare-object"]

VerificationTest[Module[{x, f, a},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  {FailureQ[SeriesNormalize[f[a]]], FailureQ[SeriesNormalize[f[a, a]]]}],
  {True, True}, TestID -> "arithmetic-explicit-normalization-rejects-unproved-analytic-functions"]

VerificationTest[Module[{x, y, gamma, barnes, sum, expected},
  gamma = AsymptoticInverse[LogGamma[x], {x, Infinity}, y, SeriesTermGoal -> 1];
  barnes = AsymptoticInverse[LogBarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 1];
  sum = gamma + barnes;
  expected = y/ProductLog[y/E] + Sqrt[4 y/ProductLog[4 y/Exp[3]]];
  {MatchQ[sum, _GeneralizedSeries],
    TrueQ[FullSimplify[Normal[sum] == expected, y > Exp[3]]],
    sum["Remainder"] =!= 0, FreeQ[Normal[sum], _GeneralizedSeries | _PowerLogRemainder]}],
  {True, True, True, True},
  TestID -> "arithmetic-distinct-Gamma-and-Barnes-cores-keep-a-composite-finite-expression-and-bound"]

VerificationTest[Module[{x, a, refined},
  a = AsymptoticExpansion[Sin[x], {x, 0, 3}];
  refined = SeriesRefine[1 + a, 7];
  seriesArithmeticMatches[refined, 1 + x - x^3/6 + x^5/120, 7]],
  True, TestID -> "arithmetic-derived-results-retain-a-replayable-refinement-source"]

VerificationTest[Module[{x, growing, reciprocal},
  growing = AsymptoticExpansion[Exp[x + 1/x], x -> Infinity, SeriesTermGoal -> 2];
  reciprocal = 1/growing;
  {MatchQ[reciprocal, _GeneralizedSeries],
    TrueQ[FullSimplify[Normal[reciprocal] == Exp[-x] (1 - 1/x), x > 0]],
    reciprocal["RemainderPower"] === 2, reciprocal["Remainder"] =!= 0}],
  {True, True, True, True}, TestID -> "arithmetic-reciprocal-of-exponential-carrier-keeps-relative-precision"]

VerificationTest[Module[{x, exact, shifted, reciprocal},
  exact = AsymptoticExpansion[x^2 + x^3, {x, 0, 5}];
  shifted = SeriesNormalize[exact/x, "Cutoff" -> 2];
  reciprocal = SeriesNormalize[1/(1 + exact/x^2), "Cutoff" -> 5];
  {seriesArithmeticMatches[shifted, x, 2],
    seriesArithmeticMatches[reciprocal, 1/2 - x/4 + x^2/8 - x^3/16 + x^4/32, 5]}],
  {True, True}, TestID -> "arithmetic-final-cutoff-keeps-exact-input-terms-until-after-division"]

VerificationTest[Module[{x, exact, result},
  exact = AsymptoticExpansion[x, {x, 0, 2}];
  result = SeriesNormalize[1/(x^8 (1 + exact)), "Cutoff" -> 2];
  seriesArithmeticMatches[result, Sum[(-1)^k x^(k - 8), {k, 0, 9}], 2]],
  True, TestID -> "arithmetic-working-order-adapts-to-an-outer-negative-valuation-without-refining-operands"]

VerificationTest[Module[{x, pure},
  pure = AsymptoticExpansion[x^3, {x, 0, 2}];
  {FailureQ[SeriesNormalize[pure/pure]], FailureQ[SeriesNormalize[pure^0]],
    seriesArithmeticMatches[pure^2, 0, 6]}],
  {True, True, True}, TestID -> "arithmetic-held-normalizer-checks-denominators-before-native-cancellation"]

VerificationTest[Module[{x, exact, result},
  exact = AsymptoticExpansion[x, {x, 0, 2}];
  result = SeriesNormalize[1/(Exp[exact] - 1 - exact), "Cutoff" -> 3];
  seriesArithmeticMatches[result, 2/x^2 - 2/(3 x) + 1/18 + x/270 - x^2/3240, 3]],
  True, TestID -> "arithmetic-normalizer-resolves-cancellation-in-new-exact-function-expansions"]

VerificationTest[Module[{x, pure, negative, alias, exact, delayed},
  pure = AsymptoticExpansion[x^3, {x, 0, 2}];
  negative = AsymptoticExpansion[-x^3, {x, 0, 2}];
  alias := pure/pure;
  exact = AsymptoticExpansion[x, {x, 0, 2}];
  delayed := 1/(1 + exact);
  {FailureQ[SeriesNormalize[alias]], FailureQ[Sqrt[negative]],
    seriesArithmeticMatches[SeriesNormalize[delayed, "Cutoff" -> 4], 1 - x + x^2 - x^3, 4]}],
  {True, True, True}, TestID -> "arithmetic-held-symbol-aliases-preserve-denominator-and-real-branch-checks"]

VerificationTest[Module[{x, unit, sine, varying, constantBase, l = Log[2]},
  unit = AsymptoticExpansion[1 + x, {x, 0, 4}];
  sine = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  varying = SeriesNormalize[unit^x, "Cutoff" -> 5]; constantBase = 2^sine;
  {seriesArithmeticMatches[varying, 1 + x^2 - x^3/2 + 5 x^4/6, 5],
    seriesArithmeticMatches[constantBase, 1 + l x + l^2 x^2/2 + (l^3 - l) x^3/6 + (l^4/24 - l^2/6) x^4, 5]}],
  {True, True}, TestID -> "arithmetic-varying-and-series-exponents-use-real-log-exp-composition"]

VerificationTest[Module[{x, y, a, b, product, ea, eb, ra, rb},
  a = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 1}];
  b = AsymptoticFlatInverse[x + Exp[-2/x], {x, 0}, {y, 1}];
  {ea, eb} = Normal /@ {a, b};
  {ra, rb} = (# ["Remainder"] /. PowerLogRemainder[w_, p_, k_] :> w^p (1 + Abs[Log[w]])^k) & /@ {a, b};
  product = a b;
  {MatchQ[product, _GeneralizedSeries], product["Scale"] === "Composite",
    TrueQ[FullSimplify[Normal[product] == ea eb && product["RemainderScaleExpression"] == Abs[ea] rb + Abs[eb] ra + ra rb, 0 < y < 1/4]]}],
  {True, True, True}, TestID -> "arithmetic-different-flat-phases-use-a-conservative-composite-product"]

VerificationTest[Module[{x, a, normalized},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  normalized = SeriesNormalize[{a, a^2}, "Cutoff" -> 3];
  {seriesArithmeticMatches[SeriesAdd[a, Sin[x]], 2 x - x^3/3, 5],
    seriesArithmeticMatches[SeriesMultiply[a, Sin[x]], x^2 - x^4/3, 6],
    seriesArithmeticMatches[SeriesPower[a, 2], x^2 - x^4/3, 6],
    seriesArithmeticMatches[normalized[[1]], x, 3],
    seriesArithmeticMatches[normalized[[2]], x^2, 4],
    MemberQ[Attributes[SeriesNormalize], HoldAllComplete]}],
  {True, True, True, True, True, True}, TestID -> "arithmetic-explicit-operations-and-list-cutoffs-share-the-normalization-contract"]
