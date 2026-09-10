(* Proposed API policies, deliberately separate from the narrow hardening patch.
   Baseline N04/N05 observations are recorded. These policy tests have NOT been
   implemented by patch_spec.json and are not claimed to pass. *)
ClearAll[x, MadeUpOption];
VerificationTest[
  Module[{s,r},s=AsymptoticAnalysis`AsymptoticExpansion[x,{x,0,5},"Backend"->"Package"];
    r=AsymptoticAnalysis`SeriesDifferentiate[s,0,"Cutoff"->1];r["Expression"]],
  0,TestID->"proposed-zero-derivative-applies-explicit-cutoff"]
VerificationTest[
  FailureQ[AsymptoticAnalysis`AsymptoticExpansion[Exp[x],{x,0,2},
    MadeUpOption->123,"Backend"->"Package"]],True,
  TestID->"proposed-unknown-symbol-option-fails-like-unknown-string-option"]
