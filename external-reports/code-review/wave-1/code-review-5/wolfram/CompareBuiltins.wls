(* Reproducible native comparison CASE COLLECTOR, not an assertion that every
   built-in solves every case. NOT EXECUTED during the audit.
   Set ASYMPTOTIC_REPO. Run in a fresh kernel; no cross-case timing claim follows
   from this single sequential run. The cutoff conventions differ by method.
   SPDX-License-Identifier: MIT-0 *)
root = Environment["ASYMPTOTIC_REPO"];
If[! StringQ[root] || root === "", Print["Set ASYMPTOTIC_REPO."]; Exit[2]];
Get[FileNameJoin[{root, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]];
If[! MemberQ[$Packages, "AsymptoticInverse`"], Exit[2]];
Clear[x, y, u];
cases = {
 {"ordinary-inverse/package", HoldComplete[AsymptoticInverse[x + x^2, {x, 0}, {y, 5}]]},
 {"ordinary-inverse/InverseSeries", HoldComplete[InverseSeries[x + x^2 + O[x]^5] /. x -> y]},
 {"ordinary-inverse/AsymptoticSolve", HoldComplete[AsymptoticSolve[x + x^2 == y, {x, 0}, {y, 0, 4}, Reals]]},
 {"log-inverse/package", HoldComplete[AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}]]},
 {"log-inverse/AsymptoticSolve", HoldComplete[AsymptoticSolve[x + x^2 (1 + Log[x]) == y, {x, 0}, {y, 0, 3}, Reals]]},
 {"irrational-inverse/package", HoldComplete[AsymptoticInverse[x + x^Sqrt[2], {x, 0}, y, SeriesTermGoal -> 5]]},
 {"irrational-inverse/AsymptoticSolve", HoldComplete[AsymptoticSolve[x + x^Sqrt[2] == y, {x, 0}, y -> 0, Reals, SeriesTermGoal -> 5]]},
 {"forward-Bessel/package", HoldComplete[AsymptoticExpansion[BesselJ[0, x], {x, Infinity}, SeriesTermGoal -> 3]]},
 {"forward-Bessel/Series", HoldComplete[Series[BesselJ[0, x], {x, Infinity, 3}]]},
 {"forward-Bessel/Asymptotic", HoldComplete[Asymptotic[BesselJ[0, x], x -> Infinity, SeriesTermGoal -> 3]]},
 {"Gamma-inverse/package", HoldComplete[AsymptoticInverse[LogGamma[x], {x, Infinity}, y, SeriesTermGoal -> 4]]},
 {"Gamma-inverse/AsymptoticSolve", HoldComplete[AsymptoticSolve[LogGamma[x] == y, {x, Infinity}, y -> Infinity, Reals, SeriesTermGoal -> 4]]},
 {"Newton-wrapper-budget/package", HoldComplete[AsymptoticInverse[Sum[x^k, {k, 1, 31}], {x, 0}, {y, 31}, Method -> "Newton", "MaxTerms" -> 20000]]}
};
collect[{name_, held_HoldComplete}] := Module[{elapsed, result, messages},
 Block[{$MessageList = {}},
  {elapsed, result} = AbsoluteTiming[MemoryConstrained[
    TimeConstrained[ReleaseHold[held], 60, $Aborted], 512 1024^2, $Aborted]];
  messages = ToString[$MessageList, InputForm]];
 <|"Case" -> name, "Input" -> ToString[held, InputForm], "Seconds" -> elapsed,
   "Output" -> ToString[result, InputForm], "Head" -> ToString[Head[result], InputForm],
   "Messages" -> messages, "Aborted" -> (result === $Aborted),
   "Failure" -> FailureQ[result]|>];
rows = collect /@ cases;
output = FileNameJoin[{DirectoryName[$InputFileName], "native-comparison-results.json"}];
Export[output, <|"Kernel" -> $Version, "SystemID" -> $SystemID,
 "Status" -> "ExecutedCaseCollector", "Cases" -> rows,
 "Warning" -> "Normalize variable, branch, scale and truncation before comparing outputs. Sequential timings are not fresh-kernel benchmarks; unevaluated output is not a theorem of impossibility."|>, "RawJSON"];
Print[output];
