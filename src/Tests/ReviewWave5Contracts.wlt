(* Wave-5 contract repairs: zeroth powers (report 37 F02), the forwarded
   Gamma/Barnes zeroth-power cutoff (37 F03), oriented coefficient metadata
   (43 F01), model offset versus target limit (43 F02), the perturbative core
   guard (43 F03), endpoint-component branch identification (38 N1), scoped
   derivative bounds (38 N2), and truncation transport (39 N01, 42 N03). *)

VerificationTest[
 Module[{x, y, a, symbolic, positive, nonzero, remainder},
  symbolic = SeriesPower[AsymptoticExpansion[a x + x^2, {x, 0, 3}, "Backend" -> "Package", Assumptions -> Element[a, Reals]], 0];
  positive = SeriesPower[AsymptoticExpansion[a x + x^2, {x, 0, 3}, "Backend" -> "Package", Assumptions -> a > 0], 0];
  nonzero = SeriesPower[AsymptoticExpansion[a x + x^2, {x, 0, 3}, "Backend" -> "Package", Assumptions -> a != 0 && Element[a, Reals]], 0];
  remainder = SeriesPower[SeriesAdd[AsymptoticInverse[x, {x, 0}, {y, 2}, "InputRemainder" -> {3, 0}],
    SeriesMultiply[AsymptoticExpansion[y, {y, 0, 4}, "Backend" -> "Package"], -1]], 0];
  {symbolic[[1]], symbolic[[2]]["Coefficient"] === a, Normal[positive], Normal[nonzero], remainder[[1]],
   Normal[SeriesPower[AsymptoticExpansion[2 x + x^2, {x, 0, 3}, "Backend" -> "Package"], 0]]}],
 {"UnprovedNonvanishing", True, 1, 1, "IndeterminatePower", 1},
 TestID -> "zeroth-power-requires-a-provably-nonvanishing-leading-coefficient"]

VerificationTest[
 Module[{x, y, s, z},
  s = AsymptoticInverse[Gamma[x], {x, Infinity}, {y, 2}];
  z = SeriesPower[s, 0, 5];
  {s["Kind"], z["Expression"], z["Cutoff"], z["Remainder"], SeriesPower[s, 0]["Cutoff"]}],
 {"GammaInverse", 1, 5, 0, 1},
 TestID -> "gamma-inverse-zeroth-power-records-the-requested-cutoff"]

