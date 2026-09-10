(* ::Package:: *)
(* PowerLogInverse 1.0.0 -- positive-real, power-logarithmic inverse germs.
   The MIT-0 license in ../LICENSE applies to this implementation.
   No PowerExpand, InverseFunction, or fractional SeriesData is used. *)

BeginPackage["PowerLogInverse`"];

PowerLogInverse::usage =
 "PowerLogInverse[f,{x,y,c}] returns the finite asymptotic inverse of f as y->0+; c is a strict cutoff in u=(y/a)^(1/p), where f~a x^p. Use PowerLogInverseData for the remainder and metadata.";
PowerLogInverseData::usage =
 "PowerLogInverseData[f,{x,y,c}] returns an Association containing the inverse, its power-log blocks, a proven asymptotic remainder envelope, and its positive-real normalization. f must be a finite sum of x^r times polynomials in Log[x], with a positive constant leading block.";
PowerLogReversion::usage =
 "PowerLogReversion[a,p,{{delta1,P1[l]},...},{u,l},c] reverts a x^p (1+Sum[x^delta_i P_i[Log[x]]]). It returns data in independent symbols u,l, with x inverse = u+... and strict u-power cutoff c>1. Exponents and cutoff must be exact real algebraic numbers; delta_i>0 and a,p>0.";
PowerLogResidual::usage =
 "PowerLogResidual[data,b] independently expands f(A)/(a u^p)-1 through relative u-powers < b, using the finite approximant A stored in data[\"Terms\"]. Automatic b is data[\"Cutoff\"]-1. Its Certificate is an exact truncated-algebra check, not a numerical interval certificate.";
PowerLogOrder::usage =
 "PowerLogOrder[u,c,k] is an inert remainder descriptor meaning O(u^c (1+Abs[Log[u]])^k) for u->0+. It is not SeriesData or an arithmetic object.";
LogPowerBaseInverse::usage =
 "LogPowerBaseInverse[y,a,p,q] returns the small positive inverse germ of a x^p (-Log[x])^q using the correct real ProductLog branch. Requires exact real a,p>0 and exact real q. The identity holds for sufficiently small positive y; q=0 gives a pure power.";
InversePerturbationJet::usage =
 "InversePerturbationJet[b,h,{z,y,n}] returns the degree-n homotopy jet for b(s), where s+h(s)=y. Here b and h are expressions in z. It is a formal derivative formula; the caller supplies the branch and analytic/smallness hypotheses.";

Begin["`Private`"];

$failureTag = Unique["PowerLogInverseFailure"];
fail[tag_String, text_String, extra_: <||>] :=
 Throw[Failure[tag, Join[<|"MessageTemplate" -> text|>, extra]], $failureTag];

exactRealQ[z_] := FreeQ[z, _Real] &&
 TrueQ[FullSimplify[Element[z, Reals]]];
algebraicRealQ[z_] := exactRealQ[z] &&
 TrueQ[FullSimplify[Element[z, Algebraics]]];
canon[z_] := RootReduce[z];
zeroQ[z_] := TrueQ[z === 0] || TrueQ[FullSimplify[z == 0]];
less[a_, b_] := Module[{v},
 If[b === Infinity, Return[True]];
 v = FullSimplify[a < b];
 Which[TrueQ[v], True, v === False, False,
  True, fail["UndecidableOrder", "Could not determine an exact exponent ordering.",
   <|"Left" -> a, "Right" -> b|>]]
];
polyNormal[z_, l_] := Expand[Collect[Expand[z], l, FullSimplify]];

Options[PowerLogReversion] = {
 "MaxMultiIndices" -> 100000, "MaxTerms" -> 50000,
 "MaxTotalDegree" -> 256, "MaxProducts" -> 2000000
};
Options[PowerLogInverseData] = Options[PowerLogReversion];
Options[PowerLogInverse] = Options[PowerLogReversion];

limits[mi_, mt_, md_, mp_] := Module[{v = {mi, mt, md, mp}},
 If[!(And @@ (Function[z, IntegerQ[z] && z > 0] /@ v)),
  fail["InvalidLimit", "All resource limits must be positive integers."]];
 <|"MaxMultiIndices" -> mi, "MaxTerms" -> mt,
   "MaxTotalDegree" -> md, "MaxProducts" -> mp|>
];

(* Canonical sparse blocks. Exact sorting followed by equality-aware grouping
   makes collisions safe even if two algebraic inputs have different syntax. *)
