(* Run in a fresh native kernel:
   wolframscript -file characterize.wl /absolute/path/AsymptoticAnalysis.wl observations.json
   This script was NOT run by the audit. It makes no repository modifications.
   Results, messages and timeouts are observations, not automatically passing tests. *)
If[Length[$ScriptCommandLine] < 3,
 Print["Usage: characterize.wl package.wl observations.json"]; Exit[2]];
packagePath = $ScriptCommandLine[[-2]];
outputPath = $ScriptCommandLine[[-1]];
If[! FileExistsQ[packagePath], Print["Package file not found."]; Exit[2]];
Get[packagePath];
If[Length[DownValues[AsymptoticAnalysis`AsymptoticExpansion]] == 0,
 Print["The package entry point did not load."]; Exit[2]];

ClearAll[observe];
SetAttributes[observe, HoldAllComplete];
observe[label_, expression_] := Block[{$MessageList = {}}, Module[{r, elapsed},
 {elapsed, r} = AbsoluteTiming[Quiet[CheckAbort[
    TimeConstrained[expression, 30, Failure["AuditTimeout", <||>]],
    Failure["AuditAborted", <||>]]]];
 <|"Label"->label, "Seconds"->elapsed,
   "ResultInputForm"->ToString[r, InputForm],
   "MessagesInputForm"->ToString[$MessageList, InputForm],
   "FailureQ"->FailureQ[r],
   "GeneralizedSeriesQ"->MatchQ[r, _AsymptoticAnalysis`GeneralizedSeries]|>
]];

ClearAll[x,y,a,z,shortTaylor];
shortTaylor[0]=1;
shortTaylor[z_?NumericQ] := 1/(1-z);
shortTaylor /: Series[shortTaylor[arg_], {v_Symbol,0,ord_Integer},
 opts:OptionsPattern[Series]] := Series[1/(1-arg), {v,0,Min[ord,1]}, opts];
s = AsymptoticAnalysis`AsymptoticExpansion[x, {x,0,4}, "Backend"->"Package"];
f = AsymptoticAnalysis`AsymptoticExpansion[1+x, {x,0,2}, "Backend"->"Package"];
observations = {
 observe["T01-native-short-oracle", Series[shortTaylor[z], {z,0,3}]],
 observe["T01-observable-short-oracle", AsymptoticAnalysis`SeriesObservable[s,shortTaylor[z],z,"Cutoff"->3]],
 observe["T01-complete-built-in-control", AsymptoticAnalysis`SeriesObservable[s,Cos[z],z,"Cutoff"->3]],
 observe["A01-upstream-forward-object-coefficient-call", AsymptoticAnalysis`InverseExpansionCoefficient[f,{0}]],
 observe["N01-direct-native-conditional", Series[ConditionalExpression[1+I*x,a>0],{x,0,2},Assumptions->a>0]],
 observe["N01-explicit-wrapper-conditional", AsymptoticAnalysis`AsymptoticExpansion[ConditionalExpression[1+I*x,a>0],{x,0,2},Assumptions->a>0,"Backend"->"Series"]],
 observe["N01-automatic-wrapper-conditional", AsymptoticAnalysis`AsymptoticExpansion[ConditionalExpression[1+I*x,a>0],{x,0,2},Assumptions->a>0]],
 observe["N01-automatic-unconditional-control", AsymptoticAnalysis`AsymptoticExpansion[1+I*x,{x,0,2}]],
 observe["U01-native-failure-marker", AsymptoticAnalysis`AsymptoticExpansion[$Failed,{x,0,2},"Backend"->"Series"]],
 observe["ordinary-inverse-control", AsymptoticAnalysis`AsymptoticInverse[x+x^2,{x,0},{y,5}]],
 observe["native-inverse-control", InverseSeries[Series[x+x^2,{x,0,5}],y]],
 observe["native-implicit-inverse-control", AsymptoticSolve[x+x^2==y,{x,0},{y,0,4},Reals]]
};
Export[outputPath, <|"KernelVersion"->$Version,"SystemID"->$SystemID,
 "PackagePath"->ExpandFileName[packagePath],
 "DeclaredAuditRevision"->"6687962f3c858a4f93623cfc496f33e35c6763d4",
 "RevisionWasNotAutomaticallyVerified"->True,
 "NativeSeriesOptions"->ToString[Options[Series],InputForm],
 "NativeAsymptoticOptions"->ToString[Options[Asymptotic],InputForm],
 "Observations"->observations|>, "RawJSON"];
Print[outputPath];
