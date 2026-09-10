(* Proposed integration tests. The complete file was NOT executed in this review.
   Load the pinned package (original or patched) and code/UniformLerch.wl first.
   On the original snapshot the reflected-frontier tests should fail.
   Use the repository's existing native/Mathics runners and loading conventions. *)
VerificationTest[
 Module[{x, y, s, v, b},
  s = AsymptoticAnalysis`AsymptoticSpecialInverse["Erfc", {x, -Infinity}, {y, 1}];
  v = -Log[Sqrt[Pi] (2-y)]; b = (-1/4 + Log[v]/8 - Log[v]^2/32)/v^(3/2);
  FullSimplify[s["FrontierTerm"] + b, 1 < y < 2]],
 0, TestID -> "audit-erfc-negative-frontier-sign"];
VerificationTest[
 Module[{x, y, s, v, b},
  s = AsymptoticAnalysis`AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 1}];
  v = -Log[Sqrt[Pi] y]; b = (-1/4 + Log[v]/8 - Log[v]^2/32)/v^(3/2);
  FullSimplify[s["FrontierTerm"] - b, 0 < y < 1/(E Sqrt[Pi])]],
 0, TestID -> "audit-erfc-positive-frontier-unchanged"];
VerificationTest[
 Module[{x, y, s, v},
  s = AsymptoticAnalysis`AsymptoticSpecialInverse["Erfc", {x, -Infinity}, {y, 1}];
  v = -Log[Sqrt[Pi] (2-y)];
  {FullSimplify[Normal[s] + Sqrt[v] - Log[v]/(4 Sqrt[v]), 1 < y < 2], s["RemainderPower"]}],
 {0, 3/2}, TestID -> "audit-erfc-expression-and-bound-preserved"];
VerificationTest[
 Module[{x, y, s, v, b},
  s = AsymptoticAnalysis`AsymptoticSpecialInverse["Erfc", {x, -Infinity}, {y, 1},
    "TargetOffset" -> 3, "TargetScale" -> -2];
  v = -Log[Sqrt[Pi] (2-(y-3)/(-2))];
  b = (-1/4 + Log[v]/8 - Log[v]^2/32)/v^(3/2);
  FullSimplify[s["FrontierTerm"] + b, -1 < y < 0]],
 0, TestID -> "audit-erfc-reflection-with-affine-target"];
VerificationTest[
 Module[{a, d}, d = AsymptoticAudit`UniformLerchModel[1, 2, a, 2];
  {Rest[d["Terms"]], d["RemainderPower"], d["AbsoluteRemainderBound"] a^7}],
 {{{2,1/2},{3,1/4},{5,-49/720}},7,233/4320},
 TestID -> "audit-uniform-lerch-exact-coefficients"];
VerificationTest[
 Module[{a, d}, d = AsymptoticAudit`UniformLerchModel[1, 0, a, 0];
  {Expand[d["Expression"]-a], d["AbsoluteRemainderBound"] a}],
 {1/2,1/12}, TestID -> "audit-uniform-lerch-zero-s"];
VerificationTest[
 Head[AsymptoticAudit`UniformLerchModel[1, 2, Pi, 2]], Failure,
 TestID -> "audit-uniform-lerch-reject-numeric-coordinate"];
