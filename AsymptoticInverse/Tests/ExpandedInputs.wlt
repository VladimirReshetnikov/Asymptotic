(* Independent coefficients for generalized composition and cancellation. *)
VerificationTest[
 Module[{x, y, s}, s = AsymptoticInverse[x + Sin[1/x], {x, Infinity}, {y, 4}];
  {Expand[Normal[s] - (y - 1/y - 5/(6 y^3))], s["RemainderPower"]}],
 {0, 5}, TestID -> "automatic-infinity-transport-computes-correct-coefficient"]

VerificationTest[
 Module[{x, s}, s = AsymptoticExpansion[ArcCos[1 - x^Sqrt[2]], {x, 0, 3}];
  FullSimplify[Normal[s] - (Sqrt[2] x^(1/Sqrt[2]) + x^(3/Sqrt[2])/(6 Sqrt[2])), x > 0]],
 0, TestID -> "puiseux-head-with-irrational-argument"]

VerificationTest[
 Module[{x, s}, s = AsymptoticExpansion[Cot[x^Sqrt[2]], {x, 0, 5}];
  FullSimplify[Normal[s] - (x^-Sqrt[2] - x^Sqrt[2]/3 - x^(3 Sqrt[2])/45), x > 0]],
 0, TestID -> "meromorphic-head-with-irrational-argument"]

VerificationTest[
 Module[{x, s}, s = AsymptoticExpansion[Sin[x^Sqrt[2] Log[x]], {x, 0, 5}];
  FullSimplify[Normal[s] - (x^Sqrt[2] Log[x] - x^(3 Sqrt[2]) Log[x]^3/6), x > 0]],
 0, TestID -> "analytic-head-with-irrational-logarithmic-argument"]

VerificationTest[
 Module[{x, s}, s = AsymptoticExpansion[Abs[x + x^2 Log[x]], {x, 0, 4}];
  {Expand[Normal[s] - x - x^2 Log[x]], s["Exact"]}],
 {0, True}, TestID -> "absolute-value-uses-eventual-positive-sign"]

VerificationTest[
 Module[{x, s}, s = AsymptoticExpansion[Abs[x Log[x] + x^2], {x, 0, 4}];
  {Expand[Normal[s] + x Log[x] + x^2], s["Exact"]}],
 {0, True}, TestID -> "absolute-value-uses-leading-log-sign"]

VerificationTest[
 Module[{x, y, s}, s = AsymptoticInverse[x + x^3, {x, 0}, y,
   SeriesTermGoal -> 2, "InputRemainder" -> {4, 0}];
  {Expand[Normal[s] - y + y^3], s["RemainderPower"]}],
 {0, 4}, TestID -> "term-goal-caps-unknown-frontier-without-discarding-known-blocks"]

VerificationTest[
 Module[{x, y, s}, s = AsymptoticInverse[x - x^2, {x, 0}, {y, 3}, Direction -> "FromBelow"];
  Expand[s["FrontierTerm"] - 2 y^3]],
 0, TestID -> "frontier-applies-source-direction-sign"]

VerificationTest[
 Module[{x, y, s}, s = AsymptoticInverse[x^2 + x^3, {x, 0}, {y, 2}];
  With[{c = InverseExpansionCoefficient[s, {1}]}, {c["Exponent"], c["UniformizerExponent"]}]],
 {1, 2}, TestID -> "coefficient-distinguishes-target-and-uniformizer-exponents"]

VerificationTest[
 Module[{x}, And @@ (FailureQ[AsymptoticExpansion[x, {x, 0, #}]] & /@ {I, 1.5})],
 True, TestID -> "forward-rejects-nonreal-and-inexact-cutoffs"]
