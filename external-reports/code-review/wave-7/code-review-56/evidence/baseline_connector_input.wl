src=Import["https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/efa1aeec4845a9c35e140963a0333d0c9ec33b05/AsymptoticAnalysis.wl","Text"];
If[!StringQ[src]||StringLength[src]<692000,Return["INCOMPLETE_SOURCE"]];
Get[StringToStream[src]];
s=AsymptoticAnalysis`AsymptoticExpansion[1/(1-a x^3),{x,0,1},Assumptions->a^2==-1,"Backend"->"Package"];
t=AsymptoticAnalysis`SeriesMultiply[AsymptoticAnalysis`SeriesAdd[s,-1],x^-4];
u=Sin[t]; v=Cos[t];
{StringLength[src],Map[If[MatchQ[#,_AsymptoticAnalysis`GeneralizedSeries],
 KeyTake[#[[1]],{"Kind","Scale","Expression","Remainder","Assumptions","TargetDomain"}],#]&,{s,t,u,v}]}
