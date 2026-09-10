(* Loaded only by Mathics, after the ordinary analytic engines.
   Mathics sends a symbolic Sum body to SymPy before substituting a finite
   iterator. Derivative orders and Part indices must already be integers
   when evaluated. Table binds those indices first and Total performs the
   same exact finite sum; the official kernel retains its original code. *)

DownValues[PerturbativeInverse] = {};
PerturbativeInverse[phi_, h_, {x_Symbol, y_Symbol}, n_Integer?NonNegative] :=
  System`Module[{hy},
    If[x === y || ! FreeQ[h, y] || ! FreeQ[phi, x],
      Failure["InvalidVariables", <|"MessageTemplate" -> "Use distinct symbols; h must not contain y and phi must not contain x."|>],
      hy = h /. x -> phi;
      phi + Total[System`Table[(-1)^k/k! D[D[phi, y] hy^k, {y, k - 1}], {k, 1, n}]]]];
PerturbativeInverse[h_, {x_Symbol, y_Symbol}, n_Integer?NonNegative] :=
  PerturbativeInverse[y, h, {x, y}, n];
PerturbativeInverse[___] := Failure["InvalidArguments", <|"MessageTemplate" ->
  "Use PerturbativeInverse[phi, h, {x, y}, n] or PerturbativeInverse[h, {x, y}, n]."|>];

logarithmicEuler[e_, levels_] := -Total[System`Table[
  D[e, levels[[j]]]/(Times @@ Take[levels, j - 1]), {j, Length[levels]}]];
