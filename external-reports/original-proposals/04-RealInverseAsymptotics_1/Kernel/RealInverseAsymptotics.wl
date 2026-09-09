(* ::Package:: *)
(* RealInverseAsymptotics 1.0.0 -- MIT-0
   Positive-real, finite power-logarithmic germs at zero.
   No InverseFunction, SeriesData, PowerExpand, or floating-point exponent keys.
   The mathematical contract and proof are in article/real_inverse_asymptotics.pdf.
*)
BeginPackage["RealInverseAsymptotics`"];

RealInverseAsymptotic::usage =
 "RealInverseAsymptotic[f, {x, 0}, {y, cutoff}] returns an Association describing the positive inverse of a finite power-log expression f, retaining precisely the powers y^q with q < cutoff. The leading term of f must be a x^alpha with a > 0 and alpha > 0. Options: Assumptions, \"MaxOrder\", \"MaxTerms\".";
PowerLogCompose::usage =
 "PowerLogCompose[f, x, g, {y, cutoff}] expands f(g(y)) in exact powers of y with polynomial coefficients in Log[y], retaining powers strictly below cutoff. f and g must be finite power-log expressions, and g must have a positive constant leading coefficient and positive leading exponent. It returns an Association with \"Expression\", \"Terms\", and \"Cutoff\".";
CheckInverseAsymptotic::usage =
 "CheckInverseAsymptotic[result] independently composes the source expression with the inverse jet returned by RealInverseAsymptotic. It checks that the residual vanishes strictly below the predicted residual cutoff. This is a symbolic coefficient check, not a numerical interval certificate.";
PowerLogO::usage =
 "PowerLogO[y, rho, k] is an inert annotation meaning O[y^rho (1+Abs[Log[y]])^k] as y tends to zero from above. It is NOT a SeriesData object and has no arithmetic rules.";

Options[RealInverseAsymptotic] = {
 Assumptions :> $Assumptions, "MaxOrder" -> 256, "MaxTerms" -> 20000};
Options[PowerLogCompose] = Options[RealInverseAsymptotic];
Options[CheckInverseAsymptotic] = {
 "MaxOrder" -> 256, "MaxTerms" -> 20000};

Begin["`Private`"];

$riaTag = Unique["riaFailure"];
$riaAssumptions = True;
$riaMaxOrder = 256;
$riaMaxTerms = 20000;

fail[tag_String, data_: <||>] := Throw[
 Failure[tag, Join[<|"MessageTemplate" -> tag|>, data]], $riaTag];

canon[e_] := FullSimplify[e, $riaAssumptions];
poly[e_] := Expand[Simplify[Expand[e], $riaAssumptions]];

(* A trichotomy must be proved; no numerical fallback is allowed. *)
compare[a_, b_] := Module[{d = canon[a - b]},
 Which[
  TrueQ[d == 0], 0,
  TrueQ[d < 0] || TrueQ[FullSimplify[d < 0, $riaAssumptions]], -1,
  TrueQ[d > 0] || TrueQ[FullSimplify[d > 0, $riaAssumptions]], 1,
  True, fail["UndecidableExponentOrder", <|"Left" -> a, "Right" -> b|>]
 ]];
less[a_, b_] := compare[a, b] == -1;

realQ[e_] := TrueQ[FullSimplify[Element[e, Reals], $riaAssumptions]];
exactExponentQ[e_] := FreeQ[e, _Real] && NumericQ[e] && realQ[e];

validateOptions[] := (
 If[!IntegerQ[$riaMaxOrder] || $riaMaxOrder < 1,
  fail["InvalidMaxOrder", <|"Value" -> $riaMaxOrder|>]];
 If[!IntegerQ[$riaMaxTerms] || $riaMaxTerms < 1,
  fail["InvalidMaxTerms", <|"Value" -> $riaMaxTerms|>]];
 If[TrueQ[FullSimplify[$riaAssumptions] === False],
  fail["InconsistentAssumptions"]];
);
validateCutoff[c_] := If[!exactExponentQ[c] || !less[0, c],
 fail["CutoffMustBeAnExactPositiveRealNumber", <|"Cutoff" -> c|>]];

(* Lists of {exact exponent, polynomial in a private log coordinate}.
   Equality is mathematical equality, not SameQ on expressions. *)
