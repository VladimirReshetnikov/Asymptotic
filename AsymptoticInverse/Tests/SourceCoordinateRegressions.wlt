If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Log[x], {x, 0}, {y, 3}];
  {Normal[s], s["Remainder"], s["CoordinateKind"]} /. y -> \[FormalY]],
  {Exp[\[FormalY]], 0, "SourceExp"}, TestID -> "source-logarithm-at-zero-exact"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Log[x], {x, Infinity}, {y, 3}];
  {Normal[s], s["Remainder"]} /. y -> \[FormalY]],
  {Exp[\[FormalY]], 0}, TestID -> "source-logarithm-at-infinity-exact"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Log[-x], {x, -Infinity}, {y, 3}];
  {Normal[s], s["Remainder"]} /. y -> \[FormalY]],
  {-Exp[\[FormalY]], 0}, TestID -> "source-logarithm-at-negative-infinity"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[1 + 2 Log[3 - x], {x, 3}, {y, 3}, Direction -> "FromBelow"];
  TrueQ[FullSimplify[Normal[s] == 3 - Exp[(y - 1)/2], y < 1]] && s["Remainder"] === 0],
  True, TestID -> "source-affine-logarithm-shifted-left-branch"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Sqrt[-Log[x]], {x, 0}, {y, 3}];
  {Normal[s], s["Remainder"]} /. y -> \[FormalY]],
  {Exp[-\[FormalY]^2], 0}, TestID -> "source-fractional-logarithm-power"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Log[x]^2 + Log[x], {x, 0}, {y, 1}];
  {TrueQ[FullSimplify[Normal[s] == Exp[-Sqrt[y] - 1/2] (1 - 1/(8 Sqrt[y])), y > 0]], s["RemainderPower"]}],
  {True, 1}, TestID -> "source-polynomial-logarithm-exponential-error-transport"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Exp[-x] + Exp[-2 x], {x, Infinity}, {y, 4}];
  Expand[Normal[s]] /. y -> \[FormalY]],
  \[FormalY] - 3 \[FormalY]^2/2 + 10 \[FormalY]^3/3 - Log[\[FormalY]], TestID -> "source-two-decaying-exponentials"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Exp[x] + Exp[-x], {x, Infinity}, {y, 3}];
  TrueQ[FullSimplify[Normal[s] == Log[y] - 1/y^2, y > 2]]],
  True, TestID -> "source-growing-and-decaying-exponentials"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Exp[x/2] + Exp[-x/2], {x, Infinity}, {y, 3}];
  TrueQ[FullSimplify[Normal[s] == 2 Log[y] - 2/y^2, y > 2]]],
  True, TestID -> "source-nonunit-exponential-rate"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Exp[x] + Exp[-x], {x, -Infinity}, {y, 3}];
  TrueQ[FullSimplify[Normal[s] == -Log[y] + 1/y^2, y > 2]]],
  True, TestID -> "source-exponential-sum-negative-source-infinity"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Exp[-x] + Exp[-2 x], {x, Infinity}, {y, 3}, "Power" -> 2];
  TrueQ[FullSimplify[Normal[s] == Log[y]^2 - 2 y Log[y] + y^2 (1 + 3 Log[y]), 0 < y < 1]]],
  True, TestID -> "source-logarithmic-reconstruction-square-observable"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Exp[-x] + Exp[-2 x], {x, Infinity}, {y, 2}, "Power" -> 1/2];
  TrueQ[FullSimplify[Normal[s]^2 == -Log[y] + y, 0 < y < 1]] && s["RemainderPower"] === 2],
  True, TestID -> "source-logarithmic-reconstruction-fractional-observable-carrier"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Log[x]^2 + Log[x], {x, 0}, y, SeriesTermGoal -> 3];
  {s["ReturnedTermCount"], s["Blocks"][[All, 1]]}],
  {3, {0, 1/2, 1}}, TestID -> "source-term-goal-counts-reconstructed-unit"]

VerificationTest[Module[{x, y, s}, s = SeriesRefine[AsymptoticInverse[Exp[-x] + Exp[-2 x], {x, Infinity}, {y, 2}], 4];
  {s["Kind"], s["CoordinateKind"], Expand[Normal[s]]} /. y -> \[FormalY]],
  {"Inverse", "SourceLog", \[FormalY] - 3 \[FormalY]^2/2 + 10 \[FormalY]^3/3 - Log[\[FormalY]]},
  TestID -> "source-refinement-replays-chart-and-reconstruction"]

