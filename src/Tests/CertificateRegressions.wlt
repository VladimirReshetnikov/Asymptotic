(* Exact arithmetic obligations and independent known-root certificate tests. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
 Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[Module[{x,y,c},
 c=InverseCertificate[AsymptoticInverse[x+x^2,{x,0},{y,3}],1/10,
   "Interval"->{1/20,1/5},"RelativeError"->1/10^12,"RefineExpansion"->False];
 {c["Certified"],c["AccuracyGoalReached"],c["CertifiedRelativeErrorBound"]<=1/10^12}],
 {True,True,True},TestID->"certificate-relative-goal-uses-proved-root-magnitude"]

VerificationTest[Module[{x,y,c},
 c=InverseCertificate[AsymptoticInverse[x,{x,-1},{y,2}],0,
   "Interval"->{-1/2,1/2},"Center"->0,"RelativeError"->1/1000,"TargetError"->1/10^12];
 {c["Certified"],c["RootEnclosure"],c["AccuracyGoalReached"]}],
 {True,{0,0},True},TestID->"certificate-relative-zero-root-has-explicit-absolute-fallback"]

VerificationTest[Module[{x,y},
 InverseCertificate[AsymptoticInverse[x,{x,-1},{y,2}],0,
   "Interval"->{-1/2,1/2},"Center"->0,"RelativeError"->1/1000]],
 Failure["RelativeAccuracyAtZero",_Association],SameTest->MatchQ,
 TestID->"certificate-relative-zero-root-requires-absolute-fallback"]

VerificationTest[Module[{x,y},
 InverseCertificate[AsymptoticInverse[x+x^2,{x,0},{y,3}],6,
   "Interval"->{1,3},"Center"->21/10,"RelativeError"->1/1000]],
 Failure["AccuracyFloor",_Association],SameTest->MatchQ,
 TestID->"certificate-relative-fixed-center-floor-uses-upper-root-magnitude"]

VerificationTest[
 And @@ Flatten[Table[
   AsymptoticAnalysis`Private`certRound[q, bits, False] <= q <=
    AsymptoticAnalysis`Private`certRound[q, bits, True],
   {q, {-100000/3, -1, -1/10000, 0, 1/10000, 1/3, 999999/7}}, {bits, {2, 8, 32}}]],
 True, TestID -> "certificate-dyadic-rounding-is-outward-for-both-signs-and-small-values"]

VerificationTest[
 Module[{ctx = <|"Bits" -> 80, "SeriesOrder" -> 20, "ExponentMagnitudeLimit" -> 10000|>, e, l},
  e = AsymptoticAnalysis`Private`certExpPoint[1, ctx];
  l = AsymptoticAnalysis`Private`certLogPoint[2, ctx];
  {8/3 < e[[1]] <= e[[2]] < 11/4, 2/3 < l[[1]] <= l[[2]] < 7/10,
   And @@ (AsymptoticAnalysis`Private`certRationalQ /@ Join[e, l])}],
 {True, True, True}, TestID -> "certificate-elementary-enclosures-have-rational-endpoints-and-known-bounds"]

VerificationTest[
 Module[{ctx = <|"Bits" -> 100, "SeriesOrder" -> 24, "ExponentMagnitudeLimit" -> 10000|>, p, n, l},
  p = AsymptoticAnalysis`Private`certExpPoint[3/2, ctx];
  n = AsymptoticAnalysis`Private`certExpPoint[-3/2, ctx];
  l = AsymptoticAnalysis`Private`certLogPoint[1/1024, ctx];
  {p[[1]] n[[1]] <= 1 <= p[[2]] n[[2]], -7 < l[[1]] < l[[2]] < -6,
   AsymptoticAnalysis`Private`certLogPoint[1, ctx],
   AsymptoticAnalysis`Private`certExpPoint[0, ctx]}],
 {True, True, {0, 0}, {1, 1}}, TestID -> "certificate-range-reduction-and-negative-exponential-reciprocal"]

VerificationTest[
 Module[{ctx = <|"Bits" -> 80|>},
  {AsymptoticAnalysis`Private`certIntegerPower[{-2, 3}, 2, ctx],
   AsymptoticAnalysis`Private`certIntegerPower[{-2, -1}, 3, ctx],
   AsymptoticAnalysis`Private`certIntegerPower[{1, 2}, -2, ctx]}],
 {{0, 9}, {-8, -1}, {1/4, 1}}, TestID -> "certificate-integer-powers-preserve-sign-and-zero-crossings"]

(* Wave-6 reports 53 N01 and 54 N01: an odd power is monotone across zero, so
   the enclosure is the endpoint range, not a product of independent copies. *)
VerificationTest[
 Module[{ctx = <|"Bits" -> 48, "SeriesOrder" -> 20, "ExponentMagnitudeLimit" -> 10000|>, t},
  {AsymptoticAnalysis`Private`certIntegerPower[{-1/4, 1}, 3, ctx],
   AsymptoticAnalysis`Private`certIntegerPower[{-1, 1/4}, 3, ctx],
   AsymptoticAnalysis`Private`certIntegerPower[{-1/4, 1}, 4, ctx],
   AsymptoticAnalysis`Private`certIntegerPower[{-3, -2}, 4, ctx],
   AsymptoticAnalysis`Private`certIntegerPower[{2, 3}, 0, ctx],
   AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`certIntegerPower[{-3, 2}, -3, ctx]][[1]],
   AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`certEnclose[1 + 4 t^3, t, {-1/4, 1}, ctx]]}],
 {{-1/64, 1}, {-1, 1/64}, {0, 1}, {16, 81}, {1, 1}, "IntervalSingularity", {15/16, 5}},
 TestID -> "certificate-odd-interval-powers-keep-the-endpoint-range-across-zero"]

