(* Observation probe for either baseline or patched source.
   No expected-success count is inferred from returned result heads.
   Load AsymptoticAnalysis first in a fresh kernel; then Get this file. *)
If[Length[DownValues[AsymptoticAnalysis`AsymptoticCoreInverse]]===0,
 Print["COMPONENT-AUDIT: package constructor is not loaded."]; Abort[]];
Module[{x,y,large,small,observe},
 observe[s_]:=If[Head[s]===AsymptoticAnalysis`GeneralizedSeries,
   <|"Head"->"GeneralizedSeries","Expression"->Normal[s],
     "RemainderScale"->s["RemainderScaleExpression"],
     "FirstOmittedMarkerTerm"->s["FirstOmittedMarkerTerm"],
     "Domain"->s["TargetDomain"],"Core"->s["Core"],"Perturbation"->s["Perturbation"]|>,s];
 large=AsymptoticAnalysis`AsymptoticCoreInverse[x-Re[y],Re[y]+1/x,{x,Infinity},{y,2}];
 small=AsymptoticAnalysis`AsymptoticCoreInverse[1/x-Re[y],Re[y]+x,{x,0},{y,2}];
 Print[InputForm[<|"Kernel"->$Version,"LargeBranch"->observe[large],
   "SmallBranch"->observe[small]|>]]
]
