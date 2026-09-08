(* Retained branch-condition fixtures. Each fixture starts with a real
   expansion produced by a public constructor, then attaches the source
   restriction that an InverseFunction/ConditionalExpression adapter must
   retain. The independent roots and certificate intervals are exact. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
 Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[Module[{x,y,s,n},
 s=AsymptoticInverse[x+x^2,{x,0},{y,5}];
 s=PowerLogSeries[Join[s[[1]],<|"SourceDomain"->(1/10<x<3/10)|>]];
 n=InverseNumericalCheck[s,6/25,WorkingPrecision->50];
 {n["SourceDomainVerified"],Abs[n["ReferenceRoot"]-1/5]<10^-45}],
 {True,True},TestID->"inverse-domain-numerical-root-satisfies-retained-restriction"]

VerificationTest[Module[{x,y,s},
 s=AsymptoticInverse[x+x^2,{x,0},{y,5}];
 s=PowerLogSeries[Join[s[[1]],<|"SourceDomain"->(0<x<1/10)|>]];
 MatchQ[InverseNumericalCheck[s,6/25],Failure["OutsideBranch",_Association]]],
 True,TestID->"inverse-domain-numerical-root-on-correct-side-but-outside-condition"]

VerificationTest[Module[{x,y,q,s,n},
 s=AsymptoticInverse[x+x^2,{x,0},{y,5}];
 s=PowerLogSeries[Join[s[[1]],<|"SourceVariable"->q,
   "SourceDomain"->(Im[q]==0&&Element[q,Reals]&&1/10<q<3/10)|>]];
 n=InverseNumericalCheck[s,6/25];
 {n["SourceDomainVerified"],FreeQ[n["SourceDomainChecked"],q]}],
 {True,True},TestID->"inverse-domain-explicit-source-symbol-is-normalized"]

VerificationTest[Module[{x,y,s,n},
 s=AsymptoticInverse[x+x^2,{x,0},{y,5},"Power"->2];
 s=PowerLogSeries[Join[s[[1]],<|"SourceDomain"->(x>1/10)|>]];
 n=InverseNumericalCheck[s,6/25];
 {n["SourceDomainVerified"],Abs[n["ReferenceRoot"]-1/5]<10^-45,
  Abs[n["ReferenceObservable"]-1/25]<10^-45}],
 {True,True,True},TestID->"inverse-domain-checks-source-root-not-powered-observable"]

VerificationTest[Module[{x,y,s,n},
 s=AsymptoticInverse[-x+x^2,{x,0},{y,5},Direction->"FromBelow"];
 s=PowerLogSeries[Join[s[[1]],<|"SourceDomain"->(-1/4<x<0)|>]];
 n=InverseNumericalCheck[s,6/25];
 {n["SourceDomainVerified"],Abs[n["ReferenceRoot"]+1/5]<10^-45}],
 {True,True},TestID->"inverse-domain-left-branch-retains-signed-source-predicate"]

VerificationTest[Module[{x,y,s,n,root=Exp[-10]},
 s=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,3}];
 n=InverseNumericalCheck[s,9 Exp[-10]/10];
 {n["SourceDomainVerified"],FreeQ[n["SourceDomainChecked"],s["LocalVariable"]],
  Abs[n["ReferenceRoot"]/root-1]<10^-45}],
 {True,True,True},TestID->"inverse-domain-legacy-logarithmic-local-coordinate-normalized"]

VerificationTest[Module[{x,y,s,predicate},
 s=AsymptoticInverse[x+x^2,{x,0},{y,5}];
 s=PowerLogSeries[Join[s[[1]],<|"SourceDomain"->predicate[x]|>]];
 MatchQ[InverseNumericalCheck[s,6/25],Failure["OutsideBranch",_Association]]],
 True,TestID->"inverse-domain-unknown-numerical-predicate-fails-closed"]

VerificationTest[Module[{x,y,q,s,c},
 s=AsymptoticInverse[x+x^2,{x,0},{y,5}];
 s=PowerLogSeries[Join[s[[1]],<|"SourceVariable"->q,
   "SourceDomain"->(Element[q,Reals]&&Im[q]==0&&1/10<=q<=3/10)|>]];
 c=InverseCertificate[s,6/25,"Interval"->{1/10,3/10},"Center"->1/5,
   "TargetError"->10^-20,"MaxRefinements"->0];
 {c["Certified"],c["SourceDomainVerified"],
  c["RootEnclosure"][[1]]<=1/5<=c["RootEnclosure"][[2]],
  c["RootEnclosure"][[2]]-c["RootEnclosure"][[1]]<=2 c["CertifiedErrorBound"],
  c["CertifiedErrorBound"]<=10^-20,
  FreeQ[c["CertifiedSourceDomain"],q]}],
 {True,True,True,True,True,True},TestID->"inverse-domain-certificate-proves-closed-nonstrict-condition"]

