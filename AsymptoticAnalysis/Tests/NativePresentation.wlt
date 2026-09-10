(* Native display and variable metadata must preserve the stored contract. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[Module[{x, s, native, expected, boxes},
  native = Series[Exp[I x], {x, 0, 3}];
  s = AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
  expected = With[{value = native}, MakeBoxes[value, StandardForm]];
  boxes = With[{value = s}, MakeBoxes[value, StandardForm]];
  {Head[boxes] === InterpretationBox, First[boxes] === expected,
    FreeQ[boxes[[1]], "Missing"], MemberQ[Rest[List @@ boxes], Editable -> False]}],
  {True, True, True, True}, TestID -> "native-presentation-displays-native-order-with-readonly-interpretation"]

VerificationTest[Module[{x, s, native, expected, boxes},
  native = Series[Exp[x], {x, 0, 2}];
  s = AsymptoticExpansion[Exp[x], {x, 0, 2}, "Backend" -> "Series"];
  expected = With[{value = native}, MakeBoxes[value, TraditionalForm]];
  boxes = With[{value = s}, MakeBoxes[value, TraditionalForm]];
  Head[boxes] === InterpretationBox && First[boxes] === expected],
  True, TestID -> "native-presentation-traditional-form-retains-native-display"]

VerificationTest[Module[{counter = 0, boxes},
  boxes = MakeBoxes[GeneralizedSeries[<|"Kind" -> "Native", "NativeResult" -> (counter++; 1),
    "Expression" -> (counter++; 2), "Remainder" -> Missing["NativeContract"]|>], StandardForm];
  counter === 0 && Head[boxes] === InterpretationBox],
  True, TestID -> "native-presentation-boxing-does-not-evaluate-raw-association-payloads"]

VerificationTest[Module[{x, a, s},
  s = AsymptoticExpansion[Exp[I x], {x, 0, 2}, "Backend" -> "Series",
    Assumptions -> a > 0, Analytic -> True];
  {s["Variable"] === x, s[I/10] === 181/200,
    s["ExpansionSpecifications"] === {HoldComplete[{x, 0, 2}]} }],
  {True, True, True}, TestID -> "native-presentation-option-symbols-are-not-expansion-variables"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticExpansion[Exp[x + y], {x, 0, 2}, {y, 0, 2}, "Backend" -> "Series"];
  MatchQ[s[1/10], Failure["NativeVariables", _Association]] &&
    s["ExpansionSpecifications"] === {HoldComplete[{x, 0, 2}], HoldComplete[{y, 0, 2}]}],
  True, TestID -> "native-presentation-multivariate-numerical-application-requires-explicit-substitution"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[x], {x, 0, 2}, "Backend" -> "Series"];
  MatchQ[InverseExpansionCoefficient[s, {1}], Failure["NativeSeriesContract", _Association]]],
  True, TestID -> "native-presentation-inverse-coefficient-query-refuses-native-without-incidental-messages"]

VerificationTest[Module[{x},
  {MatchQ[AsymptoticExpansion[Exp[x], {x, 0, 2}, "Backend" -> "Series", "MaxTerms" -> 1],
      Failure["NativeOptionConflict", _Association]],
    MatchQ[AsymptoticExpansion[Exp[x], {x, 0, 2}, "Backend" -> "Series",
      "InverseFunctionBranches" -> Automatic], Failure["NativeOptionConflict", _Association]],
    MatchQ[AsymptoticExpansion[Exp[x], {x, 0, 2}, "Backend" -> "Unknown"],
      Failure["InvalidBackend", _Association]]}],
  {True, True, True}, TestID -> "native-presentation-invalid-selector-and-package-only-constraints-are-not-dropped"]
