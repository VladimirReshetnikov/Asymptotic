src=Import["https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/efa1aeec4845a9c35e140963a0333d0c9ec33b05/AsymptoticAnalysis.wl","Text"];
If[!StringQ[src]||StringLength[src]<692000,Return["INCOMPLETE_SOURCE"]]; Get[StringToStream[src]];
s=AsymptoticAnalysis`AsymptoticExpansion[a x,{x,0,2},Assumptions->a>0,"Backend"->"Package"];
result=Reap[Do[Sow[{k,Length[s["Blocks"]],LeafCount[s["Assumptions"]],
 Count[s["Assumptions"],a>0,{0,Infinity}],LeafCount[s["TargetDomain"]]}];
 If[k<5,s=AsymptoticAnalysis`SeriesAdd[s,s]],{k,0,5}]][[2]];
{StringLength[src],result}
