(* Native Wolfram regression suite. Execute with TestReport.
   Prepared but NOT executed in a genuine Wolfram kernel in this delivery. *)
Get[FileNameJoin[{DirectoryName[$InputFileName],"..","Kernel","RealLogPowerInverse.wl"}]];
Clear[x,y,ell,p];

VerificationTest[
 Module[{r=RealInverseExpansion[x+x^2 (1+Log[x]),{x,y},3]},
  Expand[r["Expression"]-y+y^2 (1+Log[y])-y^3 (2 Log[y]^2+5 Log[y]+3)]],
 0,TestID->"logarithmic-order-3"]

VerificationTest[
 LogQuadraticInversePolynomial[3,ell] // Expand,
 -5 ell^3-41 ell^2/2-27 ell-23/2,TestID->"logarithmic-polynomial-3"]

VerificationTest[
 Table[Coefficient[LogQuadraticInversePolynomial[n,ell],ell,n],{n,1,8}],
 Table[(-1)^n CatalanNumber[n],{n,1,8}],TestID->"Catalan-top-coefficients"]

VerificationTest[
 Module[{r=RealInverseExpansion[x+x^2 (1+Log[x]),{x,y},2]},
  {r["Remainder"]["Power"],r["Remainder"]["LogPower"]}],
 {3,2},TestID->"log-aware-remainder"]

VerificationTest[
 Module[{r=RealInverseExpansion[x+x^2 (1+Log[x]),{x,y},5]},
  InverseResidual[r]["Vanishes"]],True,TestID->"logarithmic-direct-composition"]

VerificationTest[
 Module[{r=LogPowerInverseExpansion[{{1,1+ell}},{y,ell},2]},
  Expand[InverseResidual[r,3]["NormalizedResidual"] +
   y^2 (2 Log[y]^2+5 Log[y]+3)]],
 0,TestID->"first-omitted-residual-sign"]

VerificationTest[
 PurePowerInverseCoefficient[p,3] // Expand,
 p/2-3 p^2/2,TestID->"pure-power-coefficient-3"]

VerificationTest[
 Module[{a=Sqrt[2]-1,r},
  r=RealInverseExpansion[x+x^Sqrt[2],{x,y},1+3 a];
  FullSimplify[r["Expression"]-(y-y^Sqrt[2]+Sqrt[2] y^(2 Sqrt[2]-1)
   -(3-Sqrt[2]/2) y^(3 Sqrt[2]-2)),Assumptions->y>0]],
 0,TestID->"irrational-exponents"]

VerificationTest[
 Module[{a=Sqrt[2]-1,r},
  r=RealInverseExpansion[x+x^Sqrt[2],{x,y},1+6 a];
  InverseResidual[r]["Vanishes"]],True,TestID->"irrational-direct-composition"]

VerificationTest[
 Module[{r=LogPowerInverseExpansion[{{1/2,1+ell},{1,2-ell}},{y,ell},3]},
  InverseResidual[r]["Vanishes"]],True,TestID->"resonant-generators"]

VerificationTest[
 Module[{r=LogPowerInverseExpansion[{{Sqrt[2]-1,1+ell},{1,2-ell}},{y,ell},3]},
  InverseResidual[r]["Vanishes"]],True,TestID->"mixed-irrational-logarithmic"]

VerificationTest[
 Module[{r=LogPowerInverseExpansion[{{1,1},{2,3}},{y,ell},3]},
  Expand[r["Expression"]]],y-y^2-y^3,TestID->"collision-coefficients-added"]

VerificationTest[
 Module[{r=LogPowerInverseExpansion[{{1,1},{2,2}},{y,ell},3]},
  Expand[r["Expression"]]],y-y^2,TestID->"collision-coefficients-cancel"]

VerificationTest[
 Module[{r=LogPowerInverseExpansion[{{1,1+ell},{1,1-ell}},{y,ell},3]},
  Expand[r["Expression"]]],y-2 y^2+8 y^3,TestID->"duplicate-input-blocks-merged"]

VerificationTest[
 Module[{r=RealInverseExpansion[2 x+3 x^2,{x,y},3]},Expand[r["Expression"]]],
 y/2-3 y^2/8+9 y^3/16,TestID->"nonunit-linear-coefficient"]

