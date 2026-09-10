If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
 Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[Module[{x,y,s},s=AsymptoticInverse[x+x/Log[x],{x,0},{y,4}];
 {s["Kind"],s["Scale"],InverseResidual[s]["ZeroBelowCutoff"]}],
 {"LogarithmicInverse","ReciprocalLogUnit",True},TestID->"integration-automatic-reciprocal-log-dispatch"]

VerificationTest[Module[{x,y,s},s=AsymptoticInverse[x+x^2 Sqrt[-Log[x]],{x,0},{y,4}];
 {s["Scale"],FullSimplify[Normal[s]==y-y^2 Sqrt[-Log[y]]+y^3(-2 Log[y]-1/2),0<y<Exp[-2]]}],
 {"GeneralizedLogarithmicCoefficients",True},TestID->"integration-automatic-generalized-log-dispatch"]

VerificationTest[Module[{x,y,s},s=AsymptoticInverse[x+x^2 Log[x],{x,0},{y,4},Method->"Newton"];
 {s["Kind"],s["Method"],InverseResidual[s]["ZeroBelowCutoff"]}],
 {"Inverse","Newton",True},TestID->"integration-ordinary-log-method-remains-available"]

VerificationTest[Module[{x,y,s},s=AsymptoticFourierInverse[x+x^2 Sin[Log[x]],{x,0},{y,4}];
 InverseResidual[s]["ZeroBelowCutoff"]],True,TestID->"integration-common-fourier-residual"]

VerificationTest[Module[{x,y,s},s=AsymptoticInverse[x+x^2 Sqrt[-Log[x]],{x,0},{y,4}];
 MatchQ[InverseResidual[s],Failure["UnsupportedResidual",_Association]]],True,
 TestID->"integration-generalized-residual-keeps-honest-scope"]

VerificationTest[Module[{x,y,s,c,oracle},s=AsymptoticInverse[x+x^2,{x,0},{y,5},"Power"->2];
 c=InverseNumericalCheck[s,1/100,WorkingPrecision->60];oracle=(Sqrt[1+4/100]-1)/2;
 {Abs[c["ReferenceRoot"]-N[oracle,60]]<10^-58,Abs[c["ReferenceObservable"]-N[oracle^2,60]]<10^-58,c["Error"]<10^-8}],
 {True,True,True},TestID->"integration-numerical-square-observable-independent-radical"]

VerificationTest[Module[{x,y,s,c},s=AsymptoticInverse[(2-x)+(2-x)^2,{x,2},{y,5},Direction->"FromBelow","Power"->-1];
 c=InverseNumericalCheck[s,1/100,WorkingPrecision->50];
 {c["ReferenceRoot"]<2,c["ReferenceObservable"]<0,Abs[c["ReferenceObservable"]-1/(c["ReferenceRoot"]-2)]<10^-44}],
 {True,True,True},TestID->"integration-numerical-negative-power-left-finite-distance"]

VerificationTest[Module[{x,y,s,c},s=AsymptoticInverse[x+1/x,{x,-Infinity},{y,4},"Power"->2];
 c=InverseNumericalCheck[s,-100,WorkingPrecision->50];
 {c["ReferenceRoot"]<0,Abs[c["ReferenceObservable"]-c["ReferenceRoot"]^2]<10^-44}],
 {True,True},TestID->"integration-numerical-even-power-negative-infinity"]

VerificationTest[Module[{x,y,s,c},s=AsymptoticInverse[x+x^2,{x,0},{y,3},"Power"->1/2];
 c=InverseNumericalCheck[s,1/100,WorkingPrecision->50];
 Abs[c["ReferenceObservable"]^2-c["ReferenceRoot"]]<10^-48],True,
 TestID->"integration-numerical-fractional-observable-positive-source"]

VerificationTest[Module[{x,y,s,c},s=AsymptoticInverse[x Log[x],{x,0},{y,4},"Power"->2];
 c=InverseNumericalCheck[s,-1/10000,WorkingPrecision->60];
 {c["ReferenceRoot"]>0,c["ReferenceRoot"]<1/E,Abs[c["ReferenceObservable"]-c["ReferenceRoot"]^2]<10^-58}],
 {True,True,True},TestID->"integration-numerical-lower-lambert-power-observable"]

VerificationTest[Module[{x,y,s,c},s=AsymptoticFlatInverse[x+Exp[-1/x],{x,0},{y,2}];
 c=InverseNumericalCheck[s,1/30,WorkingPrecision->80];
 {AssociationQ[c],0<c["Error"]<10^-32,NumericQ[c["RemainderScale"]]}],
 {True,True,True},TestID->"integration-common-flat-numerical-check"]

