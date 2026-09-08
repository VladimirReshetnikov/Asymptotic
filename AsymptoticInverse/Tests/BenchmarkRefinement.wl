(* Run in a fresh kernel:
     wolfram -script AsymptoticInverse/Tests/BenchmarkRefinement.wl
   ASYMPTOTIC_BENCHMARK_OUTPUT optionally names the JSON result file.
   The reference repeats the public constructor at every requested cutoff.
   The current path constructs once, then uses public SeriesRefine. Both
   include normalization, observable assembly and remainder computation.
   Exact identities and retained-state invariants determine success;
   elapsed time is an observation, never a test threshold. MaxMemoryUsed[expr]
   measures evaluation memory; ByteCount records retained result/state size.
   Memory API reference: https://reference.wolfram.com/language/ref/MaxMemoryUsed.html *)

refinementBenchmarkRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{refinementBenchmarkRoot, "Kernel", "AsymptoticInverse.wl"}]];

Begin["AsymptoticInverse`Private`"];

refinementBenchmarkEqual[a_, b_] := MatchQ[a, _PowerLogSeries] && MatchQ[b, _PowerLogSeries] &&
  refinementEqualJets[a["Blocks"], b["Blocks"] /. b["LogVariable"] -> a["LogVariable"],
    a["LogVariable"], a["Assumptions"]] && a["Remainder"] === b["Remainder"] &&
  a["ExpansionPoint"] === b["ExpansionPoint"] && a["Direction"] === b["Direction"] && a["Power"] === b["Power"];

refinementBenchmarkText[e_] := ToString[e, InputForm];

refinementBenchmarkStateValid[before_, after_, method_] := Module[{stats, state, previous},
  If[! MatchQ[after, _PowerLogSeries], Return[False, Module]];
  stats = after["RefinementStatistics"]; state = after["ComputationState"];
  If[! AssociationQ[stats] || ! AssociationQ[state], Return[False, Module]];
  If[method === "Lagrange",
    previous = before["ComputationState"];
    TrueQ[stats["ReusedCoefficientEvaluations"] > 0 &&
      stats["NewCoefficientEvaluations"] ===
        state["CoefficientEvaluations"] - stats["ReusedCoefficientEvaluations"] + stats["UncachedFrontierCoefficientEvaluations"] &&
      (! AssociationQ[previous] || stats["ReusedCoefficientEvaluations"] === previous["CoefficientEvaluations"])],
    TrueQ[stats["VerifiedNewtonResidual"]] &&
      Take[state["StepCutoffs"], Length[stats["RecordedPriorNewtonSteps"]]] === stats["RecordedPriorNewtonSteps"] &&
      leq[stats["NewtonPrecisionBefore"], stats["NewtonPrecisionAfter"]]]];