merge[items_List] := Module[{out = {}, p, e, c, k, j},
 Do[
  e = canon[p[[1]]]; c = poly[p[[2]]];
  If[!TrueQ[c == 0],
   k = 0;
   Do[If[compare[e, out[[j, 1]]] == 0, k = j; Break[]],
    {j, Length[out]}];
   If[k == 0, AppendTo[out, {e, c}],
    out[[k, 2]] = poly[out[[k, 2]] + c]];
  ], {p, items}];
 out = Select[out, !TrueQ[#[[2]] == 0] &];
 If[Length[out] > $riaMaxTerms,
  fail["TermBudgetExceeded", <|"Terms" -> Length[out],
    "Limit" -> $riaMaxTerms|>]];
 Sort[out, less[#1[[1]], #2[[1]]] &]
];

trim[a_List, cutoff_] := Select[a, less[#[[1]], cutoff] &];
scale[a_List, c_] := ({#[[1]], poly[c #[[2]]]} & /@ a);
shift[a_List, e_, c_: 1] :=
 ({canon[#[[1]] + e], poly[c #[[2]]]} & /@ a);

multiply[a_List, b_List, cutoff_: Infinity] := Module[{items = {}, p, q, e},
 Do[
  e = canon[p[[1]] + q[[1]]];
  If[cutoff === Infinity || less[e, cutoff],
   AppendTo[items, {e, p[[2]] q[[2]]}];
   (* Bound temporary as well as final allocation. *)
   If[Length[items] > 4 $riaMaxTerms,
    fail["ProductBudgetExceeded", <|"Limit" -> 4 $riaMaxTerms|>]];
  ], {p, a}, {q, b}];
 merge[items]
];

(* The parser deliberately does not distribute noninteger powers or rewrite
   logarithms of products. Accepted syntax is a finite sum x^q P(Log[x]). *)
parse[expr_, x_Symbol, ell_Symbol] := Module[
 {expanded, terms, term, factors, fac, e, c, pairs = {}, cs},
 If[!FreeQ[expr, _Real], fail["InexactInput",
  <|"Explanation" -> "Use exact input; explicitly rationalize measured data outside this package."|>]];
 If[!FreeQ[expr, Indeterminate | _DirectedInfinity],
  fail["NonfiniteInput"]];
 expanded = Expand[expr /. Log[x] -> ell];
 terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
 Do[
  e = 0; c = 1;
  factors = If[Head[term] === Times, List @@ term, {term}];
  Do[
   Which[
    FreeQ[fac, x], c *= fac,
    SameQ[fac, x], e += 1,
    Head[fac] === Power && SameQ[fac[[1]], x] && FreeQ[fac[[2]], x],
     e += fac[[2]],
    True, fail["UnsupportedPowerLogSyntax", <|"Factor" -> fac|>]
   ], {fac, factors}];
  e = canon[e]; c = poly[c];
  If[!exactExponentQ[e], fail["ExponentMustBeExactNumericReal", <|"Exponent" -> e|>]];
  If[!PolynomialQ[c, ell], fail["LogCoefficientMustBePolynomial", <|"Coefficient" -> c|>]];
  cs = CoefficientList[c, ell];
  If[!TrueQ[And @@ (realQ /@ cs)], fail["CoefficientNotProvedReal", <|"Coefficient" -> c|>]];
  AppendTo[pairs, {e, c}], {term, terms}];
 merge[pairs]
];

positiveLead[pairs_List, ell_Symbol] := Module[{a, alpha},
 If[pairs === {}, fail["ZeroGerm"]];
 {alpha, a} = First[pairs];
 If[!less[0, alpha], fail["LeadingExponentMustBePositive", <|"Exponent" -> alpha|>]];
 If[!FreeQ[a, ell], fail["LogarithmicLeadingScaleUnsupported", <|"LeadingCoefficient" -> a|>]];
 If[!TrueQ[FullSimplify[a > 0, $riaAssumptions]],
  fail["LeadingCoefficientNotProvedPositive", <|"LeadingCoefficient" -> a|>]];
 {alpha, a}
];

orderNeeded[cap_, delta_] := Module[{n = FullSimplify[Ceiling[cap/delta], $riaAssumptions]},
 If[!IntegerQ[n] || n < 1,
  fail["UnresolvedIterationBound", <|"Bound" -> n|>]];
 If[n > $riaMaxOrder, fail["OrderBudgetExceeded", <|"Required" -> n,
  "Limit" -> $riaMaxOrder|>]];
 n
];

toExpression[pairs_List, y_Symbol, ell_Symbol] :=
 Total[(y^#[[1]] (#[[2]] /. ell -> Log[y])) & /@ pairs];
publicTerms[pairs_List, y_Symbol, ell_Symbol] :=
 ({#[[1]], #[[2]] /. ell -> Log[y]} & /@ pairs);

(* On a block t^mu Q(log t), Euler differentiation is mu + d/dell. *)
eulerBlock[q_, mu_, alpha_, n_Integer, ell_Symbol] := Module[{r = q, j},
 Do[r = poly[(mu + 1 + j alpha) r + D[r, ell]], {j, 1, n - 1}];
 poly[(-1)^n r/(Factorial[n] alpha^n)]
];

inverseCore[expr_, x_Symbol, y_Symbol, cutoff_] := Module[
 {ell = Unique["logCoordinate"], src, alpha, a, leading, u, delta,
  cap, nmax = 0, power, raw, kept, total, n, p, q, mu,
  frontier = Infinity, boundary = 0, converted, rho, k,
  boundaryY = 0, exact = False, expression, remainder, leadY},
 If[SameQ[x, y], fail["VariablesMustBeDistinct"]];
 If[!FreeQ[expr, y], fail["SourceContainsTargetVariable"]];
 validateCutoff[cutoff];
 src = parse[expr, x, ell];
 {alpha, a} = positiveLead[src, ell];
 leading = {canon[1/alpha], canon[a^(-1/alpha)]};
 leadY = y^leading[[1]] leading[[2]];
 cap = canon[alpha cutoff - 1];
 total = {};
 If[compare[cap, 0] <= 0,
  (* The requested strict cutoff excludes even the leading term. *)
  converted = {}; rho = leading[[1]]; k = 0; boundaryY = leadY,
  (* Otherwise all correction exponents are positive by construction. *)
  u = ({canon[#[[1]] - alpha], poly[#[[2]]/a]} & /@ Rest[src]);
  total = {{0, 1}};
  If[u === {},
   exact = True; converted = {leading}; rho = Infinity; k = 0,
   delta = First[u][[1]];
   nmax = orderNeeded[cap, delta];
   power = {{0, 1}};
   Do[
    raw = multiply[power, u]; kept = {};
    Do[
     mu = p[[1]];
     q = eulerBlock[p[[2]], mu, alpha, n, ell];
     If[less[mu, cap],
      AppendTo[kept, p];
      total = merge[Append[total, {mu, q}]],
      If[frontier === Infinity || less[mu, frontier],
       frontier = mu; boundary = q,
       If[compare[mu, frontier] == 0, boundary = poly[boundary + q]]]
     ], {p, raw}];
    power = kept;
    If[power === {}, Break[]], {n, 1, nmax}];
   If[frontier === Infinity, fail["InternalMissingFrontier"]];
   converted = merge[({canon[(1 + #[[1]])/alpha],
      poly[a^(-(1 + #[[1]])/alpha)
       (#[[2]] /. ell -> (ell - Log[a])/alpha)]} & /@ total)];
   rho = canon[(1 + frontier)/alpha];
   boundary = poly[a^(-rho) (boundary /. ell -> (ell - Log[a])/alpha)];
   k = If[TrueQ[boundary == 0], 0, Max[0, Exponent[boundary, ell]]];
   boundaryY = y^rho (boundary /. ell -> Log[y]);
  ];
 ];
 expression = toExpression[converted, y, ell];
 remainder = If[exact, 0, PowerLogO[y, rho, k]];
 <|"Expression" -> expression,
   "Terms" -> publicTerms[converted, y, ell],
   "Remainder" -> remainder,
   "RemainderPower" -> rho,
   "RemainderLogDegree" -> k,
   "RemainderScale" -> If[exact, 0, y^rho (1 + Abs[Log[y]])^k],
   "BoundaryTerm" -> boundaryY,
   "Exact" -> exact,
   "Cutoff" -> cutoff,
   "LeadingTerm" -> leadY,
   "LeadingExponent" -> leading[[1]],
   "SourceLeadingExponent" -> alpha,
   "SourceLeadingCoefficient" -> a,
   "SourceExpression" -> expr,
   "SourceVariable" -> x,
   "ExpansionVariable" -> y,
   "Direction" -> "FromAbove",
   "BranchCondition" -> "The positive branch with x/(y/a)^(1/alpha) tending to 1.",
   "Assumptions" -> $riaAssumptions,
   "PerturbationOrdersBound" -> nmax,
   "Method" -> "Euler-Lagrange with exact support and a first-omitted frontier"|>
];

RealInverseAsymptotic[expr_, {x_Symbol, 0}, {y_Symbol, cutoff_}, OptionsPattern[]] :=
 Catch[Block[{$riaAssumptions = OptionValue[Assumptions],
   $riaMaxOrder = OptionValue["MaxOrder"], $riaMaxTerms = OptionValue["MaxTerms"]},
   validateOptions[]; inverseCore[expr, x, y, cutoff]], $riaTag];

(* Independent composition machinery; it does not call eulerBlock. *)
unitFunction[v_List, cap_, which_, q_: 0] := Module[
 {acc, power = {{0, 1}}, n, nmax, c},
 If[!less[0, cap], Return[{}]];
 acc = If[which === "Power", {{0, 1}}, {}];
 If[v === {}, Return[acc]];
 nmax = orderNeeded[cap, First[v][[1]]];
 Do[
  power = multiply[power, v, cap];
  If[power === {}, Break[]];
  c = If[which === "Power", Binomial[q, n], (-1)^(n + 1)/n];
  acc = merge[Join[acc, scale[power, c]]], {n, 1, nmax - 1}];
 acc
];

composeCore[expr_, x_Symbol, inner_, y_Symbol, cutoff_, ell_Symbol] := Module[
 {src, inn, beta, c, v, out = {}, p, q, polynomial, cap, b,
  unit, logarithm, lp, logPolynomial, k, coeff, pieces},
 If[SameQ[x, y], fail["VariablesMustBeDistinct"]];
 If[!FreeQ[expr, y] || !FreeQ[inner, x], fail["VariableCollision"]];
 validateCutoff[cutoff];
 src = parse[expr, x, ell]; inn = parse[inner, y, ell];
 {beta, c} = positiveLead[inn, ell];
 v = ({canon[#[[1]] - beta], poly[#[[2]]/c]} & /@ Rest[inn]);
 b = Log[c] + beta ell;
 Do[
  {q, polynomial} = p; cap = canon[cutoff - beta q];
  If[less[0, cap],
   unit = unitFunction[v, cap, "Power", q];
   logarithm = unitFunction[v, cap, "Log"];
   lp = {{0, 1}}; logPolynomial = {};
   Do[
    coeff = poly[(D[polynomial, {ell, k}] /. ell -> b)/Factorial[k]];
    logPolynomial = merge[Join[logPolynomial, scale[lp, coeff]]];
    lp = multiply[lp, logarithm, cap],
    {k, 0, Max[0, Exponent[polynomial, ell]]}];
   pieces = multiply[unit, logPolynomial, cap];
   out = merge[Join[out, shift[pieces, beta q, c^q]]]
  ], {p, src}];
 trim[out, cutoff]
];

PowerLogCompose[expr_, x_Symbol, inner_, {y_Symbol, cutoff_}, OptionsPattern[]] :=
 Catch[Block[{$riaAssumptions = OptionValue[Assumptions],
   $riaMaxOrder = OptionValue["MaxOrder"], $riaMaxTerms = OptionValue["MaxTerms"]},
  Module[{ell = Unique["logCoordinate"], pairs},
   validateOptions[];
   pairs = composeCore[expr, x, inner, y, cutoff, ell];
   <|"Expression" -> toExpression[pairs, y, ell],
     "Terms" -> publicTerms[pairs, y, ell], "Cutoff" -> cutoff|>
  ]], $riaTag];

CheckInverseAsymptotic[result_Association, OptionsPattern[]] :=
 Catch[Block[{$riaAssumptions = Lookup[result, "Assumptions", True],
   $riaMaxOrder = OptionValue["MaxOrder"], $riaMaxTerms = OptionValue["MaxTerms"]},
  Module[{ell = Unique["logCoordinate"], x, y, cutoff, pairs, residual, keys},
   validateOptions[];
   keys = {"SourceVariable", "ExpansionVariable", "SourceExpression",
     "Expression", "LeadingExponent", "RemainderPower", "Exact"};
   If[!TrueQ[And @@ (KeyExistsQ[result, #] & /@ keys)], fail["MalformedResult"]];
   x = result["SourceVariable"]; y = result["ExpansionVariable"];
   If[TrueQ[result["Expression"] == 0], fail["LeadingTermNotRetained"]];
   cutoff = If[TrueQ[result["Exact"]], 2,
     canon[result["RemainderPower"] + 1 - result["LeadingExponent"]]];
   pairs = composeCore[result["SourceExpression"], x,
     result["Expression"], y, cutoff, ell];
   residual = merge[Join[pairs, trim[{{1, -1}}, cutoff]]];
   <|"Passed" -> (residual === {}),
     "ResidualBelowBound" -> toExpression[residual, y, ell],
     "ResidualCutoff" -> cutoff,
     "Check" -> "Independent truncated binomial/logarithm composition"|>
  ]], $riaTag];

End[];
EndPackage[];
