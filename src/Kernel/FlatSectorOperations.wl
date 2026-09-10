(* Two independent truncations: inclusive exponential degree and exclusive
   inner power. A discarded inner coefficient remains in its own sector. *)

AsymptoticAnalysis`FlatSeriesTruncate::usage =
"FlatSeriesTruncate[s,h] truncates each positive exponential sector at the exclusive inner power h in the positive monomial core coordinate. It preserves the exact zero sector and records separate inner and exponential-sector remainders.";
AsymptoticAnalysis`FlatSeriesMultiply::usage =
"FlatSeriesMultiply[s,t] multiplies finite flat-sector expansions in the same exact monomial target chart and phase. Unknown inner errors and the complete sector tail are propagated separately. An exact finite power-log scalar is also accepted.";
AsymptoticAnalysis`FlatSeriesObservable::usage =
"FlatSeriesObservable[s,H,z] substitutes s into an exact polynomial H in z. Its coefficients may be finite real power-log expressions in the common target chart. The zero sector is evaluated exactly.";
AsymptoticAnalysis`FlatSeriesDifferentiate::usage =
"FlatSeriesDifferentiate[s,n] differentiates n times with respect to the target variable, including the derivative of the flat exponential. Nonzero remainders require the qualified exact-flat-IFT analytic derivative contract.";

Options[AsymptoticAnalysis`FlatSeriesTruncate] = {"MaxTerms" -> 20000};
Options[AsymptoticAnalysis`FlatSeriesMultiply] = {"InnerCutoff" -> Automatic, "MaxTerms" -> 20000};
Options[AsymptoticAnalysis`FlatSeriesObservable] = {"InnerCutoff" -> Automatic,
  "MaxTerms" -> 20000, "MaxPolynomialDegree" -> 32};
Options[AsymptoticAnalysis`FlatSeriesDifferentiate] = {"InnerCutoff" -> Automatic, "MaxTerms" -> 20000};

flatOpsAss[d_] := d["Assumptions"] && d["LocalVariable"] > 0;
flatOpsZero[ell_, ass_] := pConst[0, ell, ass];
flatOpsExactZeroQ[j_] := j[[1]] === {} && j[[2]] === Infinity;
flatOpsBudget[d_, limit_] := Module[{jets = d["SectorJets"]},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[Length[jets] > limit || LeafCount[jets] > limit,
    fail["ResourceLimit", "The retained flat-sector coefficient representation exceeded MaxTerms."]]; d];

