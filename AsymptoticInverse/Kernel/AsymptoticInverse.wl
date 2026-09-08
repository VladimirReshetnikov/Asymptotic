(* ::Package:: *)
(* AsymptoticInverse -- power-log asymptotic expansions of functions and of their
   inverse functions on a real branch (finite endpoints and infinity, real
   exponents, polynomial logarithmic coefficients).

   Written after analysing nine independent reports on Mathematica Stack Exchange
   question 236367 and question "Asymptotic expansion for a function containing
   irrational exponents".  Theory: article/asymptotic-inverse.tex.

   SPDX-License-Identifier: MIT
*)

BeginPackage["AsymptoticInverse`"];

AsymptoticExpansion::usage =
"AsymptoticExpansion[f, {x, x0, cutoff}] gives the power-log asymptotic expansion of f \
as x -> x0 (x0 may be a real number, Infinity or -Infinity) with every block of \
exponent strictly less than cutoff in the local variable (|x - x0| or 1/|x|) retained, \
as a PowerLogSeries object.
AsymptoticExpansion[f, {x, x0}, SeriesTermGoal -> n] retains the first n nonzero blocks.";

AsymptoticInverse::usage =
"AsymptoticInverse[f, {x, x0}, {y, cutoff}] gives the asymptotic expansion of the real \
branch of the inverse function of f near x = x0 (x0 may be a real number, Infinity or \
-Infinity) as a PowerLogSeries object in y. Every complete block with exponent strictly \
less than cutoff in the local variable (y - y0, or 1/y when y0 is infinite) is retained.
AsymptoticInverse[f, {x, x0}, y, SeriesTermGoal -> n] retains the first n nonzero blocks.
Recognized leading-logarithmic and exponential cores return Scale -> \"Logarithmic\": \
the cutoff and term count apply to the unit bracket after extracting Prefactor, in \
the positive inverse-logarithmic variable LogarithmicVariable. See the package README \
for this scale's branch and remainder conventions.";

PowerLogSeries::usage =
"PowerLogSeries[assoc] represents a power-log asymptotic expansion together with its \
remainder and provenance. Normal[s] gives the finite expression; s[\"Remainder\"], \
s[\"Terms\"], s[\"SeriesData\"], s[\"Properties\"] and other properties are available; \
s[value] evaluates the finite expression at a numerical value of the variable.";

PowerLogRemainder::usage =
"PowerLogRemainder[w, beta, k] is an inert descriptor of the remainder class \
O[w^beta (1 + Abs[Log[w]])^k] as w -> 0+.";

InverseResidual::usage =
"InverseResidual[s] composes the forward model with the truncated inverse in the exact \
power-log jet algebra and returns the normalized residual f(g(y))/(a z^p) - 1 below the \
residual cutoff; InverseResidual[s, h] uses the relative cutoff h in the uniformizer.";

InverseNumericalCheck::usage =
"InverseNumericalCheck[s, y1] solves f(x) = y1 numerically on the selected branch and \
compares the exact inverse with the truncated expansion at y = y1.";

PerturbativeInverse::usage =
"PerturbativeInverse[phi, h, {x, y}, n] gives the Lagrange-Buermann expansion \
phi(y) + Sum[(-1)^N/N! D^(N-1)[phi'(y) h(phi(y))^N], {N, 1, n}] of the solution x of \
F0(x) + h(x) == y, where phi is the inverse of the core F0. PerturbativeInverse[h, {x, y}, n] \
uses the identity core. It is a formula generator; no asymptotic ordering is asserted.";

InverseExpansionCoefficient::usage =
"InverseExpansionCoefficient[s, {k1, k2, ...}] gives the exact logarithmic-polynomial \
coefficient attached to one multi-index of the inverse expansion s (or of a PowerLogModel).";

PowerLogModel::usage =
"PowerLogModel[f, {x, x0}] parses f near x0 into the normalized model \
y0 + a u^p (1 + Sum[u^delta_i B_i[Log[u]]]) in the local variable u and returns an Association.";

Begin["`Private`"];

$kernelDirectory = DirectoryName[$InputFileName];

(* ------------------------------------------------------------------ *)
(* Failure handling                                                     *)
(* ------------------------------------------------------------------ *)

$tag = "AsymptoticInverseFailure";
fail[tag_String, msg_String, extra_Association : <||>] :=
  Throw[Failure[tag, Join[<|"MessageTemplate" -> msg|>, extra]], $tag];
SetAttributes[catch, HoldAll];
catch[body_] := Catch[body, $tag];

(* ------------------------------------------------------------------ *)
(* Exact numbers: canonical forms, comparison, zero tests               *)
(* ------------------------------------------------------------------ *)

exactQ[e_] := FreeQ[e, _Real | _Complex];
validateInput[f_, limit_] := (
  If[! exactQ[f], fail["InexactInput", "Exact real input is required; approximate and complex constants are rejected."]];
  If[! FreeQ[f, Indeterminate | _DirectedInfinity], fail["NonfiniteInput", "The forward expression must not contain nonfinite constants."]];
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]]);
exactRealQ[e_] := NumericQ[e] && exactQ[e] && TrueQ[FullSimplify[Element[e, Reals]]];
algebraicRealQ[e_] := exactQ[e] && NumericQ[e] && Module[{t},
   t = Quiet[Element[e, Algebraics] && Element[e, Reals]];
   If[t === True || t === False, t, TrueQ[Quiet[FullSimplify[t]]]]];

canon[Infinity] = Infinity;
canon[-Infinity] = -Infinity;
canon[e_?NumericQ] := Module[{r},
  If[! exactQ[e], fail["InexactInput", "Exact input is required; approximate real numbers are rejected."]];
  If[Head[e] === Integer || Head[e] === Rational, Return[e, Module]];
  If[algebraicRealQ[e], RootReduce[e],
   r = FullSimplify[e];
   If[NumericQ[r] && TrueQ[FullSimplify[Element[r, Reals]]], r,
    fail["UnsupportedNumber", "Cannot canonicalize the exact number.", <|"Number" -> e|>]]]];
canon[e_] := FullSimplify[e];

compare[a_, b_] := Module[{d, t},
  If[a === b, Return[0, Module]];
  If[a === Infinity, Return[1, Module]]; If[b === Infinity, Return[-1, Module]];
  If[a === -Infinity, Return[-1, Module]]; If[b === -Infinity, Return[1, Module]];
  If[(Head[a] === Integer || Head[a] === Rational) && (Head[b] === Integer || Head[b] === Rational),
   Return[Sign[a - b], Module]];
  If[NumericQ[a] && NumericQ[b],
   If[TrueQ[a < b], Return[-1, Module]];
   If[TrueQ[a > b], Return[1, Module]]];
  d = canon[a - b];
  If[d === 0, Return[0, Module]];
  If[TrueQ[d < 0], Return[-1, Module]];
  If[TrueQ[d > 0], Return[1, Module]];
  t = FullSimplify[d < 0];
  Which[TrueQ[t], -1, TrueQ[! t], 1,
   True, fail["UndecidableOrder", "The ordering of two exact exponents could not be decided.", <|"Difference" -> d|>]]];
less[a_, b_] := compare[a, b] < 0;
leq[a_, b_] := compare[a, b] <= 0;
equal[a_, b_] := compare[a, b] == 0;
minOf[a_, b_] := If[leq[a, b], a, b];

symbolicEqualQ[a_, b_, ass_] := a === b || TrueQ[Simplify[a - b == 0, ass]];

(* ------------------------------------------------------------------ *)
(* Coefficient normalization                                            *)
(* ------------------------------------------------------------------ *)

