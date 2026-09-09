(* Additional source-audit questions, not asserted public bugs.
   Load the package first; each result should be examined in a fresh kernel.
   NOT RUN during the audit. No deliberately enormous allocation is attempted. *)
Module[{x, z, a, s, t, direct, nested},
  s = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  direct = SeriesAdd[s, a];
  nested = SeriesObservable[s, a + z, z];
  Print["R02 real-scalar consistency: ", InputForm[{direct, nested}]];
  t = GeneralizedSeries[Join[SeriesAdd[s, 0][[1]], <|"Expression" -> 123|>]];
  Print["A05 deliberately malformed object (not supported input): ",
    InputForm[{Normal[t], Normal[SeriesAdd[t, 0]]}]];
]
Module[{x, s, rows = {}, n},
  s = AsymptoticExpansion[1, {x, 0, 2}];
  Do[
    AppendTo[rows, {n, LeafCount[s], ByteCount[s], StringLength[ToString[s, InputForm]]}];
    s = SeriesMultiply[s, s], {n, 0, 8}];
  Print["A04 n, logical leaves, ByteCount, serialized characters: ", InputForm[rows]];
]
