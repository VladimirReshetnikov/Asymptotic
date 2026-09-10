(* Proposed focused regression suite. NOT run as a suite during this audit.
   Load the audited/patched package first, then use TestReport on Wolfram.
   Baseline failures of the correction tests are intentional.
   This file does not assume Mathics implements MUnit/TestReport. *)

VerificationTest[
  Block[{saved = HoldComplete[System`Element]},
    AsymptoticAnalysis`PowerLogModel[a x, {x, 0},
      Assumptions :> If[HoldComplete[System`Element] === saved,
        a == 1, a == 2]]["LeadingCoefficient"]],
  1, TestID -> "N01-bare-held-symbol-is-caller-data"]

VerificationTest[
  Block[{saved = HoldComplete[System`Element[Sin[z], Reals]]},
    AsymptoticAnalysis`PowerLogModel[a x, {x, 0},
      Assumptions :> If[HoldComplete[System`Element[Sin[z], Reals]] === saved,
        a == 1, a == 2]]["LeadingCoefficient"]],
  1, TestID -> "N01-held-membership-call-is-caller-data"]

VerificationTest[
  Module[{s, r},
    s = AsymptoticAnalysis`AsymptoticInverse[x, {x, 0}, {y, 3}, "Power" -> 2];
    r = AsymptoticAnalysis`InverseNumericalCheck[s, 2, WorkingPrecision -> 30];
    {Chop[r["LocalRoot"] - 2], Chop[r["LocalApproximation"] - 4],
      Chop[r["ReferenceObservable"] - 4]}],
  {0, 0, 0}, TestID -> "N02-power-two-values-remain-unchanged"]

VerificationTest[
  Module[{s, r},
    s = AsymptoticAnalysis`AsymptoticInverse[x, {x, 0}, {y, 4},
      "Power" -> 3, Direction -> "FromBelow"];
    r = AsymptoticAnalysis`InverseNumericalCheck[s, -2, WorkingPrecision -> 30];
    {Chop[r["LocalRoot"] - 2], Chop[r["LocalApproximation"] + 8],
      Chop[r["ReferenceObservable"] + 8], r["SourceSide"]}],
  {0, 0, 0, -1}, TestID -> "N02-left-odd-power-values-remain-unchanged"]

VerificationTest[
  Module[{s, r},
    s = AsymptoticAnalysis`AsymptoticInverse[x, {x, 0}, {y, 3}, "Power" -> 2];
    r = AsymptoticAnalysis`InverseNumericalCheck[s, 2, WorkingPrecision -> 30];
    r["LocalCoordinate"]],
  "x = SourceOffset + SourceSide u; LocalRoot is u. LocalApproximation is u for Power 1 and (SourceSide u)^Power otherwise.",
  TestID -> "N02-coordinate-description-matches-values"]
