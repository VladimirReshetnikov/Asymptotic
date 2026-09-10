(* Native compatibility is delegation, not certification of a package remainder.
   The direct native calls are independent oracles for argument/order/option
   forwarding. In particular, native Series retains its requested nth power.
   Native contracts and accepted argument forms:
   https://reference.wolfram.com/language/ref/Series.html
   https://reference.wolfram.com/language/ref/Asymptotic.html *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

nativeCompatibilityQ[s_, expected_, backend_] := MatchQ[s, _GeneralizedSeries] &&
  s["Kind"] === "Native" && s["NativeBackend"] === backend &&
  s["NativeResult"] === expected && Normal[s] === Normal[expected] &&
  s["RemainderContract"] === If[backend === "Series", "NativeFormalOrder", "NativeAsymptotic"] &&
  s["Exact"] === Missing["NotEstablished"];

VerificationTest[
  Module[{x, native, s},
    native = Series[Exp[I x], {x, 0, 3}];
    s = AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
    nativeCompatibilityQ[s, native, "Series"] &&
      Normal[s] === 1 + I x - x^2/2 - I x^3/6],
  True, TestID -> "native-compatibility-series-complex-coefficients-inclusive-native-order"]

VerificationTest[
  Module[{x, native, s},
    native = Series[Sin[2.5 x], {x, 0, 5}];
    s = AsymptoticExpansion[Sin[2.5 x], {x, 0, 5}, "Backend" -> "Series"];
    nativeCompatibilityQ[s, native, "Series"] && ! FreeQ[Normal[s], _Real]],
  True, TestID -> "native-compatibility-series-preserves-approximate-coefficients"]

VerificationTest[
  Module[{x, native, s},
    native = Series[Exp[x], {x, I, 2}];
    s = AsymptoticExpansion[Exp[x], {x, I, 2}, "Backend" -> "Series"];
    nativeCompatibilityQ[s, native, "Series"]],
  True, TestID -> "native-compatibility-series-complex-center"]

VerificationTest[
  Module[{x, a, native, s},
    native = Series[Sin[x], {x, a, 2}, Assumptions -> True];
    s = AsymptoticExpansion[Sin[x], {x, a, 2},
      "Backend" -> "Series", Assumptions -> True];
    nativeCompatibilityQ[s, native, "Series"]],
  True, TestID -> "native-compatibility-series-symbolic-center-without-realness-admission"]

VerificationTest[
  Module[{x, y, native, s},
    native = Series[Exp[x + y], {x, 0, 2}, {y, 0, 3}];
    s = AsymptoticExpansion[Exp[x + y], {x, 0, 2}, {y, 0, 3}, "Backend" -> "Series"];
    nativeCompatibilityQ[s, native, "Series"] &&
      ! FreeQ[native, HoldPattern[SeriesData[_, _, coefficients_List, ___]] /;
        ! FreeQ[coefficients, _SeriesData]] &&
      FreeQ[Normal[s], _SeriesData | _GeneralizedSeries | _PowerLogRemainder]],
  True, TestID -> "native-compatibility-series-multivariate-nested-native-series-normalizes"]

VerificationTest[
  Module[{x, native, s},
    native = Series[{{Sin[x], Cos[x]}, {Exp[x], 1/(1 - x)}}, {x, 0, 3}];
    s = AsymptoticExpansion[{{Sin[x], Cos[x]}, {Exp[x], 1/(1 - x)}},
      {x, 0, 3}, "Backend" -> "Series"];
    nativeCompatibilityQ[s, native, "Series"] && Dimensions[Normal[s]] === {2, 2}],
  True, TestID -> "native-compatibility-series-preserves-list-and-matrix-shape"]

VerificationTest[
  Module[{x, native, s},
    native = Series[Log[x]/x + Sqrt[x] Exp[x], {x, 0, 2}];
    s = AsymptoticExpansion[Log[x]/x + Sqrt[x] Exp[x], {x, 0, 2}, "Backend" -> "Series"];
    nativeCompatibilityQ[s, native, "Series"]],
  True, TestID -> "native-compatibility-series-laurent-logarithmic-and-puiseux-data"]

VerificationTest[
  Module[{x, f, native, s},
    native = Series[f[x] Exp[x], {x, 0, 2}, Analytic -> True];
    s = AsymptoticExpansion[f[x] Exp[x], {x, 0, 2},
      "Backend" -> "Series", Analytic -> True];
    nativeCompatibilityQ[s, native, "Series"]],
  True, TestID -> "native-compatibility-series-unknown-function-formal-analytic-contract"]

VerificationTest[
  Module[{x, f, native, s},
    native = Quiet[Series[f[Log[x]] Exp[x], {x, 0, 2}, Analytic -> False]];
    s = Quiet[AsymptoticExpansion[f[Log[x]] Exp[x], {x, 0, 2},
      "Backend" -> "Series", Analytic -> False]];
    nativeCompatibilityQ[s, native, "Series"] && ! FreeQ[s["NativeResult"], f]],
  True, TestID -> "native-compatibility-series-preserves-unresolved-strict-analytic-output"]

VerificationTest[
  Module[{x, a, native, s},
    Block[{$Assumptions = a < 0},
      native = Series[Sqrt[a^2] Exp[x], {x, 0, 2}, Assumptions -> a > 0];
      s = AsymptoticExpansion[Sqrt[a^2] Exp[x], {x, 0, 2},
        "Backend" -> "Series", Assumptions -> a > 0]];
    nativeCompatibilityQ[s, native, "Series"]],
  True, TestID -> "native-compatibility-series-explicit-assumptions-follow-native-semantics"]

VerificationTest[
  Module[{x, native, s},
    native = Series[Sin[x], {x, 0, 9}, SeriesTermGoal -> 2];
    s = AsymptoticExpansion[Sin[x], {x, 0, 9},
      "Backend" -> "Series", SeriesTermGoal -> 2];
    nativeCompatibilityQ[s, native, "Series"]],
  True, TestID -> "native-compatibility-series-term-goal-forwarded-with-original-order"]

VerificationTest[
  Module[{x, native, s},
    native = Asymptotic[Sin[x], x -> 0];
    s = AsymptoticExpansion[Sin[x], x -> 0, "Backend" -> "Asymptotic"];
    nativeCompatibilityQ[s, native, "Asymptotic"] && Normal[s] === x],
  True, TestID -> "native-compatibility-asymptotic-rule-form-default-leading-term"]

VerificationTest[
  Module[{x, native, s},
    native = Asymptotic[Exp[I x], {x, 0, 3}];
    s = AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Asymptotic"];
    nativeCompatibilityQ[s, native, "Asymptotic"]],
  True, TestID -> "native-compatibility-asymptotic-preserves-native-order-and-complex-source"]

VerificationTest[
  Module[{x, native, s},
    native = Asymptotic[Log[1 + 1/x], x -> Infinity, SeriesTermGoal -> 3];
    s = AsymptoticExpansion[Log[1 + 1/x], x -> Infinity,
      "Backend" -> "Asymptotic", SeriesTermGoal -> 3];
    nativeCompatibilityQ[s, native, "Asymptotic"] &&
      Normal[s] === 1/x - 1/(2 x^2) + 1/(3 x^3)],
  True, TestID -> "native-compatibility-asymptotic-infinity-rule-term-goal-forwarded"]

VerificationTest[
  Module[{x, native, s},
    native = Asymptotic[1 + x + x^2, {x, 0, Infinity}];
    s = AsymptoticExpansion[1 + x + x^2, {x, 0, Infinity}, "Backend" -> "Asymptotic"];
    nativeCompatibilityQ[s, native, "Asymptotic"] && Normal[s] === 1 + x + x^2],
  True, TestID -> "native-compatibility-asymptotic-infinite-order-finite-polynomial"]

VerificationTest[
  Module[{x, t, native, s},
    native = Asymptotic[Inactive[Integrate][Exp[-t], {t, 0, x}], x -> 0, SeriesTermGoal -> 2];
    s = AsymptoticExpansion[Inactive[Integrate][Exp[-t], {t, 0, x}], x -> 0,
      "Backend" -> "Asymptotic", SeriesTermGoal -> 2];
    nativeCompatibilityQ[s, native, "Asymptotic"]],
  True, TestID -> "native-compatibility-asymptotic-inactive-integral-remains-native-input"]

VerificationTest[
  Module[{x, a, native, s},
    Block[{$Assumptions = a < 0},
      native = Asymptotic[Sqrt[a^2 + x], x -> 0, Assumptions -> a > 0, SeriesTermGoal -> 2];
      s = AsymptoticExpansion[Sqrt[a^2 + x], x -> 0,
        "Backend" -> "Asymptotic", Assumptions -> a > 0, SeriesTermGoal -> 2]];
    nativeCompatibilityQ[s, native, "Asymptotic"]],
  True, TestID -> "native-compatibility-asymptotic-assumptions-and-term-goal-forwarded-together"]

VerificationTest[
  Module[{x, native, s, ordinary, automatic, nativeCalls = 0, packageCalls = 0},
    native = Asymptotic[(nativeCalls++; Sin[x]), x -> 0, SeriesTermGoal -> 2];
    s = AsymptoticAnalysis`AsymptoticExpand[(packageCalls++; Sin[x]),
      x -> 0, "Backend" -> "Asymptotic", SeriesTermGoal -> 2];
    ordinary = AsymptoticExpansion[Sin[x], {x, 0, 4}];
    automatic = AsymptoticAnalysis`AsymptoticExpand[Sin[x], {x, 0, 4}];
    nativeCompatibilityQ[s, native, "Asymptotic"] &&
      nativeCalls === 1 && packageCalls === nativeCalls &&
      MatchQ[automatic, _GeneralizedSeries] &&
      Normal[automatic] === Normal[ordinary] &&
      automatic["Remainder"] === ordinary["Remainder"]],
  True, TestID -> "native-compatibility-held-alias-shares-automatic-default-and-preserves-explicit-backend"]

VerificationTest[
  Module[{x, a, native, s, nativeCalls = 0, packageCalls = 0},
    native = Series[Sqrt[a^2] Exp[x], {x, 0, 2},
      Assumptions :> (nativeCalls++; a > 0)];
    s = AsymptoticAnalysis`AsymptoticExpand[Sqrt[a^2] Exp[x], {x, 0, 2},
      "Backend" -> "Series", Assumptions :> (packageCalls++; a > 0)];
    nativeCompatibilityQ[s, native, "Series"] && nativeCalls > 0 &&
      packageCalls === nativeCalls],
  True, TestID -> "native-compatibility-alias-explicit-series-backend-delayed-option-not-preexecuted"]

VerificationTest[
  Module[{x, native, s, nativeCalls = 0, packageCalls = 0},
    native = Series[(nativeCalls++; 1/(1 - x)), {x, 0, 3}];
    s = AsymptoticExpansion[(packageCalls++; 1/(1 - x)),
      {x, 0, 3}, "Backend" -> "Series"];
    nativeCompatibilityQ[s, native, "Series"] && nativeCalls === 1 &&
      packageCalls === nativeCalls && Normal[s] === 1 + x + x^2 + x^3],
  True, TestID -> "native-compatibility-explicit-series-backend-source-evaluates-once"]

(* Keep native option containers and evaluation order intact. These cases use
   direct native observations as their oracle; none promotes a returned formal
   SeriesData, conditional expression, or infinite sum to a proved remainder. *)

VerificationTest[
  Module[{x, native, s},
    native = Series[Sin[x], x -> 0];
    s = AsymptoticExpansion[Sin[x], x -> 0, "Backend" -> "Series"];
    nativeCompatibilityQ[s, native, "Series"] && Normal[s] === x &&
      s["NativeEvaluationStatus"] === "Computed"],
  True, TestID -> "native-compatibility-series-rule-form-is-native-leading-order"]

VerificationTest[
  Module[{x, native, s},
    native = Series[Sin[1/x], x -> Infinity, SeriesTermGoal -> 2];
    s = AsymptoticExpansion[Sin[1/x], x -> Infinity,
      "Backend" -> "Series", SeriesTermGoal -> 2];
    (* Native Series counts order positions here, including the zero x^-2
       coefficient; this is not the package's two-nonzero-block goal. *)
    nativeCompatibilityQ[s, native, "Series"] &&
      Normal[s] === 1/x],
  True, TestID -> "native-compatibility-series-rule-form-at-infinity-forwards-term-goal"]

VerificationTest[
  Module[{x, a, native, s},
    native = Series[Sqrt[a^2] Exp[x], {x, 0, 3},
      {{Assumptions -> a > 0}, {Analytic -> True, SeriesTermGoal -> 2}}];
    s = AsymptoticExpansion[Sqrt[a^2] Exp[x], {x, 0, 3},
      {{"Backend" -> "Series", Assumptions -> a > 0},
        {Analytic -> True, SeriesTermGoal -> 2}}];
    nativeCompatibilityQ[s, native, "Series"]],
  True, TestID -> "native-compatibility-nested-option-lists-can-contain-backend-selector"]

VerificationTest[
  Module[{x, native, s},
    native = Series[Sin[x], {x, 0, 5},
      Sequence[Analytic -> False, SeriesTermGoal -> 2]];
    s = AsymptoticAnalysis`AsymptoticExpand[Sin[x], {x, 0, 5},
      Sequence["Backend" -> "Series", Analytic -> False, SeriesTermGoal -> 2]];
    nativeCompatibilityQ[s, native, "Series"]],
  True, TestID -> "native-compatibility-held-alias-forwards-sequence-of-native-options"]

VerificationTest[
  Module[{x, a, native, s, nativeOptions, packageOptions,
      nativeCalls = 0, packageCalls = 0},
    nativeOptions := (nativeCalls++; {Assumptions -> a > 0, Analytic -> True});
    packageOptions := (packageCalls++;
      {"Backend" -> "Series", Assumptions -> a > 0, Analytic -> True});
    native = Series[Sqrt[a^2] Exp[x], {x, 0, 2}, nativeOptions];
    s = AsymptoticExpansion[Sqrt[a^2] Exp[x], {x, 0, 2}, packageOptions];
    nativeCompatibilityQ[s, native, "Series"] &&
      nativeCalls > 0 && packageCalls === nativeCalls],
  True, TestID -> "native-compatibility-stored-option-list-is-not-evaluated-twice-for-dispatch"]

VerificationTest[
  Module[{x, native, s, nativeSource = 0, packageSource = 0,
      nativeCenter = 0, packageCenter = 0, nativeOrder = 0, packageOrder = 0,
      nativeAssumptions = 0, packageAssumptions = 0, nativeCounts, packageCounts},
    native = Series[(nativeSource++; Exp[x]),
      {x, (nativeCenter++; 0), (nativeOrder++; 3)},
      Assumptions -> (nativeAssumptions++; True)];
    s = AsymptoticExpansion[(packageSource++; Exp[x]),
      {x, (packageCenter++; 0), (packageOrder++; 3)}, "Backend" -> "Series",
      Assumptions -> (packageAssumptions++; True)];
    nativeCounts = {nativeSource, nativeCenter, nativeOrder, nativeAssumptions};
    packageCounts = {packageSource, packageCenter, packageOrder, packageAssumptions};
    nativeCompatibilityQ[s, native, "Series"] &&
      nativeCounts === packageCounts && And @@ Thread[nativeCounts > 0]],
  True, TestID -> "native-compatibility-source-triple-and-immediate-rule-evaluate-as-native"]

VerificationTest[
  Module[{x, native, s, nativeCalls = 0, packageCalls = 0},
    native = Series[Sin[x], x -> (nativeCalls++; 0), SeriesTermGoal -> 2];
    s = AsymptoticAnalysis`AsymptoticExpand[Sin[x], x -> (packageCalls++; 0),
      "Backend" -> "Series", SeriesTermGoal -> 2];
    nativeCompatibilityQ[s, native, "Series"] &&
      nativeCalls > 0 && packageCalls === nativeCalls],
  True, TestID -> "native-compatibility-rule-specification-rhs-evaluates-as-native"]

VerificationTest[
  Module[{x, native, s, nativeMethod = 0, packageMethod = 0,
      nativePrecision = 0, packagePrecision = 0},
    native = Asymptotic[Sin[2.5 x], {x, 0, 3},
      Method -> (nativeMethod++; Automatic),
      WorkingPrecision -> (nativePrecision++; 30)];
    s = AsymptoticExpansion[Sin[2.5 x], {x, 0, 3}, "Backend" -> "Asymptotic",
      Method -> (packageMethod++; Automatic),
      WorkingPrecision -> (packagePrecision++; 30)];
    nativeCompatibilityQ[s, native, "Asymptotic"] &&
      {packageMethod, packagePrecision} === {nativeMethod, nativePrecision} &&
      nativeMethod > 0 && nativePrecision > 0],
  True, TestID -> "native-compatibility-asymptotic-method-and-working-precision-forwarded"]

VerificationTest[
  Module[{x, k, native, s},
    native = Asymptotic[1/(1 - x), {x, 0, Infinity},
      GeneratedParameters -> (k[#] &)];
    s = AsymptoticExpansion[1/(1 - x), {x, 0, Infinity},
      "Backend" -> "Asymptotic", GeneratedParameters -> (k[#] &)];
    nativeCompatibilityQ[s, native, "Asymptotic"] &&
      ! FreeQ[native, _Sum | HoldPattern[Inactive[Sum][___]]] &&
      s["NativeEvaluationStatus"] === "Computed"],
  True, TestID -> "native-compatibility-infinite-sum-shape-and-generated-parameters-preserved"]

VerificationTest[
  Module[{x, k, native, s},
    native = Asymptotic[1/(1 - x), {x, 0, Infinity},
      GeneratedParameters -> (k[#] &), GenerateConditions -> True];
    s = AsymptoticAnalysis`AsymptoticExpand[1/(1 - x), {x, 0, Infinity},
      "Backend" -> "Asymptotic", GeneratedParameters -> (k[#] &),
      GenerateConditions -> True];
    nativeCompatibilityQ[s, native, "Asymptotic"] &&
      ! FreeQ[native, _ConditionalExpression | _Piecewise]],
  True, TestID -> "native-compatibility-infinite-series-convergence-condition-preserved"]

VerificationTest[
  Quiet[Module[{x, n, native, s},
    native = Series[Exp[x], {x, 0, n}];
    s = AsymptoticExpansion[Exp[x], {x, 0, n}, "Backend" -> "Series"];
    Head[native] === Series && nativeCompatibilityQ[s, native, "Series"] &&
      s["NativeEvaluationStatus"] === "Unresolved"]],
  True, TestID -> "native-compatibility-unresolved-native-order-remains-inspectable"]

VerificationTest[
  Module[{x, f, native, s},
    native = Series[f["Backend" -> "Asymptotic"] + x, {x, 0, 2}];
    s = AsymptoticExpansion[f["Backend" -> "Asymptotic"] + x,
      {x, 0, 2}, "Backend" -> "Series"];
    nativeCompatibilityQ[s, native, "Series"] &&
      ! FreeQ[Normal[s], HoldPattern[f["Backend" -> "Asymptotic"]]]],
  True, TestID -> "native-compatibility-backend-rules-inside-source-data-are-not-options"]

VerificationTest[
  Module[{x, native, package, automatic},
    native = Series[Exp[x], {x, 0, 3}];
    package = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Package"];
    automatic = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> Automatic];
    MatchQ[package, _GeneralizedSeries] && MatchQ[automatic, _GeneralizedSeries] &&
      package["Kind"] =!= "Native" && automatic["Kind"] =!= "Native" &&
      Normal[package] === 1 + x + x^2/2 &&
      Normal[automatic] === Normal[package] &&
      package["Remainder"] === automatic["Remainder"] &&
      package["RemainderPower"] === 3 &&
      Normal[native] === Normal[package] + x^3/6],
  True, TestID -> "native-compatibility-package-selector-preserves-automatic-exclusive-cutoff"]
