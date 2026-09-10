(* Load the candidate package before TestReport[this file].
   These are desired-behavior tests, not assertions that the baseline passes. *)
ClearAll[x,z,shortSin];
VerificationTest[
  FailureQ[AsymptoticAnalysis`SeriesObservable[
    AsymptoticAnalysis`AsymptoticExpansion[1-x,{x,0,1},"Backend"->"Package"],
    FractionalPart[z],z]],True,TestID->"N01-uncertain-side-refused"]
VerificationTest[
  FailureQ[AsymptoticAnalysis`SeriesObservable[
    AsymptoticAnalysis`AsymptoticExpansion[1-x,{x,0,2},"Backend"->"Package"],
    FractionalPart[z],z]],True,TestID->"N01-known-left-side-conservative-refusal"]
VerificationTest[
  Module[{s,r},s=AsymptoticAnalysis`AsymptoticExpansion[x,{x,0,5},"Backend"->"Package"];
    r=AsymptoticAnalysis`SeriesObservable[s,Sin[z],z,"Cutoff"->5];
    Simplify[r["Expression"]-(x-x^3/6)]],0,TestID->"analytic-Sin-control"]
VerificationTest[
  Module[{s,r},s=AsymptoticAnalysis`AsymptoticExpansion[x,{x,0,4},"Backend"->"Package"];
    r=AsymptoticAnalysis`SeriesObservable[s,Cos[z],z,"Cutoff"->4];
    Simplify[r["Expression"]-(1-x^2/2)]],0,TestID->"analytic-Cos-control"]
VerificationTest[
  Module[{s,r},s=AsymptoticAnalysis`AsymptoticExpansion[1/2+x,{x,0,2},"Backend"->"Package"];
    r=AsymptoticAnalysis`SeriesObservable[s,FractionalPart[z],z];
    Simplify[r["Expression"]-(1/2+x)]],0,TestID->"FractionalPart-away-from-jump-control"]
VerificationTest[
  Module[{s,r},s=AsymptoticAnalysis`AsymptoticExpansion[1,{x,0,2},"Backend"->"Package"];
    r=AsymptoticAnalysis`SeriesObservable[s,FractionalPart[z],z];
    r["Expression"]],0,TestID->"exact-constant-at-jump-control"]
VerificationTest[
  Module[{s,r},ClearAll[shortSin];shortSin[0]=0;shortSin[t_?NumericQ]:=Sin[t];
    shortSin /: Series[shortSin[v_],{u_Symbol,0,n_Integer},opts___] /; v===u := SeriesData[u,0,{1},1,2,1];
    s=AsymptoticAnalysis`AsymptoticExpansion[x,{x,0,5},"Backend"->"Package"];
    r=AsymptoticAnalysis`SeriesObservable[s,shortSin[z],z,"Cutoff"->5];
    MatchQ[r,Failure["InsufficientNativeObservablePrecision",_Association]]],True,
  TestID->"N02-short-native-jet-refused"]
VerificationTest[
  Module[{old=Options[AsymptoticAnalysis`AsymptoticExpansion],s,result},
    SetOptions[AsymptoticAnalysis`AsymptoticExpansion,"Backend"->"Series"];
    s=AsymptoticAnalysis`AsymptoticExpansion[Exp[x],{x,0,2}];
    result={s["Kind"],s["Expression"]};Options[AsymptoticAnalysis`AsymptoticExpansion]=old;result],
  {"Native",1+x+x^2/2},TestID->"N03-default-Series-respected"]
VerificationTest[
  Module[{old=Options[AsymptoticAnalysis`AsymptoticExpansion],s,result},
    SetOptions[AsymptoticAnalysis`AsymptoticExpansion,"Backend"->"Package"];
    s=AsymptoticAnalysis`AsymptoticExpansion[Exp[I x],{x,0,2}];
    result=FailureQ[s];Options[AsymptoticAnalysis`AsymptoticExpansion]=old;result],
  True,TestID->"N03-default-Package-respected"]
VerificationTest[
  Module[{old=Options[AsymptoticAnalysis`AsymptoticExpansion],s,result},
    SetOptions[AsymptoticAnalysis`AsymptoticExpansion,"Backend"->"Package"];
    s=AsymptoticAnalysis`AsymptoticExpansion[Exp[I x],{x,0,2},"Backend"->"Series"];
    result=s["Kind"];Options[AsymptoticAnalysis`AsymptoticExpansion]=old;result],
  "Native",TestID->"N03-explicit-override-respected"]
