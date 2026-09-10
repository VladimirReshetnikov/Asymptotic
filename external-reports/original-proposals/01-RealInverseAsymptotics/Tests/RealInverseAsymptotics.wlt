(* Wolfram Language regression suite. Supplied for execution in a real kernel.
   It was NOT executed during preparation: see verification/STATUS.md. *)
Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],
  "Kernel", "RealInverseAsymptotics.wl"}]];
ClearAll[x,y,a,b,eps,eqTest];
eqTest[r_,e_,ass_:True] := Head[r] === InverseExpansion &&
 TrueQ[FullSimplify[Normal[r] == e, y > 0 && ass]];

VerificationTest[
 eqTest[RealInverseAsymptotic[x+x^2(1+Log[x]),{x,0},{y,6}],
  y-y^2(1+Log[y])+y^3(2 Log[y]^2+5 Log[y]+3)
  -y^4(5 Log[y]^3+41 Log[y]^2/2+27 Log[y]+23/2)
  +y^5(14 Log[y]^4+241 Log[y]^3/3+335 Log[y]^2/2+151 Log[y]+299/6)],
 True,TestID->"logarithmic-example-five-blocks"]
VerificationTest[
 RealInverseAsymptotic[x+x^2(1+Log[x]),{x,0},{y,6}]["Remainder"],
 PowerLogRemainder[y,6,5],TestID->"logarithmic-remainder"]
VerificationTest[
 InverseResidual[RealInverseAsymptotic[x+x^2(1+Log[x]),{x,0},{y,7}]]["ZeroBelowCutoff"],
 True,TestID->"logarithmic-independent-residual"]
VerificationTest[
 eqTest[RealInverseAsymptotic[x+x^Sqrt[2],{x,0},{y,4 Sqrt[2]-3}],
 y-y^Sqrt[2]+Sqrt[2] y^(2 Sqrt[2]-1)-(6-Sqrt[2])/2 y^(3 Sqrt[2]-2)],
 True,TestID->"irrational-example-from-question"]
VerificationTest[
 TrueQ[FullSimplify[RealInverseAsymptotic[x+x^Sqrt[2],{x,0},{y,4 Sqrt[2]-3}]["RemainderPower"] == 4 Sqrt[2]-3]],
 True,TestID->"irrational-remainder-exponent"]
VerificationTest[
 InverseResidual[RealInverseAsymptotic[x+x^Sqrt[2],{x,0},{y,3}]]["ZeroBelowCutoff"],
 True,TestID->"irrational-independent-residual"]
VerificationTest[
 eqTest[RealInverseAsymptotic[3 x^2+3 x^3(1+Log[x]),{x,0},{y,2}],
 Sqrt[y/3]-(y/3)(1+Log[y/3]/2)/2
 +(y/3)^(3/2)(5 (Log[y/3]/2)^2+12 Log[y/3]/2+7)/8],
 True,TestID->"nonunit-leading-power"]
VerificationTest[
 InverseResidual[RealInverseAsymptotic[3 x^2+3 x^3(1+Log[x]),{x,0},{y,5/2}]]["ZeroBelowCutoff"],
 True,TestID->"nonunit-leading-residual"]
VerificationTest[
 eqTest[RealInverseAsymptotic[5 x^(3/2),{x,0},{y,3}],(y/5)^(2/3)],
 True,TestID->"pure-monomial"]
VerificationTest[
 RealInverseAsymptotic[5 x^(3/2),{x,0},{y,3}]["Remainder"],
 0,TestID->"pure-monomial-exact"]
VerificationTest[
 InverseResidual[RealInverseAsymptotic[5 x^(3/2),{x,0},{y,3}]]["ZeroBelowCutoff"],
 True,TestID->"pure-monomial-residual"]
VerificationTest[
 eqTest[RealInverseAsymptotic[x+x^2,{x,0},{y,6}],y-y^2+2 y^3-5 y^4+14 y^5],
 True,TestID->"ordinary-Catalan-reversion"]
VerificationTest[
 FullSimplify[Coefficient[Normal[RealInverseAsymptotic[x+x^2+x^3,{x,0},{y,6}]],y,4]],
 0,TestID->"resonance-cancellation"]
VerificationTest[
 InverseResidual[RealInverseAsymptotic[x+x^2+x^3,{x,0},{y,7}]]["ZeroBelowCutoff"],
 True,TestID->"resonant-independent-residual"]
VerificationTest[
 InverseResidual[RealInverseAsymptotic[x+x^Sqrt[2](1+Log[x])+2 x^Sqrt[3],{x,0},{y,3}]]["ZeroBelowCutoff"],
 True,TestID->"mixed-irrational-and-logarithmic-blocks"]
