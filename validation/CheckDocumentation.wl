(* Focused documentation checks only. This does not discover or run the package
   regression suite. Run from any directory with:
     wolfram.exe -script validation/CheckDocumentation.wl
   ASYMPTOTIC_VALIDATION_OUTPUT may override the JSON output location.
   Every check, including its exact comparison, has a 60-second bound. *)

documentationRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{documentationRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]];
documentationGuide = Import[FileNameJoin[{documentationRoot, "AsymptoticInverse",
  "Documentation", "UserGuide.md"}], "Text"];

documentationEqual[s_, expected_, assumptions_: True] :=
  MatchQ[s, _PowerLogSeries] && TrueQ[FullSimplify[Normal[s] == expected, assumptions]];
SetAttributes[documentationTest, HoldAll];
documentationTest[id_String, expression_, expected_] := VerificationTest[
  TimeConstrained[Print["Checking: ", id]; expression, 60,
    Failure["DocumentationCheckTimeout", <|"TestID" -> id, "Seconds" -> 60|>]],
  expected, TestID -> id];

documentationReport = TestReport[{
  documentationTest["docs-all-36-public-symbols-have-explicit-guide-anchors",
    Module[{names = Last[StringSplit[#, "`"]] & /@ Names["AsymptoticInverse`*"]},
      {Length[names], Select[names,
        ! StringContainsQ[documentationGuide, "<a id=\"" <> # <> "\"></a>"] &]}],
    {36, {}}],

  documentationTest["docs-getting-started-Catalan-expression-remainder-and-residual",
    Module[{x, y, s}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 5}];
      {documentationEqual[s, y - y^2 + 2 y^3 - 5 y^4],
        s["Remainder"] === PowerLogRemainder[y, 5, 0],
        InverseResidual[s]["ZeroBelowCutoff"]}], {True, True, True}],

  documentationTest["docs-irrational-cotangent-exclusive-cutoff",
    Module[{x, s}, s = AsymptoticExpansion[Cot[x^Sqrt[2]], {x, 0, 5}];
      documentationEqual[s, x^-Sqrt[2] - x^Sqrt[2]/3 - x^(3 Sqrt[2])/45, x > 0]], True],

  documentationTest["docs-logarithmic-inverse-complete-block-and-log-remainder",
    Module[{x, y, s},
      s = AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}];
      {documentationEqual[s, y - y^2 (1 + Log[y]) + y^3 (3 + 5 Log[y] + 2 Log[y]^2), y > 0],
        s["Remainder"] === PowerLogRemainder[y, 4, 3]}], {True, True}],

  documentationTest["docs-requested-callable-irrational-inverse-at-infinity",
    Module[{x, s, expected},
      s = AsymptoticExpansion[InverseFunction[
        x |-> ConditionalExpression[x + x^Sqrt[2], x > 0]],
        x -> Infinity, SeriesTermGoal -> 5];
      expected = x^(1/Sqrt[2]) - x^(Sqrt[2] - 1)/Sqrt[2]
        + (3 - Sqrt[2])/4 x^(3/Sqrt[2] - 2)
        + (6 - 5 Sqrt[2])/6 x^(2 Sqrt[2] - 3)
        + (235 - 162 Sqrt[2])/96 x^(5/Sqrt[2] - 4);
      {documentationEqual[s, expected, x > 0], Length[s["Terms"]],
        TrueQ[FullSimplify[s["RemainderPower"] == 5 - 3 Sqrt[2]]],
        s["RemainderVariable"] === 1/x, s["RemainderLogDegree"]}],
    {True, 5, True, True, 0}],

  documentationTest["docs-requested-Gamma-square-prefactor-and-five-blocks",
    Module[{x, s, prefactor}, prefactor = 2 Pi Exp[-2 x] x^(2 x - 1);
      s = AsymptoticExpansion[Gamma[x]^2, x -> Infinity, SeriesTermGoal -> 5];
      {documentationEqual[s, prefactor (1 + 1/(6 x) + 1/(72 x^2)
          - 31/(6480 x^3) - 139/(155520 x^4)), x > 0],
        s["ReturnedTermCount"], s["RemainderPower"],
        TrueQ[FullSimplify[s["Remainder"] == prefactor PowerLogRemainder[1/x, 5, 0], x > 0]]}],
    {True, 5, 5, True}],

  documentationTest["docs-requested-Gamma-ratio-prefactor-metadata-and-remainder",
    Module[{x, s, prefactor}, prefactor = 3^(3 x - 1/2) x^(2 x) Exp[-2 x];
      s = AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
      {documentationEqual[s, prefactor (1 - 1/(18 x) + 1/(648 x^2)
          + 463/(174960 x^3) - 1867/(12597120 x^4)), x > 0],
        s["RemainderPower"], s["ReturnedTermCount"],
        s["LogarithmicFunction"] === LogGamma[3 x] - LogGamma[x],
        TrueQ[FullSimplify[s["Remainder"] == prefactor PowerLogRemainder[1/x, 5, 0], x > 0]]}],
    {True, 5, 5, True, True}],

  documentationTest["docs-varying-Gamma-power-constant-in-prefactor",
    Module[{x, s}, s = AsymptoticExpansion[Gamma[x]^x, x -> Infinity, SeriesTermGoal -> 3];
      {documentationEqual[s, Exp[1/12] (Sqrt[2 Pi] x^(x - 1/2) Exp[-x])^x
          (1 - 1/(360 x^2) + 1447/(1814400 x^4)), x > 0],
        s["RemainderPower"], s["ReturnedTermCount"]}], {True, 6, 3}],

  documentationTest["docs-exact-Gamma-recurrence-terminates-before-goal",
    Module[{x, s}, s = AsymptoticExpansion[Gamma[x + 1]/Gamma[x], x -> Infinity, SeriesTermGoal -> 5];
      {documentationEqual[s, x, x > 0], s["Remainder"]}], {True, 0}],

  documentationTest["docs-central-binomial-five-correction-blocks",
    Module[{x, s}, s = AsymptoticExpansion[Binomial[2 x, x], x -> Infinity, SeriesTermGoal -> 5];
      documentationEqual[s, 4^x/Sqrt[Pi x] (1 - 1/(8 x) + 1/(128 x^2)
        + 5/(1024 x^3) - 21/(32768 x^4)), x > 0]], True],

  documentationTest["docs-elementary-exponential-growth",
    Module[{x, s}, s = AsymptoticExpansion[Exp[x + 1/x], x -> Infinity, SeriesTermGoal -> 5];
      documentationEqual[s, Exp[x] (1 + 1/x + 1/(2 x^2) + 1/(6 x^3) + 1/(24 x^4)), x > 0]], True],

  documentationTest["docs-exact-inverse-of-flat-forward-expression",
    Module[{x, y, s}, s = AsymptoticInverse[Exp[-1/x], {x, 0}, y, SeriesTermGoal -> 3];
      {documentationEqual[s, -1/Log[y], 0 < y < 1], s["Remainder"]}], {True, 0}],

  documentationTest["docs-negative-source-side-selects-negative-root",
    Module[{x, y, s}, s = AsymptoticInverse[x^2, {x, 0}, {y, 2}, Direction -> "FromBelow"];
      {documentationEqual[s, -Sqrt[y], y > 0], s["Remainder"]}], {True, 0}],

  documentationTest["docs-symbolic-perturbation-depth",
    Module[{x, y, a, p, s},
      s = AsymptoticInverse[x + a x^(1 + p), {x, 0}, {y, 2},
        "Truncation" -> "Depth", Assumptions -> p > 0 && Element[a, Reals]];
      documentationEqual[s, y - a y^(1 + p) + a^2 (1 + p) y^(1 + 2 p),
        y > 0 && p > 0 && Element[a, Reals]]], True],

  documentationTest["docs-SeriesLog-explicit-cutoff",
    Module[{x, s}, s = AsymptoticExpansion[x + x^2, {x, 0, 5}];
      documentationEqual[SeriesLog[s, 4], Log[x] + x - x^2/2 + x^3/3, x > 0]], True],

  documentationTest["docs-SeriesExp-retains-nonvanishing-exponent",
    Module[{x, s}, s = AsymptoticExpansion[1/x + Log[x] + x, {x, 0, 5}];
      documentationEqual[SeriesExp[s, 4], x Exp[1/x] (1 + x + x^2/2 + x^3/6), x > 0]], True],

  documentationTest["docs-SeriesCompose-transports-inner-scale",
    Module[{x, y, outer, inner},
      outer = AsymptoticExpansion[Sin[x], {x, 0, 5}];
      inner = AsymptoticExpansion[y^2 + y^3, {y, 0, 7}];
      documentationEqual[SeriesCompose[outer, inner, "Cutoff" -> 8],
        y^2 + y^3 - y^6/6 - y^7/2, y > 0]], True],

  documentationTest["docs-SeriesObservable-analytic-substitution",
    Module[{x, z, s}, s = AsymptoticExpansion[x + x^2, {x, 0, 5}];
      documentationEqual[SeriesObservable[s, Sin[z], z, "Cutoff" -> 4], x + x^2 - x^3/6]], True],

  documentationTest["docs-refinement-preserves-declared-input-ceiling",
    Module[{x, y, s, limited}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 2}];
      limited = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}, "InputRemainder" -> {3, 0}];
      {documentationEqual[SeriesRefine[s, 5], y - y^2 + 2 y^3 - 5 y^4],
        MatchQ[SeriesRefine[limited, 8], Failure["InsufficientInputOrder", _Association]]}], {True, True}],

  documentationTest["docs-rational-interval-certificate-target-accuracy",
    Module[{x, y, s, certificate}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
      certificate = InverseCertificate[s, 1/10, "Interval" -> {1/20, 1/5}, "TargetError" -> 10^-12];
      {certificate["Certified"], TrueQ[certificate["CertifiedErrorBound"] <= 10^-12]}], {True, True}],

  documentationTest["docs-exact-core-marker-depth-and-first-omitted-term",
    Module[{x, y, s}, s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 2}];
      {documentationEqual[s, y - y^2 + 2 y^3], s["FirstOmittedMarkerTerm"] === -5 y^4}], {True, True}],

  documentationTest["docs-exponential-core-retains-exact-Lambert-inverse",
    Module[{x, y, s},
      s = AsymptoticExponentialCoreInverse[x Exp[x], x^2, {x, Infinity}, {y, 1}];
      documentationEqual[s, ProductLog[y] - ProductLog[y]^3/((1 + ProductLog[y]) y), y > 0]], True],

  documentationTest["docs-reciprocal-logarithmic-inverse-and-residual",
    Module[{x, y, s}, s = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, 4}];
      {documentationEqual[s, y (1 - 1/Log[y] + 1/Log[y]^2 - 2/Log[y]^3), 0 < y < 1],
        LogarithmicInverseResidual[s]["ZeroBelowCutoff"]}], {True, True}],

  documentationTest["docs-flat-sectors-retain-complete-third-sector",
    Module[{x, y, s}, s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 3}];
      documentationEqual[s, y - Exp[-1/y] + Exp[-2/y]/y^2
        + (1/y^3 - 3/(2 y^4)) Exp[-3/y], y > 0]], True],

  documentationTest["docs-Fourier-logarithmic-coefficients",
    Module[{x, y, s}, s = AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 4}];
      documentationEqual[s, y - y^2 Sin[Log[y]]
        + y^3 Sin[Log[y]] (2 Sin[Log[y]] + Cos[Log[y]]), y > 0]], True],

  documentationTest["docs-quadratic-threshold-affine-target-and-zero-remainder",
    Module[{x, y, s}, s = AsymptoticSpecialInverse["QuadraticThreshold", {x, 3}, {y, 2},
        "TargetOffset" -> 7, "TargetScale" -> -2, "QuadraticCoefficient" -> 3];
      {documentationEqual[s, 3 + Sqrt[(7 - y)/6], y < 7], s["Remainder"]}], {True, 0}]
}, ProgressReporting -> False];

