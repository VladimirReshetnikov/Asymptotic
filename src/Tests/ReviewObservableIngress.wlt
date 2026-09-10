(* A requested Taylor order is not evidence that the provider returned it.
   The rational fixture reports a truthful short expansion independently of
   the package. Other providers deliberately return the wrong chart or a
   nonregular lattice so that the public ingress must reject those results. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

ClearAll[reviewObservableShort, reviewObservableWrongVariable,
  reviewObservableWrongCenter, reviewObservableFractional,
  reviewObservablePole, reviewObservableForeignVariable, reviewObservablePointSpike];
reviewObservableShort[0] = 1;
reviewObservableShort[t_?NumericQ] := 1/(1 - t);
reviewObservableShort /: HoldPattern[System`Series[reviewObservableShort[arg_],
    {v_Symbol, 0, n_Integer}, opts___]] :=
  System`Series[1/(1 - arg), {v, 0, Min[n, 1]}, opts];
reviewObservableWrongVariable[0] = 1;
reviewObservableWrongVariable /: HoldPattern[System`Series[reviewObservableWrongVariable[arg_],
    {v_Symbol, 0, n_Integer}, opts___]] :=
  SeriesData[reviewObservableForeignVariable, 0, {1, 1}, 0, n + 1, 1];
reviewObservableWrongCenter[0] = 1;
reviewObservableWrongCenter /: HoldPattern[System`Series[reviewObservableWrongCenter[arg_],
    {v_Symbol, 0, n_Integer}, opts___]] :=
  SeriesData[v, 1, {1, 1}, 0, n + 1, 1];
reviewObservableFractional[0] = 1;
reviewObservableFractional /: HoldPattern[System`Series[reviewObservableFractional[arg_],
    {v_Symbol, 0, n_Integer}, opts___]] := SeriesData[v, 0, {1, 1}, 0, 2 n + 1, 2];
reviewObservablePole[0] = 1;
reviewObservablePole /: HoldPattern[System`Series[reviewObservablePole[arg_],
    {v_Symbol, 0, n_Integer}, opts___]] := SeriesData[v, 0, {1}, -1, n + 1, 1];
reviewObservablePointSpike[0] = 7;
reviewObservablePointSpike[t_?NumericQ] := 1 + t;
reviewObservablePointSpike /: HoldPattern[System`Series[reviewObservablePointSpike[arg_],
    {v_Symbol, 0, n_Integer}, opts___]] := System`Series[1 + arg, {v, 0, n}, opts];

VerificationTest[
  Module[{u, raw},
    raw = Series[reviewObservableShort[u], {u, 0, 5}, Assumptions -> u > 0];
    Head[raw] === SeriesData && raw[[1]] === u && raw[[2]] === 0 &&
      raw[[5]] === 2 && Normal[raw] === 1 + u &&
      reviewObservableShort[1/5] === 5/4],
  True, TestID -> "review-observable-native-provider-establishes-truthful-short-rational-series"]

VerificationTest[
  Module[{x, z, s},
    s = AsymptoticExpansion[x, {x, 0, 5}, "Backend" -> "Package"];
    MatchQ[SeriesObservable[s, reviewObservableShort[z], z, "Cutoff" -> 3],
      Failure["InsufficientObservableNativeOrder", _Association]]],
  True, TestID -> "review-observable-short-endpoint-cannot-hide-required-quadratic-coefficient"]

VerificationTest[
  Module[{x, z, s, r},
    s = AsymptoticExpansion[x, {x, 0, 5}, "Backend" -> "Package"];
    r = SeriesObservable[s, reviewObservableShort[z], z, "Cutoff" -> 2];
    MatchQ[r, _GeneralizedSeries] && Normal[r] === 1 + x && r["RemainderPower"] === 2],
  True, TestID -> "review-observable-endpoint-equal-to-exclusive-demand-is-sufficient"]

VerificationTest[
  Module[{x, z, s, accepted, rejected},
    s = AsymptoticExpansion[x^2, {x, 0, 6}, "Backend" -> "Package"];
    accepted = SeriesObservable[s, reviewObservableShort[z], z, "Cutoff" -> 4];
    rejected = SeriesObservable[s, reviewObservableShort[z], z, "Cutoff" -> 5];
    MatchQ[accepted, _GeneralizedSeries] && Normal[accepted] === 1 + x^2 &&
      accepted["RemainderPower"] === 4 &&
      MatchQ[rejected, Failure["InsufficientObservableNativeOrder", _Association]]],
  True, TestID -> "review-observable-coefficient-demand-scales-with-inner-valuation"]

VerificationTest[
  Module[{x, z, s, r},
    s = AsymptoticExpansion[x, {x, 0, 5}, "Backend" -> "Package"];
    r = SeriesObservable[s, Cos[z], z, "Cutoff" -> 4];
    MatchQ[r, _GeneralizedSeries] && Normal[r] === 1 - x^2/2 && r["RemainderPower"] === 4],
  True, TestID -> "review-observable-interior-zero-coefficients-remain-known"]

VerificationTest[
  Module[{x, z, s},
    s = AsymptoticExpansion[x, {x, 0, 4}, "Backend" -> "Package"];
    MatchQ[SeriesObservable[s, reviewObservableWrongVariable[z], z, "Cutoff" -> 3],
      Failure["InvalidObservableNativeChart", _Association]]],
  True, TestID -> "review-observable-native-variable-must-match-requested-dummy"]

VerificationTest[
  Module[{x, z, s},
    s = AsymptoticExpansion[x, {x, 0, 4}, "Backend" -> "Package"];
    MatchQ[SeriesObservable[s, reviewObservableWrongCenter[z], z, "Cutoff" -> 3],
      Failure["InvalidObservableNativeChart", _Association]]],
  True, TestID -> "review-observable-native-center-must-match-requested-zero"]

VerificationTest[
  Module[{x, z, s},
    s = AsymptoticExpansion[x, {x, 0, 4}, "Backend" -> "Package"];
    And @@ (MatchQ[#, Failure["UnsupportedObservable", _Association]] & /@ {
      SeriesObservable[s, reviewObservableFractional[z], z, "Cutoff" -> 3],
      SeriesObservable[s, reviewObservablePole[z], z, "Cutoff" -> 3]})],
  True, TestID -> "review-observable-regular-import-does-not-admit-puiseux-or-pole-data"]

VerificationTest[
  Module[{x, z, s, r},
    s = AsymptoticExpansion[1 - x, {x, 0, 2}, "Backend" -> "Package"];
    r = SeriesObservable[s, FractionalPart[z], z, "Cutoff" -> 2];
    MatchQ[r, _GeneralizedSeries] && Normal[r] === 1 - x && r["RemainderPower"] === 2],
  True, TestID -> "review-observable-left-germ-keeps-native-constant-at-jump"]

VerificationTest[
  Module[{x, z, s, r},
    s = AsymptoticExpansion[1 + x, {x, 0, 2}, "Backend" -> "Package"];
    r = SeriesObservable[s, FractionalPart[z], z, "Cutoff" -> 2];
    MatchQ[r, _GeneralizedSeries] && Normal[r] === x && r["RemainderPower"] === 2],
  True, TestID -> "review-observable-right-germ-zero-constant-is-preserved"]

VerificationTest[
  Module[{x, z, s, r},
    s = AsymptoticExpansion[1, {x, 0, 2}, "Backend" -> "Package"];
    r = SeriesObservable[s, FractionalPart[z], z];
    MatchQ[r, _GeneralizedSeries] && Normal[r] === 0 && r["Remainder"] === 0],
  True, TestID -> "review-observable-exact-point-uses-actual-value-at-jump"]

VerificationTest[
  Module[{x, z, s},
    s = AsymptoticExpansion[1 - x, {x, 0, 1}, "Backend" -> "Package"];
    MatchQ[SeriesObservable[s, FractionalPart[z], z],
      Failure["UnprovedObservableApproach", _Association]]],
  True, TestID -> "review-observable-pure-uncertainty-cannot-select-one-side-of-jump"]

VerificationTest[
  Module[{x, z, s, r},
    s = AsymptoticExpansion[1/2 + x, {x, 0, 2}, "Backend" -> "Package"];
    r = SeriesObservable[s, FractionalPart[z], z, "Cutoff" -> 2];
    MatchQ[r, _GeneralizedSeries] && Normal[r] === 1/2 + x],
  True, TestID -> "review-observable-fractional-part-away-from-jump-remains-supported"]

VerificationTest[
  Module[{x, z, s, r},
    s = AsymptoticExpansion[1 + x Log[x], {x, 0, 2}, "Backend" -> "Package"];
    r = SeriesObservable[s, FractionalPart[z], z, "Cutoff" -> 2];
    MatchQ[r, _GeneralizedSeries] && Expand[Normal[r] - (1 + x Log[x])] === 0],
  True, TestID -> "review-observable-leading-logarithm-proves-negative-approach"]

VerificationTest[
  Module[{x, z, a, s, r},
    s = AsymptoticExpansion[a x, {x, 0, 4}, "Backend" -> "Package", Assumptions -> Element[a, Reals]];
    r = SeriesObservable[s, Sin[z], z, "Cutoff" -> 4];
    MatchQ[r, _GeneralizedSeries] && Expand[Normal[r] - (a x - a^3 x^3/6)] === 0 &&
      r["RemainderPower"] === 4],
  True, TestID -> "review-observable-common-two-sided-taylor-germ-handles-unproved-sign"]

VerificationTest[
  Module[{x, z, a, s},
    s = AsymptoticExpansion[1 + a x, {x, 0, 3}, "Backend" -> "Package", Assumptions -> Element[a, Reals]];
    MatchQ[SeriesObservable[s, FractionalPart[z], z],
      Failure["UnprovedObservableApproach", _Association]]],
  True, TestID -> "review-observable-unproved-leading-sign-cannot-choose-jump-germ"]

VerificationTest[
  Module[{x, z, s, r},
    s = AsymptoticExpansion[x, {x, 0, 1}, "Backend" -> "Package"];
    r = SeriesObservable[s, Sin[z], z];
    MatchQ[r, _GeneralizedSeries] && Normal[r] === 0 && r["RemainderPower"] === 1],
  True, TestID -> "review-observable-two-sided-regular-bound-transports-pure-uncertainty"]

VerificationTest[
  Module[{x, z, s, r},
    s = AsymptoticExpansion[Sin[x], {x, 0, 3}, "Backend" -> "Package"];
    r = SeriesObservable[s, ArcSin[2 + z] + ArcCos[2 + z], z];
    MatchQ[r, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[r] == Pi/2, x > 0]]],
  True, TestID -> "review-observable-complete-coefficient-cancellation-stays-after-native-import"]

VerificationTest[
  Module[{x, z, s, point},
    s = AsymptoticExpansion[x, {x, 0, 5}, "Backend" -> "Package"];
    point = AsymptoticExpansion[1, {x, 0, 2}, "Backend" -> "Package"];
    MatchQ[SeriesObservable[s, Sin[z], z, "Cutoff" -> 4, "MaxTerms" -> 2],
      Failure["ResourceLimit", _Association]] &&
      MatchQ[SeriesObservable[point, FractionalPart[z], z, "MaxTerms" -> 0],
        Failure["InvalidOption", _Association]]],
  True, TestID -> "review-observable-taylor-budget-and-exact-point-option-validation-remain-enforced"]

VerificationTest[
  Module[{x, z, s, r},
    s = AsymptoticExpansion[x Log[x], {x, 0, 2}, "Backend" -> "Package"];
    r = SeriesObservable[s, reviewObservableShort[z], z, "Cutoff" -> 2];
    MatchQ[r, _GeneralizedSeries] && Expand[Normal[r] - (1 + x Log[x])] === 0 &&
      r["RemainderPower"] === 2 && r["RemainderLogDegree"] === 2],
  True, TestID -> "review-observable-equal-endpoint-retains-logarithmic-taylor-tail-degree"]

VerificationTest[
  Module[{x, z, s, r},
    s = AsymptoticExpansion[x Log[x] + x^2 Log[x]^5, {x, 0, 2}, "Backend" -> "Package"];
    r = SeriesObservable[s, reviewObservableShort[z], z, "Cutoff" -> 3];
    MatchQ[r, _GeneralizedSeries] && Expand[Normal[r] - (1 + x Log[x])] === 0 &&
      r["RemainderPower"] === 2 && r["RemainderLogDegree"] === 5],
  True, TestID -> "review-observable-native-endpoint-does-not-discard-stronger-input-log-degree"]

VerificationTest[
  Module[{x, z, a, uncertain, point, r},
    uncertain = AsymptoticExpansion[a x, {x, 0, 3}, "Backend" -> "Package", Assumptions -> Element[a, Reals]];
    point = AsymptoticExpansion[0, {x, 0, 3}, "Backend" -> "Package"];
    r = SeriesObservable[point, reviewObservablePointSpike[z], z];
    MatchQ[SeriesObservable[uncertain, reviewObservablePointSpike[z], z],
      Failure["UnprovedObservableApproach", _Association]] &&
      MatchQ[r, _GeneralizedSeries] && Normal[r] === 7 && r["Remainder"] === 0],
  True, TestID -> "review-observable-possibly-attained-point-needs-point-value-compatibility"]

VerificationTest[
  Module[{x, z, a, s, r},
    s = AsymptoticExpansion[x, {x, 0, 3}, "Backend" -> "Package", Assumptions -> a^2 == -1];
    r = SeriesObservable[s, a Re[a z], z];
    MatchQ[r, Failure["UnprovedObservableArgument", _Association]] &&
      And @@ (TrueQ[FullSimplify[a Re[a x] /. a -> #, x > 0] == 0] & /@ {I, -I})],
  True, TestID -> "review-observable-real-axis-taylor-cannot-follow-complex-displacement"]

VerificationTest[
  Module[{x, z, a, s},
    (* The cubic input frontier discards the imaginary fifth-power term in
       the intermediate jet. The complete inner expression still detects it. *)
    s = AsymptoticExpansion[Sin[x], {x, 0, 3}, "Backend" -> "Package", Assumptions -> a^2 == -1];
    MatchQ[SeriesObservable[s, Re[z + a z^5], z, "Cutoff" -> 3],
      Failure["UnprovedObservableArgument", _Association]]],
  True, TestID -> "review-observable-discarded-imaginary-argument-is-not-certified-real"]

VerificationTest[
  Module[{x, z, a, s, r},
    s = AsymptoticExpansion[x, {x, 0, 3}, "Backend" -> "Package", Assumptions -> a^2 == -1];
    r = SeriesObservable[s, Re[(a^2 + 2) z], z];
    MatchQ[r, _GeneralizedSeries] && Expand[Normal[r] - x] === 0],
  True, TestID -> "review-observable-complete-real-argument-cancellation-remains-supported"]

VerificationTest[
  Module[{x, z, s, r, expected},
    s = AsymptoticExpansion[1 + x, {x, 0, 4}, "Backend" -> "Package"];
    r = SeriesObservable[s, Sin[Sqrt[z]], z, "Cutoff" -> 3];
    expected = Sin[1] + Cos[1] x/2 - (Cos[1] + Sin[1]) x^2/8;
    MatchQ[r, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[r] == expected]]],
  True, TestID -> "review-observable-local-input-value-domain-proves-complete-argument-real"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[ConditionalExpression[-2 - x, 0 < x < 1],
      {x, 0, 3}, "Backend" -> "Package"];
    (* The formal input value shares the source coordinate's printed symbol.
       Its actual values are below -2, not in the source interval (0,1). *)
    MatchQ[SeriesObservable[s, Re[ArcSin[x]], x],
      Failure["UnprovedObservableArgument", _Association]]],
  True, TestID -> "review-observable-realness-proof-distinguishes-input-value-and-source-coordinate"]

VerificationTest[
  Module[{x, z, s},
    s = AsymptoticExpansion[3 x + x^2, {x, 0, 3}, "Backend" -> "Package"];
    (* ArcSin[(z-x)/x] is real for 0<z<2x with x fixed, but its argument
       becomes 2+x on the represented joint path. *)
    MatchQ[SeriesObservable[s, Re[ArcSin[(z - x)/x]], z],
      Failure["UnprovedObservableArgument", _Association]]],
  True, TestID -> "review-observable-local-realness-proof-cannot-freeze-a-varying-coefficient"]

(* This provider is identically one on the real axis, including zero, and
   zero off that axis. Its real-axis Taylor data are truthful but cannot be
   composed with even a higher-order imaginary displacement. *)
ClearAll[reviewObservableRealAxisOnly];
reviewObservableRealAxisOnly[0] = 1;
reviewObservableRealAxisOnly[t_?NumericQ] := If[TrueQ[Im[t] == 0], 1, 0];
reviewObservableRealAxisOnly /: HoldPattern[System`Series[reviewObservableRealAxisOnly[arg_],
    {v_Symbol, 0, n_Integer}, opts___]] /; arg === v :=
  SeriesData[v, 0, {1}, 0, n + 1, 1];

VerificationTest[
  Module[{u, x, z, a, raw, s, r},
    raw = Series[reviewObservableRealAxisOnly[u], {u, 0, 3}, Assumptions -> u > 0];
    s = AsymptoticExpansion[x, {x, 0, 3}, "Backend" -> "Package", Assumptions -> a^2 == -1];
    r = SeriesObservable[s, reviewObservableRealAxisOnly[Sin[z] + a z^5], z, "Cutoff" -> 3];
    Head[raw] === SeriesData && raw[[5]] === 4 && Normal[raw] === 1 &&
      reviewObservableRealAxisOnly[0] === 1 && reviewObservableRealAxisOnly[1/5] === 1 &&
      And @@ (reviewObservableRealAxisOnly[Sin[1/5] + #/5^5] === 0 & /@ {I, -I}) &&
      MatchQ[r, Failure["UnprovedObservableArgument", _Association]]],
  True, TestID -> "review-observable-truthful-real-axis-provider-cannot-hide-constant-error-from-imaginary-tail"]

ClearAll[reviewObservableRealAxisOnly];