logCanon[e_] := e /. Log[r_Rational] :> Total[(#[[2]] Log[#[[1]]]) & /@ FactorInteger[r]] /.
   Log[n_Integer] /; n > 1 :> Total[(#[[2]] Log[#[[1]]]) & /@ FactorInteger[n]];

coefCanon[c_, ass_] := Module[{e},
  If[Head[c] === Integer || Head[c] === Rational, Return[c, Module]];
  e = logCanon[Together[Expand[c]]];
  Which[e === 0, 0,
   Head[e] === Integer || Head[e] === Rational, e,
   algebraicRealQ[e], RootReduce[e],
   NumericQ[e], Simplify[e],
   True, Simplify[e, ass]]];

polyCanon[q_, ell_, ass_] := Module[{cl, e = Expand[logCanon[q]]},
  If[e === 0, Return[0, Module]];
  If[! PolynomialQ[e, ell], e = Expand[Together[e]]];
  If[! PolynomialQ[e, ell], Return[Simplify[e, ass], Module]];
  cl = coefCanon[#, ass] & /@ CoefficientList[e, ell];
  Expand[cl . ell^Range[0, Length[cl] - 1]]];
zeroQ[q_, ass_] := q === 0 || (NumericQ[q] && exactQ[q] && (algebraicRealQ[q] && RootReduce[q] === 0 || TrueQ[Simplify[q == 0]])) ||
  (! NumericQ[q] && TrueQ[Simplify[q == 0, ass]]);
polyZeroQ[q_, ell_, ass_] := Module[{p = polyCanon[q, ell, ass]},
  p === 0 || (PolynomialQ[p, ell] && And @@ (zeroQ[#, ass] & /@ CoefficientList[p, ell]))];
polyDegree[q_, ell_] := If[q === 0, 0, Exponent[q, ell]];

(* ------------------------------------------------------------------ *)
(* Sparse power-log jets: lists of {weight, polynomial in ell}          *)
(* ------------------------------------------------------------------ *)

jetMerge[terms_List, ell_, ass_, symbolic_: False] := Module[{groups, out},
  If[terms === {}, Return[{}, Module]];
  If[symbolic,
   out = {};
   Do[Module[{pos},
     pos = FirstPosition[out, {w_, _} /; symbolicEqualQ[w, t[[1]], ass], Missing[], {1}, Heads -> False];
     If[MissingQ[pos], AppendTo[out, {t[[1]], t[[2]]}],
      out[[pos[[1]], 2]] = out[[pos[[1]], 2]] + t[[2]]]], {t, terms}];
   out = {#[[1]], polyCanon[#[[2]], ell, ass]} & /@ out;
   Return[Select[out, ! polyZeroQ[#[[2]], ell, ass] &], Module]];
  groups = GatherBy[terms, canon[#[[1]]] &];
  out = {canon[#[[1, 1]]], polyCanon[Total[#[[All, 2]]], ell, ass]} & /@ groups;
  out = Select[out, ! polyZeroQ[#[[2]], ell, ass] &];
  Sort[out, leq[#1[[1]], #2[[1]]] &]];

jetTrim[u_List, cut_, ell_, ass_] := jetMerge[Select[u, less[#[[1]], cut] &], ell, ass];
jetAdd[u_List, v_List, cut_, ell_, ass_] := jetTrim[Join[u, v], cut, ell, ass];
jetScale[u_List, c_, ell_, ass_] := If[zeroQ[c, ass], {}, jetMerge[{#[[1]], c #[[2]]} & /@ u, ell, ass]];
jetShift[u_List, s_] := {#[[1]] + s, #[[2]]} & /@ u;
jetMul[u_List, v_List, cut_, ell_, ass_, limit_] := Module[{raw, last = Length[v], counts, products = 0},
  If[u === {} || v === {}, Return[{}, Module]];
  (* Canonical jets are sorted by weight.  The last admissible column can only
     decrease as the row weight increases, so locate the retained products in
     linear time before multiplying any coefficient polynomials. *)
  counts = Table[
    If[cut =!= Infinity,
     While[last > 0 && ! less[a[[1]] + v[[last, 1]], cut], last--]];
    products += last;
    If[products > limit, fail["ResourceLimit", "A truncated sparse product exceeded the MaxTerms budget.",
      <|"MaxTerms" -> limit|>]];
    last, {a, u}];
  raw = Flatten[Table[
    Table[{u[[i, 1]] + v[[j, 1]], u[[i, 2]] v[[j, 2]]}, {j, counts[[i]]}],
    {i, Length[u]}], 1];
  jetMerge[raw, ell, ass]];
jetValuation[u_List] := If[u === {}, Infinity, u[[1, 1]]];
jetLeadingDegree[u_List, ell_] := If[u === {}, 0, polyDegree[u[[1, 2]], ell]];
jetMaxDegree[u_List, ell_] := If[u === {}, 0, Max[polyDegree[#[[2]], ell] & /@ u]];

(* Sum c_k U^k for k >= 1 with coefficients supplied by cf[k]; U has positive valuation.
   Stops when U^k vanishes below cut or when the coefficient generator returns Null. *)
jetPowerSeries[u_List, cf_, cut_, ell_, ass_, limit_] := Module[{ans = {}, pw = {{0, 1}}, k = 0, c},
  If[u === {}, Return[{}, Module]];
  If[cut === Infinity, fail["InfiniteSeries", "An infinite series is required; a finite working order is needed."]];
  If[! less[0, jetValuation[u]], fail["NonSmallJet", "Unit-series arithmetic requires positive valuation."]];
  While[True,
   k++;
   pw = jetMul[pw, u, cut, ell, ass, limit];
   If[pw === {}, Break[]];
   c = cf[k];
   If[c === Null, Break[]];
   If[! zeroQ[c, ass], ans = jetAdd[ans, jetScale[pw, c, ell, ass], cut, ell, ass]]];
  ans];
jetUnitPower[u_List, r_, cut_, ell_, ass_, limit_] := Module[{c = 1, last = 0},
  jetAdd[{{0, 1}}, jetPowerSeries[u, Function[k, c = c (r - k + 1)/k; If[zeroQ[c, ass], Null, c]], cut, ell, ass, limit], cut, ell, ass]];
jetUnitLog[u_List, cut_, ell_, ass_, limit_] := jetPowerSeries[u, Function[k, (-1)^(k + 1)/k], cut, ell, ass, limit];
jetUnitExp[u_List, cut_, ell_, ass_, limit_] := jetAdd[{{0, 1}}, jetPowerSeries[u, Function[k, 1/k!], cut, ell, ass, limit], cut, ell, ass];

(* (1+U)^a P(ell + log(1+U)) = Sum Q_k(ell) U^k, Q_0 = P, Q_{k+1} = ((a-k) Q_k + Q_k')/(k+1) *)
jetComposeBlock[u_List, a_, P_, cut_, ell_, ass_, limit_] := Module[{ans, pw = {{0, 1}}, k = 0, Q = P},
  ans = jetMerge[{{0, P}}, ell, ass];
  If[u === {}, Return[ans, Module]];
  If[cut === Infinity, fail["InfiniteSeries", "An infinite series is required; a finite working order is needed."]];
  If[! less[0, jetValuation[u]], fail["NonSmallJet", "Unit-series arithmetic requires positive valuation."]];
  While[True,
   Q = Expand[((a - k) Q + D[Q, ell])/(k + 1)];
   k++;
   pw = jetMul[pw, u, cut, ell, ass, limit];
   If[pw === {}, Break[]];
   If[polyZeroQ[Q, ell, ass], Continue[]];
   ans = jetAdd[ans, jetMul[pw, {{0, Q}}, cut, ell, ass, limit], cut, ell, ass]];
  ans];

jetReciprocalUnit[v_List, cut_, ell_, ass_, limit_] := Module[{c0, rest},
  If[v === {} || ! (v[[1, 1]] === 0) || ! FreeQ[v[[1, 2]], ell],
   fail["NotAUnit", "The jet is not a unit with constant leading term."]];
  c0 = v[[1, 2]];
  rest = jetScale[Rest[v], 1/c0, ell, ass];
  jetScale[jetUnitPower[rest, -1, cut, ell, ass, limit], 1/c0, ell, ass]];

(* ------------------------------------------------------------------ *)
(* Precision-tracked jets: {terms, P, D} means terms + O(u^P (1+|L|)^D) *)
(* ------------------------------------------------------------------ *)

pConst[c_, ell_, ass_] := (
  If[! PolynomialQ[c, ell], fail["UnsupportedCoefficient", "Logarithmic coefficients must be polynomials.", <|"Coefficient" -> c|>]];
  If[zeroQ[c, ass], {{}, Infinity, 0}, {{{0, c}}, Infinity, 0}]);
pVar = {{{1, 1}}, Infinity, 0};

combinePrecision[{P1_, D1_}, {P2_, D2_}] := Which[less[P1, P2], {P1, D1}, less[P2, P1], {P2, D2}, True, {P1, Max[D1, D2]}];

pAdd[{T1_, P1_, D1_}, {T2_, P2_, D2_}, ell_, ass_] := Module[{pd = combinePrecision[{P1, D1}, {P2, D2}]},
  If[pd[[1]] =!= Infinity,
   pd[[2]] = Max[pd[[2]], polyDegree[Total[Cases[Join[T1, T2], {w_, q_} /; equal[w, pd[[1]]] :> q]], ell]]];
  {jetTrim[Join[T1, T2], pd[[1]], ell, ass], pd[[1]], pd[[2]]}];
pScale[{T_, P_, D_}, c_, ell_, ass_] := If[zeroQ[c, ass], {{}, Infinity, 0}, {jetScale[T, c, ell, ass], P, D}];
pMul[{T1_, P1_, D1_}, {T2_, P2_, D2_}, ell_, ass_, limit_] := Module[{v1, v2, e1, e2, pd},
  If[P1 === Infinity && P2 === Infinity, Return[{jetMul[T1, T2, Infinity, ell, ass, limit], Infinity, 0}, Module]];
  v1 = If[T1 === {}, P1, jetValuation[T1]]; e1 = If[T1 === {}, D1, jetLeadingDegree[T1, ell]];
  v2 = If[T2 === {}, P2, jetValuation[T2]]; e2 = If[T2 === {}, D2, jetLeadingDegree[T2, ell]];
  pd = combinePrecision[{If[P1 === Infinity, Infinity, P1 + v2], D1 + e2}, {If[P2 === Infinity, Infinity, P2 + v1], D2 + e1}];
  If[pd[[1]] =!= Infinity,
   Do[If[equal[t1[[1]] + t2[[1]], pd[[1]]], pd[[2]] = Max[pd[[2]], polyDegree[t1[[2]], ell] + polyDegree[t2[[2]], ell]]],
    {t1, T1}, {t2, T2}]];
  {jetMul[T1, T2, pd[[1]], ell, ass, limit], pd[[1]], pd[[2]]}];
pIntegerPower[j_, n_Integer?NonNegative, ell_, ass_, limit_] := Module[{r = pConst[1, ell, ass], b = j, k = n},
  (* Binary powering also preserves the precision propagation of pMul. *)
  While[k > 0,
   If[OddQ[k], r = pMul[r, b, ell, ass, limit]];
   k = Quotient[k, 2];
   If[k > 0, b = pMul[b, b, ell, ass, limit]]];
  r];

(* tail bound of a unit series truncated at relative weight cut, with argument U known to relative precision {PU, DU} *)
unitSeriesPrecision[U_List, PU_, DU_, cut_, ell_] := Module[{c = minOf[PU, cut], Nn, d},
  If[U === {}, Return[{PU, DU}, Module]];
  If[c === Infinity, Return[{Infinity, 0}, Module]];
  Nn = Ceiling[canon[c/jetValuation[U]]];
  d = jetMaxDegree[U, ell];
  If[equal[c, cut] && less[cut, PU], {cut, Nn d},
   If[equal[c, PU] && less[PU, cut], {PU, DU}, {c, Max[Nn d, DU]}]]];

(* generic unit-series application: f(1+U) or f(c0+U) via coefficient generator *)
pUnitSeries[U_List, PU_, DU_, cf_, cut_, ell_, ass_, limit_] := Module[{c = minOf[PU, cut], pd, T},
  pd = unitSeriesPrecision[U, PU, DU, cut, ell];
  T = jetPowerSeries[U, cf, pd[[1]], ell, ass, limit];
  {T, pd[[1]], pd[[2]]}];

(* ------------------------------------------------------------------ *)
(* Forward expansion engine                                             *)
(* ------------------------------------------------------------------ *)

(* split a jet into weight<0 part, weight-0 polynomial, weight>0 part *)
splitJet[T_List] := {Select[T, less[#[[1]], 0] &], Total[Select[T, #[[1]] === 0 &][[All, 2]]], Select[T, less[0, #[[1]]] &]};

provablyPositive[c_, ass_] := TrueQ[Simplify[c > 0, ass]];
provablyNegative[c_, ass_] := TrueQ[Simplify[c < 0, ass]];

fwd[e_, u_, ell_, ass_, Kw_, limit_] := Module[{h = Head[e]},
  Which[
   FreeQ[e, u], pConst[e, ell, ass],
   e === u, pVar,
   h === Plus, Fold[pAdd[#1, fwd[#2, u, ell, ass, Kw, limit], ell, ass] &, pConst[0, ell, ass], List @@ e],
   h === Times, Fold[pMul[#1, fwd[#2, u, ell, ass, Kw, limit], ell, ass, limit] &, pConst[1, ell, ass], List @@ e],
   h === Power && e[[1]] === E, fwdExp[fwd[e[[2]], u, ell, ass, Kw, limit], u, ell, ass, Kw, limit],
   h === Power && FreeQ[e[[2]], u], fwdPower[fwd[e[[1]], u, ell, ass, Kw, limit], e[[2]], u, ell, ass, Kw, limit],
   h === Power, fwdExp[pMul[fwd[e[[2]], u, ell, ass, Kw, limit], fwdLog[fwd[e[[1]], u, ell, ass, Kw, limit], u, ell, ass, Kw, limit], ell, ass, limit], u, ell, ass, Kw, limit],
   h === Log && Length[e] == 1, fwdLog[fwd[e[[1]], u, ell, ass, Kw, limit], u, ell, ass, Kw, limit],
   h === Log && Length[e] == 2, fwd[Log[e[[2]]]/Log[e[[1]]], u, ell, ass, Kw, limit],
   h === Exp, fwdExp[fwd[e[[1]], u, ell, ass, Kw, limit], u, ell, ass, Kw, limit],
   h === Sqrt, fwdPower[fwd[e[[1]], u, ell, ass, Kw, limit], 1/2, u, ell, ass, Kw, limit],
   h === Abs, fwdAbs[fwd[e[[1]], u, ell, ass, Kw, limit], ell, ass],
   Length[e] == 1, fwdAnalytic[h, fwd[e[[1]], u, ell, ass, Kw, limit], e, u, ell, ass, Kw, limit],
   True, fwdSeries[e, u, ell, ass, Kw, limit]]];

fwdAbs[j : {T_, P_, D_}, ell_, ass_] := Module[{q, c, degree},
  If[T === {}, Return[j, Module]];
  q = T[[1, 2]]; degree = polyDegree[q, ell];
  c = (-1)^degree Coefficient[q, ell, degree];
  Which[provablyPositive[c, ass], j, provablyNegative[c, ass], pScale[j, -1, ell, ass],
    True, fail["UnprovedSign", "The eventual sign of the absolute-value argument could not be proved."]]];

fwdPower[{T_, P_, D_}, r_, u_, ell_, ass_, Kw_, limit_] := Module[{alpha, Q, c, U, PU, DU, cutRel, res, rr},
  If[! (NumericQ[r] && exactQ[r]), fail["SymbolicExponent", "Exponents must be exact numbers.", <|"Exponent" -> r|>]];
  If[! TrueQ[Simplify[Element[r, Reals]]], fail["ComplexExponent", "Only real exponents are supported.", <|"Exponent" -> r|>]];
  rr = If[algebraicRealQ[r], RootReduce[r], r];
  If[IntegerQ[rr] && rr >= 0, Return[pIntegerPower[{T, P, D}, rr, ell, ass, limit], Module]];
  If[T === {},
   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],
    fail["UnknownLeadingTerm", "Cannot raise a quantity known only as a remainder to a nonpositive power; increase the working order."]]];
  {alpha, Q} = T[[1]];
  If[! FreeQ[Q, ell],
   fail["LogarithmicLeadingPower", "The leading block contains a logarithm and the exponent is not a nonnegative integer; the result is outside the power-log class.", <|"LeadingBlock" -> Q, "Exponent" -> r|>]];
  c = Q;
  If[! provablyPositive[c, ass],
   If[IntegerQ[rr] && provablyNegative[c, ass], Null,
    fail["NonpositiveBase", "The leading coefficient of the base must be provably positive for a real non-integer power.", <|"Coefficient" -> c|>]]];
  U = jetScale[jetShift[Rest[T], -alpha], 1/c, ell, ass];
  PU = If[P === Infinity, Infinity, P - alpha]; DU = D;
  cutRel = If[Kw === Infinity, Infinity, Kw - alpha rr];
  If[! less[0, cutRel] && ! (Kw === Infinity), Return[{{}, alpha rr + cutRel, 0}, Module]];
  res = If[U === {}, {{}, PU, DU},
    pUnitSeries[U, PU, DU, Module[{cc = 1}, Function[k, cc = cc (rr - k + 1)/k; If[zeroQ[cc, ass], Null, cc]]], cutRel, ell, ass, limit]];
  res = {jetAdd[{{0, 1}}, res[[1]], res[[2]], ell, ass], res[[2]], res[[3]]};
  {jetScale[jetShift[res[[1]], alpha rr], c^rr, ell, ass], If[res[[2]] === Infinity, Infinity, res[[2]] + alpha rr], res[[3]]}];

fwdLog[{T_, P_, D_}, u_, ell_, ass_, Kw_, limit_] := Module[{alpha, Q, c, U, PU, DU, res},
  If[T === {}, fail["UnknownLeadingTerm", "Cannot take the logarithm of a quantity known only as a remainder; increase the working order."]];
  {alpha, Q} = T[[1]];
  If[! FreeQ[Q, ell], fail["LogarithmicLeadingPower", "Log of a block with a logarithmic factor is outside the power-log class.", <|"LeadingBlock" -> Q|>]];
  c = Q;
  If[! provablyPositive[c, ass], fail["NonpositiveBase", "The leading coefficient must be provably positive to take a real logarithm.", <|"Coefficient" -> c|>]];
  U = jetScale[jetShift[Rest[T], -alpha], 1/c, ell, ass];
  PU = If[P === Infinity, Infinity, P - alpha]; DU = D;
  res = If[U === {}, {{}, PU, DU}, pUnitSeries[U, PU, DU, Function[k, (-1)^(k + 1)/k], Kw, ell, ass, limit]];
  {jetAdd[{{0, logCanon[Log[c]] + alpha ell}}, res[[1]], res[[2]], ell, ass], res[[2]], res[[3]]}];

fwdExp[{T_, P_, D_}, u_, ell_, ass_, Kw_, limit_] := Module[{neg, q0, U, k, c, res, cutRel},
  If[! less[0, P], fail["UnknownLeadingTerm", "The exponential argument needs positive remainder precision."]];
  {neg, q0, U} = splitJet[T];
  If[neg =!= {}, fail["ExponentialScale", "Exp of a quantity that is unbounded at the expansion point produces exponential growth or decay, which is outside the power-log class.", <|"Argument" -> neg|>]];
  If[! (PolynomialQ[q0, ell] && polyDegree[q0, ell] <= 1), fail["ExponentialScale", "Exp of a polynomial of degree > 1 in the logarithm is outside the power-log class."]];
  k = Coefficient[q0, ell, 1]; c = Coefficient[q0, ell, 0];
  If[! exactRealQ[k], fail["SymbolicExponent", "Exp[k Log[u]] needs an exact real numeric k."]];
  If[T === {}, Return[{{{0, 1}}, P, D}, Module]];
  cutRel = If[Kw === Infinity, Infinity, Kw - k];
  res = If[U === {}, {{}, P, D}, pUnitSeries[U, P, D, Function[j, 1/j!], cutRel, ell, ass, limit]];
  res = {jetAdd[{{0, 1}}, res[[1]], res[[2]], ell, ass], res[[2]], res[[3]]};
  {jetScale[jetShift[res[[1]], k], Exp[c], ell, ass], If[res[[2]] === Infinity, Infinity, res[[2]] + k], res[[3]]}];

fwdAnalytic[h_, {T_, P_, D_}, e_, u_, ell_, ass_, Kw_, limit_] := Module[{neg, q0, U, c0, s, N0, t, coeffs, res, nmin, k, cf, sign, lc, V, rho, pd, power},
  If[! less[0, P], fail["UnknownLeadingTerm", "A function argument needs positive remainder precision."]];
  {neg, q0, U} = splitJet[T];
  If[neg =!= {} || ! FreeQ[q0, ell], Return[fwdSeries[e, u, ell, ass, Kw, limit], Module]];
  c0 = q0;
  If[Kw === Infinity && U =!= {}, fail["InfiniteSeries", "An infinite series is required; a finite working order is needed."]];
  N0 = If[U === {}, 1, Max[1, Ceiling[canon[minOf[If[P === Infinity, Kw, P], Kw]/jetValuation[U]]]]];
  If[N0 > 400, fail["ResourceLimit", "Too many Taylor terms are required."]];
  sign = 1;
  If[U =!= {},
   lc = U[[1, 2]];
   lc = (-1)^polyDegree[lc, ell] Coefficient[lc, ell, polyDegree[lc, ell]];
   If[provablyNegative[lc, ass], sign = -1]];
  s = Quiet[Series[h[c0 + sign t], {t, 0, N0}, Assumptions -> ass && t > 0]];
  If[! MatchQ[s, _SeriesData] || ! FreeQ[s[[3]], t],
   Return[fwdSeries[e, u, ell, ass, Kw, limit], Module]];
  (* Compose Laurent and Puiseux expansions in a positive local increment.
     In particular this handles poles and algebraic branch points even when
     Series cannot order the irrational powers in the original expression. *)
  If[s[[6]] =!= 1 || s[[4]] < 0,
   If[U === {}, fail["UnknownLeadingTerm", "A singular function needs a known leading increment."]];
   V = {jetScale[U, sign, ell, ass], P, D};
   res = pConst[0, ell, ass];
   Do[If[! zeroQ[s[[3, k]], ass],
     power = (s[[4]] + k - 1)/s[[6]];
     res = pAdd[res, pScale[fwdPower[V, power, u, ell, ass, Kw, limit], s[[3, k]], ell, ass], ell, ass]],
     {k, Length[s[[3]]]}];
   rho = s[[5]]/s[[6]];
   pd = {canon[rho jetValuation[U]], Max[0, Ceiling[rho jetLeadingDegree[U, ell]]]};
   Return[pAdd[res, {{}, pd[[1]], pd[[2]]}, ell, ass], Module]];
  If[sign === -1, U = jetScale[U, -1, ell, ass]];
  coeffs = s[[3]]; nmin = s[[4]];
  c0 = If[nmin <= 0 && Length[coeffs] >= 1 - nmin, coeffs[[1 - nmin]], 0];
  cf = Function[j, If[j >= nmin && j - nmin + 1 <= Length[coeffs], coeffs[[j - nmin + 1]], If[j < nmin, 0, Null]]];
  If[U === {}, Return[{jetMerge[{{0, c0}}, ell, ass], P, D}, Module]];
  res = pUnitSeries[U, P, D, cf, Kw, ell, ass, limit];
  {jetAdd[jetMerge[{{0, c0}}, ell, ass], res[[1]], res[[2]], ell, ass], res[[2]], res[[3]]}];

(* fallback: Series in u; the remainder degree is read from the first omitted block *)
fwdSeries[e_, u_, ell_, ass_, Kw_, limit_] := Module[{order, s, parts, sd, rest, rows = {}, rho, kdeg, s2, sd2, cand, extra},
  If[Kw === Infinity, fail["InfiniteSeries", "The expression is not a finite power-log sum and no finite working order was given.", <|"Expression" -> e|>]];
  order = Max[1, Ceiling[canon[Kw]]];
  s = Quiet[Series[e, {u, 0, order}, Assumptions -> ass && u > 0]];
  If[Head[s] === Series || (Head[s] =!= SeriesData && FreeQ[s, SeriesData]),
   fail["UnsupportedInput", "The function could not be expanded in a power-log scale at the expansion point.", <|"Expression" -> e|>]];
  parts = If[Head[s] === Plus, List @@ s, {s}];
  sd = Select[parts, Head[#] === SeriesData &];
  rest = Select[parts, Head[#] =!= SeriesData &];
  If[Length[sd] =!= 1 || ! (sd[[1, 1]] === u && sd[[1, 2]] === 0), fail["UnsupportedInput", "The function could not be expanded in a power-log scale at the expansion point (oscillatory, exponential or nested-logarithmic behaviour).", <|"Expression" -> e|>]];
  sd = First[sd];
  Do[If[! zeroQ[sd[[3, i]], ass],
    Module[{cj = fwd[sd[[3, i]] /. Log[u] -> ell, u, ell, ass, Infinity, limit]},
     If[cj[[2]] =!= Infinity, fail["UnsupportedInput", "A Series coefficient is not a finite power-log expression.", <|"Coefficient" -> sd[[3, i]]|>]];
     rows = Join[rows, jetShift[cj[[1]] /. ell -> ell, (sd[[4]] + i - 1)/sd[[6]]]]]],
   {i, Length[sd[[3]]]}];
  rho = sd[[5]]/sd[[6]];
  extra = If[rest === {}, pConst[0, ell, ass], fwd[Total[rest], u, ell, ass, Kw, limit]];
  (* first omitted block degree *)
  kdeg = 0;
  s2 = Quiet[Series[e, {u, 0, order + 1}, Assumptions -> ass && u > 0]];
  If[Head[s2] =!= Series,
   Module[{p2 = If[Head[s2] === Plus, List @@ s2, {s2}]},
    sd2 = Select[p2, Head[#] === SeriesData &];
    If[Length[sd2] == 1,
     sd2 = First[sd2];
     cand = Select[Transpose[{Range[Length[sd2[[3]]]], sd2[[3]]}], (sd2[[4]] + #[[1]] - 1)/sd2[[6]] >= rho && ! zeroQ[#[[2]], ass] &];
     If[cand =!= {},
      kdeg = polyDegree[Expand[cand[[1, 2]] /. Log[u] -> ell], ell];
      rho = (sd2[[4]] + cand[[1, 1]] - 1)/sd2[[6]],
      rho = sd2[[5]]/sd2[[6]]]]]];
  pAdd[{jetMerge[rows, ell, ass], rho, kdeg}, extra, ell, ass]];

(* ------------------------------------------------------------------ *)
(* Endpoint normalization                                               *)
(* ------------------------------------------------------------------ *)

localCoordinate[x_, x0_, direction_] := Module[{dir = direction, u = Unique["u$"], sub, s},
  Which[
   x0 === Infinity, If[dir === Automatic, dir = "FromBelow"];
   If[dir =!= "FromBelow", fail["InvalidDirection", "x -> Infinity is approached from below."]];
   sub = 1/u; s = 1,
   x0 === -Infinity, If[dir === Automatic, dir = "FromAbove"];
   If[dir =!= "FromAbove", fail["InvalidDirection", "x -> -Infinity is approached from above."]];
   sub = -1/u; s = -1,
   True,
   If[! (NumericQ[x0] && exactQ[x0] && TrueQ[Simplify[Element[x0, Reals]]]),
    fail["InvalidExpansionPoint", "The expansion point must be an exact real number, Infinity or -Infinity."]];
   If[dir === Automatic, dir = "FromAbove"];
   Which[dir === "FromAbove", sub = x0 + u; s = 1,
    dir === "FromBelow", sub = x0 - u; s = -1,
    True, fail["InvalidDirection", "Direction must be Automatic, \"FromAbove\" or \"FromBelow\"."]]];
  <|"u" -> u, "Substitution" -> sub, "Sign" -> s, "Direction" -> dir,
    "Infinite" -> (x0 === Infinity || x0 === -Infinity),
    (* the local variable and its logarithm in terms of x *)
    "LocalVariable" -> Which[x0 === Infinity, 1/x, x0 === -Infinity, -1/x, dir === "FromAbove", x - x0, True, x0 - x]|>];

(* ------------------------------------------------------------------ *)
(* Forward expansion: public                                            *)
(* ------------------------------------------------------------------ *)

Options[AsymptoticExpansion] = {Assumptions -> True, Direction -> Automatic, SeriesTermGoal -> Automatic, "MaxTerms" -> 20000};
AsymptoticExpansion[f_, {x_Symbol, x0_, cutoff_}, opts : OptionsPattern[]] := catch[forwardPublic[f, x, x0, cutoff, opts]];
AsymptoticExpansion[f_, {x_Symbol, x0_}, opts : OptionsPattern[]] := catch[forwardPublic[f, x, x0, Automatic, opts]];
AsymptoticExpansion[___] := Failure["InvalidArguments", <|"MessageTemplate" ->
   "Use AsymptoticExpansion[f, {x, x0, cutoff}] or AsymptoticExpansion[f, {x, x0}, SeriesTermGoal -> n]."|>];

(* compute the forward jet of f in the local variable to absolute precision >= K *)
forwardJet[fu_, u_, ell_, ass_, K_, limit_, extra_: 1] := Module[{Kw, res, tries = 0},
  Kw = K + extra;
  While[True,
   tries++;
   res = Catch[fwd[fu, u, ell, ass, Kw, limit], $tag];
   If[FailureQ[res],
    If[res[[1]] === "UnknownLeadingTerm" && tries <= 12, Kw = Max[1, 2 Kw + 1]; Continue[]];
    Throw[res, $tag]];
   If[res[[2]] === Infinity || ! less[res[[2]], K], Break[]];
   If[tries > 8, fail["InsufficientOrder", "Could not reach the requested precision.", <|"Reached" -> res[[2]]|>]];
   Kw = Kw + (K - res[[2]]) + 1];
  res];

(* exact jet of a finite power-log expression, or $Failed when an infinite series would be needed *)
exactJet[fu_, u_, ell_, ass_, limit_] := Module[{r = Catch[fwd[fu, u, ell, ass, Infinity, limit], $tag]},
  Which[FailureQ[r] && r[[1]] === "InfiniteSeries", $Failed,
   FailureQ[r] && r[[1]] === "UnsupportedInput", $Failed,
   FailureQ[r], Throw[r, $tag],
   True, r]];

forwardPublic[f_, x_, x0_, cutoff0_, opts : OptionsPattern[AsymptoticExpansion]] := Module[
  {ass = OptionValue[AsymptoticExpansion, {opts}, Assumptions], dir = OptionValue[AsymptoticExpansion, {opts}, Direction],
   goal = OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], limit = OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"],
   coord, u, ell = Unique["ell$"], fu, jet, cutoff = cutoff0, T, tries = 0, K, ex},
  validateInput[f, limit];
  If[! FreeQ[ass, x], fail["InvalidAssumptions", "Assumptions concern parameters only."]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"];
  fu = f /. x -> coord["Substitution"];
  If[cutoff === Automatic,
   If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give an exponent cutoff or SeriesTermGoal -> n."]];
   ex = exactJet[fu, u, ell, ass, limit];
   If[ex =!= $Failed,
    T = ex[[1]];
    cutoff = If[Length[T] > goal, T[[goal + 1, 1]], Infinity];
    jet = ex,
    K = 1;
    While[True,
     tries++;
     jet = forwardJet[fu, u, ell, ass, K, limit, 0];
     T = jet[[1]];
     If[Length[T] > goal || jet[[2]] === Infinity, Break[]];
     If[tries > 12, fail["ResourceLimit", "SeriesTermGoal iteration did not terminate."]];
     K = 2 K + 1];
    cutoff = If[Length[T] > goal, T[[goal + 1, 1]], Infinity];
    If[cutoff =!= Infinity, jet = forwardJet[fu, u, ell, ass, cutoff, limit, 1]]],
   If[! exactRealQ[cutoff], fail["InvalidCutoff", "The cutoff must be an exact real number."]];
   ex = exactJet[fu, u, ell, ass, limit];
   jet = If[ex =!= $Failed, ex, forwardJet[fu, u, ell, ass, cutoff, limit, 1]]];
  makeForwardObject[jet, cutoff, f, x, x0, coord, u, ell, ass, goal]];

makeForwardObject[jet_, cutoff_, f_, x_, x0_, coord_, u_, ell_, ass_, goal_] := Module[
  {T, P, D, kept, omitted, remData, wexpr, logw, expr, terms, frontier, sd},
  {T, P, D} = jet;
  kept = Select[T, less[#[[1]], cutoff] &];
  omitted = Select[T, ! less[#[[1]], cutoff] &];
  If[IntegerQ[goal] && Length[kept] > goal, omitted = Join[Drop[kept, goal], omitted]; kept = Take[kept, goal]];
  remData = Which[
    omitted =!= {}, {omitted[[1, 1]], polyDegree[omitted[[1, 2]], ell]},
    P === Infinity, None,
    True, {P, D}];
  frontier = If[omitted =!= {}, omitted[[1]], None];
  wexpr = coord["LocalVariable"];
  logw = Which[x0 === Infinity, -Log[x], x0 === -Infinity, -Log[-x], True, Log[wexpr]];
  terms = {ToRadicals[#[[1]]], ToRadicals[#[[2]]] /. ell -> logw} & /@ kept;
  expr = Total[(Which[x0 === Infinity, x^(-#[[1]]), x0 === -Infinity, (-x)^(-#[[1]]), True, wexpr^#[[1]]] #[[2]]) & /@ terms];
  sd = makeSeriesData[terms, x, x0, coord, remData, logw];
  PowerLogSeries[<|
    "Kind" -> "Forward",
    "Expression" -> expr,
    "Remainder" -> If[remData === None, 0, PowerLogRemainder[wexpr, ToRadicals[remData[[1]]], remData[[2]]]],
    "RemainderPower" -> If[remData === None, Infinity, ToRadicals[remData[[1]]]],
    "RemainderLogDegree" -> If[remData === None, 0, remData[[2]]],
    "RemainderVariable" -> wexpr,
    "FrontierTerm" -> If[frontier === None, If[P === Infinity, 0, Missing["Unknown"]], wexpr^ToRadicals[frontier[[1]]] (ToRadicals[frontier[[2]]] /. ell -> logw)],
    "Terms" -> terms,
    "TermConvention" -> "Each {beta, C} means w^beta C with w the local variable (x - x0, x0 - x, 1/x or -1/x); logarithms have been substituted.",
    "Blocks" -> kept, "LogVariable" -> ell, "LocalVariable" -> u,
    "Variable" -> x, "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "Cutoff" -> ToRadicals[cutoff], "Precision" -> {P, D},
    "Exact" -> (P === Infinity && omitted === {}),
    "Function" -> f, "Assumptions" -> ass,
    "SeriesData" -> sd|>]];

makeSeriesData[terms_, x_, x0_, coord_, remData_, logw_] := Module[{exps, den, nmin, nmax, coeffs, ptx, dirSign},
  If[coord["Direction"] === "FromBelow" && ! coord["Infinite"], Return[Missing["NotAvailable"], Module]];
  If[x0 === -Infinity, Return[Missing["NotAvailable"], Module]];
  exps = terms[[All, 1]];
  If[! (And @@ (IntegerQ[#] || Head[#] === Rational & /@ exps)), Return[Missing["IrrationalExponents"], Module]];
  If[remData === None, Return[Missing["Exact"], Module]];
  If[! (IntegerQ[remData[[1]]] || Head[remData[[1]]] === Rational), Return[Missing["IrrationalExponents"], Module]];
  den = LCM @@ (Denominator /@ Append[exps, remData[[1]]]);
  nmin = If[exps === {}, remData[[1]] den, Min[exps] den]; nmax = remData[[1]] den;
  coeffs = Table[0, {nmax - nmin}];
  Do[coeffs[[t[[1]] den - nmin + 1]] = t[[2]], {t, terms}];
  SeriesData[x, x0, coeffs, nmin, nmax, den]];

(* ------------------------------------------------------------------ *)
(* Model construction for the inverse                                   *)
(* ------------------------------------------------------------------ *)

rowsToModel[rows0_List, u_, ell_, ass_, symbolic_] := Module[{rows, lead, p, a, y0 = 0, rest, deltas, polys},
  rows = jetMerge[rows0, ell, ass, symbolic];
  If[rows === {}, fail["ZeroFunction", "The function is constant or zero near the expansion point; no inverse branch."]];
  If[symbolic,
   Module[{cands = Select[rows, Function[r, And @@ (TrueQ[Simplify[r[[1]] <= #[[1]], ass]] & /@ rows)]]},
    If[cands === {}, fail["UndecidableLeadingTerm", "No provably least exponent under the assumptions."]];
    lead = First[cands];
    rows = Prepend[DeleteCases[rows, lead], lead]]];
  lead = First[rows];
  If[zeroQ[lead[[1]], ass],
   If[! FreeQ[lead[[2]], ell], fail["LogarithmicLimit", "The function has a logarithmic singularity at the expansion point (leading block Log[u]^k); this is outside the supported class."]];
   y0 = lead[[2]]; rows = Rest[rows];
   If[rows === {}, fail["ZeroFunction", "The function is constant near the expansion point."]];
   If[symbolic,
    Module[{cands = Select[rows, Function[r, And @@ (TrueQ[Simplify[r[[1]] <= #[[1]], ass]] & /@ rows)]]},
     If[cands === {}, fail["UndecidableLeadingTerm", "No provably least nonconstant exponent under the assumptions."]];
     lead = First[cands]; rows = Prepend[DeleteCases[rows, lead], lead]],
    lead = First[rows]]];
  p = lead[[1]]; a = lead[[2]];
  If[! FreeQ[a, ell], fail["LogarithmicLeadingTerm",
    "The leading block a u^p Log[u]^k has a logarithmic factor; such a core needs a Lambert-W coordinate and is not supported by this version."]];
  If[! TrueQ[Simplify[a != 0, ass]], fail["UnprovedNonzeroLeadingCoefficient", "The leading coefficient must be provably nonzero.", <|"Coefficient" -> a|>]];
  If[! TrueQ[Simplify[Element[a, Reals], ass]], fail["UnprovedRealCoefficient", "The leading coefficient must be provably real.", <|"Coefficient" -> a|>]];
  rest = Rest[rows];
  deltas = If[symbolic, Simplify[#[[1]] - p, ass], canon[#[[1]] - p]] & /@ rest;
  polys = polyCanon[#[[2]]/a, ell, ass] & /@ rest;
  Do[If[! (And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@ CoefficientList[q, ell])),
     fail["UnprovedRealCoefficient", "All coefficients must be provably real under the assumptions.", <|"Polynomial" -> q|>]], {q, polys}];
  If[symbolic,
   Do[If[! TrueQ[Simplify[d > 0, ass]], fail["UnprovedPositiveGap", "A power gap could not be proved positive.", <|"Gap" -> d|>]], {d, deltas}]];
  <|"Limit" -> y0, "LeadingCoefficient" -> a, "LeadingPower" -> p, "Gaps" -> deltas,
    "Polynomials" -> polys, "LogVariable" -> ell, "Variable" -> u, "Rows" -> rows, "Symbolic" -> symbolic|>];

(* ------------------------------------------------------------------ *)
(* Multi-index enumeration                                              *)
(* ------------------------------------------------------------------ *)

indexRegion[d_List, W_, inclusive_, limit_] := Module[
  {m = Length[d], inside, nodes = 0, visit, boundary = <||>, ok, add, q, key, indexKey},
  If[m == 0, Return[<|"Inside" -> {{}}, "Boundary" -> {}|>, Module]];
  ok[w_] := If[inclusive, leq[w, W], less[w, W]];
  add[] := (nodes++;
    If[nodes > limit, fail["ResourceLimit", "Multi-index enumeration exceeded MaxTerms.", <|"MaxTerms" -> limit|>]]);
  visit[j_, sofar_, prefix_] := Module[{k = 0},
    If[j > m,
     add[]; Sow[prefix];
     (* Only the outside neighbors can belong to the boundary.  Deduplicate
        them as they are found, without allocating all m times Length[inside]
        neighbors.  Both retained and boundary indices consume the budget. *)
     Do[If[! ok[sofar + d[[h]]],
       q = ReplacePart[prefix, h -> prefix[[h]] + 1]; key = indexKey[q];
       If[! KeyExistsQ[boundary, key], add[]; AssociateTo[boundary, key -> q]]], {h, m}];
     Return[Null, Module]];
    While[ok[sofar + k d[[j]]],
     visit[j + 1, sofar + k d[[j]], Append[prefix, k]];
     k++]];
  inside = Reap[visit[1, 0, {}]][[2]];
  inside = If[inside === {}, {}, First[inside]];
  <|"Inside" -> inside, "Boundary" -> Values[boundary]|>];

depthRegion[m_, N_, limit_] := Module[{visit, indices, count},
  If[m == 0, Return[<|"Inside" -> {{}}, "Boundary" -> {}|>, Module]];
  (* Stars and bars counts the retained simplex and its degree-(N+1) shell.
     Check that count before allocating anything; a surrounding cube is
     exponentially larger than the requested set when there are many gaps. *)
  count = Binomial[N + m + 1, m];
  If[count > limit, fail["ResourceLimit", "Depth enumeration exceeded MaxTerms.",
    <|"MaxTerms" -> limit, "RequiredTerms" -> count|>]];
  visit[j_, remaining_, prefix_] := Module[{k},
    If[j > m, Sow[prefix, If[remaining == 0, "Boundary", "Inside"]]; Return[Null, Module]];
    Do[visit[j + 1, remaining - k, Append[prefix, k]], {k, 0, remaining}]];
  indices = Association[Reap[visit[1, N + 1, {}], _, Rule][[2]]];
  <|"Inside" -> Lookup[indices, "Inside", {}], "Boundary" -> Lookup[indices, "Boundary", {}]|>];

(* ------------------------------------------------------------------ *)
(* Lagrange coefficient for one multi-index                             *)
(* ------------------------------------------------------------------ *)

lagrangeCoefficient[k_List, d_List, polys_List, p_, r_, ell_, ass_, symbolic_] := Module[{n = Total[k], w, q},
  If[n == 0, Return[{0, 1}, Module]];
  w = If[symbolic, Simplify[k . d, ass], canon[k . d]];
  q = Expand[Times @@ MapThread[Power, {polys, k}]];
  Do[q = Expand[D[q, ell] + (r + w + p j) q], {j, 1, n - 1}];
  q = Expand[(-1)^n r q/(p^n (Times @@ (Factorial /@ k)))];
  {w, polyCanon[q, ell, ass]}];

(* ------------------------------------------------------------------ *)
(* Newton engine in the jet algebra                                     *)
(* ------------------------------------------------------------------ *)

modelEquation[U_List, d_List, polys_List, p_, cut_, ell_, ass_, limit_] := Module[{ans, part},
  ans = jetAdd[jetUnitPower[U, p, cut, ell, ass, limit], {{0, -1}}, cut, ell, ass];
  Do[If[less[d[[i]], cut],
    part = jetComposeBlock[U, p + d[[i]], polys[[i]], cut - d[[i]], ell, ass, limit];
    ans = jetAdd[ans, jetShift[part, d[[i]]], cut, ell, ass]], {i, Length[d]}];
  ans];
modelEquationDerivative[U_List, d_List, polys_List, p_, cut_, ell_, ass_, limit_] := Module[{ans, part},
  ans = jetScale[jetUnitPower[U, p - 1, cut, ell, ass, limit], p, ell, ass];
  Do[If[less[d[[i]], cut],
    part = jetComposeBlock[U, p + d[[i]] - 1, Expand[(p + d[[i]]) polys[[i]] + D[polys[[i]], ell]], cut - d[[i]], ell, ass, limit];
    ans = jetAdd[ans, jetShift[part, d[[i]]], cut, ell, ass]], {i, Length[d]}];
  ans];

newtonSolve[d_List, polys_List, p_, cut_, ell_, ass_, limit_] := Module[{U = {}, G, Gp, iter = 0, maxIter},
  If[d === {}, Return[{}, Module]];
  maxIter = Ceiling[Log[2, N[cut/First[Sort[d, leq]]]]] + 3;
  While[True,
   G = modelEquation[U, d, polys, p, cut, ell, ass, limit];
   If[G === {}, Break[]];
   iter++;
   If[iter > maxIter, fail["NewtonFailure", "Newton iteration did not stabilize."]];
   Gp = modelEquationDerivative[U, d, polys, p, cut, ell, ass, limit];
   U = jetAdd[U, jetScale[jetMul[G, jetReciprocalUnit[Gp, cut, ell, ass, limit], cut, ell, ass, limit], -1, ell, ass], cut, ell, ass]];
  U];

(* ------------------------------------------------------------------ *)
(* Inverse expansion: public                                            *)
(* ------------------------------------------------------------------ *)

Options[AsymptoticInverse] = {Assumptions -> True, Direction -> Automatic, Method -> "Lagrange",
  "Power" -> 1, "InputRemainder" -> Automatic, "Truncation" -> "Exponent",
  SeriesTermGoal -> Automatic, "MaxTerms" -> 20000};

AsymptoticInverse[f_, {x_Symbol, x0_}, {y_Symbol, cutoff_}, opts : OptionsPattern[]] := catch[inverseDispatch[f, x, x0, y, cutoff, opts]];
AsymptoticInverse[f_, {x_Symbol, x0_}, y_Symbol, opts : OptionsPattern[]] := catch[inverseDispatch[f, x, x0, y, Automatic, opts]];
AsymptoticInverse[f_, x_Symbol, y_Symbol, opts : OptionsPattern[]] := catch[inverseDispatch[f, x, 0, y, Automatic, opts]];
AsymptoticInverse[___] := Failure["InvalidArguments", <|"MessageTemplate" ->
   "Use AsymptoticInverse[f, {x, x0}, {y, cutoff}] or AsymptoticInverse[f, {x, x0}, y, SeriesTermGoal -> n]."|>];

inverseDispatch[f_, x_, x0_, y_, cutoff_, opts___] := Module[{s},
  s = lambertConstruct[f, x, x0, y, cutoff, opts];
  If[s === $Failed, construct[f, x, x0, y, cutoff, opts], s]];

inverseBlocks[d_, polys_, p_, rint_, H_, method_, ell_, ass_, limit_, region_] := Module[{U, blocks},
  If[method === "Newton",
   U = newtonSolve[d, polys, p, H, ell, ass, limit];
   blocks = jetUnitPower[U, rint, H, ell, ass, limit];
   If[blocks === {} || ! (blocks[[1, 1]] === 0), blocks = jetMerge[Join[{{0, 1}}, blocks], ell, ass]];
   blocks,
   jetMerge[lagrangeCoefficient[#, d, polys, p, rint, ell, ass, False] & /@ region["Inside"], ell, ass]]];

(* Look past finitely many cancelled boundary blocks. A bounded search retains
   the original valid (possibly non-sharp) bound if no nonzero block is found. *)
inverseFrontier[region0_, d_, polys_, p_, rint_, ell_, ass_, limit_] := Module[
  {region = region0, ws, weight, near, poly, first = None, result = None, next, attempt},
  If[d === {} || region["Boundary"] === {}, Return[None, Module]];
  Do[
   ws = canon[# . d] & /@ region["Boundary"];
   weight = First[Sort[ws, leq]];
   near = Pick[region["Boundary"], equal[#, weight] & /@ ws];
   poly = jetMerge[lagrangeCoefficient[#, d, polys, p, rint, ell, ass, False] & /@ near, ell, ass];
   result = {weight, If[poly === {}, 0, poly[[1, 2]]]};
   If[first === None, first = result];
   If[poly =!= {}, Break[]];
   next = Catch[indexRegion[d, weight, True, limit], $tag];
   If[FailureQ[next] || next["Boundary"] === {}, result = first; Break[]];
   region = next,
   {attempt, 8}];
  If[result[[2]] === 0, first, result]];

(* finite power-log parser that tolerates symbolic exponents (used by depth truncation) *)
parseFinite[e_, u_Symbol, ell_Symbol, ass_] := Module[{ex, summands, rows = {}, ok = True},
  ex = Expand[e //. {Log[u^k_] /; FreeQ[k, u] :> k Log[u], Log[c_ u^k_.] /; FreeQ[c, u] && FreeQ[k, u] && TrueQ[Simplify[c > 0, ass]] :> Log[c] + k Log[u]} /. Log[u] -> ell];
  summands = If[Head[ex] === Plus, List @@ ex, {ex}];
  Do[Module[{factors, expo = 0, coef = 1},
    factors = If[Head[term] === Times, List @@ term, {term}];
    Do[Which[
       FreeQ[factor, u], coef = coef factor,
       factor === u, expo += 1,
       MatchQ[factor, Power[u, _]] && FreeQ[factor[[2]], u | ell], expo += factor[[2]],
       True, ok = False], {factor, factors}];
    If[ok && (! PolynomialQ[coef, ell] || ! FreeQ[coef, u]), ok = False];
    If[ok, AppendTo[rows, {expo, coef}]]], {term, summands}];
  If[! ok, $Failed, rows]];

Get[FileNameJoin[{$kernelDirectory, "ExactTermination.wl"}]];

construct[f_, x_, x0_, y_, cutoff0_, opts : OptionsPattern[AsymptoticInverse]] := Module[
  {ass = OptionValue[AsymptoticInverse, {opts}, Assumptions], dir = OptionValue[AsymptoticInverse, {opts}, Direction],
   method = OptionValue[AsymptoticInverse, {opts}, Method], r = OptionValue[AsymptoticInverse, {opts}, "Power"],
   inputRem = OptionValue[AsymptoticInverse, {opts}, "InputRemainder"], trunc = OptionValue[AsymptoticInverse, {opts}, "Truncation"],
   goal = OptionValue[AsymptoticInverse, {opts}, SeriesTermGoal], limit = OptionValue[AsymptoticInverse, {opts}, "MaxTerms"],
   coord, u, ell = Unique["ell$"], fu, jet, rows, model, p, a, d, polys, y0, symbolic, H, cutoff = cutoff0,
   region, blocks, frontier, rem, inputCap, v, z, expr, terms, wexpr, rint, obj, remData, forwardRem, depth, exactModel, Kf, tries, gexpr, logw, need,
   termination = None, terminationTried = Missing["NotTried"], terminationEligible, reliableBlocks},
  validateInput[f, limit];
  If[x === y, fail["InvalidVariables", "Source and target variables must be distinct symbols."]];
  If[! FreeQ[f, y], fail["InvalidVariables", "The forward expression must not contain the target variable."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters only; positivity of the local variable is built in."]];
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  symbolic = (trunc === "Depth");
  If[! MemberQ[{"Exponent", "Depth"}, trunc], fail["InvalidOption", "Truncation must be \"Exponent\" or \"Depth\"."]];
  If[! MemberQ[{"Lagrange", "Newton"}, method], fail["InvalidOption", "Method must be \"Lagrange\" or \"Newton\"."]];
  If[! (NumericQ[r] && exactQ[r] && TrueQ[Simplify[Element[r, Reals]]] && r =!= 0), fail["InvalidOption", "\"Power\" must be a nonzero exact real number."]];
  If[cutoff =!= Automatic && ! symbolic && ! exactRealQ[cutoff], fail["InvalidCutoff", "The cutoff must be an exact real number."]];
  If[cutoff === Automatic && ! (IntegerQ[goal] && goal >= 1), fail["InvalidCutoff", "Give an exponent cutoff or SeriesTermGoal -> n."]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"];
  If[r =!= 1 && coord["Sign"] =!= 1 && ! IntegerQ[r], fail["InvalidOption", "\"Power\" -> r with non-integer r requires a positive local variable (x -> x0 from above or x -> +Infinity)."]];
  rint = If[coord["Infinite"], -r, r];
  terminationEligible = r === 1 && cutoff0 === Automatic && MemberQ[{Automatic, None}, inputRem] && exactTerminationCoreQ[f, x];
  fu = f /. x -> coord["Substitution"];
  (* ---------------- depth truncation with possibly symbolic exponents ---------------- *)
  If[symbolic,
   rows = parseFinite[fu, u, ell, ass];
   If[rows === $Failed, fail["UnsupportedInput", "Depth truncation requires a finite power-log expression."]];
   model = rowsToModel[rows, u, ell, ass, True];
   p = model["LeadingPower"]; a = model["LeadingCoefficient"]; d = model["Gaps"]; polys = model["Polynomials"]; y0 = model["Limit"];
   If[! TrueQ[Simplify[Element[p, Reals], ass]] || ! (provablyPositive[p, ass] || provablyNegative[p, ass]),
    fail["UnprovedLeadingPower", "The leading power must be provably real with a known nonzero sign."]];
   If[method =!= "Lagrange", fail["UnsupportedOption", "Depth truncation uses the Lagrange method."]];
   depth = cutoff; If[cutoff === Automatic, depth = goal];
   If[! IntegerQ[depth] || depth < 0, fail["InvalidCutoff", "Depth truncation needs a nonnegative integer cutoff."]];
   If[! MemberQ[{Automatic, None}, inputRem], fail["UnsupportedOption", "Explicit InputRemainder is currently supported with exponent truncation only."]];
   region = depthRegion[Length[d], depth, limit];
   blocks = jetMerge[lagrangeCoefficient[#, d, polys, p, rint, ell, ass, True] & /@ region["Inside"], ell, ass, True];
   If[Length[blocks] > 1, blocks = Quiet[Check[Sort[blocks, TrueQ[Simplify[#1[[1]] <= #2[[1]], ass]] &], blocks]]];
   frontier = Missing["Depth"]; exactModel = True; forwardRem = None; H = Missing["Depth"];
   remData = If[d === {}, None, {Simplify[(rint + (depth + 1) Min @@ d)/Abs[p], ass], (depth + 1) Max @@ (polyDegree[#, ell] & /@ polys)}],
   (* ---------------- exponent truncation ---------------- *)
   Kf = 2; tries = 0;
   jet = exactJet[fu, u, ell, ass, limit];
   While[True,
    tries++;
    If[jet === $Failed || tries > 1, jet = forwardJet[fu, u, ell, ass, Kf, limit, 0]];
    rows = jet[[1]]; exactModel = (jet[[2]] === Infinity);
    If[! exactModel && (rows === {} || (Length[rows] === 1 && rows[[1, 1]] === 0 && FreeQ[rows[[1, 2]], ell])),
     If[tries >= 12, fail["InsufficientForwardOrder", "No nonconstant leading block was found within the working-order budget."]];
     Kf = Max[Kf + 1, 2 Kf]; Continue[]];
    model = rowsToModel[rows, u, ell, ass, False];
    p = model["LeadingPower"]; a = model["LeadingCoefficient"]; d = model["Gaps"]; polys = model["Polynomials"]; y0 = model["Limit"];
    If[! (NumericQ[p] && exactQ[p]), fail["SymbolicExponent", "The leading power must be an exact number; use \"Truncation\" -> \"Depth\" for symbolic exponents."]];
    If[p === 0, fail["ZeroLeadingPower", "The leading power is zero."]];
    Do[If[! (NumericQ[dd] && exactQ[dd]), fail["SymbolicExponent", "Exponents must be exact numbers; use \"Truncation\" -> \"Depth\" with Assumptions for symbolic exponents.", <|"Exponent" -> dd|>]], {dd, d}];
    If[cutoff === Automatic,
     (* term goal: enlarge the inclusive weight bound until goal blocks are present *)
     Module[{W = 0, count = 0, tries2 = 0, sigmaStar},
      While[True,
       tries2++; If[tries2 > 50 goal + 10, fail["ResourceLimit", "SeriesTermGoal iteration did not terminate."]];
       region = indexRegion[d, W, True, limit];
       blocks = jetMerge[lagrangeCoefficient[#, d, polys, p, rint, ell, ass, False] & /@ region["Inside"], ell, ass];
       count = Length[blocks];
       If[terminationEligible,
        reliableBlocks = If[exactModel, blocks, Select[blocks, less[#[[1]], jet[[2]] - p] &]];
        If[reliableBlocks =!= terminationTried,
         terminationTried = reliableBlocks;
         termination = exactInverseTermination[f, x, x0, coord, model, reliableBlocks, ell, ass];
         If[AssociationQ[termination], blocks = reliableBlocks; Break[]]]];
       If[count >= goal || region["Boundary"] === {}, Break[]];
       sigmaStar = First[Sort[canon[# . d] & /@ region["Boundary"], leq]];
       W = sigmaStar]];
     H = If[AssociationQ[termination] || region["Boundary"] === {}, Infinity, canon[First[Sort[canon[# . d] & /@ region["Boundary"], leq]]]];
     cutoff = If[H === Infinity, Infinity, canon[(rint + H)/Abs[p]]],
     H = canon[Abs[p] cutoff - rint];
     If[! less[0, H], fail["CutoffTooSmall", "The cutoff must exceed the leading exponent r/|p| of the inverse.", <|"LeadingExponent" -> ToRadicals[rint/Abs[p]]|>]]];
    (* u^rint has error O(z^(P-p+rint)); transport includes the observable derivative. *)
    If[exactModel || AssociationQ[termination], Break[]];
    If[tries > 8, fail["InsufficientForwardOrder", "Could not obtain a forward expansion of sufficient order.", <|"Reached" -> ToRadicals[jet[[2]]]|>]];
    If[cutoff === Infinity,
     (* the truncated forward jet has too few blocks for the requested number of terms *)
     Kf = Max[Kf + 1, 2 Kf]; cutoff = cutoff0; Continue[]];
    need = canon[Abs[p] cutoff + p - rint];
    If[! less[jet[[2]], need], Break[]];
    Kf = Max[Kf + 1, Ceiling[need] + 1];
    cutoff = cutoff0];
   forwardRem = If[exactModel, None, {jet[[2]], jet[[3]]}];
   If[! MemberQ[{None, Automatic}, inputRem],
    If[! MatchQ[inputRem, {_, _Integer?NonNegative}] || ! exactRealQ[inputRem[[1]]],
     fail["InvalidOption", "InputRemainder must be None, Automatic or {rho, k} with exact real rho and nonnegative integer k."]];
    forwardRem = If[forwardRem === None, inputRem, combinePrecision[forwardRem, inputRem]]];
   inputCap = If[AssociationQ[termination] || forwardRem === None, None,
     If[! MatchQ[forwardRem, {_, _Integer?NonNegative}], fail["InvalidOption", "\"InputRemainder\" must be None, Automatic or {rho, k}."]];
     If[! less[Last[model["Rows"]][[1]], forwardRem[[1]]], fail["InvalidOption", "The input remainder power must exceed every supplied forward power."]];
     canon[(forwardRem[[1]] - p + rint)/Abs[p]]];
   If[inputCap =!= None && (cutoff === Infinity || less[inputCap, cutoff]),
    If[cutoff0 === Automatic && Length[Select[blocks, less[(rint + #[[1]])/Abs[p], inputCap] &]] >= goal,
     cutoff = inputCap; H = canon[Abs[p] cutoff - rint];
     region = indexRegion[d, H, False, limit];
     blocks = inverseBlocks[d, polys, p, rint, H, method, ell, ass, limit, region],
     fail["InsufficientInputOrder", "The request exceeds the precision transported from the forward remainder.", <|"MaximumCutoff" -> ToRadicals[inputCap]|>]]];
   If[! AssociationQ[termination] && (cutoff0 =!= Automatic || method === "Newton"),
    region = If[H === Infinity, indexRegion[d, 1 + If[d === {}, 0, Max[d]], False, limit], indexRegion[d, H, False, limit]];
    blocks = If[H === Infinity && method === "Newton", inverseBlocks[d, polys, p, rint, 1 + If[d === {}, 0, Max[d]], "Lagrange", ell, ass, limit, region],
      inverseBlocks[d, polys, p, rint, H, method, ell, ass, limit, region]]];
   (* frontier: complete coefficient at the first omitted weight *)
   frontier = If[AssociationQ[termination], None, inverseFrontier[region, d, polys, p, rint, ell, ass, limit]];
   remData = If[frontier === None, None, {canon[(rint + frontier[[1]])/Abs[p]], polyDegree[frontier[[2]], ell]}];
   If[inputCap =!= None,
    remData = Which[remData === None, {inputCap, forwardRem[[2]]},
      less[inputCap, remData[[1]]], {inputCap, forwardRem[[2]]},
      equal[inputCap, remData[[1]]], {remData[[1]], Max[remData[[2]], forwardRem[[2]]]},
      True, remData]]];
  (* ---------------- assemble the expression in y ---------------- *)
  If[! (provablyPositive[a, ass] || provablyNegative[a, ass]), fail["UnprovedSign", "The sign of the leading coefficient must be provable.", <|"Coefficient" -> a|>]];
  If[! symbolic && less[p, 0], y0 = If[provablyPositive[a, ass], Infinity, -Infinity]];
  If[symbolic && TrueQ[Simplify[p < 0, ass]], y0 = If[provablyPositive[a, ass], Infinity, -Infinity]];
  v = If[y0 === Infinity || y0 === -Infinity, y, y - y0];
  wexpr = Which[y0 === Infinity, 1/y, y0 === -Infinity, -1/y, provablyPositive[a, ass], v, True, -v];
  z = (v/a)^(1/p);
  logw = Log[v/a]/p;
  terms = Table[{ToRadicals[If[symbolic, Simplify[(rint + b[[1]])/p, ass], canon[(rint + b[[1]])/p]]], ToRadicals[b[[2]]] /. ell -> logw}, {b, blocks}];
  gexpr = Total[((v/a)^#[[1]] #[[2]]) & /@ terms];
  expr = Which[
    coord["Infinite"], coord["Sign"]^r gexpr,
    r === 1, x0 + coord["Sign"] gexpr,
    True, coord["Sign"]^r gexpr];
  rem = If[remData === None, 0, PowerLogRemainder[wexpr, ToRadicals[remData[[1]]], remData[[2]]]];
  obj = <|
    "Kind" -> "Inverse",
    "Scale" -> "PowerLog",
    "Expression" -> expr,
    "Remainder" -> rem,
    "RemainderPower" -> If[remData === None, Infinity, ToRadicals[remData[[1]]]],
    "RemainderLogDegree" -> If[remData === None, 0, remData[[2]]],
    "RemainderVariable" -> wexpr,
    "FrontierTerm" -> Which[frontier === None, 0, MissingQ[frontier], frontier,
      True, coord["Sign"]^r (v/a)^ToRadicals[canon[(rint + frontier[[1]])/p]] (ToRadicals[frontier[[2]]] /. ell -> logw)],
    "Terms" -> terms,
    "TermConvention" -> "Each {beta, C} means (v/a)^beta C with v = y - y0 (or y when y0 is infinite) and C already containing Log[v/a]/p; the sum is the expansion of (x - x0)^r, of (x0 - x)^r, or of x^r.",
    "Blocks" -> blocks, "LogVariable" -> ell,
    "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "Limit" -> y0, "LeadingCoefficient" -> a, "LeadingPower" -> p,
    "Uniformizer" -> z, "Power" -> r, "Cutoff" -> If[cutoff === Infinity || symbolic, cutoff, ToRadicals[cutoff]],
    "Truncation" -> trunc, "Method" -> method,
    "Model" -> model,
    "ForwardExpansion" -> (model["Limit"] + Total[(coord["LocalVariable"]^ToRadicals[#[[1]]] (ToRadicals[#[[2]]] /. ell -> Log[coord["LocalVariable"]])) & /@ model["Rows"]]),
    "LocalVariable" -> u, "LocalSubstitution" -> (x -> coord["Substitution"]),
    "ExactModel" -> exactModel, "InputRemainder" -> forwardRem,
    "ExactTerminationCertificate" -> termination,
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Length[blocks],
    "Function" -> f, "Assumptions" -> ass,
    "Branch" -> "the inverse tends to the expansion point with " <> ToString[coord["LocalVariable"], InputForm] <> " ~ " <> ToString[z, InputForm],
    "SeriesData" -> makeInverseSeriesData[terms, y, y0, a, coord, remData, r, x0]
    |>;
  PowerLogSeries[obj]];

makeInverseSeriesData[terms_, y_, y0_, a_, coord_, remData_, r_, x0_] := Module[{exps, den, nmin, nmax, coeffs},
  If[r =!= 1 || coord["Sign"] =!= 1 || coord["Infinite"] || x0 =!= 0, Return[Missing["NotAvailable"], Module]];
  If[y0 === Infinity || y0 === -Infinity, Return[Missing["NotAvailable"], Module]];
  exps = terms[[All, 1]];
  If[! (And @@ (IntegerQ[#] || Head[#] === Rational & /@ exps)), Return[Missing["IrrationalExponents"], Module]];
  If[remData === None, Return[Missing["Exact"], Module]];
  If[! (IntegerQ[remData[[1]]] || Head[remData[[1]]] === Rational), Return[Missing["IrrationalExponents"], Module]];
  den = LCM @@ (Denominator /@ Append[exps, remData[[1]]]);
  nmin = Min[exps] den; nmax = remData[[1]] den;
  coeffs = Table[0, {nmax - nmin}];
  Do[coeffs[[t[[1]] den - nmin + 1]] = a^(-t[[1]]) t[[2]], {t, terms}];
  SeriesData[y, y0, coeffs, nmin, nmax, den]];

(* ------------------------------------------------------------------ *)
(* The PowerLogSeries object                                            *)
(* ------------------------------------------------------------------ *)

PowerLogSeries /: Normal[PowerLogSeries[a_Association]] := a["Expression"];
PowerLogSeries[a_Association]["Properties"] := Keys[a];
PowerLogSeries[a_Association][key_String] := Lookup[a, key, Missing["KeyAbsent", key]];
PowerLogSeries[a_Association][val_?NumericQ] := a["Expression"] /. a["Variable"] -> val;
remainderScale[PowerLogRemainder[w_, b_, k_]] := Module[{base, lg},
  {base, lg} = If[MatchQ[w, Power[_, -1]], {w[[1]]^(-b), Log[w[[1]]]}, {w^b, Log[w]}];
  If[k === 0, base, base (1 + Abs[lg])^k]];
PowerLogSeries /: MakeBoxes[PowerLogSeries[a_Association], fmt_] :=
  With[{e = a["Expression"], rm = a["Remainder"]},
   If[rm === 0, RowBox[{"PowerLogSeries", "[", MakeBoxes[e, fmt], "]"}],
    RowBox[{"PowerLogSeries", "[", RowBox[{MakeBoxes[e, fmt], "+", MakeBoxes[rm, fmt]}], "]"}]]];
Format[PowerLogSeries[a_Association], OutputForm] := PowerLogSeries[a["Expression"], a["Remainder"]];
Format[PowerLogSeries[a_Association], InputForm] := PowerLogSeries[a["Expression"], a["Remainder"]];

PowerLogRemainder /: MakeBoxes[r_PowerLogRemainder, fmt_] :=
  With[{sc = remainderScale[r]}, RowBox[{"O", "[", MakeBoxes[sc, fmt], "]"}]];
Format[r_PowerLogRemainder, OutputForm] := With[{sc = remainderScale[r]}, HoldForm[O[sc]]];

(* ------------------------------------------------------------------ *)
(* Residual check                                                       *)
(* ------------------------------------------------------------------ *)

Options[InverseResidual] = {"MaxTerms" -> 200000};
InverseResidual[PowerLogSeries[a_Association], opts : OptionsPattern[]] := catch[residual[a, Automatic, OptionValue["MaxTerms"]]];
InverseResidual[PowerLogSeries[a_Association], h_, opts : OptionsPattern[]] := catch[residual[a, h, OptionValue["MaxTerms"]]];
InverseResidual[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use InverseResidual[expansion] or InverseResidual[expansion, relativeCutoff]."|>];

residual[a_Association, h_, limit_] := Module[{model = a["Model"], blocks = a["Blocks"], ell = a["LogVariable"], ass = a["Assumptions"],
   p, d, polys, r = a["Power"], cut, U, res, y, v, aa, rint},
  If[Lookup[a, "Scale", "PowerLog"] === "Logarithmic", Return[lambertResidual[a, h, limit], Module]];
  If[a["Kind"] =!= "Inverse", fail["Unsupported", "Residuals are computed for inverse expansions only."]];
  If[a["Truncation"] === "Depth", fail["Unsupported", "Residuals are computed for exponent truncation only."]];
  p = model["LeadingPower"]; d = model["Gaps"]; polys = model["Polynomials"]; aa = model["LeadingCoefficient"];
  rint = If[a["ExpansionPoint"] === Infinity || a["ExpansionPoint"] === -Infinity, -r, r];
  cut = If[h === Automatic, If[a["Cutoff"] === Infinity, 1 + If[d === {}, 0, Max[d]], canon[Abs[p] a["Cutoff"] - rint]], h];
  If[! (NumericQ[cut] && exactQ[cut] && less[0, cut]), fail["InvalidCutoff", "The residual cutoff must be a positive exact number."]];
  U = jetTrim[Select[blocks, less[0, #[[1]]] &], cut, ell, ass];
  If[rint =!= 1, U = jetAdd[jetUnitPower[U, 1/rint, cut, ell, ass, limit], {{0, -1}}, cut, ell, ass]];
  res = modelEquation[U, d, polys, p, cut, ell, ass, limit];
  y = a["Variable"];
  v = If[a["Limit"] === Infinity || a["Limit"] === -Infinity, y, y - a["Limit"]];
  <|"ZeroBelowCutoff" -> (res === {}),
    "NormalizedResidual" -> Total[((v/aa)^ToRadicals[canon[#[[1]]/p]] (ToRadicals[#[[2]]] /. ell -> Log[v/aa]/p)) & /@ res],
    "ResidualBlocks" -> res, "RelativeCutoff" -> ToRadicals[cut],
    "Normalization" -> "f(g(y))/(a z^p) - 1 with z the uniformizer; blocks are in z",
    "Scope" -> "Formal composition with the finite forward model only."|>];

(* ------------------------------------------------------------------ *)
(* Numerical check                                                      *)
(* ------------------------------------------------------------------ *)

Options[InverseNumericalCheck] = {WorkingPrecision -> 50};
InverseNumericalCheck[PowerLogSeries[a_Association], yv_, OptionsPattern[]] := catch[Module[
   {wp = OptionValue[WorkingPrecision], x, y = a["Variable"], f = a["Function"], approx, root, err, scale, rm = a["Remainder"], yy, xr, target, local},
   If[a["Kind"] =!= "Inverse", fail["Unsupported", "Numerical checks are for inverse expansions."]];
   If[Lookup[a, "Scale", "PowerLog"] === "Logarithmic", Return[lambertNumericalCheck[a, yv, wp], Module]];
   If[! IntegerQ[wp] || wp < 10, fail["InvalidOption", "WorkingPrecision must be an integer of at least 10 digits."]];
   x = a["Variables"][[1]];
   If[! (NumericQ[yv] && (exactQ[yv] || Precision[yv] >= wp)), fail["InsufficientPrecision", "Supply an exact evaluation point or one with at least WorkingPrecision digits."]];
   If[a["Power"] =!= 1, fail["Unsupported", "Numerical checks are for the inverse itself (\"Power\" -> 1)."]];
   target = If[MemberQ[{Infinity, -Infinity}, a["Limit"]], yv, yv - a["Limit"]]/a["LeadingCoefficient"];
   If[! TrueQ[Im[N[target, wp]] == 0] || ! TrueQ[N[target, wp] > 0],
    fail["OutsideBranch", "The target must be real and lie on the selected side of the limiting value."]];
   yy = N[yv, wp + 10];
   approx = N[a["Expression"] /. y -> yy, wp + 10];
   xr = With[{xv = x, fv = f, yv2 = yy, start = approx, wp2 = wp + 10, pg = wp},
     Quiet[Check[xv /. FindRoot[fv == yv2, {xv, start}, WorkingPrecision -> wp2, AccuracyGoal -> Infinity, PrecisionGoal -> pg, MaxIterations -> 500], $Failed]]];
   If[xr === $Failed || ! NumericQ[xr], fail["RootNotFound", "FindRoot did not converge from the expansion value."]];
   local = Which[a["ExpansionPoint"] === Infinity, 1/xr, a["ExpansionPoint"] === -Infinity, -1/xr,
    a["Direction"] === "FromAbove", xr - a["ExpansionPoint"], True, a["ExpansionPoint"] - xr];
   If[! TrueQ[Im[xr] == 0] || ! TrueQ[local > 0], fail["OutsideBranch", "The numerical root is outside the selected real branch."]];
   err = Abs[xr - approx];
   xr = N[xr, wp]; approx = N[approx, wp]; err = N[err, wp];
   scale = If[rm === 0, 0, N[rm[[1]]^rm[[2]] (1 + Abs[Log[rm[[1]]]])^rm[[3]] /. y -> yy, wp]];
   <|"ExactInverse" -> xr, "Approximation" -> approx, "Error" -> err,
     "RemainderScale" -> scale, "Ratio" -> If[scale === 0, Indeterminate, err/scale],
     "ForwardResidual" -> N[(f /. x -> approx) - yy, wp]|>]];
InverseNumericalCheck[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use InverseNumericalCheck[expansion, yvalue]."|>];

lambertNumericalCheck[a_Association, yv_, wp_] := Module[
  {x = a["Variables"][[1]], y = a["Variable"], yy, approx, xr, local, scale, err, domain, f = a["Function"]},
  If[! IntegerQ[wp] || wp < 10, fail["InvalidOption", "WorkingPrecision must be an integer of at least 10 digits."]];
  If[! NumericQ[yv] || (! exactQ[yv] && Precision[yv] < wp),
   fail["InsufficientPrecision", "Supply an exact evaluation point or one with at least WorkingPrecision digits."]];
  If[a["Power"] =!= 1, fail["Unsupported", "Numerical checks are for the inverse itself (Power -> 1)."]];
  yy = N[yv, wp + 10];
  domain = Lookup[a, "TargetDomain", a["LogarithmicVariable"] > 0] /. y -> yy;
  If[! TrueQ[domain], fail["OutsideBranch", "The target lies outside the real asymptotic branch domain."]];
  approx = N[a["Expression"] /. y -> yy, wp + 10];
  If[! NumericQ[approx] || ! TrueQ[Im[approx] == 0], fail["OutsideBranch", "The expansion is not real at this target."]];
  xr = With[{xv = x, fv = f, yv2 = yy, start = approx, wp2 = wp + 10, pg = wp},
    Quiet[Check[xv /. FindRoot[fv == yv2, {xv, start}, WorkingPrecision -> wp2,
      AccuracyGoal -> Infinity, PrecisionGoal -> pg, MaxIterations -> 500], $Failed]]];
  If[xr === $Failed || ! NumericQ[xr], fail["RootNotFound", "FindRoot did not converge from the expansion value."]];
  local = Which[a["ExpansionPoint"] === Infinity, 1/xr, a["ExpansionPoint"] === -Infinity, -1/xr,
    a["Direction"] === "FromAbove", xr - a["ExpansionPoint"], True, a["ExpansionPoint"] - xr];
  If[! TrueQ[Im[xr] == 0] || ! TrueQ[local > 0], fail["OutsideBranch", "The numerical root is outside the selected real branch."]];
  scale = N[a["RemainderScaleExpression"] /. y -> yy, wp];
  err = N[Abs[xr - approx], wp];
  <|"ExactInverse" -> N[xr, wp], "Approximation" -> N[approx, wp], "Error" -> err,
    "RemainderScale" -> scale, "Ratio" -> If[TrueQ[scale == 0], Indeterminate, err/scale],
    "ForwardResidual" -> N[(f /. x -> approx) - yy, wp],
    "RootResidual" -> N[(f /. x -> xr) - yy, wp]|>];

(* ------------------------------------------------------------------ *)
(* Perturbative (Lagrange-Buermann) formula generator                   *)
(* ------------------------------------------------------------------ *)

PerturbativeInverse[phi_, h_, {x_Symbol, y_Symbol}, n_Integer?NonNegative] := Module[{hy},
  If[x === y || ! FreeQ[h, y], Return[Failure["InvalidVariables", <|"MessageTemplate" -> "Use distinct symbols; h must not contain y."|>]]];
  hy = h /. x -> phi;
  phi + Sum[(-1)^k/k! D[D[phi, y] hy^k, {y, k - 1}], {k, 1, n}]];
PerturbativeInverse[h_, {x_Symbol, y_Symbol}, n_Integer?NonNegative] := PerturbativeInverse[y, h, {x, y}, n];
PerturbativeInverse[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use PerturbativeInverse[phi, h, {x, y}, n] or PerturbativeInverse[h, {x, y}, n]."|>];

(* ------------------------------------------------------------------ *)
(* Model access and single coefficients                                 *)
(* ------------------------------------------------------------------ *)

Options[PowerLogModel] = {Assumptions -> True, Direction -> Automatic, "MaxTerms" -> 20000};
PowerLogModel[f_, {x_Symbol, x0_}, OptionsPattern[]] := catch[Module[{coord, u, ell = Unique["ell$"], jet, ass = OptionValue[Assumptions]},
   validateInput[f, OptionValue["MaxTerms"]];
   coord = localCoordinate[x, x0, OptionValue[Direction]]; u = coord["u"];
   jet = exactJet[f /. x -> coord["Substitution"], u, ell, ass, OptionValue["MaxTerms"]];
   If[jet === $Failed, fail["UnsupportedInput", "The expression is not a finite power-log sum in the local variable."]];
   rowsToModel[jet[[1]], u, ell, ass, False]]];
PowerLogModel[f_, x_Symbol, opts : OptionsPattern[]] := PowerLogModel[f, {x, 0}, opts];

Options[InverseExpansionCoefficient] = {"Power" -> 1};
InverseExpansionCoefficient[model_Association, k_List, OptionsPattern[]] := catch[Module[{r = OptionValue["Power"], c},
   If[Length[k] =!= Length[model["Gaps"]] || ! (And @@ (IntegerQ[#] && # >= 0 & /@ k)),
    fail["InvalidMultiIndex", "Give one nonnegative integer per correction block of the model."]];
   c = lagrangeCoefficient[k, model["Gaps"], model["Polynomials"], model["LeadingPower"], r, model["LogVariable"], True, model["Symbolic"]];
   <|"Weight" -> ToRadicals[c[[1]]], "Exponent" -> ToRadicals[canon[(r + c[[1]])/model["LeadingPower"]]],
     "Coefficient" -> (ToRadicals[c[[2]]] /. model["LogVariable"] -> \[FormalL]),
     "UniformizerExponent" -> ToRadicals[r + c[[1]]],
     "Meaning" -> "(v/a)^Exponent Coefficient[\[FormalL]] with z = (v/a)^(1/p), \[FormalL] = Log[z]"|>]];
InverseExpansionCoefficient[PowerLogSeries[a_Association], k_List, opts : OptionsPattern[]] :=
  If[Lookup[a, "Scale", "PowerLog"] === "Logarithmic",
   Failure["Unsupported", <|"MessageTemplate" -> "Lambert coefficients are listed in the logarithmic expansion's Terms property; they have no power-gap multi-index."|>],
   InverseExpansionCoefficient[a["Model"], k, "Power" -> If[a["ExpansionPoint"] === Infinity || a["ExpansionPoint"] === -Infinity, -a["Power"], a["Power"]], opts]];
InverseExpansionCoefficient[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use InverseExpansionCoefficient[expansion, {k1, k2, ...}]."|>];

(* The logarithmic-scale engine shares the exact jet algebra above. *)
Get[FileNameJoin[{$kernelDirectory, "LambertInverse.wl"}]];

End[];
EndPackage[];
