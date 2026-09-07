(* ::Package:: *)
(* RealInverseAsymptotics 1.0.0 -- exact finite power-logarithmic inversion.
   Positive-real branch at 0. No InverseFunction, Solve, or PowerExpand is used.
   See article/real-inverse-asymptotics.pdf for hypotheses and proofs.
   This source is supplied with MUnit tests; native-kernel execution status is
   recorded separately in validation/REPORT.md. *)

BeginPackage["RealInverseAsymptotics`"];

PowerLogNormalForm::usage =
 "PowerLogNormalForm[f,x] parses a finite sum of x^r Log[x]^k into a positive-leading-monomial model. Use Assumptions for real symbolic coefficients.";
RealInverseSeries::usage =
 "RealInverseSeries[f,{x,0},y,b] gives the positive-real inverse as y approaches 0 from above, retaining every y-power strictly below b. It returns an Association, not SeriesData.";
InversePowerLog::usage =
 "InversePowerLog[a,p,{{delta1,P1[L]},...},L,y,b] inverts a x^p (1+Sum[x^delta_i P_i[Log[x]]]) through y-powers strictly below b. The model has a>0, p>0, delta_i>0.";
RealInverseResidual::usage =
 "RealInverseResidual[result,b] computes the normalized residual f(G)/(a t^p)-1 through relative t-powers strictly below b, where t=(y/a)^(1/p). It requires an inverse (ObservablePower=1), not a power of the inverse.";
PowerLogRemainder::usage =
 "PowerLogRemainder[t,r,d] is inert metadata meaning O(t^r (1+Abs[Log[t]])^d) as t approaches 0 through positive reals. It does not implement arithmetic on error terms.";
PurePowerInverseCoefficient::usage =
 "PurePowerInverseCoefficient[alpha,n] returns the coefficient of y^(1+n(alpha-1)) in the inverse of x+x^alpha, for exact real algebraic alpha>1 and integer n>=0.";

Options[PowerLogNormalForm] = {Assumptions -> True};
Options[InversePowerLog] = {Assumptions -> True,
 "ObservablePower" -> 1, "Method" -> "Lagrange",
 "MaxMultiIndices" -> 100000, "MaxTotalDegree" -> 1000};
Options[RealInverseSeries] = Options[InversePowerLog];
Options[RealInverseResidual] = {"MaxTotalDegree" -> 1000};

Begin["`Private`"];

$failureTag = Unique["RealInverseAsymptoticsFailure$"];
fail[tag_String, message_String, extra_: <||>] :=
 Throw[Failure[tag, Join[<|"MessageTemplate" -> message|>, extra]], $failureTag];
exactQ[z_] := FreeQ[z, _Real];
algebraicRealQ[z_] := exactQ[z] &&
 TrueQ[FullSimplify[Element[z, Algebraics] && Element[z, Reals],
   Assumptions -> True]];
realQ[z_, ass_] := TrueQ[FullSimplify[Element[z, Reals], ass]];
positiveQ[z_, ass_] := TrueQ[FullSimplify[z > 0, ass]];
canon[z_] := RootReduce[z];
compare[a_, b_] := Module[{d = canon[a - b]},
 Which[TrueQ[d == 0], 0, TrueQ[d < 0], -1, TrueQ[d > 0], 1,
  True, fail["UndecidableExponentOrder", "An exact exponent comparison did not resolve.",
    <|"Left" -> a, "Right" -> b|>]]];
lt[a_, b_] := compare[a, b] == -1;
le[a_, b_] := compare[a, b] != 1;
validateAlgebraic[z_, name_String] := If[!algebraicRealQ[z],
 fail["InvalidExponent", "Exponents and cutoffs must be exact real algebraic numbers.",
  <|"Parameter" -> name, "Value" -> z|>]];
validateLimit[n_, name_String] := If[!IntegerQ[n] || n < 1,
 fail["InvalidResourceLimit", "Resource limits must be positive integers.",
  <|"Parameter" -> name, "Value" -> n|>]];

(* A jet is a sorted list {{relative power, polynomial in L},...}.
   Addition merges exact algebraic exponent collisions by comparison, not
   by machine approximations or by textual identity of expressions. *)
