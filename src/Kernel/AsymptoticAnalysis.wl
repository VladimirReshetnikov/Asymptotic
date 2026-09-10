(* ::Package:: *)
(* AsymptoticAnalysis -- power-log asymptotic expansions of functions and of their
   inverse functions on a real branch (finite endpoints and infinity, real
   exponents, polynomial logarithmic coefficients).

   Written after analysing nine independent reports on Mathematica Stack Exchange
   question 236367 and question "Asymptotic expansion for a function containing
   irrational exponents".  Theory: docs/article/asymptotic-inverse.tex.

   SPDX-License-Identifier: MIT
*)

(* Mathics can evaluate an existing private definition while reading the
   left-hand side of its replacement. Clear implementation definitions before
   a streamed reload so held dispatch patterns are installed from clean state.
   The official Wolfram kernel keeps its established loading behavior. *)
If[StringQ[$Version] && StringContainsQ[$Version, "Mathics"],
  ClearAll["AsymptoticAnalysis`Private`*"]];

BeginPackage["AsymptoticAnalysis`"];

AsymptoticExpansion::usage =
"AsymptoticExpansion[f, {x, x0, cutoff}] gives the power-log asymptotic expansion of f \
as x -> x0 (x0 may be a real number, Infinity or -Infinity) with every block of \
exponent strictly less than cutoff in the local variable (|x - x0| or 1/|x|) retained, \
as a GeneralizedSeries object.
AsymptoticExpansion[f, {x, x0}, SeriesTermGoal -> n] retains the first n nonzero blocks.
AsymptoticExpansion[f, x -> x0, SeriesTermGoal -> n] is equivalent. A unary pure Function \
or unapplied InverseFunction is applied to x before expansion.
For supported Gamma/Barnes G products, ratios, real varying powers and elementary exponential growth, an exact prefactor is extracted; \
the cutoff and term goal apply to the power-log correction bracket.
Increasing Gamma and LogGamma inverses, their admitted affine forms and fixed powers use Scale -> \"GammaInverse\": \
each block is a complete polynomial in 1/Log[CoreInverse] at one power of 1/CoreInverse. \
Increasing BarnesG and LogBarnesG inverses use Scale -> \"BarnesGInverse\", with coefficients polynomial in 1/(Log[CoreInverse]-1). \
Real logarithms of supported positive Gamma products are normalized to LogGamma before ordinary absolute power-log expansion. \
The explicit option \"Backend\" -> \"Series\" or \"Asymptotic\" delegates the original native argument forms and options, \
using the native order convention and preserving the complete native result without asserting a package analytic remainder. \
Automatic retains successful package expansions and uses a compatible native backend for native specifications/options or selected representation failures. \
Native fallback records its own order convention; explicit direction, branch and resource constraints keep the package path. \
\"Backend\" -> \"Package\" selects the existing real expansion engines. See Documentation/UserGuide.md for the domains and contracts.";

AsymptoticExpand::usage =
"AsymptoticExpand[args] is a held alias for AsymptoticExpansion[args], with identical options and order conventions. \
Use \"Backend\" -> \"Series\" or \"Asymptotic\" for explicit native delegation.";

AsymptoticInverse::usage =
"AsymptoticInverse[f, {x, x0}, {y, cutoff}] gives the asymptotic expansion of the real \
branch of the inverse function of f near x = x0 (x0 may be a real number, Infinity or \
-Infinity) as a GeneralizedSeries object in y. For ordinary power-log results, every complete \
block with exponent strictly less than cutoff in the positive target coordinate recorded \
in s[\"RemainderVariable\"] is retained; this coordinate includes the target limit and selected sign.
AsymptoticInverse[f, {x, x0}, y, SeriesTermGoal -> n] retains the first n nonzero blocks.
Recognized leading-logarithmic and exponential cores return Scale -> \"Logarithmic\": \
the cutoff and term count apply to the unit bracket after extracting Prefactor, in \
the positive inverse-logarithmic variable LogarithmicVariable. See Documentation/UserGuide.md \
for this scale's branch and remainder conventions.
Gamma and LogGamma at a source infinity with Gamma argument tending to positive infinity use Scale -> \"GammaInverse\". \
BarnesG, LogBarnesG and the positive-real Log[BarnesG] use Scale -> \"BarnesGInverse\", with an exact Lambert core for the Barnes argument minus one. \
The cutoff is exclusive in 1/CoreInverse and the term goal counts complete polynomial inverse-logarithmic blocks. \
Power specifies a fixed real source observable, with integer powers required on negative source branches.";

GeneralizedSeries::usage =
"GeneralizedSeries[assoc] represents a generalized asymptotic expansion together with its \
remainder and provenance. StandardForm and TraditionalForm display an analytic finite expression \
and remainder, or the stored native result, without the GeneralizedSeries head. InputForm retains \
the complete object. Normal[s] returns the stored Expression. For native results, \
Expression is Normal[NativeResult] computed during construction and may contain an infinite sum \
or unresolved expression. s[\"Properties\"] lists stored keys; an absent s[\"key\"] returns \
Missing[\"KeyAbsent\", \"key\"]. s[value] substitutes a numerical value into the stored expression \
when its expansion variable is identified; this evaluation does not certify the domain or an error bound. \
A native formal order or asymptotic output does not establish an analytic remainder or exactness.";

PowerLogRemainder::usage =
"PowerLogRemainder[w, beta, k] is an inert descriptor of the remainder class \
O[w^beta (1 + Abs[Log[w]])^k] as w -> 0+.";

InverseResidual::usage =
"InverseResidual[s] composes the forward model with the truncated inverse in the exact \
power-log jet algebra and returns a report association containing the normalized residual \
(f(g(y)) - y0)/(a z^p) - 1 below the residual cutoff, where y0 is the finite target offset (zero at an infinite target), together with its cutoff, offset and scope. \
InverseResidual[s, h] uses the relative cutoff h in the uniformizer.
For GammaInverse with Power -> 1, it checks the finite Stirling residual normalized by CoreInverse Log[CoreInverse], \
reporting the separate forward-model error and the exact logarithmic equation residual expression. \
BarnesGInverse uses CoreInverse^2 CoreLogExpression and a finite Barnes logarithmic model.";

InverseNumericalCheck::usage =
"InverseNumericalCheck[s, y1] solves f(x) = y1 numerically on the selected branch and \
returns an association comparing the truncated expansion with the requested source observable \
of a high-precision reference root at y = y1. ReferenceRoot records the root; \
ReferenceObservable records the observable selected by Power and compared with the approximation. \
This comparison is numerical evidence, not an interval certificate.";

InverseCertificate::usage = "InverseCertificate[s,y1,\"Interval\"->{lo,hi}] proves a unique root enclosure by exact rational interval arithmetic and explicit elementary-function tail bounds. TargetError requests adaptive absolute accuracy; a rational Center may be fixed explicitly. WorkingPrecision controls numerical seed selection and planning of the automatic initial enclosure order; certified bounds use exact enclosure arithmetic.";

PerturbativeInverse::usage =
"PerturbativeInverse[phi, h, {x, y}, n] gives the Lagrange-Buermann expansion \
phi(y) + Sum[(-1)^N/N! D^(N-1)[phi'(y) h(phi(y))^N], {N, 1, n}] of the solution x of \
F0(x) + h(x) == y, where phi is the inverse of the core F0. PerturbativeInverse[h, {x, y}, n] \
uses the identity core. It is a formula generator; no asymptotic ordering is asserted.";

InverseExpansionCoefficient::usage =
"InverseExpansionCoefficient[s, {k1, k2, ...}] returns an association describing the exact \
contribution of one ordinary inverse multi-index, including its logarithmic-polynomial \
Coefficient and weight metadata. A PowerLogModel association may replace s. Several \
multi-index contributions may belong to the same complete block.";

PowerLogModel::usage =
"PowerLogModel[f, {x, x0}] parses f near x0 into the normalized model \
y0 + a u^p (1 + Sum[u^delta_i B_i[Log[u]]]) in the local variable u and returns an Association.";

SeriesAdd::usage = "SeriesAdd[s,t] adds compatible expansion objects, transporting both remainders. A regular real expression may replace either operand. Ordinary s+t also normalizes automatically.";
SeriesMultiply::usage = "SeriesMultiply[s,t] multiplies compatible expansion objects, transporting both remainders. A regular real expression may replace either operand. Ordinary s t also normalizes automatically.";
SeriesPower::usage = "SeriesPower[s,r] expands a real power with a proved branch and a transported remainder; SeriesPower[s,r,h] uses cutoff h.";
SeriesLog::usage = "SeriesLog[s] expands the real logarithm of an eventually positive expansion; SeriesLog[s,h] uses cutoff h.";
SeriesExp::usage = "SeriesExp[s] exponentiates an expansion with an absolute remainder tending to zero, retaining any unbounded exponential prefactor exactly; SeriesExp[s,h] uses cutoff h.";
SeriesCompose::usage = "SeriesCompose[outer,inner] composes compatible expansion objects and transports the outer and inner remainders.";
SeriesObservable::usage = "SeriesObservable[s,expr,z] applies a supported real expression expr in z to the expansion s, transporting its input remainder. Generic unary Taylor expansions require the complete inner argument to be provably real and enough Taylor information on the selected approach. Exact point values and supported one-sided limits are distinguished; the input remainder and available Taylor order limit output precision.";
SeriesTruncate::usage = "SeriesTruncate[s,h] discards complete blocks at or above the exclusive cutoff h, retaining a valid remainder.";
SeriesRefine::usage = "SeriesRefine[s,h] extends a compatible retained inverse computation or replays its source or operation recipe at cutoff h. A request association with AdditionalBlocks asks for more complete ordinary blocks; Target with TargetError or RelativeError and Interval returns a numerical certificate. RefinementStatistics records reused and new work; precision never improves without source evidence.";
SeriesDifferentiate::usage = "SeriesDifferentiate[s,n] differentiates n times when matching remainder derivative bounds are known. RemainderDerivativeOrder declares such bounds; a magnitude Big-O bound alone is insufficient.";

Begin["`Private`"];

