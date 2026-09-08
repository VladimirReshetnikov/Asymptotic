(* One bounded pass through every family. Larger campaigns are explicit and
   preserve their input, native kernel version, results and shrunken failures. *)
Block[{AsymptoticInverse`GeneratedCampaign`$LibraryOnly = True},
  Get[FileNameJoin[{DirectoryName[$TestFileName], "RunGeneratedCampaign.wl"}]]];

Do[With[{case = c}, VerificationTest[
  Module[{result = AsymptoticInverse`GeneratedCampaign`evaluateCase[case, 30]},
    If[TrueQ[result["Passed"]], True, result]], True,
  TestID -> "generated-advanced-seed-236369-" <> ToString[case["Index"]] <> "-" <> case["Family"]]],
  {c, AsymptoticInverse`GeneratedCampaign`generateCases[236369, 16]}];

VerificationTest[
  AsymptoticInverse`GeneratedCampaign`generateCases[236369, 16] ===
    AsymptoticInverse`GeneratedCampaign`generateCases[236369, 16], True,
  TestID -> "generated-campaign-repeats-the-recorded-seed-exactly"]

VerificationTest[Module[{case, result, predicate},
  case = AsymptoticInverse`GeneratedCampaign`generateCases[236369, 3][[3]];
  predicate = Function[c, <|"Passed" -> False, "FailureClass" -> "SyntheticFailure"|>];
  result = AsymptoticInverse`GeneratedCampaign`shrinkFailure[case, "SyntheticFailure", predicate, 8, 5];
  result["OriginalCase"] === case && result["Attempts"] <= 8 &&
    Length[result["ReducedCase"]["Gaps"]] === 1 &&
    AsymptoticInverse`GeneratedCampaign`lexLess[result["ReducedComplexity"], result["OriginalComplexity"]]], True,
  TestID -> "generated-shrinker-preserves-original-and-strictly-reduces-complexity"]

VerificationTest[Module[{case, result},
  case = First[AsymptoticInverse`GeneratedCampaign`generateCases[236369, 1]];
  result = AsymptoticInverse`GeneratedCampaign`shrinkFailure[case, "CoefficientMismatch",
    Function[c, <|"Passed" -> False, "FailureClass" -> "DifferentFailure"|>], 4, 5];
  {result["ReducedCase"] === case, Length[result["AcceptedShrinks"]], result["Attempts"]}],
  {True, 0, 4}, TestID -> "generated-shrinker-does-not-change-the-failure-contract"]