VerificationTest[
 Module[{x, y, s, c},
  s = AsymptoticInverse[(x - 1)^4/4 + x/16, {x, 2/3}, {y, 3}, Direction -> "FromAbove"];
  c = InverseCertificate[s, 1/16, "Interval" -> {3/4, 2}, "Center" -> 1, "EnclosureOrder" -> 2,
    "MaxRefinements" -> 0, "RefineExpansion" -> False];
  {c["Certified"], c["RootEnclosure"], c["DerivativeLowerBound"]}],
 {True, {1, 1}, 3/64}, TestID -> "certificate-quartic-derivative-is-separated-from-zero-at-an-exact-center"]

(* Report 53 N02: rational powers of a nonnegative base use exact dyadic roots
   instead of Exp[(p/q) Log[base]] and its exponent magnitude budget. *)
VerificationTest[
 Module[{ctx = <|"Bits" -> 48, "SeriesOrder" -> 20, "ExponentMagnitudeLimit" -> 10000|>, t, big, small, negative, zero, refused},
  big = AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`certEnclose[t^(1/2), t, {2^39998, 2^40002}, ctx]];
  small = AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`certEnclose[t^(3/2), t, {1/4, 4}, ctx]];
  negative = AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`certEnclose[t^(-1/2), t, {1/4, 4}, ctx]];
  zero = AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`certEnclose[t^(1/3), t, {0, 8}, ctx]];
  refused = AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`certEnclose[t^(1/2), t, {-1, 4}, ctx]];
  {big[[1]] <= 2^19999 && 2^20001 <= big[[2]] && big[[2]] - big[[1]] < 2^20001 - 2^19999 + 1,
   small, negative, zero, refused[[1]], refused[[2]]["ArgumentEnclosure"]}],
 {True, {1/8, 8}, {1/2, 2}, {0, 2}, "IntervalDomain", {-1, 4}},
 TestID -> "certificate-rational-powers-use-exact-roots-without-the-exponential-budget"]

(* Report 53 N03: a failure no arithmetic precision can repair ends the
   refinement at once instead of being retried at every doubled order. *)
VerificationTest[
 Module[{x, y, s, side, unsupported, control},
  s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
  side = InverseCertificate[s, 6, "Interval" -> {-3, -1}, "Center" -> -2];
  unsupported = InverseCertificate[AsymptoticInverse[x + Sin[x], {x, 0}, {y, 3}], 1/2,
    "Interval" -> {1/10, 1/2}, "Center" -> 1/4];
  control = InverseCertificate[s, 6, "Interval" -> {1, 3}, "Center" -> 21/10];
  {side[[1]], side[[2]]["StoppingReason"], Length[side[[2]]["History"]], side[[2]]["ArithmeticRetryable"],
   unsupported[[1]], unsupported[[2]]["StoppingReason"], Length[unsupported[[2]]["History"]],
   control["Certified"], control["AccuracyGoalReached"]}],
 {"OutsideBranch", "NonRefinableArithmeticFailure", 1, False,
  "UnsupportedEnclosure", "NonRefinableArithmeticFailure", 1, True, True},
 TestID -> "certificate-non-refinable-failures-stop-before-the-refinement-budget"]

VerificationTest[
 Module[{x, y, s, c},
  s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
  c = InverseCertificate[s, 6, "Interval" -> {1, 3}, "Center" -> 21/10];
  {c["Certified"], c["RootEnclosure"][[1]] <= 2 <= c["RootEnclosure"][[2]],
   c["DerivativeLowerBound"], c["CertifiedErrorLowerBound"] <= 1/10 <= c["CertifiedErrorBound"]}],
 {True, True, 3, True}, TestID -> "certificate-positive-derivative-encloses-independent-rational-root"]

VerificationTest[
 Module[{x, y, c},
  c = InverseCertificate[AsymptoticInverse[1/x, {x, Infinity}, {y, 1}], 1/2,
    "Interval" -> {1, 3}, "Center" -> 21/10];
  {c["Certified"], c["DerivativeSign"],
   c["RootEnclosure"][[1]] <= 2 <= c["RootEnclosure"][[2]]}],
 {True, -1, True}, TestID -> "certificate-normalizes-negative-derivative"]

VerificationTest[
 Module[{x, y, c},
  c = InverseCertificate[AsymptoticInverse[x^(3/2), {x, 0}, {y, 2}], 1/8,
    "Interval" -> {1/5, 1/3}, "Center" -> 251/1000, "EnclosureOrder" -> 24];
  {c["Certified"], c["RootEnclosure"][[1]] <= 1/4 <= c["RootEnclosure"][[2]]}],
 {True, True}, TestID -> "certificate-positive-noninteger-power-uses-rigorous-log-exp-enclosures"]

VerificationTest[
 Module[{x, y, c},
  c = InverseCertificate[AsymptoticInverse[x^Sqrt[2], {x, 0}, {y, 2}], 1,
    "Interval" -> {1/2, 3/2}, "Center" -> 1, "EnclosureOrder" -> 24];
  {c["Certified"], c["RootEnclosure"], c["CertifiedErrorBound"]}],
 {True, {1, 1}, 0}, TestID -> "certificate-supports-an-exact-irrational-exponent-on-a-positive-base"]

VerificationTest[
 Module[{x, y, c},
  c = InverseCertificate[AsymptoticInverse[x + x^2, {x, 0}, {y, 3}], 6,
    "Interval" -> {1, 3}, "Center" -> 2];
  {c["Certified"], c["RootEnclosure"], c["CertifiedErrorBound"], c["ResidualEnclosure"]}],
 {True, {2, 2}, 0, {0, 0}}, TestID -> "certificate-exact-zero-residual-proves-zero-error"]

VerificationTest[
 Module[{x, y, c},
  c = InverseCertificate[AsymptoticInverse[x Log[x], {x, 0}, {y, 2}], Log[1/5]/5,
    "Interval" -> {1/8, 1/4}, "Center" -> 201/1000, "EnclosureOrder" -> 24];
  {c["Certified"], c["DerivativeSign"], c["RootEnclosure"][[1]] <= 1/5 <= c["RootEnclosure"][[2]]}],
 {True, -1, True}, TestID -> "certificate-lower-lambert-branch-with-logarithm-tail-bounds"]

VerificationTest[
 Module[{x, y, c},
  c = InverseCertificate[AsymptoticInverse[Exp[x^2 + x], {x, Infinity}, {y, 2}], Exp[6],
    "Interval" -> {1, 3}, "Center" -> 21/10, "ExponentMagnitudeLimit" -> 1];
  {c["Certified"], c["Route"], c["RootEnclosure"][[1]] <= 2 <= c["RootEnclosure"][[2]]}],
 {True, "LogarithmicPhase", True}, TestID -> "certificate-logarithmic-phase-avoids-evaluating-large-exponentials"]

VerificationTest[
 Module[{x, y, s, c},
  s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
  c = InverseCertificate[s, 1/10, "Interval" -> {1/20, 1/5}, "TargetError" -> 1/10^12,
    WorkingPrecision -> 20, "RefineExpansion" -> False];
  {c["Certified"], c["AccuracyGoalReached"], c["CertifiedErrorBound"] <= 1/10^12,
   c["Refinements"] > 0}],
 {True, True, True, True}, TestID -> "certificate-adaptive-interval-newton-meets-requested-exact-tolerance"]

VerificationTest[
 Module[{x, y}, InverseCertificate[AsymptoticInverse[x + x^2, {x, 0}, {y, 3}], 6,
   "Interval" -> {1, 3}, "Center" -> 21/10, "TargetError" -> 1/1000]],
 Failure["AccuracyFloor", _Association], SameTest -> MatchQ,
 TestID -> "certificate-reports-a-proved-fixed-center-accuracy-floor"]

VerificationTest[
 Module[{x, y}, InverseCertificate[AsymptoticInverse[x + x^2, {x, 0}, {y, 2}], 1/10,
   "Interval" -> {1/20, 1/5}, "TargetError" -> 1/10^30, "MaxRefinements" -> 0]],
 Failure["AccuracyNotReached", _Association], SameTest -> MatchQ,
 TestID -> "certificate-does-not-claim-an-unreached-adaptive-tolerance"]

VerificationTest[
 Module[{x, y}, InverseCertificate[AsymptoticInverse[x + x^2, {x, 0}, {y, 3}], 0.1,
   "Interval" -> {1/20, 1/5}]],
 Failure["InexactTarget", _Association], SameTest -> MatchQ,
 TestID -> "certificate-rejects-rounded-targets"]

VerificationTest[
 Module[{x, y}, InverseCertificate[AsymptoticInverse[x + x^2, {x, 0}, {y, 3}], 1/10,
   "Interval" -> {-1, -1/2}, "MaxRefinements" -> 0]],
 Failure["OutsideBranch", _Association], SameTest -> MatchQ,
 TestID -> "certificate-rejects-the-wrong-source-side"]

VerificationTest[
 Module[{x, y}, InverseCertificate[AsymptoticInverse[x + x^2, {x, 0}, {y, 3}, Direction -> "FromBelow"], -1/8,
   "Interval" -> {-1, -1/4}, "MaxRefinements" -> 0]],
 Failure["DerivativeNotSeparated", _Association], SameTest -> MatchQ,
 TestID -> "certificate-rejects-an-interval-containing-a-turning-point"]

VerificationTest[
 Module[{x, ctx = <|"Bits" -> 80, "SeriesOrder" -> 20, "ExponentMagnitudeLimit" -> 10000|>},
  AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`certEnclose[1/(x - 1), x, {1/2, 3/2}, ctx]]],
 Failure["IntervalSingularity", _Association], SameTest -> MatchQ,
 TestID -> "certificate-continuity-check-rejects-a-pole-inside-the-interval"]

