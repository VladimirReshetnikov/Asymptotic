(* Fixed-parameter bounds cannot be specialized to a moving parameter without
   a joint proof. These oracles use exact rational identities and elementary
   Taylor coefficients; no native Series output supplies the expectations. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
  Module[{x, a, outer, inner, result},
    outer = AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 0, "Backend" -> "Package"];
    inner = AsymptoticExpansion[a, {a, 0, 4}, "Backend" -> "Package"];
    result = SeriesCompose[outer, inner];
    {Normal[result], result["Remainder"], result["Exact"]}],
  {1/2, 0, True},
  TestID -> "review-composition-scope-rational-diagonal-replayed"]

VerificationTest[
  Module[{x, a, outer, inner, result},
    outer = AsymptoticExpansion[1 + x^2/a^2, {x, 0, 2}, Assumptions -> a > 0, "Backend" -> "Package"];
    inner = AsymptoticExpansion[a, {a, 0, 4}, "Backend" -> "Package"];
    result = SeriesCompose[outer, inner];
    {Normal[result], result["Remainder"], result["Exact"]}],
  {2, 0, True},
  TestID -> "review-composition-scope-parameter-hidden-only-in-discarded-source"]

VerificationTest[
  Module[{x, a, outer, inner, result},
    outer = AsymptoticExpansion[Cos[x/a], {x, 0, 2}, Assumptions -> a > 0, "Backend" -> "Package"];
    inner = AsymptoticExpansion[a, {a, 0, 4}, "Backend" -> "Package"];
    result = SeriesCompose[outer, inner];
    {Normal[result], result["Remainder"]}],
  {Cos[1], 0},
  TestID -> "review-composition-scope-nonpolynomial-source-replayed"]

VerificationTest[
  Module[{x, a, outer, inner, result},
    outer = AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 0, "Backend" -> "Package"];
    inner = AsymptoticExpansion[a^2, {a, 0, 5}, "Backend" -> "Package"];
    result = SeriesCompose[outer, inner, "Cutoff" -> 4];
    {Expand[Normal[result] - (a - a^2 + a^3)] === 0,
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 4, 0},
  TestID -> "review-composition-scope-new-regime-retains-rational-tail"]

VerificationTest[
  Module[{x, a, outer, inner, result},
    outer = AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 0, "Backend" -> "Package"];
    inner = AsymptoticExpansion[1/a, {a, Infinity, 7}, "Backend" -> "Package"];
    result = SeriesCompose[outer, inner, "Cutoff" -> 6];
    {Expand[Normal[result] - (a^-2 - a^-4)] === 0,
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 6, 0},
  TestID -> "review-composition-scope-replay-respects-infinite-inner-endpoint"]

VerificationTest[
  Module[{x, a, outer, inner},
    outer = SeriesTruncate[AsymptoticExpansion[1 + x^2/a^2, {x, 0, 3},
      Assumptions -> a > 0, "Backend" -> "Package"], 2];
    inner = AsymptoticExpansion[a, {a, 0, 4}, "Backend" -> "Package"];
    MatchQ[SeriesCompose[outer, inner], Failure["ParameterCapture", _Association]]],
  True,
  TestID -> "review-composition-scope-derived-recipe-retains-hidden-parameter"]

VerificationTest[
  Module[{x, a, outer, inner},
    outer = AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 0, "Backend" -> "Package"];
    inner = AsymptoticExpansion[a + a^2, {a, 0, 2}, "Backend" -> "Package"];
    MatchQ[SeriesCompose[outer, inner], Failure["ParameterCapture", _Association]]],
  True,
  TestID -> "review-composition-scope-inexact-inner-is-not-silently-replaced-by-source"]

VerificationTest[
  Module[{x, a, outer, inner},
    outer = AsymptoticExpansion[Sin[x], {x, 0, 3}, "Backend" -> "Package"];
    (* An externally reconstructed nonexact object without its source has
       no evidence that all fixed parameters were retained. *)
    outer = GeneralizedSeries[KeyDrop[outer[[1]], {"Function", "ForwardModel", "SeriesRecipe"}]];
    inner = AsymptoticExpansion[a, {a, 0, 4}, "Backend" -> "Package"];
    MatchQ[SeriesCompose[outer, inner], Failure["MissingParameterScope", _Association]]],
  True,
  TestID -> "review-composition-scope-unknown-remainder-scope-is-not-inferred-from-coefficients"]

VerificationTest[
  Module[{x, a, outer, inner, result},
    outer = AsymptoticExpansion[x + a, {x, 0, 3}, Assumptions -> a > 0, "Backend" -> "Package"];
    inner = AsymptoticExpansion[a, {a, 0, 4}, "Backend" -> "Package"];
    result = SeriesCompose[outer, inner];
    {Expand[Normal[result] - 2 a] === 0, result["Remainder"], result["Exact"],
      FreeQ[result["Assumptions"], a]}],
  {True, 0, True, True},
  TestID -> "review-composition-scope-exact-outer-preserves-valid-diagonal"]

VerificationTest[
  Module[{x, a, outer, inner, result},
    outer = AsymptoticExpansion[x/a, {x, 0, 3}, Assumptions -> a > 0, "Backend" -> "Package"];
    inner = AsymptoticExpansion[a + a^2, {a, 0, 2}, "Backend" -> "Package"];
    result = SeriesCompose[outer, inner];
    {Normal[result], result["RemainderPower"], result["RemainderLogDegree"]}],
  {1, 1, 0},
  TestID -> "review-composition-scope-exact-outer-transports-amplified-inner-error"]

