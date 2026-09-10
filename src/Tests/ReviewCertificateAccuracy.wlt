(* Exact acceptance predicates for the certificate controller. Square-root
   enclosures are checked by rational squares; no decimal comparison is an
   oracle for certification. The final synthetic case isolates best retention
   using valid, deliberately loose enclosures of the identity inverse. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

reviewCertificateSquareRootQ[c_, target_, relative_] := AssociationQ[c] &&
  TrueQ[c["Certified"] && c["AccuracyGoalReached"] &&
    0 < c["RootEnclosure"][[1]] <= c["RootEnclosure"][[2]] &&
    c["RootEnclosure"][[1]]^2 <= target <= c["RootEnclosure"][[2]]^2 &&
    c["CertifiedRelativeErrorBound"] <= relative &&
    c["CertifiedErrorBound"] <= c["SufficientAbsoluteTolerance"]] &&
  c["CertifiedErrorBound"] === Max[Abs[c["RootEnclosure"] - c["Center"]]];

VerificationTest[Module[{x, y, s, c},
  s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
  c = InverseCertificate[s, 2, "Interval" -> {1, 2}, "RelativeError" -> 10^-120,
    "MaxRefinements" -> 3, "RefineExpansion" -> False];
  reviewCertificateSquareRootQ[c, 2, 10^-120]],
  True, TestID -> "review-certificate-relative-only-square-root-reaches-requested-accuracy"]

VerificationTest[Module[{x, y, s, absolute, explicit},
  s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
  absolute = InverseCertificate[s, 2, "Interval" -> {1, 2}, "TargetError" -> 10^-120,
    "MaxRefinements" -> 3, "RefineExpansion" -> False];
  explicit = InverseCertificate[s, 2, "Interval" -> {1, 2}, "RelativeError" -> 10^-120,
    "EnclosureOrder" -> 150, "MaxRefinements" -> 3, "RefineExpansion" -> False];
  {AssociationQ[absolute] && TrueQ[absolute["Certified"] && absolute["AccuracyGoalReached"] &&
      absolute["CertifiedErrorBound"] <= 10^-120 &&
      absolute["RootEnclosure"][[1]]^2 <= 2 <= absolute["RootEnclosure"][[2]]^2],
    reviewCertificateSquareRootQ[explicit, 2, 10^-120]}],
  {True, True}, TestID -> "review-certificate-absolute-and-explicit-order-controls-remain-valid"]

VerificationTest[Module[{x, y, s, c, history},
  s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
  c = InverseCertificate[s, 2, "Interval" -> {1, 2}, "RelativeError" -> 10^-120,
    "EnclosureOrder" -> 60, "MaxRefinements" -> 3, "RefineExpansion" -> False];
  If[! AssociationQ[c], Return[False, Module]];
  history = c["History"];
  reviewCertificateSquareRootQ[c, 2, 10^-120] &&
    First[history]["EnclosureOrder"] === 60 && First[history]["Outcome"] === "Certified" &&
    First[history]["AccuracyGoalReached"] === False &&
    Last[history]["EnclosureOrder"] > 60 && Length[history] === c["Refinements"] + 1],
  True, TestID -> "review-certificate-successful-insufficient-attempts-increase-explicit-initial-order"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
  And @@ Table[With[{target = 2 10^(2 k)},
    reviewCertificateSquareRootQ[
      InverseCertificate[s, target, "Interval" -> 10^k {1, 2}, "RelativeError" -> 10^-120,
        "MaxRefinements" -> 3, "RefineExpansion" -> False], target, 10^-120]],
    {k, {-40, 0, 40}}]],
  True, TestID -> "review-certificate-relative-accuracy-at-small-unit-and-large-root-magnitudes"]

