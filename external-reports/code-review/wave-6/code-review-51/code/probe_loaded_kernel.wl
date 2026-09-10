(* Kernel-neutral observation expressions, not an aggregate test runner.
   In a FRESH Wolfram or Mathics session first load a known local standalone:
     Get["/path/to/Asymptotic/AsymptoticAnalysis.wl"]
   Then Get this file. It changes only review-prefixed/global probe symbols.
   No candidate is installed; no file is written; results are not certificates.
   Not executed as a complete script during this audit. *)
ClearAll[reviewSaved, reviewModel1, reviewModel2, reviewSquare, reviewCube];
reviewSaved = HoldComplete[System`Element];
reviewModel1 = AsymptoticAnalysis`PowerLogModel[a x, {x, 0},
  Assumptions :> If[HoldComplete[System`Element] === reviewSaved, a == 1, a == 2]];
reviewSaved = HoldComplete[System`Element[Sin[z], Reals]];
reviewModel2 = AsymptoticAnalysis`PowerLogModel[a x, {x, 0},
  Assumptions :> If[HoldComplete[System`Element[Sin[z], Reals]] === reviewSaved,
    a == 1, a == 2]];
reviewSquare = AsymptoticAnalysis`InverseNumericalCheck[
  AsymptoticAnalysis`AsymptoticInverse[x, {x, 0}, {y, 3}, "Power" -> 2],
  2, WorkingPrecision -> 30];
reviewCube = AsymptoticAnalysis`InverseNumericalCheck[
  AsymptoticAnalysis`AsymptoticInverse[x, {x, 0}, {y, 4},
    "Power" -> 3, Direction -> "FromBelow"], -2, WorkingPrecision -> 30];
Print[InputForm[<|"Kernel" -> $Version,
  "BareHeldDataModel" -> reviewModel1,
  "NestedHeldCallModel" -> reviewModel2,
  "SquareEvidence" -> reviewSquare, "LeftCubeEvidence" -> reviewCube|>]];
