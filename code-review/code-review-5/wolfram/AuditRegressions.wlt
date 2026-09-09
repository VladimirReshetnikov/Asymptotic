(* Native regression proposals for the pinned Asymptotic 1.8.0 source.
   NOT RUN during this audit. RunAudit.wls loads the repository first.
   F01, F02 and F05 target the supplied surgical patches. F04 intentionally
   remains a regression target for a subsequent precision-planner fix.
   SPDX-License-Identifier: MIT-0 *)

VerificationTest[
 Module[{x, y, s}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 5}];
  Expand[Normal[s] - (y - y^2 + 2 y^3 - 5 y^4)]],
 0, TestID -> "audit-baseline-catalan-inverse"]

VerificationTest[
 Module[{x, y, s}, s = AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}];
  FullSimplify[Normal[s] - (y - y^2 (1 + Log[y]) + y^3 (2 Log[y]^2 + 5 Log[y] + 3)), y > 0]],
 0, TestID -> "audit-baseline-complete-log-blocks"]

VerificationTest[
 Module[{x, y, s}, s = AsymptoticInverse[x + x^2 + x^3, {x, 0}, {y, 6}];
  Expand[Normal[s] - (y - y^2 + y^3 - 4 y^5)]],
 0, TestID -> "audit-baseline-resonant-cancellation"]

VerificationTest[
 Module[{x, s, result},
  (* A modest denominator exercises the policy without a billion-slot request. *)
  s = MemoryConstrained[
    TimeConstrained[AsymptoticExpansion[x^(1/100003) + x, {x, 0, 1}, "MaxTerms" -> 10], 30, $Aborted],
    128 1024^2, $Aborted];
  MatchQ[s, _GeneralizedSeries] &&
   MatchQ[s["SeriesData"], Missing["DenseRepresentationTooLarge", _Association]]],
 True, TestID -> "audit-F01-dense-export-refused-without-losing-sparse-result"]

VerificationTest[
 Module[{x, s}, s = AsymptoticExpansion[x, {x, 0, 1}];
  FailureQ[SeriesPower[s, 1/2]]],
 True, TestID -> "audit-F02-existing-direct-power-guard"]

VerificationTest[
 Module[{x, z, s}, s = AsymptoticExpansion[x, {x, 0, 1}];
  FailureQ[SeriesObservable[s, 1 + Sqrt[-z], z]]],
 True, TestID -> "audit-F02-nested-power-must-not-bypass-real-branch-guard"]

VerificationTest[
 Module[{x, z, s, result}, s = AsymptoticExpansion[x, {x, 0, 2}];
  result = SeriesObservable[s, 1 + Sqrt[z], z];
  MatchQ[result, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[result] == 1 + Sqrt[x], x > 0]]],
 True, TestID -> "audit-F02-proved-positive-leading-term-still-supported"]

VerificationTest[
 Module[{x, s, t, r},
  s = AsymptoticExpansion[Exp[x] - 1, {x, 0, 3}];
  t = SeriesPower[s, -10]; r = SeriesRefine[t, 5];
  (* The source is available: successful refinement should actually reach 5. *)
  MatchQ[r, _GeneralizedSeries] && TrueQ[r["RemainderPower"] >= 5]],
 True, TestID -> "audit-F04-negative-power-refinement-must-reach-requested-cutoff"]

VerificationTest[
 Module[{x, y, s, result}, s = AsymptoticInverse[7 + x + x^2, {x, 0}, {y, 4}];
  result = InverseResidual[s];
  StringContainsQ[result["Normalization"], "y0"]],
 True, TestID -> "audit-F05-offset-recorded-in-residual-normalization-label"]

VerificationTest[
 Module[{x, y, s}, s = AsymptoticInverse[7 + x, {x, 0}, {y, 3}];
  TrueQ[InverseResidual[s]["ZeroBelowCutoff"]]],
 True, TestID -> "audit-F05-offset-residual-calculation-remains-correct"]

VerificationTest[
 Module[{x, y, centered, absolute},
  centered = AsymptoticInverse[x, {x, 1}, {y, 3}, "Power" -> 2];
  absolute = SeriesPower[AsymptoticInverse[x, {x, 1}, {y, 3}], 2];
  {Expand[Normal[centered]], Expand[Normal[absolute]]} == {1 - 2 y + y^2, y^2}],
 True, TestID -> "audit-documented-displacement-versus-absolute-power"]
