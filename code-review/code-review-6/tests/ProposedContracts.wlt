(* DESIRED CONTRACTS, NOT a claimed passing suite for the pinned upstream.
   These tests target findings A01-A04. They have NOT been run natively.
   The coefficient test chooses the explicit-option-wins design policy. *)
VerificationTest[
 Module[{x,s},s=AsymptoticInverse`AsymptoticExpansion[1+x Log[x],{x,0,1}];
  MatchQ[s,_AsymptoticInverse`GeneralizedSeries] && MissingQ[s["SeriesData"]]],
 True, TestID->"A02-do-not-export-unqualified-log-tail"]
VerificationTest[
 Module[{x,s,q=1000000},
  s=TimeConstrained[MemoryConstrained[
    AsymptoticInverse`AsymptoticExpansion[1+x^(1/q)+x,{x,0,1},"MaxTerms"->10],
    256*2^20,Failure["MemoryBudget",<||>]],20,Failure["TimeBudget",<||>]];
  MatchQ[s,_AsymptoticInverse`GeneralizedSeries] &&
    MatchQ[s["SeriesData"],Missing["DenseRepresentationBudget",___]]],
 True, TestID->"A01-sparse-result-survives-dense-export-budget"]
VerificationTest[
 Module[{x,y,s,c},s=AsymptoticInverse`AsymptoticInverse[x+x^2,{x,0},{y,4}];
  c=AsymptoticInverse`InverseExpansionCoefficient[s,{1},"Power"->2];
  {c["Exponent"],c["Coefficient"]}],
 {3,-2}, TestID->"A03-explicit-observable-power-wins-policy"]
VerificationTest[
 Module[{x,s,t,p,r},
  s=AsymptoticInverse`AsymptoticExpansion[Exp[x],{x,0,2}];
  t=AsymptoticInverse`AsymptoticExpansion[x^-100,{x,0,1}];
  p=AsymptoticInverse`SeriesMultiply[s,t];
  r=TimeConstrained[AsymptoticInverse`SeriesRefine[p,5],30,Failure["TimeBudget",<||>]];
  (* A success must meet the request. An explicit inability is also safe. *)
  FailureQ[r] || (MatchQ[r,_AsymptoticInverse`GeneralizedSeries] &&
    TrueQ[r["RemainderPower"]>=5])],
 True, TestID->"A04-refinement-meets-target-or-reports-failure"]
