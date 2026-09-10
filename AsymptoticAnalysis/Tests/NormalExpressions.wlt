(* Normal extracts the ordinary finite expression. It must not expose the
   displayed O term, native SeriesData, or series objects retained only in
   operation recipes and refinement metadata. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

normalExpressionPlainQ[e_] := FreeQ[e,
  _GeneralizedSeries | _PowerLogRemainder | _SeriesData | _InterpretationBox | _RowBox];
normalExpressionMatches[s_, expected_, assumptions_: True] := Module[{plain},
  If[! MatchQ[s, _GeneralizedSeries], Return[False, Module]];
  plain = Normal[s];
  normalExpressionPlainQ[plain] && Normal[plain] === plain &&
    TrueQ[FullSimplify[plain == expected, assumptions]]];

VerificationTest[Module[{x, s, remainder, plain},
  s = AsymptoticExpansion[(1 + Log[x])/(1 - x), {x, 0, 3}];
  remainder = s["Remainder"]; plain = Normal[s];
  {normalExpressionMatches[s, (1 + x + x^2) (1 + Log[x]), x > 0],
    remainder =!= 0 && s["Remainder"] === remainder,
    TrueQ[FullSimplify[D[plain, x] == 1/x + 2 + 3 x + (1 + 2 x) Log[x], x > 0]]}],
  {True, True, True}, TestID -> "normal-ordered-logarithmic-expression-is-ordinary-and-differentiable"]

VerificationTest[Module[{x, s, plain},
  s = AsymptoticExpansion[Exp[x + 1/x], x -> Infinity, SeriesTermGoal -> 3];
  plain = Normal[s];
  {normalExpressionMatches[s, Exp[x] (1 + 1/x + 1/(2 x^2)), x > 0],
    s["Remainder"] =!= 0,
    TrueQ[FullSimplify[plain /. x -> 2] == 13 E^2/8]}],
  {True, True, True}, TestID -> "normal-factored-expression-keeps-the-exact-prefactor"]

VerificationTest[Module[{x, sine, cosine, product},
  sine = AsymptoticExpansion[Sin[x], {x, 0, 6}];
  cosine = AsymptoticExpansion[Cos[x], {x, 0, 6}];
  product = sine cosine;
  {normalExpressionMatches[product, x - 2 x^3/3 + 2 x^5/15],
    MatchQ[product, _GeneralizedSeries] && product["Remainder"] =!= 0,
    ! FreeQ[product[[1]], _GeneralizedSeries]}],
  {True, True, True}, TestID -> "normal-arithmetic-result-does-not-expose-series-in-its-recipe"]

VerificationTest[Module[{x, s, quotient},
  s = AsymptoticExpansion[x, {x, 0, 4}];
  quotient = SeriesNormalize[(1 + s)/(1 - s), "Cutoff" -> 4];
  {normalExpressionMatches[quotient, 1 + 2 x + 2 x^2 + 2 x^3],
    MatchQ[quotient, _GeneralizedSeries] && quotient["Remainder"] =!= 0}],
  {True, True}, TestID -> "normal-explicit-normalization-produces-an-ordinary-polynomial"]

VerificationTest[Module[{t, x, low, refined, shortened},
  low = AsymptoticInverse[ConditionalExpression[t + t^2, t > 0], {t, 0}, {x, 3}];
  refined = SeriesRefine[low, 5]; shortened = SeriesTruncate[refined, 3];
  {normalExpressionMatches[low, x - x^2],
    normalExpressionMatches[refined, x - x^2 + 2 x^3 - 5 x^4],
    normalExpressionMatches[shortened, x - x^2],
    And @@ (#["Remainder"] =!= 0 & /@ {low, refined, shortened})}],
  {True, True, True, True}, TestID -> "normal-refined-and-truncated-inverse-expressions-have-no-remainder-head"]

VerificationTest[Module[{t, x, flat, ordinary, sum, decorated},
  flat = AsymptoticFlatInverse[t + Exp[-1/t], {t, 0}, {x, 1}];
  ordinary = AsymptoticExpansion[x^2, {x, 0, 3}];
  sum = flat + ordinary;
  decorated = GeneralizedSeries[Append[sum[[1]], "NormalMetadataSentinel" ->
    <|"Operand" -> flat, "NativeJet" -> SeriesData[x, 0, {7, 11}, 0, 2, 1],
      "Error" -> PowerLogRemainder[x, 99, 0]|>]];
  {sum["Scale"] === "Composite",
    normalExpressionMatches[decorated, x + x^2 - Exp[-1/x], x > 0],
    Normal[decorated] === Normal[sum], decorated["Remainder"] =!= 0}],
  {True, True, True, True}, TestID -> "normal-composite-expression-ignores-nested-provenance-and-native-jets"]

VerificationTest[Module[{x, exact, uncertain, zero},
  exact = AsymptoticExpansion[1 + x, {x, 0, 2}];
  uncertain = AsymptoticExpansion[-1 - x + x^2, {x, 0, 2}];
  zero = exact + uncertain;
  {normalExpressionMatches[zero, 0], Normal[zero] === 0,
    MatchQ[zero, _GeneralizedSeries] && zero["Remainder"] =!= 0}],
  {True, True, True}, TestID -> "normal-cancelled-finite-expression-is-zero-while-object-retains-error"]

VerificationTest[Module[{x, s, plain, value},
  s = AsymptoticExpansion[BesselJ[0, x], x -> Infinity, SeriesTermGoal -> 2];
  plain = Normal[s]; value = N[plain /. x -> 20, 30];
  {MatchQ[s, _GeneralizedSeries] && s["Remainder"] =!= 0,
    normalExpressionPlainQ[plain] && FreeQ[plain, _BesselJ],
    Normal[plain] === plain,
    NumericQ[value] && TrueQ[Element[value, Reals]]}],
  {True, True, True, True}, TestID -> "normal-native-oscillatory-expression-has-no-structured-series-leaks"]
