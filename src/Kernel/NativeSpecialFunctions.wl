(* Import structured native asymptotic series without discarding their O terms.
   Native special-function expansions may contain several exact exponential
   carriers and oscillatory phases. Every tree operation transports an
   absolute error; a real projection is allowed only for a proved real source.
   https://reference.wolfram.com/language/ref/Series.html
   https://dlmf.nist.gov/2.1.iii *)

SetAttributes[specialNativeTry, HoldAllComplete];
specialNativeTry[e_] := Quiet[TimeConstrained[e, 4, $Failed]];

$specialNativeHeads = {AiryAi, AiryBi, AiryAiPrime, AiryBiPrime,
  BesselJ, BesselY, BesselI, BesselK, SphericalBesselJ, SphericalBesselY,
  HankelH1, HankelH2, StruveH, StruveL, AngerJ, WeberE,
  Erf, Erfc, Erfi, InverseErf, InverseErfc, DawsonF,
  ExpIntegralE, ExpIntegralEi, LogIntegral, SinIntegral, CosIntegral,
  SinhIntegral, CoshIntegral, FresnelC, FresnelS, Sinh, Cosh,
  PolyGamma, Zeta, HurwitzZeta, PolyLog, LerchPhi,
  GammaRegularized, InverseGammaRegularized, BetaRegularized,
  Hypergeometric0F1, Hypergeometric0F1Regularized,
  Hypergeometric1F1, Hypergeometric1F1Regularized, HypergeometricU,
  Hypergeometric2F1, Hypergeometric2F1Regularized, HypergeometricPFQ,
  HypergeometricPFQRegularized, MeijerG, WhittakerM, WhittakerW,
  ParabolicCylinderD, EllipticK, EllipticE, EllipticF, EllipticPi, JacobiSN, JacobiCN,
  JacobiDN, JacobiAmplitude, JacobiZeta, EllipticTheta,
  LegendreP, LegendreQ, GegenbauerC, JacobiP, LaguerreL,
  HermiteH, ChebyshevT, ChebyshevU, SpheroidalPS, SpheroidalQS};
$specialNativeCoreHeads = {Plus, Times, Power, Log, Exp, Abs, Sign,
  Sin, Cos, Tan, Cot, Sec, Csc, Tanh, Coth, Sech, Csch,
  ArcSin, ArcCos, ArcTan, ArcCot, ArcSec, ArcCsc, ArcSinh, ArcCosh,
  ArcTanh, ArcCoth, ArcSech, ArcCsch, Gamma, LogGamma, BarnesG,
  LogBarnesG, Factorial, Factorial2, Binomial, Beta, Pochhammer,
  Floor, Ceiling, Round, FractionalPart, IntegerPart, UnitStep,
  Min, Max, Re, Im, Conjugate, Arg};
specialNativeCandidateQ[f_, x_] := ! FreeQ[f, node_ /;
  ! AtomQ[node] && ! FreeQ[node, x] &&
    (MemberQ[$specialNativeHeads, Head[node]] ||
      specialNativeBuiltinHeadQ[Head[node]] ||
      MatchQ[node, Gamma[_, _] | Gamma[_, _, _] | Beta[_, _, _] | Beta[_, _, _, _]])];
specialNativeBuiltinHeadQ[h_Symbol] := Context[h] === "System`" &&
  ! MemberQ[$specialNativeCoreHeads, h] && MemberQ[Attributes[h], NumericFunction];
specialNativeBuiltinHeadQ[_] := False;

specialNativeBound[r_] := r /. rr_PowerLogRemainder :> remainderScale[rr];
specialNativeSmallQ[r_, u_, ass_] := Module[{bound},
  If[r === 0, Return[True, Module]];
  bound = Refine[specialNativeBound[r], ass && u > 0];
  (* These factors occur in nonnegative error sums. Their global bounds
     remove oscillations before the scalar limit test. *)
  bound = bound /. HoldPattern[Abs[(h : Sin | Cos)[phase_]]] /;
      TrueQ[Refine[Element[phase, Reals], ass && u > 0]] :> 1;
  specialNativeTry[Limit[bound, u -> 0, Direction -> "FromAbove", Assumptions -> ass]] === 0];
specialNativeReal[e_, u_, ass_] := Module[{value, simplified},
  value = specialNativeTry[Refine[ComplexExpand[Re[e],
    Select[DeleteDuplicates[Cases[e, _Symbol, {0, Infinity}]],
      # =!= u && ! NumericQ[#] && ! TrueQ[Refine[Element[#, Reals], ass]] &]], ass && u > 0]];
  If[value === $Failed, fail["ResourceLimit", "Real projection of the native expansion exceeded its time budget."]];
  value = Expand[value];
  (* Keep real oscillatory phases polynomial in their bounded modes.
     Global trigonometric simplification can combine different algebraic
     weights into a variable phase or a rational coefficient. *)
  If[! FreeQ[value, node : (Sin[_] | Cos[_]) /; ! FreeQ[node, u]], Return[value, Module]];
  simplified = specialNativeTry[FullSimplify[value, ass && u > 0]];
  If[simplified === $Failed, value, simplified]];
(* A structural absolute majorant avoids expensive cancellation inside an
   absolute value. In particular |sin(a+ib)| and |cos(a+ib)| are bounded by
   exp(|b|), which cancels opposite real carriers before the limit check. *)
specialNativeAbs[e_Plus, u_, ass_] := Total[specialNativeAbs[#, u, ass] & /@ List @@ e];
specialNativeAbs[e_Times, u_, ass_] := Times @@ (specialNativeAbs[#, u, ass] & /@ List @@ e);
specialNativeAbs[Power[E, phase_], u_, ass_] := Exp[Refine[Re[phase], ass && u > 0]];
specialNativeAbs[(Sin | Cos)[phase_], u_, ass_] := Exp[Abs[Refine[Im[phase], ass && u > 0]]];
specialNativeAbs[e_, u_, ass_] := Module[{value},
  value = specialNativeTry[FullSimplify[Abs[e], ass && u > 0]];
  If[value === $Failed, Abs[e], value]];

specialNativeMultiply[{a_, r_}, {b_, s_}, u_, ass_] :=
  {a b, If[s === 0, 0, specialNativeAbs[a, u, ass] s] +
    If[r === 0, 0, specialNativeAbs[b, u, ass] r] + r s};

specialNativeTree[e_, u_, ass_, limit_] := Module[
  {head = Head[e], result, argument, value, error, power, rows, coefficient, term},
  If[LeafCount[e] > limit, fail["ResourceLimit", "The native special-function expansion exceeds MaxTerms."]];
  If[FreeQ[e, _SeriesData],
    If[! FreeQ[e, _Series | _Derivative | Indeterminate | _DirectedInfinity],
      fail["UnresolvedNativeSeries", "The native expansion contains an unresolved function or nonfinite coefficient."]];
    Return[{e, 0}, Module]];
  Switch[head,
    SeriesData,
      If[e[[1]] =!= u || e[[2]] =!= 0 || ! IntegerQ[e[[6]]] || e[[6]] < 1,
        fail["UnsupportedNativeCoordinate", "Native series must use the recorded positive local variable at zero."]];
      rows = e[[3]]; result = {0, 0};
      Do[
        coefficient = specialNativeTree[rows[[k]], u, ass, limit];
        term = specialNativeMultiply[coefficient, {u^((e[[4]] + k - 1)/e[[6]]), 0}, u, ass];
        result += term,
        {k, Length[rows]}];
      (* SeriesData does not encode the logarithmic degree of its unknown
         tail. A half-lattice-step loss absorbs every fixed logarithmic
         polynomial. A sharper returned boundary comes from an explicitly
         computed omitted block, never a degree guessed from kept terms. *)
      result + {0, PowerLogRemainder[u, Sequence @@ nativeSeriesTailPrecision[e]]},
    Plus,
      Total[specialNativeTree[#, u, ass, limit] & /@ List @@ e],
    Times,
      Fold[specialNativeMultiply[#1, #2, u, ass] &, {1, 0},
        specialNativeTree[#, u, ass, limit] & /@ List @@ e],
    Power,
      If[e[[1]] === E,
        argument = specialNativeTree[e[[2]], u, ass, limit];
        If[! specialNativeSmallQ[argument[[2]], u, ass],
          fail["InsufficientNativePhasePrecision", "A native exponential phase must have vanishing absolute error."]];
        Return[{Exp[argument[[1]]], Exp[specialNativeReal[argument[[1]], u, ass]] argument[[2]]}, Module]];
      argument = specialNativeTree[e[[1]], u, ass, limit]; power = e[[2]];
      If[! FreeQ[power, _SeriesData] || ! exactRealQ[power],
        fail["UnsupportedNativePower", "A native series power requires a fixed exact real exponent."]];
      If[IntegerQ[power] && power >= 0,
        If[power > limit, fail["ResourceLimit", "The native polynomial power exceeds MaxTerms."]];
        Return[Fold[specialNativeMultiply[#1, argument, u, ass] &, {1, 0}, Range[power]], Module]];
      If[! TrueQ[specialNativeTry[FullSimplify[argument[[1]] > 0, ass && u > 0]]] ||
          ! specialNativeSmallQ[argument[[2]]/argument[[1]], u, ass],
        fail["UnprovedNativePowerBranch", "The native power needs a positive leading approximation and vanishing relative error."]];
      {argument[[1]]^power, argument[[1]]^(power - 1) argument[[2]]},
    Sin | Cos | Sinh | Cosh,
      argument = specialNativeTree[First[e], u, ass, limit];
      value = argument[[1]]; error = argument[[2]];
      If[MemberQ[{Sin, Cos}, head] && TrueQ[specialNativeTry[FullSimplify[Element[value, Reals], ass && u > 0]]],
        Return[{head[value], error}, Module]];
      If[! specialNativeSmallQ[error, u, ass],
        fail["InsufficientNativePhasePrecision", "A complex or hyperbolic phase requires vanishing absolute error."]];
      {head[value], Exp[Abs[If[MemberQ[{Sin, Cos}, head], Im[value], Re[value]]]] error},
    _, fail["UnsupportedNativeSeriesTree", "The native series contains an unsupported operation on a truncated argument.", <|"Head" -> head|>]]];

(* Split finite terms into real exponential carriers and algebraic weights.
   Oscillations remain coefficients with absolute bounds, never a nonzero
   leading coefficient from which division could infer a branch. *)
specialNativeTerm[term_, u_, ass_] := Module[{factors, carrier = 1, weight = 0, coefficient = 1},
  factors = If[Head[term] === Times, List @@ term, {term}];
  Do[Which[
    factor === u, weight += 1,
    MatchQ[factor, Power[u, _?exactRealQ]], weight += factor[[2]],
    MatchQ[factor, Power[E, _]] && ! FreeQ[factor, u], carrier *= factor,
    MatchQ[factor, Power[u, _]] && TrueQ[specialNativeTry[FullSimplify[Element[factor[[2]], Reals], ass]]], carrier *= factor,
    True, coefficient *= factor], {factor, factors}];
  {carrier, canon[weight], coefficient}];

specialNativeCoefficientDegree[c_, u_, ass_] := Module[{q, ell = Unique["nativeLog$"], oscillations, modes},
  oscillations = DeleteDuplicates[Cases[c, node : (Sin[_] | Cos[_]) /; ! FreeQ[node, u], {0, Infinity}]];
  If[! AllTrue[oscillations, TrueQ[specialNativeTry[FullSimplify[Element[First[#], Reals], ass && u > 0]]] &],
    fail["UnprovedNativeOscillation", "Oscillatory coefficient phases must be real."]];
  modes = Table[Unique["boundedMode$"], {Length[oscillations]}];
  q = c /. Thread[oscillations -> modes] /. Log[u] -> ell;
  If[! FreeQ[q, u] || ! PolynomialQ[q, Prepend[modes, ell]],
    fail["UnsupportedNativeCoefficient", "A native amplitude must have polynomial logarithmic coefficients and bounded real sine/cosine modes.", <|"Coefficient" -> c|>]];
  Max[0, Exponent[q, ell]]];

specialNativeSectors[expression_, u_, ass_] := Module[{expanded, terms, groups, result},
  expanded = Expand[expression];
  terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  groups = GatherBy[specialNativeTerm[#, u, ass] & /@ terms, First];
  result = Function[group, Module[{rows, alpha, carrier = group[[1, 1]], oscillatory},
    rows = GatherBy[group, #[[2]] &];
    rows = {#[[1, 2]], specialNativeTry[FullSimplify[Total[#[[All, 3]]], ass && u > 0]]} & /@ rows;
    If[! FreeQ[rows, $Failed], fail["ResourceLimit", "Native amplitude simplification exceeded its time budget."]];
    rows = orderedWeightGroups[Select[rows, #[[2]] =!= 0 &]];
    rows = If[Length[#] === 1, First[#], {#[[1, 1]],
      specialNativeTry[FullSimplify[Total[#[[All, 2]]], ass && u > 0]]}] & /@ rows;
    If[! FreeQ[rows, $Failed], fail["ResourceLimit", "Native amplitude simplification exceeded its time budget."]];
    rows = Select[rows, #[[2]] =!= 0 &];
    If[rows === {}, Return[Nothing, Module]];
    oscillatory = ! FreeQ[rows, (Sin | Cos)[_]];
    alpha = If[carrier =!= 1 || oscillatory, rows[[1, 1]], 0];
    <|"Carrier" -> carrier u^alpha, "OriginalCarrier" -> carrier, "LeadingPower" -> alpha,
      "Rows" -> ({canon[#[[1]] - alpha], #[[2]], specialNativeCoefficientDegree[#[[2]], u, ass]} & /@ rows),
      "Oscillatory" -> oscillatory|>]] /@ groups;
  result];

specialNativeExactPart[source_, u_, ass_] := Module[{pieces, accepted = {}, sectors, phases},
  pieces = If[Head[source] === Plus, List @@ source, {source}];
  Do[
    If[specialNativeCandidateQ[piece, u], Continue[]];
    sectors = catch[specialNativeSectors[piece, u, ass]];
    If[! ListQ[sectors], Continue[]];
    phases = Cases[piece, Power[E, phase_] | (Sin | Cos)[phase_] :> phase, {0, Infinity}];
    If[AllTrue[Select[phases, ! FreeQ[#, u] &],
        MemberQ[{Infinity, -Infinity}, specialNativeTry[Limit[#, u -> 0,
          Direction -> "FromAbove", Assumptions -> ass]]] &], AppendTo[accepted, piece]],
    {piece, pieces}];
  Total[accepted]];

specialNativeTruncate[sectors_, u_, cut_, goal_, ass_] := Module[
  {expression = 0, remainder = 0, result = {}, rows, kept, omitted, frontier, degree, threshold},
  Do[
    rows = sector["Rows"]; threshold = cut;
    If[cut === Automatic, threshold = If[Length[rows] > goal, rows[[goal + 1, 1]], Infinity]];
    kept = Select[rows, less[#[[1]], threshold] &];
    If[IntegerQ[goal] && Length[kept] > goal, kept = Take[kept, goal]];
    omitted = Drop[rows, Length[kept]];
    expression += sector["Carrier"] Total[u^#[[1]] #[[2]] & /@ kept];
    frontier = If[omitted === {}, Missing["NativeFrontier"], First[omitted]];
    If[omitted =!= {},
      degree = Max[omitted[[All, 3]]];
      remainder += specialNativeAbs[sector["Carrier"], u, ass] PowerLogRemainder[u, First[omitted][[1]], degree]];
    AppendTo[result, Join[sector, <|"Rows" -> kept, "Cutoff" -> threshold, "Frontier" -> frontier|>]],
    {sector, sectors}];
  <|"Expression" -> expression, "Remainder" -> remainder, "Sectors" -> result|>];

specialNativeOrderedResult[truncated_, remainder_, u_, x_, coord_, ass_, domain_, limit_] := Module[
  {sectors = truncated["Sectors"], sector, ell = Unique["nativeLog$"], bound, envelope, precision,
    rows, representation},
  If[Length[sectors] =!= 1 || TrueQ[First[sectors]["Oscillatory"]], Return[$Failed, Module]];
  sector = First[sectors];
  rows = ({#[[1]], #[[2]] /. Log[u] -> ell} & /@ sector["Rows"]);
  If[! FreeQ[rows, u], Return[$Failed, Module]];
  If[remainder === 0, precision = {Infinity, 0},
    bound = specialNativeTry[FullSimplify[specialNativeBound[remainder]/Abs[sector["Carrier"]], ass && u > 0]];
    If[bound === $Failed, Return[$Failed, Module]];
    envelope = catch[exactJet[bound, u, ell, ass, limit]];
    If[! MatchQ[envelope, {_List, Infinity, _}] || envelope[[1]] === {}, Return[$Failed, Module]];
    precision = {envelope[[1, 1, 1]], polyDegree[envelope[[1, 1, 2]], ell]}];
  representation = <|"Variable" -> x, "ScaleVariable" -> coord["LocalVariable"],
    "LogVariable" -> ell, "Assumptions" -> ass, "Domain" -> domain,
    "Offset" -> 0, "Prefactor" -> (sector["Carrier"] /. u -> coord["LocalVariable"]),
    "Jet" -> {rows, precision[[1]], precision[[2]]}, "Cutoff" -> sector["Cutoff"],
    "RemainderDerivativeOrder" -> If[remainder === 0, Infinity, 0]|>;
  seriesMake[representation, {"NativeSpecialFunctionExpansion", {}}, Automatic]];

specialFunctionForwardExpansion[f_, x_, x0_, cut_, ass_, coord_, goal_, limit_] := Module[
  {domain, normalized, source, u = coord["u"], order, raw, data, expression, sectors,
    truncated, remainder, work = 0, enough, exact, result, restored, localDomain,
    exactPart, uncertainExpression, uncertainSectors, uncertainCarriers, ordinary},
  If[! specialNativeCandidateQ[f, x], Return[$Failed, Module]];
  validateInput[f, limit];
  If[goal =!= Automatic && (! IntegerQ[goal] || goal < 1),
    fail["InvalidTermGoal", "SeriesTermGoal must be a positive integer or Automatic."]];
  If[cut === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give an exponent cutoff or SeriesTermGoal -> n."]],
    If[! exactRealQ[cut], fail["InvalidCutoff", "The cutoff must be an exact real number."]]];
  domain = specialFunctionRealDomain[f, x, coord, ass, limit];
  If[! AssociationQ[domain], fail["UnprovedSpecialFunctionDomain", "The special-function expression must have a proved real branch on the requested approach."]];
  normalized = specialFunctionNormalize[f, x, coord, ass, limit];
  If[! MemberQ[{Infinity, -Infinity}, x0],
    ordinary = Quiet[TimeConstrained[catch[forwardCore[normalized["Expression"], x, x0, cut,
      Assumptions -> ass, Direction -> coord["Direction"], SeriesTermGoal -> goal, "MaxTerms" -> limit]], 30, $Failed]];
    If[MatchQ[ordinary, _GeneralizedSeries], Return[GeneralizedSeries[Join[ordinary[[1]],
      <|"Function" -> f, "TargetDomain" -> domain["Domain"] && normalized["Domain"],
        "RealDomainProof" -> domain, "NormalizedExpression" -> normalized["Expression"]|>]], Module]]];
  localDomain = ass && ((domain["Domain"] && normalized["Domain"]) /. x -> coord["Substitution"]);
  source = normalized["Expression"] /. x -> coord["Substitution"];
  exactPart = specialNativeExactPart[source, u, ass];
  order = If[cut === Automatic, Max[3, goal + 1], Max[3, Ceiling[cut] + 2]];
  While[True,
    If[++work > 8 || order + 1 > limit, fail["ResourceLimit", "Native special-function expansion exceeded its working-order budget."]];
    raw = Quiet[TimeConstrained[Series[source - exactPart, {u, 0, order}, Assumptions -> ass && u > 0,
      Analytic -> False], 30, $Failed]];
    If[raw === $Failed || ! FreeQ[raw, _Series], fail["UnsupportedSpecialFunctionExpansion", "Wolfram Series did not supply a structured expansion on this approach."]];
    raw = Refine[raw, localDomain && u > 0];
    data = specialNativeTree[raw, u, ass, limit];
    uncertainExpression = specialNativeReal[data[[1]], u, ass] /. {
      HoldPattern[Sinh[z_]] :> (Exp[z] - Exp[-z])/2,
      HoldPattern[Cosh[z_]] :> (Exp[z] + Exp[-z])/2};
    uncertainSectors = specialNativeSectors[uncertainExpression, u, ass];
    uncertainCarriers = Lookup[uncertainSectors, "OriginalCarrier", {}];
    expression = uncertainExpression + exactPart;
    sectors = If[exactPart === 0, uncertainSectors, specialNativeSectors[expression, u, ass]];
    exact = TrueQ[specialNativeTry[FullSimplify[source == expression, localDomain && u > 0]]];
    If[FreeQ[raw, _SeriesData] && ! exact,
      fail["UnresolvedNativeSeries", "A finite native result without a remainder is accepted only after exact equality with the source is established."]];
    enough = exact || (sectors =!= {} && uncertainSectors =!= {} && (cut =!= Automatic || AllTrue[sectors,
      Length[#["Rows"]] > goal || ! MemberQ[uncertainCarriers, #["OriginalCarrier"]] ||
      (#["OriginalCarrier"] === 1 && FreeQ[Total[#["Rows"][[All, 2]]], u] &&
        And @@ (# == 0 & /@ #["Rows"][[All, 1]])) &]));
    If[enough,
      truncated = specialNativeTruncate[sectors, u, cut, goal, ass];
      If[! exact, enough = truncated["Remainder"] =!= 0 &&
        specialNativeSmallQ[data[[2]]/specialNativeBound[truncated["Remainder"]], u, ass]]];
    If[enough, Break[]]; order = 2 order + 1];
  (* A nonexact exit has already proved the native error negligible beside
     this truncation's remainder. Reuse that accepted bound and its proof. *)
  remainder = truncated["Remainder"];
  restored = {u -> coord["LocalVariable"]};
  result = specialNativeOrderedResult[truncated, remainder, u, x, coord, ass,
    domain["Domain"] && normalized["Domain"], limit];
  If[result === $Failed, result = seriesEnvelopeMake[truncated["Expression"] /. restored, remainder /. restored,
    <|"Variable" -> x, "Assumptions" -> ass, "Domain" -> domain["Domain"] && normalized["Domain"],
      "Approach" -> <|"Variable" -> x, "Point" -> x0, "Direction" -> coord["Direction"]|>|>,
    <|"Operation" -> "NativeSpecialFunctionExpansion", "Source" -> f|>, limit]];
  GeneralizedSeries[Join[result[[1]], <|"Kind" -> "Forward", "Function" -> f,
    "Expression" -> Refine[result["Expression"], ass && domain["Domain"] && normalized["Domain"]],
    "Remainder" -> Refine[result["Remainder"], ass && domain["Domain"] && normalized["Domain"]],
    "RemainderScaleExpression" -> Refine[result["RemainderScaleExpression"], ass && domain["Domain"] && normalized["Domain"]],
    "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "NativeSectors" -> (truncated["Sectors"] /. restored), "NativeSeriesOrder" -> order,
    "NormalizedExpression" -> normalized["Expression"], "RequestedCutoff" -> cut,
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Total[Length[#["Rows"]] & /@ truncated["Sectors"]],
    "ExpansionNature" -> "Poincare", "NativeSeriesBackend" -> "Wolfram Series with Analytic -> False",
    "ExactSourceEqualityVerified" -> exact, "RealDomainProof" -> domain,
    "TermConvention" -> "Each exact carrier has an amplitude in powers of the positive local coordinate with polynomial logarithms and bounded oscillations. Cutoffs and term goals apply separately to amplitude blocks; exact constant offsets are retained. Oscillatory and distinct exponential sectors retain separate absolute error bounds.",
    "AsymptoticReferences" -> Join[Lookup[domain, "References", {}], normalized["References"],
      {"https://reference.wolfram.com/language/ref/Series.html", "https://dlmf.nist.gov/2.1.iii"}]|>]]];