flatOpsParse[e_, d_, limit_] := Module[{u = d["LocalVariable"], ell = d["LogVariable"], q, rows},
  validateInput[e, limit];
  q = Simplify[e /. d["Variable"] -> d["TargetOffset"] + d["CoreCoefficient"] u^d["CorePower"], flatOpsAss[d]];
  rows = parseFinite[q, u, ell, d["Assumptions"]];
  If[rows === $Failed || ! And @@ (exactRealQ[#[[1]]] &&
      corePerturbationRealPolynomialQ[#[[2]], ell, d["Assumptions"]] & /@ rows),
    fail["UnsupportedFlatCoefficient", "The exact coefficient must be a finite real power-log expression in the monomial core coordinate."]];
  {jetMerge[rows, ell, d["Assumptions"]], Infinity, 0}];

flatOpsData[s : GeneralizedSeries[a_Association], limit_] := Module[
  {d, model, u = Unique["flatCoordinate$"], ell = Unique["flatLog$"], n, jets, tail, proof},
  If[AssociationQ[Lookup[a, "FlatRepresentation", None]],
    Return[flatOpsBudget[a["FlatRepresentation"], limit], Module]];
  If[Lookup[a, "Kind", ""] =!= "FlatInverse" || Lookup[a, "Scale", ""] =!= "FiniteFlatSectors" ||
     ! TrueQ[Lookup[a, "ExactModel", False]],
    fail["UnsupportedFlatSeries", "Use an exact-model AsymptoticFlatInverse or an expansion produced by the explicit flat-series operations."]];
  model = a["Model"]; n = a["SectorDepth"];
  If[! AssociationQ[model] || ! IntegerQ[n] || n < 1,
    fail["InvalidFlatRepresentation", "The flat inverse has no valid monomial model or sector depth."]];
  proof = Lookup[a, "FlatAnalyticRemainder", <||>];
  d = <|"Variable" -> a["Variable"], "LocalVariable" -> u, "LogVariable" -> ell,
    "CoreCoordinate" -> a["CoreInverseCoordinate"], "CorePower" -> model["CorePower"],
    "CoreCoefficient" -> model["CoreCoefficient"], "TargetOffset" -> model["Offset"],
    "PhaseRate" -> model["PhaseRate"], "PhasePower" -> model["PhasePower"],
    "Assumptions" -> a["Assumptions"], "TargetDomain" -> a["TargetDomain"], "SectorDepth" -> n,
    "InnerCutoff" -> Infinity, "DerivativeContract" -> (AssociationQ[proof] &&
      Lookup[proof, "Type", ""] === "ExactMonomialFlatIFT" && TrueQ[Lookup[proof, "AllFixedOrders", False]]),
    "DerivativeProvenance" -> proof, "DerivativeOrder" -> 0|>;
  jets = Table[flatOpsZero[ell, a["Assumptions"]], {n + 1}];
  jets[[1]] = flatOpsParse[a["ZeroSector"], d, limit];
  Do[jets[[row[[1]] + 1]] = flatOpsParse[row[[2]], d, limit], {row, a["Sectors"]}];
  tail = Cases[a["Remainder"], PowerLogRemainder[_, rho_, degree_] :> {rho, degree}, Infinity];
  If[Length[tail] =!= 1,
    fail["InvalidFlatRepresentation", "The original flat inverse must carry one complete omitted-sector bound."]];
  flatOpsBudget[Join[d, <|"SectorJets" -> jets, "SectorTail" -> First[tail]|>], limit]];

flatOpsAlign[a_, b_] := Module[{ass = a["Assumptions"] && b["Assumptions"], aligned},
  If[a["Variable"] =!= b["Variable"] ||
    ! TrueQ[Simplify[a["CoreCoefficient"] == b["CoreCoefficient"] &&
      a["TargetOffset"] == b["TargetOffset"], ass]] ||
    ! equal[a["CorePower"], b["CorePower"]] || ! equal[a["PhasePower"], b["PhasePower"]] ||
    ! equal[a["PhaseRate"], b["PhaseRate"]],
    fail["IncompatibleFlatScales", "Flat-series operations require the same target variable, monomial chart, phase rate and phase power."]];
  aligned = b /. {b["LocalVariable"] -> a["LocalVariable"], b["LogVariable"] -> a["LogVariable"]};
  {Join[a, <|"Assumptions" -> ass, "TargetDomain" -> a["TargetDomain"] && b["TargetDomain"]|>],
   Join[aligned, <|"Assumptions" -> ass, "TargetDomain" -> a["TargetDomain"] && b["TargetDomain"]|>]}];

(* Bound a whole coefficient, including an unknown inner remainder. A finite
   exact zero has no magnitude contribution. Bounds never cancel by addition. *)
flatOpsJetBound[j_, ell_] := Module[{bound = j[[{2, 3}]]},
  If[j[[1]] =!= {}, bound = combinePrecision[bound,
    {j[[1, 1, 1]], polyDegree[j[[1, 1, 2]], ell]}]]; bound];
flatOpsBoundProduct[a_, b_] := If[a[[1]] === Infinity || b[[1]] === Infinity,
  {Infinity, 0}, {canon[a[[1]] + b[[1]]], a[[2]] + b[[2]]}];
flatOpsTailAdd[a_, b_] := combinePrecision[a, b];

flatOpsTruncateData[d0_, h_, limit_] := Module[{d = d0, jets, ell = d0["LogVariable"]},
  If[h === Automatic, Return[d, Module]];
  If[h =!= Infinity && ! exactRealQ[h], fail["InvalidCutoff", "The inner flat-sector cutoff must be an exact real number or Infinity."]];
  jets = d["SectorJets"];
  (* Sector zero remains exact, even when one of its powers exceeds h. *)
  Do[jets[[k + 1]] = seriesTrim[jets[[k + 1]], h, ell, d["Assumptions"]], {k, 1, d["SectorDepth"]}];
  flatOpsBudget[Join[d, <|"SectorJets" -> jets, "InnerCutoff" -> h|>], limit]];

(* Graded omitted-tail candidates. Every contribution omitted from a
   product or sum lives in an exponential sector k > N with an
   algebraic/logarithmic bound pair; for fixed data, a later sector is
   negligible relative to any earlier one whatever their algebraic powers,
   because the phase decides. The dominant candidates are therefore those of
   least sector, combined by the ordinary power-log dominance; only then is
   the bound weakened to the schema's sector N+1, and the least sector is
   recorded as SectorTailGrade. Combining every candidate's algebraic pair
   first would let a remote tail/tail product with a large pole control the
   whole bound and lose 2N+1 algebraic orders on a depth-N inverse square. *)
flatOpsGrade[d_] := Lookup[d, "SectorTailGrade",
  If[d["SectorTail"][[1]] === Infinity, Infinity, d["SectorDepth"] + 1]];
(* Evaluate the held bounds of the least-grade candidates only. A held
   candidate's bound is finite by construction: jets at the recorded indices
   are not exact zeros and infinite tails are never recorded, so the least
   grade over the held population equals the least grade over the finite
   evaluated population. *)
flatOpsLeastGradeCandidates[candidates_List] := Module[{finite, least},
  finite = Select[candidates, #[[1]] =!= Infinity &];
  If[finite === {}, Return[{}, Module]];
  least = Min[finite[[All, 1]]];
  {#[[1]], ReleaseHold[#[[2]]]} & /@ Select[finite, #[[1]] == least &]];
flatOpsGradedTail[candidates_List] := Module[{finite, least},
  finite = Select[candidates, #[[2, 1]] =!= Infinity && #[[1]] =!= Infinity &];
  If[finite === {}, Return[{{Infinity, 0}, Infinity}, Module]];
  least = Min[finite[[All, 1]]];
  {Fold[flatOpsTailAdd, {Infinity, 0}, Select[finite, #[[1]] == least &][[All, 2]]], least}];

flatOpsMultiplyData[a0_, b0_, limit_] := Module[
  {a, b, n, na, nb, ell, ass, convolution, first, term, aj, bj, aIndices, bIndices,
   candidates = {}, tail, grade, aBounds, bBounds, data},
  {a, b} = flatOpsAlign[a0, b0];
  {na, nb} = {a["SectorDepth"], b["SectorDepth"]}; n = Min[na, nb];
  ell = a["LogVariable"]; ass = a["Assumptions"]; aj = a["SectorJets"]; bj = b["SectorJets"];
  If[(na + 1) (nb + 1) > limit,
    fail["ResourceLimit", "The complete flat-sector convolution exceeds MaxTerms pair products."]];
  (* Only exact zeros annihilate a pair. An empty finite part with an
     unknown inner remainder still contributes in its convolution sector. *)
  aIndices = Select[Range[na + 1], ! flatOpsExactZeroQ[aj[[#]]] &];
  bIndices = Select[Range[nb + 1], ! flatOpsExactZeroQ[bj[[#]]] &];
  aBounds = flatOpsJetBound[#, ell] & /@ aj; bBounds = flatOpsJetBound[#, ell] & /@ bj;
  (* Retained sectors k <= N use full coefficient products. The first omitted
     sector N+1 is also multiplied out so that exact cancellations there are
     found; deeper omitted pairs contribute envelope products only. *)
  convolution = Table[flatOpsZero[ell, ass], {n + 1}];
  first = flatOpsZero[ell, ass];
  (* Candidates are recorded as {grade, held bound} and only those of the
     least finite grade are evaluated, since only they enter the tail. The
     selected set and the combined bound are exactly those of evaluating
     every candidate first; the quadratic population of deeper pair
     envelopes is enumerated but not materialized (wave-6 report 48 P1). *)
  Do[Which[i + j - 2 <= n,
      term = pMul[aj[[i]], bj[[j]], ell, ass, limit];
      convolution[[i + j - 1]] = pAdd[convolution[[i + j - 1]], term, ell, ass],
     i + j - 2 == n + 1,
      first = pAdd[first, pMul[aj[[i]], bj[[j]], ell, ass, limit], ell, ass],
     True,
      AppendTo[candidates, {i + j - 2, With[{p = aBounds[[i]], q = bBounds[[j]]}, Hold[flatOpsBoundProduct[p, q]]]}]],
    {i, aIndices}, {j, bIndices}];
  If[! flatOpsExactZeroQ[first], AppendTo[candidates, {n + 1, With[{p = first}, Hold[flatOpsJetBound[p, ell]]]}]];
  (* An input tail sits at its recorded grade, which can exceed its depth+1. *)
  If[a["SectorTail"][[1]] =!= Infinity && flatOpsGrade[a] =!= Infinity,
    Do[AppendTo[candidates, {flatOpsGrade[a] + j - 1, With[{p = a["SectorTail"], q = bBounds[[j]]}, Hold[flatOpsBoundProduct[p, q]]]}], {j, bIndices}]];
  If[b["SectorTail"][[1]] =!= Infinity && flatOpsGrade[b] =!= Infinity,
    Do[AppendTo[candidates, {flatOpsGrade[b] + i - 1, With[{p = b["SectorTail"], q = aBounds[[i]]}, Hold[flatOpsBoundProduct[p, q]]]}], {i, aIndices}]];
  If[a["SectorTail"][[1]] =!= Infinity && b["SectorTail"][[1]] =!= Infinity &&
      flatOpsGrade[a] =!= Infinity && flatOpsGrade[b] =!= Infinity,
    AppendTo[candidates, {flatOpsGrade[a] + flatOpsGrade[b], With[{p = a["SectorTail"], q = b["SectorTail"]}, Hold[flatOpsBoundProduct[p, q]]]}]];
  {tail, grade} = flatOpsGradedTail[flatOpsLeastGradeCandidates[candidates]];
  data = Join[a, <|"SectorDepth" -> n, "SectorJets" -> convolution, "SectorTail" -> tail,
    "SectorTailGrade" -> grade,
    "InnerCutoff" -> Automatic, "DerivativeContract" -> (TrueQ[a["DerivativeContract"]] && TrueQ[b["DerivativeContract"]]),
    "DerivativeProvenance" -> <|"Type" -> "ClosedUnderFlatOperations",
      "Inputs" -> {a["DerivativeProvenance"], b["DerivativeProvenance"]}|>|>];
  flatOpsBudget[data, limit]];

flatOpsConstantData[e_, d_, limit_] := Module[{j = flatOpsParse[e, d, limit], jets},
  jets = Prepend[Table[flatOpsZero[d["LogVariable"], d["Assumptions"]], {d["SectorDepth"]}], j];
  flatOpsBudget[Join[d, <|"SectorJets" -> jets, "SectorTail" -> {Infinity, 0}, "SectorTailGrade" -> Infinity,
    "InnerCutoff" -> Infinity, "DerivativeContract" -> True,
    "DerivativeProvenance" -> <|"Type" -> "ExactFinitePowerLogCoefficient"|>|>], limit]];

flatOpsAddData[a0_, b0_, limit_] := Module[{a, b, jets, tail, grade},
  {a, b} = flatOpsAlign[a0, b0];
  If[a["SectorDepth"] =!= b["SectorDepth"], fail["FlatSectorInvariant", "Internal polynomial addition requires equal retained sector depths."]];
  jets = MapThread[pAdd[#1, #2, a["LogVariable"], a["Assumptions"]] &, {a["SectorJets"], b["SectorJets"]}];
  {tail, grade} = flatOpsGradedTail[{{flatOpsGrade[a], a["SectorTail"]}, {flatOpsGrade[b], b["SectorTail"]}}];
  flatOpsBudget[Join[a, <|"SectorJets" -> jets, "SectorTail" -> tail, "SectorTailGrade" -> grade,
    "InnerCutoff" -> Automatic, "DerivativeContract" -> (TrueQ[a["DerivativeContract"]] && TrueQ[b["DerivativeContract"]]),
    "DerivativeProvenance" -> <|"Type" -> "ClosedUnderFlatOperations",
      "Inputs" -> {a["DerivativeProvenance"], b["DerivativeProvenance"]}|>|>], limit]];

flatOpsObservableData[d_, h_, z_, degreeLimit_, limit_] := Module[{coefficients, result, degree},
  validateInput[h, limit];
  If[z === d["Variable"] || ! PolynomialQ[h, z],
    fail["UnsupportedFlatObservable", "The observable must be polynomial in a separate formal variable."]];
  If[! IntegerQ[degreeLimit] || degreeLimit < 0,
    fail["InvalidOption", "MaxPolynomialDegree must be a nonnegative integer."]];
  degree = If[h === 0, 0, Exponent[h, z]];
  If[degree > degreeLimit || degree + 1 > limit,
    fail["ResourceLimit", "The polynomial flat observable exceeds its degree budget."]];
  coefficients = CoefficientList[Expand[h], z]; If[coefficients === {}, coefficients = {0}];
  result = flatOpsConstantData[Last[coefficients], d, limit];
  Do[result = flatOpsAddData[flatOpsMultiplyData[result, d, limit],
      flatOpsConstantData[coefficients[[j]], d, limit], limit], {j, Length[coefficients] - 1, 1, -1}];
  result];

flatOpsDerivativeJet[j_, k_, d_, limit_] := Module[
  {q = d["CorePower"], a = d["CoreCoefficient"], p = d["PhasePower"], c = d["PhaseRate"],
   ell = d["LogVariable"], ass = d["Assumptions"], rows, rho, degree = j[[3]], boundary},
  rows = ({canon[#[[1]] - q], (#[[1]] #[[2]] + D[#[[2]], ell])/(a q)} &) /@ j[[1]];
  If[k > 0, rows = Join[rows, ({canon[#[[1]] - p - q], k c p #[[2]]/(a q)} &) /@ j[[1]]]];
  rho = If[j[[2]] === Infinity, Infinity, canon[j[[2]] - q - If[k > 0, p, 0]]];
  rows = jetMerge[rows, ell, ass];
  If[rho =!= Infinity,
    boundary = Select[rows, equal[#[[1]], rho] &];
    If[boundary =!= {}, degree = Max[degree, polyDegree[Total[boundary[[All, 2]]], ell]]]];
  {jetTrim[rows, rho, ell, ass], rho, degree}];

flatOpsDifferentiateData[d0_, n_, limit_] := Module[{d = d0, jets, tail, loss, hasError},
  If[! IntegerQ[n] || n < 0, fail["InvalidDerivativeOrder", "The flat derivative order must be a nonnegative integer."]];
  If[n > limit, fail["ResourceLimit", "The flat derivative order exceeds MaxTerms."]];
  hasError = d["SectorTail"][[1]] =!= Infinity || AnyTrue[d["SectorJets"], #[[2]] =!= Infinity &];
  If[n > 0 && hasError && ! TrueQ[d["DerivativeContract"]],
    fail["UnprovedFlatRemainderDerivative", "Differentiating a nonzero flat remainder requires the exact monomial flat-IFT analytic derivative contract."]];
  loss = canon[d["PhasePower"] + d["CorePower"]];
  Do[jets = MapIndexed[flatOpsDerivativeJet[#1, First[#2] - 1, d, limit] &, d["SectorJets"]];
    tail = d["SectorTail"]; If[tail[[1]] =!= Infinity, tail = {canon[tail[[1]] - loss], tail[[2]]}];
    d = flatOpsBudget[Join[d, <|"SectorJets" -> jets, "SectorTail" -> tail,
      "InnerCutoff" -> Automatic, "DerivativeOrder" -> d["DerivativeOrder"] + 1|>], limit], {n}]; d];

flatOpsMake[d_, recipe_] := Module[
  {u0 = d["CoreCoordinate"], ell = d["LogVariable"], phase, jets = d["SectorJets"], sectors, zero,
   inner, tail = d["SectorTail"], sectorRemainder, remainder, envelope, expression, coefficient},
  phase = Exp[-d["PhaseRate"]/u0^d["PhasePower"]];
  coefficient[j_] := Total[(u0^#[[1]] (#[[2]] /. ell -> Log[u0])) & /@ j[[1]]];
  zero = coefficient[First[jets]];
  sectors = Select[Table[{k, coefficient[jets[[k + 1]]]}, {k, d["SectorDepth"]}], ! zeroQ[#[[2]], d["Assumptions"]] &];
  expression = zero + Total[(#[[2]] phase^#[[1]]) & /@ sectors];
  inner = Select[Table[{k, If[jets[[k + 1, 2]] === Infinity, 0,
    PowerLogRemainder[u0, jets[[k + 1, 2]], jets[[k + 1, 3]]]]}, {k, 1, d["SectorDepth"]}], #[[2]] =!= 0 &];
  sectorRemainder = If[tail[[1]] === Infinity, 0,
    phase^(d["SectorDepth"] + 1) PowerLogRemainder[u0, tail[[1]], tail[[2]]]];
  remainder = sectorRemainder + Total[(phase^#[[1]] #[[2]]) & /@ inner];
  envelope = remainder /. rr_PowerLogRemainder :> remainderScale[rr];
  GeneralizedSeries[<|"Kind" -> "FlatDerived", "Scale" -> "FiniteFlatSectors", "Variable" -> d["Variable"],
    "Expression" -> expression, "Assumptions" -> d["Assumptions"], "TargetDomain" -> d["TargetDomain"],
    "CoreInverseCoordinate" -> u0, "FlatScale" -> phase, "ZeroSector" -> zero, "Sectors" -> sectors,
    "Terms" -> Join[{{0, zero}}, sectors], "SectorDepth" -> d["SectorDepth"], "InnerCutoff" -> d["InnerCutoff"],
    "TermConvention" -> "Sector degrees k<=N are inclusive; positive-sector inner powers alpha<h are exclusive. Sector zero remains exact.",
    "InnerRemainders" -> inner, "SectorRemainder" -> sectorRemainder, "Remainder" -> remainder,
    "SectorTailGrade" -> flatOpsGrade[d],
    "RemainderScaleExpression" -> envelope, "Exact" -> (remainder === 0),
    "RetainedCoefficientPrecision" -> Table[{k, jets[[k + 1, {2, 3}]]}, {k, 1, d["SectorDepth"]}],
    "MajorantContract" -> <|"Type" -> "AsymptoticExistence", "NumericCertificate" -> False,
      "Statement" -> "The sum of the recorded positive-sector inner bounds and the separately recorded complete sector-tail bound is valid for fixed data sufficiently near the branch endpoint. Unknown bounds do not cancel."|>,
    "FlatAnalyticRemainder" -> d["DerivativeProvenance"], "RemainderDerivativeOrder" -> If[remainder === 0 || TrueQ[d["DerivativeContract"]], Infinity, 0],
    "FlatRepresentation" -> d, "FlatRecipe" -> recipe, "SeriesData" -> Missing["IndependentFlatSectorTruncations"]|>]];

AsymptoticAnalysis`FlatSeriesTruncate[s_GeneralizedSeries, h_, OptionsPattern[]] :=
  catch[flatOpsMake[flatOpsTruncateData[flatOpsData[s, OptionValue["MaxTerms"]], h, OptionValue["MaxTerms"]], {"Truncate", {s}, h}]];
AsymptoticAnalysis`FlatSeriesMultiply[s_GeneralizedSeries, t_GeneralizedSeries, OptionsPattern[]] := catch[Module[{d},
  d = flatOpsMultiplyData[flatOpsData[s, OptionValue["MaxTerms"]], flatOpsData[t, OptionValue["MaxTerms"]], OptionValue["MaxTerms"]];
  flatOpsMake[flatOpsTruncateData[d, OptionValue["InnerCutoff"], OptionValue["MaxTerms"]], {"Multiply", {s, t}}]]];
AsymptoticAnalysis`FlatSeriesMultiply[s_GeneralizedSeries, c_ /; FreeQ[c, _GeneralizedSeries], OptionsPattern[]] := catch[Module[{d},
  d = flatOpsData[s, OptionValue["MaxTerms"]];
  flatOpsMake[flatOpsTruncateData[flatOpsMultiplyData[d, flatOpsConstantData[c, d, OptionValue["MaxTerms"]], OptionValue["MaxTerms"]],
    OptionValue["InnerCutoff"], OptionValue["MaxTerms"]], {"MultiplyScalar", {s}, c}]]];
AsymptoticAnalysis`FlatSeriesMultiply[c_ /; FreeQ[c, _GeneralizedSeries], s_GeneralizedSeries, opts : OptionsPattern[]] :=
  AsymptoticAnalysis`FlatSeriesMultiply[s, c, opts];
AsymptoticAnalysis`FlatSeriesObservable[s_GeneralizedSeries, h_, z_Symbol, OptionsPattern[]] := catch[Module[{d},
  d = flatOpsObservableData[flatOpsData[s, OptionValue["MaxTerms"]], h, z,
    OptionValue["MaxPolynomialDegree"], OptionValue["MaxTerms"]];
  flatOpsMake[flatOpsTruncateData[d, OptionValue["InnerCutoff"], OptionValue["MaxTerms"]], {"PolynomialObservable", {s}, h, z}]]];
AsymptoticAnalysis`FlatSeriesDifferentiate[s_GeneralizedSeries, n_Integer : 1, OptionsPattern[]] := catch[Module[{d},
  d = flatOpsDifferentiateData[flatOpsData[s, OptionValue["MaxTerms"]], n, OptionValue["MaxTerms"]];
  flatOpsMake[flatOpsTruncateData[d, OptionValue["InnerCutoff"], OptionValue["MaxTerms"]], {"Differentiate", {s}, n}]]];

AsymptoticAnalysis`FlatSeriesTruncate[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use FlatSeriesTruncate[flatSeries,exactInnerCutoff]."|>];
AsymptoticAnalysis`FlatSeriesMultiply[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use FlatSeriesMultiply[flatSeries,flatSeriesOrExactScalar]."|>];
AsymptoticAnalysis`FlatSeriesObservable[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use FlatSeriesObservable[flatSeries,polynomial,formalVariable]."|>];
AsymptoticAnalysis`FlatSeriesDifferentiate[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use FlatSeriesDifferentiate[flatSeries,nonnegativeIntegerOrder]."|>];