VerificationTest[Module[{x, y}, FailureQ[AsymptoticInverse[Log[x], {x, 0}, {y, 3}, "InputRemainder" -> {2, 0}]]],
  True, TestID -> "source-rejects-untransported-input-remainder"]

VerificationTest[Module[{x, y}, FailureQ[AsymptoticInverse[Log[-x], {x, -Infinity}, {y, 3}, "Power" -> 1/2]]],
  True, TestID -> "source-rejects-nonreal-observable-on-negative-branch"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Log[-Log[x]], {x, 0}, {y, 3}];
  {Normal[s], s["Remainder"]} /. y -> \[FormalY]],
  {Exp[-Exp[\[FormalY]]], 0}, TestID -> "source-repeated-exact-logarithmic-charts"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Log[x], {x, 0}, {y, 3}, "Power" -> -2];
  {Normal[s], s["Remainder"]} /. y -> \[FormalY]],
  {Exp[-2 \[FormalY]], 0}, TestID -> "source-reciprocal-power-of-exponential-reconstruction"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Log[x]^2 + Log[x], {x, 0}, {y, 2}];
  InverseResidual[s]["ZeroBelowCutoff"]],
  True, TestID -> "source-exponential-reconstruction-formal-residual"]

VerificationTest[Module[{x, y, s}, s = AsymptoticInverse[Exp[-x] + Exp[-2 x], {x, Infinity}, {y, 4}];
  InverseResidual[s]["ZeroBelowCutoff"]],
  True, TestID -> "source-logarithmic-reconstruction-formal-residual"]

VerificationTest[Module[{x, y, s, shorter, changed, result},
  s = AsymptoticInverse[Exp[-x] + Exp[-2 x], {x, Infinity}, {y, 4}];
  shorter = SeriesTruncate[s["ReconstructedSeries"], 1];
  changed = PowerLogSeries[Join[s[[1]], <|"Expression" -> Normal[shorter], "Blocks" -> shorter["Blocks"],
    "SeriesRepresentation" -> shorter["SeriesRepresentation"], "ReconstructedSeries" -> shorter|>]];
  result = InverseResidual[changed, 3]; {result["ZeroBelowCutoff"], TrueQ[Simplify[result["NormalizedResidual"] == y, y > 0]]}],
  {False, True}, TestID -> "source-residual-composes-returned-reconstruction"]

VerificationTest[Module[{x, y, check}, check = InverseNumericalCheck[
    AsymptoticInverse[Exp[-x] + Exp[-2 x], {x, Infinity}, {y, 4}], 1/1000];
  TrueQ[check["Error"] > 0 && check["Ratio"] < 20 && check["ReferenceRoot"] > 0]],
  True, TestID -> "source-numerical-comparison-in-decaying-exponential-chart"]

VerificationTest[Module[{x, y, check}, check = InverseNumericalCheck[
    AsymptoticInverse[Log[x]^2 + Log[x], {x, 0}, {y, 2}], 100];
  TrueQ[check["Error"] > 0 && check["Ratio"] < 100 && 0 < check["ReferenceRoot"] < 1]],
  True, TestID -> "source-numerical-comparison-after-exponential-reconstruction"]

VerificationTest[Module[{x, y, check}, check = InverseNumericalCheck[
    AsymptoticInverse[Exp[-x] + Exp[-2 x], {x, Infinity}, {y, 2}, "Power" -> 1/2], 1/1000];
  TrueQ[check["Error"] > 0 && check["Ratio"] < 10]],
  True, TestID -> "source-numerical-fractional-observable-comparison"]

VerificationTest[Module[{x, y, check}, check = InverseNumericalCheck[
    AsymptoticInverse[Exp[x] + Exp[-x], {x, -Infinity}, {y, 3}], 100];
  TrueQ[check["ReferenceRoot"] < 0 && check["Ratio"] < 10]],
  True, TestID -> "source-numerical-negative-infinity-branch"]

VerificationTest[Module[{x, y}, FailureQ[InverseNumericalCheck[
    AsymptoticInverse[Exp[-x] + Exp[-2 x], {x, Infinity}, {y, 3}], -1/1000]]],
  True, TestID -> "source-numerical-rejects-wrong-target-side"]
