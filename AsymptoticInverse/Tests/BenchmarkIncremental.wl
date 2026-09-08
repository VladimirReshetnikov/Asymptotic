(* Run in a fresh kernel:
     wolfram -script AsymptoticInverse/Tests/BenchmarkIncremental.wl
   Optionally set ASYMPTOTIC_BENCHMARK_OUTPUT to write the JSON result.
   Timings are observations on this kernel and machine, never test thresholds.
   The reference routines freeze the pre-incremental control flow; they call
   the same exact low-level jet algebra to isolate the algorithmic changes. *)

benchmarkRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{benchmarkRoot, "Kernel", "AsymptoticInverse.wl"}]];

Begin["AsymptoticInverse`Private`"];

benchmarkFrozenTermGoal[d_, polys_, p_, r_, ell_, ass_, goal_, limit_] := Module[
  {weight = 0, region, blocks, evaluations = 0, layers = 0},
  While[True,
   layers++;
   If[layers > 50 goal + 10, fail["ResourceLimit", "Frozen term-goal benchmark did not terminate."]];
   region = indexRegion[d, weight, True, limit];
   evaluations += Length[region["Inside"]];
   blocks = jetMerge[lagrangeCoefficient[#, d, polys, p, r, ell, ass, False] & /@
      region["Inside"], ell, ass];
   If[Length[blocks] >= goal || region["Boundary"] === {}, Break[]];
   weight = First[Sort[canon[# . d] & /@ region["Boundary"], leq]]];
  <|"Blocks" -> blocks, "CoefficientEvaluations" -> evaluations, "Layers" -> layers|>];

benchmarkIncrementalTermGoal[d_, polys_, p_, r_, ell_, ass_, goal_, limit_] := Module[{s},
  s = incrementalInverseState[d, polys, p, r, ell, ass, limit];
  While[Length[s["Blocks"]] < goal && s["NextWeight"] =!= Infinity,
   If[s["Layers"] > 50 goal + 10, fail["ResourceLimit", "Incremental benchmark did not terminate."]];
   s = advanceInverseState[s]];
  KeyTake[s, {"Blocks", "CoefficientEvaluations", "Layers"}]];

benchmarkFrozenNewton[d_List, polys_List, p_, cut_, ell_, ass_, limit_] := Module[
  {u = {}, residual, derivative, iteration = 0, maximum},
  If[d === {}, Return[{}, Module]];
  maximum = Ceiling[Log[2, N[cut/First[Sort[d, leq]]]]] + 3;
  While[True,
   residual = modelEquation[u, d, polys, p, cut, ell, ass, limit];
   If[residual === {}, Break[]];
   iteration++;
   If[iteration > maximum, fail["NewtonFailure", "Frozen Newton benchmark did not stabilize."]];
   derivative = modelEquationDerivative[u, d, polys, p, cut, ell, ass, limit];
   u = jetAdd[u,
      jetScale[jetMul[residual, jetReciprocalUnit[derivative, cut, ell, ass, limit],
        cut, ell, ass, limit], -1, ell, ass], cut, ell, ass]];
  u];

benchmarkJetEqual[a_, b_, ell_] := ListQ[a] && ListQ[b] &&
  jetMerge[Join[a, jetScale[b, -1, ell, True]], ell, True] === {};

benchmarkRecords = {};
benchmarkSuccess = True;

Module[{ell, d = {1, 2, 3}, polys, old, new, oldTime, newTime, same},
 polys = {1 + ell, 2 - ell, ell^2};
 {oldTime, old} = AbsoluteTiming[catch[benchmarkFrozenTermGoal[d, polys, 2, 1, ell, True, 8, 20000]]];
 {newTime, new} = AbsoluteTiming[catch[benchmarkIncrementalTermGoal[d, polys, 2, 1, ell, True, 8, 20000]]];
 same = AssociationQ[old] && AssociationQ[new] && benchmarkJetEqual[old["Blocks"], new["Blocks"], ell];
 benchmarkSuccess = benchmarkSuccess && same;
 AppendTo[benchmarkRecords, <|"Case" -> "normalized-term-goal-eight-logarithmic-blocks",
   "Reference" -> "Repeated complete index enumeration and coefficient evaluation",
   "Current" -> "Persistent complete-weight frontier and coefficient reuse",
   "ReferenceSeconds" -> oldTime, "CurrentSeconds" -> newTime,
   "Speedup" -> oldTime/Max[newTime, $MinMachineNumber], "ExactlyEqual" -> same,
   "ReferenceCoefficientEvaluations" -> If[AssociationQ[old], old["CoefficientEvaluations"], Null],
   "CurrentCoefficientEvaluations" -> If[AssociationQ[new], new["CoefficientEvaluations"], Null]|>]];

Module[{ell, d = {1, 2, 3}, polys = {1, 2, 3}, old, new, oldTime, newTime, same},
 {oldTime, old} = AbsoluteTiming[catch[benchmarkFrozenNewton[d, polys, 3/2, 12, ell, True, 20000]]];
 {newTime, new} = AbsoluteTiming[catch[newtonSolveDoubling[d, polys, 3/2, 12, ell, True, 20000]]];
 same = benchmarkJetEqual[old, new, ell];
 benchmarkSuccess = benchmarkSuccess && same;
 AppendTo[benchmarkRecords, <|"Case" -> "normalized-newton-twelve-weights",
   "Reference" -> "Full final precision at every Newton iteration",
   "Current" -> "Exact precision doubling with a checked residual",
   "ReferenceSeconds" -> oldTime, "CurrentSeconds" -> newTime,
   "Speedup" -> oldTime/Max[newTime, $MinMachineNumber], "ExactlyEqual" -> same|>]];

Module[{x, y, f, old, new, oldTime, newTime, same},
 f = Sum[x^j, {j, 1, 7}];
 {oldTime, old} = AbsoluteTiming[AsymptoticInverse[f, {x, 0}, {y, 12}, Method -> "Lagrange"]];
 {newTime, new} = AbsoluteTiming[AsymptoticInverse[f, {x, 0}, {y, 12}, Method -> "GroupedLagrange"]];
 same = MatchQ[old, _PowerLogSeries] && MatchQ[new, _PowerLogSeries] &&
   Expand[Normal[old] - Normal[new]] === 0 && old["Remainder"] === new["Remainder"];
 benchmarkSuccess = benchmarkSuccess && same;
 AppendTo[benchmarkRecords, <|"Case" -> "public-seven-power-forward-model-to-target-cutoff-twelve",
   "Reference" -> "Individual Lagrange method including normalization and remainder",
   "Current" -> "Grouped Lagrange method including normalization and remainder",
   "ReferenceSeconds" -> oldTime, "CurrentSeconds" -> newTime,
   "Speedup" -> oldTime/Max[newTime, $MinMachineNumber], "ExactlyEqual" -> same|>]];

benchmarkResult = <|"Kernel" -> $Version, "SystemID" -> $SystemID,
  "AllExactlyEqual" -> benchmarkSuccess, "Cases" -> benchmarkRecords,
  "Interpretation" -> "One fresh-kernel sample per implementation and case; no universal speedup is asserted."|>;
Print[ExportString[benchmarkResult, "RawJSON"]];
benchmarkOutput = Environment["ASYMPTOTIC_BENCHMARK_OUTPUT"];
If[StringQ[benchmarkOutput] && StringLength[benchmarkOutput] > 0,
 Export[benchmarkOutput, benchmarkResult, "RawJSON"]];
benchmarkExitCode = If[TrueQ[benchmarkSuccess], 0, 1];
End[];
Exit[AsymptoticInverse`Private`benchmarkExitCode];
