(* DESIRED CONTRACT for the conservative guard candidate.
   Not executed in Wolfram or Mathics during this review.
   Load the reviewed/patched package before TestReport[this file]. *)

VerificationTest[
 Module[{x, z, a, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4},
    Assumptions -> a^2 == -1, "Backend" -> "Package"];
  If[FailureQ[s], Return[s, Module]];
  r = AsymptoticAnalysis`SeriesObservable[s,
    Abs[1 + a z] + Abs[1 - a z], z, "Cutoff" -> 4];
  MatchQ[r, Failure["UnprovedAbsJetRealness", _Association]]],
 True, TestID -> "ABS-01-conjugate-pair-refused-before-cancellation"]

VerificationTest[
 Module[{x, z, a, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4},
    Assumptions -> a^2 == -1, "Backend" -> "Package"];
  If[FailureQ[s], Return[s, Module]];
  r = AsymptoticAnalysis`SeriesObservable[s,
    Abs[1 + a z]^2 + Abs[1 - a z]^2, z, "Cutoff" -> 4];
  MatchQ[r, Failure["UnprovedAbsJetRealness", _Association]]],
 True, TestID -> "ABS-02-squared-moduli-refused-before-wrong-real-coefficient"]

VerificationTest[
 Module[{x, z, a, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4},
    Assumptions -> Element[a, Reals], "Backend" -> "Package"];
  If[FailureQ[s], Return[s, Module]];
  r = AsymptoticAnalysis`SeriesObservable[s,
    Abs[1 + a z] + Abs[1 - a z], z, "Cutoff" -> 4];
  If[FailureQ[r], r, {Normal[r], r["Remainder"]}]],
 {2, 0}, TestID -> "ABS-03-real-parameter-control"]

VerificationTest[
 Module[{x, z, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4}, "Backend" -> "Package"];
  If[FailureQ[s], Return[s, Module]];
  r = AsymptoticAnalysis`SeriesObservable[s, Abs[-1 + z], z, "Cutoff" -> 4];
  If[FailureQ[r], r, {Expand[Normal[r] - (1 - x)], r["Remainder"]}]],
 {0, 0}, TestID -> "ABS-04-negative-real-control"]

VerificationTest[
 Module[{x, z, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4}, "Backend" -> "Package"];
  If[FailureQ[s], Return[s, Module]];
  r = AsymptoticAnalysis`SeriesObservable[s, Abs[1 + z], z, "Cutoff" -> 4];
  If[FailureQ[r], r, {Expand[Normal[r] - (1 + x)], r["Remainder"]}]],
 {0, 0}, TestID -> "ABS-05-positive-real-control"]

VerificationTest[
 Module[{x, z, a, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4},
    Assumptions -> a^2 == -1, "Backend" -> "Package"];
  If[FailureQ[s], Return[s, Module]];
  r = AsymptoticAnalysis`SeriesObservable[s, (1 + a z) + (1 - a z), z, "Cutoff" -> 4];
  If[FailureQ[r], r, {Normal[r], r["Remainder"]}]],
 {2, 0}, TestID -> "ABS-06-legitimate-algebraic-cancellation-control"]

VerificationTest[
 Module[{x, z, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4}, "Backend" -> "Package"];
  If[FailureQ[s], Return[s, Module]];
  r = AsymptoticAnalysis`SeriesObservable[s, Abs[1 + I z] + Abs[1 - I z], z];
  MatchQ[r, Failure["InexactInput", _Association]]],
 True, TestID -> "ABS-07-direct-complex-literal-is-a-refusal-not-the-bug"]

VerificationTest[
 Module[{x, z, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[0, {x, 0, 4}, "Backend" -> "Package"];
  If[FailureQ[s], Return[s, Module]];
  r = AsymptoticAnalysis`SeriesObservable[s, Abs[z], z, "Cutoff" -> 4];
  If[FailureQ[r], r, {Normal[r], r["Remainder"]}]],
 {0, 0}, TestID -> "ABS-08-exact-zero-control"]
