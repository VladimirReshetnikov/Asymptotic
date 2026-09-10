(* Interpreter overhead is materially higher than the compiled Wolfram
   evaluator. Give package-owned proof attempts four times their original
   wall-clock budget. The expression, fallback and proof criteria are
   unchanged; process timeouts and MaxTerms remain independent bounds.
   User calls to System`TimeConstrained are not changed. *)
Begin["AsymptoticAnalysis`Mathics`"];
ClearAll[AsymptoticAnalysis`Mathics`TimeConstrained];
SetAttributes[TimeConstrained, HoldAll];
TimeConstrained[expression_, seconds_, fallback_] :=
  System`TimeConstrained[expression, 4 seconds, fallback];
TimeConstrained[expression_, seconds_] :=
  System`TimeConstrained[expression, 4 seconds];
End[];
