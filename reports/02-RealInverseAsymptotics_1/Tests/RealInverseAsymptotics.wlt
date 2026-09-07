(* MUnit test suite. Native execution status: see validation/REPORT.md.
   Run with TestReport["path/to/Tests/RealInverseAsymptotics.wlt"]. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "RealInverseAsymptotics.wl"}]];
Clear[x, y, ell, a, b];

VerificationTest[
 FullSimplify[RealInverseSeries[x + x^2 (1 + Log[x]), {x, 0}, y, 3]["Expression"] -
 (y-y^2 (1+Log[y])), y>0],
 0, TestID -> "log-first-two-powers"]

VerificationTest[
 FullSimplify[RealInverseSeries[x + x^2 (1 + Log[x]), {x, 0}, y, 5]["Expression"] -
  (y-y^2 (1+Log[y])+y^3 (1+Log[y]) (3+2 Log[y])-
   y^4 (1+Log[y]) (10 Log[y]^2+31 Log[y]+23)/2), y>0],
 0, TestID -> "log-through-y4"]

VerificationTest[
 With[{r=RealInverseSeries[x+x^2 (1+Log[x]),{x,0},y,3]},
  {r["RemainderPower"],r["RemainderLogDegree"]}],
 {3,2}, TestID -> "log-remainder-not-O-y3"]

VerificationTest[
 FullSimplify[RealInverseSeries[x+x^Sqrt[2],{x,0},y,4 Sqrt[2]-3]["Expression"]-
 (y-y^Sqrt[2]+Sqrt[2] y^(2 Sqrt[2]-1)-(6-Sqrt[2])/2 y^(3 Sqrt[2]-2)), y>0],
 0, TestID -> "question-irrational-four-terms"]

VerificationTest[
 FullSimplify[RealInverseSeries[x+x^Sqrt[2],{x,0},y,4 Sqrt[2]-3]["RemainderPower"] -
 (4 Sqrt[2]-3)],
 0, TestID -> "irrational-strict-cutoff"]

VerificationTest[
 RealInverseSeries[x+x^Sqrt[2],{x,0},y,1+(Sqrt[2]-1)/2]["Expression"],
 y, TestID -> "cutoff-before-first-correction"]

VerificationTest[
 FullSimplify[RealInverseSeries[x+x^(3/2)+2 x^2 Log[x],{x,0},y,3]["Expression"]-
 (y-y^(3/2)+(3/2-2 Log[y]) y^2+(7 Log[y]-5/8) y^(5/2)),y>0],
 0, TestID -> "resonant-exponent-collision"]

VerificationTest[
 Module[{r,t=(y/2)^(1/3),l=Log[y/2]/3},
  r=InversePowerLog[2,3,{{1/2,1+ell}},ell,y,5/6];
  FullSimplify[r["Expression"]-(t-(y/2)^(1/2) (1+l)/3+
    (y/2)^(2/3) (1+l) (5 l+7)/18),y>0]],
 0, TestID -> "nonlinear-leading-monomial"]

VerificationTest[
 FullSimplify[RealInverseSeries[x+x^2,{x,0},y,6,"ObservablePower"->2]["Expression"]-
 (y^2-2 y^3+5 y^4-14 y^5),y>0],
 0, TestID -> "inverse-observable-square"]

VerificationTest[
 RealInverseSeries[3 x^2,{x,0},y,2]["Expression"],
 Sqrt[y/3], TestID -> "exact-monomial-inverse"]

VerificationTest[
 RealInverseSeries[3 x^2,{x,0},y,2]["IsExact"],
 True, TestID -> "exact-monomial-metadata"]

VerificationTest[
 RealInverseSeries[x+x^2,{x,0},y,1,"ObservablePower"->0]["Expression"],
 1, TestID -> "zero-observable-power"]

VerificationTest[
 FullSimplify[InversePowerLog[1,1,{{1/2,1},{1/2,ell}},ell,y,2]["Expression"]-
 (y-y^(3/2) (1+Log[y])),y>0],
 0, TestID -> "merge-input-corrections"]

