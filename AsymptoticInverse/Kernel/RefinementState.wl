(* Reuse of ordinary inverse coefficient prefixes. No global cache is used.
   $Failed requests the existing source-replay path (for example when a new
   automatic forward expansion is needed). All returned states are values. *)

refinementInternalPower[a_] := If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], -a["Power"], a["Power"]];
refinementSignature[a_] := Module[{m = a["Model"], ell},
  ell = m["LogVariable"];
  IntegerString[Hash[{m["LeadingPower"], m["Gaps"], m["Polynomials"] /. ell -> $refinementLogMarker,
    refinementInternalPower[a], a["Assumptions"], a["Function"], a["Variables"],
    a["ExpansionPoint"], a["Direction"], a["LeadingCoefficient"]}, "SHA256"], 16, 64]];

refinementEqualJets[x_, y_, ell_, ass_] :=
  jetMerge[Join[x, jetScale[y, -1, ell, ass]], ell, ass] === {};

refinementCompatibleState[state_, a_, signature_] := Module[{m = a["Model"], aligned},
  If[KeyExistsQ[state, "ModelSignature"] && state["ModelSignature"] =!= signature,
    fail["StaleComputationState", "The retained state belongs to a different model, branch or assumptions."]];
  aligned = state /. state["LogVariable"] -> a["LogVariable"];
  If[aligned["Gaps"] =!= m["Gaps"] || aligned["Polynomials"] =!= m["Polynomials"] ||
    aligned["LeadingPower"] =!= m["LeadingPower"] || aligned["Assumptions"] =!= a["Assumptions"],
    fail["StaleComputationState", "The retained state does not match the stored inverse model."]];
  aligned];

