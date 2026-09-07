(* ::Package:: *)
(* PowerLogInverse 1.0.0 -- positive-real inverse germs of finite power-log models.
   SPDX-License-Identifier: MIT
   No external services, numerical exponent comparisons, or PowerExpand are used.
   See Article/power-log-inverse.pdf for proofs and the exact scope of the API.
   Native Wolfram-kernel execution was unavailable during preparation; see
   Verification/STATUS.md and the executable MUnit tests supplied with this file. *)

BeginPackage["PowerLogInverse`"];

PowerLogModel::usage =
 "PowerLogModel[f,x] parses a finite sum of powers of x times polynomials in Log[x]. PowerLogModel[a,p,{{delta1,P1},...},ell] specifies f(x)=a x^p (1+Sum[x^deltaj Pj(Log[x])]). Exact real data, a>0, p>0 and deltaj>0 are required; use Assumptions for parameters.";
PowerLogInverse::usage =
 "PowerLogInverse[f,{x,y,B}] returns the positive inverse expansion at y->0+, retaining complete logarithmic blocks with y exponent strictly less than B. PowerLogInverse[model,{y,B}] uses a PowerLogModel. Option \"Truncation\"->\"Depth\" interprets B as the nonnegative total perturbation degree. Use PowerLogInverseData to retain remainder metadata.";
PowerLogInverseData::usage =
 "PowerLogInverseData[f,{x,y,B}] (or [model,{y,B}]) returns an Association containing the inverse expression, model, coefficient blocks, enumeration details, positive-branch conditions, and a proved asymptotic remainder scale. Options: Assumptions, \"Truncation\" (\"Exponent\" or \"Depth\"), \"InversePower\" (positive, default 1), \"MaxTerms\" (default 10000).";
PowerLogCoefficient::usage =
 "PowerLogCoefficient[model,{k1,...}] gives the polynomial multiplying t^(q+Sum[kj deltaj]), where t=(y/a)^(1/p), q is option \"InversePower\" (default 1), and the polynomial variable is model[\"LogVariable\"]. The zero multiindex returns 1.";

Options[PowerLogModel] = {Assumptions -> True};
Options[PowerLogInverseData] = {
 Assumptions -> True, "Truncation" -> "Exponent",
 "InversePower" -> 1, "MaxTerms" -> 10000};
Options[PowerLogInverse] = Options[PowerLogInverseData];
Options[PowerLogCoefficient] = {Assumptions -> True, "InversePower" -> 1};

Begin["`Private`"];

fail[tag_String, message_String, extra_: <||>] :=
 Throw[Failure[tag, Join[<|"MessageTemplate" -> message|>, extra]], failureTag];

proved[statement_, ass_] := TrueQ[FullSimplify[statement, Assumptions -> ass]];
eq[a_, b_, ass_] := SameQ[a,b] || proved[a == b, ass];
zero[expr_, ass_] := eq[expr, 0, ass];
canon[expr_, ass_] := FullSimplify[expr, Assumptions -> ass];

checkAssumptions[ass_] := If[SameQ[FullSimplify[ass], False],
 fail["InconsistentAssumptions", "The supplied assumptions simplify to False."]];
checkExact[expr_] := If[!FreeQ[expr, _Real],
 fail["InexactInput", "Use exact coefficients, exponents and cutoffs. Machine and arbitrary-precision Real inputs are not silently rationalized."]];
checkReal[expr_, ass_, what_String] := If[!proved[Element[expr, Reals], ass],
 fail["UnprovedReal", "A required real-valued condition could not be proved.",
  <|"Quantity" -> what, "Expression" -> expr, "Assumptions" -> ass|>]];
checkPositive[expr_, ass_, what_String] := (
 checkReal[expr, ass, what];
 If[!proved[expr > 0, ass], fail["UnprovedPositive",
  "A required strict positivity condition could not be proved.",
  <|"Quantity" -> what, "Expression" -> expr, "Assumptions" -> ass|>]]);

