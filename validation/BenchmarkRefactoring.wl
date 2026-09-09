(* Run the same fixtures in fresh kernels before and after a refactor.
   ASYMPTOTIC_BENCHMARK_ROOT selects an immutable source copy; the default is
   this checkout. ASYMPTOTIC_BENCHMARK_OUTPUT selects the JSON report.
   One warm-up and three measured samples per fixture; no timing assertions. *)
benchmarkRoot = Environment["ASYMPTOTIC_BENCHMARK_ROOT"];
If[! StringQ[benchmarkRoot] || benchmarkRoot === "",
  benchmarkRoot = DirectoryName[DirectoryName[$InputFileName]]];
benchmarkSources = FileNames["*.wl", FileNameJoin[{benchmarkRoot, "AsymptoticInverse", "Kernel"}]];
benchmarkHashes[] := Association[(FileNameTake[#] -> IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ benchmarkSources];
benchmarkBefore = benchmarkHashes[];
Get[FileNameJoin[{benchmarkRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]];

benchmarkSeriesResult[s_PowerLogSeries] := {Normal[s], s["Remainder"]};
benchmarkSeriesResult[s_] := s;
SetAttributes[benchmarkMeasure, HoldRest];
benchmarkMeasure[name_, expression_] := Module[{warm, samples, values, valid},
  Print["Timing: ", name];
  warm = TimeConstrained[expression, 120, $Aborted];
  samples = Table[AbsoluteTiming[TimeConstrained[expression, 120, $Aborted]], {3}];
  values = samples[[All, 2]];
  valid = FreeQ[{warm, values}, _Failure | $Aborted | $Failed] && SameQ[warm, Sequence @@ values];
  <|"Fixture" -> name, "Seconds" -> samples[[All, 1]],
    "MedianSeconds" -> Median[samples[[All, 1]]], "StableResult" -> valid,
    "Result" -> ToString[Last[values], InputForm]|>];

benchmarkRows = Table[{k, 1 + ell^Mod[k, 4]}, {k, 0, 79}];
benchmarkMergeRows = Flatten[Table[{k Sqrt[2], (1 + ell)^4 - ell^4 + j}, {j, 0, 2}, {k, 0, 49}], 1];
benchmarkNative = SeriesData[u, 0, Table[(1 + Log[u])^Mod[k, 4], {k, 0, 39}], 0, 40, 1];
benchmarkResults = {
  benchmarkMeasure["Sparse product with a finite remainder boundary",
    AsymptoticInverse`Private`pMul[{benchmarkRows, 80, 3}, {benchmarkRows, 80, 3}, ell, True, 20000]],
  benchmarkMeasure["Merge repeated irrational weights and logarithmic polynomials",
    AsymptoticInverse`Private`jetMerge[benchmarkMergeRows, ell, True]],
  benchmarkMeasure["Import a 40-coefficient native logarithmic series",
    AsymptoticInverse`Private`specialNativeTree[benchmarkNative, u, True, 20000]],
  benchmarkMeasure["Irrational inverse with five complete blocks",
    benchmarkSeriesResult[AsymptoticExpansion[InverseFunction[
      Function[x, ConditionalExpression[x + x^Sqrt[2], x > 0]]], x -> Infinity, SeriesTermGoal -> 5]]],
  benchmarkMeasure["Gamma ratio with five correction blocks",
    benchmarkSeriesResult[AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity, SeriesTermGoal -> 5]]],
  benchmarkMeasure["Barnes G with five correction blocks",
    benchmarkSeriesResult[AsymptoticExpansion[BarnesG[x], x -> Infinity, SeriesTermGoal -> 5]]],
  benchmarkMeasure["Exact summand plus native Erfc tail",
    benchmarkSeriesResult[AsymptoticExpansion[x + Erfc[x], x -> Infinity, SeriesTermGoal -> 3]]]
};
benchmarkUnchanged = benchmarkBefore === benchmarkHashes[];
benchmarkOutput = Environment["ASYMPTOTIC_BENCHMARK_OUTPUT"];
If[! StringQ[benchmarkOutput] || benchmarkOutput === "",
  benchmarkOutput = FileNameJoin[{DirectoryName[$InputFileName], "refactoring-benchmark.json"}]];
Export[benchmarkOutput, <|"Kernel" -> $Version, "WarmupRuns" -> 1, "MeasuredRuns" -> 3,
  "Scope" -> "Seven selected fixtures; local timings are not portable performance guarantees.",
  "SourcesUnchangedDuringRun" -> benchmarkUnchanged, "TestedSourceSHA256" -> benchmarkBefore,
  "BenchmarkSHA256" -> IntegerString[FileHash[$InputFileName, "SHA256"], 16, 64],
  "Results" -> benchmarkResults|>, "RawJSON"];
Exit[If[benchmarkUnchanged && And @@ Lookup[benchmarkResults, "StableResult"], 0, 1]];