VerificationTest[
 Module[{x, ctx = <|"Bits" -> 80, "SeriesOrder" -> 20, "ExponentMagnitudeLimit" -> 10000|>},
  AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`certEnclose[Log[x], x, {-1, 2}, ctx]]],
 Failure["IntervalDomain", _Association], SameTest -> MatchQ,
 TestID -> "certificate-logarithm-enclosure-requires-a-positive-whole-interval"]

VerificationTest[
 Module[{x, ctx = <|"Bits" -> 80, "SeriesOrder" -> 20, "ExponentMagnitudeLimit" -> 10000|>},
  AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`certEnclose[Sin[x], x, {1, 2}, ctx]]],
 Failure["UnsupportedEnclosure", _Association], SameTest -> MatchQ,
 TestID -> "certificate-unsupported-heads-never-become-numerical-proof"]

VerificationTest[
 Module[{x, y, f, c, target},
  f = x + x^2 (1 + Log[x]); target = 1/10 + (1 + Log[1/10])/100;
  c = InverseCertificate[AsymptoticInverse[f, {x, 0}, {y, 3}], target,
    "Interval" -> {1/20, 3/20}, "Center" -> 101/1000, "EnclosureOrder" -> 24];
  {c["Certified"], c["RootEnclosure"][[1]] <= 1/10 <= c["RootEnclosure"][[2]],
   c["OriginalForwardFunction"] === f}],
 {True, True, True}, TestID -> "certificate-original-logarithmic-example-encloses-known-root"]