VerificationTest[
 eqTest[RealInverseAsymptotic[a x+b x^2,{x,0},{y,4},Assumptions->a>0 && Element[b,Reals]],
 y/a-(b/a)(y/a)^2+2 (b/a)^2(y/a)^3,a>0 && Element[b,Reals]],
 True,TestID->"symbolic-real-coefficients"]
VerificationTest[
 eqTest[RealInverseAsymptotic[x+x^2,{x,0},{y,3/2}],y],
 True,TestID->"cutoff-between-support-points"]
VerificationTest[
 RealInverseAsymptotic[x+x^2,{x,0},{y,3/2}]["Remainder"],
 PowerLogRemainder[y,2,0],TestID->"next-support-not-arbitrary-cutoff"]
VerificationTest[
 RealInverseAsymptotic[x+x^2,{x,0},{y,3},InputRemainder->{3,0}]["Remainder"],
 PowerLogRemainder[y,3,0],TestID->"forward-jet-precision"]
VerificationTest[
 RealInverseAsymptotic[x+x^2(1+Log[x]),{x,0},{y,3},InputRemainder->{3,4}]["Remainder"],
 PowerLogRemainder[y,3,4],TestID->"logarithmic-forward-precision"]
VerificationTest[
 Head[RealInverseAsymptotic[x+x^2,{x,0},{y,4},InputRemainder->{3,0}]],
 Failure,TestID->"insufficient-input-order-rejected"]
VerificationTest[
 Head[RealInverseAsymptotic[x+x^2,{x,0},{y,3},InputRemainder->{2,0}]],
 Failure,TestID->"invalid-input-remainder-rejected"]
VerificationTest[
 Head[RealInverseAsymptotic[x+x^1.5,{x,0},{y,3}]],
 Failure,TestID->"inexact-input-rejected"]
VerificationTest[
 Head[RealInverseAsymptotic[-x+x^2,{x,0},{y,3}]],
 Failure,TestID->"negative-leading-coefficient-rejected"]
VerificationTest[
 Head[RealInverseAsymptotic[x Log[x]+x^2,{x,0},{y,3}]],
 Failure,TestID->"leading-logarithm-rejected"]
VerificationTest[
 Head[RealInverseAsymptotic[Exp[x]-1,{x,0},{y,3}]],
 Failure,TestID->"nonfinite-input-rejected"]
VerificationTest[
 Head[RealInverseAsymptotic[x+x^a,{x,0},{y,3},Assumptions->a>1]],
 Failure,TestID->"symbolic-exponent-rejected"]
VerificationTest[
 Head[RealInverseAsymptotic[x+I x^2,{x,0},{y,3}]],
 Failure,TestID->"complex-coefficient-rejected"]
VerificationTest[
 Head[RealInverseAsymptotic[a x+x^2,{x,0},{y,3}]],
 Failure,TestID->"unproved-coefficient-sign-rejected"]
VerificationTest[
 Head[RealInverseAsymptotic[x+x^2,{x,0},{x,3}]],
 Failure,TestID->"same-source-target-rejected"]
VerificationTest[
 Head[RealInverseAsymptotic[x+x^2,{x,0},{y,1}]],
 Failure,TestID->"leading-term-cutoff-rejected"]
VerificationTest[
 Head[RealInverseAsymptotic[x+x^2,{x,0},{y,10},MaxMultiIndices->1]],
 Failure,TestID->"resource-limit-is-failure-not-partial-answer"]
VerificationTest[
 TrueQ[FullSimplify[
  InverseResidual[RealInverseAsymptotic[x+x^2(1+Log[x]),{x,0},{y,3}],3]["NormalizedResidual"]
   ==-y^2(2 Log[y]^2+5 Log[y]+3),y>0]],
 True,TestID->"first-omitted-residual"]
VerificationTest[
 TrueQ[FullSimplify[
  PerturbativeInverse[x^2(1+Log[x]),{x},{y,2},eps]
   ==y-eps y^2(1+Log[y])+eps^2 y^3(2 Log[y]^2+5 Log[y]+3),y>0]],
 True,TestID->"homotopy-marker-polynomial"]
VerificationTest[
 PerturbativeInverse[x^2,{x},{y,0},eps],y,TestID->"zero-homotopy-order"]
VerificationTest[
 Head[PerturbativeInverse[x^2+eps,{x},{y,2},eps]],
 Failure,TestID->"marker-already-in-perturbation-rejected"]