VerificationTest[
 Module[{x, y, below, above, minus, offset, even, c},
  below = AsymptoticInverse[x, {x, 0}, {y, 2}, Direction -> "FromBelow"];
  c = InverseExpansionCoefficient[below, {}];
  above = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
  minus = AsymptoticInverse[x, {x, -Infinity}, {y, 2}];
  offset = AsymptoticInverse[(x - 3) + (x - 3)^2, {x, 3}, {y, 3}];
  even = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}, Direction -> "FromBelow", "Power" -> 2];
  {Normal[below] === y, Lookup[c, {"Coefficient", "LocalCoefficient", "SourceOrientation", "ObservableCoefficient", "AdditiveOffset"}],
   c["ContributionExpression"] === y,
   InverseExpansionCoefficient[AsymptoticInverse[x + x^2, {x, 0}, {y, 4}, Direction -> "FromBelow"], {1}]["ContributionExpression"] === -y^2,
   Simplify[Total[InverseExpansionCoefficient[above, {#}]["ContributionExpression"] & /@ Range[0, 2]] - Normal[above]] === 0,
   InverseExpansionCoefficient[minus, {}]["SourceOrientation"], InverseExpansionCoefficient[minus, {}]["ContributionExpression"] === y,
   Normal[offset] === 3 + y - y^2,
   Simplify[InverseExpansionCoefficient[offset, {0}]["AdditiveOffset"] +
     Total[InverseExpansionCoefficient[offset, {#}]["ContributionExpression"] & /@ Range[0, 1]] - Normal[offset]] === 0,
   Lookup[InverseExpansionCoefficient[even, {0}], {"SourceOrientation", "ObservableCoefficient"}],
   InverseExpansionCoefficient[even, {0}]["ContributionExpression"] === y^2}],
 {True, {1, 1, -1, -1, 0}, True, True, True, -1, True, True, True, {-1, 1}, True},
 TestID -> "inverse-coefficients-carry-the-source-orientation-and-oriented-contributions"]

VerificationTest[
 Module[{x, a},
  {Lookup[PowerLogModel[1/x, {x, 0}], {"Limit", "ModelOffset", "TargetLimit"}],
   Lookup[PowerLogModel[-1/x, {x, 0}], "TargetLimit"],
   Lookup[PowerLogModel[7 + x, {x, 0}], {"Limit", "TargetLimit"}],
   Lookup[PowerLogModel[1/x + 7, {x, 0}], {"Limit", "TargetLimit"}],
   Lookup[PowerLogModel[a/x, {x, 0}, Assumptions -> a > 0], "TargetLimit"],
   Lookup[PowerLogModel[a/x, {x, 0}, Assumptions -> a != 0 && Element[a, Reals]], "TargetLimit"],
   AsymptoticInverse[1/x + 7, {x, 0}, {y, 2}]["Limit"]}],
 {{0, 0, Infinity}, -Infinity, {7, 7}, {0, Infinity}, Infinity, Missing["Unresolved", "LeadingSign"], Infinity},
 TestID -> "model-offset-and-target-limit-are-separate-fields"]

VerificationTest[
 Module[{x, y},
  {PerturbativeInverse[x + y, x^2, {x, y}, 1][[1]], PerturbativeInverse[y, x^2, {x, y}, 1] === y - y^2,
   PerturbativeInverse[x^2, {x, y}, 1] === y - y^2}],
 {"InvalidVariables", True, True},
 TestID -> "perturbative-inverse-refuses-a-core-containing-the-source-symbol"]

VerificationTest[
 Module[{x, y, cubic, check, control, nonpolynomial},
  cubic = AsymptoticInverse[x + 8 x^2 - 16 x^3, {x, 0}, {y, 2}];
  check = InverseNumericalCheck[cubic, 1/2, WorkingPrecision -> 20];
  control = InverseNumericalCheck[AsymptoticInverse[x + x^2, {x, 0}, {y, 3}], 1/10, WorkingPrecision -> 20];
  nonpolynomial = InverseNumericalCheck[AsymptoticInverse[x + Sin[x], {x, 0}, {y, 3}], 1/10, WorkingPrecision -> 20];
  {Normal[cubic] === y, TrueQ[check["LocalRoot"] == 1/4], check["EndpointComponent"] === {0, (2 + Sqrt[7])/12},
   check["BranchComponentVerified"], TrueQ[check["Error"] == 1/4],
   control["BranchComponentVerified"], control["EndpointComponent"],
   nonpolynomial["BranchComponentVerified"], nonpolynomial["EndpointComponent"]}],
 {True, True, True, True, True, True, {0, Infinity}, False, "NotPolynomial"},
 TestID -> "numerical-check-selects-the-root-on-the-endpoint-incident-component"]

VerificationTest[
 Module[{x, y, lg, g},
  lg = AsymptoticSpecialInverse["LogGamma", {x, Infinity}, {y, 2}];
  g = AsymptoticSpecialInverse["Gamma", {x, Infinity}, {y, 2}];
  {lg["TransformedDerivativeLowerBound"] === Log[x] - 1/(2 x) - 1/(12 x^2),
   lg["OriginalDerivativeLowerBound"] === Log[x] - 1/(2 x) - 1/(12 x^2),
   g["OriginalDerivativeLowerBound"] === Gamma[x] (Log[x] - 1/(2 x) - 1/(12 x^2)),
   KeyExistsQ[lg[[1]], "DerivativeLowerBoundScope"], StringContainsQ[lg["DerivativeLowerBoundScope"]["OriginalDerivativeLowerBound"], "x > 2"]}],
 {True, True, True, True, True},
 TestID -> "special-adapter-derivative-bounds-name-their-scope"]

VerificationTest[
 Module[{x, z, first, same, wider},
  z = AsymptoticExpansion[Zeta[x], x -> Infinity, SeriesTermGoal -> 4];
  first = SeriesTruncate[z, Log[3]]; same = SeriesTruncate[first, Log[3]]; wider = SeriesTruncate[first, Log[10]];
  {first["TruncationDiscardedPart"] === 3^-x + 4^-x, same["TruncationDiscardedPart"] === first["TruncationDiscardedPart"],
   wider["TruncationDiscardedPart"] === first["TruncationDiscardedPart"],
   same["AbsoluteRemainderBound"] === first["AbsoluteRemainderBound"], Normal[same] === Normal[first]}],
 {True, True, True, True, True},
 TestID -> "no-op-truncation-keeps-the-transported-discarded-part"]
