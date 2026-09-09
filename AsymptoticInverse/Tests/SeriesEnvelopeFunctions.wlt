(* The expected bounds follow from the mean-value inequality for Log/Exp
   and the global real Lipschitz bounds for Abs, Sin and Cos. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

envelopeFunctionFixture[e_, r_, x_Symbol] := PowerLogSeries[<|
  "Kind" -> "Derived", "Scale" -> "Composite", "Expression" -> e, "Remainder" -> r,
  "Variable" -> x, "Assumptions" -> True, "TargetDomain" -> 0 < x < 1,
  "SeriesApproach" -> <|"Variable" -> x, "Point" -> 0, "Direction" -> "FromAbove"|>|>];
envelopeFunctionMatches[s_, expression_, bound_, assumptions_] :=
  MatchQ[s, _PowerLogSeries] && TrueQ[FullSimplify[
    Normal[s] == expression && s["RemainderScaleExpression"] == bound, assumptions]];

VerificationTest[Module[{x, a, result},
  a = envelopeFunctionFixture[2 + x, PowerLogRemainder[x, 2, 0], x];
  result = Log[a];
  {envelopeFunctionMatches[result, Log[2 + x], x^2/(2 + x), 0 < x < 1],
    result["Scale"] === "Composite", result["CompositeRecipe"]["FunctionHead"] === Log,
    result["CompositeRecipe"]["RelativeRemainderLimit"] === 0,
    TrueQ[result["TargetDomain"] /. x -> 1/2], (result["TargetDomain"] /. x -> 2) === False}],
  {True, True, True, True, True, True},
  TestID -> "envelope-logarithm-transports-relative-error-and-retains-the-domain"]

VerificationTest[Module[{x, a, result},
  a = envelopeFunctionFixture[1/x, PowerLogRemainder[x, 2, 1], x];
  result = Exp[a];
  {envelopeFunctionMatches[result, Exp[1/x], Exp[1/x] x^2 (1 + Abs[Log[x]]), 0 < x < 1],
    result["CompositeRecipe"]["AbsoluteRemainderLimit"] === 0,
    result["Exact"] === False}],
  {True, True, True},
  TestID -> "envelope-exponential-retains-growing-exact-carrier-and-small-absolute-error"]

VerificationTest[Module[{x, negative, pure, absoluteNegative, absolutePure},
  negative = envelopeFunctionFixture[-x, PowerLogRemainder[x, 3, 0], x];
  pure = envelopeFunctionFixture[0, PowerLogRemainder[x, 2, 0], x];
  absoluteNegative = Abs[negative]; absolutePure = Abs[pure];
  {envelopeFunctionMatches[absoluteNegative, x, x^3, 0 < x < 1],
    envelopeFunctionMatches[absolutePure, 0, x^2, 0 < x < 1],
    absolutePure["CompositeRecipe"]["LipschitzConstant"] === 1,
    absolutePure["Remainder"] =!= 0}],
  {True, True, True, True},
  TestID -> "envelope-absolute-value-handles-negative-and-pure-remainder-inputs"]

VerificationTest[Module[{x, phase, sine, cosine},
  phase = envelopeFunctionFixture[1/x, PowerLogRemainder[x, 2, 0], x];
  sine = Sin[phase]; cosine = Cos[phase];
  {envelopeFunctionMatches[sine, Sin[1/x], x^2, 0 < x < 1],
    envelopeFunctionMatches[cosine, Cos[1/x], x^2, 0 < x < 1],
    sine["CompositeRecipe"]["LipschitzConstant"] === 1,
    cosine["CompositeRecipe"]["LipschitzConstant"] === 1}],
  {True, True, True, True},
  TestID -> "envelope-sine-and-cosine-keep-an-unbounded-real-phase-without-Taylor-reexpansion"]

VerificationTest[Module[{x, exact, phase, sine, cosine},
  exact = AsymptoticExpansion[1/x, {x, 0, 2}];
  phase = AsymptoticExpansion[1/x + Sin[x], {x, 0, 3}];
  sine = Sin[phase]; cosine = Cos[phase];
  {envelopeFunctionMatches[Sin[exact], Sin[1/x], 0, x > 0],
    envelopeFunctionMatches[Cos[exact], Cos[1/x], 0, x > 0],
    envelopeFunctionMatches[sine, Sin[1/x + x], x^3, x > 0],
    envelopeFunctionMatches[cosine, Cos[1/x + x], x^3, x > 0],
    sine["Scale"] === "Composite", FailureQ[Tan[phase]]}],
  {True, True, True, True, True, True},
  TestID -> "envelope-ordinary-unbounded-phase-enters-the-Lipschitz-fallback-and-keeps-its-error"]

VerificationTest[Module[{x, unresolved},
  unresolved = envelopeFunctionFixture[0, PowerLogRemainder[x, 0, 0], x];
  {envelopeFunctionMatches[Sin[unresolved], 0, 1, 0 < x < 1],
    envelopeFunctionMatches[Cos[unresolved], 1, 1, 0 < x < 1],
    envelopeFunctionMatches[Abs[unresolved], 0, 1, 0 < x < 1],
    FailureQ[Exp[unresolved]]}],
  {True, True, True, True},
  TestID -> "envelope-Lipschitz-observables-need-no-smallness-but-exponential-does"]

VerificationTest[Module[{x, negative, uncertain, pure},
  negative = envelopeFunctionFixture[-x, PowerLogRemainder[x, 2, 0], x];
  uncertain = envelopeFunctionFixture[x, PowerLogRemainder[x, 1, 0], x];
  pure = envelopeFunctionFixture[0, PowerLogRemainder[x, 2, 0], x];
  {FailureQ[Log[negative]], FailureQ[Log[uncertain]], FailureQ[Log[pure]],
    envelopeFunctionMatches[Exp[pure], 1, x^2, 0 < x < 1]}],
  {True, True, True, True},
  TestID -> "envelope-logarithm-rejects-nonpositive-or-unresolved-relative-error"]

VerificationTest[Module[{x, zero, one, exponential, logarithm},
  zero = envelopeFunctionFixture[0, 0, x]; one = envelopeFunctionFixture[1, 0, x];
  exponential = Exp[zero]; logarithm = Log[one];
  {envelopeFunctionMatches[exponential, 1, 0, 0 < x < 1],
    envelopeFunctionMatches[logarithm, 0, 0, 0 < x < 1],
    exponential["Exact"] === True, logarithm["Exact"] === True,
    (exponential["TargetDomain"] /. x -> 2) === False}],
  {True, True, True, True, True},
  TestID -> "envelope-unary-exact-values-keep-exactness-and-target-domain"]

VerificationTest[Module[{x, a, nested},
  a = envelopeFunctionFixture[2 + x, PowerLogRemainder[x, 2, 0], x];
  nested = SeriesNormalize[Sin[Log[a]]];
  {envelopeFunctionMatches[nested, Sin[Log[2 + x]], x^2/(2 + x), 0 < x < 1],
    nested["CompositeRecipe"]["FunctionHead"] === Sin,
    MatchQ[SeriesNormalize[Log[a], "Cutoff" -> 3], Failure["UnsupportedCompositeCutoff", _]]}],
  {True, True, True},
  TestID -> "envelope-nested-unary-normalization-keeps-composite-error-and-rejects-single-cutoff"]

VerificationTest[Module[{x, y, inverse, result, core},
  inverse = AsymptoticInverse[LogGamma[x], {x, Infinity}, y, SeriesTermGoal -> 1];
  result = Log[inverse + 1]; core = y/ProductLog[y/E];
  {envelopeFunctionMatches[result, Log[1 + core], 1/(1 + core), y > E],
    result["Scale"] === "Composite", result["Remainder"] =!= 0,
    result["CompositeRecipe"]["RelativeRemainderLimit"] === 0}],
  {True, True, True, True},
  TestID -> "envelope-logarithm-of-shifted-inverse-Gamma-retains-the-Lambert-core-and-error"]

VerificationTest[Module[{x, inconsistent},
  inconsistent = PowerLogSeries[<|"Kind" -> "Derived", "Scale" -> "Composite", "Expression" -> 2,
    "Remainder" -> PowerLogRemainder[x, 2, 0], "Variable" -> x, "Assumptions" -> True,
    "TargetDomain" -> False, "SeriesApproach" -> <|"Variable" -> x, "Point" -> 0, "Direction" -> "FromAbove"|>|>];
  {FailureQ[Log[inconsistent]], FailureQ[inconsistent^(-1)]}],
  {True, True}, TestID -> "envelope-unary-proofs-reject-a-contradictory-input-domain"]
