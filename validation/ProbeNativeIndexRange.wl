(* Bounded native-constructor observations; no package tests or dense arrays. *)
Module[{bound = 2^($SystemWordLength - 1), x, cases, observations, output},
 cases = {
   {"largest-denominator", {1}, 1, 2, bound - 1},
   {"denominator-overflow", {1}, 1, 2, bound},
   {"largest-endpoint", {1}, 0, bound - 1, 1},
   {"endpoint-overflow", {1}, 0, bound, 1},
   {"smallest-start-one-slot", {1}, -bound, -bound + 1, 1},
   {"smallest-start-two-slots", {1, 1}, -bound, -bound + 2, 1},
   {"start-underflow", {1}, -bound - 1, -bound + 1, 1},
   {"largest-valid-span", {1}, -bound + 1, 0, 1},
   {"span-overflow-from-smallest-start", {1}, -bound, 0, 1},
   {"span-overflow-across-zero", {1}, -1, bound - 1, 1},
   {"smallest-empty-endpoint", {}, -bound, -bound, 1},
   {"largest-empty-endpoint", {}, bound - 1, bound - 1, 1},
   {"billion-denominator-short-view", {1}, 1, 1000000007, 1000000007},
   {"reported-huge-tail", {1}, 0, 2^100, 1}};
 observations = Function[c, Module[{result, warned = False},
   result = Quiet[Check[Apply[SeriesData, Join[{x, 0}, Rest[c]]], warned = True; $Failed]];
   (* RawJSON in native 15.0.1 misformats the most-negative machine integer.
      Decimal strings also preserve these integers in readers using doubles. *)
   <|"Case" -> First[c], "Coefficients" -> c[[2]], "MinimumIndex" -> ToString[c[[3]], InputForm],
     "RemainderIndex" -> ToString[c[[4]], InputForm], "Denominator" -> ToString[c[[5]], InputForm],
     "OrderSpan" -> ToString[c[[4]] - c[[3]], InputForm], "NativeMessage" -> warned,
     "RetainedCoefficients" -> If[result === $Failed, Null, result[[3]]],
     "CoefficientsPreserved" -> If[result === $Failed, False, result[[3]] === c[[2]]]|>]] /@ cases;
 output = FileNameJoin[{DirectoryName[$InputFileName], "native-index-range-probe.json"}];
 Export[output, <|"Runtime" -> $Version, "SystemWordLength" -> $SystemWordLength,
   "Scope" -> "Fourteen bounded native SeriesData constructor observations. No package load or full test suite. Silent coefficient loss is reported separately from native diagnostics.",
   "ProbeSHA256" -> FileHash[$InputFileName, "SHA256", "HexString"],
   "Observations" -> observations|>, "RawJSON"];
 Print[output];
 Exit[If[Length[observations] === 14, 0, 1]]];