VerificationTest[
 With[{r=RealInverseSeries[x+x^2+2 x^3,{x,0},y,3]},
  {r["FrontierPolynomial"],r["RemainderPower"],r["RemainderLogDegree"]}],
 {0,3,0}, TestID -> "cancelled-frontier-conservative-bound"]

VerificationTest[
 FullSimplify[RealInverseSeries[a x+b x^2,{x,0},y,3,
   Assumptions->a>0 && Element[b,Reals]]["Expression"]-
  (y/a-b y^2/a^3),a>0 && y>0 && Element[b,Reals]],
 0, TestID -> "symbolic-real-coefficients"]

VerificationTest[FailureQ[RealInverseSeries[-x+x^2,{x,0},y,3]],True,
 TestID -> "reject-negative-leading-coefficient"]
VerificationTest[FailureQ[RealInverseSeries[a x+x^2,{x,0},y,3]],True,
 TestID -> "reject-unproved-leading-sign"]
VerificationTest[FailureQ[RealInverseSeries[x+x^1.4142,{x,0},y,3]],True,
 TestID -> "reject-floating-exponent"]
VerificationTest[FailureQ[RealInverseSeries[x+x^Pi,{x,0},y,3]],True,
 TestID -> "reject-unsupported-transcendental-exponent"]
VerificationTest[FailureQ[RealInverseSeries[x Log[x],{x,0},y,3]],True,
 TestID -> "reject-logarithmic-leading-sector"]
VerificationTest[FailureQ[RealInverseSeries[x+x^2 Log[Log[x]],{x,0},y,3]],True,
 TestID -> "reject-nested-logarithm"]
VerificationTest[FailureQ[RealInverseSeries[x+x^2/Log[x],{x,0},y,3]],True,
 TestID -> "reject-negative-log-degree"]
VerificationTest[FailureQ[RealInverseSeries[0,{x,0},y,3]],True,
 TestID -> "reject-zero-function"]
VerificationTest[FailureQ[RealInverseSeries[x+x^2,{x,0},x,3]],True,
 TestID -> "reject-variable-collision"]
VerificationTest[FailureQ[RealInverseSeries[x+x^2,{x,0},y,1]],True,
 TestID -> "reject-cutoff-at-leading-power"]
VerificationTest[FailureQ[InversePowerLog[1,1,{{0,1}},ell,y,3]],True,
 TestID -> "reject-zero-delta"]
VerificationTest[FailureQ[RealInverseSeries[x+I x^2,{x,0},y,3]],True,
 TestID -> "reject-complex-coefficient"]
VerificationTest[FailureQ[RealInverseSeries[x+x^2,{x,0},y,20,
 "MaxTotalDegree"->4]],True, TestID -> "degree-resource-limit"]
VerificationTest[FailureQ[RealInverseSeries[x+x^(3/2)+x^2,{x,0},y,4,
 "MaxMultiIndices"->2]],True, TestID -> "enumeration-resource-limit"]
VerificationTest[FailureQ[RealInverseSeries[x+x^2,{x,0},y,3,
 "Method"->"Unknown"]],True, TestID -> "unknown-method"]
VerificationTest[FailureQ[RealInverseResidual[
 RealInverseSeries[x+x^2,{x,0},y,4,"ObservablePower"->2],2]],True,
 TestID -> "reject-residual-of-observable"]
VerificationTest[PurePowerInverseCoefficient[Sqrt[2],0],1,
 TestID -> "pure-power-coefficient-zero"]
VerificationTest[FullSimplify[PurePowerInverseCoefficient[Sqrt[2],3]-(-3+Sqrt[2]/2)],0,
 TestID -> "pure-power-coefficient-three"]
VerificationTest[FailureQ[PurePowerInverseCoefficient[Sqrt[2],-1]],True,
 TestID -> "reject-negative-coefficient-index"]
