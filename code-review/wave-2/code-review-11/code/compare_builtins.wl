(* Optional comparison harness; not executed in this audit. Individual refusal
   or timeout is not a universal statement about a built-in's capabilities. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "load_pinned.wl"}]];
Clear[x, y];
SetAttributes[compareProbe, HoldAll];
compareProbe[label_, expr_] := Print[ExportString[<|"case" -> label,
  "result_inputform" -> ToString[TimeConstrained[expr, 20, "HARNESS_TIME_LIMIT"], InputForm]|>, "RawJSON"]];
compareProbe["native-ordinary-inverse", InverseSeries[Series[x + x^2, {x, 0, 5}], y]];
compareProbe["package-ordinary-inverse", AsymptoticInverse`AsymptoticInverse[x + x^2, {x, 0}, {y, 6}]];
compareProbe["native-irrational-implicit", AsymptoticSolve[x + x^Sqrt[2] == y, x, {y, 0, 3}, Assumptions -> y > 0]];
compareProbe["package-irrational-inverse", AsymptoticInverse`AsymptoticInverse[x + x^Sqrt[2], {x, 0}, {y, 3}]];
compareProbe["native-erfc", Asymptotic[Erfc[x], {x, Infinity, 3}]];
compareProbe["package-erfc", AsymptoticInverse`AsymptoticExpansion[Erfc[x], {x, Infinity, 6}]];
compareProbe["native-loggamma", Series[LogGamma[x], {x, Infinity, 3}]];
compareProbe["package-loggamma", AsymptoticInverse`AsymptoticExpansion[LogGamma[x], {x, Infinity, 4}]];
