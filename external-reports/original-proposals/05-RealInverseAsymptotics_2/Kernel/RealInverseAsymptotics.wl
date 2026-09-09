(* ::Package:: *)
(* RealInverseAsymptotics 1.0.0 -- positive-real, finite power-log inversion.
   Copyright (c) 2026. Distributed under the MIT license in ../LICENSE.
   No PowerExpand, InverseFunction, floating-point exponent ordering, or
   replacement of irrational exponents by rational approximations is used. *)

BeginPackage["RealInverseAsymptotics`"];

RealInverseAsymptotic::usage =
 "RealInverseAsymptotic[f,{x,0},{y,0,b}] expands the positive-real inverse of an exact finite power-log expression f through every power of y <= b. It returns an Association; use result[\"Expression\"] and result[\"RemainderScale\"]. The selected branch has x/(y/c)^(1/alpha) -> 1. Exponents and b must be exact real algebraic numbers. The leading term must be c x^alpha with c,alpha>0.";
InversePowerLogModel::usage =
 "InversePowerLogModel[c,alpha,{{delta1,P1[L]},...},L,{y,0,b}] inverts the exact model c x^alpha (1+Sum[x^delta_j P_j[Log[x]]]) through powers of y <= b. All delta_j are positive. Assumptions may establish that symbolic coefficients are real and c is positive.";
PowerLogInverseCoefficient::usage =
 "PowerLogInverseCoefficient[alpha,{{delta1,P1[L]},...},L,{k1,...}] returns the multivariate Lagrange coefficient C_k(L). The supplied generators are NOT merged in this coefficient-level function.";
InverseResidual::usage =
 "InverseResidual[result] returns f(result[\"Expression\"])-y for the exact model stored in result. It does not turn a numerical check into an error certificate.";
EvaluateInverseAsymptotic::usage =
 "EvaluateInverseAsymptotic[result,y0,WorkingPrecision->50] evaluates the finite approximation at positive y0. Use exact or sufficiently high-precision input; insufficient-precision input is rejected, not padded.";
ResidualErrorBound::usage =
 "ResidualErrorBound[f,{x,a,b},y,u,m] returns the conditional mean-value error bound Abs[f(u)-y]/m, together with the endpoint, derivative, and regularity hypotheses. It does NOT automatically prove those hypotheses.";

Options[RealInverseAsymptotic] = {Assumptions -> True,
  "MaxMultiIndices" -> 50000, "MaxGenerators" -> 32};
Options[InversePowerLogModel] = Options[RealInverseAsymptotic];
Options[PowerLogInverseCoefficient] = {Assumptions -> True};
Options[EvaluateInverseAsymptotic] = {WorkingPrecision -> 50};

LagrangeInverseBlocks::usage =
 "LagrangeInverseBlocks[phi,{x,0},{y,0},n] returns n Lagrange derivative blocks for f(x)=x+phi(x), without evaluating any derivative at zero. With the option \"DerivativeScale\"->{delta,M}, it returns a CONDITIONAL remainder O[y^(1+(n+1)delta)(1+Abs[Log[y]])^((n+1)M)], requiring the real derivative bounds in the article. This routine does not verify those bounds.";
InversePowerLogJet::usage =
 "InversePowerLogJet[c,alpha,data,L,{y,0,b},{sigma,q}] inverts a finite source jet plus an unknown remainder O[x^(alpha+sigma)(1+Abs[Log[x]])^q]. The requested cutoff must satisfy alpha b-1<sigma. The output is conditional on the source and derivative estimates stated in the article.";
Options[LagrangeInverseBlocks] = {"DerivativeScale" -> Automatic};
Options[InversePowerLogJet] = Options[InversePowerLogModel];

Begin["`Private`"];

fail[tag_String, message_String, data_: <||>] :=
 Throw[Failure[tag, Join[<|"MessageTemplate" -> message|>, data]], failureTag];
failureQ[e_] := MatchQ[e, _Failure];
exactInputQ[e_] := FreeQ[e, _Real];
algebraicRealQ[e_] := exactInputQ[e] && NumericQ[e] &&
 TrueQ[FullSimplify[Element[e, Algebraics] && Element[e, Reals]]];
