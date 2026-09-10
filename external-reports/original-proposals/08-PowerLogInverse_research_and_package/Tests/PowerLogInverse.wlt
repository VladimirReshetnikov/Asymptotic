(* Native Wolfram Language regression suite. Run with Tests/run-tests.wls.
   This suite is supplied for native execution; see VALIDATION.md for what
   was actually executed when this archive was built. *)
Get[FileNameJoin[{
 DirectoryName[If[StringQ[$TestFileName] && $TestFileName =!= "",
   $TestFileName, $InputFileName]],
 "..", "Kernel", "PowerLogInverse.wl"}]];

VerificationTest[
 Module[{x,y}, Expand[PowerLogInverse[x+x^2(1+Log[x]),{x,y,5}] -
  (y-(1+Log[y])y^2+(2Log[y]^2+5Log[y]+3)y^3-
   (5Log[y]^3+41Log[y]^2/2+27Log[y]+23/2)y^4)]],
 0, TestID->"log-example-four-blocks"]

VerificationTest[
 Module[{x,y,d},d=PowerLogInverseData[x+x^2(1+Log[x]),{x,y,3}];
  {Expand[d["Expression"]-(y-(1+Log[y])y^2)],d["Remainder"]/.y->t}],
 {0,PowerLogOrder[t,3,2]},TestID->"log-remainder-not-O-y-cubed"]

VerificationTest[
 Module[{x,y,r=Sqrt[2]},FullSimplify[
  PowerLogInverse[x+x^r,{x,y,1+4(r-1)}] -
  (y-y^r+r y^(2r-1)-r(3r-1)y^(3r-2)/2),Assumptions->y>0]],
 0,TestID->"irrational-four-blocks"]

VerificationTest[
 Module[{u,l,d},d=PowerLogReversion[1,1,{{Sqrt[2]-1,1}},{u,l},1+5(Sqrt[2]-1)];
  {Length[d["Terms"]],FullSimplify[Last[d["Terms"]][[1]]==1+4(Sqrt[2]-1)]}],
 {5,True},TestID->"strict-irrational-cutoff"]

VerificationTest[
 Module[{x,y,d},d=PowerLogInverseData[x+x^2(1+Log[x]),{x,y,7}];
  PowerLogResidual[d]["Certificate"]],True,TestID->"log-residual-certificate"]

VerificationTest[
 Module[{x,y,d,l,r},d=PowerLogInverseData[x+x^2(1+Log[x]),{x,y,5}];
  l=d["LogSymbol"];r=PowerLogResidual[d,5]["Terms"];
  {r[[1,1]],Expand[r[[1,2]]+14l^4+241l^3/3+335l^2/2+151l+299/6]}],
 {4,0},TestID->"first-omitted-block-from-residual"]

VerificationTest[
 Module[{x,y,d},d=PowerLogInverseData[x+x^Sqrt[2],{x,y,3}];
  PowerLogResidual[d]["Certificate"]],True,TestID->"irrational-residual-certificate"]

VerificationTest[
 Module[{x,y,d},d=PowerLogInverseData[x+x^2+x^3,{x,y,7}];
  {PowerLogResidual[d]["Certificate"],Coefficient[d["Expression"],y,4],
    Coefficient[d["Expression"],y,5]}],
 {True,0,-4},TestID->"collisions-and-exact-cancellation"]

VerificationTest[
 Module[{u,l,a,b},a=PowerLogReversion[1,1,{{1,l},{1,1}},{u,l},6];
  b=PowerLogReversion[1,1,{{1,1+l}},{u,l},6];
  Expand[a["Expression"]-b["Expression"]]],0,TestID->"duplicate-generator-merging"]

VerificationTest[
 Module[{x,y,d},d=PowerLogInverseData[x+x^Sqrt[2]+x^2(1+Log[x]),{x,y,7/2}];
  PowerLogResidual[d]["Certificate"]],True,TestID->"mixed-log-irrational-certificate"]

VerificationTest[
 Module[{x,y},FullSimplify[PowerLogInverse[x^2(1+x),{x,y,5}]-
  (Sqrt[y]-y/2+5y^(3/2)/8-y^2),Assumptions->y>0]],
 0,TestID->"nonunit-leading-power"]

VerificationTest[
 Module[{x,y},FullSimplify[PowerLogInverse[4x^2(1+x),{x,y,4}]-
  (Sqrt[y]/2-y/8+5y^(3/2)/64),Assumptions->y>0]],
 0,TestID->"leading-coefficient-normalization"]

VerificationTest[
 Module[{x,y,d},d=PowerLogInverseData[4x^2(1+x Log[x]+3x^Sqrt[2]),{x,y,4}];
  PowerLogResidual[d]["Certificate"]],True,TestID->"mixed-p2-log-shift"]

VerificationTest[
 Module[{u,l,d},d=PowerLogReversion[2,3/2,{{1/2,l^2-2},{1,l+3}},{u,l},3];
  PowerLogResidual[d]["Certificate"]],True,TestID->"fractional-leading-exponent"]

VerificationTest[
 Module[{x,y,d},d=PowerLogInverseData[3x^(2/3),{x,y,4}];
  {FullSimplify[d["Expression"]==(y/3)^(3/2),Assumptions->y>0],
    d["Remainder"],PowerLogResidual[d]["Expression"]}],
 {True,0,0},TestID->"exact-monomial"]

VerificationTest[
 Module[{x,y},Expand[PowerLogInverse[x+x^2,{x,y,8}] -
  Sum[(-1)^n CatalanNumber[n] y^(n+1),{n,0,6}]]],
 0,TestID->"ordinary-Catalan-reversion"]

