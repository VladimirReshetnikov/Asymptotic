(* Run with wolfram -script AsymptoticAnalysis/Tests/BenchmarkPerformance.wl.
   The reference algorithms reproduce the original four implementations.
   Timings are evidence for these fixtures, not portable performance tests. *)
root = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Kernel", "AsymptoticAnalysis.wl"}]];

Begin["AsymptoticAnalysis`Private`"];
referenceMul[u_List, v_List, cut_, ell_, ass_, limit_] := Module[{raw},
  If[Length[u] Length[v] > limit, fail["ResourceLimit", "Reference Cartesian product exceeded the budget."]];
  raw = Flatten[Table[{a[[1]] + b[[1]], Expand[a[[2]] b[[2]]]}, {a, u}, {b, v}], 1];
  jetTrim[raw, cut, ell, ass]];
referencePower[j_, n_, ell_, ass_, limit_] := Nest[pMul[#, j, ell, ass, limit] &, pConst[1, ell, ass], n];
referenceDepth[m_, n_] := <|"Inside" -> Select[Tuples[Range[0, n], m], Total[#] <= n &],
  "Boundary" -> Select[Tuples[Range[0, n + 1], m], Total[#] == n + 1 &]|>;
referenceRegion[d_List, w_, inclusive_, limit_] := Module[
  {m = Length[d], inside, nodes = 0, visit, cand, frontier, ok},
  ok[t_] := If[inclusive, leq[t, w], less[t, w]];
  visit[j_, sofar_, prefix_] := Module[{k = 0},
    If[j > m, Sow[prefix]; Return[Null, Module]];
    While[ok[sofar + k d[[j]]],
      nodes++; If[nodes > limit, fail["ResourceLimit", "Reference enumeration exceeded budget."]];
      visit[j + 1, sofar + k d[[j]], Append[prefix, k]]; k++]];
  inside = Reap[visit[1, 0, {}]][[2]];
  inside = If[inside === {}, {}, First[inside]];
  cand = DeleteDuplicates[Flatten[Table[v + UnitVector[m, j], {v, inside}, {j, m}], 1]];
  frontier = Select[cand, ! ok[# . d] &];
  <|"Inside" -> inside, "Boundary" -> frontier|>];

SetAttributes[measure, HoldAll];
measure[label_, previous_, current_] := Module[{before, after},
  before = AbsoluteTiming[previous]; after = AbsoluteTiming[current];
  <|"Fixture" -> label, "ReferenceSeconds" -> First[before], "CurrentSeconds" -> First[after],
    "Speedup" -> First[before]/First[after], "SameResult" -> SameQ[Last[before], Last[after]]|>];
u = Table[{k, 1}, {k, 0, 199}];
results = {
  measure["200-by-200 product below weight 5 (15 retained pairs)",
    referenceMul[u, u, 5, ell, True, 40000], jetMul[u, u, 5, ell, True, 40000]],
  measure["Exact monomial raised to power 2048",
    referencePower[{{{3, 1}}, Infinity, 0}, 2048, ell, True, 1],
    pIntegerPower[{{{3, 1}}, Infinity, 0}, 2048, ell, True, 1]],
  measure["Depth 2 in 10 dimensions (286 output indices)",
    referenceDepth[10, 2], depthRegion[10, 2, 286]],
  measure["Weighted region {1,2,3,5} below 20",
    referenceRegion[{1, 2, 3, 5}, 20, False, 20000], indexRegion[{1, 2, 3, 5}, 20, False, 20000]]};
Print[ExportString[<|"Kernel" -> $Version, "Results" -> results|>, "RawJSON"]];
Exit[If[And @@ Lookup[results, "SameResult"], 0, 1]];
End[];