merge[terms_List] := Module[{s, out = {}, e, p, j},
 s = Sort[({canon[#[[1]]], Expand[#[[2]]]} & /@ terms),
   lt[#1[[1]], #2[[1]]] &];
 Do[e = term[[1]]; p = term[[2]];
  If[!TrueQ[p === 0],
   If[Length[out] > 0 && compare[out[[-1, 1]], e] == 0,
    j = Length[out]; out[[j, 2]] = Expand[out[[j, 2]] + p],
    AppendTo[out, {e, p}]]], {term, s}];
 Select[out, !TrueQ[#[[2]] === 0] &]
];
trim[jet_List, bound_] := Select[jet, le[#[[1]], bound] &];
add[jets__List] := merge[Join[jets]];
scale[jet_List, c_] := merge[({#[[1]], c #[[2]]} & /@ jet)];
shift[jet_List, d_, bound_] := trim[
 merge[({canon[#[[1]] + d], #[[2]]} & /@ jet)], bound];
multiply[a_List, b_List, bound_] := Module[{r},
 r = Reap[Do[If[le[u[[1]] + v[[1]], bound],
    Sow[{canon[u[[1]] + v[[1]]], Expand[u[[2]] v[[2]]]}]],
    {u, a}, {v, b}]][[2]];
 If[r === {}, {}, merge[First[r]]]
];
positiveJetOrder[u_List] := If[u === {}, Infinity,
 If[!lt[0, First[u][[1]]],
  fail["NonPositiveJetOrder", "A binomial or logarithm expansion requires positive relative order."]];
 First[u][[1]]];
seriesDegree[bound_, d_, max_Integer] := Module[{n},
 n = Floor[canon[bound/d]];
 If[!IntegerQ[n] || n > max,
  fail["ResourceLimit", "The required formal Taylor degree exceeds MaxTotalDegree.",
   <|"RequiredDegree" -> n, "Limit" -> max|>]];
 Max[0, n]
];
onePlusPower[u_List, r_, bound_, max_Integer] :=
 Module[{d, n, term = {{0, 1}}, out = {{0, 1}}, c = 1},
 If[u === {} || TrueQ[r === 0], Return[out]];
 d = positiveJetOrder[u]; n = seriesDegree[bound, d, max];
 Do[term = multiply[term, u, bound];
   If[term === {}, Break[]]; c = c (r - k + 1)/k;
   If[!TrueQ[c === 0], out = add[out, scale[term, c]]], {k, 1, n}];
 out
];
logOnePlus[u_List, bound_, max_Integer] :=
 Module[{d, n, term = {{0, 1}}, out = {}},
 If[u === {}, Return[{}]];
 d = positiveJetOrder[u]; n = seriesDegree[bound, d, max];
 Do[term = multiply[term, u, bound]; If[term === {}, Break[]];
  out = add[out, scale[term, (-1)^(k + 1)/k]], {k, 1, n}]; out
];
polynomialAtJet[pol_, L_Symbol, logv_List, bound_] :=
 Module[{out = {}, argument, d},
 argument = add[{{0, L}}, logv]; d = Exponent[pol, L];
 If[TrueQ[pol === 0], Return[{}]];
 Do[out = add[multiply[out, argument, bound],
    {{0, Coefficient[pol, L, k]}}], {k, d, 0, -1}]; out
];
correctionJet[v_List, corrections_List, L_Symbol, bound_, max_Integer] :=
 Module[{u, logv, out = {}, z},
 u = add[v, {{0, -1}}]; logv = logOnePlus[u, bound, max];
 Do[z = multiply[onePlusPower[u, c[[1]], bound, max],
      polynomialAtJet[c[[2]], L, logv, bound], bound];
    out = add[out, shift[z, c[[1]], bound]], {c, corrections}]; out
];
fixedPointJet[p_, corrections_List, L_Symbol, bound_, max_Integer] :=
 Module[{v = {{0, 1}}, h, next, n, d},
 If[corrections === {}, Return[v]];
 d = First[corrections][[1]]; n = seriesDegree[bound, d, max] + 1;
 Do[h = correctionJet[v, corrections, L, bound, max];
   next = onePlusPower[h, -1/p, bound, max];
   If[SameQ[next, v], Return[v]]; v = next, {n}]; v
];

parseTerm[term_, x_Symbol, L_Symbol] :=
 Module[{factors, exponent = 0, degree = 0, coefficient = 1},
 factors = If[Head[term] === Times, List @@ term, {term}];
 Do[Which[
   FreeQ[z, x], coefficient *= z,
   SameQ[z, x], exponent += 1,
   MatchQ[z, Power[x, _]] && FreeQ[z[[2]], x], exponent += z[[2]],
   SameQ[z, Log[x]], degree += 1,
   Head[z] === Power && SameQ[z[[1]], Log[x]] &&
      IntegerQ[z[[2]]] && z[[2]] >= 0, degree += z[[2]],
   True, fail["UnsupportedInput", "Expected a finite sum of x^r times polynomials in Log[x]. Nested logarithms, leading logarithms, and other function calls require a different normalization.",
      <|"OffendingFactor" -> z|>]], {z, factors}];
 validateAlgebraic[exponent, "power of x"];
 {canon[exponent], coefficient L^degree}
];

PowerLogNormalForm[f_, x_Symbol, OptionsPattern[]] := Catch[
 Module[{L = Unique["ell$"], ass = OptionValue[Assumptions], e, terms, parsed,
   p, a, coefficients, corrections},
 If[!exactQ[f], fail["InexactInput", "Use exact coefficients and exponents; automatic rationalization is not performed."]];
 e = Expand[f]; terms = If[Head[e] === Plus, List @@ e, {e}];
 parsed = merge[parseTerm[#, x, L] & /@ terms];
 parsed = merge[({#[[1]], FullSimplify[#[[2]], ass]} & /@ parsed)];
 If[parsed === {}, fail["ZeroFunction", "The zero function has no inverse germ."]];
 p = parsed[[1, 1]]; a = parsed[[1, 2]];
 If[!lt[0, p], fail["InvalidLeadingPower", "The leading power must be positive for an inverse germ at y=0."]];
 If[!FreeQ[a, L], fail["LogarithmicLeadingTerm", "The leading coefficient depends on Log[x]. The implemented normalization requires a positive constant leading coefficient."]];
 If[!positiveQ[a, ass], fail["LeadingCoefficientNotPositive", "The leading coefficient must be provably positive; supply Assumptions for symbolic parameters.", <|"Coefficient" -> a|>]];
 coefficients = Flatten[CoefficientList[#[[2]], L] & /@ parsed];
 If[!(And @@ (realQ[#, ass] & /@ coefficients)),
  fail["NonRealCoefficient", "All coefficients must be provably real under Assumptions."]];
 corrections = ({canon[#[[1]] - p], Expand[#[[2]]/a]} & /@ Rest[parsed]);
 <|"Coefficient" -> a, "Power" -> p, "Corrections" -> corrections,
   "LogVariable" -> L, "Assumptions" -> ass|>
 ], $failureTag];

(* Enumerate only the finite simplex sum k_i delta_i <= bound. *)
indices[deltas_List, bound_, max_Integer] :=
 Module[{visit, m = Length[deltas], count = 0, r},
 visit[i_, weight_, counts_] := Module[{limit},
  If[i > m,
   count++; If[count > max,
    fail["ResourceLimit", "Multi-index enumeration exceeded MaxMultiIndices.",
     <|"Limit" -> max|>]];
   Sow[{canon[weight], counts}],
   limit = Floor[canon[(bound - weight)/deltas[[i]]]];
   If[!IntegerQ[limit], fail["EnumerationFailure", "An exact simplex bound did not reduce to an integer."]];
   Do[visit[i + 1, canon[weight + k deltas[[i]]], Append[counts, k]],
      {k, 0, limit}]]];
 r = Reap[visit[1, 0, {}]][[2]];
 If[r === {}, {}, First[r]]
];
lagrangePolynomial[p_, q_, corrections_List, L_Symbol, pair_] :=
 Module[{w = pair[[1]], ks = pair[[2]], n, pol},
 n = Total[ks];
 If[n == 0, Return[1]];
 pol = Expand[Times @@ MapThread[Power, {corrections[[All, 2]], ks}]];
 Do[pol = Expand[(q + w + p j) pol + D[pol, L]], {j, 1, n - 1}];
 Expand[(-1)^n q pol/(p^n Times @@ (Factorial /@ ks))]
];
targetExpression[terms_List, L_Symbol, a_, p_, y_Symbol] :=
 Total[((y/a)^(#[[1]]/p) (#[[2]] /. L -> Log[y/a]/p)) & /@ terms];

InversePowerLog[a_, p_, raw_List, L_Symbol, y_Symbol, cutoff_, OptionsPattern[]] :=
 Catch[Module[{ass = OptionValue[Assumptions], q = OptionValue["ObservablePower"],
   method = OptionValue["Method"], max = OptionValue["MaxMultiIndices"],
   maxDegree = OptionValue["MaxTotalDegree"], corrections, coeffs, B, dmin,
   ceiling, upper, all, frontier, selected, jet, terms, kept, frontierPol,
   degree, v, u, t, normalizedTerms, common, remainder},
 validateAlgebraic[p, "leading power"];
 validateAlgebraic[q, "observable power"];
 validateAlgebraic[cutoff, "cutoff"];
 validateLimit[max, "MaxMultiIndices"]; validateLimit[maxDegree, "MaxTotalDegree"];
 If[!lt[0, p], fail["InvalidLeadingPower", "The leading power must be positive."]];
 If[SameQ[L, y], fail["VariableCollision", "The logarithmic placeholder and target variable must differ."]];
 If[!MemberQ[{"Lagrange", "FixedPoint"}, method],
  fail["UnknownMethod", "Method must be Lagrange or FixedPoint."]];
 If[!exactQ[a] || !FreeQ[a, L | y] || !positiveQ[a, ass],
  fail["LeadingCoefficientNotPositive", "The leading coefficient must be an exact positive constant independent of the target and log variables."]];
 If[!lt[q/p, cutoff], fail["CutoffTooSmall", "The strict cutoff must exceed the leading y-power."]];
 If[!(And @@ (MatchQ[#, {_, _}] & /@ raw)),
  fail["InvalidModel", "Corrections must be pairs {positive delta, polynomial in the log placeholder}."]];
 Do[validateAlgebraic[c[[1]], "correction delta"];
  If[!lt[0, c[[1]]], fail["NonPositiveCorrection", "Every correction exponent delta must be strictly positive."]];
  If[!exactQ[c[[2]]] || !PolynomialQ[c[[2]], L] || !FreeQ[c[[2]], y],
   fail["InvalidLogPolynomial", "Each amplitude must be an exact polynomial in the supplied logarithmic placeholder, independent of the target variable."]];
  coeffs = CoefficientList[c[[2]], L];
  If[!(And @@ (realQ[#, ass] & /@ coeffs)),
    fail["NonRealCoefficient", "All amplitude coefficients must be provably real under Assumptions."]], {c, raw}];
 corrections = merge[({#[[1]], FullSimplify[#[[2]], ass]} & /@ raw)];
 common = <|"Coefficient" -> a, "LeadingPower" -> p,
   "Corrections" -> corrections, "LogVariable" -> L, "TargetVariable" -> y,
   "Cutoff" -> cutoff, "CutoffConvention" -> "Strict target-variable power",
   "TermBasis" -> "t=(y/a)^(1/p); each term is {t-power, polynomial in LogVariable}",
   "ObservablePower" -> q, "Method" -> method, "Assumptions" -> ass && y > 0,
   "Branch" -> "Positive real germ at 0; x/(y/a)^(1/p) tends to 1"|>;
 If[corrections === {} || TrueQ[q === 0],
  Return[Join[common, <|"Expression" -> (y/a)^(q/p), "Terms" -> {{q, 1}},
    "Remainder" -> 0, "RemainderPower" -> Infinity, "RemainderLogDegree" -> 0,
    "FrontierWeight" -> Infinity, "FrontierPolynomial" -> 0,
    "IsExact" -> True, "EnumeratedMultiIndices" -> 0|>]]];
 B = canon[p cutoff - q]; dmin = First[corrections][[1]];
 ceiling = Ceiling[canon[B/dmin]];
 If[!IntegerQ[ceiling] || ceiling > maxDegree,
  fail["ResourceLimit", "The requested order exceeds MaxTotalDegree.",
    <|"RequiredDegree" -> ceiling, "Limit" -> maxDegree|>]];
 upper = canon[ceiling dmin];
 all = indices[corrections[[All, 1]], upper, max];
 frontier = First[Sort[Select[all[[All, 1]], le[B, #] &], lt]];
 selected = Select[all, le[#[[1]], frontier] &];
 jet = If[method === "Lagrange",
   merge[({#[[1]], lagrangePolynomial[p, q, corrections, L, #]} & /@ selected)],
   v = fixedPointJet[p, corrections, L, frontier, maxDegree];
   u = add[v, {{0, -1}}]; onePlusPower[u, q, frontier, maxDegree]];
 jet = merge[({#[[1]], FullSimplify[#[[2]], ass]} & /@ jet)];
 terms = ({canon[q + #[[1]]], #[[2]]} & /@ jet);
 kept = Select[terms, lt[#[[1]], p cutoff] &];
 frontierPol = Total[Last /@ Select[jet, compare[#[[1]], frontier] == 0 &]];
 degree = If[TrueQ[frontierPol === 0], 0, Exponent[frontierPol, L]];
 t = (y/a)^(1/p);
 remainder = PowerLogRemainder[t, canon[q + frontier], degree];
 Join[common, <|"Expression" -> targetExpression[kept, L, a, p, y],
   "Terms" -> kept, "Remainder" -> remainder,
   "RemainderPower" -> canon[(q + frontier)/p], "RemainderLogDegree" -> degree,
   "FrontierWeight" -> frontier, "FrontierPolynomial" -> frontierPol,
   "FrontierExpression" -> targetExpression[{{q + frontier, frontierPol}}, L, a, p, y],
   "IsExact" -> False, "EnumeratedMultiIndices" -> Length[all]|>]
 ], $failureTag];

RealInverseSeries[f_, {x_Symbol, 0}, y_Symbol, cutoff_, OptionsPattern[]] :=
 Catch[Module[{model},
 If[SameQ[x, y], fail["VariableCollision", "Use distinct source and target variables."]];
 model = PowerLogNormalForm[f, x, Assumptions -> OptionValue[Assumptions]];
 If[FailureQ[model], Return[model]];
 InversePowerLog[model["Coefficient"], model["Power"], model["Corrections"],
  model["LogVariable"], y, cutoff, Assumptions -> OptionValue[Assumptions],
  "ObservablePower" -> OptionValue["ObservablePower"],
  "Method" -> OptionValue["Method"],
  "MaxMultiIndices" -> OptionValue["MaxMultiIndices"],
  "MaxTotalDegree" -> OptionValue["MaxTotalDegree"]]
 ], $failureTag];

RealInverseResidual[result_Association, bound_, OptionsPattern[]] :=
 Catch[Module[{p, a, q, L, y, v, u, h, residual, max, expression, terms},
 If[!(And @@ (KeyExistsQ[result, #] & /@
    {"Coefficient", "LeadingPower", "ObservablePower", "Corrections",
     "LogVariable", "TargetVariable", "Terms"})),
  fail["InvalidResult", "Expected an Association returned by RealInverseSeries or InversePowerLog."]];
 validateAlgebraic[bound, "relative normalized residual cutoff"];
 If[!lt[0, bound], fail["InvalidCutoff", "The residual cutoff must be positive."]];
 max = OptionValue["MaxTotalDegree"]; validateLimit[max, "MaxTotalDegree"];
 q = result["ObservablePower"];
 If[compare[q, 1] != 0,
  fail["NotAnInverse", "Residual composition requires ObservablePower equal to 1."]];
 p = result["LeadingPower"]; a = result["Coefficient"];
 L = result["LogVariable"]; y = result["TargetVariable"];
 v = trim[merge[({canon[#[[1]] - 1], #[[2]]} & /@ result["Terms"])], bound];
 u = add[v, {{0, -1}}];
 h = correctionJet[v, result["Corrections"], L, bound, max];
 residual = add[multiply[onePlusPower[u, p, bound, max],
                 add[{{0, 1}}, h], bound], {{0, -1}}];
 residual = merge[({#[[1]], FullSimplify[#[[2]],
     Lookup[result, "Assumptions", True]]} & /@ residual)];
 terms = Select[residual, lt[#[[1]], bound] &];
 expression = targetExpression[terms, L, a, p, y];
 <|"Terms" -> terms, "Expression" -> expression,
   "LogVariable" -> L, "AllZero" -> (terms === {}),
   "RelativeNormalizedCutoff" -> bound,
   "Meaning" -> "Finite jet of f(G)/(a t^p)-1, t=(y/a)^(1/p); no numerical error certificate is asserted"|>
 ], $failureTag];

PurePowerInverseCoefficient[alpha_, n_Integer] /; n >= 0 := Catch[
 Module[{value}, validateAlgebraic[alpha, "alpha"];
 If[!lt[1, alpha], fail["InvalidPower", "alpha must exceed 1."]];
 If[n == 0, Return[1]];
 value = (-1)^n Product[n alpha - j, {j, 0, n - 2}]/n!;
 RootReduce[value]
 ], $failureTag];
PurePowerInverseCoefficient[alpha_, n_] :=
 Failure["InvalidIndex", <|"MessageTemplate" -> "n must be a nonnegative integer.", "Index" -> n|>];

End[];
EndPackage[];
