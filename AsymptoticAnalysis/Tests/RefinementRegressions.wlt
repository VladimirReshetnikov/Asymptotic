If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

refinementRegressionEqual[a_, b_] := MatchQ[a, _GeneralizedSeries] && MatchQ[b, _GeneralizedSeries] &&
  AsymptoticAnalysis`Private`refinementEqualJets[a["Blocks"], b["Blocks"] /. b["LogVariable"] -> a["LogVariable"],
    a["LogVariable"], a["Assumptions"]] && a["Remainder"] === b["Remainder"];

VerificationTest[Module[{x, y, old, refined, fresh},
  old = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}]; refined = SeriesRefine[old, 6];
  fresh = AsymptoticInverse[x + x^2, {x, 0}, {y, 6}];
  {refinementRegressionEqual[refined, fresh], refined["RefinementStatistics"]["StateOrigin"],
    refined["RefinementStatistics"]["ReusedCoefficientEvaluations"] > 0,
    refined["RefinementStatistics"]["NewCoefficientEvaluations"] > 0}],
  {True, "StoredCompleteBlocks", True, True}, TestID -> "refinement-reuses-explicit-cutoff-coefficient-prefix"]

VerificationTest[Module[{x, y, old, refined},
  old = AsymptoticInverse[x + x^2 + x^3, {x, 0}, y, SeriesTermGoal -> 3];
  refined = SeriesRefine[old, 7];
  {refinementRegressionEqual[refined, AsymptoticInverse[x + x^2 + x^3, {x, 0}, {y, 7}]],
    refined["RefinementStatistics"]["StateOrigin"],
    refined["RefinementStatistics"]["ReusedCoefficientEvaluations"] === old["ComputationState"]["CoefficientEvaluations"]}],
  {True, "RetainedLagrangeState", True}, TestID -> "refinement-reuses-term-goal-state"]

VerificationTest[Module[{x, y, first, second, third, before},
  first = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}]; second = SeriesRefine[first, 5]; before = second;
  third = SeriesRefine[second, 7];
  {second === before, third["RefinementStatistics"]["StateOrigin"],
    third["RefinementStatistics"]["NewCoefficientEvaluations"] ===
      third["ComputationState"]["CoefficientEvaluations"] - second["ComputationState"]["CoefficientEvaluations"],
    refinementRegressionEqual[third, AsymptoticInverse[x + x^2, {x, 0}, {y, 7}]]}],
  {True, "RetainedLagrangeState", True, True}, TestID -> "refinement-chain-preserves-state-and-counts-only-new-work"]

VerificationTest[Module[{x, y, old, same}, old = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
  same = SeriesRefine[old, 4];
  {Normal[same] === Normal[old], same["Remainder"] === old["Remainder"], same["RefinementStatistics"]["NewCoefficientEvaluations"]}],
  {True, True, 0}, TestID -> "refinement-unchanged-cutoff-does-no-new-coefficient-work"]

VerificationTest[Module[{x, y, f, old, refined, fresh}, f = x + x^2 (1 + Log[x]);
  old = AsymptoticInverse[f, {x, 0}, {y, 4}, Method -> "Newton", "Power" -> 2];
  refined = SeriesRefine[old, 7]; fresh = AsymptoticInverse[f, {x, 0}, {y, 7}, Method -> "Newton", "Power" -> 2];
  {refinementRegressionEqual[refined, fresh], refined["RefinementStatistics"]["StateOrigin"],
    Length[refined["RefinementStatistics"]["NewNewtonSteps"]] > 0, InverseResidual[refined]["ZeroBelowCutoff"]}],
  {True, "StoredObservableUnit", True, True}, TestID -> "refinement-recovers-newton-unit-from-power-observable"]

VerificationTest[Module[{x, y, old, second, third},
  old = AsymptoticInverse[x + x^2 + x^3, {x, 0}, {y, 3}, Method -> "Newton"];
  second = SeriesRefine[old, 5]; third = SeriesRefine[second, 8];
  {third["RefinementStatistics"]["StateOrigin"],
    Take[third["ComputationState"]["StepCutoffs"], Length[second["ComputationState"]["StepCutoffs"]]] === second["ComputationState"]["StepCutoffs"],
    refinementRegressionEqual[third, AsymptoticInverse[x + x^2 + x^3, {x, 0}, {y, 8}, Method -> "Newton"]]}],
  {"RetainedNewtonState", True, True}, TestID -> "refinement-continues-retained-newton-precision"]