canonical[e_] := RootReduce[e];
compare[a_, b_] := Module[{v = canonical[a - b]},
 Which[TrueQ[v == 0], 0, TrueQ[v < 0], -1, TrueQ[v > 0], 1,
  True, fail["UndecidableOrder", "Could not certify an exact exponent comparison.",
    <|"Left" -> a, "Right" -> b|>]]];
positiveAlgebraicQ[e_] := algebraicRealQ[e] && compare[e, 0] > 0;
zeroPolynomialQ[p_] := TrueQ[Expand[p] === 0];

validatePolynomial[p_, ell_Symbol, assum_] := Module[{coeff},
 If[! PolynomialQ[p, ell],
  fail["NonPolynomialLog", "Logarithmic coefficients must be polynomials.",
   <|"Coefficient" -> p|>]];
 coeff = CoefficientList[Expand[p], ell];
 If[! exactInputQ[coeff],
  fail["InexactCoefficient", "Use exact coefficients, not floating-point Real values."]];
 If[! And @@ (TrueQ[FullSimplify[Element[#, Reals], assum]] & /@ coeff),
  fail["UnprovedRealCoefficient", "A coefficient is not provably real under Assumptions.",
   <|"Coefficients" -> coeff, "Assumptions" -> assum|>]];
 Expand[p]
];

(* Sort by an exact real algebraic comparison, then merge all resonances. *)
mergeBlocks[raw_List] := Module[{s, groups},
 If[raw === {}, Return[{}]];
 s = Sort[raw, (compare[#1[[1]], #2[[1]]] < 0) &];
 groups = Split[s, (compare[#1[[1]], #2[[1]]] == 0) &];
 Select[({#[[1, 1]], Expand[Total[#[[All, 2]]]]} & /@ groups),
  (! zeroPolynomialQ[#[[2]]]) &]
];

validateData[data_List, ell_Symbol, assum_, merge_: True] := Module[{v},
 If[! And @@ (MatchQ[#, {_, _}] & /@ data),
  fail["InvalidGenerators", "Generators must be pairs {positiveDelta, polynomial}."]];
 v = Map[Function[row,
   If[! positiveAlgebraicQ[row[[1]]],
    fail["InvalidExponent", "Every delta must be an exact positive real algebraic number.",
     <|"Exponent" -> row[[1]]|>]];
   {canonical[row[[1]]], validatePolynomial[row[[2]], ell, assum]}], data];
 If[TrueQ[merge], mergeBlocks[v], v]
];

(* Every admitted lattice point is visited exactly once. Floor is exact. *)
enumerateIndices[d_List, bound_, limit_Integer] := Module[
 {out, visit, count = 0, m = Length[d]},
 visit[j_Integer, remaining_, prefix_List] := Module[{last, k},
  If[j > m,
   count++;
   If[count > limit,
    fail["ResourceLimit", "The multi-index enumeration limit was exceeded.",
     <|"Limit" -> limit|>]];
   Sow[prefix]; Return[Null]];
  last = Floor[canonical[remaining/d[[j]]]];
  If[! IntegerQ[last] || last < 0,
   fail["EnumerationFailure", "An exact lattice bound could not be obtained."]];
  If[last + 1 > limit,
   fail["ResourceLimit", "One lattice direction alone exceeds MaxMultiIndices.",
    <|"Limit" -> limit, "RequiredAtLeast" -> last + 1|>]];
  Do[visit[j + 1, canonical[remaining - k d[[j]]], Append[prefix, k]],
   {k, 0, last}]
 ];
 out = Reap[visit[1, canonical[bound], {}]][[2]];
 If[out === {}, {}, First[out]]
];

coefficientCore[alpha_, d_List, polys_List, ell_Symbol, k_List] := Module[
 {n = Total[k], weight, p, j},
 If[n == 0, Return[1]];
 weight = canonical[k.d];
 p = Expand[Times @@ MapThread[Power, {polys, k}]];
 Do[p = Expand[D[p, ell] + (1 + weight + alpha j) p], {j, 1, n - 1}];
 Expand[(-1)^n p/(alpha^n Times @@ (Factorial /@ k))]
];

PowerLogInverseCoefficient[alpha_, data_List, ell_Symbol, k_List,
 OptionsPattern[]] := Catch[Module[{v, assum = OptionValue[Assumptions]},
 If[! positiveAlgebraicQ[alpha],
  fail["InvalidLeadingExponent", "alpha must be exact, real algebraic, and positive."]];
 v = validateData[data, ell, assum, False];
 If[Length[k] != Length[v] || ! And @@ (IntegerQ[#] && # >= 0 & /@ k),
  fail["InvalidMultiIndex", "The multi-index must have one nonnegative integer per generator."]];
 If[v === {}, Return[1]];
 coefficientCore[alpha, v[[All, 1]], v[[All, 2]], ell, k]
], failureTag];

modelExpansion[c_, alpha_, inputData_List, ell_Symbol, y_Symbol, b_,
 assum_, limit_, maxgen_] := Module[
 {data, d, polys, cut, indices, weights, candidates, rho, frontierIndices,
  frontier, raw, blocks, omittedPolynomial, logDegree, logArgument,
  expression, scale, blockRecords, model, count, zeroK},
 If[ell === y, fail["VariableCollision", "The log indeterminate and output variable must differ."]];
 If[! positiveAlgebraicQ[alpha] || ! positiveAlgebraicQ[b],
  fail["InvalidOrder", "alpha and the requested power cutoff must be exact positive real algebraic numbers."]];
 If[! exactInputQ[c] || ! FreeQ[c, ell] || ! FreeQ[c, y] ||
    ! TrueQ[FullSimplify[c > 0, assum]],
  fail["InvalidLeadingCoefficient", "c must be exact, independent of the variables, and provably positive."]];
 If[! IntegerQ[limit] || limit < 1 || ! IntegerQ[maxgen] || maxgen < 1,
  fail["InvalidLimit", "Resource limits must be positive integers."]];
 If[compare[alpha b, 1] < 0,
  fail["CutoffBelowLeadingTerm", "The cutoff is smaller than the leading inverse power 1/alpha.",
   <|"LeadingPower" -> 1/alpha, "Cutoff" -> b|>]];
 data = validateData[inputData, ell, assum];
 If[! FreeQ[data, y],
  fail["VariableDependentCoefficient", "Model coefficients may not depend on the output variable."]];
 If[Length[data] > maxgen,
  fail["ResourceLimit", "The number of merged generators exceeds MaxGenerators."]];
 model = <|"LeadingCoefficient" -> c, "LeadingExponent" -> alpha,
   "Generators" -> data, "LogSymbol" -> ell|>;
 logArgument = (Log[y] - Log[c])/alpha;
 If[data === {},
  Return[<|"Expression" -> (y/c)^(1/alpha), "RemainderScale" -> 0,
    "RemainderKind" -> "Exact", "FirstOmittedPower" -> Infinity,
    "FirstOmittedCoefficient" -> 0, "RemainderLogDegree" -> 0,
    "CoefficientBlocks" -> {<|"Weight" -> 0, "NormalizedPower" -> 1,
      "PowerInY" -> 1/alpha, "Polynomial" -> 1|>},
    "MultiIndexCoefficients" -> {{{}, 0, 1}},
    "Model" -> model, "Variable" -> y, "LogSymbol" -> ell,
    "Cutoff" -> b, "Conditions" -> (assum && y > 0),
    "BranchEquivalent" -> (y/c)^(1/alpha),
    "Branch" -> "Positive real; x/(y/c)^(1/alpha) tends to 1",
    "NumberOfMultiIndices" -> 1, "Version" -> "1.0.0"|>]];
 d = data[[All, 1]]; polys = data[[All, 2]];
 cut = canonical[alpha b - 1];
 indices = enumerateIndices[d, cut, limit];
 weights = canonical[#.d] & /@ indices;
 candidates = Select[Flatten[Table[canonical[w + dj], {w, weights}, {dj, d}]],
   (compare[#, cut] > 0) &];
 rho = First[Sort[candidates, (compare[#1, #2] < 0) &]];
 (* Enumerating through rho, not just one step from each included index,
    ensures ALL representations at a resonant first omitted exponent. *)
 frontierIndices = enumerateIndices[d, rho, limit];
 frontier = Select[frontierIndices, (compare[canonical[#.d], rho] == 0) &];
 raw = ({#, canonical[#.d], coefficientCore[alpha, d, polys, ell, #]} &) /@ indices;
 blocks = mergeBlocks[({#[[2]], #[[3]]} &) /@ raw];
 omittedPolynomial = Expand[Total[
   coefficientCore[alpha, d, polys, ell, #] & /@ frontier]];
 logDegree = If[zeroPolynomialQ[omittedPolynomial], 0,
   Max[0, Exponent[omittedPolynomial, ell]]];
 expression = Total[(y/c)^((1 + #[[1]])/alpha)
     (#[[2]] /. ell -> logArgument) & /@ blocks];
 scale = (y/c)^((1 + rho)/alpha) (1 + Abs[logArgument])^logDegree;
 blockRecords = (<|"Weight" -> #[[1]], "NormalizedPower" -> 1 + #[[1]],
     "PowerInY" -> canonical[(1 + #[[1]])/alpha], "Polynomial" -> #[[2]]|> &) /@ blocks;
 <|"Expression" -> expression, "RemainderScale" -> scale,
   "RemainderKind" -> "BigO as y tends to zero from above, with fixed parameters",
   "FirstOmittedPower" -> canonical[(1 + rho)/alpha],
   "FirstOmittedCoefficient" -> omittedPolynomial,
   "RemainderLogDegree" -> logDegree, "CoefficientBlocks" -> blockRecords,
   "MultiIndexCoefficients" -> raw, "Model" -> model,
   "Variable" -> y, "LogSymbol" -> ell, "Cutoff" -> b,
   "Conditions" -> (assum && y > 0),
   "BranchEquivalent" -> (y/c)^(1/alpha),
   "Branch" -> "Positive real; x/(y/c)^(1/alpha) tends to 1",
   "NumberOfMultiIndices" -> Length[indices],
   "NumberOfFrontierMultiIndices" -> Length[frontier], "Version" -> "1.0.0"|>
];

InversePowerLogModel[c_, alpha_, data_List, ell_Symbol, {y_Symbol, 0, b_},
 OptionsPattern[]] := Catch[
 modelExpansion[c, alpha, data, ell, y, b, OptionValue[Assumptions],
  OptionValue["MaxMultiIndices"], OptionValue["MaxGenerators"]], failureTag];

parseExpression[f_, x_Symbol, ell_Symbol, assum_] := Module[
 {expanded, pieces, rows, blocks, row, factors, factor, e, p, c, alpha},
 expanded = Expand[f /. Log[x] -> ell];
 pieces = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
 rows = Table[
   factors = If[Head[row] === Times, List @@ row, {row}]; e = 0; p = 1;
   Do[Which[
     factor === x, e += 1,
     MatchQ[factor, Power[x, _]], e += factor[[2]],
     FreeQ[factor, x], p *= factor,
     True, fail["UnsupportedInput",
       "Input must expand to a finite sum of x^r times polynomials in Log[x].",
       <|"UnsupportedFactor" -> factor|>]], {factor, factors}];
   If[! algebraicRealQ[e],
    fail["InvalidExponent", "All input powers must be exact real algebraic numbers.",
     <|"Exponent" -> e|>]];
   {canonical[e], validatePolynomial[p, ell, assum]}, {row, pieces}];
 blocks = mergeBlocks[rows];
 If[blocks === {}, fail["ZeroFunction", "The zero function has no selected local inverse."]];
 alpha = blocks[[1, 1]]; c = blocks[[1, 2]];
 If[! positiveAlgebraicQ[alpha] || ! FreeQ[c, ell],
  fail["UnsupportedLeadingTerm", "The leading term must be c x^alpha without a log factor, with alpha>0."]];
 {c, alpha, ({canonical[#[[1]] - alpha], Expand[#[[2]]/c]} & /@ Rest[blocks])}
];

RealInverseAsymptotic[f_, {x_Symbol, 0}, {y_Symbol, 0, b_},
 OptionsPattern[]] := Catch[Module[{ell, parsed, result, assum},
 If[x === y, fail["VariableCollision", "Use distinct input and output variables."]];
 ell = Unique["ell$"]; assum = OptionValue[Assumptions];
 parsed = parseExpression[f, x, ell, assum];
 result = modelExpansion[parsed[[1]], parsed[[2]], parsed[[3]], ell, y, b,
   assum, OptionValue["MaxMultiIndices"], OptionValue["MaxGenerators"]];
 Join[result, <|"SourceFunction" -> f, "SourceVariable" -> x|>]
], failureTag];

InverseResidual[result_Association] := Catch[Module[{m, u, y, ell, data},
 If[! And @@ (KeyExistsQ[result, #] & /@ {"Model", "Expression", "Variable"}),
  fail["InvalidResult", "The input is not an inverse-expansion result."]];
 If[TrueQ[Lookup[result, "SourceIsJet", False]],
  fail["UnknownSourceFunction", "A source jet does not specify the actual function; its model residual is not the actual residual."]];
 m = result["Model"]; u = result["Expression"]; y = result["Variable"];
 ell = m["LogSymbol"]; data = m["Generators"];
 m["LeadingCoefficient"] u^m["LeadingExponent"]
   (1 + Total[u^#[[1]] (#[[2]] /. ell -> Log[u]) & /@ data]) - y
], failureTag];

EvaluateInverseAsymptotic[result_Association, value_, OptionsPattern[]] :=
 Catch[Module[{wp = OptionValue[WorkingPrecision], prec, v, answer},
 If[! IntegerQ[wp] || wp < 16,
  fail["InvalidPrecision", "WorkingPrecision must be an integer of at least 16."]];
 If[! NumericQ[value] || ! TrueQ[value > 0],
  fail["InvalidPoint", "The evaluation point must be a positive real number."]];
 prec = Precision[value];
 If[prec =!= Infinity && (prec === MachinePrecision || ! TrueQ[prec >= wp]),
  fail["InsufficientPrecision", "Supply an exact or sufficiently high-precision point; precision will not be padded."]];
 If[! And @@ (KeyExistsQ[result, #] & /@ {"Variable", "Expression"}),
  fail["InvalidResult", "The input is not an inverse-expansion result."]];
 v = N[value, wp]; answer = N[result["Expression"] /. result["Variable"] -> v, wp];
 If[! NumericQ[answer] || ! TrueQ[Im[answer] == 0],
  fail["NonNumericResult", "The approximation is not a real number; substitute parameters and check the domain."]];
 answer
], failureTag];

ResidualErrorBound[f_, {x_Symbol, a_, b_}, y_, u_, m_] := Catch[Module[{res, v},
 If[! FreeQ[{a, b, y, u, m}, x],
  fail["VariableDependentBound", "Endpoints, target, approximation, and derivative lower bound must be independent of the source variable."]];
 If[NumericQ[m] && ! TrueQ[m > 0],
  fail["InvalidLowerBound", "A numerical derivative lower bound must be strictly positive."]];
 v = Unique["v$"]; res = (f /. x -> u) - y;
 <|"Bound" -> Abs[res]/m, "Residual" -> res,
   "EndpointAndPositivityConditions" ->
     (0 < a <= u <= b && m > 0 && (f /. x -> a) <= y <= (f /. x -> b)),
   "DerivativeCondition" -> ForAll[v,
     Implies[Element[v, Reals] && a <= v <= b, (D[f, x] /. x -> v) >= m]],
   "RegularityRequirement" -> "f is real-valued and continuously differentiable on [a,b]",
   "VerificationStatus" -> "Conditional: hypotheses have not been automatically proved"|>
], failureTag];


LagrangeInverseBlocks[phi_, {x_Symbol, 0}, {y_Symbol, 0}, n_Integer,
 OptionsPattern[]] := Catch[Module[{blocks, ds = OptionValue["DerivativeScale"],
  delta, logdeg, scale, hypothesis},
 If[x === y || ! FreeQ[phi, y],
  fail["VariableCollision", "Use distinct variables and a perturbation independent of y."]];
 If[n < 0, fail["InvalidOrder", "The number of derivative blocks must be nonnegative."]];
 blocks = Table[Expand[(-1)^j D[phi^j, {x, j - 1}]/j!] /. x -> y,
   {j, 1, n}];
 scale = Missing["NoDerivativeScaleSupplied"];
 hypothesis = "Formal blocks only: a separate asymptotic and branch argument is required";
 If[ds =!= Automatic,
  If[! MatchQ[ds, {_, _}] || ! positiveAlgebraicQ[ds[[1]]] ||
     ! IntegerQ[ds[[2]]] || ds[[2]] < 0,
   fail["InvalidDerivativeScale", "DerivativeScale must be {positive exact algebraic delta, nonnegative integer M}."]];
  {delta, logdeg} = ds;
  scale = y^(1 + (n + 1) delta) (1 + Abs[Log[y]])^((n + 1) logdeg);
  hypothesis = <|"Regularity" -> "phi is real C^(n+1) on a positive interval",
    "DerivativeOrders" -> Range[0, n + 1], "Delta" -> delta,
    "LogDegree" -> logdeg,
    "RequiredBounds" -> "For r=0,...,n+1, phi^(r)(x)=O[x^(1+delta-r)(1+Abs[Log[x]])^M] as x->0+; constants independent of x",
    "VerificationStatus" -> "Conditional: derivative hypotheses are not checked automatically"|>];
 <|"Expression" -> y + Total[blocks], "Blocks" -> blocks,
   "RemainderScale" -> scale, "Hypotheses" -> hypothesis,
   "Branch" -> "Positive real; x/y tends to 1", "Variable" -> y|>
], failureTag];

InversePowerLogJet[c_, alpha_, data_List, ell_Symbol, {y_Symbol, 0, b_},
 {sigma_, q_}, OptionsPattern[]] := Catch[Module[{r, extra},
 If[! positiveAlgebraicQ[sigma] || ! IntegerQ[q] || q < 0,
  fail["InvalidJetRemainder", "sigma must be positive exact algebraic and q a nonnegative integer."]];
 If[! positiveAlgebraicQ[alpha] || ! positiveAlgebraicQ[b],
  fail["InvalidOrder", "alpha and b must be positive exact algebraic numbers."]];
 If[compare[alpha b - 1, sigma] >= 0,
  fail["UncertifiedJetOrder", "Requested coefficients reach or exceed the unknown source remainder order."]];
 r = modelExpansion[c, alpha, data, ell, y, b, OptionValue[Assumptions],
   OptionValue["MaxMultiIndices"], OptionValue["MaxGenerators"]];
 extra = (y/c)^((1 + sigma)/alpha)
   (1 + Abs[(Log[y] - Log[c])/alpha])^q;
 Join[r, <|"SourceIsJet" -> True, "ModelRemainderScale" -> r["RemainderScale"],
   "InputRemainderTransportScale" -> extra,
   "RemainderScale" -> r["RemainderScale"] + extra,
   "RemainderKind" -> "Conditional BigO: exact model error plus transported source-jet error",
   "ModelFirstOmittedPower" -> r["FirstOmittedPower"],
   "FirstOmittedPower" -> Min[r["FirstOmittedPower"], (1 + sigma)/alpha],
   "FirstOmittedCoefficient" -> Missing["SourceJetHasUnknownRemainder"],
   "RemainderLogDegree" -> Missing["UseCombinedRemainderScale"],
   "JetHypotheses" -> <|"RelativeRemainderPower" -> sigma, "LogDegree" -> q,
     "RequiredBounds" -> "F=f_model+E with E(x), x E'(x)=O[x^(alpha+sigma)(1+Abs[Log[x]])^q] on a positive interval",
     "VerificationStatus" -> "Conditional: source and derivative bounds are not checked automatically"|>|>]
], failureTag];

End[];
EndPackage[];
