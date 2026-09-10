(* ::Package:: *)
(* RealInverseSeries 1.0.0
   Positive-real power-log inversion at zero.
   Copyright (c) 2026. Distributed under the MIT license.

   This implementation does not use InverseFunction, PowerExpand, or a
   floating-point fallback to order exponents. Its result is an Association,
   not SeriesData: logarithmic error factors must not be hidden inside O[y]^q.
   See the article and Tests/ for the precise contract and validation status.
*)

BeginPackage["RealInverseSeries`"];

RealInverseSeries::usage =
 "RealInverseSeries[f,{x,y},q] constructs the positive-real inverse of f(x) near zero, retaining complete power-log blocks with y exponent strictly less than q. The result is an Association with keys Expansion, Remainder, Blocks, and FormalResidualZero. Supported inputs are finite sums x^a P(Log[x]) with a positive monomial leading block c x^p, c>0 and p>0. Exponents and the cutoff must be exact real numeric constants. Use Assumptions for symbolic real coefficients.";

InverseResidual::usage =
 "InverseResidual[result,r] expands f(result[\"Expansion\"])-y through all y powers strictly below r. InverseResidual[result] uses the residual cutoff corresponding to the requested inverse cutoff. The returned Association records a formal truncated residual, not a numerical interval certificate. A declared input remainder is not included in this residual.";

PerturbativeInverse::usage =
 "PerturbativeInverse[phi,h,{x,y,eps},n] returns the degree-n Taylor polynomial in eps of the branch solving F(x)+eps h(x)=y, where phi is a specified local inverse of F expressed in y. It uses phi+Sum[(-eps)^k D[(h/.x->phi)^k D[phi,y],{y,k-1}]/k!,{k,1,n}]. Setting eps=1 requires a separate convergence or remainder argument unless the power-log theorem applies.";

$RealInverseSeriesVersion::usage = "Version string for RealInverseSeries.";
$RealInverseSeriesVersion = "1.0.0";

Options[RealInverseSeries] = {
 Assumptions -> True, Method -> "Lagrange",
 "InputRemainder" -> None, "MaxIndices" -> 10000,
 "VerifyResidual" -> True
};

Begin["`Private`"];

$failureTag = Unique["RealInverseSeriesFailure$"];
$assumptions = True;
$maxIndices = 10000;

fail[tag_, text_, data_: <||>] :=
 Throw[Failure[tag, Join[<|"MessageTemplate" -> text|>, data]], $failureTag];

zeroQ[z_] := TrueQ[z === 0] ||
 TrueQ[FullSimplify[z == 0, Assumptions -> $assumptions]];

realQ[z_] := TrueQ[FullSimplify[Element[z, Reals],
 Assumptions -> $assumptions]];

exactRealQ[z_] := FreeQ[z, _Real] && NumericQ[z] && realQ[z] &&
 FreeQ[z, Indeterminate | ComplexInfinity | _DirectedInfinity];

ce[z_] := FullSimplify[z, Assumptions -> $assumptions];
cp[z_] := Expand[FullSimplify[Expand[z], Assumptions -> $assumptions]];

(* No approximate comparison is permitted, including in Sort. *)
cmp[a_, b_] := Module[{d = ce[a - b]},
 If[TrueQ[d == 0], Return[0]];
 If[TrueQ[d < 0], Return[-1]];
 If[TrueQ[d > 0], Return[1]];
 If[TrueQ[FullSimplify[d < 0, Assumptions -> $assumptions]], Return[-1]];
 If[TrueQ[FullSimplify[d > 0, Assumptions -> $assumptions]], Return[1]];
 fail["UndecidableOrder", "An exponent comparison could not be certified exactly.",
  <|"Left" -> a, "Right" -> b|>]
];

(* Sparse jets: sorted lists {weight, polynomial in a private log symbol}.
   Canonicalization adds colliding weights before discarding zero blocks. *)
