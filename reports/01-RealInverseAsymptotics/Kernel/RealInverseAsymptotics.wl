(* ::Package:: *)
(* RealInverseAsymptotics 1.0.0, 7 September 2026.
   MIT license. See LICENSE and the accompanying article.
   No external resources, numerical exponent ordering, or PowerExpand are used. *)

BeginPackage["RealInverseAsymptotics`"];

RealInverseAsymptotic::usage =
 "RealInverseAsymptotic[f,{x,0},{y,q}] inverts a finite real power-log expression on the positive branch tending to zero. It retains every complete logarithmic block with y-exponent strictly less than q. Exponents must be exact real algebraic constants; the leading term must be a x^p with a>0 and p>0. Normal[result] returns the finite expression.";
InverseExpansion::usage =
 "InverseExpansion[data] stores a finite inverse expansion and its hypotheses. Use Normal[result] or result[\"Expression\"], result[\"Remainder\"], result[\"Terms\"], result[\"Branch\"].";
PowerLogRemainder::usage =
 "PowerLogRemainder[y,b,k] denotes O[y^b (1+Abs[Log[y]])^k] as y tends to zero from above. It is an inert descriptor, NOT a SeriesData object and not an expression with automatic order arithmetic.";
InputRemainder::usage =
 "InputRemainder is an option for RealInverseAsymptotic. None means the input expression is exact. {rho,k} means an additional forward remainder R(x)=O[x^rho (1+Abs[Log[x]])^k], with the differentiated bound R'(x)=O[x^(rho-1) (1+Abs[Log[x]])^k]. These are caller-supplied mathematical hypotheses, not automatically verified facts.";
MaxMultiIndices::usage =
 "MaxMultiIndices limits enumeration, boundary candidates, and sparse jet products. Reaching the limit returns Failure, never a partially computed expansion.";
InverseResidual::usage =
 "InverseResidual[result] independently composes the finite inverse with the stored finite forward model, using sparse binomial and logarithmic arithmetic. It returns the normalized residual below the relative cutoff. InverseResidual[result,h] uses relative cutoff h in the leading-root coordinate. This is a formal residual test, not a numerical error certificate.";
PerturbativeInverse::usage =
 "PerturbativeInverse[h,{x},{y,n},epsilon] gives the degree-n polynomial in epsilon for the solution of u+epsilon h(u)=y with u=y at epsilon=0. No claim that epsilon=1 is an asymptotic expansion in y is made.";

Options[RealInverseAsymptotic] = {Assumptions -> True,
 InputRemainder -> None, MaxMultiIndices -> 20000};
Options[InverseResidual] = {MaxMultiIndices -> 20000};

Begin["`Private`"];

$failureTag = Unique["RealInverseFailure$"];
fail[tag_String, text_String, extra_: <||>] :=
 Throw[Failure[tag, Join[<|"MessageTemplate" -> text|>, extra]], $failureTag];

(* Exact algebraic exponents are canonicalized before gathering. *)
canon[a_] := RootReduce[a];
algRealQ[a_] := FreeQ[a, _Real] && NumericQ[a] &&
 TrueQ[FullSimplify[Element[a, Algebraics] && Element[a, Reals]]];
less[a_, b_] := Module[{d = canon[a-b], t},
 t = FullSimplify[d < 0];
 Which[TrueQ[t], True, TrueQ[Not[t]], False,
  True, fail["UndecidableOrder", "An exponent comparison could not be proved.",
   <|"Comparison" -> HoldForm[a < b]|>]]];
leq[a_, b_] := Not[less[b, a]];
zeroQ[a_, assumptions_] := TrueQ[Simplify[a == 0, assumptions]];
simp[a_, assumptions_] := Expand[Simplify[Expand[a], assumptions]];
prettyExponent[a_] := ToRadicals[a];

(* A jet is a list {{exponent, polynomial in ell}, ...}.
   A missing coefficient is zero. No finite-precision comparison is allowed. *)