VerificationTest[
 Module[{x, y, f, c, target},
  f = x + x^Sqrt[2]; target = 1/4 + (1/4)^Sqrt[2];
  c = InverseCertificate[AsymptoticInverse[f, {x, 0}, {y, 2}], target,
    "Interval" -> {1/5, 3/10}, "Center" -> 251/1000, "EnclosureOrder" -> 30];
  {c["Certified"], c["RootEnclosure"][[1]] <= 1/4 <= c["RootEnclosure"][[2]]}],
 {True, True}, TestID -> "certificate-original-irrational-example-encloses-known-root"]

VerificationTest[
 Module[{x, y, c},
  c = InverseCertificate[AsymptoticInverse[3 x^2 + x^3, {x, 0}, {y, 2}], 7/8,
    "Interval" -> {2/5, 3/5}, "Center" -> 501/1000];
  {c["Certified"], c["RootEnclosure"][[1]] <= 1/2 <= c["RootEnclosure"][[2]]}],
 {True, True}, TestID -> "certificate-nonunit-leading-coefficient-and-power"]

VerificationTest[
 Module[{x, y, s, c},
  s = AsymptoticInverse[x Exp[x], {x, Infinity}, {y, 3}];
  c = InverseCertificate[s, 2 Exp[2], "Interval" -> {1, 3}, "Center" -> 21/10,
    "EnclosureOrder" -> 24, "ExponentMagnitudeLimit" -> 1];
  {s["LambertBranch"], c["Certified"], c["Route"],
   c["RootEnclosure"][[1]] <= 2 <= c["RootEnclosure"][[2]]}],
 {0, True, "LogarithmicPhase", True}, TestID -> "certificate-principal-lambert-core-uses-its-exact-logarithmic-phase"]

