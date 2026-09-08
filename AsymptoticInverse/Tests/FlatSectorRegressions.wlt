If[! MemberQ[$Packages, "AsymptoticInverse`"],
 Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[Module[{x,y,s}, s=AsymptoticFlatInverse[x+Exp[-1/x],{x,0},{y,3}];
 ({#[[1]], Expand[#[[2]]]} & /@ s["Sectors"]) /. y -> \[FormalY]],
 {{1,-1},{2,1/\[FormalY]^2},{3,1/\[FormalY]^3-3/(2 \[FormalY]^4)}},
 TestID -> "flat-primary-three-complete-sectors"]

VerificationTest[Module[{x,y,s}, s=AsymptoticFlatInverse[x+x^2 Exp[-1/x],{x,0},{y,2}];
 FullSimplify[Normal[s] == y-y^2 Exp[-1/y]+(y^2+2 y^3) Exp[-2/y],y>0]],
 True, TestID -> "flat-polynomial-factor-corrections"]

VerificationTest[Module[{x,y,s}, s=AsymptoticFlatInverse[x+Exp[-1/x]+2 Exp[-2/x],{x,0},{y,2}];
 FullSimplify[Normal[s] == y-Exp[-1/y]+(y^-2-2) Exp[-2/y],y>0]],
 True, TestID -> "flat-two-commensurate-input-sectors"]

VerificationTest[Module[{x,y,s}, s=AsymptoticFlatInverse[3 x^2+x Exp[-2/x],{x,0},{y,1}];
 FullSimplify[Normal[s] == Sqrt[y/3]-Exp[-2 Sqrt[3/y]]/6,y>0]],
 True, TestID -> "flat-nonunit-monomial-core"]

VerificationTest[Module[{x,y,s}, s=AsymptoticFlatInverse[7+(2-x)+Exp[-1/(2-x)],{x,2},{y,2},Direction->"FromBelow"];
 FullSimplify[Normal[s] == 2-(y-7)+Exp[-1/(y-7)]-(y-7)^-2 Exp[-2/(y-7)],y>7]],
 True, TestID -> "flat-shifted-source-and-target-left-branch"]

VerificationTest[Module[{x,y,s}, s=AsymptoticFlatInverse[1/x+Exp[-x],{x,Infinity},{y,1}];
 FullSimplify[Normal[s] == 1/y+Exp[-1/y]/y^2,y>0]],
 True, TestID -> "flat-infinite-source-observable-transport"]

VerificationTest[Module[{x,y,s}, s=AsymptoticFlatInverse[x+Exp[-1/x],{x,0},{y,2},"Power"->2];
 FullSimplify[Normal[s] == y^2-2 y Exp[-1/y]+(1+2/y) Exp[-2/y],y>0]],
 True, TestID -> "flat-square-observable-has-own-coefficients"]

VerificationTest[Module[{x,y,s,z,g,residual},
 s=AsymptoticFlatInverse[x+Exp[-1/x],{x,0},{y,3}];
 g=y+Total[(#[[2]] z^#[[1]])&/@s["Sectors"]];
 residual=Normal[Series[g+z Exp[1/y-1/g]-y,{z,0,3}]];
 Together[residual]], 0, TestID -> "flat-independent-sector-composition"]

VerificationTest[Module[{x,y,s,v,approx,root},
 s=AsymptoticFlatInverse[x+Exp[-1/x],{x,0},{y,3}]; v=1/30;
 approx=N[Normal[s]/.y->v,100];
 root=x/.FindRoot[x+Exp[-1/x]==v,{x,N[v,100]},WorkingPrecision->100,AccuracyGoal->90,PrecisionGoal->90];
 0 < Abs[root-approx] < N[4 Exp[-4/v] v^-6,80]],
 True, TestID -> "flat-high-precision-original-equation-oracle"]

VerificationTest[Module[{x,y}, FailureQ[AsymptoticFlatInverse[x+x^2+Exp[-1/x],{x,0},{y,2}]]],
 True, TestID -> "flat-rejects-an-inexact-zero-sector"]
VerificationTest[Module[{x,y}, FailureQ[AsymptoticFlatInverse[x+Exp[-1/x]+Exp[-Sqrt[2]/x],{x,0},{y,2}]]],
 True, TestID -> "flat-rejects-incommensurate-rates"]
VerificationTest[Module[{x,y}, FailureQ[AsymptoticFlatInverse[x+Exp[-1/x]+Exp[-1/x^2],{x,0},{y,2}]]],
 True, TestID -> "flat-rejects-different-phase-powers"]
VerificationTest[Module[{x,y}, FailureQ[AsymptoticFlatInverse[x+Exp[1/x],{x,0},{y,2}]]],
 True, TestID -> "flat-rejects-growing-exponential-perturbations"]
VerificationTest[Module[{x,y}, FailureQ[AsymptoticFlatInverse[x+Exp[-1/x],{x,0},{y,20},"MaxTerms"->10]]],
 True, TestID -> "flat-depth-budget-failure"]

VerificationTest[Module[{x,y,b}, FailureQ[AsymptoticFlatInverse[b+x+Exp[-1/x],{x,0},{y,2}]]],
 True, TestID -> "flat-target-offset-requires-real-assumption"]

VerificationTest[Module[{x,y,b,s}, s=AsymptoticFlatInverse[b+x+Exp[-1/x],{x,0},{y,1},Assumptions->Element[b,Reals]];
 FullSimplify[Normal[s]==y-b-Exp[-1/(y-b)],Element[b,Reals]&&y>b]],
 True, TestID -> "flat-real-symbolic-target-offset"]
