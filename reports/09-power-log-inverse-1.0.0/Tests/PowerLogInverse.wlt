(* MUnit regression suite. NOT executed in a native kernel during preparation. *)
Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]], "Kernel", "PowerLogInverse.wl"}]];
Begin["PowerLogInverseTests`"];
ClearAll[x,y,ell,a,p,alpha,beta];

VerificationTest[
 Expand[PowerLogInverse[x+x^2(1+Log[x]),{x,y,3}]],
 Expand[y-y^2(1+Log[y])], TestID->"log-two-blocks"]

VerificationTest[
 With[{r=PowerLogInverseData[x+x^2(1+Log[x]),{x,y,3}]["Remainder"]},
  {r["YExponent"],r["LogDegree"]}], {3,2}, TestID->"log-correct-remainder"]

VerificationTest[
 Expand[PowerLogInverse[x+x^2(1+Log[x]),{x,y,5}]],
 Expand[y-y^2(1+Log[y])+y^3(3+5Log[y]+2Log[y]^2)
 -y^4(23/2+27Log[y]+41Log[y]^2/2+5Log[y]^3)],
 TestID->"log-through-fourth-power"]

VerificationTest[
 FullSimplify[PowerLogInverse[x+x^Sqrt[2],{x,y,4Sqrt[2]-3}]-
  (y-y^Sqrt[2]+Sqrt[2] y^(2Sqrt[2]-1)
   -(6-Sqrt[2])/2 y^(3Sqrt[2]-2)),Assumptions->y>0],
 0, TestID->"archived-irrational-example"]

