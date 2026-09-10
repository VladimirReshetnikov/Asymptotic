(* Native comparison probes. Values are evidence for this kernel and call,
   not universal claims about the built-ins. Each probe has a time budget. *)
SetAttributes[probe, HoldAll];
probe[label_, expression_] := Module[{time, value},
 {time, value} = AbsoluteTiming[TimeConstrained[expression, 20, $Aborted]];
 <|"Case" -> label, "Seconds" -> time, "Value" -> value|>];
Print[$Version];
Print[probe["polynomial inverse branches", AsymptoticSolve[x + x^2 == y, x, {y, 0, 4}, Reals]]];
Print[probe["native reversion", InverseSeries[Series[x + x^2, {x, 0, 5}]]]];
Print[probe["finite irrational support", Series[x^Sqrt[2] + x^Pi, {x, 0, 4}]]];
Print[probe["irrational inverse", AsymptoticSolve[x + x^Sqrt[2] == y, x, y -> Infinity, Reals, SeriesTermGoal -> 3]]];
Print[probe["logarithmic inverse", AsymptoticSolve[x + x^2 Log[x] == y, x, y -> 0, Reals, SeriesTermGoal -> 3]]];
Print[probe["special-function asymptotic", Asymptotic[Erfc[x], x -> Infinity, SeriesTermGoal -> 3]]];