VerificationTest[Module[{x, y, old, refined, fresh}, old = AsymptoticInverse[x + 1/x, {x, Infinity}, {y, 3}, Method -> "Newton"];
  refined = SeriesRefine[old, 5]; fresh = AsymptoticInverse[x + 1/x, {x, Infinity}, {y, 5}, Method -> "Newton"];
  {refinementRegressionEqual[refined, fresh], TrueQ[FullSimplify[Normal[refined] == y - 1/y - 1/y^3, y > 0]]}],
  {True, True}, TestID -> "refinement-newton-preserves-infinity-observable-transport"]

VerificationTest[Module[{x, y, f, old, refined, fresh}, f = (2 - x) + (2 - x)^2;
  old = AsymptoticInverse[f, {x, 2}, {y, 3}, Direction -> "FromBelow"];
  refined = SeriesRefine[old, 5]; fresh = AsymptoticInverse[f, {x, 2}, {y, 5}, Direction -> "FromBelow"];
  {refinementRegressionEqual[refined, fresh], Expand[Normal[refined]]} /. y -> \[FormalY]],
  {True, 2 - \[FormalY] + \[FormalY]^2 - 2 \[FormalY]^3 + 5 \[FormalY]^4}, TestID -> "refinement-preserves-finite-offset-and-left-branch"]

VerificationTest[Module[{x, y, old, refined}, old = AsymptoticInverse[1/x + 1, {x, 0}, {y, 3}]; refined = SeriesRefine[old, 6];
  refinementRegressionEqual[refined, AsymptoticInverse[1/x + 1, {x, 0}, {y, 6}]]],
  True, TestID -> "refinement-preserves-negative-leading-power"]

VerificationTest[Module[{x, y, old, refined, failed, saved}, old = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}, "InputRemainder" -> {5, 3}];
  refined = SeriesRefine[old, 5]; saved = refined; failed = SeriesRefine[refined, 6];
  {refinementRegressionEqual[refined, AsymptoticInverse[x + x^2, {x, 0}, {y, 5}, "InputRemainder" -> {5, 3}]],
    refined["RemainderLogDegree"], MatchQ[failed, Failure["InsufficientInputOrder", _Association]], refined === saved}],
  {True, 3, True, True}, TestID -> "refinement-state-reuse-respects-declared-precision-cap"]

VerificationTest[Module[{x, y, old, refined}, old = AsymptoticInverse[x + x^2 + x^3, {x, 0}, {y, 3}]; refined = SeriesRefine[old, 4];
  {refinementRegressionEqual[refined, AsymptoticInverse[x + x^2 + x^3, {x, 0}, {y, 4}]], refined["RemainderPower"],
    FreeQ[refined["Blocks"][[All, 1]], 3]}],
  {True, 5, True}, TestID -> "refinement-keeps-complete-resonant-frontier-after-cancellation"]

VerificationTest[Module[{x, y, old, refined, changed, broken},
  old = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}]; refined = SeriesRefine[old, 5];
  broken = Join[refined["ComputationState"], <|"LeadingPower" -> 2|>];
  changed = GeneralizedSeries[Join[refined[[1]], <|"ComputationState" -> broken|>]];
  MatchQ[SeriesRefine[changed, 7], Failure["StaleComputationState", _Association]]],
  True, TestID -> "refinement-rejects-incompatible-retained-state"]

VerificationTest[Module[{x, y, old, refined}, old = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
  refined = SeriesRefine[old, 4, "MaxTerms" -> 4];
  {refinementRegressionEqual[refined, AsymptoticInverse[x + x^2, {x, 0}, {y, 4}, "MaxTerms" -> 4]],
    refined["RefinementStatistics"]["UncachedFrontierCoefficientEvaluations"]}],
  {True, 1}, TestID -> "refinement-frontier-cache-does-not-reduce-admissible-budget"]

VerificationTest[Module[{x, y, old, refined}, old = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}]; refined = SeriesRefine[old, 6];
  MatchQ[SeriesRefine[refined, 8, "MaxTerms" -> 1], Failure["ResourceLimit", _Association]]],
  True, TestID -> "refinement-enforces-new-resource-budget"]

