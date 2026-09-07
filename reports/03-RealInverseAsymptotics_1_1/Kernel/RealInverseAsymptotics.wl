(* ::Package:: *)
(* RealInverseAsymptotics, version 1.0.0, 2026-09-07.
   Exact, positive-real power/logarithm inversion at zero.
   See Article/real_inverse_asymptotics.pdf for proofs and limitations.
   No InverseFunction, PowerExpand, or approximate exponent ordering is used. *)

BeginPackage["RealInverseAsymptotics`"];

RealInverseExpansion::usage =
 "RealInverseExpansion[f,{x,y},r] returns an Association describing the positive real inverse of f as y->0+, retaining all output powers strictly below r. The exact input must be a finite sum x^alpha P(Log[x]) with a positive pure-power leading term. Exponents must be exact real numerical constants; coefficients may be symbolic under Assumptions.";
InverseResidual::usage =
 "InverseResidual[result] independently composes the model with result[\"Blocks\"] and checks that f(X)/a-t vanishes below result[\"Cutoff\"]+1-result[\"LeadingInversePower\"], where t=y/a. InverseResidual[result,c] uses an explicit residual cutoff c. It checks Blocks, not a separately edited Expression field.";
LagrangeInverseTruncation::usage =
 "LagrangeInverseTruncation[h,{x,t},n] gives the derivative-form Lagrange truncation through perturbation degree n for the inverse of x+h(x). The option \"OutputPower\"->q returns the qth power of that inverse. This general helper does not certify analytic hypotheses or attach an asymptotic error bound.";
LogCoordinate::usage =
 "LogCoordinate is the protected polynomial indeterminate used in the Blocks and Model fields. It stands for Log[y/a], where a is the leading coefficient.";

Options[RealInverseExpansion] = {
 Assumptions -> True, "MaxMultiIndices" -> 100000,
 "MaxTotalOrder" -> 64
};
Options[InverseResidual] = {"MaxCompositionOrder" -> 128};
Options[LagrangeInverseTruncation] = {"OutputPower" -> 1};

Begin["`Private`"];

$failureTag = Unique["realInverseFailure"];
fail[tag_String, text_String] :=
 Throw[Failure[tag, <|"MessageTemplate" -> text|>], $failureTag];

simp[z_, ass_] := FullSimplify[z, Assumptions -> ass];
zeroQ[z_, ass_] := TrueQ[simp[z == 0, ass]];

(* Fail closed: no decimal approximation ever decides a support order. *)
compare[a_, b_, ass_] := Module[{d = simp[a - b, ass]},
 Which[
  TrueQ[d == 0], 0,
  TrueQ[simp[d < 0, ass]], -1,
  TrueQ[simp[d > 0, ass]], 1,
  True, fail["UndecidableOrder",
    "An exact exponent comparison could not be established. Use simpler exact constants or the derivative-form helper."]
 ]
];

exactRealNumberQ[z_, ass_] :=
 NumericQ[z] && FreeQ[z, _Real] && TrueQ[simp[Element[z, Reals], ass]];

integerBound[z_, ass_] := Module[{v = simp[Floor[z], ass]},
 If[!IntegerQ[v], fail["UndecidableBound",
   "An exact finite integer bound for a support enumeration could not be established."]];
 v
];

(* A block is {exponent, polynomial in LogCoordinate}.  Equal real
   exponents are combined even if their input syntax differs. *)
