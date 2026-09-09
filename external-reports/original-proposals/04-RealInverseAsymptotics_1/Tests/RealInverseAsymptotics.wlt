(* Wolfram MUnit regression suite. Run with Tests/RunTests.wls.
   Supplied for execution in a Wolfram kernel; see validation status in README. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "RealInverseAsymptotics.wl"}]];
Clear[x, y, a, p];

VerificationTest[
 Expand[RealInverseAsymptotic[x+x^2(1+Log[x]), {x,0}, {y,4}]["Expression"]],
 y-y^2(1+Log[y])+y^3(3+5 Log[y]+2 Log[y]^2) // Expand,
 TestID -> "log-first-three-blocks"]

VerificationTest[
 RealInverseAsymptotic[x+x^2(1+Log[x]),{x,0},{y,3}]["Remainder"],
 PowerLogO[y,3,2], TestID -> "log-aware-remainder"]

VerificationTest[
 Expand[RealInverseAsymptotic[x+x^2(1+Log[x]),{x,0},{y,3}]["BoundaryTerm"]],
 Expand[y^3(3+5 Log[y]+2 Log[y]^2)], TestID -> "first-omitted-polynomial"]

VerificationTest[
 Expand[RealInverseAsymptotic[x+x^2(1+Log[x]),{x,0},{y,5}]["Expression"]],
 Expand[y-y^2(1+Log[y])+y^3(3+5 Log[y]+2 Log[y]^2)
  -y^4(23/2+27 Log[y]+41 Log[y]^2/2+5 Log[y]^3)],
 TestID -> "fourth-logarithmic-block"]

VerificationTest[
 FullSimplify[RealInverseAsymptotic[x+x^Sqrt[2],{x,0},{y,4 Sqrt[2]-3}]["Expression"]
  -(y-y^Sqrt[2]+Sqrt[2] y^(2 Sqrt[2]-1)
  -(6-Sqrt[2]) y^(3 Sqrt[2]-2)/2),y>0],
 0,TestID -> "irrational-question-example"]

VerificationTest[
 FullSimplify[RealInverseAsymptotic[x+x^Sqrt[2],{x,0},{y,4 Sqrt[2]-3}]["RemainderPower"]
  -(4 Sqrt[2]-3)],0,TestID -> "exact-irrational-cutoff"]

VerificationTest[
 RealInverseAsymptotic[x+x^Sqrt[2],{x,0},{y,4 Sqrt[2]-3}]["RemainderLogDegree"],
 0,TestID -> "pure-power-remainder"]

VerificationTest[
 FullSimplify[RealInverseAsymptotic[4 x^2(1+x(1+Log[x])),{x,0},{y,3/2}]["Expression"]
  -(Sqrt[y]/2-y(1+Log[y]/2-Log[2])/8),y>0],
 0,TestID -> "nonunit-leading-monomial"]

VerificationTest[
 FullSimplify[RealInverseAsymptotic[8 x^(3/2),{x,0},{y,2}]["Expression"]
  -(y/8)^(2/3),y>0],0,TestID -> "exact-monomial"]

VerificationTest[
 RealInverseAsymptotic[8 x^(3/2),{x,0},{y,2}]["Exact"],
 True,TestID -> "exact-monomial-flag"]

VerificationTest[
 Expand[RealInverseAsymptotic[x+x^2+2 x^3,{x,0},{y,5}]["Expression"]],
 y-y^2+5 y^4,TestID -> "resonant-cancellation"]

VerificationTest[
 {RealInverseAsymptotic[x+x^2+2 x^3,{x,0},{y,3}]["BoundaryTerm"],
  RealInverseAsymptotic[x+x^2+2 x^3,{x,0},{y,3}]["RemainderPower"]},
 {0,3},TestID -> "zero-boundary-is-not-exactness"]

VerificationTest[
 RealInverseAsymptotic[x+x^2,{x,0},{y,1/2}]["Expression"],
 0,TestID -> "cutoff-before-leading-term"]

