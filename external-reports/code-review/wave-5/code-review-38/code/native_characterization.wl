(* UNEXECUTED during this review. Load the pinned package in a fresh kernel
   BEFORE Get of this file. Optionally set $AuditOutputFile to a writable
   .json filename. This records observations, not desired-contract passes.
   None of the independent Python tests invokes this program. *)
Module[{observe, source, cubic, quartic, one, half, negative, guarded, records},
  SetAttributes[observe, HoldRest];
  observe[id_, expr_] := Module[{value = TimeConstrained[expr, 120, $Aborted]},
    <|"ID" -> id, "ResultInputForm" -> ToString[value, InputForm]|>];
  source = "8e859961d7d37f008b826f3a8cad406460271614";
  cubic = AsymptoticAnalysis`AsymptoticInverse[
    x + 8 x^2 - 16 x^3, {x, 0}, {y, 2}];
  quartic = AsymptoticAnalysis`AsymptoticInverse[
    384 x^4 - 304 x^3 + 56 x^2 + x, {x, 0}, {y, 2}];
  half = AsymptoticAnalysis`AsymptoticSpecialInverse[
    "LogGamma", {x, Infinity}, {y, 1}, "TargetScale" -> 1/2];
  one = AsymptoticAnalysis`AsymptoticSpecialInverse[
    "LogGamma", {x, Infinity}, {y, 1}, "TargetScale" -> 1];
  negative = AsymptoticAnalysis`AsymptoticSpecialInverse[
    "LogGamma", {x, Infinity}, {y, 1}, "TargetScale" -> -1];
  guarded = AsymptoticAnalysis`AsymptoticInverse[
    ConditionalExpression[x + 8 x^2 - 16 x^3, 0 < x < 1/3],
    {x, 0}, {y, 2}];
  records = {
    observe["cubic-expression", Normal[cubic]],
    observe["cubic-reference", AsymptoticAnalysis`InverseNumericalCheck[
      cubic, 1/2, WorkingPrecision -> 50]],
    observe["quartic-expression", Normal[quartic]],
    observe["quartic-reference", AsymptoticAnalysis`InverseNumericalCheck[
      quartic, 1/2, WorkingPrecision -> 50]],
    observe["narrowed-source-control", AsymptoticAnalysis`InverseNumericalCheck[
      guarded, 1/2, WorkingPrecision -> 50]],
    observe["unit-scale-derivative", {one["Function"], one["OriginalDerivativeLowerBound"]}],
    observe["half-scale-derivative", {half["Function"], half["OriginalDerivativeLowerBound"],
      FullSimplify[(D[half["Function"], x] - half["OriginalDerivativeLowerBound"]) /. x -> 3]}],
    observe["negative-scale-derivative", {negative["Function"], negative["OriginalDerivativeLowerBound"]}]
  };
  records = <|"Runtime" -> $Version, "ExpectedSourceRevision" -> source,
    "SourceRevisionVerifiedByThisProgram" -> False,
    "Scope" -> "Observed values only. Confirm the loaded source revision independently.",
    "Cases" -> records|>;
  If[ValueQ[$AuditOutputFile] && StringQ[$AuditOutputFile],
    Export[$AuditOutputFile, records, "RawJSON"], Print[InputForm[records]]];
  records
]
