(* Characterization, NOT a completed benchmark. Integer orders in different
   calls do not imply equal retained terms or equal achieved error contracts. *)
Get[FileNameJoin[{DirectoryName[$InputFileName],"NativeCommon.wl"}]];
results={
 auditProbe["native-polynomial-inverse",Module[{x,y},InverseSeries[Series[x+x^2,{x,0,5}],y]]],
 auditProbe["package-polynomial-inverse",Module[{x,y},AsymptoticInverse[x+x^2,{x,0},{y,6}]]],
 auditProbe["native-ramified-inverse",Module[{x,y},InverseSeries[Series[x^2+3*x^4,{x,0,8}],y]]],
 auditProbe["package-ramified-inverse",Module[{x,y},AsymptoticInverse[x^2+3*x^4,{x,0},{y,4}]]],
 auditProbe["native-irrational-implicit",Module[{x,y},AsymptoticSolve[x+x^Sqrt[2]==y,{x,0},{y,0,4},Reals]]],
 auditProbe["package-irrational-inverse",Module[{x,y},AsymptoticInverse[x+x^Sqrt[2],{x,0},{y,3}]]],
 auditProbe["native-Erfc-inverse",Module[{y},Asymptotic[InverseErfc[y],{y,0,3},Direction->"FromAbove"]]],
 auditProbe["package-Erfc-tail",Module[{x,y},AsymptoticSpecialInverse["Erfc",{x,Infinity},{y,2}]]],
 auditProbe["native-zeta-large-order",Module[{x},Asymptotic[Zeta[x],{x,Infinity,4}]]],
 auditProbe["package-zeta-Dirichlet",Module[{x},AsymptoticExpansion[Zeta[x],{x,Infinity},SeriesTermGoal->4]]],
 auditProbe["native-Gamma-implicit",Module[{x,y},AsymptoticSolve[LogGamma[x]==y,x,{y,Infinity,3},Reals]]],
 auditProbe["package-Gamma-Lambert-core",Module[{x,y},AsymptoticInverse[LogGamma[x],{x,Infinity},{y,2}]]]
};
auditWrite["native-builtin-comparison.json",Join[auditMetadata[],<|"Results"->results,
 "Warning"->"These are isolated bounded calls in one process, not matched-order speed comparisons."|>]];