$kernelDirectory = DirectoryName[$InputFileName];

(* Bind evaluator adapters only when loading in Mathics. The official Wolfram
   kernel continues to resolve every existing definition to System` symbols. *)
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsCompatibility.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsTimeBudget.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsCalls.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsAlgebra.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsAssumptions.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsTaylor.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsSimplification.wl"}]]];

(* ------------------------------------------------------------------ *)
(* Failure handling                                                     *)
(* ------------------------------------------------------------------ *)

$tag = "AsymptoticAnalysisFailure";
fail[tag_String, msg_String, extra_Association : <||>] :=
  Throw[Failure[tag, Join[<|"MessageTemplate" -> msg|>, extra]], $tag];
SetAttributes[catch, HoldAll];
(* Capture the caller context once per public request. Internal proofs use
   explicit retained hypotheses; later Assuming scopes must not specialize
   an existing result without recording the new restrictions. Nested soft
   probes and constructor replay share the original request boundary. *)
$assumptionScopeActive = False;
$entryAssumptions = True;
catch[body_] := If[TrueQ[$assumptionScopeActive],
  Block[{$Assumptions = True}, Catch[body, $tag]],
  Block[{$assumptionScopeActive = True, $entryAssumptions = $Assumptions,
    $Assumptions = True}, Catch[body, $tag]]];

(* Resolve delayed constructor defaults in the captured caller context.
   Explicit options replace that default. Only option resolution sees the
   ambient context; simplifying stored predicates under themselves loses it. *)
optionAssumptions[public_, rules_List] :=
  Block[{$Assumptions = If[TrueQ[$assumptionScopeActive], $entryAssumptions, $Assumptions]},
    OptionValue[public, rules, Assumptions]];

(* OptionsPattern admits nested lists and both immediate and delayed rules.
   Once resolved, never forward a delayed assumption into another engine. *)
withoutAssumptions[rules_List] := DeleteCases[Flatten[rules],
  HoldPattern[(Assumptions -> _) | (Assumptions :> _)]];
withAssumptions[rules_List, ass_] := Prepend[withoutAssumptions[rules], Assumptions -> ass];

(* ------------------------------------------------------------------ *)
(* Exact numbers: canonical forms, comparison, zero tests               *)
(* ------------------------------------------------------------------ *)

exactQ[e_] := FreeQ[e, _Real | _Complex];
(* A finite numerical value. Wolfram already excludes Indeterminate and
   infinities from NumericQ; Mathics does not, and a realness test on an
   Indeterminate value aborts its evaluator, so exclude them explicitly. *)
finiteNumericQ[e_] := NumericQ[e] && FreeQ[e, Indeterminate | ComplexInfinity | _DirectedInfinity | Undefined];
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
   If[Quiet[TrueQ[a < b], {Less::meprec}], Return[-1, Module]];
   If[Quiet[TrueQ[a > b], {Greater::meprec}], Return[1, Module]]];
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

(* Exact logarithms of integers and rationals are written over prime
   factors so that Log[4] and 2 Log[2] cancel. Factoring is bounded: an
   argument above 10^30 that is not prime is divided by the primes below
   1000 and its remaining cofactor stays an opaque Log[m], since a general
   factorization of a 300-digit composite need not finish (P05). Equal
   opaque cofactors still cancel structurally; Log[p q] with two large
   primes does not reduce to Log[p] + Log[q] under this budget. *)
$logCanonSmallPrimes = Select[Range[2, 1000], PrimeQ];
$logCanonFactorBound = 10^30;
logCanonFactor[n_Integer] := Module[{m = Abs[n], factors = {}, k},
  If[n < 0, factors = {{-1, 1}}];
  If[m <= 1, Return[factors, Module]];
  If[m <= $logCanonFactorBound, Return[Join[factors, FactorInteger[m]], Module]];
  If[PrimeQ[m], Return[Append[factors, {m, 1}], Module]];
  Do[If[Mod[m, p] === 0, k = 0; While[Mod[m, p] === 0, m = Quotient[m, p]; k++]; AppendTo[factors, {p, k}]],
    {p, $logCanonSmallPrimes}];
  Which[m === 1, factors,
   m <= $logCanonFactorBound, Join[factors, FactorInteger[m]],
   True, Append[factors, {m, 1}]]];
logCanonInteger[n_Integer] := Total[(#[[2]] Log[#[[1]]]) & /@ logCanonFactor[n]];
logCanon[e_] := e /. Log[r_Rational] :> logCanonInteger[Numerator[r]] - logCanonInteger[Denominator[r]] /.
   Log[n_Integer] /; n > 1 :> logCanonInteger[n];

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
polyCanonicalZeroQ[p_, ell_, ass_] :=
  p === 0 || (PolynomialQ[p, ell] && And @@ (zeroQ[#, ass] & /@ CoefficientList[p, ell]));
polyZeroQ[q_, ell_, ass_] := polyCanonicalZeroQ[polyCanon[q, ell, ass], ell, ass];
polyDegree[q_, ell_] := If[q === 0, 0, Exponent[q, ell]];

realPolynomialCondition[p_, ell_, ass_] := Module[{condition},
  condition = Simplify[And @@ (Element[#, Reals] & /@ CoefficientList[p, ell]), ass];
  If[condition === True || condition === False, condition,
    TimeConstrained[FullSimplify[condition, ass], 1, condition]]];
realPolynomialQ[p_, ell_, ass_] := PolynomialQ[p, ell] &&
  TrueQ[realPolynomialCondition[p, ell, ass]];

(* Validate complete coefficients at representation boundaries. Internal
   summands, Taylor coefficients and native phases may be complex and cancel;
   checking them before collection would reject real final expressions. *)
realCoefficientRows[rows0_List, ell_, ass_, symbolic_: False] := Module[{rows, condition},
  rows = jetMerge[rows0, ell, ass, symbolic];
  Do[
   If[! PolynomialQ[row[[2]], ell],
    fail["UnsupportedCoefficient", "Logarithmic coefficients must be polynomials.", <|"Coefficient" -> row[[2]]|>]];
   condition = realPolynomialCondition[row[[2]], ell, ass];
   If[! TrueQ[condition],
    fail["UnprovedRealCoefficient", "Every collected coefficient must be provably real under the recorded assumptions.",
     <|"Polynomial" -> row[[2]], "Weight" -> row[[1]], "Condition" -> condition,
       "Realness" -> If[condition === False, "Nonreal", "Unproved"], "Assumptions" -> ass|>]],
   {row, rows}];
  rows];

(* ------------------------------------------------------------------ *)
(* Sparse power-log jets: lists of {weight, polynomial in ell}          *)
(* ------------------------------------------------------------------ *)

(* Canonical expression trees need not identify equal exact real weights.
   First bucket identical keys, then sort representatives and join adjacent
   proved-equal buckets. Only the m structural representatives are sorted;
   at most m-1 adjacent equality checks are needed, without all-pairs proofs.
   Callers canonicalize weights and normalize coefficients in their own
   algebra; a failed order proof retains the existing UndecidableOrder exit. *)
orderedWeightGroups[rows_List] := Module[{groups},
  groups = GatherBy[rows, First];
  If[Length[groups] < 2, Return[groups, Module]];
  groups = Sort[groups, less[#1[[1, 1]], #2[[1, 1]]] &];
  Flatten[#, 1] & /@ Split[groups, equal[#1[[1, 1]], #2[[1, 1]]] &]];

jetMerge[terms_List, ell_, ass_, symbolic_: False] := Module[{groups, out},
  If[terms === {}, Return[{}, Module]];
  If[symbolic,
   out = {};
   Do[Module[{pos},
     pos = FirstPosition[out, {w_, _} /; symbolicEqualQ[w, t[[1]], ass], Missing[], {1}, Heads -> False];
     If[MissingQ[pos], AppendTo[out, {t[[1]], t[[2]]}],
      out[[pos[[1]], 2]] = out[[pos[[1]], 2]] + t[[2]]]], {t, terms}];
   out = {#[[1]], polyCanon[#[[2]], ell, ass]} & /@ out;
   Return[Select[out, ! polyCanonicalZeroQ[#[[2]], ell, ass] &], Module]];
  groups = GatherBy[{canon[#[[1]]], #[[2]]} & /@ terms, First];
  out = {#[[1, 1]], polyCanon[Total[#[[All, 2]]], ell, ass]} & /@ groups;
  out = Select[out, ! polyCanonicalZeroQ[#[[2]], ell, ass] &];
  (* Preserve cheap structural cancellation before requiring cross-weight
     order proofs, and only recanonicalize coefficients that actually merge. *)
  groups = orderedWeightGroups[out];
  out = If[Length[#] === 1, First[#],
    {#[[1, 1]], polyCanon[Total[#[[All, 2]]], ell, ass]}] & /@ groups;
  Select[out, ! polyCanonicalZeroQ[#[[2]], ell, ass] &]];

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
   (* The recurrence is homogeneous: a zero coefficient stays zero. *)
   If[polyZeroQ[Q, ell, ass], Break[]];
   pw = jetMul[pw, u, cut, ell, ass, limit];
   If[pw === {}, Break[]];
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
(* Canonical jets have distinct increasing weights. Walk opposite ends to
   find every product on the boundary without inspecting the full rectangle. *)
jetProductBoundaryDegree[u_List, v_List, weight_, ell_] := Module[{i = 1, j = Length[v], degree = 0},
  While[i <= Length[u] && j > 0,
   Switch[compare[u[[i, 1]] + v[[j, 1]], weight],
    -1, i++, 1, j--,
    0, degree = Max[degree, polyDegree[u[[i, 2]], ell] + polyDegree[v[[j, 2]], ell]]; i++; j--]];
  degree];
pMul[{T1_, P1_, D1_}, {T2_, P2_, D2_}, ell_, ass_, limit_] := Module[{v1, v2, e1, e2, pd},
  If[P1 === Infinity && P2 === Infinity, Return[{jetMul[T1, T2, Infinity, ell, ass, limit], Infinity, 0}, Module]];
  v1 = If[T1 === {}, P1, jetValuation[T1]]; e1 = If[T1 === {}, D1, jetLeadingDegree[T1, ell]];
  v2 = If[T2 === {}, P2, jetValuation[T2]]; e2 = If[T2 === {}, D2, jetLeadingDegree[T2, ell]];
  pd = combinePrecision[{If[P1 === Infinity, Infinity, P1 + v2], D1 + e2}, {If[P2 === Infinity, Infinity, P2 + v1], D2 + e1}];
  If[pd[[1]] =!= Infinity, pd[[2]] = Max[pd[[2]], jetProductBoundaryDegree[T1, T2, pd[[1]], ell]]];
  {jetMul[T1, T2, pd[[1]], ell, ass, limit], pd[[1]], pd[[2]]}];
(* Drop the rows of a jet at or above a working cutoff; the precision
   becomes the least omitted weight with its logarithmic degree, so an
   exact operand truncated inside a computation keeps a valid remainder. *)
pTrimTo[{T_, P_, D_}, cut_, ell_, ass_] := Module[{omitted},
  If[cut === Infinity || ! less[cut, P], Return[{T, P, D}, Module]];
  omitted = Select[T, ! less[#[[1]], cut] &];
  If[omitted === {}, Return[{T, P, D}, Module]];
  {jetTrim[T, cut, ell, ass], Sequence @@ combinePrecision[{P, D}, {omitted[[1, 1]], polyDegree[omitted[[1, 2]], ell]}]}];
pIntegerPower[j_, n_Integer?NonNegative, ell_, ass_, limit_, cut_: Infinity] := Module[{r = pConst[1, ell, ass], b = pTrimTo[j, cut, ell, ass], k = n},
  (* Binary powering also preserves the precision propagation of pMul.
     Every intermediate product is trimmed to the working cutoff, so an
     exact many-term operand is never expanded to a degree the request
     discards (P01); with an infinite cutoff exact operands stay exact. *)
  While[k > 0,
   If[OddQ[k], r = pTrimTo[pMul[r, b, ell, ass, limit], cut, ell, ass]];
   k = Quotient[k, 2];
   If[k > 0, b = pTrimTo[pMul[b, b, ell, ass, limit], cut, ell, ass]]];
  r];

(* tail bound of a unit series truncated at relative weight cut, with argument U known to relative precision {PU, DU} *)
unitSeriesPrecision[U_List, PU_, DU_, cut_, ell_] := Module[{c = minOf[PU, cut], Nn, d},
  If[U === {}, Return[{PU, DU}, Module]];
  If[c === Infinity, Return[{Infinity, 0}, Module]];
  Nn = Ceiling[canon[c/jetValuation[U]]];
  d = jetMaxDegree[U, ell];
  (* Discarded Taylor products still contribute at an input-limited frontier. *)
  If[less[cut, PU], {c, Nn d}, {c, Max[Nn d, DU]}]];

(* generic unit-series application: f(1+U) or f(c0+U) via coefficient generator *)
pUnitSeries[U_List, PU_, DU_, cf_, cut_, ell_, ass_, limit_] := Module[{pd, T},
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

fwd[e_, u_, ell_, ass_, Kw_, limit_] := Module[{h = Head[e], parameterized},
  If[Length[e] > 1 && ! MemberQ[{Plus, Times, Power}, h] && ! FreeQ[e, u],
    parameterized = specialParameterizedForwardJet[e, u, ell, ass, Kw, limit];
    If[MatchQ[parameterized, {_List, _, _}], Return[parameterized, Module]]];
  Which[
   inverseFunctionApplicationQ[e], inverseFunctionForwardJet[e, u, ell, ass, Kw, limit],
   FreeQ[e, u], pConst[e, ell, ass],
   e === u, pVar,
   h === LogBarnesG,
     If[! inverseFunctionEventually[e[[1]] > 0, u, ass],
       fail["UnsupportedBarnesArgument", "The logarithmic Barnes expansion requires an eventually positive argument."]];
     barnesLogJet[e[[1]], u, ell, ass, Kw, limit],
   h === barnesLog, barnesLogJet[e[[1]], u, ell, ass, Kw, limit],
   h === Plus, Fold[pAdd[#1, fwd[#2, u, ell, ass, Kw, limit], ell, ass] &, pConst[0, ell, ass], List @@ e],
   h === Times, Fold[pMul[#1, fwd[#2, u, ell, ass, Kw, limit], ell, ass, limit] &, pConst[1, ell, ass], List @@ e],
   h === Power && e[[1]] === E, fwdExp[fwd[e[[2]], u, ell, ass, Kw, limit], u, ell, ass, Kw, limit],
   h === Power && FreeQ[e[[2]], u], fwdPower[fwd[e[[1]], u, ell, ass, Kw, limit], e[[2]], u, ell, ass, Kw, limit],
   h === Power, fwdExp[pMul[fwd[e[[2]], u, ell, ass, Kw, limit], fwdLog[fwd[e[[1]], u, ell, ass, Kw, limit], u, ell, ass, Kw, limit], ell, ass, limit], u, ell, ass, Kw, limit],
   h === Log && Length[e] == 1, fwdLog[fwd[e[[1]], u, ell, ass, Kw, limit], u, ell, ass, Kw, limit],
   h === Log && Length[e] == 2, fwd[Log[e[[2]]]/Log[e[[1]]], u, ell, ass, Kw, limit],
   h === Exp, fwdExp[fwd[e[[1]], u, ell, ass, Kw, limit], u, ell, ass, Kw, limit],
   h === Sqrt, fwdPower[fwd[e[[1]], u, ell, ass, Kw, limit], 1/2, u, ell, ass, Kw, limit],
   h === Abs, fwdAbs[fwd[e[[1]], u, ell, ass, Kw, limit], ell, ass, u, Kw, limit],
   Length[e] == 1, fwdAnalytic[h, fwd[e[[1]], u, ell, ass, Kw, limit], e, u, ell, ass, Kw, limit],
   True, fwdSeries[e, u, ell, ass, Kw, limit]]];

(* |F| for a power-log jet F = T + O(w^P M^D) on the real coordinate w.

   When every retained coefficient polynomial is provably real, the eventual
   sign of the leading block gives |T| = +-T, and the reverse triangle
   inequality ||F| - |T|| <= |F - T| carries the remainder unchanged. That
   sign rule is false for a jet with nonreal coefficients even when its
   leading coefficient is positive: |1 + a w| + |1 - a w| - 2 under a^2 == -1
   is 2 Sqrt[1 + w^2] - 2, not 0, and the imaginary parts cancel so the wrong
   result even looks real (wave-5 report 37 F01 and retired reports 40, 41).
   Such a jet is handled on the real coordinate by the norm square
   Q = T Conjugate[T], whose blocks are real by construction, followed by the
   positive square root; a nonconstant logarithmic leading block leaves the
   power-log scale and is refused by that root. A remainder consumed by the
   modulus keeps its magnitude bound only, which the flag below reports so
   consumers drop any classical derivative contract (report 42 N01). *)
$absorbedAbsRemainder = False;
fwdAbs[j : {T_, P_, D_}, ell_, ass_, u_: None, Kw_: Infinity, limit_: 20000] := Module[
  {q, c, degree, conjugate, square},
  If[P =!= Infinity, $absorbedAbsRemainder = True];
  If[T === {}, Return[j, Module]];
  If[And @@ (TrueQ[realPolynomialCondition[#[[2]], ell, ass]] & /@ T),
   q = T[[1, 2]]; degree = polyDegree[q, ell];
   c = (-1)^degree Coefficient[q, ell, degree];
   Return[Which[provablyPositive[c, ass], j, provablyNegative[c, ass], pScale[j, -1, ell, ass],
     True, fail["UnprovedSign", "The eventual sign of the absolute-value argument could not be proved."]], Module]];
  conjugate = {{#[[1]], coefficientConjugate[#[[2]], ell, ass]} & /@ T, P, D};
  square = pMul[j, conjugate, ell, ass, limit];
  square = {{#[[1]], coefficientConjugateCanon[#[[2]], ell, ass]} & /@ square[[1]], square[[2]], square[[3]]};
  fwdPower[square, 1/2, u, ell, ass, Kw, limit]];

(* Coefficientwise conjugation of a polynomial in the real logarithm ell,
   and the canonical real forms Wolfram gives z + Conjugate[z] -> 2 Re[z]
   and z Conjugate[z] -> Abs[z]^2, which the realness checks recognize. *)
coefficientConjugate[p_, ell_, ass_] := Module[{k},
  Sum[Simplify[Conjugate[Coefficient[p, ell, k]], ass] ell^k, {k, 0, polyDegree[p, ell]}]];
coefficientConjugateCanon[p_, ell_, ass_] := Module[{k},
  Sum[TimeConstrained[FullSimplify[Coefficient[p, ell, k], ass], 2, Coefficient[p, ell, k]] ell^k,
    {k, 0, polyDegree[p, ell]}]];

fwdPower[{T_, P_, D_}, r_, u_, ell_, ass_, Kw_, limit_] := Module[{alpha, Q, c, U, PU, DU, cutRel, res, rr},
  If[! (NumericQ[r] && exactQ[r]), fail["SymbolicExponent", "Exponents must be exact numbers.", <|"Exponent" -> r|>]];
  If[! TrueQ[Simplify[Element[r, Reals]]], fail["ComplexExponent", "Only real exponents are supported.", <|"Exponent" -> r|>]];
  rr = If[algebraicRealQ[r], RootReduce[r], r];
  (* F^0 = 1 only where F is nonzero. A pure remainder gives no such proof,
     and a symbolic leading coefficient must be proved nonzero on the
     parameter domain: a x with only a real vanishes identically at a = 0
     (wave-5 report 37 F02). *)
  If[rr === 0,
   If[T === {}, fail["IndeterminatePower", "A zeroth power requires a known nonzero leading term."]];
   If[! TrueQ[Simplify[Coefficient[T[[1, 2]], ell, polyDegree[T[[1, 2]], ell]] != 0, ass]],
    fail["UnprovedNonvanishing", "A zeroth power requires the leading coefficient to be provably nonzero on the parameter domain.",
     <|"Coefficient" -> T[[1, 2]], "Assumptions" -> ass|>]]];
  If[IntegerQ[rr] && rr >= 0, Return[pIntegerPower[{T, P, D}, rr, ell, ass, limit, Kw], Module]];
  If[T === {},
   If[P =!= Infinity && ! IntegerQ[rr],
    fail["UnknownLeadingTerm", "A pure remainder does not establish the real branch required by a noninteger power."]];
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
  If[! MatchQ[s, _SeriesData] || ! FreeQ[s[[3]], t] || ! less[N0, s[[5]]/s[[6]]],
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
   rho = nativeSeriesTailPrecision[s][[1]];
   pd = {canon[rho jetValuation[U]], Max[0, Ceiling[rho jetLeadingDegree[U, ell]]]};
   Return[pAdd[res, {{}, pd[[1]], pd[[2]]}, ell, ass], Module]];
  If[sign === -1, U = jetScale[U, -1, ell, ass]];
  coeffs = s[[3]]; nmin = s[[4]];
  c0 = If[nmin <= 0 && Length[coeffs] >= 1 - nmin, coeffs[[1 - nmin]], 0];
  cf = Function[j, If[j >= nmin && j - nmin + 1 <= Length[coeffs], coeffs[[j - nmin + 1]], If[j < nmin, 0, Null]]];
  If[U === {}, Return[{jetMerge[{{0, c0}}, ell, ass], P, D}, Module]];
  res = pUnitSeries[U, P, D, cf, Kw, ell, ass, limit];
  {jetAdd[jetMerge[{{0, c0}}, ell, ass], res[[1]], res[[2]], ell, ass], res[[2]], res[[3]]}];

(* Native formal order alone does not specify an analytic logarithmic degree.
   Under the admitted finite-logarithmic tail contract, a half lattice step
   absorbs any fixed degree. Retained coefficient degrees do not prove that
   contract or determine the unknown degree. Shared by both native importers. *)
nativeSeriesTailPrecision[sd_SeriesData] := {(sd[[5]] - 1/2)/sd[[6]], 0};

nativePowerLogSeries[s_, u_, ell_, ass_, Kw_, limit_] := Module[
  {parts, sd, rest, rows = {}, extra, pd},
  If[Head[s] === Series || (Head[s] =!= SeriesData && FreeQ[s, SeriesData]),
   fail["UnsupportedInput", "The native result is not a resolved power-log series."]];
  parts = If[Head[s] === Plus, List @@ s, {s}];
  sd = Select[parts, Head[#] === SeriesData &];
  rest = Select[parts, Head[#] =!= SeriesData &];
  If[Length[sd] =!= 1 || ! (sd[[1, 1]] === u && sd[[1, 2]] === 0) ||
      ! IntegerQ[sd[[1, 6]]] || sd[[1, 6]] < 1 || ! FreeQ[rest, _SeriesData | _Series],
    fail["UnsupportedInput", "The native series must use the recorded positive local variable at zero and a supported power-log form."]];
  sd = First[sd];
  Do[If[! zeroQ[sd[[3, i]], ass],
    Module[{cj = fwd[sd[[3, i]] /. Log[u] -> ell, u, ell, ass, Infinity, limit]},
     If[cj[[2]] =!= Infinity, fail["UnsupportedInput", "A Series coefficient is not a finite power-log expression.", <|"Coefficient" -> sd[[3, i]]|>]];
     rows = Join[rows, jetShift[cj[[1]], (sd[[4]] + i - 1)/sd[[6]]]]]],
   {i, Length[sd[[3]]]}];
  pd = nativeSeriesTailPrecision[sd];
  extra = If[rest === {}, pConst[0, ell, ass], fwd[Total[rest], u, ell, ass, Kw, limit]];
  pAdd[{jetMerge[rows, ell, ass], pd[[1]], pd[[2]]}, extra, ell, ass]];

(* Reconcile whole normalized probes, including their regular summands and
   coefficient power shifts. Only a strictly better, compatible second probe
   may sharpen the first error. No observed coefficient means an unknown tail,
   not exactness or a log-free bound at the second native endpoint. *)
nativeRefineSeriesTail[first_, second_, ell_, ass_] := Module[{delta, pd},
  If[! less[first[[2]], second[[2]]], Return[first, Module]];
  delta = jetAdd[second[[1]], jetScale[first[[1]], -1, ell, ass], second[[2]], ell, ass];
  If[delta =!= {} && less[delta[[1, 1]], first[[2]]], Return[first, Module]];
  pd = If[delta === {}, Rest[second],
    combinePrecision[{delta[[1, 1]], polyDegree[delta[[1, 2]], ell]}, Rest[second]]];
  If[less[pd[[1]], first[[2]]] ||
      (equal[pd[[1]], first[[2]]] && pd[[2]] > first[[3]]), Return[first, Module]];
  {first[[1]], pd[[1]], pd[[2]]}];

(* The optional extra native probe supplies evidence, never a guessed degree. *)
fwdSeries[e_, u_, ell_, ass_, Kw_, limit_] := Module[{order, s, first, s2, second},
  If[Kw === Infinity, fail["InfiniteSeries", "The expression is not a finite power-log sum and no finite working order was given.", <|"Expression" -> e|>]];
  order = Max[1, Ceiling[canon[Kw]]];
  s = Quiet[Series[e, {u, 0, order}, Assumptions -> ass && u > 0]];
  first = nativePowerLogSeries[s, u, ell, ass, Kw, limit];
  s2 = Quiet[Series[e, {u, 0, order + 1}, Assumptions -> ass && u > 0]];
  second = catch[nativePowerLogSeries[s2, u, ell, ass, Kw, limit]];
  If[FailureQ[second], first, nativeRefineSeriesTail[first, second, ell, ass]]];

(* ------------------------------------------------------------------ *)
(* Endpoint normalization                                               *)
(* ------------------------------------------------------------------ *)

(* A coordinate must be a symbol without a numeric value: Pi, E, Degree,
   Glaisher and the other named constants are symbols that NumericQ accepts,
   and native Series refuses them as variables (wave-6 report 52 N1). *)
seriesVariableQ[v_] := MatchQ[v, _Symbol] && ! NumericQ[v];

localCoordinate[x_, x0_, direction_] := Module[{dir = direction, u = Unique["u$"], sub, s},
  If[! seriesVariableQ[x],
   fail["InvalidVariable", "The expansion variable must be a symbol without a numeric value.", <|"Variable" -> x|>]];
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

(* Only peel outer conditions and split top-level assumption conjuncts.
   Held scopes and nested conditional expressions retain their own meaning. *)
(* Parameter-only clauses of the Assumptions option and of an outer
   ConditionalExpression alike are parameter assumptions; only clauses that
   mention the variable are approach conditions that must hold eventually.
   An inline parameter predicate such as a > 0 or Element[Log[a], Reals] was
   previously demanded of the approach and refused (wave-6 report 49 N1). *)
splitApproachInput[f_, x_, ass_] := Module[{body = f, condition = True, clauses},
  While[Head[body] === ConditionalExpression,
    condition = condition && body[[2]]; body = body[[1]]];
  clauses = Join[If[Head[ass] === And, List @@ ass, {ass}],
    If[Head[condition] === And, List @@ condition, {condition}]];
  {body, And @@ Select[clauses, FreeQ[#, x] &],
    And @@ Select[clauses, ! FreeQ[#, x] &]}];

(* ------------------------------------------------------------------ *)
(* Forward expansion: public                                            *)
(* ------------------------------------------------------------------ *)

Options[AsymptoticExpansion] = {Assumptions :> $Assumptions, Direction -> Automatic, SeriesTermGoal -> Automatic, "MaxTerms" -> 20000};
SetAttributes[AsymptoticExpansion, HoldAllComplete];
AsymptoticExpansion[args___] := expansionHeldEntry[args];
(* Preserve explicit callable syntax before native evaluation can turn, for
   example, InverseFunction[Exp] into the symbol Log. All other arguments still
   receive the ordinary evaluation of forwardEntry, including option Sequences. *)
SetAttributes[{forwardHeldEntry, forwardHeldExpression, forwardCallable}, HoldAllComplete];
forwardHeldEntry[f_, args___] := forwardEntry[forwardHeldExpression[f], args];
forwardHeldEntry[args___] := forwardEntry[args];
forwardHeldExpression[f : (_InverseFunction | _Function)] := forwardCallable[f];
forwardHeldExpression[ConditionalExpression[f_, condition_]] := ConditionalExpression[forwardHeldExpression[f], condition];
forwardHeldExpression[f_] := f;
forwardApplyCallable[f_Function, x_] := Module[{arity},
  arity = catch[inverseFunctionCallableArity[f, 1]];
  If[FailureQ[arity], fail["CallableArity", "An unapplied pure Function must accept one expansion variable.", <|"Cause" -> arity|>]];
  Quiet[Check[f[x], fail["CallableArity", "An unapplied pure Function must accept one expansion variable."],
    {Function::slotn}], Function::slotn]];
forwardApplyCallable[f_, x_] := f[x];
forwardExpression[forwardCallable[f_], x_] := forwardApplyCallable[f, x];
forwardExpression[f : (_InverseFunction | _Function), x_] := forwardApplyCallable[f, x];
forwardExpression[ConditionalExpression[f_, condition_], x_] := ConditionalExpression[forwardExpression[f, x], condition];
forwardExpression[f_, x_] := f;
forwardEntry[f_, {x_Symbol, x0_, cutoff_}, opts : OptionsPattern[AsymptoticExpansion]] := forwardPublic[forwardExpression[f, x], x, x0, cutoff, opts];
forwardEntry[f_, {x_Symbol, x0_}, opts : OptionsPattern[AsymptoticExpansion]] := forwardPublic[forwardExpression[f, x], x, x0, Automatic, opts];
forwardEntry[f_, x_Symbol -> x0_, opts : OptionsPattern[AsymptoticExpansion]] := forwardEntry[f, {x, x0}, opts];
forwardEntry[___] := Failure["InvalidArguments", <|"MessageTemplate" ->
   "Use AsymptoticExpansion[f, {x, x0, cutoff}] or AsymptoticExpansion[f, x -> x0, SeriesTermGoal -> n] (also accepting {x, x0})."|>];

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

(* exact jet of a finite power-log expression, or $Failed when an infinite
   series would be needed or the exact expansion exceeds the term budget;
   the truncated attempt that follows works at the requested cutoff (P01) *)
exactJet[fu_, u_, ell_, ass_, limit_] := Module[{r = Catch[fwd[fu, u, ell, ass, Infinity, limit], $tag]},
  Which[FailureQ[r] && r[[1]] === "InfiniteSeries", $Failed,
   FailureQ[r] && r[[1]] === "UnsupportedInput", $Failed,
   FailureQ[r] && r[[1]] === "ResourceLimit", $Failed,
   FailureQ[r], Throw[r, $tag],
   True, r]];

forwardCore[f_, x_, x0_, cutoff0_, opts : OptionsPattern[AsymptoticExpansion]] := Module[
  {ass = optionAssumptions[AsymptoticExpansion, {opts}], dir = OptionValue[AsymptoticExpansion, {opts}, Direction],
   goal = OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], limit = OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"],
   coord, u, ell = Unique["ell$"], fu, jet, cutoff = cutoff0, T, tries = 0, K, ex, normalized, result},
  validateInput[f, limit];
  If[! FreeQ[ass, x], fail["InvalidAssumptions", "Assumptions concern parameters only."]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"];
  normalized = gammaLogarithmNormalize[f, x, ass, coord, limit];
  fu = normalized["Expression"] /. x -> coord["Substitution"];
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
  result = makeForwardObject[jet, cutoff, f, x, x0, coord, u, ell, ass, goal];
  If[! TrueQ[normalized["Changed"]], Return[result, Module]];
  GeneralizedSeries[Join[result[[1]], <|
    "TargetDomain" -> Lookup[result[[1]], "TargetDomain", True] && normalized["Domain"],
    "NormalizedExpression" -> normalized["Expression"],
    "Transformation" -> "Real logarithms of positive Gamma and Barnes G products are normalized before ordinary power-log expansion.",
    "AsymptoticReference" -> If[FreeQ[f, _BarnesG | _LogBarnesG], "https://dlmf.nist.gov/5.11.E1", "https://dlmf.nist.gov/5.17.E5"]|>]]];

makeForwardObject[jet_, cutoff_, f_, x_, x0_, coord_, u_, ell_, ass_, goal_] := Module[
  {T, P, D, kept, omitted, remData, wexpr, logw, expr, terms, frontier, sd},
  {T, P, D} = jet;
  T = realCoefficientRows[T, ell, ass];
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
  GeneralizedSeries[<|
    "Kind" -> "Forward",
    "Expression" -> expr,
    "Remainder" -> If[remData === None, 0, PowerLogRemainder[wexpr, ToRadicals[remData[[1]]], remData[[2]]]],
    "RemainderPower" -> If[remData === None, Infinity, ToRadicals[remData[[1]]]],
    "RemainderLogDegree" -> If[remData === None, 0, remData[[2]]],
    "RemainderVariable" -> wexpr,
    "FrontierTerm" -> If[frontier === None, If[P === Infinity, 0, Missing["Unknown"]], wexpr^ToRadicals[frontier[[1]]] (ToRadicals[frontier[[2]]] /. ell -> logw)],
    "Terms" -> terms,
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Length[kept],
    "TermConvention" -> "Each {beta, C} means w^beta C with w the local variable (x - x0, x0 - x, 1/x or -1/x); logarithms have been substituted.",
    "Blocks" -> kept, "LogVariable" -> ell, "LocalVariable" -> u,
    "Variable" -> x, "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "Cutoff" -> ToRadicals[cutoff], "Precision" -> {P, D},
    "Exact" -> (P === Infinity && omitted === {}),
    "Function" -> f, "Assumptions" -> ass,
    "SeriesData" -> sd|>]];

makeSeriesData[terms_, x_, x0_, coord_, remData_, logw_] :=
  If[(coord["Direction"] === "FromBelow" && ! coord["Infinite"]) || x0 === -Infinity,
    Missing["NotAvailable"], makeRationalSeriesData[terms, x, x0, remData]];

(* Native SeriesData is an optional dense view of the sparse result. Its
   remainder index does not require trailing zero coefficients. Bound the
   native integer fields and their order difference, then the retained
   lattice span, before allocating or scaling any coefficients. A native
   order difference outside the signed range can silently discard terms. *)
makeRationalSeriesData[terms_, x_, x0_, remData_, scale_: 1] := Module[
  {exps, den, nmin, nmax, span, count, coeffs, limit = 100000,
   nativeMax = 2^($SystemWordLength - 1) - 1},
  exps = terms[[All, 1]];
  If[! (And @@ (IntegerQ[#] || Head[#] === Rational & /@ exps)), Return[Missing["IrrationalExponents"], Module]];
  If[remData === None, Return[Missing["Exact"], Module]];
  If[! (IntegerQ[remData[[1]]] || Head[remData[[1]]] === Rational), Return[Missing["IrrationalExponents"], Module]];
  If[remData[[2]] =!= 0, Return[Missing["LogarithmicRemainder",
    <|"RemainderPower" -> remData[[1]], "RemainderLogDegree" -> remData[[2]]|>], Module]];
  den = LCM @@ (Denominator /@ Append[exps, remData[[1]]]);
  nmin = If[exps === {}, remData[[1]] den, Min[exps] den]; nmax = remData[[1]] den;
  span = nmax - nmin;
  If[! TrueQ[1 <= den <= nativeMax && -nativeMax - 1 <= nmin <= nativeMax &&
      -nativeMax - 1 <= nmax <= nativeMax && 0 <= span <= nativeMax],
    Return[Missing["NativeSeriesDataRange", <|"Indices" -> {nmin, nmax, den},
      "OrderSpan" -> span, "AllowedIndexRange" -> {-nativeMax - 1, nativeMax},
      "MaximumDenominator" -> nativeMax, "MaximumOrderSpan" -> nativeMax|>], Module]];
  count = If[exps === {}, 0, Max[exps] den - nmin + 1];
  If[count > limit, Return[Missing["DenseSeriesDataLimit",
    <|"RequiredCoefficients" -> count, "Limit" -> limit|>], Module]];
  coeffs = ConstantArray[0, count];
  Do[coeffs[[t[[1]] den - nmin + 1]] = scale^(-t[[1]]) t[[2]], {t, terms}];
  SeriesData[x, x0, coeffs, nmin, nmax, den]];

(* ------------------------------------------------------------------ *)
(* Model construction for the inverse                                   *)
(* ------------------------------------------------------------------ *)

rowsToModel[rows0_List, u_, ell_, ass_, symbolic_] := Module[{rows, lead, p, a, y0 = 0, rest, deltas, polys},
  rows = realCoefficientRows[rows0, ell, ass, symbolic];
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
    "The ordinary power-log engine requires a constant leading coefficient. This logarithmic leading block needs an admitted Lambert or logarithmic-coordinate reduction."]];
  If[! TrueQ[Simplify[a != 0, ass]], fail["UnprovedNonzeroLeadingCoefficient", "The leading coefficient must be provably nonzero.", <|"Coefficient" -> a|>]];
  If[! TrueQ[Simplify[Element[a, Reals], ass]], fail["UnprovedRealCoefficient", "The leading coefficient must be provably real.", <|"Coefficient" -> a|>]];
  rest = Rest[rows];
  deltas = If[symbolic, Simplify[#[[1]] - p, ass], canon[#[[1]] - p]] & /@ rest;
  polys = polyCanon[#[[2]]/a, ell, ass] & /@ rest;
  Do[If[! realPolynomialQ[q, ell, ass],
     fail["UnprovedRealCoefficient", "All coefficients must be provably real under the assumptions.", <|"Polynomial" -> q|>]], {q, polys}];
  If[symbolic,
   Do[If[! TrueQ[Simplify[d > 0, ass]], fail["UnprovedPositiveGap", "A power gap could not be proved positive.", <|"Gap" -> d|>]], {d, deltas}]];
  (* "Limit" is the baseline extracted by normalization, which for a pole
     (p < 0) is 0 rather than the analytic limit; "ModelOffset" names that
     baseline and "TargetLimit" the analytic endpoint of the admitted
     approach, unresolved when the leading sign is unproved (wave-5 report
     43 F02). The legacy key is kept for its internal consumers. *)
  <|"Limit" -> y0, "ModelOffset" -> y0,
    "TargetLimit" -> Which[TrueQ[Simplify[p > 0, ass]], y0,
      TrueQ[Simplify[p < 0, ass]] && provablyPositive[a, ass], Infinity,
      TrueQ[Simplify[p < 0, ass]] && provablyNegative[a, ass], -Infinity,
      True, Missing["Unresolved", "LeadingSign"]],
    "LeadingCoefficient" -> a, "LeadingPower" -> p, "Gaps" -> deltas,
    "Polynomials" -> polys, "LogVariable" -> ell, "Variable" -> u, "Rows" -> rows,
    "Symbolic" -> symbolic, "Assumptions" -> ass|>];

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

newtonSolve[d_List, polys_List, p_, cut_, ell_, ass_, limit_] :=
  newtonSolveDoubling[d, polys, p, cut, ell, ass, limit];

(* ------------------------------------------------------------------ *)
(* Inverse expansion: public                                            *)
(* ------------------------------------------------------------------ *)

Options[AsymptoticInverse] = {Assumptions :> $Assumptions, Direction -> Automatic, Method -> "Lagrange",
  "Power" -> 1, "InputRemainder" -> Automatic, "Truncation" -> "Exponent",
  SeriesTermGoal -> Automatic, "MaxTerms" -> 20000};

SetAttributes[AsymptoticInverse, HoldAllComplete];
AsymptoticInverse[args___] := catch[inverseEntry[args]];
inverseEntry[f_, {x_Symbol, x0_}, {y_Symbol, cutoff_}, opts : OptionsPattern[AsymptoticInverse]] := inverseFunctionPublicInverse[f, x, x0, y, cutoff, opts];
inverseEntry[f_, {x_Symbol, x0_}, y_Symbol, opts : OptionsPattern[AsymptoticInverse]] := inverseFunctionPublicInverse[f, x, x0, y, Automatic, opts];
inverseEntry[f_, x_Symbol, y_Symbol, opts : OptionsPattern[AsymptoticInverse]] := inverseFunctionPublicInverse[f, x, 0, y, Automatic, opts];
inverseEntry[___] := Failure["InvalidArguments", <|"MessageTemplate" ->
   "Use AsymptoticInverse[f, {x, x0}, {y, cutoff}] or AsymptoticInverse[f, {x, x0}, y, SeriesTermGoal -> n]."|>];

inverseDispatch[f_, x_, x0_, y_, cutoff_, opts___] := Module[{s},
  If[! FreeQ[f, _InverseFunction], Return[construct[f, x, x0, y, cutoff, opts], Module]];
  s = gammaInverseConstruct[f, x, x0, y, cutoff, opts];
  If[s =!= $Failed, Return[s, Module]];
  s = lambertConstruct[f, x, x0, y, cutoff, opts];
  If[s === $Failed, s = coordinateConstruct[f, x, x0, y, cutoff, opts]];
  If[s === $Failed, s = sourceCoordinateConstruct[f, x, x0, y, cutoff, opts]];
  If[s === $Failed, s = logarithmicDispatch[f, x, x0, y, cutoff, opts]];
  If[s === $Failed, construct[f, x, x0, y, cutoff, opts], s]];

inverseBlocks[d_, polys_, p_, rint_, H_, method_, ell_, ass_, limit_, region_] := Module[{U, blocks},
  If[method === "GroupedLagrange" && H =!= Infinity,
    Return[groupedLagrangeBlocks[d, polys, p, rint, H, ell, ass, limit], Module]];
  If[method === "Newton",
   U = newtonSolve[d, polys, p, H, ell, ass, limit];
   blocks = jetUnitPower[U, rint, H, ell, ass, limit];
   If[blocks === {} || ! (blocks[[1, 1]] === 0), blocks = jetMerge[Join[{{0, 1}}, blocks], ell, ass]];
   blocks,
   jetMerge[lagrangeCoefficient[#, d, polys, p, rint, ell, ass, False] & /@ region["Inside"], ell, ass]]];

(* Look past finitely many cancelled boundary blocks. A bounded search retains
   the original valid (possibly non-sharp) bound if no nonzero block is found. *)
inverseFrontier[region_, d_, polys_, p_, rint_, ell_, ass_, limit_] :=
  First[inverseFrontierWithCount[region, d, polys, p, rint, ell, ass, limit]];
inverseFrontierWithCount[region0_, d_, polys_, p_, rint_, ell_, ass_, limit_] := Module[
  {region = region0, ws, weight, near, poly, first = None, result = None, next, attempt, count = 0},
  If[d === {} || region["Boundary"] === {}, Return[{None, 0}, Module]];
  Do[
   ws = canon[# . d] & /@ region["Boundary"];
   weight = First[Sort[ws, leq]];
   near = Pick[region["Boundary"], equal[#, weight] & /@ ws];
   count += Length[near];
   poly = jetMerge[lagrangeCoefficient[#, d, polys, p, rint, ell, ass, False] & /@ near, ell, ass];
   result = {weight, If[poly === {}, 0, poly[[1, 2]]]};
   If[first === None, first = result];
   If[poly =!= {}, Break[]];
   next = Catch[indexRegion[d, weight, True, limit], $tag];
   If[FailureQ[next] || next["Boundary"] === {}, result = first; Break[]];
   region = next,
   {attempt, 8}];
  {If[result[[2]] === 0, first, result], count}];

(* Return the real logarithm only for a proved positive monomial tree.
   Recursion preserves reciprocal/scaled bases introduced by coordinates;
   realness of an outer power cannot erase an unproved inner branch. *)
finitePositiveMonomialLog[e_, u_Symbol, ass_] := Module[{parts}, Which[
  e === u, Log[u],
  FreeQ[e, u], If[TrueQ[Simplify[e > 0, ass]], Log[e], $Failed],
  Head[e] === Power && FreeQ[e[[2]], u] &&
      TrueQ[Simplify[Element[e[[2]], Reals], ass]],
    parts = finitePositiveMonomialLog[e[[1]], u, ass];
    If[parts === $Failed, $Failed, e[[2]] parts],
  Head[e] === Times,
    parts = finitePositiveMonomialLog[#, u, ass] & /@ List @@ e;
    If[MemberQ[parts, $Failed], $Failed, Total[parts]],
  True, $Failed]];

(* finite power-log parser that tolerates symbolic exponents (used by depth truncation) *)
parseFinite[e_, u_Symbol, ell_Symbol, ass_] := Module[{ex, summands, rows = {}, ok = True},
  ex = Expand[(e /. Log[b_] :> With[{lg = finitePositiveMonomialLog[b, u, ass]},
      If[lg === $Failed, Log[b], lg]]) /. Log[u] -> ell];
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
  {ass = optionAssumptions[AsymptoticInverse, {opts}], dir = OptionValue[AsymptoticInverse, {opts}, Direction],
   method = OptionValue[AsymptoticInverse, {opts}, Method], r = OptionValue[AsymptoticInverse, {opts}, "Power"],
   inputRem = OptionValue[AsymptoticInverse, {opts}, "InputRemainder"], trunc = OptionValue[AsymptoticInverse, {opts}, "Truncation"],
   goal = OptionValue[AsymptoticInverse, {opts}, SeriesTermGoal], limit = OptionValue[AsymptoticInverse, {opts}, "MaxTerms"],
   coord, u, ell = Unique["ell$"], fu, jet, rows, model, p, a, d, polys, y0, symbolic, H, cutoff = cutoff0,
   region, blocks, frontier, rem, inputCap, v, z, expr, terms, wexpr, rint, obj, remData, forwardRem, depth, exactModel, Kf, tries, gexpr, logw, need,
   termination = None, terminationTried = Missing["NotTried"], terminationEligible, reliableBlocks, computationState = None},
  validateInput[f, limit];
  If[! seriesVariableQ[x] || ! seriesVariableQ[y] || x === y,
   fail["InvalidVariables", "Source and target variables must be distinct symbols without numeric values.", <|"Variables" -> {x, y}|>]];
  If[! FreeQ[f, y], fail["InvalidVariables", "The forward expression must not contain the target variable."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters only; positivity of the local variable is built in."]];
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  symbolic = (trunc === "Depth");
  If[! MemberQ[{"Exponent", "Depth"}, trunc], fail["InvalidOption", "Truncation must be \"Exponent\" or \"Depth\"."]];
  If[! MemberQ[{"Lagrange", "Newton", "GroupedLagrange"}, method], fail["InvalidOption", "Method must be Lagrange, Newton or GroupedLagrange."]];
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
     Module[{count = 0, tries2 = 0},
      computationState = incrementalInverseState[d, polys, p, rint, ell, ass, limit];
      While[True,
       tries2++; If[tries2 > 50 goal + 10, fail["ResourceLimit", "SeriesTermGoal iteration did not terminate."]];
       computationState = advanceInverseState[computationState];
       blocks = computationState["Blocks"];
       count = Length[blocks];
       If[terminationEligible,
        reliableBlocks = If[exactModel, blocks, Select[blocks, less[#[[1]], jet[[2]] - p] &]];
        If[reliableBlocks =!= terminationTried,
         terminationTried = reliableBlocks;
         termination = exactInverseTermination[f, x, x0, coord, model, reliableBlocks, ell, ass];
         If[AssociationQ[termination], blocks = reliableBlocks; Break[]]]];
       If[count >= goal || computationState["NextWeight"] === Infinity, Break[]]];
      region = incrementalInverseRegion[computationState]];
     H = If[AssociationQ[termination], Infinity, computationState["NextWeight"]];
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
   If[! AssociationQ[termination] && (cutoff0 =!= Automatic || MemberQ[{"Newton", "GroupedLagrange"}, method]),
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
    "DeclaredInputRemainder" -> inputRem,
    "ExactTerminationCertificate" -> termination,
    "ComputationState" -> computationState,
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Length[blocks],
    "Function" -> f, "Assumptions" -> ass,
    "Branch" -> "the inverse tends to the expansion point with " <> ToString[coord["LocalVariable"], InputForm] <> " ~ " <> ToString[z, InputForm],
    "SeriesData" -> makeInverseSeriesData[terms, y, y0, a, coord, remData, r, x0]
    |>;
  GeneralizedSeries[obj]];

makeInverseSeriesData[terms_, y_, y0_, a_, coord_, remData_, r_, x0_] :=
  If[r =!= 1 || coord["Sign"] =!= 1 || coord["Infinite"] || x0 =!= 0 ||
      y0 === Infinity || y0 === -Infinity, Missing["NotAvailable"],
    makeRationalSeriesData[terms, y, y0, remData, a]];

(* ------------------------------------------------------------------ *)
(* The GeneralizedSeries object                                            *)
(* ------------------------------------------------------------------ *)

GeneralizedSeries /: Normal[GeneralizedSeries[a_Association]] := a["Expression"];
GeneralizedSeries[a_Association]["Properties"] := Keys[a];
GeneralizedSeries[a_Association][key_String] := Lookup[a, key, Missing["KeyAbsent", key]];
GeneralizedSeries[a_Association][val_?NumericQ] :=
  If[Lookup[a, "Kind", None] === "Native", nativeSeriesValue[a, val], a["Expression"] /. a["Variable"] -> val];
remainderScale[PowerLogRemainder[w_, b_, k_]] := Module[{base, lg},
  {base, lg} = If[MatchQ[w, Power[_, -1]], {w[[1]]^(-b), Log[w[[1]]]}, {w^b, Log[w]}];
  If[k === 0, base, base (1 + Abs[lg])^k]];
(* Interpretation supplies the displayed expression's precedence as well as
   the original object. Keep both held: formatting must not evaluate payloads.
   Read-only boxes prevent edited coefficients from retaining stale metadata. *)
seriesInterpretationBoxes[HoldComplete[display_], HoldComplete[original_], fmt_] :=
  MakeBoxes[Interpretation[display, original], fmt] /.
    box_InterpretationBox :> Append[box, Editable -> False];
heldSeriesSum[HoldComplete[Plus[e___]], HoldComplete[Plus[r___]]] := HoldComplete[Plus[e, r]];
heldSeriesSum[HoldComplete[Plus[e___]], HoldComplete[r_]] := HoldComplete[Plus[e, r]];
heldSeriesSum[HoldComplete[e_], HoldComplete[Plus[r___]]] := HoldComplete[Plus[e, r]];
heldSeriesSum[HoldComplete[e_], HoldComplete[r_]] := HoldComplete[e + r];

GeneralizedSeries /: MakeBoxes[GeneralizedSeries[a_Association], fmt : StandardForm | TraditionalForm] :=
  generalizedSeriesBoxes[HoldComplete[GeneralizedSeries[a]], fmt];
generalizedSeriesBoxes[held : HoldComplete[GeneralizedSeries[a_Association]], fmt_] := Module[{rules, fields, native},
  (* Matching the association's rules works for both evaluated associations and
     raw associations inside MakeBoxes; ordinary Lookup would evaluate them. *)
  rules = Replace[held, HoldComplete[GeneralizedSeries[Association[r___]]] :> HoldComplete[r]];
  native = Cases[rules, HoldPattern[(Rule | RuleDelayed)["Kind", "Native"]], {1}];
  If[native =!= {},
    native = Cases[rules, HoldPattern[(Rule | RuleDelayed)["NativeResult", value_]] :> HoldComplete[value], {1}];
    If[Length[native] === 1, Return[seriesInterpretationBoxes[First[native], held, fmt], Module]]];
  fields = (Cases[rules, HoldPattern[(Rule | RuleDelayed)[#, value_]] :> HoldComplete[value], {1}] &) /@
    {"Expression", "Remainder"};
  Replace[fields, {
    {{HoldComplete[e_]}, {HoldComplete[0]}} :> seriesInterpretationBoxes[HoldComplete[e], held, fmt],
    {{HoldComplete[0]}, {HoldComplete[r_]}} :> seriesInterpretationBoxes[HoldComplete[r], held, fmt],
    {{HoldComplete[e_]}, {HoldComplete[r_]}} :>
      seriesInterpretationBoxes[heldSeriesSum[HoldComplete[e], HoldComplete[r]], held, fmt],
    _ :> RowBox[{"GeneralizedSeries", "[", MakeBoxes[a, fmt], "]"}]}]];
Format[GeneralizedSeries[a_Association], OutputForm] :=
  If[Lookup[a, "Kind", None] === "Native", a["NativeResult"], GeneralizedSeries[a["Expression"], a["Remainder"]]];

(* Small syntactic reductions keep scales readable without evaluating symbols
   or arbitrary expressions supplied to a held MakeBoxes call. *)
heldScaleNegate[HoldComplete[n_Integer]] := With[{negative = -n}, HoldComplete[negative]];
heldScaleNegate[HoldComplete[Rational[n_Integer, d_Integer]]] :=
  With[{negative = -Rational[n, d]}, HoldComplete[negative]];
heldScaleNegate[HoldComplete[Times[-1, e_]]] := HoldComplete[e];
heldScaleNegate[HoldComplete[e_]] := HoldComplete[-e];
heldScalePower[_, HoldComplete[0]] := HoldComplete[1];
heldScalePower[HoldComplete[w_], HoldComplete[1]] := HoldComplete[w];
heldScalePower[HoldComplete[w_], HoldComplete[b_]] := HoldComplete[w^b];
heldScaleTimes[HoldComplete[1], factor_] := factor;
heldScaleTimes[base_, HoldComplete[1]] := base;
heldScaleTimes[HoldComplete[b_], HoldComplete[f_]] := HoldComplete[b f];
heldRemainderScale[HoldComplete[PowerLogRemainder[w_, b_, k_]]] := Module[{base, log, factor},
  {base, log} = Replace[HoldComplete[w], {
    HoldComplete[Power[z_, -1]] :> {heldScalePower[HoldComplete[z], heldScaleNegate[HoldComplete[b]]], HoldComplete[Log[z]]},
    _ :> {heldScalePower[HoldComplete[w], HoldComplete[b]], HoldComplete[Log[w]]}}];
  factor = Replace[log, HoldComplete[l_] :> heldScalePower[HoldComplete[1 + Abs[l]], HoldComplete[k]]];
  heldScaleTimes[base, factor]];
PowerLogRemainder /: MakeBoxes[r : PowerLogRemainder[_, _, _], fmt : StandardForm | TraditionalForm] :=
  Replace[heldRemainderScale[HoldComplete[r]],
    HoldComplete[scale_] :> seriesInterpretationBoxes[HoldComplete[O[scale]], HoldComplete[r], fmt]];
If[! (StringQ[$Version] && StringContainsQ[$Version, "Mathics"]),
  Format[r_PowerLogRemainder, OutputForm] := With[{sc = remainderScale[r]}, HoldForm[O[sc]]]
];

(* ------------------------------------------------------------------ *)
(* Residual check                                                       *)
(* ------------------------------------------------------------------ *)

Options[InverseResidual] = {"MaxTerms" -> 200000};
InverseResidual[GeneralizedSeries[a_Association], opts : OptionsPattern[]] := catch[residual[a, Automatic, OptionValue["MaxTerms"]]];
InverseResidual[GeneralizedSeries[a_Association], h_, opts : OptionsPattern[]] := catch[residual[a, h, OptionValue["MaxTerms"]]];
InverseResidual[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use InverseResidual[expansion] or InverseResidual[expansion, relativeCutoff]."|>];

residual[a_Association, h_, limit_] := Module[{model = a["Model"], blocks = a["Blocks"], ell = a["LogVariable"], ass = a["Assumptions"],
   p, d, polys, r = a["Power"], cut, U, res, y, v, aa, rint},
  If[Lookup[a, "Kind", ""] === "GammaInverse", Return[gammaInverseResidual[a, h, limit], Module]];
  If[Lookup[a, "Kind", ""] === "BarnesGInverse", Return[barnesInverseResidual[a, h, limit], Module]];
  If[Lookup[a, "Scale", "PowerLog"] === "Transformed", Return[coordinateResidual[a, h, limit], Module]];
  If[Lookup[a, "Scale", "PowerLog"] === "Logarithmic", Return[lambertResidual[a, h, limit], Module]];
  If[Lookup[a, "Kind", ""] === "LogarithmicInverse", Return[logarithmicResidual[a, h, limit], Module]];
  If[Lookup[a, "Kind", ""] === "FourierInverse", Return[fourierResidual[a, h, limit], Module]];
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
  (* The label states the translated model: the target offset y0 = Limit is
     subtracted before normalization, exactly as v = y - y0 is used above. *)
  <|"ZeroBelowCutoff" -> (res === {}),
    "NormalizedResidual" -> Total[((v/aa)^ToRadicals[canon[#[[1]]/p]] (ToRadicals[#[[2]]] /. ell -> Log[v/aa]/p)) & /@ res],
    "ResidualBlocks" -> res, "RelativeCutoff" -> ToRadicals[cut],
    "TargetOffset" -> If[v === y, 0, a["Limit"]],
    "Normalization" -> If[v === y, "f(g(y))/(a z^p) - 1 with z the uniformizer; blocks are in z",
      "(f(g(y)) - y0)/(a z^p) - 1 with y0 = TargetOffset and z the uniformizer of y - y0; blocks are in z"],
    "Scope" -> "Formal composition with the finite forward model only."|>];

(* ------------------------------------------------------------------ *)
(* Numerical check                                                      *)
(* ------------------------------------------------------------------ *)

Options[InverseNumericalCheck] = {WorkingPrecision -> 50};
InverseNumericalCheck[GeneralizedSeries[a_Association], yv_, OptionsPattern[]] := catch[Module[
  {wp = OptionValue[WorkingPrecision], result, root},
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[a, "Kind", ""]], Return[gammaInverseNumerical[a, yv, wp], Module]];
  If[Lookup[a, "Kind", ""] === "SpecialInverse" || Lookup[a, "Scale", "PowerLog"] === "Transformed",
    result = If[Lookup[a, "Kind", ""] === "SpecialInverse", specialNumerical[a, yv, wp], coordinateNumericalCheck[a, yv, wp]];
    If[FailureQ[result], Return[result, Module]];
    root = Lookup[result, "ReferenceRoot", Lookup[result, "ExactInverse", Missing["NotAvailable"]]];
    If[KeyExistsQ[a, "SourceDomain"] && ! MissingQ[root], numericalSourceDomainCheck[a, root, yv, wp]];
    Return[result, Module]];
  numericalInverseEvidence[a, yv, wp]]];
InverseNumericalCheck[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use InverseNumericalCheck[expansion, yvalue]."|>];

lambertNumericalCheck[a_Association, yv_, wp_] := numericalInverseEvidence[a, yv, wp];

(* ------------------------------------------------------------------ *)
(* Perturbative (Lagrange-Buermann) formula generator                   *)
(* ------------------------------------------------------------------ *)

PerturbativeInverse[phi_, h_, {x_Symbol, y_Symbol}, n_Integer?NonNegative] := Module[{hy},
  (* The core inverse is a function of the target alone; a core containing
     the source symbol would survive elimination and yield a formally
     successful but structurally invalid result (wave-5 report 43 F03). *)
  If[x === y || ! FreeQ[h, y] || ! FreeQ[phi, x], Return[Failure["InvalidVariables", <|"MessageTemplate" -> "Use distinct symbols; h must not contain y and phi must not contain x."|>]]];
  hy = h /. x -> phi;
  phi + Sum[(-1)^k/k! D[D[phi, y] hy^k, {y, k - 1}], {k, 1, n}]];
PerturbativeInverse[h_, {x_Symbol, y_Symbol}, n_Integer?NonNegative] := PerturbativeInverse[y, h, {x, y}, n];
PerturbativeInverse[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use PerturbativeInverse[phi, h, {x, y}, n] or PerturbativeInverse[h, {x, y}, n]."|>];

(* ------------------------------------------------------------------ *)
(* Model access and single coefficients                                 *)
(* ------------------------------------------------------------------ *)

Options[PowerLogModel] = {Assumptions :> $Assumptions, Direction -> Automatic, "MaxTerms" -> 20000};
SetAttributes[PowerLogModel, HoldAllComplete];
PowerLogModel[args___] := catch[powerLogModelEntry[args]];
powerLogModelEntry[f_, {x_Symbol, x0_}, opts : OptionsPattern[PowerLogModel]] := Module[
   {coord, u, ell = Unique["ell$"], jet, ass = optionAssumptions[PowerLogModel, {opts}],
    body = f, condition, parameterAss, limit = OptionValue[PowerLogModel, {opts}, "MaxTerms"]},
   validateInput[f, limit];
   {body, parameterAss, condition} = splitApproachInput[body, x, ass];
   coord = localCoordinate[x, x0, OptionValue[PowerLogModel, {opts}, Direction]]; u = coord["u"];
   If[! inverseFunctionEventually[condition /. x -> coord["Substitution"], u, parameterAss],
     fail["IncompatibleSourceCondition", "The model condition must hold eventually on the requested real source approach."]];
   jet = exactJet[body /. x -> coord["Substitution"], u, ell, parameterAss, limit];
   If[jet === $Failed, fail["UnsupportedInput", "The expression is not a finite power-log sum in the local variable."]];
   Join[rowsToModel[jet[[1]], u, ell, parameterAss, False], <|"SourceDomain" -> condition, "SourceVariable" -> x|>]];
powerLogModelEntry[f_, x_Symbol, opts : OptionsPattern[PowerLogModel]] := powerLogModelEntry[f, {x, 0}, opts];
powerLogModelEntry[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use PowerLogModel[f,{x,x0}] or PowerLogModel[f,x]."|>];

Options[InverseExpansionCoefficient] = {"Power" -> 1};
(* Coefficient queries need the ordinary inverse model, not merely a series
   result with a finite expression. Check its schema before reading fields. *)
inverseCoefficientModelQ[model_] := AssociationQ[model] &&
  And @@ (KeyExistsQ[model, #] & /@
    {"Gaps", "Polynomials", "LeadingPower", "LogVariable", "Symbolic"}) &&
  ListQ[model["Gaps"]] && ListQ[model["Polynomials"]] &&
  Length[model["Gaps"]] === Length[model["Polynomials"]] &&
  Head[model["LogVariable"]] === Symbol &&
  MemberQ[{True, False}, model["Symbolic"]] && model["LeadingPower"] =!= 0;
InverseExpansionCoefficient[model_Association, k_List, OptionsPattern[]] := catch[Module[
   {r = OptionValue["Power"], c, ass = Lookup[model, "Assumptions", True]},
   If[! inverseCoefficientModelQ[model],
    fail["UnsupportedCoefficientModel", "Give an ordinary inverse coefficient model produced by PowerLogModel or retained by an inverse expansion."]];
   If[Length[k] =!= Length[model["Gaps"]] || ! (And @@ (IntegerQ[#] && # >= 0 & /@ k)),
    fail["InvalidMultiIndex", "Give one nonnegative integer per correction block of the model."]];
   c = lagrangeCoefficient[k, model["Gaps"], model["Polynomials"], model["LeadingPower"], r, model["LogVariable"], ass, model["Symbolic"]];
   <|"Weight" -> ToRadicals[c[[1]]], "Exponent" -> ToRadicals[canon[(r + c[[1]])/model["LeadingPower"]]],
     "Coefficient" -> (ToRadicals[c[[2]]] /. model["LogVariable"] -> \[FormalL]),
     "UniformizerExponent" -> ToRadicals[r + c[[1]]], "Assumptions" -> ass,
     "Meaning" -> "(v/a)^Exponent Coefficient[\[FormalL]] with z = (v/a)^(1/p), \[FormalL] = Log[z]"|>]];
InverseExpansionCoefficient[GeneralizedSeries[a_Association], k_List, opts : OptionsPattern[]] :=
  Which[Lookup[a, "Kind", None] === "Native",
   Failure["NativeSeriesContract", <|"MessageTemplate" -> "Native results do not supply an inverse coefficient model."|>],
  Lookup[a, "Scale", "PowerLog"] === "Logarithmic",
   Failure["Unsupported", <|"MessageTemplate" -> "Lambert coefficients are listed in the logarithmic expansion's Terms property; they have no power-gap multi-index."|>],
  ! inverseCoefficientModelQ[Lookup[a, "Model", None]] ||
    ! KeyExistsQ[a, "Power"] || ! KeyExistsQ[a, "ExpansionPoint"],
   Failure["UnsupportedCoefficientModel", <|
     "MessageTemplate" -> "This result does not retain an ordinary inverse coefficient model.",
     "Kind" -> Lookup[a, "Kind", Missing["Unknown"]],
     "Scale" -> Lookup[a, "Scale", "PowerLog"]|>],
  True,
   (* An explicit caller "Power" takes precedence over the stored observable
      power; both are observable powers of the source displacement and are
      converted to the internal uniformizer convention at an infinite endpoint.
      The option is resolved by OptionValue so that the symbol spelling
      Power -> p, nested lists and delayed rules all yield the value and the
      first occurrence wins; a literal string replacement would leave the
      option name inside the coefficient arithmetic (wave-6 report 48 N1). *)
   Module[{explicit = FilterRules[Flatten[{opts}], "Power"], power},
    power = If[explicit === {}, a["Power"], OptionValue[InverseExpansionCoefficient, explicit, "Power"]];
    If[! exactRealQ[power] || power === 0,
     Return[Failure["InvalidOption", <|"MessageTemplate" -> "Power must be a nonzero exact real number.",
       "Power" -> power|>], Module]];
    inverseCoefficientOriented[a, power,
     InverseExpansionCoefficient[Join[a["Model"], <|"Assumptions" -> Lookup[a, "Assumptions", Lookup[a["Model"], "Assumptions", True]]|>],
      k, "Power" -> If[a["ExpansionPoint"] === Infinity || a["ExpansionPoint"] === -Infinity, -power, power]]]]];

(* The normalized coefficient describes the positive local coordinate; the
   represented observable is sigma^r times that contribution, where sigma is
   the source orientation of the chart, and a finite endpoint is added once
   for power one. The oriented fields make that reconstruction explicit
   (wave-5 report 43 F01); "Coefficient" and "Meaning" are unchanged. *)
inverseCoefficientOriented[a_, power_, c_] := Module[{sigma, y, y0, lead, p, v, contribution},
  If[! AssociationQ[c], Return[c, Module]];
  sigma = Which[a["ExpansionPoint"] === -Infinity, -1, a["ExpansionPoint"] === Infinity, 1,
    Lookup[a, "Direction", "FromAbove"] === "FromBelow", -1, True, 1];
  y = a["Variable"]; y0 = Lookup[a["Model"], "Limit", 0];
  lead = a["Model"]["LeadingCoefficient"]; p = a["Model"]["LeadingPower"];
  v = If[MemberQ[{Infinity, -Infinity}, y0], y, y - y0];
  contribution = sigma^power (v/lead)^c["Exponent"] (c["Coefficient"] /. \[FormalL] -> Log[v/lead]/p);
  Join[c, <|"LocalCoefficient" -> c["Coefficient"], "SourceOrientation" -> sigma,
    "ObservableCoefficient" -> sigma^power c["Coefficient"],
    "AdditiveOffset" -> If[power === 1 && ! MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], a["ExpansionPoint"], 0],
    "ContributionExpression" -> contribution,
    "ObservableMeaning" -> "The represented observable (x - x0)^Power, or x^Power at an infinite endpoint, is AdditiveOffset plus the sum of ContributionExpression over all multi-indices: SourceOrientation^Power (v/a)^Exponent Coefficient[Log[v/a]/p] with v the target minus its finite limit. AdditiveOffset is added once per expansion, not per coefficient."|>]];
InverseExpansionCoefficient[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use InverseExpansionCoefficient[expansion, {k1, k2, ...}]."|>];

(* The logarithmic-scale engine shares the exact jet algebra above. *)
Get[FileNameJoin[{$kernelDirectory, "LambertInverse.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "CoordinateInverse.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "IncrementalInverse.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "SeriesOperations.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "RefinementState.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "SourceCoordinates.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "CorePerturbation.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "InverseCertificates.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "LogarithmicScales.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "FlatSectors.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "FlatSectorOperations.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "FourierCoefficients.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "SpecialFunctionAdapters.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "ExponentialCorePerturbation.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "NumericalInverseChecks.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "RefinementRequests.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "ReciprocalLogOperations.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "InverseFunctionSyntax.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "InverseFunctionBranches.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "InverseFunctionFamilies.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "InverseFunctionExpressions.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "GammaForward.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "BarnesForward.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "GammaInverse.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "BarnesInverse.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "GammaInverseChecks.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "BarnesInverseChecks.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "GammaInverseOperations.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "ExponentialForward.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "SeriesEnvelopeArithmetic.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "SeriesArithmetic.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "SpecialFunctionRealDomain.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "SpecialFunctionIdentities.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "ParameterizedSpecialFunctions.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "DirichletSpecialFunctions.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "NativeSpecialFunctions.wl"}]];
Get[FileNameJoin[{$kernelDirectory, "NativeCompatibility.wl"}]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsCalculus.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsCoreFunctions.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsCertificate.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsRefinement.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsInverseBranches.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsSpecialFunctions.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsInputAssumptions.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsNumerical.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsLists.wl"}]]];
If[StringContainsQ[$Version, "Mathics"], Get[FileNameJoin[{$kernelDirectory, "MathicsFormatting.wl"}]]];

End[];
EndPackage[];

(* Mathics EndPackage retains contexts inserted while the package loads. Keep
   the adapters private to already-parsed package definitions. *)
If[StringContainsQ[$Version, "Mathics"],
  $ContextPath = DeleteCases[$ContextPath, "AsymptoticAnalysis`Mathics`"]];
