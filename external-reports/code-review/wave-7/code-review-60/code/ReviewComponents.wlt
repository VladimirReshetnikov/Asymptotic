(* Desired post-patch acceptance. The complete file was NOT run in this audit.
   Load the selected AsymptoticAnalysis entry in a fresh kernel before TestReport.
   Public names are explicitly qualified to avoid binding them before Get. *)

VerificationTest[
 Module[{x,y,s}, s=AsymptoticAnalysis`AsymptoticCoreInverse[
   x-Re[y],Re[y]+1/x,{x,Infinity},{y,2}];
   MatchQ[s,Failure["InvalidVariables",_Association]]],
 True,TestID->"CV01-cancelled-target-large"]

VerificationTest[
 Module[{x,y,s}, s=AsymptoticAnalysis`AsymptoticCoreInverse[
   x-Abs[y],Abs[y]+1/x,{x,Infinity},{y,2}];
   MatchQ[s,Failure["InvalidVariables",_Association]]],
 True,TestID->"CV02-cancelled-target-abs"]

VerificationTest[
 Module[{x,y,s}, s=AsymptoticAnalysis`AsymptoticCoreInverse[
   1/x-Re[y],Re[y]+x,{x,0},{y,2}];
   MatchQ[s,Failure["InvalidVariables",_Association]]],
 True,TestID->"CV03-cancelled-target-small"]

VerificationTest[
 Module[{x,y,s}, s=AsymptoticAnalysis`AsymptoticCoreInverse[
   x-y,y+1/x,{x,Infinity},{y,2}];
   MatchQ[s,Failure["InvalidVariables",_Association]]],
 True,TestID->"CV04-dependency-precedes-coefficient-realness"]

VerificationTest[
 Module[{x,y,s}, s=AsymptoticAnalysis`AsymptoticCoreInverse[
   x-Re[y],1/x,{x,Infinity},{y,2}];
   MatchQ[s,Failure["InvalidVariables",_Association]]],
 True,TestID->"CV05-target-in-core-only"]

VerificationTest[
 Module[{x,y,s}, s=AsymptoticAnalysis`AsymptoticCoreInverse[
   x,Re[y]+1/x,{x,Infinity},{y,2}];
   MatchQ[s,Failure["InvalidVariables",_Association]]],
 True,TestID->"CV06-target-in-perturbation-only"]

VerificationTest[
 Module[{x,s}, s=AsymptoticAnalysis`AsymptoticCoreInverse[
   x,1/x,{x,Infinity},{x,2}];
   MatchQ[s,Failure["InvalidVariables",_Association]]],
 True,TestID->"CV07-identical-variables"]

VerificationTest[
 Module[{x,y,s}, s=AsymptoticAnalysis`AsymptoticCoreInverse[x,1/x,{x,Infinity},{y,2}];
   Head[s]===AsymptoticAnalysis`GeneralizedSeries &&
   Together[Normal[s]-(y-1/y-1/y^3)]===0 &&
   Together[s["RemainderScaleExpression"]-1/y^5]===0],
 True,TestID->"CV08-unshifted-exact-control"]

VerificationTest[
 Module[{x,y,s}, s=AsymptoticAnalysis`AsymptoticCoreInverse[x,x^2,{x,0},{y,2}];
   Head[s]===AsymptoticAnalysis`GeneralizedSeries &&
   Together[Normal[s]-(y-y^2+2y^3)]===0],
 True,TestID->"CV09-finite-endpoint-control"]

VerificationTest[
 Module[{x,y,s}, s=AsymptoticAnalysis`AsymptoticCoreInverse[
   x-1,1+1/x,{x,Infinity},{y,2},"CoreInverse"->y+1];
   Head[s]===AsymptoticAnalysis`GeneralizedSeries &&
   Together[Normal[s]-(y-1/(y+1)-1/(y+1)^2-1/(y+1)^3)]===0 &&
   Together[s["RemainderScaleExpression"]-1/(y+1)^2]===0],
 True,TestID->"CV10-legitimate-target-dependent-inverse-option"]

VerificationTest[
 Module[{x,y,a,s}, s=AsymptoticAnalysis`AsymptoticCoreInverse[
   a x,x^2,{x,0},{y,2},Assumptions->a>0];
   Head[s]===AsymptoticAnalysis`GeneralizedSeries &&
   Together[Normal[s]-(y/a-y^2/a^3+2y^3/a^5)]===0],
 True,TestID->"CV11-fixed-real-parameter"]

VerificationTest[
 Module[{x,y,s}, s=AsymptoticAnalysis`AsymptoticCoreInverse[
   x+0.1,-0.1+1/x,{x,Infinity},{y,1}];
   MatchQ[s,Failure["InexactInput",_Association]]],
 True,TestID->"CV12-inexact-input-remains-refused"]
