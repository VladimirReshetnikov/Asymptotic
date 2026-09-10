(* Focused baseline observations. Run in a fresh Wolfram 15+ kernel.
   Usage: wolframscript -file native_characterizations.wl /path/to/AsymptoticAnalysis.wl
   This program does not run the upstream suite and does not alter source files. *)
If[Length[$ScriptCommandLine] < 2, Print["Supply the local package file."]; Exit[2]];
Get[Last[$ScriptCommandLine]];
ClearAll[x, z, shortSin, normalProbe, MadeUpOption];
summary[s_] := If[FailureQ[s], s, KeyTake[s[[1]],
  {"Kind", "Expression", "Remainder", "Exact", "RemainderDerivativeOrder", "NativeBackend"}]];
observations = <|"Kernel" -> $Version, "SystemID" -> $SystemID,
  "IntendedSnapshot" -> "6687962f3c858a4f93623cfc496f33e35c6763d4"|>;
s1 = AsymptoticAnalysis`AsymptoticExpansion[1-x, {x,0,1}, "Backend"->"Package"];
s2 = AsymptoticAnalysis`AsymptoticExpansion[1-x, {x,0,2}, "Backend"->"Package"];
AssociateTo[observations, "N01" -> (summary /@ {
  AsymptoticAnalysis`SeriesObservable[s1, FractionalPart[z], z],
  AsymptoticAnalysis`SeriesObservable[s2, FractionalPart[z], z]})];
shortSin[0] = 0;
shortSin[t_?NumericQ] := Sin[t];
shortSin /: Series[shortSin[v_], {u_Symbol,0,n_Integer}, opts___] /; v===u :=
  SeriesData[u,0,{1},1,2,1];
sx = AsymptoticAnalysis`AsymptoticExpansion[x,{x,0,5},"Backend"->"Package"];
AssociateTo[observations, "N02Oracle" -> Series[shortSin[x],{x,0,5}],
  "N02" -> summary[AsymptoticAnalysis`SeriesObservable[sx,shortSin[z],z,"Cutoff"->5]]];
savedOptions = Options[AsymptoticAnalysis`AsymptoticExpansion];
SetOptions[AsymptoticAnalysis`AsymptoticExpansion,"Backend"->"Series"];
AssociateTo[observations,"N03SeriesDefault" -> summary[
  AsymptoticAnalysis`AsymptoticExpansion[Exp[x],{x,0,2}]]];
SetOptions[AsymptoticAnalysis`AsymptoticExpansion,"Backend"->"Package"];
AssociateTo[observations,"N03PackageDefault" -> summary[
  AsymptoticAnalysis`AsymptoticExpansion[Exp[I x],{x,0,2}]]];
Options[AsymptoticAnalysis`AsymptoticExpansion] = savedOptions;
AssociateTo[observations,"N04" -> summary[
  AsymptoticAnalysis`SeriesDifferentiate[sx,0,"Cutoff"->1]],
  "N04InvalidLimitControl" -> AsymptoticAnalysis`SeriesDifferentiate[sx,0,"MaxTerms"->0],
  "N05" -> summary[AsymptoticAnalysis`AsymptoticExpansion[Exp[x],{x,0,2},
     MadeUpOption->123,"Backend"->"Package"]]];
normalCalls = 0;
normalProbe /: Normal[normalProbe] := (++normalCalls;7);
direct = Series[normalProbe,{x,0,2}];
sn = AsymptoticAnalysis`AsymptoticExpansion[normalProbe,{x,0,2},"Backend"->"Series"];
AssociateTo[observations,"N06" -> <|"Direct"->direct,"NormalCalls"->normalCalls,
  "NativeResult"->sn["NativeResult"],"Expression"->sn["Expression"]|>];
Print[InputForm[observations]];
