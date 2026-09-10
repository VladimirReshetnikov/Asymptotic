(* UNEXECUTED desired helper/public contracts. Load the chosen package first.
   The official Wolfram TestReport runner can evaluate the common cases.
   The Mathics-only cases need an appropriate Mathics test harness; this file
   makes no claim that Mathics implements the complete MUnit format. *)

VerificationTest[
 AsymptoticAnalysis`Private`catch[
  AsymptoticAnalysis`Private`certIntegerPower[{-1/4, 1}, 3,
   <|"Bits" -> 48|>]],
 {-1/64, 1}, TestID -> "N01-odd-asymmetric-endpoint-range"]

VerificationTest[
 AsymptoticAnalysis`Private`catch[
  AsymptoticAnalysis`Private`certIntegerPower[{-1, 1/4}, 3,
   <|"Bits" -> 48|>]],
 {-1, 1/64}, TestID -> "N01-reflected-odd-endpoint-range"]

VerificationTest[
 AsymptoticAnalysis`Private`catch[
  AsymptoticAnalysis`Private`certIntegerPower[{-1/4, 1}, 4,
   <|"Bits" -> 48|>]],
 {0, 1}, TestID -> "N01-even-control"]

VerificationTest[
 Module[{x, y, s, c},
  s = AsymptoticAnalysis`AsymptoticInverse[(x - 1)^4/4 + x/16,
   {x, 2/3}, {y, 3}, Direction -> "FromAbove"];
  c = AsymptoticAnalysis`InverseCertificate[s, 1/16,
   "Interval" -> {3/4, 2}, "Center" -> 1, "EnclosureOrder" -> 2,
   "MaxRefinements" -> 0, "RefineExpansion" -> False];
  {c["Certified"], c["RootEnclosure"], c["DerivativeLowerBound"]}],
 {True, {1, 1}, 3/64}, TestID -> "N01-exact-center-public-certificate"]

If[StringContainsQ[$Version, "Mathics"],
 VerificationTest[
  Module[{held}, held = HoldComplete[Rule[Assumptions,
   If[Context[Unevaluated[System`Element]] === "System`", a > 0, a < 0]]];
   AsymptoticAnalysis`Private`mathicsProtectInputAssumptions[held] === held],
  True, TestID -> "N02-bare-Element-data-unchanged"]]

If[StringContainsQ[$Version, "Mathics"],
 VerificationTest[
  AsymptoticAnalysis`Private`mathicsProtectInputAssumptions[
   HoldComplete[Rule[Assumptions, System`Element[Sin[a], Reals]]]],
  HoldComplete[Rule[Assumptions, AsymptoticAnalysis`Mathics`Element[Sin[a], Reals]]],
  TestID -> "N02-membership-head-remains-protected"]]

If[StringContainsQ[$Version, "Mathics"],
 VerificationTest[
  {AsymptoticAnalysis`Private`mathicsNumericalPositiveFactorQ[Sqrt[Pi]],
   AsymptoticAnalysis`Private`mathicsNumericalPositiveFactorQ[10^-1000],
   AsymptoticAnalysis`Private`mathicsNumericalPositiveFactorQ[
    Sqrt[2] + Sqrt[3] - Sqrt[5 + 2 Sqrt[6] + 10^-30]]},
  {True, True, False}, TestID -> "N03-exact-positive-grammar"]]

VerificationTest[
 Module[{x, y, s, r},
  s = AsymptoticAnalysis`AsymptoticInverse[x, {x, 0}, {y, 4},
   Direction -> "FromBelow", "Power" -> 3];
  r = AsymptoticAnalysis`InverseNumericalCheck[s, -2, WorkingPrecision -> 50];
  {TrueQ[r["LocalRoot"] == 2], TrueQ[r["LocalApproximation"] == -8],
   StringContainsQ[r["LocalCoordinate"], "LocalRoot is always"]}],
 {True, True, True}, TestID -> "N04-signed-observable-metadata"]