VerificationTest[Module[{x,y,s,c},
 s=AsymptoticInverse[x+x^2,{x,0},{y,5}];
 s=PowerLogSeries[Join[s[[1]],<|"SourceDomain"->(0<x<1/4)|>]];
 c=InverseCertificate[s,6/25,"Interval"->{1/10,3/10},"Center"->1/5,"MaxRefinements"->0];
 {MatchQ[c,Failure["OutsideBranch",_Association]],c[[2,"ConditionScope"]]}],
 {True,"EntireClosedVerificationInterval"},TestID->"inverse-domain-valid-root-does-not-excuse-invalid-interval"]

VerificationTest[Module[{x,y,s},
 s=AsymptoticInverse[x+x^2,{x,0},{y,5}];
 s=PowerLogSeries[Join[s[[1]],<|"SourceDomain"->(1/10<x<1)|>]];
 MatchQ[InverseCertificate[s,6/25,"Interval"->{1/10,3/10},"Center"->1/5,
   "MaxRefinements"->0],Failure["OutsideBranch",_Association]]],
 True,TestID->"inverse-domain-open-condition-excludes-closed-interval-endpoint"]

VerificationTest[Module[{x,y,s,c},
 s=AsymptoticInverse[x+x^2,{x,0},{y,5}];
 s=PowerLogSeries[Join[s[[1]],<|"SourceDomain"->((x<0||x>1/20)&&x!=1&&Not[x>=1])|>]];
 c=InverseCertificate[s,6/25,"Interval"->{1/10,3/10},"Center"->1/5,"MaxRefinements"->0];
 {c["Certified"],c["SourceDomainVerified"]}],
 {True,True},TestID->"inverse-domain-boolean-and-nonequality-interval-proof"]

VerificationTest[Module[{x,y,s,predicate},
 s=AsymptoticInverse[x+x^2,{x,0},{y,5}];
 s=PowerLogSeries[Join[s[[1]],<|"SourceDomain"->predicate[x]|>]];
 MatchQ[InverseCertificate[s,6/25,"Interval"->{1/10,3/10},"Center"->1/5,
   "MaxRefinements"->0],Failure["OutsideBranch",_Association]]],
 True,TestID->"inverse-domain-unknown-certificate-predicate-fails-closed"]

VerificationTest[Module[{x,y,s},
 s=AsymptoticInverse[x Exp[x],{x,Infinity},{y,3}];
 s=PowerLogSeries[Join[s[[1]],<|"SourceDomain"->(x<5/2)|>]];
 MatchQ[InverseCertificate[s,2 Exp[2],"Interval"->{1,3},"Center"->2,
   "MaxRefinements"->0],Failure["OutsideBranch",_Association]]],
 True,TestID->"inverse-domain-lambert-phase-conversion-preserves-original-condition"]

VerificationTest[Module[{x,y,s,c},
 s=AsymptoticInverse[Exp[x^2+x],{x,Infinity},{y,3}];
 s=PowerLogSeries[Join[s[[1]],<|"SourceDomain"->(1/2<x<4)|>]];
 c=InverseCertificate[s,Exp[6],"Interval"->{1,3},"Center"->2,"MaxRefinements"->0];
 {c["Certified"],c["SourceDomainVerified"],c["RootEnclosure"]}],
 {True,True,{2,2}},TestID->"inverse-domain-target-log-route-retains-certified-condition"]

VerificationTest[Module[{x,y,s,c},
 s=AsymptoticInverse[x+x^2,{x,0},{y,5}];
 c=InverseCertificate[s,6/25,"Interval"->{1/10,3/10},"Center"->1/5,"MaxRefinements"->0];
 {c["Certified"],c["CertifiedSourceDomain"],c["SourceDomainVerified"]}],
 {True,True,True},TestID->"inverse-domain-legacy-object-without-condition-is-unchanged"]

VerificationTest[Module[{y,s,target,n,c,residual},
 (* Exercise actual inverse syntax and retained branch provenance through
    all public evidence operations. The exact source root is 1/5. *)
 s=AsymptoticExpansion[InverseFunction[
   ConditionalExpression[#+#^2(1+Log[#]),0<#<1]&][y],{y,0,4}];
 target=1/5+(1+Log[1/5])/25;
 residual=InverseResidual[s];
 n=InverseNumericalCheck[s,target,WorkingPrecision->50];
 c=InverseCertificate[s,target,"Interval"->{1/10,3/10},"Center"->1/5,
   "TargetError"->10^-20,"MaxRefinements"->0];
 {s["Kind"]==="Inverse",residual["ZeroBelowCutoff"],
  n["SourceDomainVerified"],Abs[n["ReferenceRoot"]-1/5]<10^-45,
  c["Certified"],c["SourceDomainVerified"],
  c["RootEnclosure"][[1]]<=1/5<=c["RootEnclosure"][[2]],
  c["CertifiedErrorBound"]<=10^-20}],
 {True,True,True,True,True,True,True,True},
 TestID->"inverse-domain-actual-conditional-inverse-preserves-all-evidence-routes"]