VerificationTest[
 Module[{x, y, root = 3677/10000, s, c},
  s = AsymptoticInverse[x Log[x], {x, 0}, {y, 2}];
  c = InverseCertificate[s, root Log[root], "Interval" -> {367/1000, 3678/10000},
    "Center" -> 36771/100000, "EnclosureOrder" -> 30];
  {c["Certified"], c["DerivativeSign"], 0 < c["DerivativeLowerBound"] < 1/1000,
   c["RootEnclosure"][[1]] <= root <= c["RootEnclosure"][[2]]}],
 {True, -1, True, True}, TestID -> "certificate-supplied-bracket-near-the-lambert-turning-threshold"]

VerificationTest[
 Module[{x, y, s, c},
  s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}, "InputRemainder" -> {5, 0}];
  c = InverseCertificate[s, 6, "Interval" -> {1, 3}, "Center" -> 2];
  {c["Certified"], c["FunctionScope"], c["CertifiesInputRemainderFamily"],
   c["InputRemainder"], c["OriginalForwardFunction"] === x + x^2}],
 {True, "StoredExpressionOnly", False, {5, 0}, True},
 TestID -> "certificate-declared-input-remainder-is-explicitly-model-only"]

VerificationTest[
 Module[{x, y, s, c},
  s = AsymptoticCoreInverse[x Log[x], x^2, {x, 0}, {y, 1}];
  c = InverseCertificate[s, Log[1/10]/10 + 1/100, "Interval" -> {2/25, 3/25},
    "EnclosureOrder" -> 24];
  {c["Certified"], c["SeedKind"], c["OriginalForwardFunction"] === x Log[x] + x^2,
   c["RootEnclosure"][[1]] <= 1/10 <= c["RootEnclosure"][[2]]}],
 {True, "CoreInverse", True, True}, TestID -> "certificate-uses-exact-core-perturbation-seed-but-checks-the-full-equation"]

VerificationTest[
 Module[{x, y, s, c},
  s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 0}];
  c = InverseCertificate[s, 1/10, "Interval" -> {1/20, 1/5}, "TargetError" -> 1/10^10,
    WorkingPrecision -> 20, "EnclosureOrder" -> 30];
  {c["Certified"], c["SeedKind"], c["CertifiedErrorBound"] <= 1/10^10,
   c["Refinements"] > 0}],
 {True, "CoreInverse", True, True}, TestID -> "certificate-adaptive-exact-core-marker-replay-is-independently-verified"]

