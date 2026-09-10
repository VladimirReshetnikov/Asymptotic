(* Narrow candidate: preserve bare-symbol data and nested held data.
   Tested as an isolated rewrite on Wolfram 15; not tested in Mathics.
   This does NOT solve arbitrary higher-order/effectful option-program semantics.
   It does not install itself into AsymptoticAnalysis. *)
ClearAll[AsymptoticReview`ProtectInputAssumptions];
AsymptoticReview`ProtectInputAssumptions[held_HoldComplete] :=
  If[FreeQ[held, System`Element], held, System`Module[
    {options, heads, opaque, positions},
    options = Position[held,
      HoldPattern[Rule[Assumptions, _] | RuleDelayed[Assumptions, _]],
      {0, Infinity}, Heads -> False];
    If[options === {}, held,
      heads = Position[held, System`Element, {0, Infinity}, Heads -> True];
      (* Level 0 is our transport wrapper, not user-owned held data. *)
      opaque = Position[held,
        _HoldComplete | _Hold | _HoldForm | _Defer | _HoldPattern | _Verbatim,
        {1, Infinity}, Heads -> False];
      positions = Select[heads, Function[position,
        Length[position] > 0 && Last[position] === 0 &&
        Or @@ (Function[option,
          Length[position] >= Length[option] + 1 &&
          Take[position, Length[option] + 1] === Append[option, 2]] /@ options) &&
        ! Or @@ (Function[barrier,
          Length[position] >= Length[barrier] &&
          Take[position, Length[barrier]] === barrier] /@ opaque)]];
      ReplacePart[held,
        (# -> AsymptoticAnalysis`Mathics`Element) & /@ positions]]]];
