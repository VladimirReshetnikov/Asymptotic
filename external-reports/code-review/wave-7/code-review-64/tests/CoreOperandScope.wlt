(* Desired-contract regressions: UNRUN. Wolfram MUnit file, not Mathics evidence.
   Load the pinned original/patched package before TestReport on this file. *)
Clear[reviewX,reviewY];
VerificationTest[
 MatchQ[AsymptoticAnalysis`AsymptoticCoreInverse[
   1/reviewX+Abs[reviewY]/2,-Abs[reviewY]/2,{reviewX,0},{reviewY,2}],
   Failure["InvalidVariables",_Association]],True,
 TestID->"N01-moving-linear-rejected"]
VerificationTest[
 MatchQ[AsymptoticAnalysis`AsymptoticCoreInverse[
   1/reviewX+Sqrt[Abs[reviewY]],-Sqrt[Abs[reviewY]],{reviewX,0},{reviewY,2}],
   Failure["InvalidVariables",_Association]],True,
 TestID->"N01-moving-small-rejected"]
VerificationTest[
 Head[AsymptoticAnalysis`AsymptoticCoreInverse[
   1/reviewX+2,-2,{reviewX,0},{reviewY,2}]],
 AsymptoticAnalysis`GeneralizedSeries,TestID->"N01-fixed-control-retained"]
VerificationTest[
 Simplify[Normal[AsymptoticAnalysis`AsymptoticCoreInverse[
   1/reviewX,0,{reviewX,0},{reviewY,2}]]-1/reviewY],0,
 TestID->"N01-zero-control-exact"]
VerificationTest[
 MatchQ[AsymptoticAnalysis`AsymptoticCoreInverse[
   1/reviewX+0.5,-0.5,{reviewX,0},{reviewY,2}],
   Failure["InexactInput",_Association]],True,
 TestID->"N01-inexact-operand-not-erased"]