VerificationTest[
 RealInverseAsymptotic[x+x^2,{x,0},{y,1}]["BoundaryTerm"],
 y,TestID -> "strict-cutoff-at-leading-term"]

VerificationTest[
 FullSimplify[RealInverseAsymptotic[a x+a x^2,{x,0},{y,3},Assumptions->a>0]["Expression"]
  -(y/a-y^2/a^2),a>0&&y>0],0,TestID -> "symbolic-positive-coefficient"]

VerificationTest[
 CheckInverseAsymptotic[RealInverseAsymptotic[x+x^2(1+Log[x]),{x,0},{y,6}]]["Passed"],
 True,TestID -> "independent-log-composition"]

VerificationTest[
 CheckInverseAsymptotic[RealInverseAsymptotic[x+x^Sqrt[2],{x,0},{y,5/2}]]["Passed"],
 True,TestID -> "independent-irrational-composition"]

VerificationTest[
 CheckInverseAsymptotic[RealInverseAsymptotic[x+x^Sqrt[2]+x^Sqrt[3],{x,0},{y,5/2}]]["Passed"],
 True,TestID -> "two-independent-irrational-generators"]

VerificationTest[
 CheckInverseAsymptotic[RealInverseAsymptotic[4 x^2(1+x(1+Log[x])),{x,0},{y,5/2}]]["Passed"],
 True,TestID -> "general-alpha-composition"]

VerificationTest[
 Module[{r=RealInverseAsymptotic[x+x^2(1+Log[x]),{x,0},{y,4}]},
  CheckInverseAsymptotic[Join[r,<|"Expression"->r["Expression"]+y^2|>]]["Passed"]],
 False,TestID -> "checker-detects-corruption"]

VerificationTest[
 Expand[PowerLogCompose[Log[x],x,y+y^2,{y,4}]["Expression"]],
 Log[y]+y-y^2/2+y^3/3,TestID -> "log-of-unit-composition"]

VerificationTest[
 Expand[PowerLogCompose[Log[x]^2,x,y+y^2,{y,3}]["Expression"]],
 Expand[Log[y]^2+2 y Log[y]+y^2(1-Log[y])],TestID -> "polynomial-log-composition"]

VerificationTest[
 FullSimplify[PowerLogCompose[x^Sqrt[2],x,y+y^2,{y,Sqrt[2]+3}]["Expression"]
  -y^Sqrt[2](1+Sqrt[2] y+Sqrt[2](Sqrt[2]-1)y^2/2),y>0],
 0,TestID -> "irrational-binomial-composition"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x+x^1.4,{x,0},{y,3}],_Failure],
 True,TestID -> "reject-inexact-exponent"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x+x^2,{x,0},{y,3.}],_Failure],
 True,TestID -> "reject-inexact-cutoff"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x+x^p,{x,0},{y,3},Assumptions->p>1],_Failure],
 True,TestID -> "symbolic-exponents-require-specialization"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[-x+x^2,{x,0},{y,3}],_Failure],
 True,TestID -> "reject-negative-leading-coefficient"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x Log[x],{x,0},{y,3}],_Failure],
 True,TestID -> "reject-logarithmic-leading-scale"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x+Exp[-1/x],{x,0},{y,3}],_Failure],
 True,TestID -> "reject-unsupported-exponential-sector"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x+x^2 Log[2 x],{x,0},{y,3}],_Failure],
 True,TestID -> "do-not-rewrite-logs-without-normalization"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x+I x^2,{x,0},{y,3}],_Failure],
 True,TestID -> "reject-complex-coefficients"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x+x^2,{x,0},{y,5},"MaxOrder"->1],_Failure],
 True,TestID -> "explicit-order-budget"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x+x^2,{x,0},{y,3},"MaxTerms"->1],_Failure],
 True,TestID -> "explicit-term-budget"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[x+y x^2,{x,0},{y,3}],_Failure],
 True,TestID -> "target-variable-collision"]

VerificationTest[
 MatchQ[RealInverseAsymptotic[0,{x,0},{y,3}],_Failure],
 True,TestID -> "reject-zero-germ"]
