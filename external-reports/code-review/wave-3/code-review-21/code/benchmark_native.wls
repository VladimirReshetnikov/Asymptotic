(* UNRUN benchmark harness. Use a separate fresh kernel per variant.
   wolframscript -file benchmark_native.wls kernel-entry variant output.json
   Variants: NativeSeries, ExplicitWrapper, AutomaticWrapper, ExactRefinement.
   This records end-memory deltas, NOT per-case peak memory. *)
args = Rest[$ScriptCommandLine];
If[Length[args] =!= 3, Print["Expected package-entry variant output.json"]; Exit[2]];
Get[ExpandFileName[args[[1]]]]; variant = args[[2]]; output = ExpandFileName[args[[3]]];
ClearAll[runCase];
Switch[variant,
 "NativeSeries", runCase[] := Series[Exp[I x], {x, 0, 20}],
 "ExplicitWrapper", runCase[] := AsymptoticExpansion[Exp[I x], {x, 0, 20}, "Backend" -> "Series"],
 "AutomaticWrapper", runCase[] := AsymptoticExpansion[Exp[I x], {x, 0, 20}],
 "ExactRefinement",
   ancestor = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}, "InputRemainder" -> {4, 0}];
   exactConstant = SeriesObservable[ancestor, 7, z];
   runCase[] := SeriesRefine[exactConstant, 20],
 _, Print["Unknown variant."]; Exit[2]];
first = AbsoluteTiming[TimeConstrained[runCase[], 30, $TimedOut]];
trials = Table[
  before = MemoryInUse[];
  measured = AbsoluteTiming[TimeConstrained[Do[last = runCase[], {10}], 60, $TimedOut]];
  <|"BatchSeconds" -> measured[[1]], "Calls" -> 10,
    "Timeout" -> (measured[[2]] === $TimedOut), "EndMemoryDeltaBytes" -> MemoryInUse[] - before,
    "LastResultHead" -> ToString[Head[last], InputForm]|>, {5}];
record = <|"KernelVersion" -> $Version, "SystemID" -> $SystemID, "Variant" -> variant,
 "PackageEntryPoint" -> ExpandFileName[args[[1]]], "FirstCallInThisProcessSeconds" -> first[[1]],
 "FirstResult" -> ToString[first[[2]], InputForm], "WarmBatches" -> trials,
 "Interpretation" -> "Do not compare successful and failed contracts as equal work. First call is not a guarantee of an empty OS cache; end-memory is not peak memory."|>;
If[Export[output, record, "RawJSON"] === $Failed, Exit[3]];
Print["Wrote ", output];
