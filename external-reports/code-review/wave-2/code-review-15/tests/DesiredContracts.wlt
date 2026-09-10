(* Desired upstream behavior; NOT claimed passing on the audited baseline.
   Run via code/RunNativeTests.wls with ASYMPTOTIC_AUDIT_SUITE=Desired. *)
VerificationTest[Module[{x,y,s},s=AsymptoticFlatInverse[1/x+Exp[-1/x],{x,0},{y,1}];
  Lookup[auditApproach[s],"Point"]],Infinity,TestID->"F01-flat-pole-target-is-infinite"]
VerificationTest[Module[{x,y,s},s=FlatSeriesTruncate[AsymptoticFlatInverse[1/x+Exp[-1/x],{x,0},{y,1}],3];
  Lookup[auditApproach[s],"Point"]],Infinity,TestID->"F01-flat-derived-target-is-infinite"]
VerificationTest[Module[{x,y,s},s=AsymptoticSpecialInverse["Erfc",{x,-Infinity},{y,2}];
  Lookup[auditApproach[s],"Direction"]],"FromBelow",TestID->"F01-negative-Erfc-target-side"]
VerificationTest[Module[{x,y,s},s=AsymptoticSpecialInverse["QuadraticThreshold",{x,0},{y,2},"QuadraticCoefficient"->-1];
  Lookup[auditApproach[s],"Direction"]],"FromBelow",TestID->"F01-quadratic-actual-curvature-sign"]
VerificationTest[Module[{x,y,s,c},s=AsymptoticInverse[x^2,{x,0},{y,2}];
  c=InverseCertificate[s,2,"Interval"->{1,2},"TargetError"->10^-60,"EnclosureOrder"->2,
    "MaxRefinements"->64,"RefineExpansion"->False];
  AssociationQ[c]&&TrueQ[c["Certified"]&&c["AccuracyGoalReached"]&&c["CertifiedErrorBound"]<=10^-60]],
  True,TestID->"F02-auto-center-escalates-insufficient-arithmetic"]
VerificationTest[Module[{x,y,s},s=AsymptoticFlatInverse[x+Exp[-1/x],{x,0},{y,1}];
  auditTail[FlatSeriesMultiply[s,s]]],{{-1,0}},TestID->"F03-square-tail-keeps-exponential-grading"]
VerificationTest[Module[{x,y,s},s=AsymptoticFlatInverse[x+Exp[-1/x],{x,0},{y,3}];
  auditTail[FlatSeriesMultiply[s,s]]],{{-5,0}},TestID->"F03-deeper-square-tail"]
VerificationTest[Module[{x,y,s,t},s=AsymptoticInverse[Gamma[-x],{x,-Infinity},{y,2},"Power"->2];
  t=SeriesPower[s,1/2];MatchQ[t,_GeneralizedSeries]],True,
  TestID->"F04-feature-positive-observable-on-negative-source"]
