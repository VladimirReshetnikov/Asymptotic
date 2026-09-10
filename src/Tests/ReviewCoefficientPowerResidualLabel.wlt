(* C09: an explicit coefficient "Power" on a result object takes precedence over
   the stored observable power. C10: the residual label names the target offset. *)

VerificationTest[
 Module[{x, y, s, s2, omitted, matching, conflicting, direct},
  s = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
  s2 = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}, "Power" -> 2];
  omitted = InverseExpansionCoefficient[s, {2}];
  matching = InverseExpansionCoefficient[s, {2}, "Power" -> 1];
  conflicting = InverseExpansionCoefficient[s, {2}, "Power" -> 2];
  direct = InverseExpansionCoefficient[s2, {2}];
  {omitted["Coefficient"], matching["Coefficient"] === omitted["Coefficient"],
   conflicting["Coefficient"] === direct["Coefficient"], conflicting["Coefficient"] =!= omitted["Coefficient"],
   conflicting["Exponent"] === direct["Exponent"]}],
 {2, True, True, True, True},
 TestID -> "coefficient-explicit-power-overrides-the-stored-observable-power-at-a-finite-endpoint"]

VerificationTest[
 Module[{x, y, s, s2, omitted, conflicting, direct},
  s = AsymptoticInverse[x^2 + x, {x, Infinity}, {y, 3}];
  s2 = AsymptoticInverse[x^2 + x, {x, Infinity}, {y, 3}, "Power" -> 2];
  omitted = InverseExpansionCoefficient[s, {1}];
  conflicting = InverseExpansionCoefficient[s, {1}, "Power" -> 2];
  direct = InverseExpansionCoefficient[s2, {1}];
  {InverseExpansionCoefficient[s, {1}, "Power" -> 1]["Coefficient"] === omitted["Coefficient"],
   conflicting["Coefficient"] === direct["Coefficient"], conflicting["Exponent"] === direct["Exponent"],
   conflicting["Coefficient"] =!= omitted["Coefficient"]}],
 {True, True, True, True},
 TestID -> "coefficient-explicit-power-is-an-observable-power-at-an-infinite-endpoint"]

VerificationTest[
 Module[{x, y, s, r, control},
  s = AsymptoticInverse[3 + x + x^2, {x, 0}, {y, 4}];
  r = InverseResidual[s];
  control = InverseResidual[AsymptoticInverse[x + x^2, {x, 0}, {y, 4}]];
  {s["Limit"], r["TargetOffset"], StringContainsQ[r["Normalization"], "(f(g(y)) - y0)"],
   r["ZeroBelowCutoff"], control["TargetOffset"], StringStartsQ[control["Normalization"], "f(g(y))/(a z^p) - 1"],
   InverseResidual[AsymptoticInverse[x^2 + x, {x, Infinity}, {y, 3}]]["TargetOffset"]}],
 {3, 3, True, True, 0, True, 0},
 TestID -> "residual-label-and-offset-field-name-the-subtracted-finite-target"]
