(* Unexecuted native benchmark harness. It records outputs as well as timing.
   Equal integer orders across systems do NOT imply equal approximation
   contracts. No automatic speedup ratios are calculated.
   ASYMPTOTIC_PACKAGE must name an existing local reviewed package file.
   ASYMPTOTIC_BENCHMARK_REPEATS optionally sets measured warm runs (1..20). *)
root=DirectoryName[DirectoryName[$InputFileName]];
package=Environment["ASYMPTOTIC_PACKAGE"];
If[!StringQ[package] || !FileExistsQ[package],Print["Set ASYMPTOTIC_PACKAGE."];Exit[2]];
Get[package];
If[Length[DownValues[AsymptoticInverse`AsymptoticExpansion]]==0,Exit[2]];
raw=Environment["ASYMPTOTIC_BENCHMARK_REPEATS"];
repeats=If[StringQ[raw] && StringMatchQ[raw,DigitCharacter..],FromDigits[raw],3];
If[!IntegerQ[repeats] || !TrueQ[1<=repeats<=20],repeats=3];
Clear[x,y];
SetAttributes[one,HoldAllComplete];
one[id_,expr_] := Module[{result,timing,messages,normalTime,normal},
 Block[{$MessageList={}},
  timing=First[AbsoluteTiming[
    result=TimeConstrained[MemoryConstrained[expr,512*2^20,
      Failure["MemoryBudget",<||>]],20,Failure["TimeBudget",<||>]]]];
  messages=ToString[$MessageList,InputForm]];
 normalTime=First[AbsoluteTiming[normal=If[MatchQ[result,_AsymptoticInverse`GeneralizedSeries],Normal[result],result]]];
 <|"ID"->id,"Seconds"->timing,"ExtractionSeconds"->normalTime,
   "ResultHead"->ToString[Head[result],InputForm],"ResultBytes"->ByteCount[result],
   "ExpressionBytes"->ByteCount[normal],"Expression"->ToString[normal,InputForm],
   "Messages"->messages,"Remainder"->If[MatchQ[result,_AsymptoticInverse`GeneralizedSeries],
     ToString[result["Remainder"],InputForm],"See native output contract"]|>];
SetAttributes[run,HoldAllComplete];
run[id_,expr_] := Module[{cold,warm},ClearSystemCache[];
 cold=one[id,expr];warm=Table[one[id,expr],{repeats}];
 <|"ID"->id,"ColdOperation"->cold,"WarmRuns"->warm,
   "WarmMedianSeconds"->Median[Lookup[warm,"Seconds"]]|>];
results={
 run["taylor/package",AsymptoticInverse`AsymptoticExpansion[Exp[x]/(1-x),{x,0,9}]],
 run["taylor/Series",Series[Exp[x]/(1-x),{x,0,8}]],
 run["irrational/package",AsymptoticInverse`AsymptoticExpansion[Exp[x]+x^Sqrt[2],{x,0,6}]],
 run["irrational/Asymptotic",Asymptotic[Exp[x]+x^Sqrt[2],x->0,SeriesTermGoal->7]],
 run["algebraic-inverse/package",AsymptoticInverse`AsymptoticInverse[x+x^2,{x,0},{y,9}]],
 run["algebraic-inverse/InverseSeries",InverseSeries[Series[x+x^2,{x,0,8}],y]],
 run["log-inverse/package",AsymptoticInverse`AsymptoticInverse[x+x^2 Log[x],{x,0},{y,4}]],
 run["log-inverse/AsymptoticSolve",AsymptoticSolve[x+x^2 Log[x]==y,{x,0},{y,0,4},Reals]],
 run["large-denominator/package-safe-fixture",AsymptoticInverse`AsymptoticExpansion[1+x^(1/1000)+x,{x,0,1}]],
 run["lambert/package",AsymptoticInverse`AsymptoticInverse[x Log[x],{x,Infinity},{y,3}]],
 run["lambert/native-exact-reference",y/ProductLog[y]]};
meta=<|"ExecutionStatus"->"ExecutedByThisRunner","WolframVersion"->$Version,
 "SystemID"->$SystemID,"ReferenceCommit"->"07a9781212beb2eeb9ff16aa625b50ac27974078",
 "SourceFile"->ExpandFileName[package],
 "ObservedSourceSHA256"->IntegerString[FileHash[package,"SHA256"],16,64],
 "WarmRepeats"->repeats,"Caveat"->"Operation-cold after ClearSystemCache is not process-cold. Match actual terms, branch, error scale and validation work before calculating performance ratios.",
 "Results"->results|>;
output=FileNameJoin[{root,"evidence","builtin-benchmarks.json"}];
If[!StringQ[Export[output,meta,"RawJSON"]],Exit[1]];
Print[output];Exit[0];
