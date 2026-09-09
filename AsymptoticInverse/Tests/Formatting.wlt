(* Formatting is checked by semantic box/text roundtrips, not snapshots of
   an implementation-specific RowBox tree. Visible precedence is checked
   separately, after removing hidden interpretations and HoldForm tags. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

formattingForms = {StandardForm, TraditionalForm};
(* Evaluated fixtures are compared in canonical form: box parsers may retain
   an unevaluated factor of 1 or use a different order for displayed sums. *)
formattingRoundTrip[value_, form_] := With[{expected = value},
  ToExpression[ToBoxes[expected, form], form] === expected];
formattingInputTextRoundTrip[value_] := With[{expected = value},
  ToExpression[ToString[expected, InputForm, PageWidth -> Infinity], InputForm] === expected];
formattingInputBoxesRoundTrip[value_] := With[{expected = value},
  ToExpression[ToBoxes[InputForm[expected]], StandardForm] === expected];
formattingVisibleBoxes[boxes_] := boxes //. {
  InterpretationBox[display_, _, ___] :> display,
  TagBox[display_, HoldForm, ___] :> display};
formattingVisibleHeld[value_, form_] :=
  ToExpression[formattingVisibleBoxes[ToBoxes[value, form]], form, HoldComplete];
formattingVisibleExpression[value_, form_] :=
  ToExpression[formattingVisibleBoxes[ToBoxes[value, form]], form];
formattingNoVisibleHead[value_, form_] :=
  FreeQ[formattingVisibleBoxes[ToBoxes[value, form]],
    text_String /; StringContainsQ[text, "GeneralizedSeries"]];
formattingReadOnlyInterpretation[value_, form_] := Module[{boxes = ToBoxes[value, form]},
  ! FreeQ[boxes, InterpretationBox[_, _GeneralizedSeries, ___, Editable -> False, ___]] &&
    FreeQ[boxes, InterpretationBox[_, _GeneralizedSeries, ___, Editable -> True, ___]]];

VerificationTest[Module[{x, y, original, s},
  original = AsymptoticInverse[ConditionalExpression[x + x^2, x > 0], {x, 0}, {y, 3}];
  s = GeneralizedSeries[Append[original[[1]], "FormattingSentinel" ->
    <|"RetainedCondition" -> HoldComplete[x > 0], "OpaquePayload" -> {17/23, "branch provenance"}|>]];
  {formattingRoundTrip[s, StandardForm], formattingNoVisibleHead[s, StandardForm],
    formattingReadOnlyInterpretation[s, StandardForm], Normal[s] === Normal[original],
    FreeQ[Normal[s], _GeneralizedSeries | _PowerLogRemainder]}],
  {True, True, True, True, True},
  TestID -> "formatting-standard-roundtrip-preserves-entire-conditional-inverse-and-extra-metadata"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticInverse[LogBarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 2];
  {formattingRoundTrip[s, TraditionalForm], formattingNoVisibleHead[s, TraditionalForm],
    formattingReadOnlyInterpretation[s, TraditionalForm],
    s["Kind"] === "BarnesGInverse", FreeQ[Normal[s], _GeneralizedSeries | _PowerLogRemainder]}],
  {True, True, True, True, True},
  TestID -> "formatting-traditional-roundtrip-preserves-Lambert-core-and-inverse-log-metadata"]

VerificationTest[Module[{x, s, text},
  s = GeneralizedSeries[<|"Expression" -> x - x^2,
    "Remainder" -> Exp[-1/x] PowerLogRemainder[x, -2, 1],
    "FormattingSentinel" -> <|"Condition" -> HoldComplete[0 < x < 1],
      "Payload" -> {17/23, "retain this metadata"}|>|>];
  text = ToString[s, OutputForm, PageWidth -> Infinity];
  {formattingInputTextRoundTrip[s], formattingInputBoxesRoundTrip[s],
    StringContainsQ[text, "GeneralizedSeries"], StringFreeQ[text, "FormattingSentinel"]}],
  {True, True, True, True},
  TestID -> "formatting-input-text-and-boxes-are-lossless-while-output-form-stays-compact"]

VerificationTest[Module[{x, plain, logarithmic},
  plain = PowerLogRemainder[x, 3, 0]; logarithmic = PowerLogRemainder[1/x, 4, 2];
  {And @@ Flatten[Table[formattingRoundTrip[r, form],
      {r, {plain, logarithmic}}, {form, formattingForms}]],
    formattingInputTextRoundTrip[plain], formattingInputBoxesRoundTrip[logarithmic],
    formattingVisibleHeld[plain, StandardForm] === HoldComplete[O[x^3]],
    formattingVisibleHeld[logarithmic, StandardForm] ===
      HoldComplete[O[(1 + Abs[Log[x]])^2/x^4]]}],
  {True, True, True, True, True},
  TestID -> "formatting-standalone-remainders-keep-inert-meaning-and-display-correct-big-O-scales"]

