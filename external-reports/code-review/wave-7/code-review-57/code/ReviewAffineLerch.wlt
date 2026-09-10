(* UNEXECUTED desired-contract tests for the COMMON-GRADE candidate repair.
   Load the canonical package before TestReport on this file.
   These are not claimed to be portable MUnit infrastructure for Mathics.
*)
VerificationTest[
 Module[{x,s}, s=AsymptoticExpansion[1+LerchPhi[1/2,2,x],{x,Infinity,0},"Backend"->"Package"];
  {Normal[s],s["RemainderPower"],s["RemainderBoundConstant"],s["FrontierTerm"],
   s["RemainderScaleExpression"],s["AbsoluteRemainderBound"],s["FirstOmittedMoment"]}],
 {0,0,3,1,1,3,0}, TestID->"omitted-affine-constant-joins-positive-Lerch-tail-grade"]
VerificationTest[
 Module[{x,s}, s=AsymptoticExpansion[1+LerchPhi[1/2,2,x],{x,Infinity,-1},"Backend"->"Package"];
  {Normal[s],s["RemainderPower"],s["AbsoluteRemainderBound"]}],
 {0,0,3}, TestID->"negative-cutoff-does-not-authorize-a-decaying-constant-bound"]
VerificationTest[
 Module[{x,s}, s=AsymptoticExpansion[-3 LerchPhi[1/2,2,x]-2,{x,Infinity,0},"Backend"->"Package"];
  {Normal[s],s["RemainderPower"],s["AbsoluteRemainderBound"],s["FrontierTerm"]}],
 {0,0,8,-2}, TestID->"signed-affine-Lerch-tail-uses-magnitudes-and-signed-frontier"]
VerificationTest[
 Module[{x,s}, s=AsymptoticExpansion[LerchPhi[1/2,2,x],{x,Infinity,0},"Backend"->"Package"];
  {Normal[s],s["RemainderPower"],s["RemainderBoundConstant"]}],
 {0,2,2}, TestID->"zero-affine-constant-preserves-atom-grade"]
VerificationTest[
 Module[{x,s}, s=AsymptoticExpansion[1+LerchPhi[1/2,2,x],{x,Infinity,1},"Backend"->"Package"];
  {Normal[s],s["RemainderPower"],s["RemainderBoundConstant"]}],
 {1,2,2}, TestID->"positive-cutoff-retains-the-affine-constant"]
VerificationTest[
 Module[{x,s}, s=AsymptoticExpansion[1+LerchPhi[1/2,2,x],{x,Infinity,3},"Backend"->"Package"];
  {TrueQ[Simplify[Normal[s] == 1+2/x^2]],s["RemainderPower"],s["RemainderBoundConstant"]}],
 {True,3,4}, TestID->"positive-cutoff-keeps-existing-Lerch-coefficient-and-bound"]
VerificationTest[
 Module[{x,s}, s=AsymptoticExpansion[1+LerchPhi[1/2,2,2 x+1],{x,Infinity,0},"Backend"->"Package"];
  {Normal[s],s["RemainderPower"],s["AbsoluteRemainderBound"]}],
 {0,0,3}, TestID->"shifted-positive-Lerch-coordinate-joins-the-same-zero-grade"]
VerificationTest[
 Module[{x,s}, s=AsymptoticExpansion[1+LerchPhi[1/2,2,x],{x,Infinity,0},"Backend"->"Package"];
  {s["AtomRemainderPower"],s["OmittedAffineConstant"],s["FirstOmittedMoment"]}],
 {2,1,0}, TestID->"atom-moment-frontier-is-distinguished-from-full-error-frontier"]
