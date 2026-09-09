(* Load the ORIGINAL package before TestReport[this file].
   These express desired behavior and intentionally fail at the audited snapshot.
   The coarsening test is a proposed API policy, not an algebraic correctness test.
   This complete .wlt file has not been executed as a TestReport in this audit. *)
VerificationTest[
 Module[{s, t}, s = AsymptoticInverse`AsymptoticExpansion[x Log[x]+x^2,{x,0,2}];
  t = AsymptoticInverse`SeriesExp[s,3]; t["RemainderLogDegree"] >= 2],
 True, TestID -> "C04-exp-input-frontier-log-degree"]
VerificationTest[
 Module[{s, t}, s = AsymptoticInverse`AsymptoticExpansion[1+x Log[x]+x^2,{x,0,2}];
  t = AsymptoticInverse`SeriesLog[s,3]; t["RemainderLogDegree"] >= 2],
 True, TestID -> "C04-log-input-frontier-log-degree"]
VerificationTest[
 Module[{s, t}, s = AsymptoticInverse`AsymptoticExpansion[1+x Log[x]+x^2,{x,0,2}];
  t = AsymptoticInverse`SeriesPower[s,1/2,3]; t["RemainderLogDegree"] >= 2],
 True, TestID -> "C04-sqrt-input-frontier-log-degree"]
VerificationTest[
 FailureQ[AsymptoticInverse`AsymptoticExpansion[ArcSin[2]+x,{x,0,2}]],
 True, TestID -> "C07-reject-proven-nonreal-forward-constant"]
VerificationTest[
 Module[{s}, s=AsymptoticInverse`AsymptoticExpansion[x,{x,0,3}];
  FailureQ[AsymptoticInverse`SeriesObservable[s,z+ArcSin[2],z]]],
 True, TestID -> "C07-reject-proven-nonreal-observable-constant"]
VerificationTest[
 Module[{s,r},s=AsymptoticInverse`AsymptoticInverse[x^2,{x,Infinity},{y,1}];
  r=AsymptoticInverse`InverseCertificate[s,2,"Interval"->{1,2},
    "RelativeError"->10^-120,"MaxRefinements"->3,"RefineExpansion"->False];
  AssociationQ[r] && TrueQ[r["AccuracyGoalReached"]]],
 True, TestID -> "N01-relative-goal-adapts-precision"]
VerificationTest[
 Module[{s,t},s=AsymptoticInverse`AsymptoticExpansion[Sin[x],{x,0,7}];
  t=AsymptoticInverse`SeriesRefine[s,3];
  FailureQ[t] || (t["RemainderPower"]>=s["RemainderPower"] && Normal[t]===Normal[s])],
 True, TestID -> "N02-proposed-policy-refine-does-not-coarsen"]
