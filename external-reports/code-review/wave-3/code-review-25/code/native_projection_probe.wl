(* No performance numbers from this harness are claimed in the article.
   Run in a fresh kernel: wolframscript -file native_projection_probe.wl package.wl *)
If[Length[$ScriptCommandLine] < 2, Print["Supply the local package path."]; Exit[2]];
Get[Last[$ScriptCommandLine]];
ClearAll[x, normalProbe];
normalCalls = 0;
normalProbe /: Normal[normalProbe] := (++normalCalls;7);
ClearSystemCache[];
directTime = AbsoluteTiming[direct = Series[normalProbe,{x,0,2}];][[1]];
directCalls = normalCalls;
wrappedTime = AbsoluteTiming[
 wrapped = AsymptoticAnalysis`AsymptoticExpansion[
   normalProbe,{x,0,2},"Backend"->"Series"];][[1]];
wrappedCalls = normalCalls-directCalls;
Print[InputForm[<|"Kernel"->$Version,"SystemID"->$SystemID,
  "DirectSeconds"->directTime,"WrappedSeconds"->wrappedTime,
  "DirectNormalCalls"->directCalls,"WrapperNormalCalls"->wrappedCalls,
  "NativeResult"->wrapped["NativeResult"],"Expression"->wrapped["Expression"],
  "Note"->"Single-run diagnostic, not a stable timing benchmark or a measurement of duplicated physical memory."|>]];