VerificationTest[Module[{x, y, c},
  c = InverseCertificate[AsymptoticInverse[x^2, {x, Infinity}, {y, 1}], 4,
    "Interval" -> {1, 2}, "Center" -> 11/10, "TargetError" -> 1, "MaxRefinements" -> 0];
  AssociationQ[c] && TrueQ[c["Certified"] && c["AccuracyGoalReached"] &&
    c["RootEnclosure"][[1]] <= 2 <= c["RootEnclosure"][[2]] &&
    c["ResidualRadius"] > 1] && c["CertifiedErrorBound"] === 9/10 &&
    c["ResidualRadius"] === c["ResidualAbsoluteBound"]/c["DerivativeLowerBound"] &&
    c["Refinements"] === 0],
  True, TestID -> "review-certificate-sharp-root-interval-improves-the-reported-center-error"]

VerificationTest[Module[{x, y, result, data, best},
  result = InverseCertificate[AsymptoticInverse[x^2, {x, Infinity}, {y, 1}], 2,
    "Interval" -> {1, 2}, "RelativeError" -> 10^-120, "EnclosureOrder" -> 60,
    "MaxRefinements" -> 0, "RefineExpansion" -> False];
  If[! MatchQ[result, Failure["AccuracyNotReached", _Association]], Return[False, Module]];
  data = result[[2]]; best = data["BestCertificate"];
  data["Certified"] === False && data["AccuracyGoalReached"] === False &&
    data["StoppingReason"] === "RefinementBudgetExhausted" &&
    data["EnclosureOrderLimitReached"] === False && data["Refinements"] === 0 &&
    Length[data["History"]] === 1 && best["Certified"] === True && best["AccuracyGoalReached"] === False &&
    TrueQ[best["RootEnclosure"][[1]]^2 <= 2 <= best["RootEnclosure"][[2]]^2]],
  True, TestID -> "review-certificate-zero-refinement-budget-retains-proof-without-accuracy-claim"]

