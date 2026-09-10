(* Regression specifications, supplied but NOT executed as an MUnit suite in
   this review. Load the selected package entry before TestReport[thisFile].
   Baseline N01 was observed in a separate native public-API probe.
   Expected post-fix behavior is tested below, not the baseline defect. *)

ClearAll[n01Source, n01Short, n01Noop, n01x];
n01Source = AsymptoticAnalysis`AsymptoticExpansion[
  Zeta[n01x], {n01x, Infinity, Log[4]}, "Backend" -> "Package"];
n01Short = AsymptoticAnalysis`SeriesTruncate[n01Source, Log[2]];
n01Noop = AsymptoticAnalysis`SeriesTruncate[n01Short, Log[2]];

VerificationTest[
  And[And @@ (MatchQ[#, _AsymptoticAnalysis`GeneralizedSeries] & /@
      {n01Source, n01Short, n01Noop}),
    !MissingQ[n01Short["TruncationDiscardedPart"]],
    n01Noop["TruncationDiscardedPart"] === n01Short["TruncationDiscardedPart"]],
  True, TestID -> "N01-noop-retains-discarded-part"]
VerificationTest[
  And[!MissingQ[n01Short["AbsoluteRemainderBound"]],
    n01Noop["AbsoluteRemainderBound"] === n01Short["AbsoluteRemainderBound"]],
  True, TestID -> "N01-noop-bound-unchanged"]
VerificationTest[
  {Normal[n01Noop], n01Noop["Remainder"]} ===
    {Normal[n01Short], n01Short["Remainder"]},
  True, TestID -> "N01-noop-expression-and-remainder-unchanged"]
VerificationTest[
  AsymptoticAnalysis`SeriesTruncate[n01Noop, Log[2]]["TruncationDiscardedPart"] ===
    n01Short["TruncationDiscardedPart"],
  True, TestID -> "N01-two-successive-noops"]
VerificationTest[
  MissingQ[AsymptoticAnalysis`SeriesTruncate[n01Source, Log[4]]["TruncationDiscardedPart"]],
  True, TestID -> "N01-no-spurious-history-on-original-source"]
VerificationTest[
  n01Noop["ForwardRemainderContract"]["Type"],
  "TransportedThroughTruncation", TestID -> "N01-contract-type-preserved"]
