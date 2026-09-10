(* Focused Wolfram documentation checks only. This does not discover or run the package
   regression suite. From the repository root, run:
     wolfram.exe -script validation/CheckDocumentation.wl
   The script resolves its sources relative to its own location.
   ASYMPTOTIC_VALIDATION_OUTPUT may override the JSON output location.
   The default documentation-current-tests.json leaves historical receipts intact.
   Every check, including its exact comparison, has a 60-second bound. *)

documentationEntry = ExpandFileName[$InputFileName];
documentationRoot = DirectoryName[DirectoryName[documentationEntry]];
documentationGuidePath = FileNameJoin[{documentationRoot, "src", "Documentation", "UserGuide.md"}];
documentationKernelFiles = Sort[FileNames["*.wl", FileNameJoin[{documentationRoot, "src", "Kernel"}], Infinity]];
documentationSources = DeleteDuplicates[Join[documentationKernelFiles, {documentationEntry, documentationGuidePath}]];
documentationStarted = AbsoluteTime[];
If[documentationKernelFiles === {} || ! AllTrue[documentationSources, FileExistsQ],
  Print["Missing documentation validation sources: ", Select[documentationSources, ! FileExistsQ[#] &]];
  Exit[1]];
documentationSourceHashes[] := Association[(StringReplace[
    FileNameJoin[Drop[FileNameSplit[#], Length[FileNameSplit[documentationRoot]]]], "\\" -> "/"] ->
      IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ documentationSources];
documentationBefore = Check[documentationSourceHashes[], $Failed];
If[! AssociationQ[documentationBefore], Print["Documentation source hashing failed."]; Exit[1]];
documentationKernelText = Check[Import[#, "Text"] & /@ documentationKernelFiles, $Failed];
documentationGuide = Check[Import[documentationGuidePath, "Text"], $Failed];
If[! MatchQ[documentationKernelText, {__String}] || ! StringQ[documentationGuide],
  Print["Documentation validation input could not be read."]; Exit[1]];
(* Match the declaration-based export inventory used by build_user_guide.py.
   Unrelated public-context helper names do not create documentation requirements. *)
documentationDeclaredSymbols = Sort[DeleteDuplicates[StringCases[
  StringRiffle[documentationKernelText, "\n"],
  RegularExpression["(?m)^(?:AsymptoticAnalysis`)?([A-Za-z][A-Za-z0-9]*)::usage\\s*="] -> "$1"]]];
If[documentationDeclaredSymbols === {}, Print["No public usage declarations were found."]; Exit[1]];
documentationLoaded = CheckAbort[TimeConstrained[
  Check[Get[FileNameJoin[{documentationRoot, "src", "Kernel", "AsymptoticAnalysis.wl"}]], $Failed],
  60, $Aborted], $Aborted];
If[MemberQ[{$Failed, $Aborted}, documentationLoaded] || ! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Print["Package loading failed; no documentation examples were run."]; Exit[1]];

documentationEqual[s_, expected_, assumptions_: True] :=
  MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[s] == expected, assumptions]];
(* Independent formulas displayed in the guide.  The additional a4 is
   obtained by equating the X^-4 coefficient in the finite logarithmic
   Stirling equation; it checks refinement one block beyond the display. *)
documentationGammaCoefficients[q_] := Module[{c = Log[2 Pi], a0, a1, a2, a3, a4},
  a0 = (1 - c q)/2;
  a1 = q/24 - c^2 q^3/8;
  a2 = c q^2 (1 + q - c^2 q^2 - 3 c^2 q^3)/48;
  a3 = -q ((a0 - 1/2) a2 + a1^2/2
    + (-a0^2/2 + a0/2 - 1/12) a1
    + a0^2 (a0 - 1)^2/12 - 1/360);
  a4 = q ((1/2 - a0) a3 + (a0^2/2 - a0/2 + 1/12 - a1) a2
    + (a0/2 - 1/4) a1^2 + (-a0^3/3 + a0^2/2 - a0/6) a1
    + a0^5/20 - a0^4/8 + a0^3/12 - a0/120);
  {a0, a1, a2, a3, a4}];
documentationGammaCore[target_] := target/ProductLog[target/E];
documentationGammaApproximation[target_, count_Integer] := Module[{core, coefficients},
  core = documentationGammaCore[target];
  coefficients = documentationGammaCoefficients[1/Log[core]];
  core + Sum[coefficients[[j + 1]]/core^j, {j, 0, count - 2}]];
documentationGammaEqual[s_, expected_] :=
  MatchQ[s, _GeneralizedSeries] && TrueQ[Together[Normal[s] - expected] === 0];
SetAttributes[documentationTest, HoldAll];
documentationTest[id_String, expression_, expected_] := VerificationTest[
  TimeConstrained[Print["Checking: ", id]; expression, 60,
    Failure["DocumentationCheckTimeout", <|"TestID" -> id, "Seconds" -> 60|>]],
  expected, TestID -> id];

documentationCases = HoldComplete[{
  documentationTest["docs-public-usage-exports-have-exactly-one-guide-anchor",
    Module[{runtimeNames},
      runtimeNames = Sort[Last[StringSplit[#, "`"]] & /@
        Select[Names["AsymptoticAnalysis`*"], StringQ[ToExpression[# <> "::usage", InputForm]] &]];
      {runtimeNames === documentationDeclaredSymbols,
        Select[documentationDeclaredSymbols,
          StringCount[documentationGuide, "<a id=\"" <> # <> "\"></a>"] =!= 1 &]}],
    {True, {}}],

  documentationTest["docs-explicit-native-and-package-orders-have-distinct-contracts",
    Module[{x, analytic, native},
      analytic = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Package"];
      native = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"];
      {documentationEqual[analytic, 1 + x + x^2/2],
        documentationEqual[native, 1 + x + x^2/2 + x^3/6], native["Kind"],
        native["Remainder"], native["Exact"], native["RemainderContract"]}],
    {True, True, "Native", Missing["NativeContract"], Missing["NotEstablished"], "NativeFormalOrder"}],

  documentationTest["docs-precision-selection-sine-cutoff-block-goal-and-native-order",
    Module[{x, cutoff, blocks, native},
      cutoff = AsymptoticExpansion[Sin[x], {x, 0, 5}, "Backend" -> "Package"];
      blocks = AsymptoticExpansion[Sin[x], {x, 0}, SeriesTermGoal -> 2, "Backend" -> "Package"];
      native = AsymptoticExpansion[Sin[x], {x, 0, 5}, "Backend" -> "Series"];
      {documentationEqual[cutoff, x - x^3/6],
        cutoff["Remainder"] === PowerLogRemainder[x, 5, 0],
        documentationEqual[blocks, x - x^3/6],
        blocks["Remainder"] === PowerLogRemainder[x, 5, 0],
        documentationEqual[native, x - x^3/6 + x^5/120], native["NativeBackend"]}],
    {True, True, True, True, True, "Series"}],

  documentationTest["docs-automatic-alias-complex-fallback-and-strict-package-refusal",
    Module[{x, automatic, strict},
      automatic = AsymptoticExpand[Exp[I x], {x, 0, 3}];
      strict = AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Package"];
      {documentationEqual[automatic, 1 + I x - x^2/2 - I x^3/6],
        automatic["NativeBackend"], automatic["BackendSelectionReason"], automatic["OrderConvention"],
        MatchQ[strict, Failure["UnprovedRealCoefficient", _Association]]}],
    {True, "Series", "PackageRepresentation", "Native", True}],

  documentationTest["docs-native-list-zero-goal-search-history",
    Module[{x, s},
      s = Quiet[AsymptoticExpansion[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 0]];
      {s["NativeBackend"], Normal[s] === {1, x},
        ({#["Backend"], #["EvaluationStatus"]} & /@ s["NativeAttempts"])}],
    {"Series", True, {{"Asymptotic", "Unresolved"}, {"Series", "Computed"}}}],

  documentationTest["docs-native-scalar-zero-goal-alias-and-package-refusal",
    Module[{x, s, strict},
      s = Quiet[AsymptoticExpand[Exp[x], x -> 0, SeriesTermGoal -> 0]];
      strict = AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> 0, "Backend" -> "Package"];
      {s["NativeBackend"], Normal[s], s["NativeEvaluationStatus"],
        MatchQ[strict, Failure["InvalidCutoff", _Association]]}],
    {"Series", 1, "Computed", True}],

  documentationTest["docs-logarithmic-remainder-refuses-optional-native-view",
    Module[{x, s}, s = AsymptoticExpansion[x + x^2 Log[x], {x, 0, 2}];
      {s["Remainder"] === PowerLogRemainder[x, 2, 1], s["SeriesData"]}],
    {True, Missing["LogarithmicRemainder",
      <|"RemainderPower" -> 2, "RemainderLogDegree" -> 1|>]}],

  documentationTest["docs-native-index-limit-preserves-sparse-analytic-result",
    Module[{x, large = 2^100, s},
      s = AsymptoticExpansion[1 + x^large, {x, 0, large}, "Backend" -> "Package"];
      {Normal[s], s["Remainder"] === PowerLogRemainder[x, large, 0],
        MatchQ[s["SeriesData"], Missing["NativeSeriesDataRange", _Association]]}],
    {1, True, True}],

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
      {documentationEqual[s, 3 + Sqrt[(7 - y)/6], y < 7], s["Remainder"]}], {True, 0}],

  documentationTest["docs-literal-Gamma-inverse-five-displayed-polynomial-blocks",
    Module[{x, z, s, core},
      s = AsymptoticExpansion[InverseFunction[
        x |-> ConditionalExpression[Gamma[x], x > 2]][z],
        z -> Infinity, SeriesTermGoal -> 5];
      core = documentationGammaCore[Log[z]];
      {documentationGammaEqual[s, documentationGammaApproximation[Log[z], 5]],
        s["CoreInverse"] === core, s["Scale"], s["ReturnedTermCount"],
        s["RemainderPower"], s["RemainderInverseLogPower"],
        s["Remainder"] === PowerLogRemainder[1/core, 4, 0]/Log[core]^2,
        InverseResidual[s]["ZeroBelowCutoff"]}],
    {True, True, "GammaInverse", 5, 4, 2, True, True}],

  documentationTest["docs-negative-reciprocal-Gamma-target-zero-from-below",
    Module[{x, z, s},
      s = AsymptoticInverse[-1/Gamma[x], {x, Infinity}, z, SeriesTermGoal -> 5];
      {documentationGammaEqual[s, documentationGammaApproximation[-Log[-z], 5]],
        TrueQ[Together[s["TargetCoordinateExpression"] + Log[-z]] === 0],
        s["ExpansionPoint"], s["Limit"], s["TargetScale"], s["GammaPower"],
        TrueQ[s["TargetDomain"] /. z -> -1/2],
        TrueQ[(s["TargetDomain"] /. z -> 1/2) === False]}],
    {True, True, Infinity, 0, -1, -1, True, True}],

  documentationTest["docs-negative-affine-Gamma-source-reconstruction",
    Module[{x, z, s},
      s = AsymptoticInverse[Gamma[3 - 2 x], {x, -Infinity}, z, SeriesTermGoal -> 3];
      {documentationGammaEqual[s, (3 - documentationGammaApproximation[Log[z], 3])/2],
        s["ExpansionPoint"], s["SourceScale"], s["SourceOffset"],
        TrueQ[s["SourceDomain"] /. x -> 0],
        TrueQ[(s["SourceDomain"] /. x -> 1) === False]}],
    {True, -Infinity, -2, 3, True, True}],

  documentationTest["docs-LogGamma-direct-and-symbolic-affine-source-assumptions",
    Module[{x, z, a, b, direct, affine, assumptions},
      assumptions = a > 0 && Element[b, Reals];
      direct = AsymptoticInverse[LogGamma[x], {x, Infinity}, z, SeriesTermGoal -> 3];
      affine = AsymptoticInverse[LogGamma[a x + b], {x, Infinity}, z,
        SeriesTermGoal -> 3, Assumptions -> assumptions];
      {documentationGammaEqual[direct, documentationGammaApproximation[z, 3]],
        documentationGammaEqual[affine, (documentationGammaApproximation[z, 3] - b)/a],
        affine["TargetCoordinateExpression"] === z,
        TrueQ[FullSimplify[affine["SourceDomain"] /. x -> (3 - b)/a, assumptions]]}],
    {True, True, True, True}],

  documentationTest["docs-Gamma-inverse-truncate-two-refine-five-core-powers",
    Module[{x, z, s, short, long},
      s = AsymptoticInverse[Gamma[x], {x, Infinity}, z, SeriesTermGoal -> 5];
      short = SeriesTruncate[s, 2];
      long = SeriesRefine[short, 5];
      {documentationGammaEqual[short, documentationGammaApproximation[Log[z], 3]],
        short["ReturnedTermCount"], short["Cutoff"],
        documentationGammaEqual[long, documentationGammaApproximation[Log[z], 6]],
        long["ReturnedTermCount"], long["Cutoff"]}],
    {True, 3, 2, True, 6, 5}],

  documentationTest["docs-Gamma-inverse-negative-observable-and-outer-square",
    Module[{x, z, core, coefficients, a0, a1, a2, a3, negative, directSquare, s, powered,
        reciprocalExpected, squareExpected},
      core = documentationGammaCore[Log[z]];
      coefficients = documentationGammaCoefficients[1/Log[core]];
      {a0, a1, a2, a3} = Take[coefficients, 4];
      reciprocalExpected = 1/core - a0/core^2 + (a0^2 - a1)/core^3;
      squareExpected = core^2 + 2 a0 core + a0^2 + 2 a1
        + (2 a2 + 2 a0 a1)/core + (2 a3 + 2 a0 a2 + a1^2)/core^2;
      negative = AsymptoticInverse[Gamma[x], {x, Infinity}, z,
        "Power" -> -1, SeriesTermGoal -> 3];
      directSquare = AsymptoticExpansion[InverseFunction[
        x |-> ConditionalExpression[Gamma[x], x > 2]][z]^2,
        z -> Infinity, SeriesTermGoal -> 5];
      s = AsymptoticInverse[Gamma[x], {x, Infinity}, z, SeriesTermGoal -> 5];
      powered = SeriesPower[s, 2];
      {documentationGammaEqual[negative, reciprocalExpected],
        negative["RemainderPower"], negative["RemainderInverseLogPower"],
        documentationGammaEqual[directSquare, squareExpected],
        documentationGammaEqual[powered, squareExpected], powered["RemainderPower"]}],
    {True, 4, 0, True, True, 3}]
}];

documentationExpectedIDs = Cases[documentationCases,
  HoldPattern[documentationTest[id_String, _, _]] :> id, Infinity];
If[documentationExpectedIDs === {} || ! DuplicateFreeQ[documentationExpectedIDs],
  Print["Documentation checks need a nonempty selection of unique test IDs."]; Exit[1]];
{documentationSeconds, documentationReport} = AbsoluteTiming[CheckAbort[TimeConstrained[
  Replace[documentationCases, HoldComplete[cases_List] :> TestReport[cases, ProgressReporting -> False]],
  60 (Length[documentationExpectedIDs] + 1), $Aborted], $Aborted]];

documentationInfrastructureFailures = {};
documentationResults = If[Head[documentationReport] === TestReportObject &&
    AssociationQ[documentationReport["TestResults"]],
  Values[documentationReport["TestResults"]],
  AppendTo[documentationInfrastructureFailures, "MissingOrAbortedTestReport"]; {}];
If[Length[documentationResults] =!= Length[documentationExpectedIDs] ||
    Sort[#["TestID"] & /@ documentationResults] =!= Sort[documentationExpectedIDs],
  AppendTo[documentationInfrastructureFailures, "IncompleteTestSelection"]];
documentationUnchanged = documentationKernelFiles ===
    Sort[FileNames["*.wl", FileNameJoin[{documentationRoot, "src", "Kernel"}], Infinity]] &&
  AllTrue[documentationSources, FileExistsQ] &&
  documentationBefore === Check[documentationSourceHashes[], $Failed];
If[! TrueQ[documentationUnchanged], AppendTo[documentationInfrastructureFailures, "SourcesChangedDuringRun"]];
documentationSucceeded = Count[(#["Outcome"] & /@ documentationResults), "Success"];
documentationFailed = Length[documentationResults] - documentationSucceeded + Length[documentationInfrastructureFailures];

Print["Kernel: ", $Version];
Print["Documentation checks succeeded: ", documentationSucceeded,
  "   Failed: ", documentationFailed, "   Executed: ", Length[documentationResults],
  "/", Length[documentationExpectedIDs]];
If[documentationInfrastructureFailures =!= {}, Print["Validation infrastructure failures: ", documentationInfrastructureFailures]];
Do[If[result["Outcome"] =!= "Success",
  Print["FAILED ", result["TestID"], "\n   expected: ", ToString[result["ExpectedOutput"], InputForm],
    "\n   actual:   ", ToString[result["ActualOutput"], InputForm],
    "\n   messages: ", ToString[result["ActualMessages"], InputForm]]],
  {result, documentationResults}];
documentationOutput = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[! StringQ[documentationOutput] || StringLength[documentationOutput] == 0,
  documentationOutput = FileNameJoin[{documentationRoot, "validation", "documentation-current-tests.json"}]];
documentationExported = Check[Export[documentationOutput, <|"Kernel" -> $Version, "SystemID" -> $SystemID,
  "Scope" -> "Explicitly selected Wolfram documentation examples and public usage anchors only; no full package suite, Mathics acceptance, or HTML/PDF layout check.",
  "StartedAtUTC" -> DateString[documentationStarted, {"ISODate", "T", "Time", "Z"}, TimeZone -> 0],
  "Seconds" -> documentationSeconds,
  "PerCheckTimeConstraintSeconds" -> 60,
  "Suites" -> {"CheckDocumentation.wl"},
  "SelectedTestIDs" -> documentationExpectedIDs,
  "ExpectedTestCount" -> Length[documentationExpectedIDs], "ExecutedTestCount" -> Length[documentationResults],
  "PublicSymbols" -> documentationDeclaredSymbols,
  "Succeeded" -> documentationSucceeded, "Failed" -> documentationFailed,
  "InfrastructureFailures" -> documentationInfrastructureFailures,
  "SourcesUnchangedDuringRun" -> documentationUnchanged, "TestedSourceSHA256" -> documentationBefore,
  "Results" -> (Join[<|"TestID" -> #["TestID"], "Outcome" -> #["Outcome"]|>,
    If[#["Outcome"] === "Success", <||>, <|
      "ExpectedOutput" -> ToString[#["ExpectedOutput"], InputForm],
      "ActualOutput" -> ToString[#["ActualOutput"], InputForm],
      "ActualMessages" -> ToString[#["ActualMessages"], InputForm]|>]] & /@
      documentationResults)|>, "RawJSON"], $Failed];
If[! StringQ[documentationExported], Print["Documentation receipt export failed: ", documentationOutput]];
Exit[If[documentationFailed === 0 && StringQ[documentationExported], 0, 1]];