normalizeRows[rows_List, l_, cut_, lim_Association] := Module[{r, groups},
 r = ({canon[#[[1]]], Expand[#[[2]]]} &) /@ rows;
 r = Select[r, !zeroQ[#[[2]]] && less[#[[1]], cut] &];
 If[r === {}, Return[{}]];
 r = Sort[r, less[#1[[1]], #2[[1]]] &];
 groups = Split[r, zeroQ[#1[[1]] - #2[[1]]] &];
 r = ({#[[1, 1]], polyNormal[Total[#[[All, 2]]], l]} &) /@ groups;
 r = Select[r, !zeroQ[#[[2]]] &];
 If[Length[r] > lim["MaxTerms"],
  fail["TermLimit", "The number of retained blocks exceeds MaxTerms.",
   <|"Terms" -> Length[r]|>]];
 r
];

validatePolynomial[P_, l_] := Module[{co},
 If[!PolynomialQ[P, l],
  fail["NotLogPolynomial", "Each logarithmic block must be a polynomial in the designated logarithm symbol.", <|"Block" -> P|>]];
 co = CoefficientList[P, l];
 If[!(And @@ (exactRealQ /@ co)),
  fail["NonrealOrInexactCoefficient", "Logarithmic polynomial coefficients must be exact, provably real constants.", <|"Block" -> P|>]]
];

parseTerm[t_, x_, l_] := Module[{factors, e = 0, q = 1},
 factors = If[Head[t] === Times, List @@ t, {t}];
 Do[
  Which[
   factor === x, e = e + 1,
   Head[factor] === Power && factor[[1]] === x,
    If[!algebraicRealQ[factor[[2]]],
     fail["UnsupportedExponent", "Powers of the source variable must have exact real algebraic exponents.", <|"Factor" -> factor|>]];
    e = e + factor[[2]],
   True, q = q factor
  ], {factor, factors}];
 If[!FreeQ[q, x],
  fail["UnsupportedExpression", "Input must expand into powers of x times polynomials in Log[x]. Normalize other functions explicitly first.", <|"Term" -> t|>]];
 validatePolynomial[q, l];
 {canon[e], Expand[q]}
];

parseInput[expr_, x_, l_, lim_] := Module[{e = expr, cond = True, ts, rows, p, a, corr},
 If[Head[e] === ConditionalExpression,
  cond = e[[2]];
  If[!TrueQ[FullSimplify[cond, Assumptions -> x > 0]],
   fail["UnresolvedCondition", "The input condition is not provably implied by x>0. Select and normalize the intended germ explicitly.", <|"Condition" -> cond|>]];
  e = e[[1]]
 ];
 e = Expand[e /. HoldPattern[Log[x]] -> l];
 ts = If[Head[e] === Plus, List @@ e, {e}];
 rows = normalizeRows[(parseTerm[#, x, l] &) /@ ts, l, Infinity, lim];
 If[rows === {}, fail["ZeroFunction", "The zero function has no inverse germ."]];
 {p, a} = First[rows];
 If[!FreeQ[a, l],
  fail["LeadingLogBlock", "The leading power has a nonconstant logarithmic coefficient. Use a leading-log normalization (see LogPowerBaseInverse) before perturbative inversion.", <|"LeadingBlock" -> a|>]];
 If[!less[0, p] || !TrueQ[FullSimplify[a > 0]],
  fail["WrongLeadingGerm", "For the selected y->0+ germ the leading coefficient and power must be positive.", <|"LeadingCoefficient" -> a, "LeadingExponent" -> p|>]];
 corr = ({canon[#[[1]] - p], polyNormal[#[[2]]/a, l]} &) /@ Rest[rows];
 <|"LeadingCoefficient" -> a, "LeadingExponent" -> p,
   "Corrections" -> corr, "InputCondition" -> cond|>
];

(* Enumerate only the finite simplex m.delta < B. No floating-point sorting,
   no rational approximation of irrational support generators. *)
enumerateIndices[d_List, B_, lim_] := Module[{s = Length[d], harvested,
  count = 0, stack, node, i, w, prefix, bound},
 If[s === 0, Return[{}]];
 stack = {{1, 0, {}}};
 harvested = Reap[
  While[stack =!= {},
   node = Last[stack]; stack = Most[stack];
   {i, w, prefix} = node;
   If[i > s,
    If[Total[prefix] > 0,
     count++;
     If[count > lim["MaxMultiIndices"],
      fail["IndexLimit", "The requested expansion exceeds MaxMultiIndices."]];
     Sow[prefix]
    ],
    bound = Ceiling[canon[(B - w)/d[[i]]]] - 1;
    If[!IntegerQ[bound], fail["UndecidableBound", "Could not compute an exact enumeration bound."]];
    If[Length[stack] + bound + 1 > lim["MaxProducts"],
     fail["FrontierLimit", "The enumeration frontier exceeds MaxProducts."]];
    Do[AppendTo[stack, {i + 1, canon[w + k d[[i]]], Append[prefix, k]}],
     {k, bound, 0, -1}]
   ]
  ]
 ];
 If[harvested[[2]] === {}, {}, First[harvested[[2]]]]
];

(* The multi-index Lagrange--Buermann differential polynomial. *)
coefficientFor[m_List, d_List, pol_List, p_, l_] := Module[{n, delta, q},
 n = Total[m]; delta = canon[m . d];
 q = Expand[Times @@ MapThread[Power, {pol, m}]];
 Do[q = polyNormal[D[q, l] + (1 + delta + p j) q, l],
  {j, 1, n - 1}];
 {canon[1 + delta], polyNormal[(-1)^n q/(p^n (Times @@ (Factorial /@ m))), l]}
];

PowerLogReversion[a_, p_, corrections_List, {u_Symbol, l_Symbol}, c_, OptionsPattern[]] :=
 Catch[Module[{lim, corr, d, pol, B, nmax, degree, inds, rows,
  active, expression, rem, minDelta, kmax, count},
  lim = limits[OptionValue["MaxMultiIndices"], OptionValue["MaxTerms"],
   OptionValue["MaxTotalDegree"], OptionValue["MaxProducts"]];
  If[u === l, fail["VariableCollision", "The uniformizer and logarithm symbols must be distinct."]];
  If[!exactRealQ[a] || !TrueQ[FullSimplify[a > 0]] ||
    !algebraicRealQ[p] || !less[0, p],
   fail["InvalidLeadingTerm", "a must be exact real and positive; p must be exact real algebraic and positive."]];
  If[!algebraicRealQ[c] || !less[1, c],
   fail["InvalidCutoff", "The strict uniformizer-power cutoff must be an exact real algebraic number greater than 1."]];
  If[!(And @@ (MatchQ[#, {_, _}] & /@ corrections)),
   fail["InvalidCorrections", "Corrections must be pairs {positive exponent, logarithmic polynomial}."]];
  Do[
   If[!algebraicRealQ[t[[1]]] || !less[0, t[[1]]],
    fail["NonpositiveCorrection", "Every correction exponent must be an exact positive real algebraic number.", <|"Correction" -> t|>]];
   If[!FreeQ[t[[2]], u], fail["VariableCollision", "Correction coefficients must be independent of the uniformizer."]];
   validatePolynomial[t[[2]], l], {t, corrections}];
  corr = normalizeRows[corrections, l, Infinity, lim];
  B = canon[c - 1];
  If[corr === {},
   rows = {{1, 1}}; rem = 0; degree = 0; nmax = 0; count = 0,
   d = corr[[All, 1]]; pol = corr[[All, 2]];
   minDelta = First[d]; kmax = Max[Exponent[#, l] & /@ pol];
   nmax = Ceiling[canon[B/minDelta]];
   If[!IntegerQ[nmax] || nmax > lim["MaxTotalDegree"] + 1,
    fail["DegreeLimit", "The requested simplex requires a larger MaxTotalDegree.", <|"RequiredMaxDegree" -> nmax - 1|>]];
   degree = nmax kmax;
   active = Select[corr, less[#[[1]], B] &];
   If[active === {}, inds = {}; rows = {{1, 1}},
    d = active[[All, 1]]; pol = active[[All, 2]];
    inds = enumerateIndices[d, B, lim];
    rows = normalizeRows[Join[{{1, 1}},
      (coefficientFor[#, d, pol, p, l] &) /@ inds], l, c, lim]
   ];
   count = Length[inds]; rem = PowerLogOrder[u, c, degree]
  ];
  expression = Total[(u^#[[1]] #[[2]] &) /@ rows];
  <|"Kind" -> "PowerLogInverseData/1", "Version" -> "1.0.0",
    "Expression" -> expression, "UniformizerExpression" -> expression,
    "UniformizerSymbol" -> u, "LogSymbol" -> l,
    "UniformizerRule" -> {}, "LogRule" -> {},
    "Terms" -> rows, "LeadingCoefficient" -> a, "LeadingExponent" -> p,
    "Corrections" -> corr, "Cutoff" -> c, "RelativeCutoff" -> B,
    "Remainder" -> rem, "RemainderLogDegree" -> degree,
    "MultiIndexCount" -> count, "MaxEnumeratedDegree" -> Max[0, nmax - 1],
    "InputSemantics" -> "Exact finite power-log germ, positive-real branch",
    "Limits" -> lim|>
 ], $failureTag];

PowerLogInverseData[expr_, {x_Symbol, y_Symbol, c_}, opts : OptionsPattern[]] :=
 Catch[Module[{u = Unique["u"], l = Unique["ell"], lim, parsed, data, a, p, ur, lr},
  If[x === y || !FreeQ[expr, y],
   fail["VariableCollision", "Use distinct source and target symbols, and a target symbol absent from the input."]];
  lim = limits[OptionValue["MaxMultiIndices"], OptionValue["MaxTerms"],
   OptionValue["MaxTotalDegree"], OptionValue["MaxProducts"]];
  parsed = parseInput[expr, x, l, lim];
  a = parsed["LeadingCoefficient"]; p = parsed["LeadingExponent"];
  data = PowerLogReversion[a, p, parsed["Corrections"], {u, l}, c, opts];
  If[MatchQ[data, _Failure], Return[data]];
  ur = u -> (y/a)^(1/p);
  lr = l -> Log[y/a]/p;
  Join[data, <|"Expression" -> (data["UniformizerExpression"] /. {ur, lr}),
    "UniformizerRule" -> ur, "LogRule" -> lr, "TargetSymbol" -> y,
    "SourceSymbol" -> x, "InputExpression" -> expr,
    "InputCondition" -> parsed["InputCondition"], "TargetCondition" -> y > 0,
    "Remainder" -> (data["Remainder"] /. ur)|>]
 ], $failureTag];

PowerLogInverse[expr_, spec : {_Symbol, _Symbol, _}, opts : OptionsPattern[]] :=
 Module[{d = PowerLogInverseData[expr, spec, opts]},
  If[MatchQ[d, _Failure], d, d["Expression"]]
 ];

(* A separate, clipped sparse-ring implementation for residuals. *)
rAdd[a_, b_, l_, B_, lim_] := normalizeRows[Join[a, b], l, B, lim];
rScale[a_, k_, l_, B_, lim_] :=
 normalizeRows[({#[[1]], k #[[2]]} &) /@ a, l, B, lim];
rMul[a_, b_, l_, B_, lim_] := Module[{pairs},
 If[a === {} || b === {}, Return[{}]];
 If[Length[a] Length[b] > lim["MaxProducts"],
  fail["ProductLimit", "A sparse product exceeds MaxProducts."]];
 pairs = Flatten[Table[
   If[less[canon[s[[1]] + t[[1]]], B],
    {{canon[s[[1]] + t[[1]]], Expand[s[[2]] t[[2]]]}}, {}],
   {s, a}, {t, b}], 2];
 normalizeRows[pairs, l, B, lim]
];
rShift[a_, d_, l_, B_, lim_] :=
 normalizeRows[({canon[#[[1]] + d], #[[2]]} &) /@ a, l, B, lim];

rBinomial[r_, q_, l_, B_, lim_] := Module[{sum = {{0, 1}}, pw = {{0, 1}}, k, bound, b = 1},
 If[r === {}, Return[sum]];
 If[!less[0, r[[1, 1]]], fail["InvalidSeriesUnit", "The binomial correction must have positive valuation."]];
 bound = Ceiling[canon[B/r[[1, 1]]]] - 1;
 If[bound > lim["MaxTotalDegree"], fail["DegreeLimit", "Residual expansion exceeds MaxTotalDegree."]];
 Do[
  pw = rMul[pw, r, l, B, lim]; If[pw === {}, Break[]];
  b = canon[b (q - k + 1)/k];
  If[zeroQ[b], Break[]];
  sum = rAdd[sum, rScale[pw, b, l, B, lim], l, B, lim],
  {k, 1, bound}]; sum
];
rLog[r_, l_, B_, lim_] := Module[{sum = {}, pw = {{0, 1}}, k, bound},
 If[r === {}, Return[{}]];
 If[!less[0, r[[1, 1]]], fail["InvalidSeriesUnit", "The logarithmic correction must have positive valuation."]];
 bound = Ceiling[canon[B/r[[1, 1]]]] - 1;
 If[bound > lim["MaxTotalDegree"], fail["DegreeLimit", "Residual expansion exceeds MaxTotalDegree."]];
 Do[
  pw = rMul[pw, r, l, B, lim]; If[pw === {}, Break[]];
  sum = rAdd[sum, rScale[pw, (-1)^(k + 1)/k, l, B, lim], l, B, lim],
  {k, 1, bound}]; sum
];
rPolynomial[P_, arg_, l_, B_, lim_] := Module[{co = CoefficientList[P, l], out = {}, j},
 Do[out = rAdd[rMul[out, arg, l, B, lim], {{0, co[[j]]}}, l, B, lim],
  {j, Length[co], 1, -1}]; out
];

PowerLogResidual[data_Association, cutoff_: Automatic] := Catch[
 Module[{l, u, lim, B, C, p, corr, rows, r, logv, logx, out, unit,
  term, cert, tested, expr, targetExpr, rules},
  If[Lookup[data, "Kind", None] =!= "PowerLogInverseData/1",
   fail["InvalidData", "Expected data returned by PowerLogReversion or PowerLogInverseData."]];
  l = data["LogSymbol"]; u = data["UniformizerSymbol"]; lim = data["Limits"];
  C = data["RelativeCutoff"]; B = If[cutoff === Automatic, C, cutoff];
  If[!algebraicRealQ[B] || !less[0, B],
   fail["InvalidCutoff", "The residual cutoff is a positive exact algebraic relative power of u."]];
  p = data["LeadingExponent"]; corr = data["Corrections"];
  rows = data["Terms"];
  r = normalizeRows[Join[({canon[#[[1]] - 1], #[[2]]} &) /@ rows,
    {{0, -1}}], l, B, lim];
  If[r =!= {} && !less[0, r[[1, 1]]],
   fail["WrongApproximationBranch", "The stored approximation must equal u times (1+positive-valuation terms)."]];
  logv = rLog[r, l, B, lim];
  logx = rAdd[{{0, l}}, logv, l, B, lim];
  unit = {{0, 1}};
  Do[
   If[less[t[[1]], B],
    term = rMul[rBinomial[r, t[[1]], l, B, lim],
      rPolynomial[t[[2]], logx, l, B, lim], l, B, lim];
    unit = rAdd[unit, rShift[term, t[[1]], l, B, lim], l, B, lim]
   ], {t, corr}];
  out = rAdd[rMul[rBinomial[r, p, l, B, lim], unit, l, B, lim],
    {{0, -1}}, l, B, lim];
  tested = Select[out, less[#[[1]], C] &];
  cert = Which[tested =!= {}, False, less[B, C], Missing["InsufficientCutoff"], True, True];
  expr = Total[(u^#[[1]] #[[2]] &) /@ out];
  rules = Select[{data["UniformizerRule"], data["LogRule"]}, MatchQ[#, _Rule] &];
  targetExpr = expr /. rules;
  <|"Expression" -> targetExpr, "UniformizerExpression" -> expr,
    "Terms" -> out, "RelativeCutoff" -> B,
    "Certificate" -> cert, "CertificateRange" -> C,
    "Meaning" -> "Exact truncated expansion of f(A)/(a u^p)-1; Certificate tests vanishing below the inverse relative cutoff."|>
 ], $failureTag];

LogPowerBaseInverse[y_, a_, p_, q_] := Catch[Module[{w},
 If[!(And @@ (exactRealQ /@ {a, p, q})) ||
   !TrueQ[FullSimplify[a > 0 && p > 0]],
  fail["InvalidLeadingLogParameters", "a,p,q must be exact real constants and a,p must be positive."]];
 If[zeroQ[q], Return[(y/a)^(1/p)]];
 w = -(p/q) (y/a)^(1/q);
 If[TrueQ[FullSimplify[q > 0]],
  Exp[(q/p) ProductLog[-1, w]],
  If[TrueQ[FullSimplify[q < 0]], Exp[(q/p) ProductLog[0, w]],
   fail["UndecidableSign", "Could not select the real ProductLog branch."]]]
 ], $failureTag];

InversePerturbationJet[b_, h_, {z_Symbol, y_Symbol, n_Integer}] /; n >= 0 :=
 If[z === y,
  Failure["VariableCollision", <|"MessageTemplate" -> "Use distinct source and target symbols."|>],
  (b + Total[Table[(-1)^k/Factorial[k] D[D[b, z] h^k, {z, k - 1}],
    {k, 1, n}]]) /. z -> y
 ];

End[];
EndPackage[];