VerificationTest[FailureQ[PurePowerInverseCoefficient[1,3]],True,
 TestID -> "reject-nonsmall-power-correction"]

(* Deterministic fixtures mirrored by validation/validate.py.
   Seed 236367. These are native tests, NOT executed in the supplied report. *)

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,2^(1/2),{{1/2,2 - ell},{1,2}},ell,y,(5/4)*2^(1/2),"Method"->"Lagrange"];
  r2=InversePowerLog[1,2^(1/2),{{1/2,2 - ell},{1,2}},ell,y,(5/4)*2^(1/2),"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-00-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,2^(1/2),{{1/2,2 - ell},{1,2}},ell,y,(5/4)*2^(1/2)],3/2]["AllZero"],
 True, TestID -> "fixture-00-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,2^(1/2),{{1/2,2 - ell},{1,2}},ell,y,(7/4)*2^(1/2),"ObservablePower"->2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,2^(1/2),{{1/2,2 - ell},{1,2}},ell,y,(7/4)*2^(1/2),"ObservablePower"->2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-00-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,2,{{1/2,1 - ell},{1,1}},ell,y,5/4,"Method"->"Lagrange"];
  r2=InversePowerLog[1,2,{{1/2,1 - ell},{1,1}},ell,y,5/4,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-01-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,2,{{1/2,1 - ell},{1,1}},ell,y,5/4],3/2]["AllZero"],
 True, TestID -> "fixture-01-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,2,{{1/2,1 - ell},{1,1}},ell,y,1,"ObservablePower"->1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,2,{{1/2,1 - ell},{1,1}},ell,y,1,"ObservablePower"->1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-01-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1,{{2/3,ell + 2},{4/3,-ell - 2}},ell,y,3,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1,{{2/3,ell + 2},{4/3,-ell - 2}},ell,y,3,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-02-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,1,{{2/3,ell + 2},{4/3,-ell - 2}},ell,y,3],2]["AllZero"],
 True, TestID -> "fixture-02-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1,{{2/3,ell + 2},{4/3,-ell - 2}},ell,y,3/2,"ObservablePower"->-1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1,{{2/3,ell + 2},{4/3,-ell - 2}},ell,y,3/2,"ObservablePower"->-1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-02-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1/2,{{1,-ell - 2},{2,-ell - 1}},ell,y,8,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1/2,{{1,-ell - 2},{2,-ell - 1}},ell,y,8,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-03-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,1/2,{{1,-ell - 2},{2,-ell - 1}},ell,y,8],3]["AllZero"],
 True, TestID -> "fixture-03-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1/2,{{1,-ell - 2},{2,-ell - 1}},ell,y,7,"ObservablePower"->1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1/2,{{1,-ell - 2},{2,-ell - 1}},ell,y,7,"ObservablePower"->1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-03-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3/2,{{1/2,1},{1,ell - 1}},ell,y,5/3,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3/2,{{1/2,1},{1,ell - 1}},ell,y,5/3,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-04-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,3/2,{{1/2,1},{1,ell - 1}},ell,y,5/3],3/2]["AllZero"],
 True, TestID -> "fixture-04-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3/2,{{1/2,1},{1,ell - 1}},ell,y,7/3,"ObservablePower"->2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3/2,{{1/2,1},{1,ell - 1}},ell,y,7/3,"ObservablePower"->2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-04-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,2,{{1/2,-2},{1,ell - 1}},ell,y,5/4,"Method"->"Lagrange"];
  r2=InversePowerLog[1,2,{{1/2,-2},{1,ell - 1}},ell,y,5/4,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-05-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,2,{{1/2,-2},{1,ell - 1}},ell,y,5/4],3/2]["AllZero"],
 True, TestID -> "fixture-05-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,2,{{1/2,-2},{1,ell - 1}},ell,y,1/2,"ObservablePower"->-1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,2,{{1/2,-2},{1,ell - 1}},ell,y,1/2,"ObservablePower"->-1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-05-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1/2,{{1,1},{2,ell - 1}},ell,y,8,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1/2,{{1,1},{2,ell - 1}},ell,y,8,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-06-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,1/2,{{1,1},{2,ell - 1}},ell,y,8],3]["AllZero"],
 True, TestID -> "fixture-06-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1/2,{{1,1},{2,ell - 1}},ell,y,10,"ObservablePower"->2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1/2,{{1,1},{2,ell - 1}},ell,y,10,"ObservablePower"->2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-06-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3/2,{{1/2,1 - ell},{1,ell - 2}},ell,y,5/3,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3/2,{{1/2,1 - ell},{1,ell - 2}},ell,y,5/3,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-07-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,3/2,{{1/2,1 - ell},{1,ell - 2}},ell,y,5/3],3/2]["AllZero"],
 True, TestID -> "fixture-07-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3/2,{{1/2,1 - ell},{1,ell - 2}},ell,y,4/3,"ObservablePower"->1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3/2,{{1/2,1 - ell},{1,ell - 2}},ell,y,4/3,"ObservablePower"->1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-07-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1/2,{{1,1 - ell},{2,2 - ell}},ell,y,8,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1/2,{{1,1 - ell},{2,2 - ell}},ell,y,8,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-08-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,1/2,{{1,1 - ell},{2,2 - ell}},ell,y,8],3]["AllZero"],
 True, TestID -> "fixture-08-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1/2,{{1,1 - ell},{2,2 - ell}},ell,y,5,"ObservablePower"->-1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1/2,{{1,1 - ell},{2,2 - ell}},ell,y,5,"ObservablePower"->-1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-08-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3,{{2/3,-1},{4/3,2 - ell}},ell,y,1,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3,{{2/3,-1},{4/3,2 - ell}},ell,y,1,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-09-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,3,{{2/3,-1},{4/3,2 - ell}},ell,y,1],2]["AllZero"],
 True, TestID -> "fixture-09-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3,{{2/3,-1},{4/3,2 - ell}},ell,y,4/3,"ObservablePower"->2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3,{{2/3,-1},{4/3,2 - ell}},ell,y,4/3,"ObservablePower"->2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-09-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3,{{1,-1},{2,ell + 1}},ell,y,4/3,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3,{{1,-1},{2,ell + 1}},ell,y,4/3,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-10-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,3,{{1,-1},{2,ell + 1}},ell,y,4/3],3]["AllZero"],
 True, TestID -> "fixture-10-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3,{{1,-1},{2,ell + 1}},ell,y,5/6,"ObservablePower"->-1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3,{{1,-1},{2,ell + 1}},ell,y,5/6,"ObservablePower"->-1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-10-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1,{{1/2,1 - ell},{1,1 - ell}},ell,y,5/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1,{{1/2,1 - ell},{1,1 - ell}},ell,y,5/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-11-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,1,{{1/2,1 - ell},{1,1 - ell}},ell,y,5/2],3/2]["AllZero"],
 True, TestID -> "fixture-11-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1,{{1/2,1 - ell},{1,1 - ell}},ell,y,2,"ObservablePower"->1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1,{{1/2,1 - ell},{1,1 - ell}},ell,y,2,"ObservablePower"->1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-11-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3/2,{{2/3,2 - ell},{4/3,-2}},ell,y,2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3/2,{{2/3,2 - ell},{4/3,-2}},ell,y,2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-12-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,3/2,{{2/3,2 - ell},{4/3,-2}},ell,y,2],2]["AllZero"],
 True, TestID -> "fixture-12-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3/2,{{2/3,2 - ell},{4/3,-2}},ell,y,8/3,"ObservablePower"->2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3/2,{{2/3,2 - ell},{4/3,-2}},ell,y,8/3,"ObservablePower"->2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-12-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,2,{{1/2,-2},{1,1 - ell}},ell,y,5/4,"Method"->"Lagrange"];
  r2=InversePowerLog[1,2,{{1/2,-2},{1,1 - ell}},ell,y,5/4,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-13-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,2,{{1/2,-2},{1,1 - ell}},ell,y,5/4],3/2]["AllZero"],
 True, TestID -> "fixture-13-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,2,{{1/2,-2},{1,1 - ell}},ell,y,7/4,"ObservablePower"->2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,2,{{1/2,-2},{1,1 - ell}},ell,y,7/4,"ObservablePower"->2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-13-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1,{{1/2,2 - ell},{1,-1}},ell,y,5/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1,{{1/2,2 - ell},{1,-1}},ell,y,5/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-14-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,1,{{1/2,2 - ell},{1,-1}},ell,y,5/2],3/2]["AllZero"],
 True, TestID -> "fixture-14-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1,{{1/2,2 - ell},{1,-1}},ell,y,1,"ObservablePower"->-1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1,{{1/2,2 - ell},{1,-1}},ell,y,1,"ObservablePower"->-1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-14-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3,{{1,2},{2,1 - ell}},ell,y,4/3,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3,{{1,2},{2,1 - ell}},ell,y,4/3,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-15-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,3,{{1,2},{2,1 - ell}},ell,y,4/3],3]["AllZero"],
 True, TestID -> "fixture-15-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3,{{1,2},{2,1 - ell}},ell,y,5/6,"ObservablePower"->-1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3,{{1,2},{2,1 - ell}},ell,y,5/6,"ObservablePower"->-1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-15-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1,{{2/3,2},{4/3,1}},ell,y,3,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1,{{2/3,2},{4/3,1}},ell,y,3,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-16-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,1,{{2/3,2},{4/3,1}},ell,y,3],2]["AllZero"],
 True, TestID -> "fixture-16-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1,{{2/3,2},{4/3,1}},ell,y,3/2,"ObservablePower"->-1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1,{{2/3,2},{4/3,1}},ell,y,3/2,"ObservablePower"->-1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-16-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1/2,{{2/3,1 - ell},{4/3,ell - 1}},ell,y,6,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1/2,{{2/3,1 - ell},{4/3,ell - 1}},ell,y,6,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-17-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,1/2,{{2/3,1 - ell},{4/3,ell - 1}},ell,y,6],2]["AllZero"],
 True, TestID -> "fixture-17-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,1/2,{{2/3,1 - ell},{4/3,ell - 1}},ell,y,3,"ObservablePower"->-1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,1/2,{{2/3,1 - ell},{4/3,ell - 1}},ell,y,3,"ObservablePower"->-1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-17-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,2,{{1,ell - 1},{2,1}},ell,y,2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,2,{{1,ell - 1},{2,1}},ell,y,2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-18-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,2,{{1,ell - 1},{2,1}},ell,y,2],3]["AllZero"],
 True, TestID -> "fixture-18-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,2,{{1,ell - 1},{2,1}},ell,y,7/4,"ObservablePower"->1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,2,{{1,ell - 1},{2,1}},ell,y,7/4,"ObservablePower"->1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-18-observable"]

VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3,{{2/3,ell + 1},{4/3,ell - 2}},ell,y,1,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3,{{2/3,ell + 1},{4/3,ell - 2}},ell,y,1,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-19-algorithm-agreement"]
VerificationTest[
 RealInverseResidual[InversePowerLog[1,3,{{2/3,ell + 1},{4/3,ell - 2}},ell,y,1],2]["AllZero"],
 True, TestID -> "fixture-19-residual"]
VerificationTest[
 Module[{r1,r2},
  r1=InversePowerLog[1,3,{{2/3,ell + 1},{4/3,ell - 2}},ell,y,1/2,"ObservablePower"->-1/2,"Method"->"Lagrange"];
  r2=InversePowerLog[1,3,{{2/3,ell + 1},{4/3,ell - 2}},ell,y,1/2,"ObservablePower"->-1/2,"Method"->"FixedPoint"];
  FullSimplify[r1["Expression"]-r2["Expression"],y>0]],
 0, TestID -> "fixture-19-observable"]
