(* Stage 3 acceptance: exact known roots, several absolute/relative requests,
   exact containment and stopping conditions, and precision failure/recovery. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

acceptanceCertificateSweep[f_, x_, y_, x0_, target_, root_, interval_, cutoff_] := Module[
  {s, tolerances = {1/10^6, 1/10^12, 1/10^20}, absolute, relative, all},
  s = AsymptoticInverse[f, {x, x0}, {y, cutoff}];
  absolute = Table[InverseCertificate[s, target, "Interval" -> interval, "TargetError" -> tolerance,
    WorkingPrecision -> 30, "EnclosureOrder" -> 50, "MaxRefinements" -> 12, "RefineExpansion" -> False], {tolerance, tolerances}];
  relative = Table[InverseCertificate[s, target, "Interval" -> interval, "RelativeError" -> tolerance,
    WorkingPrecision -> 30, "EnclosureOrder" -> 50, "MaxRefinements" -> 12, "RefineExpansion" -> False], {tolerance, tolerances}];
  all = Join[absolute, relative];
  If[! AllTrue[all, AssociationQ], Return[all, Module]];
  {And @@ MapThread[TrueQ[#1["Certified"] && #1["AccuracyGoalReached"] && #1["CertifiedErrorBound"] <= #2] &, {absolute, tolerances}],
    And @@ MapThread[TrueQ[#1["Certified"] && #1["AccuracyGoalReached"] && #1["CertifiedRelativeErrorBound"] <= #2] &, {relative, tolerances}],
    AllTrue[all, TrueQ[#["RootEnclosure"][[1]] <= root <= #["RootEnclosure"][[2]]] &],
    AllTrue[all, Length[#["History"]] === #["Refinements"] + 1 &],
    AnyTrue[all, #["Refinements"] > 0 &]}];

VerificationTest[Module[{x, y, f, root = 1/10}, f = x + x^2 (1 + Log[x]);
  acceptanceCertificateSweep[f, x, y, 0, f /. x -> root, root, {1/20, 3/20}, 3]],
  {True, True, True, True, True}, TestID -> "acceptance-certificate-logarithmic-family-three-absolute-and-relative-tolerances"]

VerificationTest[Module[{x, y, f, root = 1/4}, f = x + x^Sqrt[2];
  acceptanceCertificateSweep[f, x, y, 0, f /. x -> root, root, {1/5, 7/20}, 2]],
  {True, True, True, True, True}, TestID -> "acceptance-certificate-irrational-family-three-absolute-and-relative-tolerances"]

VerificationTest[Module[{x, y, f, root = 1/2}, f = 3 x^2 + x^3;
  acceptanceCertificateSweep[f, x, y, 0, f /. x -> root, root, {2/5, 3/5}, 2]],
  {True, True, True, True, True}, TestID -> "acceptance-certificate-nonunit-family-three-absolute-and-relative-tolerances"]

VerificationTest[Module[{x, y, f, root = 1/5}, f = x Log[x];
  acceptanceCertificateSweep[f, x, y, 0, f /. x -> root, root, {1/8, 1/4}, 3]],
  {True, True, True, True, True}, TestID -> "acceptance-certificate-lower-lambert-three-absolute-and-relative-tolerances"]

VerificationTest[Module[{x, y, f, root = 2}, f = x Exp[x];
  acceptanceCertificateSweep[f, x, y, Infinity, f /. x -> root, root, {1, 7/2}, 3]],
  {True, True, True, True, True}, TestID -> "acceptance-certificate-principal-lambert-three-absolute-and-relative-tolerances"]

VerificationTest[Module[{x, y, f, root = 2}, f = Exp[x^2 + x];
  acceptanceCertificateSweep[f, x, y, Infinity, f /. x -> root, root, {1, 3}, 2]],
  {True, True, True, True, True}, TestID -> "acceptance-certificate-transformed-phase-three-absolute-and-relative-tolerances"]

VerificationTest[Module[{x, y, s, low, recovered, root = 3677/10000, target},
  s = AsymptoticInverse[x Log[x], {x, 0}, {y, 2}]; target = root Log[root];
  low = InverseCertificate[s, target, "Interval" -> {367/1000, 3678/10000}, "Center" -> root,
    WorkingPrecision -> 10, "EnclosureOrder" -> 2, "MaxRefinements" -> 0];
  recovered = InverseCertificate[s, target, "Interval" -> {367/1000, 3678/10000}, "Center" -> root,
    WorkingPrecision -> 10, "EnclosureOrder" -> 2, "MaxRefinements" -> 6];
  {MatchQ[low, Failure["DerivativeNotSeparated", _Association]],
    AssociationQ[recovered] && TrueQ[recovered["Certified"]],
    AssociationQ[recovered] && TrueQ[recovered["RootEnclosure"][[1]] <= root <= recovered["RootEnclosure"][[2]]],
    AssociationQ[recovered] && recovered["Refinements"] > 0 &&
      Last[recovered["History"]]["EnclosureOrder"] > First[recovered["History"]]["EnclosureOrder"]}],
  {True, True, True, True}, TestID -> "acceptance-certificate-insufficient-enclosure-precision-fails-then-recovers"]

VerificationTest[Module[{x, y, increasing, decreasing},
  increasing = InverseCertificate[AsymptoticInverse[x + x^2, {x, 0}, {y, 3}], 6,
    "Interval" -> {1, 3}, "Center" -> 29/10, "MaxRefinements" -> 0];
  decreasing = InverseCertificate[AsymptoticInverse[1/x, {x, Infinity}, {y, 1}], 1/2,
    "Interval" -> {1, 3}, "Center" -> 11/10, "MaxRefinements" -> 0];
  {increasing["ExistenceEvidence"], decreasing["ExistenceEvidence"],
    And @@ (TrueQ[#["RootEnclosure"][[1]] <= 2 <= #["RootEnclosure"][[2]] &&
       Abs[#["Center"] - 2] <= #["CertifiedErrorBound"]] & /@ {increasing, decreasing}),
    increasing["EndpointResidualEnclosures"][[1, 2]] <= 0 <= increasing["EndpointResidualEnclosures"][[2, 1]],
    decreasing["EndpointResidualEnclosures"][[2, 2]] <= 0 <= decreasing["EndpointResidualEnclosures"][[1, 1]]}],
  {"Exact endpoint signs and continuity", "Exact endpoint signs and continuity", True, True, True},
  TestID -> "acceptance-certificate-endpoint-sign-existence-with-center-radius-outside-interval"]

VerificationTest[Module[{x, y},
  InverseCertificate[AsymptoticInverse[x + x^2, {x, 0}, {y, 3}], 20,
    "Interval" -> {1, 3}, "Center" -> 29/10, "MaxRefinements" -> 0]],
  Failure["ResidualBracketOutsideInterval", _Association], SameTest -> MatchQ,
  TestID -> "acceptance-certificate-endpoint-fallback-rejects-an-interval-with-no-root"]