merge[terms_List, assumptions_] := Module[{g, out},
 If[terms === {}, Return[{}]];
 g = GatherBy[({canon[#[[1]]], #[[2]]} & /@ terms), First];
 out = ({#[[1,1]], simp[Total[#[[All,2]]], assumptions]} & /@ g);
 out = Select[out, Not[zeroQ[#[[2]], assumptions]] &];
 Sort[out, less[#1[[1]], #2[[1]]] &]
];
trim[terms_List, h_, assumptions_] :=
 merge[Select[terms, less[#[[1]], h] &], assumptions];

parseModel[f_, x_Symbol, ell_Symbol, assumptions_] := Module[
 {e, summands, terms = {}, factors, a, c, exponent, blocks, p,
  lead, polys, deltas, coeffs},
 If[!FreeQ[f, _Real], fail["InexactInput",
  "Use exact coefficients and exponents; machine and arbitrary-precision Real input is rejected."]];
 e = Expand[f /. Log[x] -> ell];
 summands = If[Head[e] === Plus, List @@ e, {e}];
 Do[
  factors = If[Head[term] === Times, List @@ term, {term}];
  a = 0; c = 1;
  Do[
   Which[
    FreeQ[factor, x], c = c factor,
    SameQ[factor, x], a = a + 1,
    MatchQ[factor, Power[x, _]] && FreeQ[factor[[2]], x | ell],
      exponent = factor[[2]];
      If[!algRealQ[exponent], fail["UnsupportedExponent",
       "Powers of x must have exact real algebraic constant exponents."]];
      a = a + exponent,
    True, fail["UnsupportedInput",
      "Expected a finite sum of x^alpha times polynomials in Log[x]. Expand analytic factors first and supply InputRemainder when appropriate.",
      <|"UnsupportedFactor" -> factor|>]
   ], {factor, factors}];
  If[!algRealQ[a] || !PolynomialQ[c, ell], fail["UnsupportedInput",
   "Each block must have an exact real algebraic exponent and a polynomial logarithmic coefficient."]];
  coeffs = CoefficientList[c, ell];
  If[!(And @@ (TrueQ[FullSimplify[Element[#, Reals], assumptions]] & /@ coeffs)),
   fail["UnprovedReality", "Reality of all coefficients must follow from Assumptions."]];
  AppendTo[terms, {canon[a], c}], {term, summands}];
 blocks = merge[terms, assumptions];
 If[blocks === {}, fail["ZeroModel", "The zero function has no selected inverse."]];
 p = blocks[[1,1]]; lead = blocks[[1,2]];
 If[!less[0, p], fail["InvalidLeadingPower", "The leading power p must be strictly positive."]];
 If[!FreeQ[lead, ell], fail["LogarithmicLeadingTerm",
  "The leading block must be a positive constant times x^p. A leading logarithmic factor requires a different dominant coordinate."]];
 If[!TrueQ[FullSimplify[lead > 0, assumptions]], fail["UnprovedPositiveLeadingCoefficient",
  "Positivity of the leading coefficient must follow from Assumptions."]];
 polys = (simp[#[[2]]/lead, assumptions] & /@ Rest[blocks]);
 deltas = (canon[#[[1]] - p] & /@ Rest[blocks]);
 <|"LeadingPower" -> p, "LeadingCoefficient" -> lead,
   "Deltas" -> deltas, "Polynomials" -> polys,
   "Blocks" -> blocks, "LogVariable" -> ell|>
];

(* Downward-closed, finite index set and one-step boundary.
   The boundary may contain nonminimal generators; the error bound remains valid. *)
indexRegion[d_List, h_, cap_Integer] := Module[
 {m = Length[d], count = 0, nodes = 0, visit, bags, inside, candidates, frontier, s},
 If[m == 0, Return[<|"Inside" -> {{}}, "Frontier" -> {}|>]];
 visit[j_, remaining_, prefix_] := Module[{k = 0},
  nodes++;
  If[nodes > cap, fail["ResourceLimit", "Multi-index traversal exceeded MaxMultiIndices."]];
  If[j > m,
   count++; Sow[prefix]; Return[Null]];
  While[less[canon[k d[[j]]], remaining],
   visit[j+1, canon[remaining-k d[[j]]], Append[prefix, k]];
   k++;
   If[k > cap, fail["ResourceLimit", "An exponent gap is too small for this cutoff and resource limit."]]
  ]
 ];
 bags = Reap[visit[1,h,{}]][[2]];
 inside = If[bags === {}, {}, First[bags]];
 If[m Length[inside] > cap, fail["ResourceLimit",
  "Boundary construction exceeded MaxMultiIndices; raise the option or lower the cutoff."]];
 candidates = Flatten[Table[v + UnitVector[m,j], {v,inside}, {j,m}], 1];
 candidates = DeleteDuplicates[candidates];
 frontier = Select[candidates, Not[less[canon[# . d], h]] &];
 <|"Inside" -> inside, "Frontier" -> frontier|>
];

(* All-order coefficient operator in z=(y/a)^(1/p), ell=Log[z]. *)
coefficient[n_List, d_List, b_List, p_, ell_, assumptions_] := Module[
 {total = Total[n], s = canon[n . d], q, j},
 If[total == 0, Return[{0,1}]];
 q = Expand[Times @@ MapThread[Power, {b,n}]];
 Do[q = Expand[D[q,ell] + (1+s+p j) q], {j,1,total-1}];
 {s, simp[(-1)^total q/(p^total (Times @@ (Factorial /@ n))), assumptions]}
];

combineRemainders[{r1_,k1_},{r2_,k2_}] := Which[
 r1 === Infinity, {r2,k2}, r2 === Infinity, {r1,k1},
 less[r1,r2], {r1,k1}, less[r2,r1], {r2,k2},
 True, {r1,Max[k1,k2]}];

RealInverseAsymptotic[f_, {x_Symbol,0}, {y_Symbol,cutoff_}, OptionsPattern[]] :=
 Catch[Module[{ass = OptionValue[Assumptions], input = OptionValue[InputRemainder],
  cap = OptionValue[MaxMultiIndices], ell = Unique["ell$"], model, p, a, d, b,
  h, region, indices, terms, degree, s0, near, k0, modelRem, inputRem,
  rem, expression, termTable, rho, k, qinput, source},
  If[SameQ[x,y] || !FreeQ[f,y], fail["Variables", "Use distinct, unassigned source and target symbols; the forward expression must not contain the target symbol."]];
  If[!IntegerQ[cap] || cap < 1, fail["InvalidOption", "MaxMultiIndices must be a positive integer."]];
  If[!algRealQ[cutoff], fail["InvalidCutoff", "The cutoff must be an exact real algebraic constant."]];
  If[!FreeQ[ass,x | y], fail["VariableDependentAssumptions", "Assumptions must concern fixed parameters, not source or target variables; positivity of x and y is built into the selected branch."]];
  model = parseModel[f,x,ell,ass];
  p = model["LeadingPower"]; a = model["LeadingCoefficient"];
  d = model["Deltas"]; b = model["Polynomials"];
  h = canon[p cutoff - 1];
  If[!less[0,h], fail["CutoffTooSmall", "The exclusive cutoff must be larger than the leading inverse exponent 1/p."]];
  inputRem = {Infinity,0};
  If[input =!= None,
   If[!MatchQ[input,{_,_Integer}], fail["InvalidInputRemainder", "InputRemainder must be None or {rho,k}, where k is a nonnegative integer."]];
   {rho,k} = input;
   If[!algRealQ[rho] || k < 0 || !less[model["Blocks"][[-1,1]],rho],
    fail["InvalidInputRemainder", "rho must be an exact real algebraic number larger than every supplied forward power, and k must be nonnegative."]];
   qinput = canon[(rho-p+1)/p];
   If[less[qinput,cutoff], fail["InsufficientInputOrder",
    "The requested cutoff exceeds the inverse precision implied by InputRemainder.",
    <|"MaximumCutoff" -> prettyExponent[qinput]|>]];
   inputRem = {qinput,k}
  ];
  region = indexRegion[d,h,cap]; indices = region["Inside"];
  terms = merge[(coefficient[#,d,b,p,ell,ass] & /@ indices), ass];
  modelRem = {Infinity,0};
  If[d =!= {},
   degree = Exponent[#,ell] & /@ b;
   s0 = First[Sort[canon[# . d] & /@ region["Frontier"], less]];
   near = Select[region["Frontier"], canon[# . d - s0] === 0 &];
   k0 = Max[(# . degree) & /@ near];
   modelRem = {canon[(1+s0)/p], k0}
  ];
  rem = combineRemainders[modelRem,inputRem];
  termTable = ({prettyExponent[canon[(1+#[[1]])/p]],
     #[[2]] /. ell -> Log[y/a]/p} & /@ terms);
  expression = Total[((y/a)^#[[1]] #[[2]]) & /@ termTable];
  source = If[input === None,"Exact finite model","Forward jet with caller-supplied differentiated remainder"];
  InverseExpansion[<|
   "Expression" -> expression,
   "Remainder" -> If[rem[[1]] === Infinity,0,
     PowerLogRemainder[y,prettyExponent[rem[[1]]],rem[[2]]]],
   "RemainderPower" -> prettyExponent[rem[[1]]],
   "RemainderLogDegree" -> rem[[2]],
   "Terms" -> termTable,
   "TermConvention" -> "Each {beta,C} means (y/a)^beta C; logarithms use Log[y/a]/p.",
   "Branch" -> "x>0, y->0+, x/(y/a)^(1/p)->1",
   "Assumptions" -> ass, "InputInterpretation" -> source,
   "InputRemainder" -> input, "Cutoff" -> cutoff,
   "RelativeCutoff" -> h, "SourceVariable" -> x,
   "TargetVariable" -> y, "ForwardExpression" -> f,
   "LeadingPower" -> p, "LeadingCoefficient" -> a,
   "ScaledTerms" -> terms, "Model" -> model,
   "MultiIndexCount" -> Length[indices],
   "BoundaryCount" -> Length[region["Frontier"]],
   "Guarantee" -> "Asymptotic theorem under stated fixed-parameter hypotheses; not a computed interval or a uniform parameter bound."
  |>]
 ],$failureTag];
RealInverseAsymptotic[___] := Failure["Arguments",<|"MessageTemplate" ->
 "Use RealInverseAsymptotic[f,{x,0},{y,q},options] with distinct unassigned symbols."|>];

InverseExpansion /: Normal[InverseExpansion[a_Association]] := a["Expression"];
InverseExpansion[a_Association][key_String] := a[key];

jetMul[u_List,v_List,h_,ass_,cap_] := Module[{raw},
 If[u === {} || v === {}, Return[{}]];
 If[Length[u] Length[v] > cap, fail["ResourceLimit", "Sparse jet multiplication exceeded MaxMultiIndices."]];
 raw = Flatten[Table[{canon[a[[1]]+b[[1]]],Expand[a[[2]] b[[2]]]},
   {a,u},{b,v}],1];
 trim[raw,h,ass]
];
jetScale[u_List,c_,ass_] := merge[({#[[1]],c #[[2]]}& /@ u),ass];
jetPower[u_List,n_Integer,h_,ass_,cap_] := Module[{r={{0,1}},j},
 Do[r=jetMul[r,u,h,ass,cap],{j,n}]; r];
unitSeries[u_List,r_,h_,ass_,cap_,kind_] := Module[
 {ans={{0,1}},power={{0,1}},j=0,coef},
 If[kind === "Log", ans = {}];
 If[u === {},Return[ans]];
 If[!less[0,u[[1,1]]], fail["NonSmallJet", "Unit-series arithmetic requires strictly positive valuation."]];
 While[True,
  j++; If[j>cap,fail["ResourceLimit", "Unit-series iteration exceeded MaxMultiIndices."]];
  power=jetMul[power,u,h,ass,cap]; If[power === {},Break[]];
  coef=If[kind === "Log",(-1)^(j+1)/j,Binomial[r,j]];
  ans=merge[Join[ans,jetScale[power,coef,ass]],ass]
 ]; ans
];

residualInternal[InverseExpansion[data_Association],requested_,cap_] := Module[
 {model=data["Model"],h,ass=data["Assumptions"],p,a,ell,u,logu,
  d,b,ans,pow,pol,part,i,k,raw,y,expr},
 If[!IntegerQ[cap] || cap<1,fail["InvalidOption", "MaxMultiIndices must be a positive integer."]];
 h=If[requested === Automatic,data["RelativeCutoff"],requested];
 If[!algRealQ[h] || !less[0,h],fail["InvalidCutoff", "The residual cutoff must be positive and exact real algebraic."]];
 p=model["LeadingPower"]; a=model["LeadingCoefficient"]; ell=model["LogVariable"];
 d=model["Deltas"]; b=model["Polynomials"]; y=data["TargetVariable"];
 u=trim[Select[data["ScaledTerms"],less[0,#[[1]]]&],h,ass];
 logu=unitSeries[u,0,h,ass,cap,"Log"];
 ans=merge[Join[unitSeries[u,p,h,ass,cap,"Power"],{{0,-1}}],ass];
 Do[
  If[less[d[[i]],h],
   pol={};
   Do[part=jetScale[jetPower[logu,k,h,ass,cap],D[b[[i]],{ell,k}]/k!,ass];
      pol=merge[Join[pol,part],ass],{k,0,Exponent[b[[i]],ell]}];
   pow=unitSeries[u,p+d[[i]],h,ass,cap,"Power"];
   part=jetMul[pow,pol,h,ass,cap];
   part=({canon[#[[1]]+d[[i]]],#[[2]]}& /@ part);
   ans=trim[Join[ans,part],h,ass]
  ],{i,Length[d]}];
 expr=Total[(((y/a)^prettyExponent[#[[1]]/p])
    (#[[2]] /. ell->Log[y/a]/p)) & /@ ans];
 <|"ZeroBelowCutoff" -> (ans === {}),"NormalizedResidual" -> expr,
   "ScaledResidualTerms" -> ans,"RelativeCutoff" -> prettyExponent[h],
   "Normalization" -> "f(g_truncated(y))/y - 1",
   "ActualResidualCutoff" -> prettyExponent[canon[1+h/p]],
   "Scope" -> "Formal composition of the finite model only; no assertion about an unspecified input remainder."|>
];
InverseResidual[r_InverseExpansion,OptionsPattern[]] :=
 Catch[residualInternal[r,Automatic,OptionValue[MaxMultiIndices]],$failureTag];
InverseResidual[r_InverseExpansion,h_?algRealQ,OptionsPattern[]] :=
 Catch[residualInternal[r,h,OptionValue[MaxMultiIndices]],$failureTag];
InverseResidual[___] := Failure["Arguments",<|"MessageTemplate" ->
 "Use InverseResidual[result] or InverseResidual[result,positiveRelativeCutoff]."|>];

PerturbativeInverse[h_,{x_Symbol},{y_Symbol,n_Integer},epsilon_Symbol] /; n>=0 :=
 Module[{hy = h /. x->y},
 If[SameQ[x,y] || SameQ[epsilon,y] || SameQ[epsilon,x] || !FreeQ[h,epsilon | y],
  Return[Failure["Variables",<|"MessageTemplate" -> "Use distinct unassigned source, target, and marker symbols."|>]]];
 y+Total[Table[(-epsilon)^j D[hy^j,{y,j-1}]/j!,{j,1,n}]]
];
PerturbativeInverse[___] := Failure["Arguments",<|"MessageTemplate" ->
 "Use PerturbativeInverse[h,{x},{y,n},epsilon], n a nonnegative integer."|>];

End[];
EndPackage[];
