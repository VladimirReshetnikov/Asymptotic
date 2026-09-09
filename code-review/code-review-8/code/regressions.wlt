(* Desired contract tests. Load the reviewed or patched package before TestReport.
   These are NOT claimed to pass on 1.8.0. Ambient-assumption isolation is not
   repaired by harden_source.py; its desired-contract tests should still fail.
   All package symbol names are explicit to avoid parse-time context capture. *)
VerificationTest[
  Module[{s}, s = Assuming[a > 0,
    AsymptoticInverse`AsymptoticExpansion[Sqrt[a^2]+x,{x,0,2}]];
    If[FailureQ[s], False,
      TrueQ[FullSimplify[s["Assumptions"] \[Implies] a > 0]] ||
      TrueQ[FullSimplify[Normal[s] == Sqrt[a^2]+x, Element[a,Reals]]]]],
  True, TestID -> "audit-assumptions-not-lost"]
VerificationTest[
  Module[{s = AsymptoticInverse`AsymptoticExpansion[-x^4,{x,0,1}]},
    FailureQ[AsymptoticInverse`SeriesObservable[s,1+Sqrt[z],z]]],
  True, TestID -> "audit-wrapped-uncertain-root-refused"]
VerificationTest[
  Module[{s = AsymptoticInverse`AsymptoticExpansion[-x^4,{x,0,1}]},
    FailureQ[AsymptoticInverse`SeriesPower[s,1/2]]],
  True, TestID -> "audit-direct-uncertain-root-refused"]
VerificationTest[
  MatchQ[TimeConstrained[
    AsymptoticInverse`AsymptoticExpansion[Exp[x^(1/50)],{x,0,1},"MaxTerms"->10],
    12,$Aborted], Failure["ResourceLimit", _Association]],
  True, TestID -> "audit-unit-series-budget"]
VerificationTest[
  Module[{s = MemoryConstrained[TimeConstrained[
    AsymptoticInverse`AsymptoticExpansion[x+x^(1+1/1000000)+x^2,
      {x,0,3/2},"MaxTerms"->10],12,$Aborted],134217728,$Aborted]},
    MatchQ[s,_AsymptoticInverse`GeneralizedSeries] &&
    MatchQ[s["SeriesData"],Missing["DenseRepresentationLimit",_Association]]],
  True, TestID -> "audit-optional-dense-cache-is-bounded"]
VerificationTest[
  Normal[AsymptoticInverse`AsymptoticExpansion[1+x+x^2,{x,0,2}]],
  1+x, TestID -> "audit-cutoff-exclusive"]
VerificationTest[
  Normal[AsymptoticInverse`AsymptoticInverse[x+x^2,{x,0},{y,6}]],
  y-y^2+2 y^3-5 y^4+14 y^5, TestID -> "audit-polynomial-inverse-control"]
VerificationTest[
  FullSimplify[Normal[AsymptoticInverse`AsymptoticInverse[x+x^Sqrt[2],
    {x,0},y,SeriesTermGoal->3]] - (y-y^Sqrt[2]+Sqrt[2] y^(2 Sqrt[2]-1)),y>0],
  0, TestID -> "audit-irrational-inverse-control"]