refinementBenchmarkRecord[name_, function_, x_, y_, cutoffs_, method_] := Module[
  {reference, current, referenceTime, currentTime, referencePeak, currentPeak,
   identities, stateChecks, statistics, valid, oracleChecks = {}},
  {referenceTime, referencePeak} = AbsoluteTiming[MaxMemoryUsed[
    reference = AsymptoticInverse[function, {x, 0}, {y, #}, Method -> method] & /@ cutoffs]];
  {currentTime, currentPeak} = AbsoluteTiming[MaxMemoryUsed[
    current = FoldList[If[FailureQ[#1], #1, SeriesRefine[#1, #2]] &,
      AsymptoticInverse[function, {x, 0}, {y, First[cutoffs]}, Method -> method], Rest[cutoffs]]]];
  identities = MapThread[refinementBenchmarkEqual, {reference, current}];
  stateChecks = MapThread[refinementBenchmarkStateValid[#1, #2, method] &, {Most[current], Rest[current]}];
  If[name === "deep-one-gap-catalan-oracle",
    oracleChecks = MapThread[MatchQ[#1, _PowerLogSeries] &&
      Expand[Normal[#1] - Sum[(-1)^(j - 1) CatalanNumber[j - 1] y^j, {j, 1, #2 - 1}]] === 0 &,
      {current, cutoffs}]];
  valid = And @@ Join[identities, stateChecks, oracleChecks];
  statistics = Map[If[! MatchQ[#, _PowerLogSeries], <|"Failure" -> refinementBenchmarkText[#]|>,
      With[{a = #["RefinementStatistics"]},
        <|"Strategy" -> a["Strategy"], "StateOrigin" -> a["StateOrigin"],
          "SourceCutoff" -> refinementBenchmarkText[a["SourceCutoff"]],
          "RequestedCutoff" -> refinementBenchmarkText[a["RequestedCutoff"]],
          "ReusedBlocks" -> a["ReusedBlocks"],
          "NewCoefficientEvaluations" -> a["NewCoefficientEvaluations"],
          "ReusedCoefficientEvaluations" -> Lookup[a, "ReusedCoefficientEvaluations", Null],
          "ReusedPolynomialPowerRequests" -> Lookup[a, "ReusedPolynomialPowerRequests", Null],
          "NewPolynomialPowerEvaluations" -> Lookup[a, "NewPolynomialPowerEvaluations", Null],
          "RetainedPolynomialPowers" -> Lookup[a, "RetainedPolynomialPowers", Null],
          "UncachedFrontierCoefficientEvaluations" -> Lookup[a, "UncachedFrontierCoefficientEvaluations", Null],
          "NewNewtonSteps" -> (refinementBenchmarkText /@ a["NewNewtonSteps"]),
          "NewtonPrecisionBefore" -> If[KeyExistsQ[a, "NewtonPrecisionBefore"], refinementBenchmarkText[a["NewtonPrecisionBefore"]], Null],
          "NewtonPrecisionAfter" -> If[KeyExistsQ[a, "NewtonPrecisionAfter"], refinementBenchmarkText[a["NewtonPrecisionAfter"]], Null]|>]] &, Rest[current]];
  <|"Case" -> name, "Method" -> method, "Function" -> refinementBenchmarkText[function],
    "Cutoffs" -> (refinementBenchmarkText /@ cutoffs),
    "ReferenceSeconds" -> referenceTime, "CurrentSeconds" -> currentTime,
    "ReferenceEvaluationPeakBytes" -> referencePeak, "CurrentEvaluationPeakBytes" -> currentPeak,
    "ReferenceFinalResultBytes" -> ByteCount[Last[reference]], "CurrentFinalResultBytes" -> ByteCount[Last[current]],
    "ReferenceRetainedSequenceBytes" -> ByteCount[reference], "CurrentRetainedSequenceBytes" -> ByteCount[current],
    "CurrentFinalStateBytes" -> If[MatchQ[Last[current], _PowerLogSeries], ByteCount[Last[current]["ComputationState"]], Null],
    "ObservedSpeedup" -> referenceTime/Max[currentTime, $MinMachineNumber],
    "ExactIdentityAtEveryCutoff" -> identities, "RetainedStateChecks" -> stateChecks,
    "IndependentCatalanOracleChecks" -> oracleChecks,
    "Accepted" -> valid, "Refinements" -> statistics|>];

refinementBenchmarkCases = Module[{x, y, dense, irrationalTwo, irrationalThree, resonance, highLog},
  dense = x + Sum[x^(1 + j/5), {j, 1, 5}];
  irrationalTwo = x + x^(1 + Sqrt[2]/3) + x^(1 + Sqrt[3]/3);
  irrationalThree = irrationalTwo + x^(1 + Sqrt[5]/3);
  resonance = x + x^(3/2) + 2 x^2 + x^(5/2);
  highLog = x + x^2 (1 + Log[x])^4 + x^3 (1 - Log[x])^3;
  {
    refinementBenchmarkRecord["dense-rational-five-gaps", dense, x, y, {3/2, 2, 5/2}, "Lagrange"],
    refinementBenchmarkRecord["two-irrational-gaps", irrationalTwo, x, y, {2, 5/2, 3}, "Lagrange"],
    refinementBenchmarkRecord["three-irrational-gaps", irrationalThree, x, y, {3/2, 2, 5/2}, "Lagrange"],
    refinementBenchmarkRecord["resonant-half-integer-gaps", resonance, x, y, {2, 3, 4}, "Lagrange"],
    refinementBenchmarkRecord["high-logarithmic-degree", highLog, x, y, {3, 4, 5}, "Lagrange"],
    refinementBenchmarkRecord["dense-rational-five-gaps", dense, x, y, {3/2, 2, 5/2}, "Newton"],
    refinementBenchmarkRecord["three-irrational-gaps", irrationalThree, x, y, {3/2, 2, 5/2}, "Newton"],
    refinementBenchmarkRecord["high-logarithmic-degree", highLog, x, y, {3, 4, 5}, "Newton"],
    refinementBenchmarkRecord["deep-one-gap-catalan-oracle", x + x^2, x, y, {16, 32, 64}, "Lagrange"]}];

refinementBenchmarkSuccess = And @@ Lookup[refinementBenchmarkCases, "Accepted"];
refinementBenchmarkResult = <|"Kernel" -> $Version, "SystemID" -> $SystemID,
  "Reference" -> "Repeated public AsymptoticInverse construction at all cutoffs",
  "Current" -> "One public construction followed by public SeriesRefine calls",
  "AllAccepted" -> refinementBenchmarkSuccess, "Cases" -> refinementBenchmarkCases,
  "Interpretation" -> "One sequential sample per implementation and case in one fresh kernel. Exact complete blocks, remainders, and retained-state invariants determine acceptance. Timing ratios and MaxMemoryUsed evaluation peaks are empirical; ByteCount measures retained expressions and states. These do not establish universal speedups or total-process memory bounds. The state counters describe actual new Euler calls or Newton steps, not a complete cost model."|>;
Print[ExportString[refinementBenchmarkResult, "RawJSON"]];
refinementBenchmarkOutput = Environment["ASYMPTOTIC_BENCHMARK_OUTPUT"];
If[StringQ[refinementBenchmarkOutput] && StringLength[refinementBenchmarkOutput] > 0,
  Export[refinementBenchmarkOutput, refinementBenchmarkResult, "RawJSON"]];
refinementBenchmarkExitCode = If[TrueQ[refinementBenchmarkSuccess], 0, 1];
End[];
Exit[AsymptoticInverse`Private`refinementBenchmarkExitCode];
