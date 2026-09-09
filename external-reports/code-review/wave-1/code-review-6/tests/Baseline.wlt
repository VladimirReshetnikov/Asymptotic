(* Native integration tests. NOT EXECUTED during the audit. *)
VerificationTest[
 Module[{x, y, s}, s = AsymptoticInverse`AsymptoticInverse[x+x^2,{x,0},{y,4}];
  Expand[Normal[s]-(y-y^2+2 y^3)]], 0, TestID->"baseline-algebraic-inverse"]
VerificationTest[
 Module[{x,y,s}, s=AsymptoticInverse`AsymptoticInverse[x+x^2 Log[x],{x,0},{y,4}];
  Expand[Normal[s]-(y-y^2 Log[y]+y^3 (2 Log[y]^2+Log[y]))]],
 0, TestID->"baseline-logarithmic-inverse"]
VerificationTest[
 Module[{x,y,s}, s=AsymptoticInverse`AsymptoticInverse[x+x^2,{x,0},{y,4}];
  AsymptoticInverse`InverseResidual[s]["ZeroBelowCutoff"]],
 True, TestID->"baseline-formal-residual"]
VerificationTest[
 Module[{x,m,c},m=AsymptoticInverse`PowerLogModel[x+x^2,{x,0}];
  c=AsymptoticInverse`InverseExpansionCoefficient[m,{1},"Power"->2];
  {c["Exponent"],c["Coefficient"]}],
 {3,-2}, TestID->"baseline-model-power-two"]
VerificationTest[
 Module[{x,s},s=AsymptoticInverse`AsymptoticExpansion[1+x Log[x],{x,0,1}];
  {s["RemainderPower"],s["RemainderLogDegree"]}],
 {1,1}, TestID->"baseline-rich-log-remainder"]
VerificationTest[
 Module[{x,y,s,c},s=AsymptoticInverse`AsymptoticInverse[x+x^2,{x,0},{y,4}];
  c=AsymptoticInverse`InverseCertificate[s,1/10,"Interval"->{1/20,1/5}];
  AssociationQ[c] && TrueQ[c["Certified"]] &&
   TrueQ[c["CertifiesInputRemainderFamily"]===False]],
 True, TestID->"baseline-explicit-function-certificate"]
