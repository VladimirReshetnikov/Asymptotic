(* Desired invariants. These are deliberately failing on the audited baseline.
   The article records execution of the three corresponding public examples
   before and after the semantic-merge transformation, not this whole file. *)
VerificationTest[
 Module[{a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s},
  s = Quiet[AsymptoticInverse`AsymptoticExpansion[
    x^a - x^b + x^2, {x, 0}, SeriesTermGoal -> 1], N::meprec];
  If[FailureQ[s], s, {Normal[s], s["Remainder"], s["ReturnedTermCount"]}]],
 {x^2, 0, 1}, TestID -> "semantic-equality-cancellation-before-term-goal"]
VerificationTest[
 Module[{a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s, t},
  s = Quiet[AsymptoticInverse`AsymptoticExpansion[
    1 + x^a + x^b Log[x]^3 + x^(2 a), {x, 0, 2 a}], N::meprec];
  t = Quiet[AsymptoticInverse`SeriesMultiply[s, s], N::meprec];
  If[FailureQ[t], t, t["RemainderLogDegree"]]],
 6, TestID -> "semantic-equality-multiplication-boundary-degree"]
VerificationTest[
 Module[{a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s},
  s = Quiet[AsymptoticInverse`AsymptoticInverse[
    x^a - x^b + x^2, {x, 0}, {y, 2}], N::meprec];
  If[FailureQ[s], s, {Normal[s], s["Remainder"]}]],
 {Sqrt[y], 0}, TestID -> "semantic-equality-no-zero-gap-enumeration"]
VerificationTest[
 Module[{s = AsymptoticInverse`AsymptoticExpansion[Sin[x], {x, 0, 5}]},
  Normal[s]], x - x^3/6, TestID -> "control-exclusive-cutoff"]
VerificationTest[
 Module[{s = AsymptoticInverse`AsymptoticInverse[x + x^2, {x, 0}, {y, 5}]},
  Normal[s]], y - y^2 + 2 y^3 - 5 y^4,
 TestID -> "control-ordinary-inverse"]
