(* Compare optional native export in fresh kernels against a pinned source copy.
   One warm-up and three measured runs. Peaks are MaxMemoryUsed evaluation
   observations, not total process memory or portable performance guarantees. *)
root = Environment["ASYMPTOTIC_BENCHMARK_ROOT"];
If[! StringQ[root] || root === "", root = DirectoryName[DirectoryName[$InputFileName]]];
(* Keep immutable pre-rename roots usable with the same timed fixtures. *)
benchmarkDirectory = Which[
  FileExistsQ[FileNameJoin[{root, "src", "Kernel", "AsymptoticAnalysis.wl"}]], "src",
  FileExistsQ[FileNameJoin[{root, "AsymptoticAnalysis", "Kernel", "AsymptoticAnalysis.wl"}]], "AsymptoticAnalysis",
  True, "AsymptoticInverse"];
benchmarkPackage = If[benchmarkDirectory === "AsymptoticInverse", "AsymptoticInverse", "AsymptoticAnalysis"];
benchmarkContext = benchmarkPackage <> "`";
benchmarkKernel = FileNameJoin[{root, benchmarkDirectory, "Kernel"}];
sources = FileNames["*.wl", benchmarkKernel];
hashes[] := Association[(FileNameTake[#] -> IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ sources];
before = hashes[];
If[Check[Get[FileNameJoin[{benchmarkKernel, benchmarkPackage <> ".wl"}]], $Failed] === $Failed ||
    ! MemberQ[$Packages, benchmarkContext], Print["Benchmark package loading failed."]; Exit[2]];

SetAttributes[measure, HoldRest];
measure[name_, expression_] := Module[{warm, result, samples, values = {}},
  Print["Measuring: ", name];
  warm = TimeConstrained[expression, 120, $Aborted];
  samples = Table[With[{sample = AbsoluteTiming[MaxMemoryUsed[
      result = TimeConstrained[expression, 120, $Aborted]]]},
    AppendTo[values, result]; sample], {3}];
  <|"Fixture" -> name, "Seconds" -> samples[[All, 1]],
    "MedianSeconds" -> Median[samples[[All, 1]]],
    "EvaluationPeakBytes" -> samples[[All, 2]],
    "MedianEvaluationPeakBytes" -> Median[samples[[All, 2]]],
    "StableResult" -> (FreeQ[{warm, values}, _Failure | $Failed | $Aborted] && SameQ[warm, Sequence @@ values]),
    "Result" -> ToString[Last[values], InputForm]|>];
seriesResult[s_GeneralizedSeries] := {Normal[s], s["Remainder"]};
coord = Symbol[benchmarkContext <> "Private`localCoordinate"][x, 0, Automatic];
results = With[{benchmarkPrivatemakeInverseSeriesData = Symbol[benchmarkContext <> "Private`makeInverseSeriesData"],
  benchmarkPrivatemakeSeriesData = Symbol[benchmarkContext <> "Private`makeSeriesData"]}, {
  measure["Forward native view with a million-slot trailing gap",
    benchmarkPrivatemakeSeriesData[{{1/1000003, 1}}, x, 0, coord, {1, 0}, Log[x]]],
  measure["Inverse native view with a million-slot trailing gap",
    benchmarkPrivatemakeInverseSeriesData[{{1/1000003, 1}}, y, 0, 2, coord, {1, 0}, 1, 0]],
  measure["Public sparse fractional power with a distant remainder",
    seriesResult[AsymptoticExpansion[x^(1/1000003) + x, {x, 0, 1}]]],
  measure["Public sparse series with a wide retained gap",
    seriesResult[AsymptoticExpansion[x^(1/100003) + x + x^2, {x, 0, 2}]]],
  measure["Ordinary polynomial inverse control",
    seriesResult[AsymptoticInverse[x + x^2, {x, 0}, {y, 5}]]]
}];
unchanged = before === hashes[];
output = Environment["ASYMPTOTIC_BENCHMARK_OUTPUT"];
If[! StringQ[output] || output === "", output = FileNameJoin[{DirectoryName[$InputFileName], "review-native-export-benchmark.json"}]];
Export[output, <|"Kernel" -> $Version, "WarmupRuns" -> 1, "MeasuredRuns" -> 3,
  "Scope" -> "Native-view allocation and selected public controls; optional cache refusal is checked by regressions, while public benchmark equality compares finite expressions and remainders.",
  "PackageContext" -> benchmarkContext, "PackageDirectory" -> benchmarkDirectory, "SourcesUnchangedDuringRun" -> unchanged, "TestedSourceSHA256" -> before,
  "BenchmarkSHA256" -> IntegerString[FileHash[$InputFileName, "SHA256"], 16, 64],
  "Results" -> results|>, "RawJSON"];
Exit[If[unchanged && And @@ Lookup[results, "StableResult"], 0, 1]];
