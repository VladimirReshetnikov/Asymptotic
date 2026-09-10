(* No MUnit, network calls, or package edits. Load the package separately first.
   This portable file was not executed under Mathics during this audit. *)
If[Length[DownValues[AsymptoticAnalysis`AsymptoticCoreInverse]]===0,
 Print["COMPONENT-AUDIT: package constructor is not loaded."];
 Abort[]
];
Module[{x,y,big,small,good,explicit,results},
 big=AsymptoticAnalysis`AsymptoticCoreInverse[x-Re[y],Re[y]+1/x,{x,Infinity},{y,2}];
 small=AsymptoticAnalysis`AsymptoticCoreInverse[1/x-Re[y],Re[y]+x,{x,0},{y,2}];
 good=AsymptoticAnalysis`AsymptoticCoreInverse[x,1/x,{x,Infinity},{y,2}];
 explicit=AsymptoticAnalysis`AsymptoticCoreInverse[x-1,1+1/x,{x,Infinity},{y,2},"CoreInverse"->y+1];
 results={
  {"CV01",MatchQ[big,Failure["InvalidVariables",_Association]]},
  {"CV03",MatchQ[small,Failure["InvalidVariables",_Association]]},
  {"CV08",Head[good]===AsymptoticAnalysis`GeneralizedSeries &&
    Together[Normal[good]-(y-1/y-1/y^3)]===0 &&
    Together[good["RemainderScaleExpression"]-1/y^5]===0},
  {"CV10",Head[explicit]===AsymptoticAnalysis`GeneralizedSeries &&
    Together[Normal[explicit]-(y-1/(y+1)-1/(y+1)^2-1/(y+1)^3)]===0}
 };
 Print[InputForm[<|"Kernel"->$Version,"Results"->results,
   "Passed"->Count[results,{_,True}],"Failed"->Count[results,{_,Except[True]}]|>]];
 results
]