VerificationTest[
 Module[{x,y},Expand[PowerLogInverse[ConditionalExpression[x+x^2,x>0],{x,y,4}]-
  (y-y^2+2y^3)]],0,TestID->"positive-condition-preserved"]

VerificationTest[
 Module[{x,y,d},d=PowerLogInverseData[ConditionalExpression[x+x^2,x>1],{x,y,4}];d[[1]]],
 "UnresolvedCondition",TestID->"unresolved-condition-rejected"]

VerificationTest[
 Module[{x,y},PowerLogInverse[x(-Log[x]),{x,y,4}][[1]]],
 "LeadingLogBlock",TestID->"leading-log-block-directed-to-helper"]

VerificationTest[
 Module[{x,y},PowerLogInverse[-x+x^2,{x,y,4}][[1]]],
 "WrongLeadingGerm",TestID->"negative-leading-coefficient-rejected"]

VerificationTest[
 Module[{x,y},PowerLogInverse[1+x,{x,y,4}][[1]]],
 "WrongLeadingGerm",TestID->"nonzero-basepoint-rejected"]

VerificationTest[
 Module[{x,y},PowerLogInverse[x+x^1.41421356237,{x,y,4}][[1]]],
 "UnsupportedExponent",TestID->"machine-exponent-not-rationalized"]

VerificationTest[
 Module[{x,y,r},PowerLogInverse[x+x^r,{x,y,4}][[1]]],
 "UnsupportedExponent",TestID->"undecidable-symbolic-exponent-rejected"]

VerificationTest[
 Module[{x,y},PowerLogInverse[x+Sin[x],{x,y,4}][[1]]],
 "UnsupportedExpression",TestID->"unprepared-function-rejected"]

VerificationTest[
 Module[{x,y},PowerLogInverse[x+x^2/Log[x],{x,y,4}][[1]]],
 "NotLogPolynomial",TestID->"negative-log-powers-not-silently-truncated"]

VerificationTest[
 Module[{x,y},PowerLogInverse[I x+x^2,{x,y,4}][[1]]],
 "NonrealOrInexactCoefficient",TestID->"complex-coefficient-rejected"]

VerificationTest[
 Module[{x},PowerLogInverse[x+x^2,{x,x,4}][[1]]],
 "VariableCollision",TestID->"source-target-collision-rejected"]

VerificationTest[
 Module[{u,l},PowerLogReversion[1,1,{{0,1}},{u,l},4][[1]]],
 "NonpositiveCorrection",TestID->"zero-valuation-correction-rejected"]

VerificationTest[
 Module[{u,l},PowerLogReversion[1,1,{{1,1}},{u,l},1][[1]]],
 "InvalidCutoff",TestID->"cutoff-must-exceed-leading-power"]

VerificationTest[
 Module[{x,y},PowerLogInverse[x+x^2,{x,y,5},"MaxMultiIndices"->1][[1]]],
 "IndexLimit",TestID->"enumeration-budget"]

VerificationTest[
 Module[{x,y},PowerLogInverse[x+x^2,{x,y,5},"MaxTotalDegree"->2][[1]]],
 "DegreeLimit",TestID->"degree-budget"]

VerificationTest[
 Module[{x,y,d},d=PowerLogInverseData[x+x^2(1+Log[x]),{x,y,5}];
  d=Join[d,<|"Terms"->ReplacePart[d["Terms"],{3,2}->(d["Terms"][[3,2]]+1)]|>];
  PowerLogResidual[d]["Certificate"]],False,TestID->"corrupt-coefficient-detected"]

VerificationTest[
 Module[{x,y,d},d=PowerLogInverseData[x+x^2(1+Log[x]),{x,y,5}];
  PowerLogResidual[d,1]["Certificate"]],
 Missing["InsufficientCutoff"],TestID->"insufficient-residual-range-not-certified"]

VerificationTest[
 Module[{u,l,d},d=PowerLogReversion[1,1,{{1,0}},{u,l},5];
 {d["Expression"]===u,d["Remainder"]}],
 {True,0},TestID->"zero-correction-removal"]

VerificationTest[
 Module[{y},LogPowerBaseInverse[y,1,1,1]/.y->t],
 Exp[ProductLog[-1,-t]],TestID->"leading-log-positive-q-branch"]

VerificationTest[
 Module[{y},LogPowerBaseInverse[y,1,1,-1]/.y->t],
 Exp[-ProductLog[0,1/t]],TestID->"leading-log-negative-q-branch"]

VerificationTest[
 Module[{y},LogPowerBaseInverse[y,4,2,0]/.y->t],
 Sqrt[t/4],SameTest->(FullSimplify[#1==#2,Assumptions->t>0]&),
 TestID->"leading-log-q-zero"]

VerificationTest[
 Module[{z,y},Expand[InversePerturbationJet[z,z^2,{z,y,3}] -
   (y-y^2+2y^3-5y^4)]],0,TestID->"homotopy-jet-ordinary"]

VerificationTest[
 Module[{z,y},FullSimplify[InversePerturbationJet[Sqrt[z],z^(3/2),{z,y,3}] -
  (Sqrt[y]-y/2+5y^(3/2)/8-y^2),Assumptions->y>0]],
 0,TestID->"homotopy-jet-observable"]

VerificationTest[
 Module[{x,y},Expand[PowerLogInverse[
  ConditionalExpression[x+x^2(1+Log[x]),Im[x]==0],{x,y,3}] -
  (y-(1+Log[y])y^2)]],0,TestID->"source-real-condition-selects-positive-germ"]