VerificationTest[Module[{x, y, c, history},
  c = InverseCertificate[AsymptoticInverse[x + x^2, {x, 0}, {y, 2}], 1/10,
    "Interval" -> {1/20, 1/5}, "TargetError" -> 10^-20, WorkingPrecision -> 10,
    "EnclosureOrder" -> 2000, "MaxRefinements" -> 6, "RefineExpansion" -> False];
  If[! AssociationQ[c], Return[False, Module]];
  history = c["History"];
  TrueQ[c["AccuracyGoalReached"] && c["CertifiedErrorBound"] <= 10^-20 &&
    c["RootEnclosure"][[1]] + c["RootEnclosure"][[1]]^2 <= 1/10 <=
      c["RootEnclosure"][[2]] + c["RootEnclosure"][[2]]^2] &&
    Length[history] > 1 && AllTrue[history, #["EnclosureOrder"] === 2000 &]],
  True, TestID -> "review-certificate-arithmetic-cap-does-not-stop-interval-contraction"]

VerificationTest[Module[{x, y, result, data},
  result = InverseCertificate[AsymptoticInverse[x^2, {x, Infinity}, {y, 1}], 2,
    "Interval" -> {1, 2}, "RelativeError" -> 10^-4000, "EnclosureOrder" -> 2000,
    "MaxRefinements" -> 1, "RefineExpansion" -> False];
  If[! MatchQ[result, Failure["AccuracyNotReached", _Association]], Return[False, Module]];
  data = result[[2]];
  data["StoppingReason"] === "RefinementBudgetExhausted" &&
    data["EnclosureOrderLimitReached"] === True && data["EnclosureOrderLimit"] === 2000 &&
    data["FinalEnclosureOrder"] === 2000 && data["Refinements"] === 1 &&
    Length[data["History"]] === 2 && data["BestCertificate"]["Certified"] === True &&
    data["AccuracyGoalReached"] === False],
  True, TestID -> "review-certificate-budget-exhaustion-reports-an-active-arithmetic-cap-separately"]

VerificationTest[Module[{x, y, s, results},
  s = AsymptoticInverse[x, {x, 0}, {y, 2}];
  results = {
    InverseCertificate[s, 1, "Interval" -> {1/2, 3/2}, "Center" -> 1,
      "TargetError" -> 10^-10000, "MaxRefinements" -> 0],
    InverseCertificate[s, 1, "Interval" -> {1/2, 3/2}, "Center" -> 1,
      "RelativeError" -> 10^-10000, "MaxRefinements" -> 0],
    InverseCertificate[s, 1, "Interval" -> {1/2, 3/2}, "Center" -> 1,
      WorkingPrecision -> 2000, "MaxRefinements" -> 0]};
  AllTrue[results, AssociationQ[#] && #["CertifiedErrorBound"] === 0 &&
      #["RootEnclosure"] === {1, 1} && #["AccuracyGoalReached"] === True &&
      First[#["History"]]["EnclosureOrder"] === 2000 &]],
  True, TestID -> "review-certificate-capped-automatic-order-still-accepts-exact-identity-roots"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
  MatchQ[#, Failure["AccuracyFloor", _Association]] & /@ {
    InverseCertificate[s, 2, "Interval" -> {1, 2}, "Center" -> 3/2, "TargetError" -> 1/1000],
    InverseCertificate[s, 2, "Interval" -> {1, 2}, "Center" -> 3/2, "RelativeError" -> 1/1000]}],
  {True, True}, TestID -> "review-certificate-fixed-center-absolute-and-relative-floors-remain-authoritative"]

VerificationTest[Module[{x, y, s, fallback, relativeOnly},
  s = AsymptoticInverse[x, {x, -1}, {y, 2}];
  fallback = InverseCertificate[s, 0, "Interval" -> {-1/2, 1/2}, "Center" -> 0,
    "RelativeError" -> 10^-120, "TargetError" -> 10^-150];
  relativeOnly = InverseCertificate[s, 0, "Interval" -> {-1/2, 1/2}, "Center" -> 0,
    "RelativeError" -> 10^-120];
  {AssociationQ[fallback] && fallback["RootEnclosure"] === {0, 0} && fallback["AccuracyGoalReached"] === True,
    MatchQ[relativeOnly, Failure["RelativeAccuracyAtZero", _Association]] &&
      relativeOnly[[2]]["BestCertificate"]["AccuracyGoalReached"] === False}],
  {True, True}, TestID -> "review-certificate-zero-root-needs-absolute-fallback-even-at-high-relative-precision"]

VerificationTest[Module[{x, y, s, noRoot, outside},
  s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
  noRoot = InverseCertificate[s, 9, "Interval" -> {1, 2}, "Center" -> 3/2,
    "RelativeError" -> 10^-120, "MaxRefinements" -> 3];
  outside = InverseCertificate[s, 2, "Interval" -> {-2, -1}, "Center" -> -3/2,
    "RelativeError" -> 10^-120, "MaxRefinements" -> 0];
  {MatchQ[noRoot, Failure["ResidualBracketOutsideInterval", _Association]] &&
      noRoot[[2]]["DefinitiveNoRoot"] === True && Length[noRoot[[2]]["History"]] === 1,
    MatchQ[outside, Failure["OutsideBranch", _Association]]}],
  {True, True}, TestID -> "review-certificate-accuracy-planning-preserves-no-root-and-source-side-refusals"]

VerificationTest[Module[{x, y, s, result},
  s = AsymptoticInverse[Sin[x], {x, 0}, {y, 3}];
  result = InverseCertificate[s, 1/10, "Interval" -> {1/20, 1/5},
    "RelativeError" -> 10^-120, "MaxRefinements" -> 0];
  MatchQ[result, Failure["UnsupportedEnclosure", _Association]] &&
    result[[2]]["AccuracyGoalReached"] === False && ! KeyExistsQ[result[[2]], "BestCertificate"]],
  True, TestID -> "review-certificate-unsupported-enclosure-does-not-become-an-accuracy-only-failure"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticInverse[x, {x, 0}, {y, 2}];
  {MatchQ[InverseCertificate[s, 1, "Interval" -> {1/2, 3/2}, "Center" -> 1,
      "EnclosureOrder" -> 2001], Failure["InvalidOption", _Association]],
    MatchQ[InverseCertificate[s, 1, "Interval" -> {1/2, 3/2}, "Center" -> 1,
      "RelativeError" -> 0.001], Failure["InvalidTolerance", _Association]]}],
  {True, True}, TestID -> "review-certificate-only-automatic-order-is-capped-and-tolerances-stay-exact"]

VerificationTest[Module[{first, second, unseparated},
  first = <|"CertifiedErrorBound" -> 1/4, "SufficientAbsoluteTolerance" -> 3/400,
    "RootEnclosure" -> {3/4, 5/4}|>;
  second = <|"CertifiedErrorBound" -> 29/100, "SufficientAbsoluteTolerance" -> 9/1000,
    "RootEnclosure" -> {9/10, 11/10}|>;
  unseparated = <|"CertifiedErrorBound" -> 1, "SufficientAbsoluteTolerance" -> 0,
    "RootEnclosure" -> {-1, 1}|>;
  {AsymptoticAnalysis`Private`certBetterCertificateQ[second, first],
    AsymptoticAnalysis`Private`certBetterCertificateQ[first, second],
    AsymptoticAnalysis`Private`certBetterCertificateQ[first, first],
    AsymptoticAnalysis`Private`certBetterCertificateQ[unseparated, unseparated],
    AsymptoticAnalysis`Private`certAccuracyKey[unseparated]}],
  {True, False, False, False, {Infinity, 1, 2}},
  TestID -> "review-certificate-best-quality-uses-relative-goal-progress-and-stable-exact-ties"]

VerificationTest[Module[{x, y, s, result, data, best},
  s = AsymptoticInverse[x, {x, 0}, {y, 2}];
  (* Each synthetic attempt encloses the actual root 1 in {3/4,5/4},
     inside its verification interval. Chosen seeds worsen the center error.
     Only controller selection is under test; interval proof tests are above. *)
  result = Block[{AsymptoticAnalysis`Private`certAttempt, AsymptoticAnalysis`Private`certSeed,
      AsymptoticAnalysis`Private`certRefinedSeed},
    Clear[AsymptoticAnalysis`Private`certAttempt, AsymptoticAnalysis`Private`certSeed,
      AsymptoticAnalysis`Private`certRefinedSeed];
    AsymptoticAnalysis`Private`certSeed[___] := 1;
    AsymptoticAnalysis`Private`certRefinedSeed[_, _, iteration_, _] := If[iteration === 1, 6/5, 11/10];
    AsymptoticAnalysis`Private`certAttempt[_, _, _, _, interval_, center_, _, _, _] :=
      <|"Certified" -> True, "RootEnclosure" -> {3/4, 5/4}, "Center" -> center,
        "CertifiedErrorBound" -> Max[Abs[{3/4, 5/4} - center]],
        "ResidualRadius" -> Max[Abs[{3/4, 5/4} - center]], "CertifiedErrorLowerBound" -> 0,
        "ResidualEnclosure" -> {center - 5/4, center - 3/4}, "DerivativeLowerBound" -> 1,
        "VerificationInterval" -> interval|>;
    InverseCertificate[s, 1, "Interval" -> {1/2, 3/2}, "TargetError" -> 1/100,
      "EnclosureOrder" -> 10, "MaxRefinements" -> 2, "RefineExpansion" -> True]];
  If[! MatchQ[result, Failure["AccuracyNotReached", _Association]], Return[False, Module]];
  data = result[[2]]; best = data["BestCertificate"];
  best["Center"] === 1 && best["CertifiedErrorBound"] === 1/4 && best["Refinements"] === 0 &&
    Lookup[data["History"], "Center"] === {1, 6/5, 11/10} &&
    Lookup[data["History"], "CertifiedErrorBound"] === {1/4, 9/20, 7/20} &&
    best["AccuracyComparisonKey"] === {25, 1/4, 1/2}],
  True, TestID -> "review-certificate-budget-failure-retains-the-best-valid-attempt-not-the-last"]