VerificationTest[
  Module[{x, a, outer, inner},
    outer = AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 1, "Backend" -> "Package"];
    inner = AsymptoticExpansion[a, {a, 0, 4}, "Backend" -> "Package"];
    MatchQ[SeriesCompose[outer, inner], Failure["IncompatibleCompositionParameters", _Association]]],
  True,
  TestID -> "review-composition-scope-old-parameter-domain-must-hold-on-new-path"]

VerificationTest[
  Module[{x, a, outer, inner},
    outer = AsymptoticExpansion[x + a, {x, 0, 3}, Assumptions -> a > 0, "Backend" -> "Package"];
    inner = AsymptoticExpansion[-a, {a, 0, 4}, Direction -> "FromBelow", "Backend" -> "Package"];
    MatchQ[SeriesCompose[outer, inner], Failure["IncompatibleCompositionParameters", _Association]]],
  True,
  TestID -> "review-composition-scope-exact-outer-still-requires-parameter-branch"]

VerificationTest[
  Module[{x, a, outer, inner},
    outer = AsymptoticExpansion[ConditionalExpression[x/(a + x), x < a/2],
      {x, 0, 2}, Assumptions -> a > 0, "Backend" -> "Package"];
    inner = AsymptoticExpansion[a, {a, 0, 4}, "Backend" -> "Package"];
    MatchQ[SeriesCompose[outer, inner], Failure["IncompatibleTargetCondition", _Association]]],
  True,
  TestID -> "review-composition-scope-replay-checks-source-condition-on-joint-path"]

VerificationTest[
  Module[{x, y, outer, inner, result},
    outer = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
    inner = AsymptoticExpansion[x, {x, 0, 5}, "Backend" -> "Package"];
    result = SeriesCompose[outer, inner];
    {Expand[Normal[result] - (x - x^2 + 2 x^3)] === 0,
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 4, 0},
  TestID -> "review-composition-scope-inverse-source-variable-is-bound"]

VerificationTest[
  Module[{x, y, a, outer, inner},
    outer = AsymptoticInverse[x + a x^2, {x, 0}, {y, 4}, Assumptions -> a > 0];
    inner = AsymptoticExpansion[a, {a, 0, 5}, "Backend" -> "Package"];
    MatchQ[SeriesCompose[outer, inner], Failure["ParameterCapture", _Association]]],
  True,
  TestID -> "review-composition-scope-inverse-fixed-parameter-needs-separate-joint-inversion"]

VerificationTest[
  Module[{x, y, outer, inner, result},
    outer = AsymptoticExpansion[Sin[x], {x, 0, 5}, "Backend" -> "Package"];
    inner = AsymptoticExpansion[y^2, {y, 0, 11}, "Backend" -> "Package"];
    result = SeriesCompose[outer, inner];
    {Expand[Normal[result] - (y^2 - y^6/6)] === 0, result["RemainderPower"]}],
  {True, 10},
  TestID -> "review-composition-scope-independent-new-variable-control"]

VerificationTest[
  Module[{x, outer, inner, result},
    outer = AsymptoticExpansion[Sin[x], {x, 0, 5}, "Backend" -> "Package"];
    inner = AsymptoticExpansion[x^2, {x, 0, 11}, "Backend" -> "Package"];
    result = SeriesCompose[outer, inner];
    {Expand[Normal[result] - (x^2 - x^6/6)] === 0, result["RemainderPower"]}],
  {True, 10},
  TestID -> "review-composition-scope-same-variable-control"]

VerificationTest[
  Module[{x, a, outer, inner, result, refined},
    outer = AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 0, "Backend" -> "Package"];
    inner = AsymptoticExpansion[a^2, {a, 0, 5}, "Backend" -> "Package"];
    result = SeriesCompose[outer, inner, "Cutoff" -> 3];
    refined = SeriesRefine[result, 6];
    {Expand[Normal[refined] - (a - a^2 + a^3 - a^4 + a^5)] === 0,
      refined["RemainderPower"], FreeQ[refined["Function"], x]}],
  {True, 6, True},
  TestID -> "review-composition-scope-refinement-replays-new-joint-source"]

VerificationTest[
  Module[{x, a, outer, inner},
    outer = AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 0, "Backend" -> "Package"];
    inner = AsymptoticExpansion[a, {a, 0, 4}, "Backend" -> "Package"];
    {MatchQ[SeriesCompose[outer, inner, "MaxTerms" -> 0], Failure["InvalidOption", _Association]],
      MatchQ[SeriesCompose[outer, inner, "Cutoff" -> 3.], Failure["InvalidCutoff", _Association]]}],
  {True, True},
  TestID -> "review-composition-scope-option-validation-precedes-replay"]

VerificationTest[
  Module[{x, z, a, outer, inner},
    outer = AsymptoticLogarithmicInverse[x + a x/Log[x], {x, 0}, {z, 4}, Assumptions -> a > 0];
    inner = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {a, 4}];
    {MatchQ[SeriesCompose[outer, inner], Failure["ParameterCapture", _Association]],
      MatchQ[ReciprocalLogCompose[outer, inner], Failure["ParameterCapture", _Association]]}],
  {True, True},
  TestID -> "review-composition-scope-explicit-reciprocal-route-shares-admission"]
