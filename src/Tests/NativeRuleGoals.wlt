(* Native rule-goal semantics are independent of package nonzero-block counts.
   Direct built-ins are the oracles; no analytic package contract is inferred. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

nativeRuleGoalResultQ[s_, native_] := MatchQ[s, _GeneralizedSeries] &&
  s["Kind"] === "Native" && s["NativeResult"] === native &&
  Normal[s] === Normal[native] &&
  s["Remainder"] === Missing["NativeContract"] && s["Exact"] === Missing["NotEstablished"];

VerificationTest[Quiet[Module[{x, s},
  s = AsymptoticExpand[Exp[x], x -> 0, SeriesTermGoal -> 0];
  nativeRuleGoalResultQ[s, Series[Exp[x], x -> 0, SeriesTermGoal -> 0]] &&
    Normal[s] === 1 && s["NativeBackend"] === "Series" && s["OrderConvention"] === "Native" &&
    Lookup[s["NativeAttempts"], "EvaluationStatus"] === {"Unresolved", "Computed"} &&
    s["BackendSelectionReason"] === "NativeSpecification" && s["PackageFailure"] === None]],
  True, TestID -> "native-rule-goal-zero-scalar-finds-series-after-unresolved-asymptotic"]

VerificationTest[Quiet[Module[{x, results},
  results = Table[With[{goal = n},
    nativeRuleGoalResultQ[AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> goal],
      Series[Exp[x], x -> 0, SeriesTermGoal -> goal]]], {n, {-1, -2, -100}}];
  And @@ results]], True, TestID -> "native-rule-goal-negative-integers-preserve-native-empty-series"]

VerificationTest[Quiet[Module[{x, s},
  s = AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> Automatic];
  nativeRuleGoalResultQ[s, Series[Exp[x], x -> 0, SeriesTermGoal -> Automatic]] && Normal[s] === 1]],
  True, TestID -> "native-rule-goal-explicit-automatic-preserves-native-leading-request"]

VerificationTest[Quiet[Module[{x, cases},
  cases = {Sin[x], x^-3 + x, 0, 5};
  And @@ (Function[f, With[{s = AsymptoticExpansion[f, x -> 0, SeriesTermGoal -> 0],
      native = Series[f, x -> 0, SeriesTermGoal -> 0]}, nativeRuleGoalResultQ[s, native]]] /@ cases)]],
  True, TestID -> "native-rule-goal-zero-handles-vanishing-laurent-zero-and-constant-sources"]

VerificationTest[Quiet[Module[{x, s},
  s = AsymptoticExpansion[x^-1 + x^-2, x -> Infinity, SeriesTermGoal -> 0];
  nativeRuleGoalResultQ[s, Series[x^-1 + x^-2, x -> Infinity, SeriesTermGoal -> 0]]]],
  True, TestID -> "native-rule-goal-infinite-endpoint-retains-native-order-convention"]

VerificationTest[Quiet[Module[{x, a, s, source = 0, center = 0, assumptions = 0, goal = 0},
  s = AsymptoticExpansion[(source++; Sqrt[a^2] Exp[x]), x -> (center++; 0),
    Assumptions :> (assumptions++; a > 0), SeriesTermGoal :> (goal++; 0)];
  nativeRuleGoalResultQ[s, Series[Sqrt[a^2] Exp[x], x -> 0, Assumptions -> a > 0, SeriesTermGoal -> 0]] &&
    {source, center, assumptions, goal} === {1, 1, 1, 1} && FreeQ[s["NativeAttempts"], _RuleDelayed]]],
  True, TestID -> "native-rule-goal-source-center-and-delayed-common-options-evaluate-once"]

VerificationTest[Quiet[Module[{x, a, s, assumptions = 0, goals = 0, unused = 0},
  s = AsymptoticExpansion[Sqrt[a^2] Exp[x], x -> 0,
    Assumptions :> (assumptions++; a > 0), SeriesTermGoal :> (goals++; 0),
    {Assumptions :> (unused++; False), SeriesTermGoal :> (unused++; 1/2)}];
  Normal[s] === a && {assumptions, goals, unused} === {1, 1, 0}]],
  True, TestID -> "native-rule-goal-first-common-options-win-without-running-unused-duplicates"]

VerificationTest[Quiet[Module[{x, options, s, source = 0, containers = 0, goals = 0},
  options := (containers++; {{SeriesTermGoal :> (goals++; 0)}});
  s = AsymptoticExpand[(source++; Exp[x]), x -> 0, Sequence @@ options];
  Normal[s] === 1 && s["Kind"] === "Native" && {source, containers, goals} === {1, 1, 1}]],
  True, TestID -> "native-rule-goal-held-alias-reuses-computed-nested-option-sequence"]

VerificationTest[Quiet[Module[{x, a, s, calls = 0},
  Block[{$Assumptions = a > 0},
    s = AsymptoticExpansion[Sqrt[a^2] Exp[x], x -> 0,
      Assumptions :> (calls++; $Assumptions), SeriesTermGoal -> 0]];
  Normal[s] === a && calls === 1 && s["AmbientAssumptions"] === (a > 0)]],
  True, TestID -> "native-rule-goal-delayed-assumptions-use-captured-entry-context"]

VerificationTest[Module[{x, s, unused = 0},
  s = AsymptoticExpansion[Sin[x], x -> 0, SeriesTermGoal -> 2, SeriesTermGoal :> (unused++; 0)];
  s["Kind"] =!= "Native" && Normal[s] === x - x^3/6 && s["ReturnedTermCount"] === 2 && unused === 0],
  True, TestID -> "native-rule-goal-positive-first-value-keeps-package-nonzero-block-count"]

VerificationTest[Module[{x},
  And @@ (Function[g, MatchQ[AsymptoticExpansion[Exp[x], x -> 0,
      SeriesTermGoal -> g, "Backend" -> "Package"], Failure["InvalidCutoff", _Association]]] /@ {0, -1, Automatic})],
  True, TestID -> "native-rule-goal-explicit-package-keeps-analytic-goal-validation"]

VerificationTest[Module[{x, results},
  results = {
    AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> 0, Direction -> Automatic],
    AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> 0, "MaxTerms" -> 100000],
    AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> 0, "InverseFunctionBranches" -> Automatic]};
  And @@ (MatchQ[#, Failure["InvalidCutoff", _Association]] & /@ results)],
  True, TestID -> "native-rule-goal-explicit-package-contracts-remain-binding"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[x], {x, 0, 3}, SeriesTermGoal -> 0];
  s["Kind"] =!= "Native" && ! KeyExistsQ[s[[1]], "NativeAttempts"]],
  True, TestID -> "native-rule-goal-explicit-triple-retains-package-cutoff-behavior"]

VerificationTest[Quiet[Module[{x, s, native},
  native = Asymptotic[Exp[x], x -> 0, SeriesTermGoal -> 0];
  s = AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> 0, "Backend" -> "Asymptotic"];
  nativeRuleGoalResultQ[s, native] && s["NativeEvaluationStatus"] === "Unresolved" &&
    ! KeyExistsQ[s[[1]], "NativeAttempts"]]],
  True, TestID -> "native-rule-goal-explicit-native-backend-never-retries"]

VerificationTest[Quiet[Module[{x},
  And @@ (Function[g, MatchQ[AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> g],
    Failure["InvalidCutoff", _Association]]] /@ {0., -1., 1/2, Infinity})]],
  True, TestID -> "native-rule-goal-noninteger-and-infinite-values-retain-package-refusal"]
