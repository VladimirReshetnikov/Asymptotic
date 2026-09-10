(* Automatic retries a compatible native backend only after the preferred
   backend fails or retains an unresolved native call. The direct built-ins
   provide result oracles; native results acquire no analytic package bound. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

nativeSearchTestResultQ[s_, expected_, backend_] := MatchQ[s, _GeneralizedSeries] &&
  s["Kind"] === "Native" && s["NativeBackend"] === backend &&
  s["NativeResult"] === expected && Normal[s] === Normal[expected] &&
  s["Remainder"] === Missing["NativeContract"] &&
  s["Exact"] === Missing["NotEstablished"] &&
  s["RemainderContract"] === If[backend === "Series", "NativeFormalOrder", "NativeAsymptotic"];
nativeSearchTestAttempts[s_] := ({Lookup[#, "Backend"], Lookup[#, "EvaluationStatus"]} & /@
  s["NativeAttempts"]);

VerificationTest[
  Quiet[Module[{x, native, preferred, s},
    native = Series[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 0];
    preferred = Asymptotic[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 0];
    s = AsymptoticExpansion[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 0];
    ! FreeQ[preferred, _Asymptotic] && nativeSearchTestResultQ[s, native, "Series"] &&
      Normal[s] === {1, x} && s["NativeEvaluationStatus"] === "Computed" &&
      s["BackendSelection"] === Automatic && s["OrderConvention"] === "Native" &&
      s["BackendSelectionReason"] === "NativeSpecification" && s["PackageFailure"] === None &&
      nativeSearchTestAttempts[s] === {{"Asymptotic", "Unresolved"}, {"Series", "Computed"}}]],
  True, TestID -> "native-search-zero-goal-list-selects-successful-second-backend"]

VerificationTest[
  Quiet[Module[{x, native, s},
    native = Series[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> -1];
    s = AsymptoticExpansion[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> -1];
    nativeSearchTestResultQ[s, native, "Series"] && Normal[s] === {1, x} &&
      nativeSearchTestAttempts[s] === {{"Asymptotic", "Unresolved"}, {"Series", "Computed"}}]],
  True, TestID -> "native-search-negative-goal-list-retains-native-acceptance"]

VerificationTest[
  Module[{x, native, s},
    native = Series[Exp[I x], {x, 0, 2}];
    s = AsymptoticExpansion[Exp[I x], {x, 0, 2}];
    nativeSearchTestResultQ[s, native, "Series"] && Normal[s] === 1 + I x - x^2/2 &&
      s["BackendSelectionReason"] === "PackageRepresentation" && FailureQ[s["PackageFailure"]] &&
      nativeSearchTestAttempts[s] === {{"Series", "Computed"}}],
  True, TestID -> "native-search-computed-series-first-attempt-stops-search"]

VerificationTest[
  Module[{x, native, s},
    native = Asymptotic[Sin[x], x -> 0];
    s = AsymptoticExpansion[Sin[x], x -> 0];
    nativeSearchTestResultQ[s, native, "Asymptotic"] && Normal[s] === x &&
      nativeSearchTestAttempts[s] === {{"Asymptotic", "Computed"}}],
  True, TestID -> "native-search-computed-asymptotic-first-attempt-stops-search"]

VerificationTest[
  Quiet[Module[{x, native, s},
    native = Asymptotic[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 1/2];
    s = AsymptoticExpansion[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 1/2];
    ! FreeQ[native, _Asymptotic] && nativeSearchTestResultQ[s, native, "Asymptotic"] &&
      s["NativeEvaluationStatus"] === "Unresolved" &&
      nativeSearchTestAttempts[s] === {{"Asymptotic", "Unresolved"}, {"Series", "Unresolved"}}]],
  True, TestID -> "native-search-two-unresolved-results-preserve-preferred-asymptotic-output"]

VerificationTest[
  Quiet[Module[{x, n, native, s},
    native = Series[Exp[x], {x, 0, n}];
    s = AsymptoticExpansion[Exp[x], {x, 0, n}];
    ! FreeQ[native, _Series] && nativeSearchTestResultQ[s, native, "Series"] &&
      s["NativeEvaluationStatus"] === "Unresolved" &&
      nativeSearchTestAttempts[s] === {{"Series", "Unresolved"}, {"Asymptotic", "Unresolved"}}]],
  True, TestID -> "native-search-two-unresolved-results-preserve-preferred-series-output"]

VerificationTest[
  Quiet[Module[{x, native, s},
    native = Asymptotic[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 0];
    s = AsymptoticExpansion[{Exp[x], Sin[x]}, x -> 0,
      "Backend" -> "Asymptotic", SeriesTermGoal -> 0];
    nativeSearchTestResultQ[s, native, "Asymptotic"] &&
      s["NativeEvaluationStatus"] === "Unresolved" && ! KeyExistsQ[s[[1]], "NativeAttempts"]]],
  True, TestID -> "native-search-explicit-asymptotic-never-switches-to-successful-series"]

VerificationTest[
  Module[{x, native, s},
    native = Series[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 0];
    s = AsymptoticExpansion[{Exp[x], Sin[x]}, x -> 0,
      "Backend" -> "Series", SeriesTermGoal -> 0];
    nativeSearchTestResultQ[s, native, "Series"] && ! KeyExistsQ[s[[1]], "NativeAttempts"]],
  True, TestID -> "native-search-explicit-series-retains-direct-delegation"]

VerificationTest[
  Quiet[Module[{x, s, source = 0, center = 0, assumptions = 0, goal = 0},
    s = AsymptoticExpansion[(source++; {Exp[x], Sin[x]}), x -> (center++; 0),
      Assumptions :> (assumptions++; True), SeriesTermGoal :> (goal++; 0)];
    MatchQ[s, _GeneralizedSeries] && Normal[s] === {1, x} &&
      {source, center, assumptions, goal} === {1, 1, 1, 1} &&
      nativeSearchTestAttempts[s] === {{"Asymptotic", "Unresolved"}, {"Series", "Computed"}} &&
      FreeQ[s["NativeAttempts"], _RuleDelayed]]],
  True, TestID -> "native-search-source-specification-and-common-delayed-options-evaluate-once"]

VerificationTest[
  Quiet[Module[{x, a, s, assumptions = 0, goal = 0, unusedAssumptions = 0, unusedGoal = 0},
    s = AsymptoticExpansion[{Sqrt[a^2] Exp[x], Sin[x]}, x -> 0,
      Assumptions :> (assumptions++; a > 0), SeriesTermGoal :> (goal++; 0),
      {Assumptions :> (unusedAssumptions++; False), SeriesTermGoal :> (unusedGoal++; 1/2)}];
    MatchQ[s, _GeneralizedSeries] && Normal[s] === {a, x} &&
      {assumptions, goal, unusedAssumptions, unusedGoal} === {1, 1, 0, 0} &&
      nativeSearchTestAttempts[s] === {{"Asymptotic", "Unresolved"}, {"Series", "Computed"}}]],
  True, TestID -> "native-search-first-option-wins-without-evaluating-unused-delayed-duplicates"]

VerificationTest[
  Quiet[Module[{x, s, options, container = 0, source = 0, assumptions = 0, goal = 0},
    options := (container++; {{Assumptions :> (assumptions++; True)},
      {SeriesTermGoal :> (goal++; 0)}});
    s = AsymptoticExpansion[(source++; {Exp[x], Sin[x]}), x -> 0, {options}];
    MatchQ[s, _GeneralizedSeries] && Normal[s] === {1, x} &&
      {container, source, assumptions, goal} === {1, 1, 1, 1} &&
      nativeSearchTestAttempts[s] === {{"Asymptotic", "Unresolved"}, {"Series", "Computed"}}]],
  True, TestID -> "native-search-computed-nested-option-container-is-reused-across-attempts"]

VerificationTest[
  Quiet[Module[{x, s, source = 0, assumptions = 0, goal = 0},
    s = AsymptoticAnalysis`AsymptoticExpand[(source++; {Exp[x], Sin[x]}), x -> 0,
      Sequence[{Assumptions :> (assumptions++; True)}, SeriesTermGoal :> (goal++; 0)]];
    MatchQ[s, _GeneralizedSeries] && Normal[s] === {1, x} &&
      {source, assumptions, goal} === {1, 1, 1} &&
      nativeSearchTestAttempts[s] === {{"Asymptotic", "Unresolved"}, {"Series", "Computed"}}]],
  True, TestID -> "native-search-held-alias-and-sequence-options-retain-once-only-evaluation"]

VerificationTest[
  Quiet[Module[{x, native, s},
    native = Asymptotic[{Exp[x], Sin[x]}, x -> 0, Method -> Automatic, SeriesTermGoal -> 0];
    s = AsymptoticExpansion[{Exp[x], Sin[x]}, x -> 0, Method -> Automatic, SeriesTermGoal -> 0];
    nativeSearchTestResultQ[s, native, "Asymptotic"] &&
      s["BackendSelectionReason"] === "NativeOptions" &&
      nativeSearchTestAttempts[s] === {{"Asymptotic", "Unresolved"}}]],
  True, TestID -> "native-search-asymptotic-exclusive-option-prevents-incompatible-retry"]

VerificationTest[
  Quiet[Module[{x, native, s, nativeGoal = 0, wrapperGoal = 0},
    native = Series[{Exp[x], Sin[x]}, x -> 0, Analytic -> False,
      SeriesTermGoal :> (nativeGoal++; 0)];
    s = AsymptoticExpansion[{Exp[x], Sin[x]}, x -> 0, Analytic -> False,
      SeriesTermGoal :> (wrapperGoal++; 0)];
    nativeSearchTestResultQ[s, native, "Series"] && nativeGoal > 0 && wrapperGoal === nativeGoal &&
      nativeSearchTestAttempts[s] === {{"Series", "Computed"}}]],
  True, TestID -> "native-search-series-exclusive-option-preserves-native-delayed-option-counts"]

VerificationTest[
  Quiet[Module[{x, a, s, inside, outside, assumptions = 0},
    Block[{$Assumptions = a > 0},
      s = AsymptoticExpansion[{Sqrt[a^2] Exp[x], Sin[x]}, x -> 0,
        Assumptions :> (assumptions++; $Assumptions), SeriesTermGoal -> 0];
      inside = $Assumptions === (a > 0)];
    outside = Block[{$Assumptions = a < 0}, Normal[s] === {a, x}];
    MatchQ[s, _GeneralizedSeries] && inside && outside && assumptions === 1 &&
      s["AmbientAssumptions"] === (a > 0) &&
      nativeSearchTestAttempts[s] === {{"Asymptotic", "Unresolved"}, {"Series", "Computed"}}]],
  True, TestID -> "native-search-shared-assumptions-use-captured-construction-context"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[Exp[x], {x, 0, 3}];
    MatchQ[s, _GeneralizedSeries] && s["Kind"] =!= "Native" &&
      Normal[s] === 1 + x + x^2/2 && s["RemainderPower"] === 3 &&
      ! KeyExistsQ[s[[1]], "NativeAttempts"] &&
      MatchQ[AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> 0, "Backend" -> "Package"], Failure["InvalidCutoff", _Association]]],
  True, TestID -> "native-search-keeps-successful-package-cutoffs-and-invalid-package-goals"]