VerificationTest[Module[{x, polynomial, zero},
  polynomial = AsymptoticExpansion[1 + x, {x, 0, 2}];
  zero = AsymptoticExpansion[0, {x, 0, 2}];
  {And @@ (formattingRoundTrip[polynomial, #] & /@ formattingForms),
    And @@ (formattingRoundTrip[zero, #] & /@ formattingForms),
    And @@ (formattingVisibleExpression[polynomial, #] === 1 + x & /@ formattingForms),
    And @@ (formattingVisibleExpression[zero, #] === 0 & /@ formattingForms),
    Normal[polynomial] === 1 + x, Normal[zero] === 0,
    polynomial["Remainder"] === 0 && zero["Remainder"] === 0}],
  {True, True, True, True, True, True, True},
  TestID -> "formatting-exact-polynomial-and-zero-hide-wrapper-without-inventing-remainder"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[x^3, {x, 0, 2}];
  {Normal[s] === 0, s["Remainder"] =!= 0,
    And @@ (formattingRoundTrip[s, #] & /@ formattingForms),
    And @@ (formattingVisibleHeld[s, #] === HoldComplete[O[x^3]] & /@ formattingForms)}],
  {True, True, True, True},
  TestID -> "formatting-pure-remainder-displays-only-big-O-and-Normal-returns-zero"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[x + 1/x], x -> Infinity, SeriesTermGoal -> 2];
  {And @@ (formattingRoundTrip[s, #] & /@ formattingForms),
    And @@ (formattingNoVisibleHead[s, #] & /@ formattingForms),
    formattingInputTextRoundTrip[s],
    TrueQ[FullSimplify[Normal[s] == Exp[x] (1 + 1/x), x > 0]],
    FreeQ[Normal[s], _GeneralizedSeries | _PowerLogRemainder]}],
  {True, True, True, True, True},
  TestID -> "formatting-factored-exponential-keeps-carrier-remainder-and-full-interpretation"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, 2}];
  {And @@ (formattingRoundTrip[s, #] & /@ formattingForms),
    And @@ (formattingNoVisibleHead[s, #] & /@ formattingForms),
    formattingInputTextRoundTrip[s], s["Scale"] === "ReciprocalLogUnit",
    FreeQ[Normal[s], _GeneralizedSeries | _PowerLogRemainder]}],
  {True, True, True, True, True},
  TestID -> "formatting-reciprocal-logarithmic-scale-keeps-its-complete-series-object"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 1}];
  {And @@ (formattingRoundTrip[s, #] & /@ formattingForms),
    And @@ (formattingNoVisibleHead[s, #] & /@ formattingForms),
    formattingInputTextRoundTrip[s], s["Scale"] === "FiniteFlatSectors",
    TrueQ[FullSimplify[Normal[s] == y - Exp[-1/y], y > 0]],
    FreeQ[Normal[s], _GeneralizedSeries | _PowerLogRemainder]}],
  {True, True, True, True, True, True},
  TestID -> "formatting-flat-sector-scale-preserves-exponential-tail-and-provenance"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticLogarithmicInverse[x + x^2 Log[-Log[x]], {x, 0}, {y, 3}];
  {And @@ (formattingRoundTrip[s, #] & /@ formattingForms),
    And @@ (formattingNoVisibleHead[s, #] & /@ formattingForms),
    formattingInputTextRoundTrip[s], s["LogarithmicLevels"] === 2,
    TrueQ[FullSimplify[Normal[s] == y - y^2 Log[-Log[y]], 0 < y < Exp[-E]]]}],
  {True, True, True, True, True},
  TestID -> "formatting-nested-logarithmic-hierarchy-preserves-coefficients-and-remainder-metadata"]

VerificationTest[Module[{x, s},
  s = GeneralizedSeries[<|"Expression" -> 1 + x, "Remainder" -> 0,
    "FormattingSentinel" -> "exact additive value"|>];
  {And @@ (formattingRoundTrip[s^2, #] & /@ formattingForms),
    And @@ (formattingRoundTrip[2 s, #] & /@ formattingForms),
    And @@ (formattingVisibleExpression[s^2, #] === (1 + x)^2 & /@ formattingForms),
    And @@ (formattingVisibleExpression[2 s, #] === 2 (1 + x) & /@ formattingForms)}],
  {True, True, True, True},
  TestID -> "formatting-visible-additive-base-retains-parentheses-under-power-and-multiplication"]

VerificationTest[Module[{x, f, s},
  s = GeneralizedSeries[<|"Expression" -> 1 + x, "Remainder" -> 0|>];
  {And @@ (formattingRoundTrip[1/s, #] & /@ formattingForms),
    And @@ (formattingRoundTrip[-s, #] & /@ formattingForms),
    And @@ (formattingRoundTrip[f[s], #] & /@ formattingForms),
    And @@ (formattingVisibleExpression[1/s, #] === 1/(1 + x) & /@ formattingForms),
    And @@ (formattingVisibleExpression[-s, #] === -(1 + x) & /@ formattingForms),
    formattingVisibleExpression[f[s], StandardForm] === f[1 + x]}],
  {True, True, True, True, True, True},
  TestID -> "formatting-visible-reciprocal-negation-and-function-argument-preserve-grouping"]

VerificationTest[Module[{x, counter = 0, standard, traditional, remainderStandard, remainderTraditional},
  (* MakeBoxes itself holds its input. Formatting must not turn extraction
     of either visible or hidden fields into evaluation of that raw input. *)
  standard = MakeBoxes[GeneralizedSeries[<|
    "Expression" -> (counter++; x),
    "Remainder" -> PowerLogRemainder[(counter++; x), 3, 0],
    "HiddenMetadata" -> (counter++; "sentinel")|>], StandardForm];
  traditional = MakeBoxes[GeneralizedSeries[<|
    "Expression" -> (counter++; x),
    "Remainder" -> PowerLogRemainder[(counter++; x), 3, 0],
    "HiddenMetadata" -> (counter++; "sentinel")|>], TraditionalForm];
  remainderStandard = MakeBoxes[PowerLogRemainder[(counter++; x), 3, 0], StandardForm];
  remainderTraditional = MakeBoxes[PowerLogRemainder[(counter++; x), 3, 0], TraditionalForm];
  counter],
  0,
  TestID -> "formatting-raw-MakeBoxes-does-not-evaluate-visible-fields-remainder-coordinate-or-hidden-metadata"]