Print["Kernel: ", $Version];
Print["Documentation checks succeeded: ", documentationReport["TestsSucceededCount"],
  "   Failed: ", documentationReport["TestsFailedCount"]];
Do[If[result["Outcome"] =!= "Success",
  Print["FAILED ", result["TestID"], "\n   expected: ", ToString[result["ExpectedOutput"], InputForm],
    "\n   actual:   ", ToString[result["ActualOutput"], InputForm],
    "\n   messages: ", ToString[result["ActualMessages"], InputForm]]],
  {result, Values[documentationReport["TestResults"]]}];
documentationOutput = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[! StringQ[documentationOutput] || StringLength[documentationOutput] == 0,
  documentationOutput = FileNameJoin[{documentationRoot, "validation", "documentation-tests.json"}]];
Export[documentationOutput, <|"Kernel" -> $Version,
  "Scope" -> "Focused documentation examples only; the full package suite was not run.",
  "PerCheckTimeConstraintSeconds" -> 60,
  "Suites" -> {"CheckDocumentation.wl"},
  "Succeeded" -> documentationReport["TestsSucceededCount"],
  "Failed" -> documentationReport["TestsFailedCount"],
  "Results" -> (Join[<|"TestID" -> #["TestID"], "Outcome" -> #["Outcome"]|>,
    If[#["Outcome"] === "Success", <||>, <|
      "ExpectedOutput" -> ToString[#["ExpectedOutput"], InputForm],
      "ActualOutput" -> ToString[#["ActualOutput"], InputForm],
      "ActualMessages" -> ToString[#["ActualMessages"], InputForm]|>]] & /@
      Values[documentationReport["TestResults"]])|>, "RawJSON"];
Exit[If[TrueQ[documentationReport["TestsFailedCount"] == 0], 0, 1]];
