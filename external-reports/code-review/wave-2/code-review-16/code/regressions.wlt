(* DESIRED-CONTRACT REGRESSIONS. Native-unrun in this audit.
   Load the pinned package first. Unpatched code is expected to fail some tests.
   These tests never fetch or execute a remote package. *)

VerificationTest[
  Block[{$Assumptions = True},
    Module[{s, baseline, ambient},
      s = AsymptoticInverse`AsymptoticInverse[
        ConditionalExpression[x, x > 1], {x, Infinity}, {y, 2}];
      baseline = AsymptoticInverse`InverseCertificate[s, 1/2,
        "Interval" -> {1/4, 3/4}, "Center" -> 1/2, "MaxRefinements" -> 0];
      ambient = Block[{$Assumptions = x > 1},
        AsymptoticInverse`InverseCertificate[s, 1/2,
          "Interval" -> {1/4, 3/4}, "Center" -> 1/2, "MaxRefinements" -> 0]];
      {FailureQ[baseline], FailureQ[ambient]}
    ]],
  {True, True}, TestID -> "N01-ambient-domain-must-not-certify-outside-root"
]

VerificationTest[
  Block[{$Assumptions = x > 1},
    AsymptoticInverse`Private`certPositiveCondition[x > 1, x, {1/4, 3/4},
      <|"SeriesOrder" -> 60, "Bits" -> 280, "ExponentMagnitudeLimit" -> 10000|>]],
  False, TestID -> "N01-low-level-domain-isolation"
]

VerificationTest[
  Block[{$Assumptions = True}, Module[{s, r},
    s = AsymptoticInverse`AsymptoticInverse[x, {x, 0}, {y, 2}];
    r = AsymptoticInverse`InverseCertificate[s, 1/3,
      "Interval" -> {1/4, 1/2}, "RelativeError" -> 10^-1000,
      "RefineExpansion" -> False, "MaxRefinements" -> 6];
    AssociationQ[r] && TrueQ[r["AccuracyGoalReached"]] &&
      TrueQ[r["CertifiedRelativeErrorBound"] <= 10^-1000]
  ]], True, TestID -> "N02-pure-relative-goal-adapts-arithmetic"
]

VerificationTest[
  Block[{$Assumptions = True}, Module[{s, r},
    s = AsymptoticInverse`AsymptoticInverse[x, {x, 0}, {y, 2}];
    r = AsymptoticInverse`InverseCertificate[s, 1/3,
      "Interval" -> {1/4, 1/2}, "RelativeError" -> 10^-1000,
      "EnclosureOrder" -> 960, "RefineExpansion" -> False, "MaxRefinements" -> 2];
    AssociationQ[r] && TrueQ[r["AccuracyGoalReached"]]
  ]], True, TestID -> "N02-explicit-high-order-control"
]

VerificationTest[
  Block[{$Assumptions = True}, Module[{s},
    s = AsymptoticInverse`AsymptoticExpansion[x Log[x] + x^2, {x, 0, 2}];
    AsymptoticInverse`SeriesExp[s, 5]["RemainderLogDegree"]
  ]], 2, TestID -> "S01-exp-complete-boundary-degree"
]

VerificationTest[
  Block[{$Assumptions = True}, Module[{s},
    s = AsymptoticInverse`AsymptoticExpansion[1+x Log[x]+x^2, {x, 0, 2}];
    AsymptoticInverse`SeriesLog[s, 5]["RemainderLogDegree"]
  ]], 2, TestID -> "S01-log-complete-boundary-degree"
]

VerificationTest[
  Block[{$Assumptions = True},
    AsymptoticInverse`Private`pUnitSeries[
      {{1, ell}, {2, -ell^2/2}}, 3, 0, Function[k, 1/k!], 2, ell, True, 20000][[3]]],
  0, TestID -> "S01-boundary-cancellation-is-preserved"
]

VerificationTest[
  Module[{calls = {}, out},
    out = AsymptoticInverse`Private`pUnitSeries[{{1, ell}}, 2, 0,
      Function[k, AppendTo[calls, k]; 1/k!], 5, ell, True, 20000];
    {calls, out[[3]]}],
  {{1, 2}, 2}, TestID -> "S01-coefficient-callback-once-per-order"
]

(* N04 is a policy test, not a native mathematical correctness claim.
   The article recommends consistent intersection semantics or an explicit
   conflicting-goals Failure. Either is accepted here. *)
VerificationTest[
  Block[{$Assumptions = True}, Module[{s},
    s = AsymptoticInverse`AsymptoticExpansion[Zeta[x], {x, Infinity, Log[5]},
      SeriesTermGoal -> 1];
    FailureQ[s] || TrueQ[s["ReturnedTermCount"] <= 1]
  ]], True, TestID -> "N04-zeta-does-not-silently-ignore-term-goal"
]
