(* Fresh kernel; load the pinned package first. No unsupported universal
   conclusions should be inferred from the one bounded AsymptoticSolve call. *)
Block[{$Assumptions = True}, Module[{x, y, p, l, q, native},
 p = AsymptoticInverse`AsymptoticInverse[x + x^2, {x, 0}, {y, 6}];
 l = AsymptoticInverse`AsymptoticExpansion[x^x, {x, 0, 3}];
 q = AsymptoticInverse`AsymptoticInverse[x + x^Sqrt[2], {x, 0}, {y, 2}];
 native = TimeConstrained[
   AsymptoticSolve[x + x^Sqrt[2] == y, x -> 0, y -> 0, Reals,
     SeriesTermGoal -> 3], 8, "BoundedTimeout"];
 <|"Kernel" -> $Version,
   "Polynomial" -> {Normal[p], Normal[InverseSeries[Series[x + x^2, {x, 0, 5}], y]], p["Remainder"]},
   "Logarithmic" -> {Normal[l], Normal[Series[x^x, {x, 0, 2}]], l["Remainder"]},
   "Irrational" -> {Normal[q], q["Remainder"], native}|>
]]
