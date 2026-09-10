(* Optional development prototype, not an installed package repair.
   Requires a loaded AsymptoticAnalysis baseline/candidate.
   The underlying centered-ratio primitive was checked natively; this wrapper
   has not been executed under Wolfram or Mathics as a separate file. *)
BeginPackage["AsymptoticAudit`"];
AuditLogRatio::usage = "AuditLogRatio[p,q,ctx] encloses Log[p/q] for positive exact rational p and q using the loaded certificate kernel.";
AuditAffineLogRatio::usage = "AuditAffineLogRatio[a,b,q,{lo,hi},ctx] encloses Log[(a x+b)/q] on an exact rational interval, retaining the exact affine image until after the logarithm.";
Begin["`Private`"];
rationalQ[z_] := IntegerQ[z] || Head[z] === Rational;
invalid[] := Failure["InvalidLogRatio", <|"MessageTemplate" ->
  "Use exact rational inputs, a positive denominator, an ordered interval, and a positive affine image."|>];
AuditLogRatio[p_, q_, ctx_Association] :=
  If[rationalQ[p] && rationalQ[q] && TrueQ[p > 0 && q > 0],
    AsymptoticAnalysis`Private`catch[
      AsymptoticAnalysis`Private`certLogPoint[p/q, ctx]], invalid[]];
AuditAffineLogRatio[a_, b_, q_, {lo_, hi_}, ctx_Association] := Module[{image},
  If[And @@ (rationalQ /@ {a,b,q,lo,hi}) && TrueQ[q > 0 && lo <= hi],
    image = Sort[(a {lo,hi} + b)/q];
    If[TrueQ[image[[1]] > 0],
      AsymptoticAnalysis`Private`catch[
        AsymptoticAnalysis`Private`certLog[image,ctx]], invalid[]], invalid[]]];
AuditLogRatio[___] := invalid[];
AuditAffineLogRatio[___] := invalid[];
End[];
EndPackage[];
