(* Tests of the supplied prototypes, after loading upstream and AuditExtensions.wl.
   Native-unexecuted during this audit. Upstream is not modified by this file. *)
VerificationTest[
 Module[{outer,inner},
  outer=AsymptoticInverse`AsymptoticExpansion[1/(1+x/a),{x,0,1},Assumptions->a>0];
  inner=AsymptoticInverse`AsymptoticExpansion[a,{a,0,2}];
  MatchQ[AsymptoticAudit`ParameterSafeCompose[outer,inner],Failure["ParameterCapture",_Association]]],
 True, TestID->"N01-reject-fixed-parameter-capture"]

VerificationTest[
 Module[{outer,inner,result},
  outer=AsymptoticInverse`AsymptoticExpansion[1/(1+x/a),{x,0,1},Assumptions->a>0];
  inner=AsymptoticInverse`AsymptoticExpansion[t,{t,0,2}];
  result=AsymptoticAudit`ParameterSafeCompose[outer,inner];
  MatchQ[result,_AsymptoticInverse`GeneralizedSeries] && Normal[result]===1],
 True, TestID->"N01-independent-inner-variable-control"]

VerificationTest[
 Module[{A=2^10000+1},
  AsymptoticAudit`RationalAffineRange[x-A-1/2,x,{A+1/2,A+1/2}]],
 {0,0}, TestID->"N02-exact-translated-center"]

VerificationTest[
 Module[{A=2^10000+1},
  AsymptoticAudit`RationalAffineRange[3(x-A)-1,x,{A+1/4,A+3/4}]],
 {-1/4,5/4}, TestID->"N02-affine-tree-with-factored-translation"]

VerificationTest[
 AsymptoticAudit`RationalAffineRange[x^2,x,{-1,1}],
 $Failed, TestID->"N02-conservative-nonlinear-fallback"]

VerificationTest[
 MatchQ[AsymptoticAudit`CheckedFourierInverse[x+x^2,{x,0},{y,4},SeriesTermGoal->1],
  Failure["UnsupportedOption",_Association]],
 True, TestID->"N04-explicit-term-goal-rejected"]

VerificationTest[
 MatchQ[AsymptoticAudit`CheckedFourierInverse[x+x^2,{x,0},{y,4},SeriesTermGoal->"invalid"],
  Failure["UnsupportedOption",_Association]],
 True, TestID->"N04-invalid-inherited-option-not-ignored"]

VerificationTest[
 MatchQ[AsymptoticAudit`CheckedFourierInverse[x+x^2,{x,0},{y,4}],
  _AsymptoticInverse`GeneralizedSeries],
 True, TestID->"N04-supported-cutoff-control"]

VerificationTest[
 Module[{s,r},
  s=AsymptoticInverse`AsymptoticExpansion[Zeta[x],{x,Infinity,Log[4]}];
  r=AsymptoticAudit`BoundPreservingTruncate[s,Log[5]];
  MatchQ[r,_AsymptoticInverse`GeneralizedSeries] &&
   TrueQ[FullSimplify[Normal[r]==Normal[s],x>1]] &&
   r["AbsoluteRemainderBound"]===s["AbsoluteRemainderBound"]],
 True, TestID->"N05-noop-preserves-quantitative-bound"]

VerificationTest[
 Module[{s,r},
  s=AsymptoticInverse`AsymptoticExpansion[Zeta[x],{x,Infinity,Log[6]}];
  r=AsymptoticAudit`BoundPreservingTruncate[s,Log[3]];
  MatchQ[r,_AsymptoticInverse`GeneralizedSeries] &&
   TrueQ[FullSimplify[r["AbsoluteRemainderBound"] == s["AbsoluteRemainderBound"]+
     Abs[Normal[s]-Normal[r]], x>1]]],
 True, TestID->"N05-transport-discarded-finite-terms"]