(* No numerical fallback: distinct unresolved weights must not be conflated. *)
compare[a_, b_, ass_] := Which[
 eq[a,b,ass], 0,
 proved[a < b, ass], -1,
 proved[a > b, ass], 1,
 True, fail["UndecidableOrder", "Cannot order these exact expressions under the supplied assumptions. Strengthen the assumptions or use depth truncation.",
  <|"Left" -> a, "Right" -> b, "Assumptions" -> ass|>]
];

(* Equality-only collection also works when symbolic weights have no known
   relative order. Unresolved coincidences remain an additive sum; they are
   not asserted to be distinct. Exponent-mode output is ordered separately. *)
addBlock[old_List, weight_, poly_, ass_] := Module[{out = old, j},
 For[j=1, j<=Length[out], j++,
  If[eq[weight, out[[j,1]], ass],
   out[[j,2]] = Expand[out[[j,2]] + poly]; Return[out]]];
 Append[out, {weight, Expand[poly]}]
];

makeModel[a_, p_, raw_List, ell_Symbol, ass_] := Module[
 {terms = {}, row, delta, poly, coeffs, c},
 checkAssumptions[ass]; checkExact[{a,p,raw}];
 If[!FreeQ[{a,p},ell], fail["VariableCollision",
  "The leading coefficient and leading power must be independent of the logarithm variable."]];
 checkPositive[a,ass,"leading coefficient"]; checkPositive[p,ass,"leading power"];
 Do[
  If[!MatchQ[row,{_,_}], fail["InvalidModel", "Every perturbation must be a pair {positive gap, polynomial}."]];
  delta = canon[row[[1]], ass]; poly = Expand[row[[2]]];
  If[!FreeQ[delta,ell], fail["VariableCollision", "A power gap must be independent of the logarithm variable."]];
  If[!PolynomialQ[poly,ell], fail["NonPolynomialLog", "Each logarithmic coefficient must be a polynomial in the supplied logarithm variable.", <|"Expression"->poly|>]];
  If[!zero[poly,ass],
   checkPositive[delta,ass,"power gap"];
   coeffs = CoefficientList[poly,ell];
   Do[checkReal[c,ass,"polynomial coefficient"],{c,coeffs}];
   terms = addBlock[terms,delta,poly,ass]],
  {row,raw}];
 terms = Select[terms, !zero[#[[2]],ass]&];
 <|"Kind" -> "PowerLogModel", "LeadingCoefficient" -> a,
   "LeadingPower" -> p, "Perturbations" -> terms,
   "LogVariable" -> ell, "Assumptions" -> ass|>
];

(* A deliberately conservative grammar. Log[x^2], nested powers, analytic
   functions of x, non-polynomial log coefficients, and ConditionalExpression
   are not rewritten by branch-unsafe transformations. *)
parseModel[f_, x_Symbol, ass_] := Module[
 {ell = Unique["ell$"], expanded, summands, factors, term, factor,
  beta, poly, rows = {}, candidates, p, a, leading, rest, row},
 checkAssumptions[ass]; checkExact[f];
 expanded = Expand[f /. Log[x] -> ell];
 summands = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
 Do[
  beta = 0; poly = 1;
  factors = If[Head[term] === Times, List @@ term, {term}];
  Do[
   Which[
    SameQ[factor,x], beta = beta + 1,
    MatchQ[factor, Power[x,_]] && FreeQ[factor[[2]], x | ell],
      beta = beta + factor[[2]],
    FreeQ[factor,x], poly = poly factor,
    True, fail["UnsupportedInput", "The input is not a finite power-log polynomial in the supported grammar. Supply an explicit PowerLogModel or a separately justified finite expansion.", <|"Factor" -> factor|>]
   ], {factor,factors}];
  If[!PolynomialQ[poly,ell], fail["NonPolynomialLog", "Only nonnegative integer powers of Log[x] are supported by the parser.", <|"Expression"->poly|>]];
  If[!zero[poly,ass],
   beta = canon[beta,ass]; checkReal[beta,ass,"input exponent"];
   rows = addBlock[rows,beta,poly,ass]],
  {term,summands}];
 rows = Select[rows, !zero[#[[2]],ass]&];
 If[rows === {}, fail["ZeroFunction", "The zero function has no inverse germ of the required kind."]];
 (* Find a provably least exponent without requiring an order between all
    the higher symbolic exponents. *)
 candidates = Select[rows, Function[r,
   And @@ (proved[r[[1]] <= #[[1]],ass]& /@ rows)]];
 If[candidates === {}, fail["UndecidableLeadingTerm", "No least input exponent can be proved under the supplied assumptions."]];
 p = candidates[[1,1]];
 leading = Select[rows, eq[#[[1]],p,ass]&];
 a = Expand[Total[leading[[All,2]]]];
 If[!FreeQ[a,ell], fail["LogarithmicLeadingTerm", "The leading term must be a positive constant times x^p, not a nonconstant function of Log[x]."]];
 rest = Select[rows, !eq[#[[1]],p,ass]&];
 makeModel[a,p,({canon[#[[1]]-p,ass],Expand[#[[2]]/a]}& /@ rest),ell,ass]
];

readModel[model_Association, extraAss_] := Module[{needed, ass},
 needed = {"Kind","LeadingCoefficient","LeadingPower","Perturbations","LogVariable","Assumptions"};
 If[!(And @@ (KeyExistsQ[model,#]& /@ needed)) || model["Kind"] =!= "PowerLogModel",
  fail["InvalidModel", "Use an Association returned by PowerLogModel."]];
 ass = model["Assumptions"] && extraAss;
 If[!MatchQ[model["LogVariable"],_Symbol] || !ListQ[model["Perturbations"]],
  fail["InvalidModel", "The model has invalid logarithm-variable or perturbation fields."]];
 makeModel[model["LeadingCoefficient"],model["LeadingPower"],
  model["Perturbations"],model["LogVariable"],ass]
];

coefficient[model_Association, k_List, q_, ass_] := Module[
 {n = Total[k], gaps, polys, p, ell, w, z, r},
 If[n == 0, Return[1]];
 gaps = model["Perturbations"][[All,1]];
 polys = model["Perturbations"][[All,2]];
 p = model["LeadingPower"]; ell = model["LogVariable"];
 w = canon[k . gaps,ass];
 z = Expand[Times @@ MapThread[Power,{polys,k}]];
 For[r=1,r<=n-1,r++, z = Expand[(q+w+p r) z + D[z,ell]]];
 Expand[(-1)^n q z/(p^n (Times @@ (Factorial /@ k)))]
];

(* Breadth-first traversal visits each labelled multiindex once. Only accepted
   indices are expanded. A rejected child is retained on the boundary; its
   smallest weight gives a valid first-omitted-weight remainder estimate. *)
enumerate[gaps_List, cutoff_, mode_String, limit_Integer, ass_] := Module[
 {m = Length[gaps], origin, queue, boundary = {}, seen, cursor = 1,
  k, child, key, w, accept, j},
 origin = ConstantArray[0,m]; queue = {origin};
 seen = Association[ToString[origin,InputForm] -> True];
 While[cursor <= Length[queue],
  k = queue[[cursor]]; cursor++;
  For[j=1,j<=m,j++,
   child = ReplacePart[k,j -> k[[j]]+1]; key = ToString[child,InputForm];
   If[!KeyExistsQ[seen,key],
    If[Length[seen] >= limit, fail["TermLimit", "The multiindex enumeration exceeded the requested resource limit. No partial expansion is returned.", <|"MaxTerms"->limit|>]];
    AssociateTo[seen,key -> True];
    accept = If[mode === "Depth", Total[child] <= cutoff,
      w = canon[child . gaps,ass]; compare[w,cutoff,ass] < 0];
    If[TrueQ[accept], AppendTo[queue,child], AppendTo[boundary,child]]
   ]
  ]
 ];
 <|"Indices"->queue,"Boundary"->boundary,"VisitedCount"->Length[seen]|>
];

build[model_Association, y_Symbol, order_, mode_, q_, limit_, ass_] := Module[
 {a, p, ell, terms, gaps, degrees, cut, enum, blocks = {}, k, w, poly,
  boundary, ws, wstar, kstar, n, t = Unique["t$"], expr, norm,
  rem, scale, firstExponent, effectiveAss, b, dmin, kmax},
 If[!MemberQ[{"Exponent","Depth"},mode], fail["InvalidTruncation", "The truncation mode must be \"Exponent\" or \"Depth\"."]];
 If[!IntegerQ[limit] || limit < 1, fail["InvalidLimit", "The MaxTerms option must be a positive integer."]];
 checkExact[{order,q}]; checkPositive[q,ass,"inverse power"];
 a = model["LeadingCoefficient"]; p = model["LeadingPower"];
 ell = model["LogVariable"]; terms = model["Perturbations"];
 If[!FreeQ[{a,p,terms,order,q},y] || SameQ[y,ell],
  fail["VariableCollision", "The output variable must be distinct from the logarithm variable and absent from all model parameters, the inverse power, and the cutoff."]];
 If[!FreeQ[{order,q},ell], fail["VariableCollision", "The cutoff and inverse power must not depend on the logarithm variable."]];
 effectiveAss = ass && y > 0;
 If[mode === "Depth",
  If[!IntegerQ[order] || order < 0, fail["InvalidDepth", "Depth must be a nonnegative integer."]]; cut = order,
  checkReal[order,ass,"exponent cutoff"]; cut = canon[p order-q,ass];
  If[!proved[cut > 0,ass], fail["CutoffTooLow", "The cutoff must be strictly larger than the leading y exponent q/p."]]
 ];
 If[terms === {},
  gaps = {}; degrees = {},
  gaps = terms[[All,1]]; degrees = Exponent[#,ell]& /@ terms[[All,2]]
 ];
 enum = enumerate[gaps,cut,mode,limit,ass];
 Do[
  w = If[gaps === {},0,canon[k . gaps,ass]];
  poly = coefficient[model,k,q,ass];
  blocks = addBlock[blocks,w,poly,ass], {k,enum["Indices"]}];
 blocks = Select[blocks,!zero[#[[2]],ass]&];
 If[mode === "Exponent", blocks = Sort[blocks,compare[#1[[1]],#2[[1]],ass] <= 0&]];
 expr = Total[((y/a)^((q+#[[1]])/p) (#[[2]] /. ell -> Log[y/a]/p))& /@ blocks];
 norm = Total[(t^(q+#[[1]]) #[[2]])& /@ blocks];
 If[terms === {},
  rem = <|"Type"->"Exact","Scale"->0|>,
  If[mode === "Depth",
   dmin = canon[Min @@ gaps,ass]; kmax = Max @@ degrees;
   wstar = (order+1) dmin; kstar = (order+1) kmax,
   boundary = enum["Boundary"]; ws = canon[# . gaps,ass]& /@ boundary;
   wstar = First[ws];
   Do[If[compare[w,wstar,ass] < 0,wstar=w],{w,Rest[ws]}];
   kstar = Max @@ (#[[1]] . degrees& /@
       Select[Transpose[{boundary,ws}],eq[#[[2]],wstar,ass]&])
  ];
  firstExponent = canon[(q+wstar)/p,ass];
  scale = (y/a)^firstExponent (1+Abs[Log[y/a]/p])^kstar;
  rem = <|"Type"->"BigO","Scale"->scale,
    "NormalizedExponent"->canon[q+wstar,ass],
    "YExponent"->firstExponent,"LogDegree"->kstar,
    "CandidateOmittedWeight"->wstar,
    "MayOverestimateAfterCancellation"->True,
    "Regime"->"y -> 0+; fixed admissible parameters; no numerical Big-O constant is claimed"|>
 ];
 <|"Expression"->expr,"NormalizedExpression"->norm,
   "NormalizedVariable"->t,"LogVariable"->ell,
   "NormalizationRules"->{t -> (y/a)^(1/p),ell -> Log[y/a]/p},
   "Model"->model,"InversePower"->q,"Truncation"->mode,"Cutoff"->order,
   "Terms"->((<|"Weight"->#[[1]],"NormalizedExponent"->q+#[[1]],
       "YExponent"->canon[(q+#[[1]])/p,ass],"LogPolynomial"->#[[2]]|>)& /@ blocks),
   "Remainder"->rem,"Conditions"->effectiveAss,"Branch"->"PositiveNearZero",
   "IncludedMultiindices"->enum["Indices"],"VisitedCount"->enum["VisitedCount"],
   "Ordering"->If[mode === "Exponent","IncreasingExponent","HomotopyDepth; unresolved symbolic coincidences remain additive"]|>
];

PowerLogModel[a_,p_,terms_List,ell_Symbol,OptionsPattern[]] :=
 Catch[makeModel[a,p,terms,ell,OptionValue[Assumptions]],failureTag];
PowerLogModel[f_,x_Symbol,OptionsPattern[]] :=
 Catch[parseModel[f,x,OptionValue[Assumptions]],failureTag];
PowerLogModel[___] := Failure["InvalidArguments",<|"MessageTemplate"->"Use PowerLogModel[f,x] or PowerLogModel[a,p,{{delta,P},...},ell] with unassigned variable symbols."|>];

PowerLogCoefficient[model_Association,k_List,OptionsPattern[]] := Catch[Module[
 {m,ass,q = OptionValue["InversePower"], n},
 m = readModel[model,OptionValue[Assumptions]]; ass=m["Assumptions"];
 checkExact[q]; checkPositive[q,ass,"inverse power"];
 If[!FreeQ[q,m["LogVariable"]], fail["VariableCollision", "The inverse power must not depend on the logarithm variable."]];
 If[Length[k] != Length[m["Perturbations"]] || !(And @@ (IntegerQ[#] && #>=0& /@ k)),
  fail["InvalidMultiindex", "The multiindex must contain one nonnegative integer per normalized perturbation."]];
 coefficient[m,k,q,ass]
],failureTag];
PowerLogCoefficient[___] := Failure["InvalidArguments",<|"MessageTemplate"->"Use PowerLogCoefficient[model,integerMultiindex]."|>];

PowerLogInverseData[f_,{x_Symbol,y_Symbol,order_},OptionsPattern[]] := Catch[Module[
 {m,ass = OptionValue[Assumptions]},
 If[SameQ[x,y], fail["VariableCollision", "Input and output variables must be distinct unassigned symbols."]];
 m = parseModel[f,x,ass];
 build[m,y,order,OptionValue["Truncation"],OptionValue["InversePower"],OptionValue["MaxTerms"],ass]
],failureTag];
PowerLogInverseData[model_Association,{y_Symbol,order_},OptionsPattern[]] := Catch[Module[
 {m,ass}, m=readModel[model,OptionValue[Assumptions]]; ass=m["Assumptions"];
 build[m,y,order,OptionValue["Truncation"],OptionValue["InversePower"],OptionValue["MaxTerms"],ass]
],failureTag];
PowerLogInverseData[___] := Failure["InvalidArguments",<|"MessageTemplate"->"Use PowerLogInverseData[f,{x,y,B}] or PowerLogInverseData[model,{y,B}] with unassigned variable symbols."|>];

PowerLogInverse[f_,spec_List,opts:OptionsPattern[]] := Module[
 {data = PowerLogInverseData[f,spec,opts]},
 If[FailureQ[data],data,data["Expression"]]
];
PowerLogInverse[___] := Failure["InvalidArguments",<|"MessageTemplate"->"Use PowerLogInverse[f,{x,y,B}] or PowerLogInverse[model,{y,B}]."|>];

End[];
EndPackage[];