refinementLagrangeSeed[a_, limit_, signature_] := Module[
  {state = Lookup[a, "ComputationState", None], m = a["Model"], ell = a["LogVariable"],
   ass = a["Assumptions"], hold, region, boundary, weights, rint, origin},
  rint = refinementInternalPower[a]; hold = canon[Abs[m["LeadingPower"]] a["Cutoff"] - rint];
  If[AssociationQ[state] && KeyExistsQ[state, "Boundary"],
    state = refinementCompatibleState[state, a, signature];
    If[state["Power"] =!= rint || ! refinementEqualJets[jetTrim[state["Blocks"], hold, ell, ass], a["Blocks"], ell, ass],
      fail["StaleComputationState", "The retained coefficient prefix does not match the displayed complete blocks."]];
    origin = "RetainedLagrangeState",
    region = indexRegion[m["Gaps"], hold, False, limit];
    boundary = Association[(incrementalIndexKey[#] -> {canon[# . m["Gaps"]], #}) & /@ region["Boundary"]];
    weights = canon[# . m["Gaps"]] & /@ region["Inside"];
    state = Join[incrementalInverseState[m["Gaps"], m["Polynomials"], m["LeadingPower"], rint, ell, ass, limit],
      <|"Inside" -> region["Inside"], "Boundary" -> boundary, "Blocks" -> a["Blocks"],
        "LastWeight" -> If[weights === {}, -Infinity, Last[Sort[weights, leq]]],
        "NextWeight" -> If[Length[boundary] === 0, Infinity, First[Sort[First /@ Values[boundary], leq]]],
        "CoefficientEvaluations" -> Length[region["Inside"]], "Layers" -> Length[DeleteDuplicates[weights]]|>];
    origin = "StoredCompleteBlocks"];
  If[Length[state["Inside"]] + Length[state["Boundary"]] > limit,
    fail["ResourceLimit", "The retained index region and boundary exceed the requested MaxTerms budget."]];
  {incrementalResizePolynomialCache[Join[state, <|"MaxTerms" -> limit,
    "ModelSignature" -> signature, "StateType" -> "Lagrange"|>]], origin}];

refinementLagrangeAdvance[state0_, cut_] := Module[{state = state0, omitted, first, attempts = 0, candidate, fallback, uncached = 0},
  While[state["NextWeight"] =!= Infinity && less[state["NextWeight"], cut], state = advanceInverseState[state]];
  omitted = Select[state["Blocks"], ! less[#[[1]], cut] &];
  first = state["NextWeight"];
  (* A frontier layer is evaluated as a whole, including every resonant index.
     Keep these extra coefficients in the state for the next refinement. *)
  While[omitted === {} && state["NextWeight"] =!= Infinity && attempts < 8,
    attempts++; candidate = catch[advanceInverseState[state]];
    If[FailureQ[candidate],
      If[candidate[[1]] =!= "ResourceLimit", Throw[candidate, $tag]];
      fallback = refinementNewtonFrontier[incrementalInverseRegion[state], state["Gaps"], state["Polynomials"],
        state["LeadingPower"], state["Power"], state["LogVariable"], state["Assumptions"], state["MaxTerms"]];
      Return[{state, fallback[[1]], fallback[[2]]}, Module]];
    state = candidate;
    omitted = Select[state["Blocks"], ! less[#[[1]], cut] &]];
  {state, Which[omitted =!= {}, First[omitted], first === Infinity, None, True, {first, 0}], uncached}];

refinementNewtonSeed[a_, limit_, signature_] := Module[
  {state = Lookup[a, "ComputationState", None], m = a["Model"], ell = a["LogVariable"],
   ass = a["Assumptions"], hold, rint, unit, observed, precision, origin, check},
  rint = refinementInternalPower[a]; hold = canon[Abs[m["LeadingPower"]] a["Cutoff"] - rint];
  If[AssociationQ[state] && KeyExistsQ[state, "UnitJet"],
    state = refinementCompatibleState[state, a, signature];
    If[less[state["Precision"], hold], fail["StaleComputationState", "The retained Newton state has insufficient precision for the displayed inverse."]];
    observed = jetUnitPower[state["UnitJet"], rint, hold, ell, ass, limit];
    If[! refinementEqualJets[observed, a["Blocks"], ell, ass],
      fail["StaleComputationState", "The retained Newton unit does not reproduce the displayed observable."]];
    origin = "RetainedNewtonState",
    observed = jetAdd[a["Blocks"], {{0, -1}}, hold, ell, ass];
    unit = If[rint === 1, observed,
      jetAdd[jetUnitPower[observed, 1/rint, hold, ell, ass, limit], {{0, -1}}, hold, ell, ass]];
    state = newtonInverseState[m["Gaps"], m["Polynomials"], m["LeadingPower"], ell, ass, limit];
    precision = If[state["Precision"] === Infinity, Infinity, If[less[hold, state["Precision"]], state["Precision"], hold]];
    check = If[precision === Infinity, {}, modelEquation[unit, m["Gaps"], m["Polynomials"], m["LeadingPower"], precision, ell, ass, limit]];
    If[check =!= {}, fail["StaleComputationState", "The unit recovered from the stored observable has a nonzero residual below its claimed precision."]];
    state = Join[state, <|"UnitJet" -> unit, "Precision" -> precision, "SeedPrecision" -> precision|>];
    origin = "StoredObservableUnit"];
  {Join[state, <|"MaxTerms" -> limit, "ModelSignature" -> signature, "StateType" -> "Newton",
    "ObservablePower" -> rint, "ResidualVerified" -> True|>], origin}];

(* Same complete-boundary convention as inverseFrontier, with an explicit
   count of the independent Euler-coefficient work used for the remainder. *)
refinementNewtonFrontier[region0_, d_, polys_, p_, r_, ell_, ass_, limit_] := Module[
  {region = region0, first = None, result = None, weight, near, poly, next, count = 0},
  If[d === {} || region["Boundary"] === {}, Return[{None, 0}, Module]];
  Do[weight = First[Sort[canon[# . d] & /@ region["Boundary"], leq]];
    near = Select[region["Boundary"], equal[canon[# . d], weight] &];
    count += Length[near];
    poly = jetMerge[lagrangeCoefficient[#, d, polys, p, r, ell, ass, False] & /@ near, ell, ass];
    result = {weight, If[poly === {}, 0, poly[[1, 2]]]}; If[first === None, first = result];
    If[poly =!= {}, Break[]];
    next = catch[indexRegion[d, weight, True, limit]];
    If[FailureQ[next] || next["Boundary"] === {}, result = first; Break[]]; region = next,
    {8}];
  {If[result[[2]] === 0, first, result], count}];

refinementAssemble[a_, cutoff_, blocks_, frontier_, state_, statistics_] := Module[
  {p = a["LeadingPower"], leading = a["LeadingCoefficient"], r = a["Power"], rint,
   ell = a["LogVariable"], ass = a["Assumptions"], y = a["Variable"], x, coord, v, logw,
   terms, expression, localExpression, remData, input = a["InputRemainder"], cap, remainder, frontierTerm},
  x = a["Variables"][[1]]; coord = localCoordinate[x, a["ExpansionPoint"], a["Direction"]];
  rint = refinementInternalPower[a];
  remData = If[frontier === None, None, {canon[(rint + frontier[[1]])/Abs[p]], polyDegree[frontier[[2]], ell]}];
  If[ListQ[input], cap = canon[(input[[1]] - p + rint)/Abs[p]];
    remData = If[remData === None, {cap, input[[2]]}, combinePrecision[remData, {cap, input[[2]]}]]];
  v = If[MemberQ[{Infinity, -Infinity}, a["Limit"]], y, y - a["Limit"]]; logw = Log[v/leading]/p;
  terms = {ToRadicals[canon[(rint + #[[1]])/p]], ToRadicals[#[[2]]] /. ell -> logw} & /@ blocks;
  localExpression = Total[((v/leading)^#[[1]] #[[2]]) & /@ terms];
  expression = Which[coord["Infinite"], coord["Sign"]^r localExpression,
    r === 1, a["ExpansionPoint"] + coord["Sign"] localExpression,
    True, coord["Sign"]^r localExpression];
  remainder = If[remData === None, 0, PowerLogRemainder[a["RemainderVariable"], ToRadicals[remData[[1]]], remData[[2]]]];
  frontierTerm = If[frontier === None, 0, coord["Sign"]^r (v/leading)^ToRadicals[canon[(rint + frontier[[1]])/p]]
    (ToRadicals[frontier[[2]]] /. ell -> logw)];
  PowerLogSeries[Join[a, <|"Expression" -> expression, "Terms" -> terms, "Blocks" -> blocks,
    "Remainder" -> remainder, "RemainderPower" -> If[remData === None, Infinity, ToRadicals[remData[[1]]]],
    "RemainderLogDegree" -> If[remData === None, 0, remData[[2]]],
    "RemainderScaleExpression" -> If[remainder === 0, 0, remainderScale[remainder]],
    "FrontierTerm" -> frontierTerm, "Cutoff" -> ToRadicals[cutoff], "RequestedTermGoal" -> Automatic,
    "ReturnedTermCount" -> Length[blocks], "ComputationState" -> state,
    "RefinementStatistics" -> statistics,
    "RefinementHistory" -> Append[Lookup[a, "RefinementHistory", {}], statistics],
    "SeriesData" -> makeInverseSeriesData[terms, y, a["Limit"], leading, coord, remData, r, a["ExpansionPoint"]]|>]]];

refineStoredInverse[s : PowerLogSeries[a_Association], cutoff_, limit_] := Module[
  {m, method, p, rint, cut, oldCut, cap, declared, signature, state, origin, before, after, blocks,
   frontier, stats, region, frontierWork = 0, pair, result, exactStats},
  If[Lookup[a, "Kind", ""] =!= "Inverse" || Lookup[a, "Scale", "PowerLog"] =!= "PowerLog" ||
    Lookup[a, "Truncation", "Exponent"] =!= "Exponent" || ! AssociationQ[Lookup[a, "Model", None]], Return[$Failed, Module]];
  method = a["Method"]; If[! MemberQ[{"Lagrange", "Newton"}, method], Return[$Failed, Module]];
  If[! exactRealQ[cutoff], fail["InvalidCutoff", "The refinement cutoff must be an exact real number."]];
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  m = a["Model"]; p = m["LeadingPower"]; rint = refinementInternalPower[a];
  cut = canon[Abs[p] cutoff - rint];
  If[! less[0, cut], fail["CutoffTooSmall", "The cutoff must exceed the leading exponent of the inverse observable.", <|"LeadingExponent" -> ToRadicals[rint/Abs[p]]|>]];
  If[ListQ[a["InputRemainder"]], cap = canon[(a["InputRemainder"][[1]] - p + rint)/Abs[p]];
    If[less[cap, cutoff],
      declared = Lookup[a, "DeclaredInputRemainder", a["InputRemainder"]];
      If[MemberQ[{Automatic, None}, declared] && ! TrueQ[a["ExactModel"]], Return[$Failed, Module]];
      fail["InsufficientInputOrder", "The requested refinement exceeds the precision transported from the declared forward remainder.", <|"MaximumCutoff" -> ToRadicals[cap]|>]]];
  If[a["Cutoff"] =!= Infinity && equal[cutoff, a["Cutoff"]],
    exactStats = <|"Strategy" -> "UnchangedCutoff", "SourceCutoff" -> a["Cutoff"], "RequestedCutoff" -> cutoff,
      "ModelReused" -> True, "NewCoefficientEvaluations" -> 0, "NewNewtonSteps" -> {}, "ReusedBlocks" -> Length[a["Blocks"]]|>;
    Return[PowerLogSeries[Join[a, <|"RefinementStatistics" -> exactStats,
      "RefinementHistory" -> Append[Lookup[a, "RefinementHistory", {}], exactStats]|>]], Module]];
  If[a["Remainder"] === 0 && And @@ (less[#[[1]], cut] & /@ a["Blocks"]),
    exactStats = <|"Strategy" -> "ExactFiniteInverse", "SourceCutoff" -> a["Cutoff"], "RequestedCutoff" -> cutoff,
      "ModelReused" -> True, "NewCoefficientEvaluations" -> 0, "NewNewtonSteps" -> {}, "ReusedBlocks" -> Length[a["Blocks"]]|>;
    Return[PowerLogSeries[Join[a, <|"Cutoff" -> cutoff, "RefinementStatistics" -> exactStats,
      "RefinementHistory" -> Append[Lookup[a, "RefinementHistory", {}], exactStats]|>]], Module]];
  If[a["Cutoff"] === Infinity, Return[$Failed, Module]];
  signature = refinementSignature[a];
  If[method === "Lagrange",
    {state, origin} = refinementLagrangeSeed[a, limit, signature]; before = state;
    {state, frontier, frontierWork} = refinementLagrangeAdvance[state, cut];
    blocks = jetTrim[state["Blocks"], cut, a["LogVariable"], a["Assumptions"]];
    stats = <|"Strategy" -> "IncrementalLagrange", "StateOrigin" -> origin,
      "ReusedCoefficientEvaluations" -> before["CoefficientEvaluations"],
      "NewCoefficientEvaluations" -> state["CoefficientEvaluations"] - before["CoefficientEvaluations"] + frontierWork,
      "UncachedFrontierCoefficientEvaluations" -> frontierWork,
      "TotalCachedCoefficientEvaluations" -> state["CoefficientEvaluations"],
      "NewCompleteWeightLayers" -> state["Layers"] - before["Layers"],
      "AvailablePolynomialPowers" -> before["PolynomialPowerCacheEntries"],
      "ReusedPolynomialPowerRequests" -> state["PolynomialPowerCacheHits"] - before["PolynomialPowerCacheHits"],
      "NewPolynomialPowerEvaluations" -> state["PolynomialPowerEvaluations"] - before["PolynomialPowerEvaluations"],
      "RetainedPolynomialPowers" -> state["PolynomialPowerCacheEntries"],
      "PolynomialPowerCacheCapacity" -> state["PolynomialPowerCacheCapacity"],
      "PolynomialPowerCacheEvictions" -> state["PolynomialPowerCacheEvictions"] -
        If[AssociationQ[Lookup[a, "ComputationState", None]], Lookup[a["ComputationState"], "PolynomialPowerCacheEvictions", 0], 0],
      "PolynomialPowerCountingScope" -> "Incremental coefficient generation only. Independent uncached frontier work is counted separately by UncachedFrontierCoefficientEvaluations.",
      "CachedThroughWeight" -> state["LastWeight"], "NextWeight" -> state["NextWeight"], "NewNewtonSteps" -> {}|>,
    {state, origin} = refinementNewtonSeed[a, limit, signature]; before = state;
    state = refineNewtonState[state, cut];
    blocks = jetUnitPower[state["UnitJet"], rint, cut, a["LogVariable"], a["Assumptions"], limit];
    region = indexRegion[m["Gaps"], cut, False, limit];
    {frontier, frontierWork} = refinementNewtonFrontier[region, m["Gaps"], m["Polynomials"], p, rint,
      a["LogVariable"], a["Assumptions"], limit];
    stats = <|"Strategy" -> "IncrementalNewton", "StateOrigin" -> origin,
      "NewtonPrecisionBefore" -> before["Precision"], "NewtonPrecisionAfter" -> state["Precision"],
      "NewNewtonSteps" -> Drop[state["StepCutoffs"], Length[before["StepCutoffs"]]],
      "RecordedPriorNewtonSteps" -> before["StepCutoffs"], "VerifiedNewtonResidual" -> True,
      "NewCoefficientEvaluations" -> frontierWork, "FrontierCoefficientEvaluations" -> frontierWork|>];
  stats = Join[stats, <|"SourceCutoff" -> a["Cutoff"], "RequestedCutoff" -> cutoff,
    "ModelReused" -> True, "ModelSignature" -> signature,
    "ReusedBlocks" -> Length[Select[a["Blocks"], less[#[[1]], cut] &]], "AvailableSourceBlocks" -> Length[a["Blocks"]],
    "CountingConvention" -> "ReusedCoefficientEvaluations counts available individual index contributions, reconstructed from the stored complete region when necessary; seeding does not reevaluate them. NewCoefficientEvaluations counts actual new Lagrange calls, including uncached frontier work. Newton reports new step cutoffs and independent frontier Euler evaluations. ReusedBlocks counts source blocks retained below the requested cutoff.",
    "Evidence" -> "Exact complete-block reuse and symbolic Newton residual invariants; no runtime claim is implied."|>];
  refinementAssemble[a, cutoff, blocks, frontier, state, stats]];
