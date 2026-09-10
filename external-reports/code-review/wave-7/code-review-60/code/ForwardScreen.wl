(* This case list and projection were executed as an inline Wolfram query.
   The supplied file itself was not run. The check concerns orders below 4,
   not all higher claimed remainders or all package-supported functions. *)
If[Length[DownValues[AsymptoticAnalysis`AsymptoticExpansion]]===0,Abort[]];
Module[{x,fs,s,d,results},
 fs={Sin[x]/x^2,(Exp[x]-1-x)/x^3,Log[1+x]/x^4,
  (Sqrt[1+x]-1-x/2)/x^3,1/(Sin[x]/x-1),(1-Cos[x])/(x-Sin[x]),
  Exp[(Sin[x]-x)/x^3],Log[(1-Cos[x])/x^2],(1+Log[1+x]/x)^(-1),
  Sin[Log[1+x]/x],(1+Sin[x]/x)^Sqrt[2],((Exp[x]-1)/x)^(1/x),
  (1+x)^(1/x),Exp[Sin[x]/x],Sqrt[1+x]-Sqrt[1-x],
  Log[1+x]+Log[1-x],Exp[Log[1+x]]};
 results=Table[
  s=AsymptoticAnalysis`AsymptoticExpansion[fs[[i]],{x,0,4},"Backend"->"Package"];
  If[Head[s]===AsymptoticAnalysis`GeneralizedSeries,
   d=FullSimplify[Normal[Series[fs[[i]]-Normal[s],{x,0,3}]]];
   {i,s["RemainderPower"],s["RemainderLogDegree"],d},
   {i,s}],{i,Length[fs]}];
 Print[InputForm[results]];results
]
