(* Direct finite-phase oracles keep the residual checks independent of the
   inverse constructors and their coefficient recurrences. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

inverseCheckFixture[family_, rows_, q_, x_, y_, scale_: 1, shift_: Automatic] := Module[
  {offset = If[family === "Gamma", 0, 1], sourceOffset, log, substitutions},
  sourceOffset = If[shift === Automatic, offset, shift];
  log = Log[y] - offset; substitutions = {q -> 1/log};
  <|"Power" -> 1, "Terms" -> rows, "RemainderPower" -> 3, "CoefficientVariable" -> q,
    "Assumptions" -> True, "SourceScale" -> scale, "SourceOffset" -> sourceOffset,
    "CoreInverse" -> y, "CoreLogExpression" -> log, "CoefficientSubstitution" -> substitutions,
    "Variables" -> {x, y},
    "Expression" -> Total[(y^(-#[[1]]) (#[[2]] /. substitutions)) & /@ rows],
    "ExactTransformedFunction" -> If[family === "Gamma",
      LogGamma[scale x + sourceOffset], LogBarnesG[scale x + sourceOffset]],
    "TargetCoordinateExpression" -> If[family === "Gamma", y (Log[y] - 1), y^2 (Log[y] - 3/2)/2]|>];

inverseCheckEvaluate[family_, a_, h_: Automatic, limit_: 20000] :=
  AsymptoticAnalysis`Private`catch[If[family === "Gamma",
    AsymptoticAnalysis`Private`gammaInverseResidual[a, h, limit],
    AsymptoticAnalysis`Private`barnesInverseResidual[a, h, limit]]];

VerificationTest[Module[{x, y, q, result, expected},
  result = inverseCheckEvaluate["Gamma", inverseCheckFixture["Gamma", {{-1, 1}}, q, x, y], 3];
  expected = {{1, (q Log[2 Pi] - 1)/2}, {2, q/12}};
  {TrueQ[FullSimplify[result["ResidualBlocks"] == expected]], result["ForwardModelTerms"],
   result["ModelRemainderPower"], result["ModelRemainderScaleExpression"] === 1/(y^4 Log[y]),
   result["ZeroBelowCutoff"], result["ExactModel"]}],
  {True, 1, 4, True, False, False},
  TestID -> "inverse-check-refactoring-Gamma-core-has-independent-Stirling-residual"]

VerificationTest[Module[{x, y, q, result, expected},
  result = inverseCheckEvaluate["Barnes", inverseCheckFixture["Barnes", {{-1, 1}}, q, x, y], 5];
  expected = {{1, q Log[2 Pi]/2}, {2, -1/12 - q Log[Glaisher]}, {4, -q/240}};
  {TrueQ[FullSimplify[result["ResidualBlocks"] == expected]], result["ForwardModelTerms"],
   result["ModelRemainderPower"], result["ModelRemainderScaleExpression"] === 1/(y^6 (Log[y] - 1)),
   result["ZeroBelowCutoff"], result["ExactModel"]}],
  {True, 1, 6, True, False, False},
  TestID -> "inverse-check-refactoring-Barnes-core-has-independent-Bernoulli-residual"]

VerificationTest[Module[{x, y, q},
  Table[With[{a = inverseCheckFixture[family, {{-1, 1}}, q, x, y]},
    {First /@ inverseCheckEvaluate[family, a, 2]["ResidualBlocks"],
     First /@ inverseCheckEvaluate[family, a, 5/2]["ResidualBlocks"],
     inverseCheckEvaluate[family, a, 5/2]["Cutoff"]}], {family, {"Gamma", "Barnes"}}]],
  {{{1}, {1, 2}, 5/2}, {{1}, {1, 2}, 5/2}},
  TestID -> "inverse-check-refactoring-integer-and-fractional-cutoffs-are-exclusive"]

VerificationTest[Module[{x, y, q, result, a},
  Table[
    a = inverseCheckFixture[family, {{-1, 1}, {0, If[family === "Gamma", 1/2, 0] - q Log[2 Pi]/2}}, q, x, y];
    a = Join[a, <|"RemainderPower" -> 1|>]; result = inverseCheckEvaluate[family, a];
    {result["ZeroBelowCutoff"], result["ResidualBlocks"], result["Residual"], result["Cutoff"],
     result["ExactModel"], result["ExactEquationResidualExpression"] =!= 0,
     result["ForwardRemainderContract"]["ConvergentForwardSeries"]},
    {family, {"Gamma", "Barnes"}}]],
  {{True, {}, 0, 2, False, True, False}, {True, {}, 0, 2, False, True, False}},
  TestID -> "inverse-check-refactoring-zero-finite-residual-retains-exact-equation-and-tail-caveats"]

VerificationTest[Module[{x, y, q, delta, a, result},
  Table[
    a = inverseCheckFixture[family, {{-1, 1},
      {0, If[family === "Gamma", 1/2, 0] - q Log[2 Pi]/2 + delta}}, q, x, y];
    result = inverseCheckEvaluate[family, a, 2];
    {result["ResidualBlocks"] === {{1, delta}}, result["Residual"] === delta/y},
    {family, {"Gamma", "Barnes"}}]],
  {{True, True}, {True, True}},
  TestID -> "inverse-check-refactoring-perturbed-source-coefficient-is-detected-in-both-normalizations"]

VerificationTest[Module[{x, y, q, shifted, bare, offset},
  Table[
    offset = If[family === "Gamma", 0, 1];
    shifted = inverseCheckEvaluate[family,
      inverseCheckFixture[family, {{-1, 1/2}, {0, (offset - 3)/2}}, q, x, y, 2, 3], 3];
    bare = inverseCheckEvaluate[family, inverseCheckFixture[family, {{-1, 1}}, q, x, y], 3];
    shifted["ResidualBlocks"] === bare["ResidualBlocks"], {family, {"Gamma", "Barnes"}}]],
  {True, True},
  TestID -> "inverse-check-refactoring-affine-source-normalization-retains-family-argument-offset"]

VerificationTest[Module[{x, y, q, a},
  Table[
    a = inverseCheckFixture[family, {{-1, 1}}, q, x, y];
    {MatchQ[inverseCheckEvaluate[family, Join[a, <|"Power" -> 2|>], 0, 0], Failure["UnsupportedObservable", _]],
     MatchQ[inverseCheckEvaluate[family, a, 0, 0], Failure["InvalidOption", _]],
     MatchQ[inverseCheckEvaluate[family, a, 0], Failure["InvalidCutoff", _]],
     MatchQ[inverseCheckEvaluate[family, a, 5, 2], Failure["ResourceLimit", _]]},
    {family, {"Gamma", "Barnes"}}]],
  {{True, True, True, True}, {True, True, True, True}},
  TestID -> "inverse-check-refactoring-observable-option-cutoff-and-resource-validation-order"]

VerificationTest[Module[{x, y, q, a},
  Table[
    a = inverseCheckFixture[family, {{-1, 1}}, q, x, y];
    {MatchQ[inverseCheckEvaluate[family, Join[a, <|"Terms" -> {{-1, 1}, {1/2, q}}|>], 2],
       Failure["UnsupportedResidualScale", _]],
     MatchQ[inverseCheckEvaluate[family, Join[a, <|"Terms" -> {{-2, 1}}|>], 2],
       Failure["UnsupportedResidualScale", _]],
     MatchQ[inverseCheckEvaluate[family, Join[a, <|"Terms" -> {}|>], 2],
       Failure[tag_, _] /; tag === "Invalid" <> family <> "InverseNormalization"]},
    {family, {"Gamma", "Barnes"}}]],
  {{True, True, True}, {True, True, True}},
  TestID -> "inverse-check-refactoring-malformed-scale-and-empty-source-are-rejected"]

VerificationTest[Module[{x, y, q, a, result, expected},
  Table[
    a = inverseCheckFixture[family, {{-1, 1}}, q, x, y];
    result = inverseCheckEvaluate[family, a, 1];
    expected = ((a["ExactTransformedFunction"] /. x -> a["Expression"]) - a["TargetCoordinateExpression"])/
      If[family === "Gamma", y Log[y], y^2 (Log[y] - 1)];
    {result["ExactEquationResidualExpression"] === expected,
     result["CoefficientSubstitution"] === a["CoefficientSubstitution"],
     result["ForwardRemainderContract"]["Type"] === If[family === "Gamma",
       "StirlingPoincareAtFixedOrder", "BarnesPoincareAtFixedOrder"]},
    {family, {"Gamma", "Barnes"}}]],
  {{True, True, True}, {True, True, True}},
  TestID -> "inverse-check-refactoring-report-keeps-distinct-log-normalizers-and-contracts"]
