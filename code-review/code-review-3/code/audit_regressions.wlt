(* Desired contracts. Some tests intentionally FAIL on unmodified 1.8.0.
   The runner sets $AuditPatched and loads the package in a fresh kernel.
   The billion-denominator case is NEVER executed against the baseline. *)
Clear[x, y, z, a];

VerificationTest[
 Normal[AsymptoticInverse`AsymptoticInverse[x+x^2,{x,0},{y,5}]],
 y-y^2+2 y^3-5 y^4,
 TestID -> "control-quadratic-inverse"]

VerificationTest[
 Module[{s=AsymptoticInverse`AsymptoticInverse[x+x^Sqrt[2],{x,0},y,SeriesTermGoal->4]},
  TrueQ[FullSimplify[Normal[s] == y-y^Sqrt[2]+Sqrt[2] y^(2 Sqrt[2]-1)+(-3+1/Sqrt[2]) y^(3 Sqrt[2]-2), y>0]] &&
  TrueQ[AsymptoticInverse`InverseResidual[s]["ZeroBelowCutoff"]]],
 True, TestID -> "control-irrational-inverse-and-residual"]

VerificationTest[
 FailureQ[AsymptoticInverse`SeriesPower[
  AsymptoticInverse`AsymptoticExpansion[-x^2,{x,0,1}],1/2]],
 True, TestID -> "control-direct-unknown-sign-power-rejected"]

VerificationTest[
 FailureQ[AsymptoticInverse`SeriesObservable[
  AsymptoticInverse`AsymptoticExpansion[-x^2,{x,0,1}],1+Sqrt[z],z]],
 True, TestID -> "F01-nested-unknown-sign-power-rejected"]

VerificationTest[
 FailureQ[AsymptoticInverse`AsymptoticExpansion[Sqrt[Sin[x]-x],{x,0,1}]],
 True, TestID -> "F01-nonreal-forward-source-rejected"]

VerificationTest[
 FailureQ[AsymptoticInverse`SeriesObservable[
  AsymptoticInverse`AsymptoticExpansion[-x^2,{x,0,1}],
  ConditionalExpression[1+Sqrt[z],Element[Sqrt[z],Reals]],z]],
 True, TestID -> "F01-impossible-real-condition-rejected"]

VerificationTest[
 Module[{s=AsymptoticInverse`AsymptoticExpansion[x+x^2 Log[x],{x,0,2}]},
  s["RemainderLogDegree"]===1 && MissingQ[s["SeriesData"]]],
 True, TestID -> "F03-native-export-does-not-forget-log-tail"]

VerificationTest[
 Module[{s=Assuming[a>0,AsymptoticInverse`AsymptoticInverse[a x+x^2,{x,0},{y,3}]]},
  TrueQ[FullSimplify[Implies[s["Assumptions"],a>0]]]],
 True, TestID -> "F04-ambient-assumptions-retained"]

VerificationTest[
 Module[{s=AsymptoticInverse`AsymptoticExpansion[x^(1/101)+x,{x,0,1},"MaxTerms"->32]},
  {Normal[s],s["ReturnedTermCount"],Length[s["SeriesData"][[3]]]}],
 {x^(1/101),1,1}, TestID -> "control-native-series-trims-trailing-zeros"]

VerificationTest[
 Normal[AsymptoticInverse`AsymptoticInverse[x,{x,1},{y,3},"Power"->2]],
 (y-1)^2, TestID -> "control-documented-translated-power-semantics"]

VerificationTest[
 Module[{s=AsymptoticInverse`AsymptoticInverse[x+x^2,{x,0},{y,4}],c},
  c=AsymptoticInverse`InverseCertificate[s,1/100,"Interval"->{1/1000,1/10}];
  AssociationQ[c] && TrueQ[c["Certified"]] && c["CertifiesInputRemainderFamily"]===False],
 True, TestID -> "control-exact-rational-root-certificate"]

VerificationTest[
 Module[{s=AsymptoticInverse`AsymptoticInverse[x+x^2,{x,0},{y,3}],r},
  r=AsymptoticInverse`SeriesRefine[s,5];
  Normal[r]===y-y^2+2 y^3-5 y^4],
 True, TestID -> "control-refinement"]

If[TrueQ[$AuditPatched],
 VerificationTest[
  Module[{s=AsymptoticInverse`AsymptoticExpansion[x^(1/1000000007)+x,{x,0,1},"MaxTerms"->32]},
   {Normal[s],MissingQ[s["SeriesData"]]}],
  {x^(1/1000000007),True}, TestID -> "F02-large-denominator-guard-PATCHED-ONLY"],
 Nothing]