VerificationTest[
 FullSimplify[PowerLogCoefficient[PowerLogModel[1,1,{{Sqrt[2]-1,1}},ell],{4}]],
 -4+17Sqrt[2]/3, TestID->"irrational-next-coefficient",
 SameTest->(TrueQ[FullSimplify[#1==#2]]&)]

VerificationTest[
 FullSimplify[PowerLogInverse[x+x^alpha,{x,y,3},
  "Truncation"->"Depth",Assumptions->alpha>1]-
  (y-y^alpha+alpha y^(2alpha-1)-alpha(3alpha-1)/2 y^(3alpha-2)),
  Assumptions->alpha>1 && y>0], 0, TestID->"symbolic-alpha-depth"]

VerificationTest[
 FullSimplify[PowerLogInverse[3x^2(1+x(1+Log[x])),{x,y,3/2}]-
  (Sqrt[y/3]-(y/3)(1+Log[y/3]/2)/2),Assumptions->y>0],
 0, TestID->"nonunit-leading-power-and-coefficient"]

VerificationTest[
 FullSimplify[PowerLogInverse[2x^(7/3),{x,y,1}]-(y/2)^(3/7),Assumptions->y>0],
 0, TestID->"pure-monomial"]

VerificationTest[
 PowerLogInverseData[2x^(7/3),{x,y,1}]["Remainder"]["Scale"],
 0, TestID->"pure-monomial-exact-remainder"]

VerificationTest[
 Expand[PowerLogInverse[x+x^2,{x,y,6},"InversePower"->2]],
 y^2-2y^3+5y^4-14y^5, TestID->"inverse-power-observable"]

VerificationTest[
 Expand[PowerLogInverse[x+x^2+x^3,{x,y,6}]],
 y-y^2+y^3-4y^5, TestID->"resonance-and-cancellation"]

VerificationTest[
 With[{f=x+2x^2-3x^3+x^5},
  Expand[PowerLogInverse[f,{x,y,9}]-Normal[InverseSeries[Series[f,{x,0,8}],y]]]],
 0, TestID->"ordinary-polynomial-InverseSeries-crosscheck"]

VerificationTest[
 Expand[PowerLogInverse[x+x^2,{x,y,10}]-
  Normal[Series[(Sqrt[1+4y]-1)/2,{y,0,9}]]],
 0, TestID->"Catalan-exact-radical-crosscheck"]

VerificationTest[
 Module[{m=PowerLogModel[1,1,{{1,1+ell}},ell]},
  Table[Coefficient[PowerLogCoefficient[m,{n}],ell,n],{n,1,10}]],
 Table[(-1)^n CatalanNumber[n],{n,1,10}], TestID->"Catalan-leading-log-coefficients"]

VerificationTest[
 Module[{d=PowerLogInverseData[x+x^Sqrt[2]+x^Sqrt[3],{x,y,3}]},
  And @@ (TrueQ[FullSimplify[#["YExponent"]<3]]& /@ d["Terms"])],
 True, TestID->"mixed-irrational-exponent-cutoff"]

VerificationTest[
 Module[{m,g},
  m=PowerLogModel[1,1,{{alpha,1},{beta,1}},ell,
    Assumptions->alpha>0 && beta>0];
  g=PowerLogInverse[m,{y,2},"Truncation"->"Depth"];
  FullSimplify[g-(y-y^(1+alpha)-y^(1+beta)
    +(1+alpha)y^(1+2alpha)+(1+beta)y^(1+2beta)
    +(2+alpha+beta)y^(1+alpha+beta)),
    Assumptions->alpha>0 && beta>0 && y>0]],
 0, TestID->"unordered-symbolic-gaps-depth"]

VerificationTest[
 Module[{m=PowerLogModel[1,1,{{1,ell},{1,1}},ell]},
  {Length[m["Perturbations"]],PowerLogCoefficient[m,{1}]}],
 {1,-1-ell}, TestID->"duplicate-generator-normalization"]

VerificationTest[
 Module[{d,g,v=10^-8},
  d=PowerLogInverseData[x+x^2(1+Log[x]),{x,y,5}];
  g=N[d["Expression"]/.y->v,80];
  Abs[g+g^2(1+Log[g])-v]<10^-30],
 True, TestID->"numerical-forward-residual"]

VerificationTest[
 MatchQ[PowerLogInverse[x Log[x],{x,y,3}],Failure["LogarithmicLeadingTerm",_]],
 True, TestID->"reject-leading-log"]
VerificationTest[
 FailureQ[PowerLogInverse[x+Exp[-1/x],{x,y,3}]],
 True, TestID->"reject-unimplemented-flat-term"]
VerificationTest[
 MatchQ[PowerLogInverse[x+x^2/Log[x],{x,y,3}],Failure["NonPolynomialLog",_]],
 True, TestID->"reject-negative-log-power"]
VerificationTest[
 FailureQ[PowerLogInverse[x+I x^2,{x,y,3}]],
 True, TestID->"reject-complex-coefficient"]
VerificationTest[
 FailureQ[PowerLogInverse[-x+x^2,{x,y,3}]],
 True, TestID->"reject-negative-leading-coefficient"]
VerificationTest[
 MatchQ[PowerLogInverse[x+x^1.4,{x,y,3}],Failure["InexactInput",_]],
 True, TestID->"reject-machine-exponent"]
VerificationTest[
 MatchQ[PowerLogInverse[0,{x,y,3}],Failure["ZeroFunction",_]],
 True, TestID->"reject-zero-function"]
VerificationTest[
 MatchQ[PowerLogInverse[x+x^2,{x,y,1}],Failure["CutoffTooLow",_]],
 True, TestID->"reject-low-cutoff"]
VerificationTest[
 MatchQ[PowerLogInverse[x+x^2,{x,y,10},"MaxTerms"->2],Failure["TermLimit",_]],
 True, TestID->"resource-limit-does-not-return-partial-answer"]
VerificationTest[
 FailureQ[PowerLogInverse[x+x^2,{x,y,3},"InversePower"->-1]],
 True, TestID->"reject-nonpositive-observable-power"]
VerificationTest[
 FailureQ[PowerLogModel[1,1,{{-1,1}},ell]],
 True, TestID->"reject-nonpositive-gap"]
VerificationTest[
 FailureQ[PowerLogInverse[x+x^alpha,{x,y,3}]],
 True, TestID->"reject-unproved-parameter-conditions"]
VerificationTest[
 MatchQ[PowerLogInverse[x+x^2,{x,x,3}],Failure["VariableCollision",_]],
 True, TestID->"reject-variable-collision"]
VerificationTest[
 MatchQ[PowerLogInverse[x+x^2,{x,y,-1},"Truncation"->"Depth"],Failure["InvalidDepth",_]],
 True, TestID->"reject-negative-depth"]
VerificationTest[
 PowerLogInverse[x+x^2(1+Log[x]),{x,y,0},"Truncation"->"Depth"],
 y, TestID->"depth-zero-base-term"]
VerificationTest[
 FailureQ[PowerLogInverse[x+x^2,{x,y,3},Assumptions->False]],
 True, TestID->"reject-inconsistent-assumptions"]
VerificationTest[
 Module[{m=PowerLogModel[1,1,{{1,1}},ell]},
  MatchQ[PowerLogCoefficient[m,{-1}],Failure["InvalidMultiindex",_]]],
 True, TestID->"reject-invalid-multiindex"]

End[];