VerificationTest[Module[{x,y,s,c},s=AsymptoticFourierInverse[x+x^2 Sin[Log[x]],{x,0},{y,4}];
 c=InverseNumericalCheck[s,1/1000,WorkingPrecision->60];
 {AssociationQ[c],c["Error"]<10^-10,Abs[c["RootResidual"]]<10^-58}],
 {True,True,True},TestID->"integration-common-fourier-numerical-check"]

VerificationTest[Module[{x,y,s,c},s=AsymptoticInverse[x+x/Log[x],{x,0},{y,4}];
 c=InverseNumericalCheck[s,Exp[-40],WorkingPrecision->60];
 {AssociationQ[c],c["Error"]<10^-22}],{True,True},TestID->"integration-common-reciprocal-log-numerical-check"]

VerificationTest[Module[{x,y,s,c},s=AsymptoticCoreInverse[x Log[x],x^2,{x,0},{y,2}];
 c=InverseNumericalCheck[s,-1/1000,WorkingPrecision->60];
 {AssociationQ[c],c["Error"]<10^-13}],{True,True},TestID->"integration-common-exact-core-numerical-check"]

VerificationTest[Module[{x,y,s,c},s=AsymptoticExponentialCoreInverse[x Exp[x],x^2,{x,Infinity},{y,2}];
 c=InverseNumericalCheck[s,20 Exp[20],WorkingPrecision->60];
 {AssociationQ[c],c["ReferenceRoot"]<20,c["Error"]<10^-19}],{True,True,True},
 TestID->"integration-common-exponential-core-numerical-check"]

VerificationTest[Module[{x,y,s,c},s=AsymptoticSpecialInverse["Erfc",{x,Infinity},{y,2}];
 c=InverseNumericalCheck[s,Erfc[20],WorkingPrecision->60];
 Abs[c["ReferenceRoot"]-20]<10^-55],True,TestID->"integration-common-special-function-numerical-check"]

VerificationTest[Module[{x,y,s,c},s=AsymptoticInverse[10^100+x+x^2,{x,0},{y,4}];
 c=InverseNumericalCheck[s,10^100+1/100,WorkingPrecision->50];
 Abs[c["ReferenceRoot"]-N[(Sqrt[1+4/100]-1)/2,50]]<10^-48],True,
 TestID->"integration-exact-target-offset-substitution-before-rounding"]

VerificationTest[Module[{x,y,s},s=AsymptoticFlatInverse[x+Exp[-1/x],{x,0},{y,2}];
 {MatchQ[InverseNumericalCheck[s,-1/100],Failure["OutsideBranch",_Association]],
 MatchQ[InverseNumericalCheck[s,0.01],Failure["InsufficientPrecision",_Association]]}],
 {True,True},TestID->"integration-new-numerical-kinds-enforce-target-contracts"]

VerificationTest[Module[{x,y,s,r},s=AsymptoticInverse[x+x^2,{x,0},{y,3}];
 r=SeriesRefine[s,<|"AdditionalBlocks"->3|>];
 {Length[r["Blocks"]],r["RefinementRequest"]["GoalReached"],InverseResidual[r]["ZeroBelowCutoff"]}],
 {5,True,True},TestID->"integration-additional-blocks-refinement-reuses-prefix"]

VerificationTest[Module[{x,y,s,r},s=AsymptoticInverse[x^2,{x,0},y,SeriesTermGoal->3];
 r=SeriesRefine[s,<|"AdditionalBlocks"->100|>];
 {r["Remainder"],r["RefinementRequest"]["GoalReached"],r["RefinementRequest"]["ExactTermination"],r["RefinementRequest"]["RefinementCalls"]}],
 {0,False,True,0},TestID->"integration-additional-blocks-stop-at-exact-termination"]

VerificationTest[Module[{x,y,s,r},s=AsymptoticInverse[x+x^2,{x,0},{y,3}];
 r=SeriesRefine[s,<|"AdditionalBlocks"->3|>,"MaxRefinements"->0];
 {MatchQ[r,Failure["RefinementGoalNotReached",_Association]],r[[2]]["BestExpansion"]===s}],
 {True,True},TestID->"integration-refinement-resource-failure-preserves-best-expansion"]

