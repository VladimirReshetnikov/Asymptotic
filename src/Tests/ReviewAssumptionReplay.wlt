(* C05 follow-up: delayed options are evaluated once at the public boundary.
   Replayed constructors and retained representations use the resulting
   predicate, independently of later ambient assumptions or option values. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

reviewAssumptionReplayEquivalent[actual_, expected_, assumptions_: True] :=
  Block[{$Assumptions = True},
    TrueQ[FullSimplify[Equivalent[actual, expected], Assumptions -> assumptions]]];
reviewAssumptionReplayEqual[actual_, expected_, assumptions_: True] :=
  Block[{$Assumptions = True},
    TrueQ[FullSimplify[actual == expected, Assumptions -> assumptions]]];
reviewAssumptionReplayStored[s_, expected_] := MatchQ[s, _GeneralizedSeries] &&
  reviewAssumptionReplayEquivalent[s["Assumptions"], expected];

VerificationTest[
  Module[{x, a, calls = 0, s},
    s = Assuming[a < 0,
      AsymptoticExpansion[Sqrt[a^2] + x, {x, 0, 2},
        Assumptions :> (calls++; a > 0)]];
    calls === 1 && reviewAssumptionReplayStored[s, a > 0] &&
      reviewAssumptionReplayEqual[Normal[s], a + x]],
  True, TestID -> "review-assumption-replay-delayed-forward-option-evaluates-once"]

VerificationTest[
  Module[{x, y, a, calls = 0, s},
    s = Assuming[a < 0,
      AsymptoticInverse[a x + x^2, {x, 0}, {y, 3},
        {{Assumptions :> (calls++; a > 0)}, {"MaxTerms" -> 200}}]];
    calls === 1 && reviewAssumptionReplayStored[s, a > 0] &&
      reviewAssumptionReplayEqual[Normal[s], y/a - y^2/a^3, a > 0 && y > 0]],
  True, TestID -> "review-assumption-replay-nested-option-lists-materialize-delayed-assumptions"]

VerificationTest[
  Module[{x, y, a, calls = 0, s},
    s = AsymptoticInverse[Exp[-a/x], {x, 0}, {y, 3},
      Assumptions :> (calls++; a > 0)];
    calls === 1 && reviewAssumptionReplayStored[s, a > 0] &&
      reviewAssumptionReplayStored[s["CoordinateSeries"], a > 0] &&
      reviewAssumptionReplayEqual[Normal[s], -a/Log[y], a > 0 && 0 < y < 1] &&
      s["Remainder"] === 0],
  True, TestID -> "review-assumption-replay-target-log-chart-forwards-materialized-predicate"]

VerificationTest[
  Module[{x, y, a, calls = 0, s},
    s = AsymptoticInverse[a Log[x], {x, 0}, {y, 3},
      Assumptions :> (calls++; a > 0)];
    calls === 1 && reviewAssumptionReplayStored[s, a > 0] &&
      reviewAssumptionReplayStored[s["CoordinateSeries"], a > 0] &&
      reviewAssumptionReplayEqual[Normal[s], Exp[y/a], a > 0 && y < 0] &&
      s["Remainder"] === 0],
  True, TestID -> "review-assumption-replay-source-exponential-chart-forwards-materialized-predicate"]

VerificationTest[
  Module[{x, y, b, automaticCalls = 0, directCalls = 0, automatic, direct},
    automatic = AsymptoticInverse[x (1 + b/Log[x]), {x, 0}, {y, 3},
      Assumptions :> (automaticCalls++; Element[b, Reals])];
    direct = AsymptoticLogarithmicInverse[x (1 + b/Log[x]), {x, 0}, {y, 3},
      Assumptions :> (directCalls++; Element[b, Reals])];
    automaticCalls === 1 && directCalls === 1 &&
      reviewAssumptionReplayStored[automatic, Element[b, Reals]] &&
      reviewAssumptionReplayStored[direct, Element[b, Reals]] &&
      reviewAssumptionReplayEqual[Cases[automatic["Terms"], {1, c_} :> c], {b}] &&
      reviewAssumptionReplayEqual[Cases[direct["Terms"], {1, c_} :> c], {b}]],
  True, TestID -> "review-assumption-replay-logarithmic-dispatch-evaluates-each-public-option-once"]

VerificationTest[
  Module[{x, a, calls = 0, predicate, s, refined},
    predicate = a > 0;
    s = AsymptoticExpansion[Sqrt[a^2] + Sin[x], {x, 0, 2},
      Assumptions :> (calls++; predicate)];
    predicate = a < 0;
    refined = Assuming[a < 0, SeriesRefine[s, 4]];
    calls === 1 && reviewAssumptionReplayStored[s, a > 0] &&
      reviewAssumptionReplayStored[refined, a > 0] &&
      reviewAssumptionReplayEqual[Normal[refined], a + x - x^3/6]],
  True, TestID -> "review-assumption-replay-refinement-does-not-reevaluate-a-delayed-predicate"]

VerificationTest[
  Module[{x, y, a, s},
    s = Assuming[a > 0, AsymptoticCoreInverse[x, a x^2, {x, 0}, {y, 1}]];
    reviewAssumptionReplayStored[s, a > 0] &&
      reviewAssumptionReplayEqual[Normal[s], y - a y^2, a > 0 && y > 0]],
  True, TestID -> "review-assumption-replay-core-constructor-captures-ambient-parameter"]

VerificationTest[
  Module[{x, y, a, s, v},
    s = Assuming[a > 0,
      AsymptoticExponentialCoreInverse[x Exp[x], a x^2, {x, Infinity}, {y, 1}]];
    If[! reviewAssumptionReplayStored[s, a > 0], False,
      v = s["LocalVariable"];
      TrueQ[Together[s["LocalSectorCoefficients"][[1, 2]] + a v^2/(v + 1)] === 0]]],
  True, TestID -> "review-assumption-replay-exponential-core-constructor-captures-ambient-parameter"]

VerificationTest[
  Module[{x, y, a, s, refined, recorded},
    s = Assuming[a > 0,
      AsymptoticSpecialInverse["QuadraticThreshold", {x, 0}, {y, 1},
        "TargetScale" -> a]];
    If[! reviewAssumptionReplayStored[s, a > 0], False,
      recorded = Assumptions /. s["AdapterOptions"];
      refined = Assuming[a < 0, SeriesRefine[s, 2]];
      reviewAssumptionReplayEquivalent[recorded, a > 0] &&
        reviewAssumptionReplayStored[refined, a > 0] &&
        reviewAssumptionReplayEqual[Normal[refined], Sqrt[y/a], a > 0 && y > 0] &&
        refined["Remainder"] === 0]],
  True, TestID -> "review-assumption-replay-special-adapter-retains-symbolic-target-scale-context"]

VerificationTest[
  Module[{x, y, a, s, refined, state},
    s = Assuming[a > 0,
      AsymptoticInverse[a x + x^2, {x, 0}, y, SeriesTermGoal -> 2]];
    If[! reviewAssumptionReplayStored[s, a > 0], False,
      state = s["ComputationState"];
      refined = Assuming[a < 0, SeriesRefine[s, 4]];
      AssociationQ[state] &&
        reviewAssumptionReplayEquivalent[Lookup[state, "Assumptions", Missing["Absent"]], a > 0] &&
        reviewAssumptionReplayStored[refined, a > 0] &&
        AssociationQ[refined["ComputationState"]] &&
        reviewAssumptionReplayEquivalent[refined["ComputationState"]["Assumptions"], a > 0] &&
        reviewAssumptionReplayEqual[Normal[refined],
          y/a - y^2/a^3 + 2 y^3/a^5, a > 0 && y > 0]]],
  True, TestID -> "review-assumption-replay-retained-computation-state-keeps-construction-context"]

VerificationTest[
  Module[{x, a, s, squared, refined, representation},
    s = AsymptoticExpansion[a + x, {x, 0, 3}, Assumptions -> a > 0];
    squared = SeriesPower[s, 2];
    refined = Assuming[a == 1, SeriesRefine[squared, 4]];
    If[! reviewAssumptionReplayStored[refined, a > 0], False,
      representation = refined["SeriesRepresentation"];
      AssociationQ[representation] &&
        reviewAssumptionReplayEquivalent[Lookup[representation, "Assumptions", Missing["Absent"]], a > 0] &&
        reviewAssumptionReplayEqual[Normal[refined], (a + x)^2] &&
        (Normal[refined] /. {a -> 2, x -> 0}) === 4]],
  True, TestID -> "review-assumption-replay-derived-series-representation-retains-unspecialized-context"]

VerificationTest[
  Module[{x, a, calls = 0, outer, inner = None},
    outer = Assuming[a > 0,
      AsymptoticExpansion[1 + x, {x, 0, 2},
        Assumptions :> (calls++;
          inner = AsymptoticExpansion[Abs[a] + x, {x, 0, 2}, Assumptions -> True];
          True)]];
    calls === 1 && reviewAssumptionReplayStored[outer, True] &&
      reviewAssumptionReplayStored[inner, True] &&
      reviewAssumptionReplayEqual[Normal[inner], Abs[a] + x] &&
      (Normal[inner] /. {a -> -2, x -> 0}) === 2],
  True, TestID -> "review-assumption-replay-delayed-callback-nested-request-isolates-explicit-true"]
