(* Load the patched package before TestReport["ReviewSourceShift.wlt"].
   These twelve MUnit cases are supplied acceptance tests, not an executed
   MUnit receipt. See evidence/native_observations.json for the smaller executed scope. *)
VerificationTest[
 Module[{x,y}, Head[AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
   Exp[x],1,{x,Infinity},{y,1},"SourceShift" -> -Abs[y]]]],
 Failure, TestID -> "source-shift-target-absolute-value-rejected"]
VerificationTest[
 Module[{x,y}, Head[AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
   Exp[x],1,{x,Infinity},{y,1},"SourceShift" -> Abs[y]]]],
 Failure, TestID -> "source-shift-positive-moving-chart-rejected"]
VerificationTest[
 Module[{x,y}, Head[AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
   Exp[x],1,{x,Infinity},{y,1},"SourceShift" -> -Log[1+Abs[y]]]]],
 Failure, TestID -> "source-shift-slow-moving-chart-rejected"]
VerificationTest[
 Module[{x,z}, Head[AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
   Exp[x],1,{x,Infinity},{z,1},"SourceShift" -> -Abs[z]]]],
 Failure, TestID -> "source-shift-target-alpha-renaming"]
VerificationTest[
 Module[{x,y}, Head[AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
   Exp[x],1,{x,Infinity},{y,1},"SourceShift" -> x]]],
 Failure, TestID -> "source-dependent-shift-stays-rejected"]
VerificationTest[
 Module[{x,y,s},s=AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
   Exp[x],1,{x,Infinity},{y,1}];
   FullSimplify[Normal[s]-(Log[y]-1/y),y>2]],
 0, TestID -> "source-shift-automatic-preserves-coefficients"]
VerificationTest[
 Module[{x,y,s},s=AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
   Exp[x],1,{x,Infinity},{y,1},"SourceShift" -> -3];
   FullSimplify[Normal[s]-(Log[y]-1/y),y>2]],
 0, TestID -> "source-shift-fixed-negative-preserves-coefficients"]
VerificationTest[
 Module[{x,y,s},s=AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
   Exp[x],1,{x,Infinity},{y,1},"SourceShift" -> 3];
   FullSimplify[Normal[s]-(Log[y]-1/y),y>Exp[4]]],
 0, TestID -> "source-shift-fixed-positive-preserves-coefficients"]
VerificationTest[
 Module[{x,y,b}, Head[AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
   Exp[x],1,{x,Infinity},{y,1},"SourceShift" -> b,Assumptions -> Element[b,Reals]]]],
 AsymptoticAnalysis`GeneralizedSeries, TestID -> "source-shift-fixed-parameter-accepted"]
VerificationTest[
 Module[{x,y,z}, Head[AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
   Exp[x],1,{x,Infinity},{z,1},"SourceShift" -> -Abs[y]]]],
 AsymptoticAnalysis`GeneralizedSeries, TestID -> "source-shift-parameter-named-y-is-not-the-target"]
VerificationTest[
 Module[{x,y}, Head[AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
   Exp[x],1,{x,Infinity},{y,1},"CoreInverse" -> Log[y]]]],
 AsymptoticAnalysis`GeneralizedSeries, TestID -> "core-inverse-target-dependence-preserved"]
VerificationTest[
 Module[{x,y,s},s=AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
   Exp[x],1,{x,Infinity},{y,1},"SourceShift" -> -3];
   FullSimplify[s["RemainderScaleExpression"] y^2,y>2]],
 Exp[-6], TestID -> "fixed-shift-remainder-changes-only-by-constant"]
