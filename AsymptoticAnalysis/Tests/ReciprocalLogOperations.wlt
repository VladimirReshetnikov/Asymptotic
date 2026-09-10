If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];
If[DownValues[AsymptoticAnalysis`ReciprocalLogCompose] === {},
  Begin["AsymptoticAnalysis`Private`"];
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "ReciprocalLogOperations.wl"}]];
  End[]];

VerificationTest[
 Module[{x,z,y,t,a,b,s,w,expected,actual},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{z,5}];
  b=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,5}];
  s=ReciprocalLogCompose[a,b]; w=1+t+t^2+2t^3+7t^4/2;
  expected=Normal[Series[w (w/.t->t/(1-t Log[w])),{t,0,4}]];
  actual=Expand[Normal[s]/y]/.Log[y]->-1/t;
  {TrueQ[Expand[actual-expected]===0],s["RemainderPower"],s["RemainderDerivativeOrder"]}],
 {True,5,Infinity},TestID->"reciprocal-compose-zero-independent-native-series"]

VerificationTest[
 Module[{x,z,y,t,a,b,s,w,expected,actual},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,Infinity},{z,5}];
  b=AsymptoticLogarithmicInverse[x+x/Log[x],{x,Infinity},{y,5}];
  s=ReciprocalLogCompose[a,b]; w=1-t+t^2-2t^3+7t^4/2;
  expected=Normal[Series[w (w/.t->t/(1+t Log[w])),{t,0,4}]];
  actual=Expand[Normal[s]/y]/.Log[y]->1/t;
  {TrueQ[Expand[actual-expected]===0],s["RemainderPower"],
   s["ReciprocalLogRepresentation"][["EndpointSign"]]}],
 {True,5,1},TestID->"reciprocal-compose-infinity-independent-native-series"]

VerificationTest[
 Module[{x,z,y,t,a,b,s,aa,bb,coordinate,expected,actual},
  a=AsymptoticLogarithmicInverse[3x^2(1+2/Log[x]),{x,0},{z,5}];
  b=AsymptoticLogarithmicInverse[5x^3(1-1/Log[x]),{x,0},{y,5}];
  s=ReciprocalLogCompose[a,b];
  aa=Total[(#[[2]](2t/(1+Log[3]t))^#[[1]])&/@a["Blocks"]];
  bb=Normal[Series[Total[(#[[2]](3t/(1+Log[5]t))^#[[1]])&/@b["Blocks"]],{t,0,4}]];
  coordinate=t/(1/3-t(Log[5^(-1/3)]+Log[bb]));
  expected=Normal[Series[Sqrt[bb](aa/.t->coordinate),{t,0,4}]];
  actual=Total[(t^#[[1]]#[[2]])&/@s["ReciprocalLogRepresentation"][["Jet",1]]];
  {TrueQ[FullSimplify[actual==expected]],s["ReciprocalLogRepresentation"][["CarrierPower"]]}],
 {True,1/6},TestID->"reciprocal-compose-nonunit-powers-and-affine-log-scales"]

VerificationTest[
 Module[{x,z,y,a,b,s},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{z,3}];
  b=AsymptoticLogarithmicInverse[x+2x/Log[x],{x,0},{y,5}];
  s=ReciprocalLogCompose[a,b,"Cutoff"->8];
  {s["RemainderPower"],Max[s["Blocks"][[All,1]]]<3}],
 {3,True},TestID->"reciprocal-compose-outer-remainder-caps-requested-cutoff"]

VerificationTest[
 Module[{x,z,y,a,b,s},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{z,6}];
  b=AsymptoticLogarithmicInverse[x+2x/Log[x],{x,0},{y,3}];
  s=ReciprocalLogCompose[a,b,"Cutoff"->8];
  {s["RemainderPower"],Max[s["Blocks"][[All,1]]]<3}],
 {3,True},TestID->"reciprocal-compose-inner-remainder-caps-requested-cutoff"]

VerificationTest[
 Module[{x,y,t,s,d,expected,actual},
  s=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,5}];
  d=ReciprocalLogDifferentiate[s];
  expected=1+t+2t^2+4t^3+19t^4/2;
  actual=Expand[Normal[d]]/.Log[y]->-1/t;
  {TrueQ[Expand[actual-expected]===0],d["RemainderPower"],
   d["AnalyticRemainderContract"][["AllFixedDerivativeOrders"]]}],
 {True,5,True},TestID->"reciprocal-first-derivative-zero-known-coefficients"]

VerificationTest[
 Module[{x,y,t,s,d,expected,actual},
  s=AsymptoticLogarithmicInverse[x+x/Log[x],{x,Infinity},{y,5}];
  d=ReciprocalLogDifferentiate[s];
  expected=1-t+2t^2-4t^3+19t^4/2;
  actual=Expand[Normal[d]]/.Log[y]->1/t;
  {TrueQ[Expand[actual-expected]===0],d["RemainderPower"]}],
 {True,5},TestID->"reciprocal-first-derivative-infinity-chain-sign"]

VerificationTest[
 Module[{x,y,t,s,d,expected,actual},
  s=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,5}];
  d=ReciprocalLogDifferentiate[s,2,"Cutoff"->8];
  expected=Normal[Series[Expand[y D[Normal[s],{y,2}]]/.Log[y]->-1/t,{t,0,5}]];
  actual=Expand[y Normal[d]]/.Log[y]->-1/t;
  {TrueQ[Expand[actual-expected]===0],d["RemainderPower"],
   d["ReciprocalLogRepresentation"][["CarrierPower"]]}],
 {True,6,-1},TestID->"reciprocal-second-derivative-cancelled-carrier-improves-log-order"]

VerificationTest[
 Module[{x,y,t,s,d,expected,actual},
  s=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,5},"Power"->1/2];
  d=ReciprocalLogDifferentiate[s,2];
  expected=Normal[Series[FullSimplify[y^(3/2) D[Normal[s],{y,2}],y>0]/.Log[y]->-1/t,{t,0,4}]];
  actual=FullSimplify[y^(3/2) Normal[d],y>0]/.Log[y]->-1/t;
  {TrueQ[FullSimplify[actual==expected]],d["RemainderPower"]}],
 {True,5},TestID->"reciprocal-fractional-monomial-carrier-derivative-native-oracle"]

VerificationTest[
 Module[{x,y,s},s=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,4}];
  ReciprocalLogDifferentiate[s,0]===s],True,TestID->"reciprocal-zero-derivative-preserves-object"]

VerificationTest[
 Module[{x,z,y,a,b,s,d,xx,mid,target,reference,error,scale},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{z,5}];
  b=AsymptoticLogarithmicInverse[x+2x/Log[x],{x,0},{y,5}];
  s=ReciprocalLogCompose[a,b]; d=ReciprocalLogDifferentiate[s];
  xx=N[Exp[-100],90]; mid=xx+xx/Log[xx]; target=mid+2mid/Log[mid];
  reference=1/((1+1/Log[xx]-1/Log[xx]^2)(1+2/Log[mid]-2/Log[mid]^2));
  error=Abs[N[Normal[d]/.y->target,70]-reference];
  scale=N[d["RemainderScaleExpression"]/.y->target,70];
  {Abs[N[Normal[s]/.y->target,70]-xx]<1000 N[s["RemainderScaleExpression"]/.y->target,70],
   0<error<1000 scale}],
 {True,True},TestID->"reciprocal-composed-function-and-derivative-original-equation-oracle"]

VerificationTest[
 Module[{x,z,y,a,b,s,xx,mid,target},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,Infinity},{z,5}];
  b=AsymptoticLogarithmicInverse[x+2x/Log[x],{x,Infinity},{y,5}];
  s=ReciprocalLogCompose[a,b];xx=N[Exp[100],90];mid=xx+xx/Log[xx];target=mid+2mid/Log[mid];
  Abs[N[Normal[s]/.y->target,70]-xx]<1000 N[s["RemainderScaleExpression"]/.y->target,70]],
 True,TestID->"reciprocal-infinity-composition-original-equation-oracle"]

VerificationTest[
 Module[{x,z,y,a,b,s},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,Infinity},{z,4}];
  b=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,4},"Power"->-1];
  s=ReciprocalLogCompose[a,b];
  {s["ReciprocalLogRepresentation"][["CarrierPower"]],s["RemainderPower"],
   s["ReciprocalLogRepresentation"][["EndpointSign"]]}],
 {-1,4,-1},TestID->"reciprocal-negative-power-inner-switches-compatible-endpoints"]

VerificationTest[
 Module[{x,z,y,a,b},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,Infinity},{z,4}];
  b=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,4}];
  MatchQ[ReciprocalLogCompose[a,b],Failure["IncompatibleLimits",_]]],
 True,TestID->"reciprocal-composition-incompatible-endpoints-rejected"]

VerificationTest[
 Module[{x,z,y,a,b},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,Infinity},{z,4}];
  b=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,4},"Power"->-1];
  b=ReciprocalLogDifferentiate[b];
  MatchQ[ReciprocalLogCompose[a,b],Failure["UnsupportedReciprocalLogComposition",_]]],
 True,TestID->"reciprocal-composition-negative-inner-value-rejected"]

VerificationTest[
 Module[{x,z,y,a,b},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{z,4}];
  b=AsymptoticLogarithmicInverse[x+x/Log[x]+x^2,{x,0},{y,4}];
  {MatchQ[ReciprocalLogCompose[a,b],Failure["UnsupportedReciprocalLogComposition",_]],
   MatchQ[ReciprocalLogDifferentiate[b],Failure["UnsupportedReciprocalLogDerivative",_]]}],
 {True,True},TestID->"reciprocal-unresolved-higher-power-sectors-do-not-gain-analytic-contract"]

VerificationTest[
 Module[{x,z,y,a,b},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{z,4}];
  b=AsymptoticLogarithmicInverse[(x-2)+(x-2)/Log[x-2],{x,2},{y,4}];
  MatchQ[ReciprocalLogCompose[a,b],Failure["UnsupportedReciprocalLogComposition",_]]],
 True,TestID->"reciprocal-finite-source-translations-outside-bounded-calculus"]

VerificationTest[
 Module[{x,z,y,a,b},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{z,4}];
  b=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,4}];
  {MatchQ[ReciprocalLogCompose[a,b,"MaxTerms"->3],Failure["ResourceLimit",_]],
   MatchQ[ReciprocalLogDifferentiate[b,20001],Failure["ResourceLimit",_]],
   MatchQ[ReciprocalLogCompose[a,b,"Cutoff"->0],Failure["InvalidCutoff",_]]}],
 {True,True,True},TestID->"reciprocal-calculus-explicit-resource-and-cutoff-failures"]

VerificationTest[
 Module[{x,z,y,a,b,c,d},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{z,4}];
  b=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,4}];
  c=SeriesCompose[a,b];d=SeriesDifferentiate[c];
  {c["Scale"],d["Scale"],TrueQ[FullSimplify[Normal[c]==Normal[ReciprocalLogCompose[a,b]],0<y<Exp[-2]]]}],
 {"ReciprocalLogCalculus","ReciprocalLogCalculus",True},TestID->"reciprocal-common-public-composition-and-derivative-hooks"]

VerificationTest[
 Module[{x,z,y,a,b,s,r,fresh},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{z,3}];
  b=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,3}];
  s=SeriesDifferentiate[SeriesCompose[a,b]];r=SeriesRefine[s,6];
  fresh=SeriesDifferentiate[SeriesCompose[AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{z,8}],
    AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,8}]],"Cutoff"->6];
  {TrueQ[FullSimplify[Normal[r]==Normal[fresh],0<y<Exp[-2]]],r["RemainderPower"]>=6}],
 {True,True},TestID->"reciprocal-derived-refinement-replays-exact-original-sources"]

VerificationTest[
 Module[{x,z,y,t,a,b,c,d,cp,dp},
  a=AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{z,6}];
  b=AsymptoticLogarithmicInverse[x+2x/Log[x],{x,0},{y,6}];
  c=ReciprocalLogCompose[a,b];d=ReciprocalLogDifferentiate[c];
  cp=Total[(t^#[[1]]#[[2]])&/@c["ReciprocalLogRepresentation"][["Jet",1]]];
  dp=Total[(t^#[[1]]#[[2]])&/@d["ReciprocalLogRepresentation"][["Jet",1]]];
  {Expand[cp-(1+3t+7t^2+22t^3+139t^4/2+703t^5/3)]===0,
   Expand[dp-(1+3t+10t^2+36t^3+271t^4/2+1537t^5/3)]===0}],
 {True,True},TestID->"reciprocal-unequal-units-independent-composition-and-derivative-coefficients"]

(* Synthetic interface fixtures below supply the exact analytic Taylor unit
   A(tau)=1+tau. They test serialization/rechart contracts, not recognition
   of a terminating inverse family by AsymptoticLogarithmicInverse. *)
VerificationTest[
 Module[{x,y,t,s,d,actual},
  s=GeneralizedSeries[<|"Kind"->"LogarithmicInverse","Scale"->"ReciprocalLogUnit",
    "ExactModel"->True,"LeadingCoreOnly"->False,"ExpansionPoint"->0,"Limit"->0,
    "Offset"->0,"Variable"->y,"Variables"->{x,y},"Assumptions"->True,
    "LeadingPower"->1,"Power"->1,"LeadingCoefficient"->1,
    "LeadingLocalApproximation"->y,"Direction"->"FromAbove",
    "Blocks"->{{0,1},{1,1}},"Expression"->y(1-1/Log[y]),
    "Remainder"->0,"RemainderPower"->Infinity,"Cutoff"->7/2,
    "TargetDomain"->(0<y<Exp[-2]),"SyntheticInterfaceFixture"->True,
    "ExactTerminationCertificate"-><|"Verified"->True,
      "Verification"->"Synthetic interface contract: the coefficient unit A(tau)=1+tau is exact; no constructor inverse-termination claim."|>|>];
  d=ReciprocalLogDifferentiate[s];actual=Expand[Normal[d]]/.Log[y]->-1/t;
  {Expand[actual-(1+t+t^2)]===0,d["RemainderPower"],d["Remainder"]=!=0,
   d["ReciprocalLogRepresentation"][["RechartPrecisionSource"]]}],
 {True,4,True,"ConservativeTaylorTruncationOfExactUnit"},
 TestID->"reciprocal-synthetic-exact-unit-interface-keeps-conservative-rechart-tail"]

VerificationTest[
 Module[{x,y,t,s,d,actual,expected},
  s=GeneralizedSeries[<|"Kind"->"LogarithmicInverse","Scale"->"ReciprocalLogUnit",
    "ExactModel"->True,"LeadingCoreOnly"->False,"ExpansionPoint"->0,"Limit"->0,
    "Offset"->0,"Variable"->y,"Variables"->{x,y},"Assumptions"->True,
    "LeadingPower"->1,"Power"->1,"LeadingCoefficient"->E,
    "LeadingLocalApproximation"->y/E,"Direction"->"FromAbove",
    "Blocks"->{{0,1},{1,1}},"Expression"->(y/E)(1-1/Log[y/E]),
    "Remainder"->0,"RemainderPower"->Infinity,"Cutoff"->7/2,
    "TargetDomain"->(0<y<Exp[-2]),"SyntheticInterfaceFixture"->True,
    "ExactTerminationCertificate"-><|"Verified"->True,
      "Verification"->"Synthetic interface contract: the coefficient unit A(tau)=1+tau is exact; no constructor inverse-termination claim."|>|>];
  d=ReciprocalLogDifferentiate[s];actual=Expand[E Normal[d]]/.Log[y]->-1/t;
  expected=Normal[Series[1+t/(1+t)+t^2/(1+t)^2,{t,0,3}]];
  {Expand[actual-expected]===0,d["RemainderPower"],d["Remainder"]=!=0,
   d["ReciprocalLogRepresentation"][["RechartPrecisionSource"]]}],
 {True,4,True,"ConservativeTaylorTruncationOfExactUnit"},
 TestID->"reciprocal-synthetic-exact-scaled-unit-interface-affine-log-tail"]