VerificationTest[
 Module[{r=LogPowerInverseExpansion[{{1/2,3(1+ell)},{1,-ell^2}},
  {y,ell},3,"LinearCoefficient"->2]},InverseResidual[r]["Vanishes"]],
 True,TestID->"scaled-logarithmic-composition"]

VerificationTest[
 Module[{r=RealInverseExpansion[5 x,{x,y},4]},
  {r["Expression"],r["Remainder"]["Scale"],InverseResidual[r]["Vanishes"]}],
 {y/5,0,True},TestID->"exact-linear-input"]

VerificationTest[
 Module[{r=RealInverseExpansion[x+x^2,{x,y},1]},
  {r["Expression"],r["Remainder"]["Power"]}],
 {y,2},TestID->"leading-only-cutoff"]

VerificationTest[
 Module[{r=LogPowerInverseExpansion[{{1/2,1+ell}},{y,ell},11/4]},
  {r["Terms"][[All,1]],r["Remainder"]["Power"]}],
 {{1,3/2,2,5/2},3},TestID->"cutoff-between-support-points"]

VerificationTest[
 Module[{r1,r2},
  r1=LogPowerInverseExpansion[{{Sqrt[8]-2,1}},{y,ell},3];
  r2=LogPowerInverseExpansion[{{2 Sqrt[2]-2,1}},{y,ell},3];
  FullSimplify[r1["Expression"]-r2["Expression"],Assumptions->y>0]],
 0,TestID->"algebraic-exponent-canonicalization"]

VerificationTest[
 FailureQ[LogPowerInverseExpansion[{{0,1+ell}},{y,ell},3]],
 True,TestID->"reject-zero-excess"]
VerificationTest[
 FailureQ[RealInverseExpansion[x+x^(3/2.),{x,y},3]],
 True,TestID->"reject-inexact-exponent"]
VerificationTest[
 FailureQ[LogPowerInverseExpansion[{{Pi,1}},{y,ell},3]],
 True,TestID->"reject-nonalgebraic-exponent"]
VerificationTest[
 FailureQ[LogPowerInverseExpansion[{{1,1/ell}},{y,ell},3]],
 True,TestID->"reject-nonpolynomial-log"]
VerificationTest[
 FailureQ[LogPowerInverseExpansion[{{1,p}},{y,ell},3]],
 True,TestID->"reject-unresolved-coefficient"]
VerificationTest[
 FailureQ[LogPowerInverseExpansion[{{1,1}},{y,ell},3,"LinearCoefficient"->-1]],
 True,TestID->"reject-negative-linear-coefficient"]
VerificationTest[
 FailureQ[RealInverseExpansion[x+x^2,{x,x},3]],
 True,TestID->"reject-identical-variables"]
VerificationTest[
 FailureQ[LogPowerInverseExpansion[{{1,1}},{y,ell},1/2]],
 True,TestID->"reject-cutoff-below-one"]
VerificationTest[
 FailureQ[LogPowerInverseExpansion[{{1,1}},{y,ell},4,"MaxMultiIndices"->2]],
 True,TestID->"multi-index-resource-limit"]
VerificationTest[
 Module[{r=RealInverseExpansion[x+x^2(1+Log[x]),{x,y},5]},
  FailureQ[InverseResidual[r,Automatic,"MaxProducts"->1]]],
 True,TestID->"composition-resource-limit"]
VerificationTest[
 Module[{r=LogPowerInverseExpansion[{{1,1+ell}},{y,ell},3],u},
  u=r["CorrectionBlocks"];u[[2,2]]=u[[2,2]]+1;
  r=Join[r,<|"CorrectionBlocks"->u|>];InverseResidual[r]["Vanishes"]],
 False,TestID->"corrupted-coefficient-detected"]

VerificationTest[
 Module[{r=RealInverseExpansion[x+x^2,{x,y},3],b},
  b=InverseErrorBound[r,1/100];
  FullSimplify[{b["Q"],b["SafeHomotopyDegree"],b["Bound"]}]],
 {9/200,2,243/1528000000},TestID->"quadratic-explicit-error-bound"]

VerificationTest[
 Module[{r=RealInverseExpansion[2 x,{x,y},3]},
  InverseErrorBound[r,1/100]["Bound"]],0,TestID->"linear-zero-error-bound"]

VerificationTest[
 Module[{r=RealInverseExpansion[x+x^2,{x,y},3]},
  FailureQ[InverseErrorBound[r,1/100,"Radius"->1]]],
 True,TestID->"reject-invalid-bound-radius"]