VerificationTest[Module[{x,y,s,r},s=AsymptoticInverse[x+x^2,{x,0},{y,3}];
 r=SeriesRefine[s,<|"Target"->1/100,"TargetError"->10^-30,"Interval"->{1/200,1/50}|>];
 {r["ResultType"],r["Certified"],r["CertifiedErrorBound"]<=10^-30,r["SourceExpansion"]===s}],
 {"NumericalCertificate",True,True,True},TestID->"integration-refinement-certified-tolerance-preserves-symbolic-scope"]

VerificationTest[Module[{x,y,s,r},s=AsymptoticInverse[x+x/Log[x],{x,0},{y,3}];
 r=SeriesRefine[s,5];
 {r["Kind"],r["RemainderPower"],InverseResidual[r]["ZeroBelowCutoff"],
 FullSimplify[Normal[r]==Normal[AsymptoticLogarithmicInverse[x+x/Log[x],{x,0},{y,5}]],0<y<Exp[-2]]}],
 {"LogarithmicInverse",5,True,True},TestID->"integration-logarithmic-refinement-replays-original-source"]

VerificationTest[Module[{x,y},MatchQ[AsymptoticInverse[x+x/Log[x],{x,0},{y,3},Method->"Unknown"],
 Failure["InvalidOption",_Association]]],True,TestID->"integration-logarithmic-route-rejects-unknown-method"]

VerificationTest[Module[{x,y,objects,refined},objects={
 AsymptoticExpansion[Sin[x],{x,0,3}],AsymptoticInverse[Sin[x],{x,0},{y,3}],
 AsymptoticInverse[x+x/Log[x],{x,0},{y,3}],AsymptoticInverse[Log[x],{x,0},{y,3}]};
 refined=SeriesRefine[#,5]&/@objects;
 {Lookup[#["RefinementStatistics"],"Strategy"]&/@refined,
 AllTrue[refined,#["RefinementStatistics"]["ModelReused"]===False&&Length[#["RefinementHistory"]]>0&]}],
 {{"ReplayOriginalSource","ReplayOriginalSource","ReplayOriginalSource","ReplayOriginalSource"},True},
 TestID->"integration-every-source-replay-reports-recomputation"]

VerificationTest[Module[{x,y,s,r},s=AsymptoticInverse[x+x^2,{x,0},{y,3}];
 r=SeriesRefine[SeriesMultiply[s,s],5];
 {r["RefinementStatistics"]["Strategy"],r["RefinementStatistics"]["NewCoefficientEvaluations"]}],
 {"ReplayOperationRecipe",Missing["ReplayNotInstrumented"]},TestID->"integration-operation-replay-does-not-invent-work-count"]

VerificationTest[Module[{x,y,s,a,t,r},s=AsymptoticSpecialInverse["Erfc",{x,-Infinity},{y,1}];
 a=SeriesAdd[s,0];t=SeriesTruncate[s,1];r=SeriesRefine[s,2];
 {FullSimplify[Normal[a]==Normal[s],2-Exp[-3]<y<2],
 FullSimplify[Normal[t]==Normal[s],2-Exp[-3]<y<2],
 r["Kind"],r["SourceSign"],r["ModelTerms"]>s["ModelTerms"],
 N[Normal[r]/.y->2-Erfc[10],50]<0}],
 {True,True,"SpecialInverse",-1,True,True},TestID->"integration-negative-erfc-calculus-and-refinement-retain-source-sign"]

VerificationTest[Module[{x,y,s,r},s=AsymptoticSpecialInverse["Erfc",{x,-Infinity},{y,1},"ModelTerms"->1];
 r=SeriesRefine[s,3];MatchQ[r,Failure["InsufficientModelOrder",_Association]]],True,
 TestID->"integration-explicit-special-forward-model-order-remains-a-cap"]

VerificationTest[Module[{x,y,s,r},s=AsymptoticSpecialInverse["LambertThreshold",{x,-1},{y,2},
 "TargetOffset"->7,"TargetScale"->-2,"LambertBranch"->-1];r=SeriesRefine[s,3];
 {s["Limit"],r["Limit"],r["ThresholdBranch"],r["Direction"]}],
 {7+2/E,7+2/E,-1,"FromBelow"},TestID->"integration-affine-lambert-threshold-limit-and-branch-survive-refinement"]

VerificationTest[Module[{x,y},MatchQ[AsymptoticSpecialInverse["LogGamma",{x,Infinity},{y,100},
 "ModelTerms"->1,"MaxTerms"->10],_Failure]],True,TestID->"integration-special-adapter-preserves-inner-constructor-failure"]
