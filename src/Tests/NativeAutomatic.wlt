(* Automatic keeps successful package contracts and admits native-only inputs
   with an explicit native result contract. Direct built-in calls are the
   independent oracle for native order, options, and unresolved expressions. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

nativeAutomaticQ[s_, expected_, backend_] := MatchQ[s, _GeneralizedSeries] &&
  s["Kind"] === "Native" && s["NativeBackend"] === backend &&
  s["NativeResult"] === expected && Normal[s] === Normal[expected] &&
  s["BackendSelection"] === Automatic && s["OrderConvention"] === "Native" &&
  s["RemainderContract"] === If[backend === "Series", "NativeFormalOrder", "NativeAsymptotic"] &&
  s["Exact"] === Missing["NotEstablished"];

VerificationTest[
  Module[{x, automatic, package, counted},
    automatic = AsymptoticExpansion[Exp[x], {x, 0, 3}];
    package = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Package"];
    counted = AsymptoticExpansion[Sin[x], x -> 0, SeriesTermGoal -> 3];
    MatchQ[automatic, _GeneralizedSeries] && automatic["Kind"] =!= "Native" &&
      Normal[automatic] === 1 + x + x^2/2 &&
      Normal[automatic] === Normal[package] &&
      automatic["Remainder"] === package["Remainder"] &&
      counted["Kind"] =!= "Native" && Normal[counted] === x - x^3/6 + x^5/120 &&
      counted["RemainderPower"] === 7],
  True, TestID -> "native-automatic-preserves-exclusive-cutoff-and-nonzero-block-goal"]

VerificationTest[
  Module[{x, native, s},
    native = Series[Exp[I x], {x, 0, 3}];
    s = AsymptoticExpansion[Exp[I x], {x, 0, 3}];
    nativeAutomaticQ[s, native, "Series"] &&
      Normal[s] === 1 + I x - x^2/2 - I x^3/6 &&
      s["BackendSelectionReason"] === "PackageRepresentation" &&
      MatchQ[s["PackageFailure"], Failure["InexactInput", _Association]]],
  True, TestID -> "native-automatic-complex-source-fallback-retains-native-inclusive-order"]

VerificationTest[
  Module[{x, native, s},
    native = Series[Sin[2.5 x], {x, 0, 3}];
    s = AsymptoticExpansion[Sin[2.5 x], {x, 0, 3}];
    nativeAutomaticQ[s, native, "Series"] && ! FreeQ[Normal[s], _Real]],
  True, TestID -> "native-automatic-approximate-source-has-native-contract"]

VerificationTest[
  Module[{x, a, native, s, strict},
    native = Series[a + Exp[x], {x, 0, 2}, Assumptions -> True];
    s = AsymptoticExpansion[a + Exp[x], {x, 0, 2}, Assumptions -> True];
    strict = AsymptoticExpansion[a + Exp[x], {x, 0, 2},
      "Backend" -> "Package", Assumptions -> True];
    nativeAutomaticQ[s, native, "Series"] &&
      MatchQ[strict, Failure["UnprovedRealCoefficient", _Association]] &&
      MatchQ[s["PackageFailure"], Failure["UnprovedRealCoefficient", _Association]]],
  True, TestID -> "native-automatic-formal-parameter-does-not-acquire-package-realness-proof"]

VerificationTest[
  Module[{x, a, native, s},
    native = Series[Log[-a] + Exp[x], {x, 0, 2}, Assumptions -> a > 0];
    s = AsymptoticExpansion[Log[-a] + Exp[x], {x, 0, 2}, Assumptions -> a > 0];
    nativeAutomaticQ[s, native, "Series"] &&
      s["PackageFailure"][[2]]["Realness"] === "Nonreal"],
  True, TestID -> "native-automatic-nonreal-complete-coefficient-remains-inspectable"]

VerificationTest[
  Module[{x, native, s},
    native = Series[ArcSin[2 + x], {x, 0, 2}];
    s = AsymptoticExpansion[ArcSin[2 + x], {x, 0, 2}];
    nativeAutomaticQ[s, native, "Series"] &&
      MatchQ[s["PackageFailure"], Failure["UnprovedRealCoefficient", _Association]]],
  True, TestID -> "native-automatic-native-complex-taylor-branch-is-not-an-analytic-package-result"]

VerificationTest[
  Module[{x, a, native, s},
    And @@ Table[
      native = Series[Exp[x], {x, center, 2}, Assumptions -> True];
      s = AsymptoticExpansion[Exp[x], {x, center, 2}, Assumptions -> True];
      nativeAutomaticQ[s, native, "Series"],
      {center, {I, a, 0.25}}]],
  True, TestID -> "native-automatic-complex-symbolic-and-approximate-centers-use-native-specifications"]

VerificationTest[
  Module[{x, y, native, s},
    native = Series[Exp[x + y], {x, 0, 2}, {y, 0, 2}];
    s = AsymptoticExpansion[Exp[x + y], {x, 0, 2}, {y, 0, 2}];
    nativeAutomaticQ[s, native, "Series"] &&
      FreeQ[Normal[s], _SeriesData | _GeneralizedSeries | _PowerLogRemainder] &&
      Expand[Normal[s]] === Expand[(1 + x + x^2/2) (1 + y + y^2/2)]],
  True, TestID -> "native-automatic-successive-specifications-preserve-nested-native-series"]

VerificationTest[
  Module[{x, native, s},
    native = Series[{{Sin[x], Cos[x]}, {Exp[x], 1/(1 - x)}}, {x, 0, 2}];
    s = AsymptoticExpansion[{{Sin[x], Cos[x]}, {Exp[x], 1/(1 - x)}}, {x, 0, 2}];
    nativeAutomaticQ[s, native, "Series"] && Dimensions[Normal[s]] === {2, 2}],
  True, TestID -> "native-automatic-matrix-source-retains-native-shape"]

VerificationTest[
  Module[{x, f, native, s},
    native = Series[f[x] Exp[x], {x, 0, 2}, Analytic -> True];
    s = AsymptoticExpansion[f[x] Exp[x], {x, 0, 2}, Analytic -> True];
    nativeAutomaticQ[s, native, "Series"] &&
      s["BackendSelectionReason"] === "NativeOptions" && s["PackageFailure"] === None],
  True, TestID -> "native-automatic-explicit-formal-analytic-option-is-not-silently-ignored"]

VerificationTest[
  Quiet[Module[{x, f, native, s},
    native = Series[f[Log[x]] Exp[x], {x, 0, 2}, Analytic -> False];
    s = AsymptoticExpansion[f[Log[x]] Exp[x], {x, 0, 2}, Analytic -> False];
    nativeAutomaticQ[s, native, "Series"] && ! FreeQ[s["NativeResult"], f] &&
      s["NativeEvaluationStatus"] ===
        If[FreeQ[native, _Series | _Asymptotic], "Computed", "Unresolved"]]],
  True, TestID -> "native-automatic-strict-native-analytic-output-is-preserved-even-if-unresolved"]

VerificationTest[
  Module[{x, native, s, alias},
    native = Asymptotic[Sin[x], x -> 0];
    s = AsymptoticExpansion[Sin[x], x -> 0];
    alias = AsymptoticAnalysis`AsymptoticExpand[Sin[x], x -> 0];
    nativeAutomaticQ[s, native, "Asymptotic"] &&
      nativeAutomaticQ[alias, native, "Asymptotic"] && Normal[s] === x],
  True, TestID -> "native-automatic-rule-without-package-goal-has-native-leading-order"]

VerificationTest[
  Module[{x, native, s},
    native = Asymptotic[1 + x + x^2, {x, 0, Infinity}];
    s = AsymptoticExpansion[1 + x + x^2, {x, 0, Infinity}];
    nativeAutomaticQ[s, native, "Asymptotic"] && Normal[s] === 1 + x + x^2],
  True, TestID -> "native-automatic-infinite-order-uses-native-asymptotic-contract"]

VerificationTest[
  Quiet[Module[{x, n, native, s},
    native = Series[Exp[x], {x, 0, n}];
    s = AsymptoticExpansion[Exp[x], {x, 0, n}];
    nativeAutomaticQ[s, native, "Series"] && Head[native] === Series &&
      s["NativeEvaluationStatus"] === "Unresolved"]],
  True, TestID -> "native-automatic-symbolic-native-order-remains-unresolved-and-inspectable"]

VerificationTest[
  Module[{x, native, s},
    native = Asymptotic[Sin[2.5 x], {x, 0, 3}, Method -> Automatic, WorkingPrecision -> 30];
    s = AsymptoticExpansion[Sin[2.5 x], {x, 0, 3}, Method -> Automatic, WorkingPrecision -> 30];
    nativeAutomaticQ[s, native, "Asymptotic"] &&
      s["BackendSelectionReason"] === "NativeOptions"],
  True, TestID -> "native-automatic-method-and-working-precision-select-compatible-native-backend"]

VerificationTest[
  Module[{x, native, s},
    native = Asymptotic[Sin[2.5/x], x -> Infinity, SeriesTermGoal -> 2];
    s = AsymptoticExpansion[Sin[2.5/x], x -> Infinity, SeriesTermGoal -> 2];
    nativeAutomaticQ[s, native, "Asymptotic"] &&
      MatchQ[s["PackageFailure"], Failure["InexactInput", _Association]]],
  True, TestID -> "native-automatic-representation-fallback-preserves-rule-and-native-term-goal"]

VerificationTest[
  Module[{x, a, native, s, sourceCalls = 0, centerCalls = 0, orderCalls = 0,
      assumptionCalls = 0, goalCalls = 0},
    native = Series[Log[-a] + Exp[x], {x, 0, 4},
      Assumptions -> a > 0, SeriesTermGoal -> 2];
    s = AsymptoticExpansion[(sourceCalls++; Log[-a] + Exp[x]),
      {x, (centerCalls++; 0), (orderCalls++; 4)},
      Assumptions :> (assumptionCalls++; a > 0),
      SeriesTermGoal :> (goalCalls++; 2)];
    nativeAutomaticQ[s, native, "Series"] &&
      {sourceCalls, centerCalls, orderCalls, assumptionCalls, goalCalls} === {1, 1, 1, 1, 1}],
  True, TestID -> "native-automatic-package-failure-replays-values-without-source-spec-or-delayed-option-effects"]

VerificationTest[
  Module[{x, a, native, s, assumptionCalls = 0, goalCalls = 0},
    native = Series[Log[-a] + Exp[x], {x, 0, 4},
      Assumptions -> a > 0, SeriesTermGoal -> 2];
    s = AsymptoticExpansion[Log[-a] + Exp[x], {x, 0, 4},
      {{Assumptions :> (assumptionCalls++; a > 0)},
        {SeriesTermGoal :> (goalCalls++; 2)}}];
    nativeAutomaticQ[s, native, "Series"] && {assumptionCalls, goalCalls} === {1, 1}],
  True, TestID -> "native-automatic-nested-delayed-common-options-are-materialized-once"]

VerificationTest[
  Module[{x, a, native, s, nativeCalls = 0, automaticCalls = 0},
    native = Series[Sqrt[a^2] Exp[x], {x, 0, 2},
      Analytic -> True, Assumptions :> (nativeCalls++; a > 0)];
    s = AsymptoticExpansion[Sqrt[a^2] Exp[x], {x, 0, 2},
      Analytic -> True, Assumptions :> (automaticCalls++; a > 0)];
    nativeAutomaticQ[s, native, "Series"] && nativeCalls > 0 &&
      automaticCalls === nativeCalls],
  True, TestID -> "native-automatic-direct-native-route-does-not-preexecute-delayed-native-options"]

VerificationTest[
  Module[{x, a, native, s, nativeOptions, automaticOptions,
      nativeCalls = 0, automaticCalls = 0, sourceCalls = 0},
    nativeOptions := (nativeCalls++; {{Analytic -> True}, {Assumptions -> a > 0}});
    automaticOptions := (automaticCalls++; {{Analytic -> True}, {Assumptions -> a > 0}});
    native = Series[Sqrt[a^2] Exp[x], {x, 0, 2}, nativeOptions];
    s = AsymptoticExpansion[(sourceCalls++; Sqrt[a^2] Exp[x]), {x, 0, 2}, automaticOptions];
    nativeAutomaticQ[s, native, "Series"] &&
      nativeCalls === 1 && automaticCalls === nativeCalls && sourceCalls === 1],
  True, TestID -> "native-automatic-computed-nested-native-option-container-without-selector-evaluates-once"]

VerificationTest[
  Module[{x, native, s, optionCalls = 0, sourceCalls = 0, options},
    native = Series[Exp[I x], {x, 0, 2}, Analytic -> True];
    options := (optionCalls++; {Analytic -> True});
    s = AsymptoticAnalysis`AsymptoticExpand[(sourceCalls++; Exp[I x]),
      {x, 0, 2}, Sequence @@ options];
    nativeAutomaticQ[s, native, "Series"] && {optionCalls, sourceCalls} === {1, 1}],
  True, TestID -> "native-automatic-held-alias-expands-computed-option-sequence-once"]

VerificationTest[
  Module[{x, a, literal, computed, options, literalCalls = 0, computedCalls = 0, optionCalls = 0},
    options := (optionCalls++; {Assumptions -> True});
    Block[{$Assumptions = a > 0},
      literal = AsymptoticExpansion[(literalCalls++; FullSimplify[Sqrt[a^2]]) + x,
        {x, 0, 2}, Assumptions -> True];
      computed = AsymptoticExpansion[(computedCalls++; FullSimplify[Sqrt[a^2]]) + x,
        {x, 0, 2}, options]];
    MatchQ[literal, _GeneralizedSeries] && MatchQ[computed, _GeneralizedSeries] &&
      Normal[computed] === Normal[literal] && computed["Kind"] === literal["Kind"] &&
      {literalCalls, computedCalls, optionCalls} === {1, 1, 1}],
  True, TestID -> "native-automatic-computed-common-options-preserve-neutral-package-source-evaluation"]

VerificationTest[
  Module[{x},
    MatchQ[AsymptoticExpansion[Log[-x], {x, 0, 2}],
      Failure["NonpositiveBase", _Association]] &&
    MatchQ[AsymptoticExpansion[ConditionalExpression[1.5 + x, x < 0], {x, 0, 2}],
      Failure["IncompatibleTargetCondition", _Association]]],
  True, TestID -> "native-automatic-preserves-real-branch-and-target-condition-refusals"]

VerificationTest[
  Module[{x, callable, applied},
    callable = AsymptoticExpansion[InverseFunction[Exp], {x, 1, 3}];
    applied = Quiet[AsymptoticExpansion[
      InverseFunction[ConditionalExpression[Gamma[#], # > 0] &][x],
      x -> Infinity, SeriesTermGoal -> 2], InverseFunction::ifun];
    MatchQ[callable, _GeneralizedSeries] && callable["Kind"] =!= "Native" &&
      Expand[Normal[callable]] === Expand[(x - 1) - (x - 1)^2/2] &&
      MatchQ[applied, Failure["AmbiguousInverseFunctionBranch", _Association]]],
  True, TestID -> "native-automatic-preserves-callable-syntax-and-applied-inverse-branch-ambiguity"]

VerificationTest[
  Module[{x, automatic, package},
    automatic = AsymptoticExpansion[Exp[I x], {x, 0, 3}, Direction -> "FromAbove"];
    package = AsymptoticExpansion[Exp[I x], {x, 0, 3},
      "Backend" -> "Package", Direction -> "FromAbove"];
    MatchQ[automatic, Failure["InexactInput", _Association]] && automatic[[1]] === package[[1]]],
  True, TestID -> "native-automatic-explicit-direction-does-not-silently-switch-branch-contracts"]

VerificationTest[
  Module[{x, automatic, package, inexact},
    automatic = AsymptoticExpansion[Exp[x + x^2], {x, 0, 4}, "MaxTerms" -> 1];
    package = AsymptoticExpansion[Exp[x + x^2], {x, 0, 4}, "Backend" -> "Package", "MaxTerms" -> 1];
    inexact = AsymptoticExpansion[Exp[1.5 x], {x, 0, 3}, "MaxTerms" -> 100];
    MatchQ[automatic, Failure["ResourceLimit", _Association]] && automatic[[1]] === package[[1]] &&
      MatchQ[inexact, Failure["InexactInput", _Association]]],
  True, TestID -> "native-automatic-explicit-resource-budget-is-never-dropped-to-obtain-native-output"]

VerificationTest[
  Module[{x},
    MatchQ[AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> 0, "Backend" -> "Package"],
      Failure["InvalidCutoff", _Association]] &&
    MatchQ[AsymptoticExpansion[Exp[x], x -> Infinity,
      Direction -> "FromAbove", SeriesTermGoal -> 2], Failure["InvalidDirection", _Association]] &&
    MatchQ[AsymptoticExpansion[Exp[x], {x, 0, 2}, "Backend" -> "MissingBackend"],
      Failure["InvalidBackend", _Association]]],
  True, TestID -> "native-automatic-invalid-goal-direction-and-selector-are-not-representation-failures"]

VerificationTest[
  Module[{x},
    MatchQ[AsymptoticExpansion[Exp[x], {x, 0, 2}, "Backend" -> "Package", Analytic -> True],
      Failure["UnsupportedOption", _Association]] &&
    MatchQ[AsymptoticExpansion[Exp[x], {x, 0, 2},
      Direction -> "FromAbove", Analytic -> True], Failure["UnsupportedOption", _Association]]],
  True, TestID -> "native-automatic-native-options-cannot-bypass-explicit-package-or-direction-contract"]

VerificationTest[
  Module[{x, a, strict, ordinary},
    strict = AsymptoticExpansion[Sin[1.5 x], {x, 0, 3}, "Backend" -> "Package"];
    ordinary = AsymptoticExpansion[a + Exp[x], {x, 0, 3}, Assumptions -> Element[a, Reals]];
    MatchQ[strict, Failure["InexactInput", _Association]] &&
      MatchQ[ordinary, _GeneralizedSeries] && ordinary["Kind"] =!= "Native" &&
      Normal[ordinary] === 1 + a + x + x^2/2 && ordinary["RemainderPower"] === 3],
  True, TestID -> "native-automatic-strict-package-remains-real-and-proved-real-parameters-stay-package"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[Exp[I x], {x, 0, 2}];
    MatchQ[s, _GeneralizedSeries] &&
      MatchQ[SeriesRefine[s, 4], Failure["NativeSeriesContract", _Association]] &&
      MatchQ[SeriesPower[s, 2], Failure["NativeSeriesContract", _Association]] &&
      FreeQ[Normal[s], _GeneralizedSeries | _PowerLogRemainder | _SeriesData]],
  True, TestID -> "native-automatic-fallback-does-not-promote-native-output-to-package-arithmetic-or-refinement"]

VerificationTest[
  Module[{x, options, sourceCalls = 0, optionCalls = 0, result},
    options := (optionCalls++; {"MaxTerms" -> 3});
    result = AsymptoticExpansion[(sourceCalls++; Exp[x]),
      {x, 0, 2}, "Backend" -> "Series", options];
    MatchQ[result, Failure["NativeOptionConflict", _Association]] &&
      {sourceCalls, optionCalls} === {0, 1}],
  True, TestID -> "native-automatic-computed-budget-container-is-rejected-before-explicit-native-source-evaluation"]

VerificationTest[
  Module[{x, options, sourceCalls = 0, optionCalls = 0, selectorCalls = 0, result, native},
    native = Series[Exp[I x], {x, 0, 2}, Analytic -> True];
    options := (optionCalls++; {Analytic -> True});
    result = AsymptoticExpansion[(sourceCalls++; Exp[I x]), {x, 0, 2},
      "Backend" :> (selectorCalls++; "Series"), options];
    MatchQ[result, _GeneralizedSeries] && result["NativeResult"] === native &&
      Normal[result] === Normal[native] &&
      {sourceCalls, optionCalls, selectorCalls} === {1, 1, 1}],
  True, TestID -> "native-automatic-preparation-consumes-computed-selector-and-options-once"]

VerificationTest[
  Module[{x, options, sourceCalls = 0, optionCalls = 0, result, native},
    native = Series[Exp[I x], {x, 0, 2}, Analytic -> True];
    options := (optionCalls++; {Analytic -> True});
    result = AsymptoticExpansion[(sourceCalls++; Exp[I x]), {x, 0, 2},
      {{"Backend" -> "Series"}, options}];
    MatchQ[result, _GeneralizedSeries] && result["NativeBackend"] === "Series" &&
      result["NativeResult"] === native && Normal[result] === Normal[native] &&
      {sourceCalls, optionCalls} === {1, 1}],
  True, TestID -> "native-automatic-nested-computed-option-member-does-not-hide-backend-selector"]

VerificationTest[
  Module[{x, options, sourceCalls = 0, optionCalls = 0, result},
    options := (optionCalls++; {"MaxTerms" -> 3});
    result = AsymptoticExpansion[(sourceCalls++; Exp[x]), {x, 0, 2},
      "Backend" -> "Series", {{Analytic -> True}, options}];
    MatchQ[result, Failure["NativeOptionConflict", _Association]] &&
      {sourceCalls, optionCalls} === {0, 1}],
  True, TestID -> "native-automatic-nested-computed-budget-member-cannot-bypass-native-conflict-check"]

VerificationTest[
  Module[{x, sourceCalls = 0, result},
    result = AsymptoticExpansion[(sourceCalls++; Exp[x]),
      Sequence[{x, 0, 2}, "MaxTerms" -> 3], "Backend" -> "Series"];
    MatchQ[result, Failure["NativeOptionConflict", _Association]] && sourceCalls === 0],
  True, TestID -> "native-automatic-mixed-specification-and-budget-sequence-is-checked-before-native-evaluation"]
