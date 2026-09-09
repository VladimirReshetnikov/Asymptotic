(* Desired fail-closed real-input contract. The semantic-weight patch does
   NOT fix these tests. The public examples were reproduced in the audit. *)
VerificationTest[
 FailureQ[AsymptoticInverse`AsymptoticExpansion[x + ArcSin[2], {x, 0, 3}]],
 True, TestID -> "reject-encoded-complex-constant"]
VerificationTest[
 FailureQ[AsymptoticInverse`AsymptoticExpansion[ArcSin[2 + x], {x, 0, 3}]],
 True, TestID -> "reject-nonreal-principal-analytic-germ"]
VerificationTest[
 FailureQ[AsymptoticInverse`AsymptoticInverse[x + ArcSin[2], {x, 0}, {y, 3}]],
 True, TestID -> "reject-complex-target-limit-in-real-inverse"]
VerificationTest[
 FailureQ[AsymptoticInverse`AsymptoticExpansion[x + I, {x, 0, 3}]],
 True, TestID -> "control-explicit-complex-rejected"]
