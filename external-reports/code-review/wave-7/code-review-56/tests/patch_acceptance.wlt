(* Evaluate after loading the candidate-patched distribution. *)
VerificationTest[
 Module[{s, t},
  s = AsymptoticAnalysis`AsymptoticExpansion[1/(1-a x^3), {x,0,1},
    Assumptions -> a^2 == -1, "Backend" -> "Package"];
  t = AsymptoticAnalysis`SeriesMultiply[AsymptoticAnalysis`SeriesAdd[s,-1],x^-4];
  {MatchQ[Sin[t], Failure["UnprovedRealRemainder", _Association]],
   MatchQ[Cos[t], Failure["UnprovedRealRemainder", _Association]]}],
 {True,True}, TestID -> "N01-amplified-complex-tail-refused"]
VerificationTest[
 Module[{s},
  s = AsymptoticAnalysis`AsymptoticExpansion[a x, {x,0,2},
    Assumptions -> a>0, "Backend" -> "Package"];
  Do[s=AsymptoticAnalysis`SeriesAdd[s,s], {5}];
  {Count[s["Assumptions"],a>0,{0,Infinity}],
   Count[s["TargetDomain"],x>0,{0,Infinity}],Normal[s]===32 a x}],
 {1,1,True}, TestID -> "N02-idempotent-condition-transport"]
