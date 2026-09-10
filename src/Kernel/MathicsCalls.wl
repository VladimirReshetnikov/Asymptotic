(* Mathics 10 implements Extract[expr,position] but not the wrapper form.
   The package needs Extract[...,HoldComplete] to inspect named Function
   parameters without evaluating their ownvalues. Keep every selected part
   held throughout the traversal; never substitute into a Function body. *)

Begin["AsymptoticAnalysis`Mathics`"];
ClearAll[AsymptoticAnalysis`Mathics`Extract,
  AsymptoticAnalysis`Mathics`mathicsExtractHeld,
  AsymptoticAnalysis`Mathics`mathicsHeldPart,
  AsymptoticAnalysis`Mathics`mathicsExtractWrapped];
SetAttributes[Extract, HoldAll];

mathicsHeldPart[HoldComplete[head_[arguments___]], 0] := HoldComplete[head];
mathicsHeldPart[HoldComplete[head_[arguments___]], index_Integer] :=
  With[{parts = Cases[HoldComplete[arguments], item_ :> HoldComplete[item], {1}]},
    If[index =!= 0 && -Length[parts] <= index <= Length[parts],
      Part[parts, index], $Failed]];
mathicsHeldPart[_, _Integer] := $Failed;

mathicsExtractHeld[expression_, position_List] :=
  Fold[mathicsHeldPart, With[{value = expression}, HoldComplete[value]], position];
mathicsExtractWrapped[expression_, position_List, wrapper_] :=
  With[{held = mathicsExtractHeld[expression, position]},
    If[MatchQ[held, HoldComplete[_]],
      Replace[held, HoldComplete[value_] :> wrapper[value]],
      System`Extract[expression, position, wrapper]]];

Extract[expression_, position : {___Integer}, wrapper_] :=
  mathicsExtractWrapped[expression, position, wrapper];
Extract[expression_, position_List] := System`Extract[expression, position];

End[];
