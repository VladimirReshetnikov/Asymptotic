(* DESIRED CONTRACT TESTS -- NOT EXECUTED IN THIS REVIEW.
   Load the patched canonical package, then ReviewAdditions.wl, in a fresh kernel.
   These tests deliberately do not count as package acceptance evidence. *)
VerificationTest[
  Module[{x,y,s},
    s = AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
      Exp[x],1,{x,Infinity},{y,0},"SourceShift" -> -Abs[y]];
    MatchQ[s, Failure["TargetDependentSourceShift",_Association]]],
  True, TestID -> "reject-target-dependent-source-shift-abs"]
VerificationTest[
  Module[{x,y,s},
    s = AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
      Exp[x],1,{x,Infinity},{y,3},"SourceShift" -> -Re[y]];
    MatchQ[s, Failure["TargetDependentSourceShift",_Association]]],
  True, TestID -> "reject-target-dependent-source-shift-re"]
VerificationTest[
  Module[{x,y,s},
    s = AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
      Exp[x],1,{x,Infinity},{y,2},"SourceShift" -> -3];
    Head[s] === AsymptoticAnalysis`GeneralizedSeries &&
      TrueQ[FullSimplify[Normal[s] == Log[y]-1/y-1/(2 y^2), y>4]]],
  True, TestID -> "constant-source-shift-keeps-ordinary-corrections"]
VerificationTest[
  Module[{x,y,s},
    s = AsymptoticIncrementalReview`AbsorbConstantExponentialPerturbation[
      Exp[x],1,{x,Infinity},{y,3}];
    Head[s] === AsymptoticAnalysis`GeneralizedSeries && s["Remainder"] === 0 &&
      TrueQ[FullSimplify[Normal[s] == Log[y-1], y>4]]],
  True, TestID -> "opt-in-constant-absorption-is-exact"]
VerificationTest[
  AsymptoticIncrementalReview`RationalMomentTable[1/2,5],
  {2,2,6,26,150,1082}, TestID -> "exact-rational-moments-at-half"]
VerificationTest[
  AsymptoticIncrementalReview`RationalMomentTable[0,5],
  {1,0,0,0,0,0}, TestID -> "zeroth-moment-includes-n-zero"]
VerificationTest[
  AsymptoticIncrementalReview`RationalLerchCoefficients[1/2,-2,5],
  {2,4,6,0,0,0}, TestID -> "negative-integer-lerch-terminates"]
VerificationTest[
  MatchQ[AsymptoticIncrementalReview`RationalMomentTable[0.5,5], _Failure],
  True, TestID -> "rational-prototype-rejects-machine-real"]
