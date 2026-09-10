(* Native Wolfram regression candidates for the reviewed commit.
   NOT EXECUTED by this audit. Load the pinned package before TestReport.
   Expectations describe corrected behavior; baseline failures are expected.
   F05/F06 need further implementation; the patcher does not fix them. *)

VerificationTest[
 Module[{x, s, t},
  s = AsymptoticExpansion[1 + x Log[x] + x^2, {x, 0, 2}];
  t = SeriesLog[s, 3];
  {t["RemainderPower"], t["RemainderLogDegree"]}],
 {2, 2}, TestID -> "F01-log-active-input-frontier"]

VerificationTest[
 Module[{x, s, t},
  s = AsymptoticExpansion[x Log[x] + x^2, {x, 0, 2}];
  t = SeriesExp[s, 3];
  {t["RemainderPower"], t["RemainderLogDegree"]}],
 {2, 2}, TestID -> "F01-exp-active-input-frontier"]

VerificationTest[
 Module[{x, s, t},
  s = AsymptoticExpansion[1 + x Log[x] + x^2, {x, 0, 2}];
  t = SeriesPower[s, -1, 3];
  {t["RemainderPower"], t["RemainderLogDegree"]}],
 {2, 2}, TestID -> "F01-reciprocal-active-input-frontier"]

VerificationTest[
 Module[{x, s, t},
  s = AsymptoticExpansion[1 + x Log[x] + x^2, {x, 0, 2}];
  t = SeriesPower[s, 1/2, 3];
  {t["RemainderPower"], t["RemainderLogDegree"]}],
 {2, 2}, TestID -> "F01-fractional-unit-active-input-frontier"]

VerificationTest[
 Module[{x, s},
  s = AsymptoticExpansion[-x, {x, 0, 0}];
  FailureQ[SeriesPower[s, 1/2]]],
 True, TestID -> "F02-pure-remainder-needs-real-branch"]

VerificationTest[
 Module[{x, s, t},
  s = AsymptoticExpansion[0, {x, 0, 2}];
  t = SeriesPower[s, 1/2];
  {Normal[t], t["Remainder"]}],
 {0, 0}, TestID -> "F02-exact-zero-positive-fractional-power"]

VerificationTest[
 Module[{x, s},
  s = AsymptoticExpansion[x + x^2 Log[x], {x, 0, 2}];
  MissingQ[s["SeriesData"]]],
 True, TestID -> "F03-log-remainder-is-not-losslessly-exportable"]

VerificationTest[
 Module[{x, y, s},
  s = AsymptoticInverse[x + x^2 Log[x], {x, 0}, {y, 2}];
  MissingQ[s["SeriesData"]]],
 True, TestID -> "F03-inverse-log-remainder-export"]

(* 100003, not 10^9, keeps the unpatched allocation small. A temporary
   bound adds containment even if behavior differs from the source trace. *)
VerificationTest[
 TimeConstrained[MemoryConstrained[
  Module[{x, s},
   s = AsymptoticExpansion[x^(1/100003) + x, {x, 0, 1}];
   MatchQ[s, _GeneralizedSeries] && MissingQ[s["SeriesData"]]],
  128*1024^2, "MemoryBudgetExceeded"], 30, "TimeBudgetExceeded"],
 True, TestID -> "F04-dense-export-cap-does-not-fail-sparse-result"]

VerificationTest[
 Module[{x, s, t},
  s = SeriesPower[AsymptoticExpansion[Sin[x^10], {x, 0, 21}], -1];
  t = SeriesRefine[s, 20];
  ! FailureQ[t] && TrueQ[t["RemainderPower"] >= 20] &&
   TrueQ[FullSimplify[Normal[t] == x^-10 + x^10/6, x > 0]]],
 True, TestID -> "F05-refinement-must-transport-output-demand-backward"]

(* This expectation requires the proposed scheduler/frontier redesign,
   not merely raising MaxTerms. Bound execution time on an unmodified tree. *)
VerificationTest[
 TimeConstrained[MemoryConstrained[
  Module[{x, y, s},
   s = AsymptoticInverse[x Total[Table[x^j, {j, 0, 20}]],
     {x, 0}, {y, 42}, Method -> "GroupedLagrange", "MaxTerms" -> 20000];
   MatchQ[s, _GeneralizedSeries]], 256*1024^2, "MemoryBudgetExceeded"], 60, "TimeBudgetExceeded"],
 True, TestID -> "F06-grouped-method-must-not-enumerate-all-indices"]

VerificationTest[
 Module[{x, y, s},
  s = AsymptoticFlatInverse[x + Exp[-2/x] + Exp[-3/x], {x, 0}, {y, 3}];
  ! FailureQ[s] && TrueQ[FullSimplify[
    Normal[s] == y - Exp[-2/y] - Exp[-3/y], y > 0]]],
 True, TestID -> "F07-commensurate-rates-need-not-divide-smallest"]
