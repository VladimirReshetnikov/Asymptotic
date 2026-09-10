(* wolframscript -file code/reproduce.wl /path/to/AsymptoticInverse.wl
   With no package argument, the pinned public standalone is downloaded.
   Results are written next to the current working directory, not to the repo. *)
args = Rest[$ScriptCommandLine];
package = If[args =!= {}, First[args], URLDownload[
 "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/921387e5ba1239bfda96e63e64e89bf63d9c41e6/AsymptoticInverse.wl"]];
If[! FileExistsQ[package], Print["Package file not available."]; Exit[2]];
Get[package];
SetAttributes[record, HoldRest];
records = {};
record[id_, expression_] := Module[{value, elapsed, messages},
 Block[{$MessageList = {}},
  {elapsed, value} = AbsoluteTiming[TimeConstrained[Quiet[expression],30,
    Missing["TimeLimit",30]]];
  messages = ToString[#,InputForm] & /@ $MessageList];
 AppendTo[records,<|"ID"->id,"ElapsedSeconds"->elapsed,
   "Input"->ToString[HoldComplete[expression],InputForm],
   "Output"->ToString[value,InputForm],"Messages"->messages|>];
];
Clear[x,y,a,z];
record["N01-relative-default",
 Module[{s,r},s=AsymptoticInverse`AsymptoticInverse[x^2,{x,Infinity},{y,1}];
 r=AsymptoticInverse`InverseCertificate[s,2,"Interval"->{1,2},
   "RelativeError"->10^-120,"MaxRefinements"->3,"RefineExpansion"->False];
 If[FailureQ[r],{r[[1]],Lookup[Lookup[r[[2]],"History",{}],"EnclosureOrder"],
   N[Lookup[Lookup[r[[2]],"BestCertificate",<||>],"CertifiedErrorBound",Missing["Absent"]],12]},r]]];
record["N01-absolute-control",
 Module[{s,r},s=AsymptoticInverse`AsymptoticInverse[x^2,{x,Infinity},{y,1}];
 r=AsymptoticInverse`InverseCertificate[s,2,"Interval"->{1,2},
   "TargetError"->10^-120,"MaxRefinements"->3,"RefineExpansion"->False];
 If[AssociationQ[r],{r["Certified"],r["AccuracyGoalReached"],
   Lookup[r["History"],"EnclosureOrder"],N[r["CertifiedErrorBound"],12]},r]]];
record["N02-forward-coarsening",
 With[{s=AsymptoticInverse`AsymptoticExpansion[Sin[x],{x,0,7}]},
  With[{t=AsymptoticInverse`SeriesRefine[s,3]},
   {Normal[s],s["Remainder"],Normal[t],t["Remainder"]}]]];
record["C07-forward",With[{s=AsymptoticInverse`AsymptoticExpansion[ArcSin[2]+x,{x,0,2}]},
 If[FailureQ[s],s,{Normal[s],s["TargetDomain"]}]]];
record["C07-cross-entry",With[{s=AsymptoticInverse`AsymptoticExpansion[x,{x,0,3}]},
 {AsymptoticInverse`SeriesAdd[s,ArcSin[2]],
  Normal[AsymptoticInverse`SeriesObservable[s,z+ArcSin[2],z]]}]];
record["C04-frontier",Module[{s,t,u},
 s=AsymptoticInverse`AsymptoticExpansion[x Log[x]+x^2,{x,0,2}];
 t=AsymptoticInverse`SeriesExp[s];u=AsymptoticInverse`SeriesExp[s,3];
 {{Normal[t],t["Remainder"]},{Normal[u],u["Remainder"]}}]];
record["B01-native-inverse",InverseSeries[Series[x+x^2,{x,0,4}],y]];
record["B01-native-solve",AsymptoticSolve[x+x^2==y,{x,0},{y,0,4},Reals]];
record["B02-package",Normal[AsymptoticInverse`AsymptoticInverse[x+x^2 Log[x],{x,0},{y,4}]]];
record["B02-native",AsymptoticSolve[x+x^2 Log[x]==y,{x,0},{y,0,3},Reals]];
record["B03-package",Normal[AsymptoticInverse`AsymptoticInverse[x+x^Sqrt[2],{x,0},{y,2}]]];
record["B03-native",AsymptoticSolve[x+x^Sqrt[2]==y,{x,0},{y,0,3},Reals]];
record["B04-package",Normal[AsymptoticInverse`AsymptoticExpansion[Gamma[x],{x,Infinity,3}]]];
record["B04-native",Asymptotic[Gamma[x],x->Infinity,SeriesTermGoal->3]];
Export["audit-native-results.json",<|"Kernel"->$Version,"PackageBytes"->FileByteCount[package],
 "PackageSHA256"->IntegerString[FileHash[package,"SHA256"],16,64],"Records"->records|>,"RawJSON"];
Print["Wrote audit-native-results.json (",Length[records]," cases)."];