VerificationTest[
 Module[{x, ctx = <|"Bits" -> 100, "SeriesOrder" -> 24, "ExponentMagnitudeLimit" -> 1|>, positive, negative},
  positive = AsymptoticAnalysis`Private`certEnclose[Log[2 Exp[x]], x, {100, 101}, ctx];
  negative = AsymptoticAnalysis`Private`certEnclose[Log[x^2], x, {-2, -1}, ctx];
  {100 < positive[[1]] < positive[[2]] < 102, negative[[1]] <= 0,
   1 < negative[[2]] < 2}],
 {True, True, True}, TestID -> "certificate-real-log-identities-avoid-large-exponentials-and-retain-negative-base-fallback"]

VerificationTest[
 Module[{x, y, s, omitted, unordered, inexact},
  s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
  omitted = InverseCertificate[s, 1/10];
  unordered = InverseCertificate[s, 1/10, "Interval" -> {1/5, 1/20}];
  inexact = InverseCertificate[s, 1/10, "Interval" -> {0.05, 0.2}];
  {FailureQ /@ {omitted, unordered, inexact}, #[[1]] & /@ {omitted, unordered, inexact},
   omitted["Reason"], unordered["Reason"], inexact["Reason"], omitted["Certified"],
   unordered["Interval"]}],
 {{True, True, True}, {"InvalidInterval", "InvalidInterval", "InvalidInterval"},
  "IntervalNotSupplied", "MalformedInterval", "MalformedInterval", False, {1/5, 1/20}},
 TestID -> "certificate-omitted-interval-is-diagnosed-separately-from-malformed-endpoints"]

VerificationTest[
 Module[{x, y, a = 2^10000 + 1, s, c},
  s = AsymptoticInverse[x - a, {x, a}, {y, 2}];
  c = InverseCertificate[s, 1/2, "Interval" -> {a + 1/4, a + 3/4}, "Center" -> a + 1/2,
    "EnclosureOrder" -> 2, "MaxRefinements" -> 0, "RefineExpansion" -> False];
  {c["Certified"], c["CertifiedErrorBound"], c["RootEnclosure"] - a, c["ResidualEnclosure"],
   c["DerivativeLowerBound"]}],
 {True, 0, {1/2, 1/2}, {0, 0}, 1},
 TestID -> "certificate-exact-affine-cancellation-survives-a-huge-translation-at-the-lowest-order"]

VerificationTest[
 Module[{x, y, b = 2^300 + 1, s, c},
  s = AsymptoticInverse[3 x - 3 b, {x, b}, {y, 2}];
  c = InverseCertificate[s, 3/2, "Interval" -> {b + 1/4, b + 3/4}, "Center" -> b + 1/2,
    "MaxRefinements" -> 0, "RefineExpansion" -> False];
  {c["Certified"], c["CertifiedErrorBound"], c["RootEnclosure"] - b, c["DerivativeLowerBound"]}],
 {True, 0, {1/2, 1/2}, 3},
 TestID -> "certificate-affine-range-handles-nonunit-slopes-and-nested-rational-products"]

VerificationTest[
 Module[{x, ctx = <|"Bits" -> 40, "SeriesOrder" -> 4, "ExponentMagnitudeLimit" -> 100|>, a = 2^500},
  {AsymptoticAnalysis`Private`certAffineRange[2 (x - a) + (a - x)/2 + 1/3, x, {a, a + 1}],
   AsymptoticAnalysis`Private`certAffineRange[x (x - a), x, {a, a + 1}],
   AsymptoticAnalysis`Private`certAffineRange[Exp[x] - a, x, {a, a + 1}],
   AsymptoticAnalysis`Private`certEnclose[x - a + 1/3, x, {a, a}, ctx] === {1/3, 1/3},
   AsymptoticAnalysis`Private`certEnclose[x^2 - x, x, {2, 2}, ctx]}],
 {{1/3, 11/6}, $Failed, $Failed, False, {2, 2}},
 TestID -> "certificate-affine-range-recognizes-rational-affine-trees-and-rejects-nonlinear-ones"]
