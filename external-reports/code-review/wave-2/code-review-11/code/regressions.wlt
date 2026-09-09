(* Desired-contract tests. NOT executed as a suite in this audit.
   N01--N04 tests are intentionally expected to expose baseline defects.
   Source is loaded by run_regressions.wl, not by this file. *)
ClearAll[AuditNotCertified, AuditRealResult, AuditOpaqueSafe];
AuditNotCertified[r_] := FailureQ[r] || (AssociationQ[r] && ! TrueQ[Lookup[r, "Certified", False]]);
AuditRealResult[r_, assumptions_] := MatchQ[r, _AsymptoticInverse`GeneralizedSeries] &&
  TrueQ[FullSimplify[Element[Normal[r], Reals], Assumptions -> assumptions]];
AuditOpaqueSafe[r_, x_] := FailureQ[r] ||
  (MatchQ[r, _AsymptoticInverse`GeneralizedSeries] && r["Remainder"] =!= 0 &&
    TrueQ[TimeConstrained[Limit[Abs[x^2 Log[1 - Log[x]] - Normal[r]] /
      Lookup[r[[1]], "RemainderScaleExpression",
        r["Remainder"] /. AsymptoticInverse`PowerLogRemainder[w_, p_, d_] :>
          w^p (1 + Abs[Log[w]])^d], x -> 0, Direction -> "FromAbove"] < Infinity, 5, False]]);
VerificationTest[
  Block[{$Assumptions = True}, Module[{x, y, s},
    s = AsymptoticInverse`AsymptoticInverse[ConditionalExpression[x, x > 2], {x, Infinity}, {y, 2}];
    AuditNotCertified[Assuming[x > 2, AsymptoticInverse`InverseCertificate[s, 1,
      "Interval" -> {1/2, 3/2}, "Center" -> 1, "MaxRefinements" -> 0]]]]],
  True, TestID -> "N01-ambient-domain-must-not-certify"]
VerificationTest[
  Block[{$Assumptions = True}, Module[{x, y, s},
    s = AsymptoticInverse`AsymptoticInverse[ConditionalExpression[x, x > 2], {x, Infinity}, {y, 2}];
    AuditNotCertified[AsymptoticInverse`InverseCertificate[s, 1,
      "Interval" -> {1/2, 3/2}, "Center" -> 1, "MaxRefinements" -> 0]]]],
  True, TestID -> "N01-clean-exclusion-control"]
VerificationTest[
  Block[{$Assumptions = True}, Module[{x, y, s, r},
    s = AsymptoticInverse`AsymptoticInverse[ConditionalExpression[x, x > 2], {x, Infinity}, {y, 2}];
    r = AsymptoticInverse`InverseCertificate[s, 3, "Interval" -> {5/2, 7/2},
      "Center" -> 3, "MaxRefinements" -> 0];
    AssociationQ[r] && TrueQ[r["Certified"]] ]], True, TestID -> "N01-valid-branch-control"]
VerificationTest[
  Block[{$Assumptions = True}, Module[{x, a, outer, inner, r},
    outer = AsymptoticInverse`AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 0];
    inner = AsymptoticInverse`AsymptoticExpansion[a, {a, 0, 4}];
    r = AsymptoticInverse`SeriesCompose[outer, inner];
    FailureQ[r] || (MatchQ[r, _AsymptoticInverse`GeneralizedSeries] &&
      r["Remainder"] === 0 && TrueQ[FullSimplify[Normal[r] == 1/2, a > 0]])]],
  True, TestID -> "N02-diagonal-refuse-or-exact-reexpand"]
VerificationTest[
  Block[{$Assumptions = True}, Module[{x, a, outer, inner, r},
    outer = AsymptoticInverse`AsymptoticExpansion[x/a, {x, 0, 2}, Assumptions -> a > 0];
    inner = AsymptoticInverse`AsymptoticExpansion[a, {a, 0, 4}];
    r = AsymptoticInverse`SeriesCompose[outer, inner];
    MatchQ[r, _AsymptoticInverse`GeneralizedSeries] && r["Remainder"] === 0 &&
      TrueQ[FullSimplify[Normal[r] == 1, a > 0]]]],
  True, TestID -> "N02-exact-outer-capture-control"]
VerificationTest[
  Block[{$Assumptions = True}, Module[{g, x, s},
    g[t_?NumericQ] := If[TrueQ[t == 0], 0, t^2 Log[1 + Abs[Log[Abs[t]]]]]; g'[0] = 0;
    s = AsymptoticInverse`AsymptoticExpansion[g[x], {x, 0, 2}];
    AuditOpaqueSafe[s, x]]], True, TestID -> "N03-opaque-true-jet-not-analytic-proof"]
VerificationTest[
  Block[{$Assumptions = True}, Module[{x, s},
    s = AsymptoticInverse`AsymptoticExpansion[Exp[x], {x, 0, 3}];
    MatchQ[s, _AsymptoticInverse`GeneralizedSeries] &&
      Expand[Normal[s] - (1 + x + x^2/2)] === 0]],
  True, TestID -> "N03-known-analytic-control"]
VerificationTest[
  Block[{$Assumptions = True}, Module[{x, a},
    FailureQ[AsymptoticInverse`AsymptoticExpansion[Sqrt[-a] + x, {x, 0, 2}, Assumptions -> a > 0]]]],
  True, TestID -> "N04-direct-reject-nonreal"]
VerificationTest[
  Block[{$Assumptions = True}, Module[{x, a, z, s},
    s = AsymptoticInverse`AsymptoticExpansion[x, {x, 0, 3}, Assumptions -> a > 0];
    FailureQ[AsymptoticInverse`SeriesObservable[s, z + Sqrt[-a], z]]]],
  True, TestID -> "N04-observable-reject-nonreal"]
VerificationTest[
  Block[{$Assumptions = True}, Module[{x, a, s},
    s = AsymptoticInverse`AsymptoticExpansion[x, {x, 0, 3}, Assumptions -> a > 0];
    FailureQ[AsymptoticInverse`SeriesAdd[s, Sqrt[-a]]]]],
  True, TestID -> "N04-scalar-rejection-control"]
VerificationTest[
  Block[{$Assumptions = True}, Module[{x, y, a},
    FailureQ[AsymptoticInverse`AsymptoticInverse[x + Sqrt[-a] x^2, {x, 0}, {y, 3}, Assumptions -> a > 0]]]],
  True, TestID -> "N04-inverse-rejection-control"]
VerificationTest[
  Block[{$Assumptions = True}, Module[{x, a, s},
    s = AsymptoticInverse`AsymptoticExpansion[Sqrt[-a] + x, {x, 0, 2}, Assumptions -> a < 0];
    AuditRealResult[s, a < 0 && x > 0]]],
  True, TestID -> "N04-real-negative-parameter-control"]
