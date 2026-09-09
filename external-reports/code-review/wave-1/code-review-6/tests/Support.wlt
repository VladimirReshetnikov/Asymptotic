(* Tests of the supplied proposed helpers; native execution pending. *)
VerificationTest[
 AsymptoticAudit`DenseSeriesPlan[{{0,1},{1/10^9,1}},{1,0}]["DenseCoefficientCount"],
 10^9,TestID->"support-dense-span-without-allocation"]
VerificationTest[
 AsymptoticAudit`DenseSeriesPlan[{{0,1}},{1,1}]["Reason"],
 "LogarithmicRemainder",TestID->"support-log-tail-rejection"]
VerificationTest[
 AsymptoticAudit`RequiredProductPrecision[0,-100,5]["LeftErrorExponentAtLeast"],
 105,TestID->"support-product-demand"]
VerificationTest[
 Module[{x,y,s,c},s=AsymptoticInverse`AsymptoticInverse[x+x^2,{x,0},{y,4}];
  c=AsymptoticAudit`InverseCoefficientForPower[s,{1},"Power"->2];
  {c["Exponent"],c["Coefficient"]}],
 {3,-2},TestID->"support-explicit-power-helper"]
