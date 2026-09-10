(* Native Wolfram Language regression suite. Not executed in the build environment.
   Load the package before TestReport["Tests/RealInverseSeries.wlt"]. *)
Clear[x,y,z,a,eps];

VerificationTest[
 RealInverseSeries[x+x^2(1+Log[x]),{x,y},3]["Expansion"] // Expand,
 y-y^2-y^2 Log[y], TestID->"log-two-blocks"]

VerificationTest[
 RealInverseSeries[x+x^2(1+Log[x]),{x,y},3]["Remainder"]["Power"],
 3, TestID->"log-remainder-power"]

VerificationTest[
 RealInverseSeries[x+x^2(1+Log[x]),{x,y},3]["Remainder"]["LogDegree"],
 2, TestID->"log-remainder-needs-two-log-powers"]

VerificationTest[
 Expand[RealInverseSeries[x+x^2(1+Log[x]),{x,y},5]["Expansion"]-
 (y-y^2(1+Log[y])+y^3(2 Log[y]^2+5 Log[y]+3)-
 y^4(5 Log[y]^3+41 Log[y]^2/2+27 Log[y]+23/2))],
 0, TestID->"four-log-blocks"]

VerificationTest[
 FullSimplify[RealInverseSeries[x+x^Sqrt[2],{x,z},4 Sqrt[2]-3]["Expansion"]-
 (z-z^Sqrt[2]+Sqrt[2] z^(2 Sqrt[2]-1)-(6-Sqrt[2])/2 z^(3 Sqrt[2]-2)),z>0],
 0, TestID->"irrational-question"]

VerificationTest[
 RealInverseSeries[x+x^Sqrt[2],{x,z},4 Sqrt[2]-3]["Remainder"]["Power"],
 4 Sqrt[2]-3, TestID->"exact-irrational-cutoff-boundary"]

VerificationTest[
 RealInverseSeries[x+x^Sqrt[2],{x,z},4 Sqrt[2]-3]["IndexCount"],
 4, TestID->"four-irrational-indices"]

VerificationTest[
 RealInverseSeries[x+x^Sqrt[2]+x^2(1+Log[x]),{x,y},3]["IndexCount"],
 8, TestID->"mixed-weight-not-total-degree"]

VerificationTest[
 RealInverseSeries[x+x^Sqrt[2]+x^2(1+Log[x]),{x,y},3]["Remainder"]["LogDegree"],
 2, TestID->"mixed-border-log-degree"]

VerificationTest[
 Expand[RealInverseSeries[x+x^(3/2)+x^2,{x,y},5/2]["Expansion"]-
 (y-y^(3/2)+y^2/2)],0,TestID->"resonance-merges-multi-indices"]

VerificationTest[
 RealInverseSeries[3 x^2,{x,y},2]["Expansion"],
 Sqrt[y/3],TestID->"pure-monomial"]

VerificationTest[
 RealInverseSeries[3 x^2,{x,y},2]["Remainder"]["Scale"],
 0,TestID->"pure-monomial-exact"]

VerificationTest[
 RealInverseSeries[3 x^2(1+Sqrt[x](1+Log[x])+2x),{x,y},7/4]["FormalResidualZero"],
 True,TestID->"nonunit-core-residual"]

VerificationTest[
 FullSimplify[
 RealInverseSeries[3 x^2(1+Sqrt[x](1+Log[x])+2x),{x,y},7/4]["Expansion"]-
 RealInverseSeries[3 x^2(1+Sqrt[x](1+Log[x])+2x),{x,y},7/4,Method->"Newton"]["Expansion"],y>0],
 0,TestID->"nonunit-newton-lagrange"]

VerificationTest[
 Expand[RealInverseSeries[x+x^2(1+Log[x]),{x,y},6]["Expansion"]-
 RealInverseSeries[x+x^2(1+Log[x]),{x,y},6,Method->"Newton"]["Expansion"]],
 0,TestID->"log-newton-lagrange"]

VerificationTest[
 InverseResidual[RealInverseSeries[x+x^2(1+Log[x]),{x,y},5]]["ZeroBelowCutoff"],
 True,TestID->"default-residual"]

VerificationTest[
 InverseResidual[RealInverseSeries[x+x^2(1+Log[x]),{x,y},3],4]["ZeroBelowCutoff"],
 False,TestID->"next-residual-is-visible"]

VerificationTest[
 Expand[InverseResidual[RealInverseSeries[x+x^2(1+Log[x]),{x,y},3],4]["Expansion"]+
 y^3(2 Log[y]^2+5 Log[y]+3)],
 0,TestID->"next-residual-coefficient-sign"]

VerificationTest[
 RealInverseSeries[x+x^2(1+Log[x]),{x,y},4,"InputRemainder"->{4,0}]["Remainder"]["LogDegree"],
 3,TestID->"combine-equal-power-remainders"]

VerificationTest[
 MatchQ[RealInverseSeries[x+x^2,{x,y},5,"InputRemainder"->{4,0}],_Failure],
 True,TestID->"no-overclaim-from-input-remainder"]

VerificationTest[
 Expand[RealInverseSeries[x+a x^(3/2),{x,y},5/2,Assumptions->Element[a,Reals]]["Expansion"]-
 (y-a y^(3/2)+3 a^2 y^2/2)],
 0,TestID->"symbolic-real-coefficient"]

VerificationTest[
 MatchQ[RealInverseSeries[x+a x^(3/2),{x,y},5/2],_Failure],
 True,TestID->"unproved-coefficient-reality"]

VerificationTest[
 MatchQ[RealInverseSeries[-x Log[x],{x,y},3],_Failure],
 True,TestID->"unsupported-logarithmic-core"]

VerificationTest[
 MatchQ[RealInverseSeries[x+Exp[-1/x],{x,y},3],_Failure],
 True,TestID->"unsupported-flat-function"]

VerificationTest[
 MatchQ[RealInverseSeries[x+x^1.5,{x,y},3],_Failure],
 True,TestID->"reject-inexact-exponent"]

VerificationTest[
 MatchQ[RealInverseSeries[-x+x^2,{x,y},3],_Failure],
 True,TestID->"reject-negative-core"]

VerificationTest[
 MatchQ[RealInverseSeries[1+x,{x,y},3],_Failure],
 True,TestID->"reject-nonzero-endpoint"]

VerificationTest[
 MatchQ[RealInverseSeries[x+x^2,{x,y},3,"MaxIndices"->1],_Failure],
 True,TestID->"index-resource-limit"]

VerificationTest[
 MatchQ[RealInverseSeries[x+x^2,{x,y},1],_Failure],
 True,TestID->"cutoff-must-include-leading-block"]

VerificationTest[
 MatchQ[RealInverseSeries[x+x^2,{x,x},3],_Failure],
 True,TestID->"distinct-variables"]

VerificationTest[
 Expand[PerturbativeInverse[y,x^2(1+Log[x]),{x,y,eps},2]-
 (y-eps y^2(1+Log[y])+eps^2 y^3(2 Log[y]^2+5 Log[y]+3))],
 0,TestID->"auxiliary-parameter-operator"]

VerificationTest[
 PerturbativeInverse[y,x^2,{x,y,eps},0],y,
 TestID->"zero-perturbation-order"]

VerificationTest[
 MatchQ[RealInverseSeries[x+y x^2,{x,y},3,Assumptions->y>0],_Failure],
 True,TestID->"output-variable-is-not-a-coefficient"]
