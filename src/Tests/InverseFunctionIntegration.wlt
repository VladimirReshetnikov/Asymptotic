If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[Module[{t,y,s,ell},
 s=Quiet[AsymptoticExpansion[InverseFunction[Function[t,t Exp[t]]][y],{y,Infinity,3}],InverseFunction::ifun];
 ell=Log[y];
 {TrueQ[FullSimplify[Normal[s]==ell-Log[ell]+Log[ell]/ell,y>1]],s["Scale"],
  s["InverseFunctionSyntax"]["NativeRealBranch"]}],
 {True,"Logarithmic",0},TestID->"inverse-integration-native-lambert-infinity-preserves-real-branch"]

VerificationTest[Module[{y,s,ell},
 s=AsymptoticExpansion[ProductLog[-1,y],{y,0,3},Direction->"FromBelow"];ell=Log[-y];
 {TrueQ[FullSimplify[Normal[s]==ell-Log[-ell]+Log[-ell]/ell+
    (Log[-ell]^2/2-Log[-ell])/ell^2,-1/E<y<0]],s["InverseFunctionSyntax"]["NativeRealBranch"]}],
 {True,-1},TestID->"inverse-integration-native-lambert-lower-real-branch"]

VerificationTest[Module[{y,s},s=AsymptoticExpansion[ProductLog[y],{y,0,4}];
 {Expand[Normal[s]]/.y->\[FormalY],s["RemainderPower"]}],
 {\[FormalY]-\[FormalY]^2+3\[FormalY]^3/2,4},TestID->"inverse-integration-native-lambert-regular-zero-branch"]

VerificationTest[Module[{a,t,y,s},s=AsymptoticExpansion[
 InverseFunction[Function[t,a+t+t^2(1+Log[t])]][a+y],{y,0,4},Assumptions->Element[a,Reals]];
 TrueQ[FullSimplify[Normal[s]==y-y^2(1+Log[y])+y^3(2Log[y]^2+5Log[y]+3),y>0]]],
 True,TestID->"inverse-integration-symbolic-real-target-offset"]

VerificationTest[Module[{t,y,s,c=Root[#^3-2&,1]},
 s=AsymptoticExpansion[InverseFunction[Function[t,c(t+t^2(1+Log[t]))]][y],{y,0,3}];
 TrueQ[FullSimplify[Normal[s]==y/c-(y/c)^2(1+Log[y/c]),y>0]]],
 True,TestID->"inverse-integration-algebraic-coefficient-retains-internal-lexical-slots"]

VerificationTest[Module[{y,z,s},s=SeriesObservable[AsymptoticExpansion[Sin[y],{y,0,4}],
 ConditionalExpression[InverseFunction[#+#^2(1+Log[#])&][z],z>0],z,"Cutoff"->4];
 TrueQ[FullSimplify[Normal[s]==y-y^2(1+Log[y])+y^3(2Log[y]^2+5Log[y]+17/6),y>0]]],
 True,TestID->"inverse-integration-conditional-observable-checks-input-germ"]

VerificationTest[Module[{y,z,s},s=AsymptoticExpansion[Sin[y],{y,0,3}];
 FailureQ[SeriesObservable[s,ConditionalExpression[z,z==y],z,"Cutoff"->4]]],
 True,TestID->"inverse-integration-unknown-input-remainder-cannot-prove-equality"]

VerificationTest[Module[{y,m},m=PowerLogModel[InverseFunction[Sqrt][y],{y,0}];
 {m["LeadingPower"],m["LeadingCoefficient"],m["Gaps"]}],
 {2,1,{}},TestID->"inverse-integration-native-finite-inverse-model"]

VerificationTest[Module[{x,y,s},s=AsymptoticInverse[
 InverseFunction[ConditionalExpression[#+#^2(1+Log[#]),#>0]&][x],{x,0},{y,4}];
 {TrueQ[FullSimplify[Normal[s]==y+y^2(1+Log[y]),y>0]],s["RemainderPower"]>=4}],
 {True,True},TestID->"inverse-integration-invert-an-unevaluated-inverse-expression"]

VerificationTest[Module[{y,rules,s},rules={Assumptions->y>0,"MaxTerms"->1000};
 s=AsymptoticExpansion[InverseFunction[#+#^2(1+Log[#])&][y],{y,0,3},Sequence@@rules];
 {TrueQ[FullSimplify[Normal[s]==y-y^2(1+Log[y]),y>0]],s["Assumptions"]}],
 {True,True},TestID->"inverse-integration-held-public-boundary-evaluates-option-sequences"]

VerificationTest[Module[{y,z,s},s=AsymptoticExpansion[Sin[y],{y,0,3}];
 FailureQ[SeriesObservable[s,ConditionalExpression[z,Unequal[z,0,y]],z,"Cutoff"->4]]],
 True,TestID->"inverse-integration-unequal-condition-requires-all-pairs-despite-unknown-remainder"]

VerificationTest[Module[{y,z,s},s=SeriesObservable[AsymptoticExpansion[y,{y,0,2}],
 ConditionalExpression[z,Unequal[z,0,1]],z,"Cutoff"->2];
 {Normal[s]/.y->\[FormalY],s["Remainder"]}],
 {\[FormalY],0},TestID->"inverse-integration-proves-distinct-observable-values-on-deleted-neighborhood"]
