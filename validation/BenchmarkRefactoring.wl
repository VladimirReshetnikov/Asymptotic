(* Run the same fixtures in fresh kernels before and after a refactor.
   ASYMPTOTIC_BENCHMARK_ROOT selects an immutable source copy; the default is
   this checkout. ASYMPTOTIC_BENCHMARK_OUTPUT selects the JSON report.
   ASYMPTOTIC_BENCHMARK_SET selects Core (default), Operations, Construction
   or Composition fixtures.
   One warm-up and three measured samples per fixture; no timing assertions. *)
benchmarkRoot = Environment["ASYMPTOTIC_BENCHMARK_ROOT"];
If[! StringQ[benchmarkRoot] || benchmarkRoot === "",
  benchmarkRoot = DirectoryName[DirectoryName[$InputFileName]]];
(* Select both the current package and immutable pre-rename baselines. *)
benchmarkPackage = If[FileExistsQ[FileNameJoin[{benchmarkRoot, "AsymptoticAnalysis", "Kernel", "AsymptoticAnalysis.wl"}]],
  "AsymptoticAnalysis", "AsymptoticInverse"];
benchmarkContext = benchmarkPackage <> "`";
benchmarkKernel = FileNameJoin[{benchmarkRoot, benchmarkPackage, "Kernel"}];
benchmarkSources = FileNames["*.wl", benchmarkKernel];
benchmarkHashes[] := Association[(FileNameTake[#] -> IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ benchmarkSources];
benchmarkBefore = benchmarkHashes[];
If[Check[Get[FileNameJoin[{benchmarkKernel, benchmarkPackage <> ".wl"}]], $Failed] === $Failed ||
    ! MemberQ[$Packages, benchmarkContext], Print["Benchmark package loading failed."]; Exit[2]];

(* Accept the association-backed result from both the baseline and current
   public head, without installing a symbol from an older package version. *)
benchmarkSeriesResult[s_] := If[Length[s] === 1 && AssociationQ[First[s]],
  {Normal[s], s["Remainder"]}, Failure["UnexpandedBenchmark", <|"Result" -> s|>]];
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
benchmarkSet = Environment["ASYMPTOTIC_BENCHMARK_SET"];
If[! StringQ[benchmarkSet] || benchmarkSet === "", benchmarkSet = "Core"];
(* Resolve private helper symbols once, outside all measured evaluations. *)
benchmarkResults = With[{benchmarkPrivatefourierJetMerge = Symbol[benchmarkContext <> "Private`fourierJetMerge"],
  benchmarkPrivatefourierJetMul = Symbol[benchmarkContext <> "Private`fourierJetMul"],
  benchmarkPrivatejetMerge = Symbol[benchmarkContext <> "Private`jetMerge"],
  benchmarkPrivatelocalCoordinate = Symbol[benchmarkContext <> "Private`localCoordinate"],
  benchmarkPrivatelogarithmicPowerBuilder = Symbol[benchmarkContext <> "Private`logarithmicPowerBuilder"],
  benchmarkPrivatelogarithmicPowerConstruct = Symbol[benchmarkContext <> "Private`logarithmicPowerConstruct"],
  benchmarkPrivatepMul = Symbol[benchmarkContext <> "Private`pMul"],
  benchmarkPrivateseriesCoordinateRule = Symbol[benchmarkContext <> "Private`seriesCoordinateRule"],
  benchmarkPrivatespecialNativeTree = Symbol[benchmarkContext <> "Private`specialNativeTree"],
  benchmarkPrivatespecialParameterizedForwardJet = Symbol[benchmarkContext <> "Private`specialParameterizedForwardJet"]}, Switch[benchmarkSet, "Core", {
  benchmarkMeasure["Sparse product with a finite remainder boundary",
    benchmarkPrivatepMul[{benchmarkRows, 80, 3}, {benchmarkRows, 80, 3}, ell, True, 20000]],
  benchmarkMeasure["Merge repeated irrational weights and logarithmic polynomials",
    benchmarkPrivatejetMerge[benchmarkMergeRows, ell, True]],
  benchmarkMeasure["Import a 40-coefficient native logarithmic series",
    benchmarkPrivatespecialNativeTree[benchmarkNative, u, True, 20000]],
  benchmarkMeasure["Irrational inverse with five complete blocks",
    benchmarkSeriesResult[AsymptoticExpansion[InverseFunction[
      Function[x, ConditionalExpression[x + x^Sqrt[2], x > 0]]], x -> Infinity, SeriesTermGoal -> 5]]],
  benchmarkMeasure["Gamma ratio with five correction blocks",
    benchmarkSeriesResult[AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity, SeriesTermGoal -> 5]]],
  benchmarkMeasure["Barnes G with five correction blocks",
    benchmarkSeriesResult[AsymptoticExpansion[BarnesG[x], x -> Infinity, SeriesTermGoal -> 5]]],
  benchmarkMeasure["Exact summand plus native Erfc tail",
    benchmarkSeriesResult[AsymptoticExpansion[x + Erfc[x], x -> Infinity, SeriesTermGoal -> 3]]]
}, "Operations",
  benchmarkFourierRows = Table[{k, {{0, 1 + ell}, {Sqrt[2], 1 - ell}}}, {k, 0, 39}];
  benchmarkFourierProduct = Table[{k, {{0, 1}}}, {k, 0, 199}];
  {
    benchmarkMeasure["100 inversions of an ordinary translated coordinate",
      Last[Table[benchmarkPrivateseriesCoordinateRule[
        <|"Variable" -> x, "ScaleVariable" -> x - Sqrt[2]|>, u], {100}]]],
    benchmarkMeasure["Merge Fourier source blocks with repeated frequencies",
      benchmarkPrivatefourierJetMerge[
        Join[benchmarkFourierRows, benchmarkFourierRows], ell, True, 20000, 8]],
    benchmarkMeasure["200-by-200 Fourier source product below weight 4",
      benchmarkPrivatefourierJetMul[
        benchmarkFourierProduct, benchmarkFourierProduct, 4, ell, True, 20, 8]],
    benchmarkMeasure["Public Fourier inverse through target weight 4",
      benchmarkSeriesResult[AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 4}]]]
  }, "Construction",
  benchmarkEnvelope = AsymptoticInverse[LogGamma[x], {x, Infinity}, y, SeriesTermGoal -> 2] + 1;
  {
    benchmarkMeasure["Generalized logarithmic inverse with six blocks",
      benchmarkSeriesResult[AsymptoticLogarithmicInverse[x + x^2 Sqrt[-Log[x]],
        {x, 0}, y, SeriesTermGoal -> 6]]],
    benchmarkMeasure["Cancelled logarithmic resonance with five blocks",
      benchmarkSeriesResult[AsymptoticLogarithmicInverse[
        x + x^2 Sqrt[-Log[x]] + x^3 (-2 Log[x] - 1/2), {x, 0}, y, SeriesTermGoal -> 5]]],
    benchmarkMeasure["Lerch positive weight with twelve blocks",
      benchmarkSeriesResult[AsymptoticExpansion[LerchPhi[1/2, 2, x], x -> Infinity, SeriesTermGoal -> 12]]],
    benchmarkMeasure["Lerch negative weight with twelve blocks",
      benchmarkSeriesResult[AsymptoticExpansion[LerchPhi[-1/2, 2, x], x -> Infinity, SeriesTermGoal -> 12]]],
    benchmarkMeasure["Lerch growing order with sixteen bound moments",
      benchmarkSeriesResult[AsymptoticExpansion[LerchPhi[1/2, -31/2, x], x -> Infinity, SeriesTermGoal -> 1]]],
    benchmarkMeasure["Add an identical Gamma inverse composite operand",
      benchmarkSeriesResult[SeriesAdd[benchmarkEnvelope, benchmarkEnvelope]]],
    benchmarkMeasure["Multiply an identical Gamma inverse composite operand",
      benchmarkSeriesResult[SeriesMultiply[benchmarkEnvelope, benchmarkEnvelope]]],
    benchmarkMeasure["Add an exact scalar to a Gamma inverse composite",
      benchmarkSeriesResult[SeriesAdd[benchmarkEnvelope, 1]]]
  }, "Composition", {
    benchmarkMeasure["Six nested logarithmic regions without exact-composition checks",
      Module[{make, result, rows = {{1, 1}, {2, Sqrt[ell]}},
        coord = benchmarkPrivatelocalCoordinate[x, 0, Automatic]},
        make = If[DownValues[benchmarkPrivatelogarithmicPowerBuilder] === {},
          Function[h, benchmarkPrivatelogarithmicPowerConstruct[
            rows, 0, 1, {ell}, x + x^2 Sqrt[-Log[x]], x, 0, y, coord, h, 1, True, 20000]],
          benchmarkPrivatelogarithmicPowerBuilder[
            rows, 0, 1, {ell}, x + x^2 Sqrt[-Log[x]], x, 0, y, coord, 1, True, 20000]];
        Do[result = make[h], {h, Range[3/2, 13/2]}];
        benchmarkSeriesResult[result]]],
    benchmarkMeasure["Exact probe of a nonconstant trigamma composition",
      benchmarkPrivatespecialParameterizedForwardJet[
        PolyGamma[1, 1 + u^Sqrt[2]], u, ell, True, Infinity, 20000] === $Failed],
    benchmarkMeasure["Irrational Bessel order and argument at zero",
      benchmarkSeriesResult[AsymptoticExpansion[BesselJ[Sqrt[2], x^Sqrt[2]], {x, 0, 5}]]],
    benchmarkMeasure["Finite trigamma composition at an irrational increment",
      benchmarkSeriesResult[AsymptoticExpansion[PolyGamma[1, 1 + x^Sqrt[2]], {x, 0, 5}]]],
    benchmarkMeasure["Incomplete Gamma with irrational shape and input",
      benchmarkSeriesResult[AsymptoticExpansion[Gamma[Sqrt[2], x^Sqrt[2]], {x, 0, 5}]]],
    benchmarkMeasure["Symbolic positive hypergeometric parameter",
      benchmarkSeriesResult[AsymptoticExpansion[Hypergeometric0F1[b, x^Sqrt[2]],
        {x, 0, 5}, Assumptions -> b > 0]]],
    benchmarkMeasure["Revert a Bessel perturbation with an irrational argument",
      benchmarkSeriesResult[AsymptoticInverse[x + BesselJ[0, x^Sqrt[2]] - 1, {x, 0}, {y, 4}]]]
  }, _, Print["Unknown benchmark set: ", benchmarkSet]; Exit[2]]];
benchmarkUnchanged = benchmarkBefore === benchmarkHashes[];
benchmarkOutput = Environment["ASYMPTOTIC_BENCHMARK_OUTPUT"];
If[! StringQ[benchmarkOutput] || benchmarkOutput === "",
  benchmarkOutput = FileNameJoin[{DirectoryName[$InputFileName], ToLowerCase[benchmarkSet] <> "-refactoring-benchmark.json"}]];
Export[benchmarkOutput, <|"Kernel" -> $Version, "WarmupRuns" -> 1, "MeasuredRuns" -> 3,
  "Scope" -> "Selected fixtures; local timings are not portable performance guarantees.", "FixtureSet" -> benchmarkSet, "PackageContext" -> benchmarkContext,
  "SourcesUnchangedDuringRun" -> benchmarkUnchanged, "TestedSourceSHA256" -> benchmarkBefore,
  "BenchmarkSHA256" -> IntegerString[FileHash[$InputFileName, "SHA256"], 16, 64],
  "Results" -> benchmarkResults|>, "RawJSON"];
Exit[If[benchmarkUnchanged && And @@ Lookup[benchmarkResults, "StableResult"], 0, 1]];