mergeBlocks[blocks_List, ass_] := Module[{out = {}, a, p, pos},
 Do[
  a = simp[b[[1]], ass]; p = Expand[b[[2]]];
  If[!zeroQ[p, ass],
   pos = 0;
   Do[If[compare[out[[j, 1]], a, ass] == 0, pos = j; Break[]],
      {j, Length[out]}];
   If[pos == 0,
    AppendTo[out, {a, p}],
    out[[pos, 2]] = Expand[out[[pos, 2]] + p]
   ]
  ], {b, blocks}];
 out = Select[({#[[1]], Expand[simp[#[[2]], ass]]} & /@ out),
   !zeroQ[#[[2]], ass] &];
 Sort[out, compare[#1[[1]], #2[[1]], ass] == -1 &]
];

truncateBlocks[blocks_List, cut_, ass_] :=
 Select[mergeBlocks[blocks, ass], compare[#[[1]], cut, ass] == -1 &];

blockExpression[blocks_List, t_] :=
 Total[(t^#[[1]] (#[[2]] /. LogCoordinate -> Log[t])) & /@ blocks];

(* Parsing is deliberately structural, rather than branch-changing. *)
parseModel[expr_, x_Symbol, y_Symbol, ass_] := Module[
 {l = Unique["log"], e, terms, factors, a, c, blocks = {}, p,
  slope, corrections, coeffs},
 If[x === y, fail["Variables", "Input and output variables must be distinct unassigned symbols."]];
 If[!FreeQ[expr, y | LogCoordinate], fail["Variables",
   "The input must not contain the output variable or LogCoordinate."]];
 If[!FreeQ[expr, _Real], fail["InexactInput",
   "Use exact input coefficients and exponents. Substitute numerical values after constructing the expansion."]];
 e = Expand[expr /. Log[x] -> l];
 terms = If[Head[e] === Plus, List @@ e, {e}];
 Do[
  a = 0; c = 1;
  factors = If[Head[term] === Times, List @@ term, {term}];
  Do[
   Which[
    factor === x, a += 1,
    Head[factor] === Power && factor[[1]] === x && FreeQ[factor[[2]], x | l],
      a += factor[[2]],
    FreeQ[factor, x], c *= factor,
    True, fail["UnsupportedInput",
      "Write the input as a finite sum of x^alpha times polynomials in Log[x]. Nested functions of x and noncanonical logarithms are not automatically expanded."]
   ], {factor, factors}];
  a = simp[a, ass]; c = Expand[c];
  If[!exactRealNumberQ[a, ass], fail["Exponent",
    "Every input exponent must be an exact real numerical constant, for example 3/2 or Sqrt[2]."]];
  If[!PolynomialQ[c, l], fail["LogCoefficient",
    "Only nonnegative integer powers of Log[x] are supported by the exact-model front end."]];
  coeffs = CoefficientList[c, l];
  If[!TrueQ[And @@ (TrueQ[simp[Element[#, Reals], ass]] & /@ coeffs)],
    fail["NonrealCoefficient", "Reality of every coefficient must follow from Assumptions."]];
  AppendTo[blocks, {a, c /. l -> LogCoordinate}], {term, terms}];
 blocks = mergeBlocks[blocks, ass];
 If[blocks === {}, fail["ZeroModel", "The zero function has no local inverse of the required kind."]];
 p = blocks[[1, 1]];
 If[compare[p, 0, ass] != 1, fail["LeadingPower", "The leading exponent must be positive."]];
 slope = blocks[[1, 2]];
 If[!FreeQ[slope, LogCoordinate], fail["LogarithmicCore",
   "A logarithmic leading coefficient needs a different dominant-core inversion and is not supported."]];
 If[!TrueQ[simp[slope > 0, ass]], fail["LeadingCoefficient",
   "The leading coefficient must be provably positive under Assumptions."]];
 corrections = ({simp[#[[1]]/p - 1, ass],
      Expand[(#[[2]] /. LogCoordinate -> LogCoordinate/p)/slope]} &) /@ Rest[blocks];
 <|"OriginalBlocks" -> blocks, "LeadingPower" -> p,
   "LeadingCoefficient" -> slope, "Corrections" -> corrections,
   "InputVariable" -> x, "OutputVariable" -> y|>
];

(* Enumerate a weighted simplex, including its boundary. *)
weightedIndices[weights_List, bound_, maxCount_Integer, ass_] := Module[
 {walk, count = 0, harvested, m = Length[weights]},
 walk[i_Integer, left_, prefix_List] := If[i > m,
   count++;
   If[count > maxCount, fail["ResourceLimit", "MaxMultiIndices was exceeded."]];
   Sow[prefix],
   With[{top = integerBound[simp[left/weights[[i]], ass], ass]},
    Do[walk[i + 1, simp[left - k weights[[i]], ass], Append[prefix, k]],
      {k, 0, top}]
   ]
 ];
 harvested = Reap[walk[1, bound, {}]][[2]];
 If[harvested === {}, {}, First[harvested]]
];

(* Observable Lagrange formula for x=v^q. *)
indexCoefficient[k_List, beta_, q_, polys_List, ass_] := Module[
 {n = Total[k], poly, j, denom},
 poly = Expand[Times @@ MapThread[Power, {polys, k}]];
 Do[poly = Expand[D[poly, LogCoordinate] + (beta + q + j) poly],
    {j, 1, n - 1}];
 denom = Times @@ (Factorial /@ k);
 Expand[simp[q (-1)^n poly/denom, ass]]
];

RealInverseExpansion[expr_, {x_Symbol, y_Symbol}, cut_, OptionsPattern[]] :=
 Catch[Module[
  {ass = OptionValue[Assumptions], maxCount = OptionValue["MaxMultiIndices"],
   maxOrder = OptionValue["MaxTotalOrder"], model, q, a, t, corr, weights,
   polys, degrees, minWeight, bound, b, ceiling, indices, rows, included,
   excluded, betaStar, degreeStar, blocks, candidates, expression, rem},
  If[!(IntegerQ[maxCount] && maxCount > 0 && IntegerQ[maxOrder] && maxOrder > 0),
   fail["Options", "Resource limits must be positive integers."]];
  model = parseModel[expr, x, y, ass];
  q = simp[1/model["LeadingPower"], ass];
  a = model["LeadingCoefficient"]; t = y/a;
  If[!exactRealNumberQ[cut, ass] || compare[cut, q, ass] != 1,
   fail["Cutoff", "The cutoff must be an exact real numerical constant greater than the leading inverse exponent."]];
  corr = model["Corrections"];
  If[corr === {},
   Return[<|"Expression" -> t^q, "Blocks" -> {{q, 1}},
    "RemainderScale" -> 0, "RemainderExponent" -> Infinity,
    "RemainderLogDegree" -> 0, "Cutoff" -> cut,
    "LeadingInversePower" -> q, "ScaledVariable" -> t,
    "Model" -> model, "Assumptions" -> ass, "Exact" -> True,
    "Branch" -> "Positive real, x/(y/a)^(1/p) -> 1 as y -> 0+",
    "EnumeratedMultiIndices" -> 0, "ContributingMultiIndices" -> 0|>]
  ];
  weights = corr[[All, 1]]; polys = corr[[All, 2]];
  degrees = Exponent[#, LogCoordinate] & /@ polys;
  minWeight = First[Sort[weights, compare[#1, #2, ass] == -1 &]];
  b = simp[cut - q, ass];
  ceiling = simp[Ceiling[b/minWeight], ass];
  If[!IntegerQ[ceiling], fail["UndecidableBound", "Could not determine the first excluded support frontier exactly."]];
  bound = simp[ceiling minWeight, ass];
  If[integerBound[simp[bound/minWeight, ass], ass] > maxOrder,
   fail["ResourceLimit", "The requested support frontier exceeds MaxTotalOrder."]];
  indices = weightedIndices[weights, bound, maxCount, ass];
  indices = Select[indices, Total[#] > 0 &];
  rows = ({#, simp[# . weights, ass]} &) /@ indices;
  included = Select[rows, compare[#[[2]], b, ass] == -1 &];
  excluded = Select[rows, compare[#[[2]], b, ass] != -1 &];
  If[excluded === {}, fail["InternalFrontier", "No excluded frontier was found."]];
  betaStar = First[Sort[excluded[[All, 2]], compare[#1, #2, ass] == -1 &]];
  candidates = Select[excluded, compare[#[[2]], betaStar, ass] == 0 &];
  degreeStar = Max[(#[[1]] . degrees) & /@ candidates];
  blocks = Prepend[
    ({simp[q + #[[2]], ass], indexCoefficient[#[[1]], #[[2]], q, polys, ass]} &) /@ included,
    {q, 1}];
  blocks = mergeBlocks[blocks, ass];
  expression = blockExpression[blocks, t];
  rem = t^simp[q + betaStar, ass] (1 + Abs[Log[t]])^degreeStar;
  <|"Expression" -> expression, "Blocks" -> blocks,
   "RemainderScale" -> rem, "RemainderExponent" -> simp[q + betaStar, ass],
   "RemainderLogDegree" -> degreeStar, "Cutoff" -> cut,
   "LeadingInversePower" -> q, "ScaledVariable" -> t,
   "Model" -> model, "Assumptions" -> ass, "Exact" -> False,
   "Branch" -> "Positive real, x/(y/a)^(1/p) -> 1 as y -> 0+",
   "EnumeratedMultiIndices" -> Length[indices],
   "ContributingMultiIndices" -> Length[included],
   "Guarantee" -> "Big-O of RemainderScale for the exact model; no numerical error constant is asserted."|>
 ], $failureTag];

(* Sparse multiplication for the independent residual computation. *)
jetMultiply[u_List, v_List, cut_, ass_] := Module[{terms = {}, e},
 Do[
  e = simp[a[[1]] + b[[1]], ass];
  If[compare[e, cut, ass] == -1,
   AppendTo[terms, {e, Expand[a[[2]] b[[2]]]}]], {a, u}, {b, v}];
 mergeBlocks[terms, ass]
];

InverseResidual[data_Association, requestedCut_: Automatic, OptionsPattern[]] :=
 Catch[Module[
  {model, ass, q, a, t, blocks, u, cut, vmin, z = Unique["u"],
   alpha, poly, base, top, aux, pow, coefficient, pieces = {}, residual,
   maxOrder = OptionValue["MaxCompositionOrder"]},
  If[!TrueQ[And @@ (KeyExistsQ[data, #] & /@
    {"Model", "Blocks", "Assumptions", "LeadingInversePower", "ScaledVariable", "Cutoff"})],
   fail["Data", "Expected an expansion Association returned by RealInverseExpansion."]];
  If[!(IntegerQ[maxOrder] && maxOrder > 0), fail["Options", "MaxCompositionOrder must be a positive integer."]];
  model = data["Model"]; ass = data["Assumptions"];
  q = data["LeadingInversePower"]; a = model["LeadingCoefficient"];
  t = data["ScaledVariable"]; blocks = mergeBlocks[data["Blocks"], ass];
  If[blocks === {} || compare[blocks[[1, 1]], q, ass] != 0 ||
     !zeroQ[blocks[[1, 2]] - 1, ass],
   fail["LeadingBlock", "Blocks must have the normalized leading block {1/p,1}."]];
  cut = If[requestedCut === Automatic, simp[data["Cutoff"] + 1 - q, ass], requestedCut];
  If[!exactRealNumberQ[cut, ass] || compare[cut, 1, ass] != 1,
   fail["Cutoff", "The residual cutoff must be an exact real numerical constant greater than 1."]];
  u = ({simp[#[[1]] - q, ass], #[[2]]} &) /@ Rest[blocks];
  If[u =!= {} && compare[u[[1, 1]], 0, ass] != 1,
   fail["UnitJet", "The correction to the leading monomial must have positive valuation."]];
  vmin = If[u === {}, Infinity, u[[1, 1]]];
  Do[
   alpha = term[[1]]; poly = term[[2]]/a; base = simp[q alpha, ass];
   If[compare[base, cut, ass] == -1,
    top = If[u === {}, 0, Max[0, integerBound[simp[(cut - base)/vmin, ass], ass]]];
    If[top > maxOrder, fail["ResourceLimit", "MaxCompositionOrder was exceeded."]];
    aux = Normal[Series[(1 + z)^alpha
       (poly /. LogCoordinate -> q LogCoordinate + Log[1 + z]), {z, 0, top}]];
    If[!PolynomialQ[aux, z], fail["Composition", "The auxiliary ordinary Taylor expansion could not be formed."]];
    pow = {{0, 1}};
    Do[
     coefficient = Expand[Coefficient[aux, z, j]];
     If[!zeroQ[coefficient, ass],
      pieces = Join[pieces,
        ({simp[base + #[[1]], ass], Expand[coefficient #[[2]]]} &) /@ pow]];
     If[j < top, pow = jetMultiply[pow, u, simp[cut - base, ass], ass]],
      {j, 0, top}]
   ], {term, model["OriginalBlocks"]}];
  residual = truncateBlocks[Append[pieces, {1, -1}], cut, ass];
  <|"ResidualBlocks" -> residual,
    "NormalizedResidualExpression" -> blockExpression[residual, t],
    "ResidualExpression" -> a blockExpression[residual, t],
    "Cutoff" -> cut, "VanishingBelowCutoff" -> (residual === {}),
    "Meaning" -> "The retained residual of f(X)/a-t, composed from Blocks; omitted orders are not asserted to vanish."|>
 ], $failureTag];

LagrangeInverseTruncation[h_, {x_Symbol, t_Symbol}, n_Integer, OptionsPattern[]] :=
 Catch[Module[{q = OptionValue["OutputPower"], result},
  If[n < 0 || x === t || !FreeQ[h, t] || !FreeQ[q, x | t],
   fail["Arguments", "Use n>=0, distinct variables, and a constant output power; h must not contain the output variable."]];
  result = t^q + Total[Table[
    (-1)^k/Factorial[k] (D[Expand[q x^(q - 1) h^k], {x, k - 1}] /. x -> t),
      {k, 1, n}]];
  result
 ], $failureTag];

RealInverseExpansion[___] := Failure["Arguments", <|"MessageTemplate" ->
 "Use RealInverseExpansion[f,{x,y},cutoff,options] with distinct unassigned variables."|>];
InverseResidual[___] := Failure["Arguments", <|"MessageTemplate" ->
 "Use InverseResidual[expansionAssociation,optionalResidualCutoff,options]."|>];
LagrangeInverseTruncation[___] := Failure["Arguments", <|"MessageTemplate" ->
 "Use LagrangeInverseTruncation[h,{x,t},nonnegativeInteger,options]."|>];

End[];
Protect[LogCoordinate];
EndPackage[];
