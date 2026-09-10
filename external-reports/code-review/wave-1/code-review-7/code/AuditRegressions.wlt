(* Proposed regression tests. No successful native run of this file was
   obtained during the audit. Several tests intentionally fail on the pinned
   baseline and specify desired behavior after the proposals are integrated.
   Load the package before running TestReport on this file. *)

VerificationTest[
 Module[{x, s},
  s = AsymptoticExpansion[1 + x^(1/200001) + x^(200000/200001) + x,
    {x, 0, 1}, "MaxTerms" -> 32];
  MatchQ[s, _GeneralizedSeries] && MissingQ[s["SeriesData"]] &&
   TrueQ[Normal[s] == 1 + x^(1/200001) + x^(200000/200001)]],
 True, TestID -> "audit-F01-wide-native-view-refused-without-losing-sparse-result"]

VerificationTest[
 Module[{x, s},
  s = AsymptoticExpansion[1 + x^(1/200001) + x, {x, 0, 1}, "MaxTerms" -> 32];
  MatchQ[s, _GeneralizedSeries] && MatchQ[s["SeriesData"], _SeriesData] &&
   Length[s["SeriesData"][[3]]] <= 2],
 True, TestID -> "audit-F01-no-unnecessary-trailing-zero-padding"]

VerificationTest[
 Module[{x, z, s, direct, nested},
  s = AsymptoticExpansion[-x, {x, 0, 1}];
  direct = SeriesPower[s, 1/2];
  nested = SeriesObservable[s, 1 + Sqrt[z], z];
  {FailureQ[direct], FailureQ[nested]}],
 {True, True}, TestID -> "audit-F02-nested-observable-must-not-bypass-real-power-guard"]

VerificationTest[
 Module[{x, z, s},
  s = AsymptoticExpansion[x + x^2, {x, 0, 3}];
  ! FailureQ[SeriesObservable[s, 1 + Sqrt[z], z]]],
 True, TestID -> "audit-F02-positive-known-leading-term-still-admitted"]

VerificationTest[
 Module[{x, a},
  FailureQ[AsymptoticExpansion[Log[-a] + x, {x, 0, 2}, Assumptions -> a > 0]]],
 True, TestID -> "audit-F04-provably-nonreal-constant-coefficient-rejected"]

VerificationTest[
 Module[{x, y, s},
  s = AsymptoticFlatInverse[x + Exp[-2/x] + Exp[-3/x], {x, 0}, {y, 3}];
  MatchQ[s, _GeneralizedSeries] &&
   TrueQ[FullSimplify[Normal[s] == y - Exp[-2/y] - Exp[-3/y], y > 0]]],
 True, TestID -> "audit-F05-commensurate-flat-rates-need-not-divide-smallest"]

VerificationTest[
 Module[{x, y, s},
  s = AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}];
  TrueQ[FullSimplify[Normal[s] == y - y^2 (1 + Log[y]) +
     y^3 (2 Log[y]^2 + 5 Log[y] + 3), y > 0]]],
 True, TestID -> "audit-control-complete-logarithmic-blocks"]

VerificationTest[
 Module[{x, y, s},
  s = AsymptoticInverse[x + x^Sqrt[2], {x, 0}, {y, 3 Sqrt[2] - 2}];
  TrueQ[FullSimplify[Normal[s] == y - y^Sqrt[2] + Sqrt[2] y^(2 Sqrt[2] - 1), y > 0]]],
 True, TestID -> "audit-control-irrational-exclusive-cutoff"]

VerificationTest[
 Module[{x, a, b, s},
  a = AsymptoticExpansion[1 + x Log[x]^3, {x, 0, 1}];
  b = AsymptoticExpansion[Log[x]^2, {x, 0, 1}];
  s = SeriesMultiply[a, b];
  {s["RemainderPower"], s["RemainderLogDegree"]}],
 {1, 5}, TestID -> "audit-control-boundary-log-degree-propagated"]