VerificationTest[Module[{x, y, old, refined, coarse}, old = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}]; refined = SeriesRefine[old, 7];
  coarse = SeriesRefine[refined, 3];
  {refinementRegressionEqual[coarse, old], coarse["RefinementStatistics"]["NewCoefficientEvaluations"],
    coarse["ComputationState"] === refined["ComputationState"]}],
  {True, 0, True}, TestID -> "refinement-coarser-view-keeps-larger-cache"]

VerificationTest[Module[{x, y, s, refined}, s = AsymptoticInverse[x^2, {x, 0}, y, SeriesTermGoal -> 5]; refined = SeriesRefine[s, 8];
  {Normal[refined] === Normal[s], refined["Remainder"], refined["RefinementStatistics"]["NewCoefficientEvaluations"]}],
  {True, 0, 0}, TestID -> "refinement-exact-finite-inverse-needs-no-new-coefficients"]

VerificationTest[Module[{x, y, f, old, refined}, f = x + x^(1 + Sqrt[2]/3) + x^(1 + Sqrt[3]/3);
  old = AsymptoticInverse[f, {x, 0}, {y, 2}]; refined = SeriesRefine[old, 4];
  refinementRegressionEqual[refined, AsymptoticInverse[f, {x, 0}, {y, 4}]]],
  True, TestID -> "refinement-two-irrational-gaps-exactly-match-replay"]

VerificationTest[Module[{x, y, f, old, refined}, f = x + x^2 (1 + Log[x])^4 + x^3 (1 - Log[x])^3;
  old = AsymptoticInverse[f, {x, 0}, {y, 3}]; refined = SeriesRefine[old, 5];
  refinementRegressionEqual[refined, AsymptoticInverse[f, {x, 0}, {y, 5}]]],
  True, TestID -> "refinement-high-logarithmic-degrees-exactly-match-replay"]

VerificationTest[Module[{x, y, f, old, middle, refined, saved, state, cache, polys},
  f = x + x^2 (1 + Log[x]) + x^3 (2 - Log[x])^2;
  old = AsymptoticInverse[f, {x, 0}, {y, 3}]; middle = SeriesRefine[old, 5]; saved = middle;
  refined = SeriesRefine[middle, 7]; state = refined["ComputationState"];
  cache = state["PolynomialPowerCache"]; polys = state["Polynomials"];
  {refinementRegressionEqual[refined, AsymptoticInverse[f, {x, 0}, {y, 7}]], middle === saved,
    refined["RefinementStatistics"]["AvailablePolynomialPowers"] > 0,
    refined["RefinementStatistics"]["ReusedPolynomialPowerRequests"] > 0,
    And @@ Flatten[Table[Expand[cache[[j, n + 1]] - polys[[j]]^n] === 0,
      {j, Length[cache]}, {n, 0, Length[cache[[j]]] - 1}]]}],
  {True, True, True, True, True}, TestID -> "refinement-retains-polynomial-powers-across-successive-cutoffs"]

VerificationTest[Module[{x, y, f, old, refined, saved, state}, f = x + x^2 (1 + Log[x]);
  old = SeriesRefine[AsymptoticInverse[f, {x, 0}, {y, 3}], 5]; saved = old;
  refined = SeriesRefine[old, 7, "MaxTerms" -> 8]; state = refined["ComputationState"];
  {refinementRegressionEqual[refined, AsymptoticInverse[f, {x, 0}, {y, 7}, "MaxTerms" -> 8]], old === saved,
    state["PolynomialPowerCacheEntries"],
    state["PolynomialPowerCacheEvictions"] > old["ComputationState"]["PolynomialPowerCacheEvictions"],
    Length[state["Inside"]] + Length[state["Boundary"]] + state["PolynomialPowerCacheEntries"] <= 8}],
  {True, True, 0, True, True}, TestID -> "refinement-evicts-optional-polynomial-powers-before-growing-region"]

VerificationTest[Module[{x, y, f, old, refined}, f = x + x^2 (1 + Log[x]);
  old = AsymptoticInverse[f, {x, 0}, {y, 3}]; refined = SeriesRefine[old, 4, "MaxTerms" -> 4];
  {refinementRegressionEqual[refined, AsymptoticInverse[f, {x, 0}, {y, 4}, "MaxTerms" -> 4]],
    refined["ComputationState"]["PolynomialPowerCacheEntries"],
    refined["RefinementStatistics"]["NewPolynomialPowerEvaluations"] > 0}],
  {True, 0, True}, TestID -> "refinement-polynomial-cache-full-falls-back-without-losing-input-support"]