spCanonical[terms_List, cut_] := Module[{s, groups, out},
 s = Select[terms, cmp[#[[1]], cut] < 0 &];
 If[s === {}, Return[{}]];
 s = Sort[s, cmp[#1[[1]], #2[[1]]] < 0 &];
 groups = Split[s, cmp[#1[[1]], #2[[1]]] == 0 &];
 out = ({ce[#[[1, 1]]], cp[Total[#[[All, 2]]]]} &) /@ groups;
 Select[out, !zeroQ[#[[2]]] &]
];

spAdd[a_List, b_List, cut_] := spCanonical[Join[a, b], cut];
spScale[a_List, c_] := ({#[[1]], Expand[c #[[2]]]} &) /@ a;

spMul[a_List, b_List, cut_] := Module[{out = {}, w, i, j},
 Do[
  w = ce[a[[i, 1]] + b[[j, 1]]];
  If[cmp[w, cut] < 0,
   AppendTo[out, {w, Expand[a[[i, 2]] b[[j, 2]]]}]],
  {i, Length[a]}, {j, Length[b]}];
 spCanonical[out, cut]
];

spReciprocal[a_List, cut_, ell_] := Module[{c, rest, term, out},
 If[a === {} || cmp[a[[1, 1]], 0] != 0,
  fail["NonunitJet", "The jet to be inverted has no nonzero constant block."]];
 c = a[[1, 2]];
 If[zeroQ[c] || !FreeQ[c, ell],
  fail["NonunitJet", "The leading jet coefficient must be a nonzero scalar."]];
 rest = spScale[Rest[a], -1/c];
 term = {{0, 1}}; out = {{0, 1/c}};
 While[term =!= {} && rest =!= {},
  term = spMul[term, rest, cut];
  out = spAdd[out, spScale[term, 1/c], cut]];
 out
];

(* terms = {{externalWeight, exponentOf(1+u), P(ell)}, ...}.
   Q[k+1] = ((a-k) Q[k] + D Q[k])/(k+1) is the Taylor
   coefficient of (1+u)^a P(ell+Log[1+u]). *)
spCompose[terms_List, u_List, cut_, ell_] :=
 Module[{out = {}, d, a, q, power, piece, k, i},
 Do[
  d = terms[[i, 1]]; a = terms[[i, 2]]; q = terms[[i, 3]];
  If[cmp[d, cut] < 0,
   power = {{0, 1}}; k = 0;
   While[power =!= {},
    piece = ({ce[d + #[[1]]], Expand[q #[[2]]]} &) /@ power;
    out = spAdd[out, piece, cut];
    q = Expand[((a - k) q + D[q, ell])/(k + 1)];
    power = spMul[power, u, ce[cut - d]];
    k++
   ]
  ], {i, Length[terms]}];
 spCanonical[out, cut]
];

parseModel[f_, x_, ell_] := Module[
 {expanded, terms, parsed = {}, facs, a, q, fac, i, j, blocks, p, c, deltas, polys},
 If[!FreeQ[f, _Real],
  fail["InexactInput", "Use exact coefficients and exponents; machine-real input is not accepted."]];
 expanded = Expand[f /. Log[x] -> ell];
 terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
 Do[
  facs = If[Head[terms[[i]]] === Times, List @@ terms[[i]], {terms[[i]]}];
  a = 0; q = 1;
  Do[
   fac = facs[[j]];
   Which[
    fac === x, a += 1,
    Head[fac] === Power && fac[[1]] === x && FreeQ[fac[[2]], x],
      a += fac[[2]],
    FreeQ[fac, x], q *= fac,
    True, fail["UnsupportedInput",
      "Input must be a finite sum x^a P(Log[x]); normalize other functions first.",
      <|"UnsupportedFactor" -> fac|>]
   ], {j, Length[facs]}];
  a = ce[a]; q = Expand[q];
  If[!exactRealQ[a],
   fail["Exponent", "Every exponent must be an exact real numeric constant.",
    <|"Exponent" -> a|>]];
  If[!PolynomialQ[q, ell],
   fail["LogPolynomial", "Only nonnegative integer powers of Log[x] are supported."]];
  If[!(And @@ (realQ /@ CoefficientList[q, ell])),
   fail["CoefficientReality", "Coefficient reality was not proved. Supply suitable Assumptions.",
    <|"CoefficientPolynomial" -> q|>]];
  AppendTo[parsed, {a, q}], {i, Length[terms]}];
 blocks = spCanonical[parsed, Infinity];
 If[blocks === {}, fail["ZeroFunction", "The zero function has no inverse germ."]];
 p = blocks[[1, 1]]; c = blocks[[1, 2]];
 If[cmp[p, 0] <= 0,
  fail["CoreExponent", "The leading exponent p must be positive for the zero-to-zero branch."]];
 If[!FreeQ[c, ell],
  fail["LogarithmicCore", "The leading block must be c x^p, not a logarithmic core."]];
 If[!TrueQ[FullSimplify[c > 0, Assumptions -> $assumptions]],
  fail["CoreCoefficient", "The leading coefficient c must be provably positive."]];
 deltas = (ce[#[[1]] - p] &) /@ Rest[blocks];
 polys = (cp[#[[2]]/c] &) /@ Rest[blocks];
 {p, c, deltas, polys}
];

(* Enumerate the finite down-set n.delta < A, without rounding a bound.
   Resource failure is explicit rather than a silently incomplete expansion. *)
indicesBelow[deltas_List, A_] := Module[{visit, out = {}, r = Length[deltas]},
 visit[j_, prefix_, w_] := Module[{k = 0, ww},
  If[j > r,
   AppendTo[out, {prefix, w}];
   If[Length[out] > $maxIndices,
    fail["IndexLimit", "The requested cutoff exceeds MaxIndices; no partial series is returned."]];
   Return[Null]];
  ww = w;
  While[cmp[ww, A] < 0,
   visit[j + 1, Append[prefix, k], ww];
   k++; ww = ce[w + k deltas[[j]]]
  ]
 ];
 visit[1, {}, 0]; out
];

borderOf[indices_List, deltas_List, A_] := Module[{out = {}, nn, w, i, j},
 Do[
  w = ce[indices[[i, 2]] + deltas[[j]]];
  If[cmp[w, A] >= 0,
   nn = indices[[i, 1]]; nn[[j]] += 1;
   AppendTo[out, {nn, w}]],
  {i, Length[indices]}, {j, Length[deltas]}];
 DeleteDuplicates[out]
];

inverseCoefficient[ns_List, d_, p_, polys_List, ell_] :=
 Module[{n = Total[ns], q, k},
  If[n == 0, Return[1]];
  q = Times @@ MapThread[Power, {polys, ns}];
  Do[q = Expand[(1 + d + p k) q + D[q, ell]], {k, 1, n - 1}];
  cp[(-1)^n q/(p^n (Times @@ (Factorial /@ ns)))]
 ];

lagrangeUnit[indices_List, p_, polys_List, A_, ell_] :=
 spCanonical[({#[[2]], inverseCoefficient[#[[1]], #[[2]], p, polys, ell]} &) /@ indices, A];

modelTerms[p_, deltas_List, polys_List] :=
 Prepend[MapThread[{#1, p + #1, #2} &, {deltas, polys}], {0, p, 1}];

newtonUnit[p_, deltas_List, polys_List, A_, ell_, iterationLimit_] := Module[
 {terms, derivativeTerms, u = {}, r, derivative, correction, step = 0},
 terms = modelTerms[p, deltas, polys];
 derivativeTerms = ({#[[1]], #[[2]] - 1,
   Expand[#[[2]] #[[3]] + D[#[[3]], ell]]} &) /@ terms;
 While[True,
  r = spAdd[spCompose[terms, u, A, ell], {{0, -1}}, A];
  If[r === {}, Return[spAdd[u, {{0, 1}}, A]]];
  If[step >= iterationLimit,
   fail["NewtonLimit", "Newton jets did not stabilize within the internal iteration bound."]];
  derivative = spCompose[derivativeTerms, u, A, ell];
  correction = spMul[r, spReciprocal[derivative, A, ell], A];
  u = spAdd[u, spScale[correction, -1], A]; step++
 ]
];

RealInverseSeries[f_, {x_Symbol, y_Symbol}, cutoff_, OptionsPattern[]] :=
 Catch[Block[{$assumptions = OptionValue[Assumptions],
    $maxIndices = OptionValue["MaxIndices"]},
  Module[{ell = Unique["ell$"], p, c, deltas, polys, A, indices, border,
    unit, method = OptionValue[Method], inputRemainder = OptionValue["InputRemainder"],
    verify = OptionValue["VerifyResidual"], beta, inputDegree, inputGap,
    ds = Infinity, kd = 0, degrees, candidates, remainderPower, remainderScale,
    residual = Missing["NotComputed"], expansion, logSub, remainderSource = "ModelTruncation"},
   If[x === y, fail["Variables", "Use distinct unassigned input and output symbols."]];
   If[!FreeQ[f, y], fail["Variables", "The forward expression must be independent of the output symbol."]];
   If[!IntegerQ[$maxIndices] || $maxIndices < 1,
    fail["MaxIndices", "MaxIndices must be a positive integer."]];
   If[!MemberQ[{True, False}, verify],
    fail["VerifyResidual", "VerifyResidual must be True or False."]];
   If[!MemberQ[{"Lagrange", "Newton"}, method],
    fail["Method", "Method must be Lagrange or Newton."]];
   If[!exactRealQ[cutoff],
    fail["Cutoff", "The cutoff must be an exact finite real numeric constant."]];
   {p, c, deltas, polys} = parseModel[f, x, ell];
   A = ce[p cutoff - 1];
   If[cmp[A, 0] <= 0,
    fail["Cutoff", "The cutoff must exceed the leading inverse exponent 1/p."]];
   If[inputRemainder =!= None,
    If[!MatchQ[inputRemainder, {_, _Integer}],
     fail["InputRemainder", "InputRemainder must be None or {beta,k} with integer k>=0."]];
    {beta, inputDegree} = inputRemainder;
    If[!exactRealQ[beta] || inputDegree < 0,
     fail["InputRemainder", "Input remainder data must have exact real beta and integer k>=0."]];
    inputGap = ce[beta - p];
    If[cmp[inputGap, 0] <= 0,
     fail["InputRemainder", "The input remainder exponent beta must exceed p."]];
    If[cmp[A, inputGap] > 0,
     fail["InsufficientInputOrder", "The requested inverse cutoff exceeds the order justified by the input remainder.",
      <|"MaximumInverseCutoff" -> ce[(beta - p + 1)/p]|>]]
   ];
   indices = indicesBelow[deltas, A];
   border = borderOf[indices, deltas, A];
   unit = If[method === "Lagrange",
    lagrangeUnit[indices, p, polys, A, ell],
    newtonUnit[p, deltas, polys, A, ell, Length[indices] + 2]];
   If[border =!= {},
    ds = First[Sort[border[[All, 2]], cmp[#1, #2] < 0 &]];
    degrees = Exponent[#, ell] & /@ polys;
    candidates = Select[border, cmp[#[[2]], ds] == 0 &];
    kd = Max[(Total[MapThread[Times, {#[[1]], degrees}]] &) /@ candidates]
   ];
   If[inputRemainder =!= None,
    Which[
     ds === Infinity || cmp[inputGap, ds] < 0,
       ds = inputGap; kd = inputDegree; remainderSource = "InputRemainder",
     cmp[inputGap, ds] == 0,
       kd = Max[kd, inputDegree]; remainderSource = "ModelAndInputRemainder",
     True, remainderSource = "ModelTruncation"
    ]
   ];
   logSub = ell -> Log[y/c]/p;
   expansion = Total[((y/c)^ce[(1 + #[[1]])/p] (#[[2]] /. logSub)) & /@ unit];
   If[ds === Infinity, remainderSource = "ExactInverse"];
   remainderPower = If[ds === Infinity, Infinity, ce[(1 + ds)/p]];
   remainderScale = If[ds === Infinity, 0,
    (y/c)^remainderPower (1 + Abs[Log[y/c]/p])^kd];
   If[TrueQ[verify],
    residual = spAdd[
     spCompose[modelTerms[p, deltas, polys], spAdd[unit, {{0, -1}}, A], A, ell],
     {{0, -1}}, A];
    If[residual =!= {},
     fail["InternalResidual", "The computed inverse failed the exact truncated residual check.",
      <|"ResidualBlocks" -> residual|>]]
   ];
   <|"Expansion" -> expansion,
     "Remainder" -> <|"Scale" -> remainderScale, "Power" -> remainderPower,
       "LogDegree" -> kd, "Source" -> remainderSource,
       "Meaning" -> "Inverse minus Expansion is O(Scale) as y->0+; 0 means an exact inverse of the supplied exact model.",
       "NumericalIntervalCertificate" -> False|>,
     "Blocks" -> ({ce[(1 + #[[1]])/p], #[[2]]} &) /@ unit,
     "LogVariable" -> ell, "LogSubstitution" -> logSub,
     "Core" -> <|"Coefficient" -> c, "Exponent" -> p|>,
     "Generators" -> MapThread[{#1, #2} &, {deltas, polys}],
     "Cutoff" -> cutoff, "NormalizedCutoff" -> A,
     "Branch" -> "Positive-real inverse germ with x/(y/c)^(1/p) -> 1 as y->0+",
     "Conditions" -> ($assumptions && y > 0),
     "Method" -> method, "IndexCount" -> Length[indices],
     "FormalResidualZero" -> If[verify, True, Missing["NotComputed"]],
     "VerifiedResidualCutoff" -> If[verify, ce[1 + A/p], Missing["NotComputed"]],
     "ForwardRemainder" -> inputRemainder,
     "ForwardRemainderContract" -> If[inputRemainder === None, "Exact finite input",
       "User assumes r=O(x^beta (1+|Log[x]|)^k) and r'=O(x^(beta-1) (1+|Log[x]|)^k). These bounds are not checked by the package."],
     "Input" -> f, "InputVariable" -> x, "OutputVariable" -> y,
     "Assumptions" -> $assumptions,
     "InternalData" -> {p, c, ell, deltas, polys, unit},
     "Version" -> $RealInverseSeriesVersion|>
  ]], $failureTag];

RealInverseSeries[___] := Failure["Arguments", <|
 "MessageTemplate" -> "Use RealInverseSeries[expression,{x,y},exactCutoff,options] with unassigned symbols x,y."|>];

InverseResidual[result_Association, requested_: Automatic] := Catch[
 Module[{needed, p, c, ell, deltas, polys, unit, y, A, cut, r, expr, data},
  needed = {"InternalData", "OutputVariable", "NormalizedCutoff", "Assumptions"};
  If[!(And @@ (KeyExistsQ[result, #] & /@ needed)),
   fail["Result", "Supply an unmodified result from RealInverseSeries."]];
  Block[{$assumptions = result["Assumptions"]},
   data = result["InternalData"];
   If[!MatchQ[data, {_, _, _Symbol, _List, _List, _List}],
    fail["Result", "The result's InternalData is invalid."]];
   {p, c, ell, deltas, polys, unit} = data;
   y = result["OutputVariable"];
   cut = If[requested === Automatic, ce[1 + result["NormalizedCutoff"]/p], requested];
   If[!exactRealQ[cut] || cmp[cut, 1] <= 0,
    fail["ResidualCutoff", "The residual cutoff must be an exact real constant greater than 1."]];
   A = ce[p (cut - 1)];
   r = spAdd[spCompose[modelTerms[p, deltas, polys],
      spAdd[unit, {{0, -1}}, A], A, ell], {{0, -1}}, A];
   expr = Total[(c (y/c)^ce[(p + #[[1]])/p]
       (#[[2]] /. ell -> Log[y/c]/p)) & /@ r];
   <|"Expansion" -> expr, "ZeroBelowCutoff" -> (r === {}),
     "Cutoff" -> cut, "RelativeResidualBlocks" -> r,
     "Meaning" -> "Formal expansion of the supplied finite model's forward residual; only powers below Cutoff are displayed. Input remainder bounds are not evaluated."|>
  ]
 ], $failureTag];

InverseResidual[___] := Failure["Arguments", <|
 "MessageTemplate" -> "Use InverseResidual[result] or InverseResidual[result,exactResidualCutoff]."|>];

PerturbativeInverse[phi_, h_, {x_Symbol, y_Symbol, eps_Symbol}, n_Integer?((# >= 0) &)] :=
 Module[{hp, dp, result = phi, k},
  If[Length[DeleteDuplicates[{x, y, eps}]] != 3,
   Return[Failure["Variables", <|"MessageTemplate" -> "Use three distinct unassigned symbols."|>]]];
  If[!FreeQ[phi, x] || !FreeQ[phi, eps] || !FreeQ[h, y] || !FreeQ[h, eps],
   Return[Failure["Variables", <|"MessageTemplate" -> "phi must be independent of x,eps and h must be independent of y,eps."|>]]];
  hp = h /. x -> phi; dp = D[phi, y];
  Do[result += (-eps)^k D[hp^k dp, {y, k - 1}]/Factorial[k], {k, 1, n}];
  Expand[result]
 ];

PerturbativeInverse[___] := Failure["Arguments", <|
 "MessageTemplate" -> "Use PerturbativeInverse[phi,h,{x,y,eps},nonnegativeInteger]."|>];

End[];
EndPackage[];
