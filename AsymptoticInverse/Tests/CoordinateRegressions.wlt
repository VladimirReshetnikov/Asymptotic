(* Exact coordinate changes: independent inverse formulas and covariance. *)
VerificationTest[
 Module[{s = AsymptoticInverse[Exp[-1/x], {x, 0}, y, SeriesTermGoal -> 4]},
  {Normal[s], s["Remainder"], s["Scale"], s["Limit"], InverseResidual[s]["ZeroBelowCutoff"]}],
 {-1/Log[y], 0, "Transformed", 0, True}, TestID -> "coordinate-flat-exponential-exact-inverse"]

VerificationTest[
 Module[{s = AsymptoticInverse[Exp[1/x], {x, 0}, y, Direction -> "FromBelow", SeriesTermGoal -> 3]},
  {Normal[s], s["Remainder"], s["Direction"]}],
 {1/Log[y], 0, "FromBelow"}, TestID -> "coordinate-flat-exponential-negative-source-side"]

VerificationTest[
 Module[{s = AsymptoticInverse[x Exp[x^2+x], {x, Infinity}, y, SeriesTermGoal -> 3], l = Log[y]},
  {Simplify[Normal[s] - (Sqrt[l] - 1/2 + (1/8 - Log[l]/4)/Sqrt[l]), y > 1],
   InverseResidual[s]["ZeroBelowCutoff"], s["RemainderPower"]}],
 {0, True, 1}, TestID -> "coordinate-mixed-exponential-phase-three-blocks"]

VerificationTest[
 Module[{s = AsymptoticInverse[(x-2) Exp[(x-2)^2+x-2], {x, Infinity}, y, SeriesTermGoal -> 3],
   t = AsymptoticInverse[x Exp[x^2+x], {x, Infinity}, y, SeriesTermGoal -> 3]},
  Simplify[Normal[s] - Normal[t], y > 1]], 2,
 TestID -> "coordinate-source-translation-covariance"]

VerificationTest[
 Module[{s = AsymptoticInverse[7 - 3 x Exp[x^2+x], {x, Infinity}, y, SeriesTermGoal -> 3],
   t = AsymptoticInverse[x Exp[x^2+x], {x, Infinity}, y, SeriesTermGoal -> 3]},
  {Simplify[Normal[s] - (Normal[t] /. y -> (7-y)/3), y < -1], s["Limit"]}],
 {0, -Infinity}, TestID -> "coordinate-signed-amplitude-and-target-offset"]

VerificationTest[
 Module[{s = AsymptoticInverse[Exp[-x^2-x], {x, Infinity}, y, SeriesTermGoal -> 3], t = -Log[y]},
  {Simplify[Normal[s] - (Sqrt[t] - 1/2 + 1/(8 Sqrt[t])), 0 < y < 1], s["Limit"]}],
 {0, 0}, TestID -> "coordinate-decaying-exponential-at-source-infinity"]

VerificationTest[
 Module[{s = AsymptoticInverse[Exp[x^2+x], {x, -Infinity}, y, SeriesTermGoal -> 3], t = Log[y]},
  Simplify[Normal[s] - (-Sqrt[t] - 1/2 - 1/(8 Sqrt[t])), y > 1]],
 0, TestID -> "coordinate-negative-infinity-selects-negative-quadratic-root"]

VerificationTest[
 Module[{s = AsymptoticInverse[Exp[-1/x^2-1/x], {x, 0}, y, SeriesTermGoal -> 3], t = -Log[y]},
  Simplify[Normal[s] - (1/Sqrt[t] + 1/(2 t) + 1/(8 t^(3/2))), 0 < y < 1]],
 0, TestID -> "coordinate-two-powers-at-singular-finite-endpoint"]

VerificationTest[
 Module[{s = AsymptoticInverse[x^x, {x, Infinity}, y, SeriesTermGoal -> 3]},
  {s["Scale"], s["CoordinateSeries"]["Scale"], InverseResidual[s]["ZeroBelowCutoff"]}],
 {"Transformed", "Logarithmic", True}, TestID -> "coordinate-variable-power-composes-with-lambert"]

VerificationTest[
 Module[{s = AsymptoticInverse[x Exp[x^2+x], {x, Infinity}, {y, 2}, Method -> "Newton"],
   t = AsymptoticInverse[x Exp[x^2+x], {x, Infinity}, {y, 2}, Method -> "Lagrange"]},
  {Simplify[Normal[s]-Normal[t], y > 1], InverseResidual[s]["ZeroBelowCutoff"]}],
 {0, True}, TestID -> "coordinate-independent-newton-and-lagrange"]

VerificationTest[
 Module[{s = AsymptoticInverse[x Exp[x^2+x], {x, Infinity}, y, SeriesTermGoal -> 4], n},
  n = InverseNumericalCheck[s, Exp[100], WorkingPrecision -> 40];
  AssociationQ[n] && n["Error"] < 1/100 && Abs[n["PhaseResidual"]] < 10^-35],
 True, TestID -> "coordinate-logarithmic-numerical-solve-avoids-large-forward-values"]

VerificationTest[
 Module[{s = AsymptoticInverse[x Exp[x^2+x], {x, Infinity}, y, SeriesTermGoal -> 4, "Power" -> 2], n},
  n = InverseNumericalCheck[s, Exp[100], WorkingPrecision -> 40];
  AssociationQ[n] && n["Error"] < 1/10 && Abs[n["ReferenceObservable"] - n["ReferenceRoot"]^2] < 10^-35],
 True, TestID -> "coordinate-numerical-check-of-inverse-observable"]

VerificationTest[
 Module[{s = AsymptoticInverse[Exp[-1/x], {x, 0}, y, SeriesTermGoal -> 2]}, InverseNumericalCheck[s, 2]],
 Failure["OutsideBranch", _Association], SameTest -> MatchQ,
 TestID -> "coordinate-numerical-check-rejects-wrong-target-side"]

VerificationTest[
 AsymptoticInverse[x Exp[x^2+x], {x, Infinity}, {y, 2}, "InputRemainder" -> {4, 0}],
 Failure["UnsupportedOption", _Association], SameTest -> MatchQ,
 TestID -> "coordinate-does-not-reinterpret-additive-input-error-as-phase-error"]

VerificationTest[Module[{x,y,s},
 s=AsymptoticInverse[x Exp[x^2+x], {x, Infinity}, y, SeriesTermGoal -> 3, Assumptions -> x > 0];
 {MatchQ[s,_PowerLogSeries], TrueQ[s["SourceDomain"] /. x -> 2],
  TrueQ[Not[s["SourceDomain"] /. x -> -2]]}],
 {True,True,True}, TestID -> "coordinate-source-assumption-is-proved-and-retained"]

VerificationTest[
 AsymptoticInverse[x Exp[x^2+x], {x, Infinity}, y, SeriesTermGoal -> 3, Assumptions -> x < 0],
 Failure["IncompatibleSourceCondition", _Association], SameTest -> MatchQ,
 TestID -> "coordinate-source-assumption-rejects-incompatible-approach"]
