(* W3-08: inverse coefficient capability is distinct from a series result.
   Ordinary expectations follow the inverse of x+x^2 and its square. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
 Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
 Module[{x, s}, s = AsymptoticExpansion[1 + x, {x, 0, 2}, "Backend" -> "Package"];
  MatchQ[Check[InverseExpansionCoefficient[s, {0}], "UnexpectedMessage"],
   Failure["UnsupportedCoefficientModel", _Association]]],
 True, TestID -> "review-coefficient-forward-result-refuses-without-messages"]

VerificationTest[
 Module[{x, s}, s = AsymptoticExpansion[x, {x, 0, 2}, "Backend" -> "Package"];
  MatchQ[Check[InverseExpansionCoefficient[SeriesMultiply[s, s], {0}], "UnexpectedMessage"],
   Failure["UnsupportedCoefficientModel", _Association]]],
 True, TestID -> "review-coefficient-derived-result-refuses-without-messages"]

VerificationTest[
 Module[{x, y, s}, s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 3}];
  MatchQ[Check[InverseExpansionCoefficient[s, {1}], "UnexpectedMessage"],
   Failure["UnsupportedCoefficientModel", _Association]]],
 True, TestID -> "review-coefficient-exact-core-result-needs-its-own-coefficients"]

VerificationTest[
 Module[{x, y, s}, s = AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 3}];
  MatchQ[Check[InverseExpansionCoefficient[s, {1}], "UnexpectedMessage"],
   Failure["UnsupportedCoefficientModel", _Association]]],
 True, TestID -> "review-coefficient-fourier-result-needs-fourier-coefficient-query"]

VerificationTest[
 Module[{x, s}, s = AsymptoticExpansion[Sin[x], {x, 0, 3}, "Backend" -> "Series"];
  MatchQ[Check[InverseExpansionCoefficient[s, {1}], "UnexpectedMessage"],
   Failure["NativeSeriesContract", _Association]]],
 True, TestID -> "review-coefficient-native-result-keeps-native-contract-refusal"]

VerificationTest[
 MatchQ[InverseExpansionCoefficient[GeneralizedSeries[<|"Scale" -> "Logarithmic"|>], {1}],
   Failure["Unsupported", _Association]],
 True, TestID -> "review-coefficient-logarithmic-refusal-precedes-ordinary-model-access"]

VerificationTest[
 Module[{x, y, s, c}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
  c = InverseExpansionCoefficient[s, {2}];
  {c["Weight"], c["Exponent"], c["Coefficient"], c["UniformizerExponent"]}],
 {2, 3, 2, 3}, TestID -> "review-coefficient-ordinary-inverse-preserves-catalan-contribution"]

VerificationTest[
 Module[{x, y, s, c}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}, "Power" -> 2];
  c = InverseExpansionCoefficient[s, {1}];
  {c["Exponent"], c["Coefficient"], c["UniformizerExponent"]}],
 {3, -2, 3}, TestID -> "review-coefficient-stored-observable-power-is-preserved"]

VerificationTest[
 Module[{x, y, s, c}, s = AsymptoticInverse[x + 1/x, {x, Infinity}, {y, 4}];
  c = InverseExpansionCoefficient[s, {1}];
  {s["Model"]["LeadingPower"], c["Weight"], c["Exponent"], c["Coefficient"]}],
 {-1, 2, -1, -1}, TestID -> "review-coefficient-infinity-retains-negative-leading-power"]

VerificationTest[
 Module[{x, model, index = {}, c}, model = PowerLogModel[x, {x, 0}];
  c = InverseExpansionCoefficient[model, index];
  {c["Weight"], c["Exponent"], c["Coefficient"], {index, 2, 0}}],
 {0, 1, 1, {{}, 2, 0}}, TestID -> "review-coefficient-zero-dimensional-model-and-input-remain-valid"]

VerificationTest[
 Module[{x, model}, model = PowerLogModel[x + x^2, {x, 0}];
  And @@ (MatchQ[InverseExpansionCoefficient[model, #], Failure["InvalidMultiIndex", _Association]] & /@
    {{}, {0, 0}, {-1}, {1/2}})],
 True, TestID -> "review-coefficient-existing-index-validation-remains-after-model-admission"]

VerificationTest[
 MatchQ[Check[InverseExpansionCoefficient[<||>, {}], "UnexpectedMessage"],
   Failure["UnsupportedCoefficientModel", _Association]],
 True, TestID -> "review-coefficient-empty-model-is-not-an-index-error"]

VerificationTest[
 Module[{x, model, changed}, model = PowerLogModel[x + x^2, {x, 0}];
  changed = {KeyDrop[model, "Polynomials"], Join[model, <|"Polynomials" -> {}|>],
    Join[model, <|"Gaps" -> Missing["Absent"]|>], Join[model, <|"LogVariable" -> 7|>]};
  And @@ (MatchQ[Check[InverseExpansionCoefficient[#, {1}], "UnexpectedMessage"],
      Failure["UnsupportedCoefficientModel", _Association]] & /@ changed)],
 True, TestID -> "review-coefficient-incomplete-and-incompatible-model-shapes-refuse"]

VerificationTest[
 Module[{x, y, s}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
  And @@ (MatchQ[Check[InverseExpansionCoefficient[GeneralizedSeries[KeyDrop[s[[1]], #]], {1}],
       "UnexpectedMessage"], Failure["UnsupportedCoefficientModel", _Association]] & /@
    {"Power", "ExpansionPoint"})],
 True, TestID -> "review-coefficient-object-coordinate-fields-checked-before-indexing"]

VerificationTest[
 Module[{x, a, model, c}, model = Assuming[Element[a, Reals], PowerLogModel[x + Abs[a] x^2, {x, 0}]];
  c = Assuming[a > 0, InverseExpansionCoefficient[model, {1}]];
  {c["Assumptions"] === Element[a, Reals], c["Coefficient"] /. a -> -2}],
 {True, -2}, TestID -> "review-coefficient-model-retains-stored-assumptions"]

VerificationTest[
 Module[{x, y, alpha, s, c}, s = AsymptoticInverse[x + x^alpha, {x, 0}, {y, 3},
    "Truncation" -> "Depth", Assumptions -> alpha > 1];
  c = InverseExpansionCoefficient[s, {1}];
  {Simplify[c["Weight"] - (alpha - 1), alpha > 1], c["Coefficient"], Simplify[c["Exponent"] - alpha, alpha > 1]}],
 {0, -1, 0}, TestID -> "review-coefficient-symbolic-depth-model-remains-admitted"]
