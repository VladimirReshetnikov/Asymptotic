(* Native formal results retain their own contracts. These public cases must
   not import Normal[native] as an exact real analytic jet or composite bound.
   VerificationTest also rejects unexpected messages from missing metadata. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

nativeContractFailureQ[result_] := MatchQ[result, Failure["NativeSeriesContract", _Association]];

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
  {s["Kind"], s["Scale"], s["Remainder"], s["Exact"],
    s["NativeResult"] === Series[Exp[I x], {x, 0, 3}],
    Normal[s] === 1 + I x - x^2/2 - I x^3/6}],
  {"Native", "Native", Missing["NativeContract"], Missing["NotEstablished"], True, True},
  TestID -> "native-contract-complex-output-keeps-formal-order-without-analytic-exactness"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
  {SeriesNormalize[s] === s, SeriesNormalize[{s, {s}}] === {s, {s}},
    SeriesDifferentiate[s, 0] === s}],
  {True, True, True},
  TestID -> "native-contract-identity-normalization-and-zero-derivative-preserve-the-object"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[1 + x, {x, 0, 3}, "Backend" -> "Series"];
  {Normal[s] === 1 + x, s["Exact"] === Missing["NotEstablished"],
    nativeContractFailureQ[SeriesTruncate[s, 1]],
    nativeContractFailureQ[SeriesRefine[s, 5]]}],
  {True, True, True, True},
  TestID -> "native-contract-finite-native-output-does-not-infer-an-analytic-contract"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"];
  nativeContractFailureQ /@ {
    SeriesNormalize[s, "Cutoff" -> 1], SeriesNormalize[s, "Cutoff" -> 8],
    SeriesNormalize[{s}, "Cutoff" -> 2], SeriesDifferentiate[s, 0, "Cutoff" -> 2]}],
  {True, True, True, True},
  TestID -> "native-contract-explicit-normalization-cutoffs-require-analytic-precision"]

VerificationTest[Module[{x, native, analytic},
  native = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"];
  analytic = AsymptoticExpansion[Sin[x], {x, 0, 3}];
  nativeContractFailureQ /@ {native + analytic, analytic + native,
    native analytic, analytic native}],
  {True, True, True, True},
  TestID -> "native-contract-automatic-mixed-arithmetic-refuses-both-operand-orders"]

VerificationTest[Module[{x, native, analytic},
  native = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"];
  analytic = AsymptoticExpansion[Sin[x], {x, 0, 3}];
  nativeContractFailureQ /@ {SeriesAdd[native, analytic], SeriesAdd[analytic, native],
    SeriesMultiply[native, analytic], SeriesMultiply[analytic, native]}],
  {True, True, True, True},
  TestID -> "native-contract-explicit-mixed-arithmetic-refuses-both-operand-orders"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
  nativeContractFailureQ /@ {s + 1, 2 s, s^2, 1/s, Log[s], Exp[s], Sin[s]}],
  {True, True, True, True, True, True, True},
  TestID -> "native-contract-automatic-scalar-and-unary-operations-do-not-strip-the-native-tail"]

VerificationTest[Module[{x, s, z},
  s = AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
  nativeContractFailureQ /@ {SeriesAdd[s, 1], SeriesMultiply[s, 2],
    SeriesPower[s, 2], SeriesLog[s], SeriesExp[s], SeriesObservable[s, Sin[z], z]}],
  {True, True, True, True, True, True},
  TestID -> "native-contract-explicit-scalar-and-observable-operations-require-an-analytic-contract"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"];
  nativeContractFailureQ /@ {SeriesDifferentiate[s],
    SeriesDifferentiate[s, 1, "RemainderDerivativeOrder" -> Infinity],
    SeriesTruncate[s, 2], SeriesRefine[s, 5]}],
  {True, True, True, True},
  TestID -> "native-contract-calculus-and-refinement-do-not-upgrade-native-order-evidence"]

VerificationTest[Module[{x, native, analytic},
  native = AsymptoticExpansion[Sin[x], {x, 0, 3}, "Backend" -> "Series"];
  analytic = AsymptoticExpansion[Sin[x], {x, 0, 3}];
  nativeContractFailureQ /@ {SeriesCompose[native, analytic],
    SeriesCompose[analytic, native], SeriesCompose[native, native]}],
  {True, True, True},
  TestID -> "native-contract-composition-rejects-a-native-operand-on-either-side"]

VerificationTest[Module[{x, native, composite},
  native = AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
  composite = GeneralizedSeries[<|"Kind" -> "Derived", "Scale" -> "Composite",
    "Expression" -> 1 + x, "Remainder" -> PowerLogRemainder[x, 2, 0],
    "Variable" -> x, "Assumptions" -> True, "TargetDomain" -> x > 0,
    "SeriesApproach" -> <|"Variable" -> x, "Point" -> 0, "Direction" -> "FromAbove"|>|>];
  nativeContractFailureQ /@ {SeriesAdd[native, composite], SeriesAdd[composite, native],
    SeriesMultiply[native, composite], SeriesMultiply[composite, native]}],
  {True, True, True, True},
  TestID -> "native-contract-composite-dispatch-cannot-reinterpret-a-native-remainder"]

VerificationTest[Module[{x, y, native, flat},
  native = AsymptoticExpansion[Exp[y], {y, 0, 3}, "Backend" -> "Series"];
  flat = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 1}];
  nativeContractFailureQ /@ {SeriesAdd[native, flat], SeriesAdd[flat, native],
    SeriesMultiply[native, flat], SeriesMultiply[flat, native]}],
  {True, True, True, True},
  TestID -> "native-contract-flat-dispatch-cannot-import-native-finite-parts"]

VerificationTest[Module[{x, s, certificate, numerical},
  s = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"];
  certificate = InverseCertificate[s, 1/2, "Interval" -> {0, 1}];
  numerical = InverseNumericalCheck[s, 1/2];
  {MatchQ[certificate, Failure["Unsupported", _Association]],
    Lookup[certificate[[2]], "Certified", Missing["NoClaim"]],
    MatchQ[numerical, Failure["Unsupported", _Association]]}],
  {True, False, True},
  TestID -> "native-contract-certificate-and-inverse-numerical-check-refuse-native-forward-results"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
  nativeContractFailureQ /@ {SeriesNormalize[s - s], SeriesNormalize[s/s],
    SeriesNormalize[0 s], SeriesNormalize[s^0]}],
  {True, True, True, True},
  TestID -> "native-contract-held-normalization-checks-operations-before-algebraic-cancellation"]

VerificationTest[Module[{x, s, sum, truncated},
  s = AsymptoticExpansion[Exp[x], {x, 0, 3}];
  sum = SeriesAdd[s, 1]; truncated = SeriesTruncate[s, 2];
  {Normal[sum] === 2 + x + x^2/2, sum["Remainder"] === PowerLogRemainder[x, 3, 0],
    Normal[truncated] === 1 + x, truncated["Remainder"] === PowerLogRemainder[x, 2, 0],
    SeriesNormalize[s] === s}],
  {True, True, True, True, True},
  TestID -> "native-contract-guards-preserve-ordinary-analytic-arithmetic-and-truncation"]
