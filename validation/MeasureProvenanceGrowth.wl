(* P07 / W3-04 storage measurements: retained operation recipes, refinement
   caches and eagerly stored native finite expressions. Read-only: nothing is
   asserted, and the receipt records byte counts, leaf counts, serialization
   sizes and recipe-tree shapes for a fixed set of chains. ByteCount charges
   every occurrence of a shared subexpression; MemoryInUse deltas and the
   distinct-node counts show how much of that is actually shared in memory.
   ASYMPTOTIC_VALIDATION_OUTPUT selects the JSON receipt; ASYMPTOTIC_MEASURE_ROOT
   selects another checkout root, such as an exported pre-fix baseline. *)
root = DirectoryName[DirectoryName[$InputFileName]];
(* ASYMPTOTIC_MEASURE_ROOT selects another checkout (a baseline export) to measure. *)
measureRoot = Environment["ASYMPTOTIC_MEASURE_ROOT"];
If[! StringQ[measureRoot] || measureRoot === "", measureRoot = root];
kernelDirectory = FileNameJoin[{measureRoot, "src", "Kernel"}];
sources = FileNames["*.wl", kernelDirectory];
hashes[] := Association[(FileNameTake[#] -> IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ sources];
before = hashes[];
If[Check[Get[FileNameJoin[{kernelDirectory, "AsymptoticAnalysis.wl"}]], $Failed] === $Failed ||
    ! MemberQ[$Packages, "AsymptoticAnalysis`"], Print["Package loading failed."]; Exit[2]];
output = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[! StringQ[output] || output === "",
  output = FileNameJoin[{root, "validation", "provenance-growth-measurements.json"}]];

(* Recipe tree shape: total operand nodes counted as a tree (each occurrence
   charged) and as a DAG (identical objects counted once). *)
recipeOperands[s_GeneralizedSeries] := Cases[Lookup[s[[1]], "SeriesRecipe", {None, {}}][[2]], _GeneralizedSeries];
recipeOperands[_] := {};
treeNodes[s_] := 1 + Total[treeNodes /@ recipeOperands[s]];
distinctNodes[s_] := Length[distinctSet[s]];
distinctSet[s_] := DeleteDuplicates[Flatten[{Hash[s], distinctSet /@ recipeOperands[s]}]];
recipeDepth[s_] := 1 + Max[0, recipeDepth /@ recipeOperands[s]];

SetAttributes[retained, HoldFirst];
(* Memory retained by the object beyond the pre-construction baseline, in a
   fresh evaluation so that construction garbage is released first. *)
retained[expression_] := Module[{base, held, after},
  ClearSystemCache[]; base = MemoryInUse[];
  held = expression; ClearSystemCache[]; after = MemoryInUse[];
  {held, after - base}];

measure[label_, chain_, step_, s_] := Module[{stored},
  <|"Chain" -> chain, "Step" -> step, "Label" -> label,
    "Cutoff" -> Lookup[s[[1]], "Cutoff", Missing["NoCutoff"]],
    "ByteCount" -> ByteCount[s], "LeafCount" -> LeafCount[s],
    "CompressedCharacters" -> StringLength[Compress[s]],
    "InputFormCharacters" -> StringLength[ToString[s, InputForm]],
    "RecipeTreeNodes" -> treeNodes[s], "RecipeDistinctNodes" -> distinctNodes[s],
    "RecipeDepth" -> recipeDepth[s],
    "RepresentationByteCount" -> ByteCount[Lookup[s[[1]], "SeriesRepresentation", None]],
    "RecipeByteCount" -> ByteCount[Lookup[s[[1]], "SeriesRecipe", None]],
    "TermCount" -> Length[Lookup[s[[1]], "Terms", {}]],
    "ExpressionByteCount" -> ByteCount[Lookup[s[[1]], "Expression", None]]|>];

rows = {};
timing = {};
record[label_, chain_, step_, s_, seconds_, memory_] := AppendTo[rows,
  Join[measure[label, chain, step, s], <|"ConstructionSeconds" -> seconds, "RetainedBytesEstimate" -> memory|>]];

(* Chain A: self-addition doubles the operand references at every step. *)
Module[{x, s, t, tm, mem, k},
  s = AsymptoticExpansion[Exp[x], {x, 0, 6}];
  record["AsymptoticExpansion[Exp[x], {x, 0, 6}]", "SelfAddition", 0, s, 0, 0];
  t = s;
  Do[{tm, {t, mem}} = AbsoluteTiming[retained[SeriesAdd[t, t]]];
    record["SeriesAdd[t, t]", "SelfAddition", k, t, tm, mem], {k, 1, 8}]];

(* Chain B: repeated multiplication by one fixed operand grows linearly. *)
Module[{x, s, t, tm, mem, k},
  s = AsymptoticExpansion[Exp[x], {x, 0, 6}];
  t = s;
  Do[{tm, {t, mem}} = AbsoluteTiming[retained[SeriesMultiply[t, s]]];
    record["SeriesMultiply[t, s]", "FixedMultiplication", k, t, tm, mem], {k, 1, 8}]];

(* Chain C: nested unary operations (power, log, exp) on a derived operand. *)
Module[{x, s, t, tm, mem, k},
  s = AsymptoticExpansion[x + x^2, {x, 0, 6}];
  t = s;
  Do[{tm, {t, mem}} = AbsoluteTiming[retained[SeriesPower[SeriesAdd[t, 1], 2, 6]]];
    record["SeriesPower[SeriesAdd[t, 1], 2, 6]", "NestedUnary", k, t, tm, mem], {k, 1, 8}]];

(* Refinement cache retention: an inverse at cutoff 12, its coarser view at
   4, and a replay-based refinement of a derived object. *)
Module[{x, y, s, coarse, wide, tm, mem},
  s = AsymptoticInverse[x + x^2 + x^3 Log[x], {x, 0}, {y, 12}];
  record["AsymptoticInverse[x + x^2 + x^3 Log[x], {x, 0}, {y, 12}]", "Refinement", 0, s, 0, 0];
  {tm, {coarse, mem}} = AbsoluteTiming[retained[SeriesRefine[s, 4]]];
  record["SeriesRefine[s, 4] (coarser view keeps the cache)", "Refinement", 1, coarse, tm, mem];
  {tm, {wide, mem}} = AbsoluteTiming[retained[SeriesRefine[coarse, 16]]];
  record["SeriesRefine[coarse, 16]", "Refinement", 2, wide, tm, mem]];

(* W3-04: eager Normal storage of native results with fixed sparse support. *)
nativeRows = {};
Module[{x, s, k, tm, mem, native, normalBytes},
  Do[{tm, {s, mem}} = AbsoluteTiming[retained[AsymptoticExpansion[1/(1 - x^7), {x, 0, 7 k}, "Backend" -> "Series"]]];
    native = Lookup[s[[1]], "NativeResult", None];
    AppendTo[nativeRows, <|"Request" -> "AsymptoticExpansion[1/(1 - x^7), {x, 0, 7 k}, Backend -> Series]",
      "Order" -> 7 k, "ByteCount" -> ByteCount[s], "LeafCount" -> LeafCount[s],
      "NativeByteCount" -> ByteCount[native],
      "NativeCoefficientCount" -> If[Head[native] === SeriesData, Length[native[[3]]], Missing["NotSeriesData"]],
      "ExpressionByteCount" -> ByteCount[Lookup[s[[1]], "Expression", None]],
      "ExpressionLeafCount" -> LeafCount[Lookup[s[[1]], "Expression", None]],
      "TermCount" -> Length[Lookup[s[[1]], "Terms", {}]],
      "ConstructionSeconds" -> tm, "RetainedBytesEstimate" -> mem|>], {k, 1, 8}]];

after = hashes[];
receipt = <|"Purpose" -> "P07 / W3-04 storage measurements; no assertions", "MeasuredKernelDirectory" -> kernelDirectory,
  "Version" -> $Version, "Date" -> DateString["ISODateTime"],
  "SourcesUnchanged" -> (before === after), "SourceHashes" -> before,
  "OperationChains" -> rows, "NativeSparseSupport" -> nativeRows|>;
(* Non-JSON atoms (Automatic, Missing) are recorded as strings. *)
Export[output, receipt /. {Automatic -> "Automatic", m_Missing :> ToString[m, InputForm]}, "JSON"];
Print["Sources unchanged: ", before === after];
Print[TableForm[{#["Chain"], #["Step"], #["ByteCount"], #["CompressedCharacters"], #["InputFormCharacters"], #["RecipeTreeNodes"], #["RecipeDistinctNodes"], #["RetainedBytesEstimate"]} & /@ rows,
  TableHeadings -> {None, {"Chain", "Step", "ByteCount", "Compressed", "InputForm", "TreeNodes", "Distinct", "Retained"}}]];
Print[TableForm[{#["Order"], #["ByteCount"], #["NativeByteCount"], #["ExpressionByteCount"], #["NativeCoefficientCount"], #["TermCount"]} & /@ nativeRows,
  TableHeadings -> {None, {"Order", "ByteCount", "Native", "Expression", "NativeCoefficients", "Terms"}}]];
Exit[If[before === after, 0, 1]];
