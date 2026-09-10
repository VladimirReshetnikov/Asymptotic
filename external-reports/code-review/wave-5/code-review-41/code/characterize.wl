(* Baseline observation script; NOT executed during authoring.
   wolframscript -file code/characterize.wl /path/to/AsymptoticAnalysis.wl *)
args = Rest[$ScriptCommandLine];
If[Length[args] =!= 1, Print["Supply one local package entry file."]; Exit[2]];
entry = ExpandFileName[First[args]];
If[! FileExistsQ[entry], Print["Missing package file."]; Exit[2]];
Get[entry];
Print["Kernel: ", $Version, "; entry: ", entry];
Clear[x, z, a];
s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4},
  Assumptions -> a^2 == -1, "Backend" -> "Package"];
Print["Seed: ", InputForm[If[FailureQ[s], s, {s["Kind"], Normal[s], s["Remainder"], s["Assumptions"]}]]];
If[FailureQ[s], Exit[1]];
Do[
 result = AsymptoticAnalysis`SeriesObservable[s, expr, z, "Cutoff" -> 4];
 Print["Observable: ", InputForm[expr]];
 Print["Result: ", InputForm[If[FailureQ[result], result,
   {Normal[result], result["Remainder"], result["Exact"], result["Assumptions"]}]]],
 {expr, {Abs[1+a z]+Abs[1-a z], Abs[1+a z]^2+Abs[1-a z]^2,
   Abs[1+a z]-Abs[1-a z], Abs[1+I z]+Abs[1-I z]}}];
Print["Independent identities for real x:"];
Print[FullSimplify[{Abs[1+I x]+Abs[1-I x], Abs[1+I x]^2+Abs[1-I x]^2}, Element[x, Reals]]];
