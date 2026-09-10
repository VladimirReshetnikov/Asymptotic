(* Explicit calculus for expansions.  A representation means
   Offset + Prefactor (Jet + remainder), in the positive ScaleVariable.
   The prefactor is exact; the jet precision is relative to that prefactor. *)

Scan[(Options[#] = {"Cutoff" -> Automatic, "MaxTerms" -> 20000}) &,
  {AsymptoticAnalysis`SeriesAdd, AsymptoticAnalysis`SeriesMultiply,
   AsymptoticAnalysis`SeriesPower, AsymptoticAnalysis`SeriesLog,
   AsymptoticAnalysis`SeriesExp, AsymptoticAnalysis`SeriesCompose,
   AsymptoticAnalysis`SeriesObservable}];
Options[AsymptoticAnalysis`SeriesTruncate] = {"MaxTerms" -> 20000};
Options[AsymptoticAnalysis`SeriesRefine] = {"MaxTerms" -> 20000, "MaxRefinements" -> 128};
Options[AsymptoticAnalysis`SeriesDifferentiate] = {
  "Cutoff" -> Automatic, "MaxTerms" -> 20000,
  "RemainderDerivativeOrder" -> Automatic};

seriesAss[d_] := d["Assumptions"] && Lookup[d, "Domain", True] && d["ScaleVariable"] > 0;
seriesJetExpression[j_, w_, ell_] := Total[(w^#[[1]] (#[[2]] /. ell -> Log[w])) & /@ j[[1]]];
seriesBound[a_Association] := Lookup[a, "RemainderScaleExpression",
  a["Remainder"] /. rr_PowerLogRemainder :> remainderScale[rr]];

seriesTrim[j : {rows_, p_, deg_}, h_, ell_, ass_] := Module[{omitted, pd = {p, deg}},
  If[h === Infinity, Return[j, Module]];
  omitted = Select[rows, ! less[#[[1]], h] &];
  If[omitted =!= {}, pd = combinePrecision[pd, {omitted[[1, 1]], polyDegree[omitted[[1, 2]], ell]}]];
  {jetTrim[rows, minOf[h, pd[[1]]], ell, ass], pd[[1]], pd[[2]]}];

seriesWorkingCut[d_, requested_] := Module[{h = requested, p = d["Jet"][[2]], rows = d["Jet"][[1]]},
  If[h === Automatic, h = Lookup[d, "Cutoff", Automatic]];
  If[h === Automatic || h === Infinity,
    h = If[p =!= Infinity, p, If[rows === {}, 1, Max[1, Last[rows][[1]] + 1]]]];
  If[! exactRealQ[h], fail["InvalidCutoff", "A series operation cutoff must be an exact real number."]]; h];

seriesData[s : GeneralizedSeries[a_Association], limit_] := Module[
  {d, base, rules, ell, w, j, var, off = 0, pref = 1, u, rows, coord},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  (* Missing native order metadata must not become an infinite-precision jet. *)
  requireAnalyticSeries[s];
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[a, "Kind", ""]],
    fail["UnsupportedScale", "This operation requires polynomial logarithmic coefficients. The Gamma/Barnes inverse scales support SeriesTruncate, SeriesRefine, SeriesPower, inverse checks, and the constructor's Power observable."]];
  If[AssociationQ[Lookup[a, "SeriesRepresentation", None]], Return[a["SeriesRepresentation"], Module]];
  If[MatchQ[Lookup[a, "CoordinateSeries", None], _GeneralizedSeries],
    base = seriesData[a["CoordinateSeries"], limit]; rules = Lookup[a, "CoordinateSubstitution", {}];
    d = base /. rules; Return[Join[d, <|"Variable" -> a["Variable"],
      "Domain" -> Lookup[a, "TargetDomain", Lookup[d, "Domain", True]]|>], Module]];
  If[Lookup[a, "Truncation", "Exponent"] === "Depth",
    fail["UnsupportedScale", "Series calculus requires a provably ordered exponent scale; refine a depth expansion with parameter values first."]];
  var = a["Variable"]; ell = Unique["ell$"]; w = Lookup[a, "RemainderVariable", Missing["Scale"]];
  If[MissingQ[w], fail["UnsupportedScale", "This result has no single power-log scale."]];
  If[Lookup[a, "Scale", "PowerLog"] === "Logarithmic",
    pref = a["Prefactor"];
    If[Lookup[a, "LambertCoreType", ""] === "PowerLog" && Lookup[a, "Power", 1] === 1 &&
       ! MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], off = a["ExpansionPoint"]];
    rows = a["Blocks"] /. a["LogVariable"] -> ell,
    If[Lookup[a, "Kind", ""] === "Forward", rows = a["Blocks"] /. a["LogVariable"] -> ell,
      d = <|"Variable" -> var, "ScaleVariable" -> w, "LogVariable" -> ell,
        "Assumptions" -> Lookup[a, "Assumptions", True], "Domain" -> Lookup[a, "TargetDomain", True]|>;
      j = seriesExpressionJet[a["Expression"], d, limit];
      If[j === $Failed, fail["UnsupportedScale", "The finite expression could not be expressed in its recorded power-log coordinate."]];
      rows = j[[1]]]];
  <|"Variable" -> var, "ScaleVariable" -> w, "LogVariable" -> ell,
    "Prefactor" -> pref, "Offset" -> off,
    "Jet" -> {rows, Lookup[a, "RemainderPower", Infinity], Lookup[a, "RemainderLogDegree", 0]},
    "Assumptions" -> Lookup[a, "Assumptions", True], "Domain" -> Lookup[a, "TargetDomain", True],
    "Cutoff" -> Lookup[a, "Cutoff", Automatic],
    "RemainderDerivativeOrder" -> Which[a["Remainder"] === 0, Infinity,
      Lookup[a, "Kind", ""] === "Forward" && MatchQ[Lookup[a, "Precision", None], {Infinity, _}], Infinity,
      True, Lookup[a, "RemainderDerivativeOrder", 0]]|>];

(* Only invert the explicitly recorded coordinate. No inversion of the unknown
   function represented by the expansion is attempted here. *)
seriesCoordinateRule[d_, u_] := Module[{w = d["ScaleVariable"], x = d["Variable"], offset, sol},
  If[w === x, Return[x -> u, Module]];
  If[w === 1/x, Return[x -> 1/u, Module]];
  If[w === -1/x, Return[x -> -1/u, Module]];
  (* Standard charts have exact real offsets. Leave parameter-dependent
     and other coordinates to the real solver's existing branch checks. *)
  offset = w - x;
  If[FreeQ[offset, x] && exactRealQ[offset], Return[x -> u - offset, Module]];
  offset = w + x;
  If[FreeQ[offset, x] && exactRealQ[offset], Return[x -> offset - u, Module]];
  sol = Quiet[TimeConstrained[Solve[w == u, x, Reals], 3, $Failed]];
  If[! ListQ[sol] || Length[sol] =!= 1 || ! MatchQ[First[sol], {_Rule}], Return[$Failed, Module]];
  First[First[sol]]];

seriesExpressionJet[e_, d_, limit_] := Module[{u = Unique["w$"], rule, q, probe, ass = seriesAss[d], ell = d["LogVariable"]},
  If[FreeQ[e, d["Variable"]], Return[pConst[e, ell, ass], Module]];
  rule = seriesCoordinateRule[d, u]; If[rule === $Failed, Return[$Failed, Module]];
  q = Simplify[e /. rule, (ass /. rule) && u > 0];
  probe = catch[exactJet[q, u, ell, ass /. rule, limit]];
  If[FailureQ[probe],
    If[MatchQ[probe, Failure["ResourceLimit", _Association]], Throw[probe, $tag], $Failed], probe]];

seriesFlat[d_, limit_] := Module[{p, b, j, ass = seriesAss[d], ell = d["LogVariable"]},
  If[d["Prefactor"] === 1 && d["Offset"] === 0, Return[d, Module]];
  p = seriesExpressionJet[d["Prefactor"], d, limit];
  b = seriesExpressionJet[d["Offset"], d, limit];
  If[p === $Failed || b === $Failed, Return[$Failed, Module]];
  j = pAdd[pMul[p, d["Jet"], ell, ass, limit], b, ell, ass];
  Join[d, <|"Prefactor" -> 1, "Offset" -> 0, "Jet" -> j|>]];

seriesMake[d0_, recipe_, cutoff_: Automatic] := Module[{d = d0, j, w, ell, p, off, expr, rem, terms},
  {j, w, ell, p, off} = Lookup[d, {"Jet", "ScaleVariable", "LogVariable", "Prefactor", "Offset"}];
  j = {realCoefficientRows[j[[1]], ell, seriesAss[d]], j[[2]], j[[3]]};
  If[cutoff =!= Automatic, j = seriesTrim[j, cutoff, ell, seriesAss[d]]];
  If[j[[1]] === {} && j[[2]] === Infinity, p = 1];
  d = Join[d, <|"Jet" -> j, "Prefactor" -> p, "Cutoff" -> cutoff,
    "RemainderDerivativeOrder" -> If[j[[2]] === Infinity, Infinity, Lookup[d, "RemainderDerivativeOrder", 0]]|>];
  expr = off + p seriesJetExpression[j, w, ell];
  rem = If[j[[2]] === Infinity, 0, Abs[p] PowerLogRemainder[w, j[[2]], j[[3]]]];
  terms = {#[[1]], #[[2]] /. ell -> Log[w]} & /@ j[[1]];
  GeneralizedSeries[<|"Kind" -> "Derived", "Scale" -> If[p === 1, "PowerLog", "Factored"],
    "Expression" -> expr, "Remainder" -> rem,
    "RemainderScaleExpression" -> If[rem === 0, 0, Abs[p] w^j[[2]] (1 + Abs[Log[w]])^j[[3]]],
    "RemainderPower" -> j[[2]], "RemainderLogDegree" -> j[[3]], "RemainderVariable" -> w,
    "Prefactor" -> p, "Offset" -> off, "Blocks" -> j[[1]], "Terms" -> terms,
    "TermConvention" -> "Offset + Prefactor Sum[w^beta C[Log[w]]]; the cutoff applies inside the prefactor.",
    "LogVariable" -> ell, "Variable" -> d["Variable"], "Assumptions" -> d["Assumptions"],
    "TargetDomain" -> Lookup[d, "Domain", True], "Cutoff" -> cutoff,
    "Exact" -> (rem === 0), "RemainderDerivativeOrder" -> Lookup[d, "RemainderDerivativeOrder", 0],
    "SeriesRepresentation" -> d, "SeriesRecipe" -> recipe,
    "SeriesData" -> Missing["ExplicitCalculus"]|>]];

seriesCompatible[a_, b_] := Module[{ass = seriesAss[a] && seriesAss[b]},
  If[TrueQ[Simplify[Not[ass]]], fail["IncompatibleDomains", "The operands have conflicting branch domains."]];
  If[a["Variable"] =!= b["Variable"] ||
    ! TrueQ[Simplify[a["ScaleVariable"] == b["ScaleVariable"], ass]],
    fail["IncompatibleScales", "The operands must use the same variable and positive asymptotic coordinate."]]];

(* Structural idempotence only: no assumption-dependent simplification. *)
seriesStructuralAnd[conditions_List] := And @@ DeleteDuplicates[
  Flatten[(If[Head[#] === And, List @@ #, {#}] &) /@ conditions, 1]];

seriesAlign[a_, b_] := Join[b /. b["LogVariable"] -> a["LogVariable"],
  <|"Assumptions" -> seriesStructuralAnd[{a["Assumptions"], b["Assumptions"]}],
    "Domain" -> seriesStructuralAnd[{Lookup[a, "Domain", True], Lookup[b, "Domain", True]}]|>];

seriesBinary[op_, s_, t_, cut_, limit_] := Module[{a, b, af, bf, ratio, j, ell, ass, d, h, order},
  a = seriesData[s, limit]; b = seriesData[t, limit]; seriesCompatible[a, b]; b = seriesAlign[a, b];
  ell = a["LogVariable"]; ass = seriesAss[a] && seriesAss[b];
  order = Min[Lookup[a, "RemainderDerivativeOrder", 0], Lookup[b, "RemainderDerivativeOrder", 0]];
  af = seriesFlat[a, limit]; bf = seriesFlat[b, limit];
  If[af =!= $Failed && bf =!= $Failed, a = af; b = bf];
  If[op === "Add",
    ratio = seriesExpressionJet[Simplify[b["Prefactor"]/a["Prefactor"], ass], a, limit];
    If[ratio === $Failed, fail["IncompatibleCarriers", "Addition needs a power-log ratio of the exact prefactors; independent exponential sectors require separate truncation."]];
    j = pAdd[a["Jet"], pMul[ratio, b["Jet"], ell, ass, limit], ell, ass];
    d = Join[a, <|"Jet" -> j, "Offset" -> a["Offset"] + b["Offset"]|>],
    If[a["Offset"] =!= 0 || b["Offset"] =!= 0,
      fail["IncompatibleCarriers", "Multiplication of translated, non-power-log carriers requires explicit sector decomposition."]];
    j = pMul[a["Jet"], b["Jet"], ell, ass, limit];
    d = Join[a, <|"Jet" -> j, "Prefactor" -> a["Prefactor"] b["Prefactor"]|>]];
  d = Join[d, <|"Assumptions" -> seriesStructuralAnd[{a["Assumptions"], b["Assumptions"]}],
    "Domain" -> seriesStructuralAnd[{Lookup[a, "Domain", True], Lookup[b, "Domain", True]}],
    "RemainderDerivativeOrder" -> order|>];
  h = If[cut === Automatic, Automatic, seriesWorkingCut[d, cut]];
  seriesTransportArithmeticBound[op, s, t, seriesMake[d, {op, {s, t}}, h]]];

(* A quantitative forward tail bound survives a sum or product. With finite
   parts e1, e2 and true values t_i = e_i + r_i, |r_i| <= B_i under C_i:
     |t1 + t2 - e| <= B1 + B2 + |e1 + e2 - e|,
     |t1 t2 - e|   <= |e1| B2 + |e2| B1 + B1 B2 + |e1 e2 - e|,
   where e is the result's finite expression and the last term is the exact
   part discarded by the result's cutoff. An exact operand contributes zero.
   Signed lower bounds and constant-form bounds are not transported. This
   closes the arithmetic half of C22. *)
seriesTransportArithmeticBound[op_, s : GeneralizedSeries[a_Association], t : GeneralizedSeries[b_Association],
  result : GeneralizedSeries[r_Association]] := Module[{boundOf, e1, e2, e, bound, discarded, conditions},
  boundOf[data_] := Which[Lookup[data, "Remainder", None] === 0, {0, True},
    KeyExistsQ[data, "AbsoluteRemainderBound"] && KeyExistsQ[data, "RemainderBoundConditions"],
      {data["AbsoluteRemainderBound"], data["RemainderBoundConditions"]},
    True, $Failed];
  If[boundOf[a] === $Failed || boundOf[b] === $Failed, Return[result, Module]];
  If[Lookup[r, "Remainder", None] === 0 || ! FreeQ[{a["Expression"], b["Expression"]}, _GeneralizedSeries],
    Return[result, Module]];
  conditions = boundOf[a][[2]] && boundOf[b][[2]];
  (* Dirichlet scales store n^(-S) as (E^-S)^Log[n]; present both finite
     expressions in the constructor's own form before differencing. *)
  {e1, e2, e} = {a["Expression"], b["Expression"], r["Expression"]} /. (E^u_)^Log[n_Integer?Positive] :> n^u;
  discarded = Simplify[If[op === "Add", e1 + e2, e1 e2] - e, conditions];
  bound = If[op === "Add", boundOf[a][[1]] + boundOf[b][[1]],
    Abs[e1] boundOf[b][[1]] + Abs[e2] boundOf[a][[1]] + boundOf[a][[1]] boundOf[b][[1]]] +
    Simplify[Abs[discarded], conditions];
  GeneralizedSeries[Join[r, <|"AbsoluteRemainderBound" -> bound, "RemainderBoundConditions" -> conditions,
    "ArithmeticDiscardedPart" -> discarded,
    "ForwardRemainderContract" -> <|"Type" -> "TransportedThroughArithmetic", "Operation" -> op,
      "OperandContracts" -> {Lookup[a, "ForwardRemainderContract", Missing["Exact"]],
        Lookup[b, "ForwardRemainderContract", Missing["Exact"]]},
      "Statement" -> If[op === "Add",
        "The omitted tail of the sum is bounded in absolute value by the sum of the operand bounds plus Abs[ArithmeticDiscardedPart], the exact part of the sum of the finite expressions beyond the result's cutoff, under the conjunction of the operand conditions.",
        "The omitted tail of the product is bounded in absolute value by Abs[e1] B2 + Abs[e2] B1 + B1 B2 plus Abs[ArithmeticDiscardedPart], the exact part of the product of the finite expressions beyond the result's cutoff, under the conjunction of the operand conditions. Signed lower bounds and constant-form bounds are not transported."]|>|>]]];
seriesTransportArithmeticBound[_, _, _, result_] := result;

AsymptoticAnalysis`SeriesAdd[s_GeneralizedSeries, t_GeneralizedSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Add", s, t, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticAnalysis`SeriesMultiply[s_GeneralizedSeries, t_GeneralizedSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Multiply", s, t, OptionValue["Cutoff"], OptionValue["MaxTerms"]];

seriesConstant[c_, s_, limit_] := Module[{d = seriesData[s, limit]},
  If[! FreeQ[c, d["Variable"]], fail["InvalidConstant", "The scalar must be independent of the expansion variable."]];
  validateInput[c, limit];
  If[! TrueQ[Simplify[Element[c, Reals], seriesAss[d]]], fail["UnprovedRealCoefficient", "The scalar must be provably real under the series assumptions."]];
  seriesMake[Join[d, <|"Offset" -> 0, "Prefactor" -> 1,
    "Jet" -> pConst[c, d["LogVariable"], seriesAss[d]], "RemainderDerivativeOrder" -> Infinity|>], {"Constant", {s}, c}]];
AsymptoticAnalysis`SeriesAdd[s_GeneralizedSeries, c_ /; FreeQ[c, _GeneralizedSeries], opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Add", s, c, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticAnalysis`SeriesAdd[c_ /; FreeQ[c, _GeneralizedSeries], s_GeneralizedSeries, opts : OptionsPattern[]] :=
  AsymptoticAnalysis`SeriesAdd[s, c, opts];
AsymptoticAnalysis`SeriesMultiply[s_GeneralizedSeries, c_ /; FreeQ[c, _GeneralizedSeries], opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Multiply", s, c, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticAnalysis`SeriesMultiply[c_ /; FreeQ[c, _GeneralizedSeries], s_GeneralizedSeries, opts : OptionsPattern[]] :=
  AsymptoticAnalysis`SeriesMultiply[s, c, opts];

seriesPower[s_, r_, cut_, limit_, truncate_: True] := Module[{d, flat, ell, ass, h, j, alpha},
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[s[[1]], "Kind", ""]],
    Return[gammaInverseSeriesPower[s, r, cut, limit], Module]];
  If[! exactRealQ[r], fail["InvalidPower", "The power must be an exact real number."]];
  d = seriesData[s, limit]; flat = seriesFlat[d, limit]; If[flat =!= $Failed, d = flat];
  If[d["Offset"] =!= 0, fail["UnsupportedScale", "First separate the finite offset from this non-power-log carrier."]];
  If[r === 0 && d["Jet"][[1]] === {}, fail["IndeterminatePower", "A zeroth power requires a known nonzero leading term."]];
  If[! IntegerQ[r] && d["Jet"][[1]] === {} && d["Jet"][[2]] =!= Infinity,
    fail["UnknownLeadingTerm", "A pure remainder does not establish the real branch required by a noninteger power."]];
  ell = d["LogVariable"]; ass = seriesAss[d]; h = seriesWorkingCut[d, cut];
  alpha = If[d["Jet"][[1]] === {}, d["Jet"][[2]], jetValuation[d["Jet"][[1]]]];
  If[cut === Automatic && d["Jet"][[2]] =!= Infinity,
    h = canon[d["Jet"][[2]] + alpha (r - 1)]];
  If[! TrueQ[truncate] && alpha =!= Infinity,
    h = Max[h, alpha r + 1];
    If[d["Jet"][[2]] =!= Infinity, h = Max[h, d["Jet"][[2]] + alpha (r - 1)]]];
  If[! IntegerQ[r] && ! provablyPositive[d["Prefactor"], ass],
    fail["NonpositiveBase", "A fractional observable power needs a provably positive exact prefactor."]];
  j = fwdPower[d["Jet"], r, Unique["w$"], ell, ass, h, limit];
  seriesMake[Join[d, <|"Jet" -> j, "Prefactor" -> d["Prefactor"]^r|>], {"Power", {s}, r},
    If[cut === Automatic || ! TrueQ[truncate], Automatic, h]]];
AsymptoticAnalysis`SeriesPower[s_GeneralizedSeries, r_, opts : OptionsPattern[]] :=
  seriesArithmeticPublicPower[s, r, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticAnalysis`SeriesPower[s_GeneralizedSeries, r_, h_?exactRealQ, opts : OptionsPattern[]] :=
  seriesArithmeticPublicPower[s, r, h, OptionValue["MaxTerms"]];

seriesLog[s_, cut_, limit_] := Module[{d, flat, ell, ass, h, j, p},
  d = seriesData[s, limit]; flat = seriesFlat[d, limit]; If[flat =!= $Failed, d = flat];
  If[d["Offset"] =!= 0, fail["UnsupportedScale", "First separate the finite offset from this non-power-log carrier."]];
  ell = d["LogVariable"]; ass = seriesAss[d]; h = seriesWorkingCut[d, cut];
  If[! provablyPositive[d["Prefactor"], ass], fail["NonpositiveBase", "A real logarithm needs a provably positive prefactor."]];
  j = fwdLog[d["Jet"], Unique["w$"], ell, ass, h, limit];
  (* A positive prefactor can combine powers and exponentials (for example
     Stirling's factor); simplify its real logarithm before parsing the jet. *)
  p = seriesExpressionJet[FullSimplify[Log[d["Prefactor"]], ass], d, limit];
  If[p === $Failed, fail["UnsupportedScale", "The logarithm of the carrier is outside the recorded power-log coordinate."]];
  j = pAdd[p, j, ell, ass];
  seriesMake[Join[d, <|"Jet" -> j, "Prefactor" -> 1|>], {"Log", {s}}, h]];
AsymptoticAnalysis`SeriesLog[s_GeneralizedSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicUnary[Log, s, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticAnalysis`SeriesLog[s_GeneralizedSeries, h_?exactRealQ, opts : OptionsPattern[]] :=
  seriesArithmeticPublicUnary[Log, s, h, OptionValue["MaxTerms"]];

seriesExp[s_, cut_, limit_] := Module[{d, ell, ass, h, rows, big, small, carrier, j},
  d = seriesFlat[seriesData[s, limit], limit];
  If[d === $Failed, fail["UnsupportedScale", "Exponentiation needs its argument in a single power-log coordinate."]];
  ell = d["LogVariable"]; ass = seriesAss[d]; h = seriesWorkingCut[d, cut];
  If[! less[0, d["Jet"][[2]]],
    fail["InsufficientObservablePrecision", "Exponentiating an asymptotic approximation requires an absolute remainder tending to zero; refine the argument first."]];
  rows = d["Jet"][[1]]; big = Select[rows, ! less[0, #[[1]]] &]; small = Select[rows, less[0, #[[1]]] &];
  carrier = Exp[seriesJetExpression[{big, Infinity, 0}, d["ScaleVariable"], ell]];
  j = fwdExp[{small, d["Jet"][[2]], d["Jet"][[3]]}, Unique["w$"], ell, ass, h, limit];
  seriesMake[Join[d, <|"Jet" -> j, "Prefactor" -> carrier|>], {"Exp", {s}}, h]];
AsymptoticAnalysis`SeriesExp[s_GeneralizedSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicUnary[Exp, s, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticAnalysis`SeriesExp[s_GeneralizedSeries, h_?exactRealQ, opts : OptionsPattern[]] :=
  seriesArithmeticPublicUnary[Exp, s, h, OptionValue["MaxTerms"]];

(* Apply an expression to a precision-tracked jet. A unary Taylor germ is
   admitted only at a finite constant argument; its coefficients, including
   the precision of the inner argument, are composed by pUnitSeries. *)
seriesIndependentJet[e_, d_, cut_, limit_] := Module[{u, rule},
  If[FreeQ[e, d["Variable"]], Return[pConst[e, d["LogVariable"], seriesAss[d]], Module]];
  u = Unique["coefficientScale$"]; rule = seriesCoordinateRule[d, u];
  If[rule === $Failed, fail["UnsupportedObservableCoefficient", "A coefficient depending on the expansion variable needs its exact local coordinate."]];
  If[cut === Infinity, fwd[e /. rule, u, d["LogVariable"], seriesAss[d] /. rule, cut, limit],
    forwardJet[e /. rule, u, d["LogVariable"], seriesAss[d] /. rule, cut, limit]]];

(* Check the returned chart and known coefficient interval, independently of
   the order requested from Series. This preserves the existing analytic
   source-admission contract; formal SeriesData alone is not its proof. *)
seriesObservableTaylorData[h_, c_, sign_, n_, ass_] := Module[{u = Unique["v$"], native},
  native = Quiet[Series[h[c + sign u], {u, 0, n}, Assumptions -> ass && u > 0]];
  If[! MatchQ[native, _SeriesData] || Length[native] =!= 6 || ! ListQ[native[[3]]],
    fail["UnsupportedObservable", "The observable must have a regular Taylor expansion at the limiting argument."]];
  If[native[[1]] =!= u || native[[2]] =!= 0,
    fail["InvalidObservableNativeChart", "The observable Taylor result must use the requested local variable at zero.",
      <|"ExpectedVariable" -> u, "ExpectedCenter" -> 0, "NativeResult" -> native|>]];
  If[! IntegerQ[native[[4]]] || ! IntegerQ[native[[5]]] || native[[4]] < 0 ||
      native[[5]] < native[[4]] || native[[6]] =!= 1 || ! FreeQ[native[[3]], u],
    fail["UnsupportedObservable", "The observable must have a regular Taylor expansion at the limiting argument."]];
  If[native[[5]] < n,
    fail["InsufficientObservableNativeOrder", "The observable Taylor result does not cover the required coefficients.",
      <|"RequiredExclusiveOrder" -> n, "NativeExclusiveOrder" -> native[[5]], "NativeResult" -> native|>]];
  native];

seriesObservableTaylorCoefficient[native_, k_] := (
  If[k >= native[[5]],
    fail["InsufficientObservableNativeOrder", "The requested observable coefficient is beyond the returned Taylor endpoint.",
      <|"CoefficientOrder" -> k, "NativeExclusiveOrder" -> native[[5]]|>]];
  If[k >= native[[4]] && k - native[[4]] + 1 <= Length[native[[3]]],
    native[[3, k - native[[4]] + 1]], 0]);

seriesObservableIncrementSign[rows_, precision_, ell_, ass_] := Module[{lc},
  If[rows === {} || ! less[jetValuation[rows], precision], Return[0, Module]];
  lc = rows[[1, 2]];
  lc = (-1)^polyDegree[lc, ell] Coefficient[lc, ell, polyDegree[lc, ell]];
  Which[provablyPositive[lc, ass], 1, provablyNegative[lc, ass], -1, True, 0]];

(* A real-axis Taylor bound needs a real complete argument, even when an
   imaginary term is beyond the retained jet. Rename the formal input value
   without renaming assumptions about the actual expansion coordinate. *)
seriesObservableArgumentRealQ[argument_, x_, input_, d_] := Module[
  {value = Unique["observableValue$"], u = Unique["observableDomain$"], expression,
   ass = seriesAss[d], ell = d["LogVariable"], parameters, parts, center, sign, charts},
  expression = argument /. x -> value;
  If[TrueQ[Quiet[TimeConstrained[
      FullSimplify[Element[expression, Reals], ass && Element[value, Reals]], 2, False]]],
    Return[True, Module]];
  (* A shrinking value neighborhood with the source coordinate fixed would
     not prove a uniform bound on their joint path. The global proof above
     is sufficient in that case; this local fallback deliberately refuses. *)
  If[! FreeQ[expression, d["Variable"]], Return[False, Module]];
  parameters = DeleteDuplicates[Cases[expression,
    p_Symbol /; p =!= value && ! NumericQ[p], {0, Infinity}]];
  If[! TrueQ[Quiet[TimeConstrained[
      AllTrue[parameters, TrueQ[FullSimplify[Element[#, Reals], ass]] &], 2, False]]],
    Return[False, Module]];
  parts = splitJet[input[[1]]];
  If[parts[[1]] === {} && FreeQ[parts[[2]], ell],
    center = parts[[2]];
    If[! FreeQ[center, d["Variable"]], Return[False, Module]];
    sign = seriesObservableIncrementSign[parts[[3]], input[[2]], ell, ass];
    charts = If[sign === 0, {center, center + u, center - u}, {center + sign u}],
    sign = seriesObservableIncrementSign[input[[1]], input[[2]], ell, ass];
    If[sign === 0, Return[False, Module]];
    charts = {sign/u}];
  And @@ (TrueQ[Quiet[TimeConstrained[
      logarithmicRealCondition[Element[expression /. value -> #, Reals], ass, <|"u" -> u|>],
      2, False]]] & /@ charts)];

seriesJetApply[e_, x_, input_, d_, cut_, limit_] := Module[{h = Head[e], ell = d["LogVariable"], ass = seriesAss[d], j, parts, c, native, opposite, n, cf, res, sign, c0, point, compatible},
  Which[inverseFunctionApplicationQ[e], inverseFunctionJetApply[e, x, input, d, cut, limit],
    FreeQ[e, x], seriesIndependentJet[e, d, cut, limit], e === x, input,
    h === Plus, Fold[pAdd[#1, seriesJetApply[#2, x, input, d, cut, limit], ell, ass] &, pConst[0, ell, ass], List @@ e],
    h === Times, Fold[pMul[#1, seriesJetApply[#2, x, input, d, cut, limit], ell, ass, limit] &, pConst[1, ell, ass], List @@ e],
    h === Power && e[[1]] === E, fwdExp[seriesJetApply[e[[2]], x, input, d, cut, limit], x, ell, ass, cut, limit],
    h === Power && FreeQ[e[[2]], x], fwdPower[seriesJetApply[e[[1]], x, input, d, cut, limit], e[[2]], x, ell, ass, cut, limit],
    h === Log && Length[e] === 1, fwdLog[seriesJetApply[e[[1]], x, input, d, cut, limit], x, ell, ass, cut, limit],
    h === Abs, fwdAbs[seriesJetApply[e[[1]], x, input, d, cut, limit], ell, ass, x, cut, limit],
    Length[e] === 1,
      j = seriesJetApply[e[[1]], x, input, d, cut, limit]; parts = splitJet[j[[1]]];
      If[parts[[1]] =!= {} || ! FreeQ[parts[[2]], ell] || ! less[0, j[[2]]],
        fail["UnsupportedObservable", "A general analytic observable needs an argument tending to a finite constant."]];
      c = parts[[2]];
      (* An exact point uses the point value. A punctured germ instead uses
         its Taylor constant, which can differ at a jump discontinuity. *)
      If[parts[[3]] === {} && j[[2]] === Infinity, Return[pConst[h[c], ell, ass], Module]];
      If[! seriesObservableArgumentRealQ[e[[1]], x, input, d],
        fail["UnprovedObservableArgument", "A real-sided observable Taylor expansion requires its complete argument to be proved real on the input germ.",
          <|"Argument" -> e[[1]], "InputVariable" -> x|>]];
      n = If[parts[[3]] === {}, 1, Max[1, Ceiling[minOf[cut, j[[2]]]/jetValuation[parts[[3]]]]]];
      If[n > limit, fail["ResourceLimit", "Observable Taylor expansion exceeded MaxTerms."]];
      sign = seriesObservableIncrementSign[parts[[3]], j[[2]], ell, ass];
      native = seriesObservableTaylorData[h, c, If[sign === 0, 1, sign], n, ass];
      c0 = seriesObservableTaylorCoefficient[native, 0];
      If[sign === 0,
        opposite = seriesObservableTaylorData[h, c, -1, n, ass];
        point = h[c];
        (* An uncertain side can include visits to the center. With no
           retained increment only the common O(displacement) bound is used;
           otherwise both sides must supply the same Taylor polynomial. *)
        compatible = TimeConstrained[
          zeroQ[c0 - point, ass] && zeroQ[c0 - seriesObservableTaylorCoefficient[opposite, 0], ass] &&
            (parts[[3]] === {} || And @@ Table[
              zeroQ[seriesObservableTaylorCoefficient[native, k] -
                (-1)^k seriesObservableTaylorCoefficient[opposite, k], ass], {k, 1, n - 1}]),
          2, False];
        If[! TrueQ[compatible], fail["UnprovedObservableApproach",
          "The input has no proved side and the observable has no compatible Taylor bound on both sides and at the limiting point.",
          <|"LimitingArgument" -> c, "PositiveGermConstant" -> c0,
            "NegativeGermConstant" -> seriesObservableTaylorCoefficient[opposite, 0], "PointValue" -> point|>]]];
      (* The completed observable is checked by seriesMake after collection;
         separate analytic summands can have cancelling imaginary parts. *)
      cf = Function[k, seriesObservableTaylorCoefficient[native, k]];
      If[parts[[3]] === {}, Return[{jetMerge[{{0, c0}}, ell, ass], j[[2]], j[[3]]}, Module]];
      If[sign === -1, parts[[3]] = jetScale[parts[[3]], -1, ell, ass]];
      res = pUnitSeries[parts[[3]], j[[2]], j[[3]], cf, cut, ell, ass, limit];
      pAdd[pConst[c0, ell, ass], res, ell, ass],
    True, fail["UnsupportedObservable", "This observable is not in the supported algebra of regular unary analytic functions, powers, logarithms and exponentials."]]];

AsymptoticAnalysis`SeriesObservable[s_GeneralizedSeries, e_, x_Symbol, opts : OptionsPattern[]] := catch[Block[
  {$inverseFunctionBranchSelections = OptionValue["InverseFunctionBranches"], $inverseFunctionProvenance = {},
    $inverseFunctionSyntaxCache = <||>, $inverseFunctionBranchCache = <||>},
  Module[{d, h, j, body = e, condition = True, result, limit = OptionValue["MaxTerms"], exact},
  requireAnalyticSeries[s];
  validateInput[e, limit];
  (* Peel an outer ConditionalExpression before choosing a route, so that a
     proved condition on an exact carrier (Log, Exp, a power of the formal
     variable) still reaches the exact route instead of the generic Taylor
     germ, which refuses such carriers (wave-6 report 52 N3). *)
  While[Head[body] === ConditionalExpression, condition = condition && body[[2]]; body = body[[1]]];
  exact = Which[body === Log[x], "Log", body === Exp[x], "Exp",
    Head[body] === Power && body[[1]] === x && FreeQ[body[[2]], x], "Power", True, None];
  If[exact =!= None && condition === True,
    Return[Switch[exact, "Log", seriesLog[s, OptionValue["Cutoff"], limit],
      "Exp", seriesExp[s, OptionValue["Cutoff"], limit],
      "Power", seriesPower[s, body[[2]], OptionValue["Cutoff"], limit]], Module]];
  d = seriesFlat[seriesData[s, limit], limit];
  If[d === $Failed, fail["UnsupportedScale", "This observable requires a single power-log representation of its argument."]];
  h = seriesWorkingCut[d, OptionValue["Cutoff"]];
  If[! TrueQ[inverseFunctionConditionOnJet[condition, x, d["Jet"], d, h, limit]],
    fail["IncompatibleObservableCondition", "The observable condition is not proved on the precision-tracked input germ.", <|"Condition" -> condition|>]];
  If[exact =!= None,
    (* The condition was proved on the input germ; the exact route computes the
       carrier, and the conditional observable is retained as the replay recipe
       so refinement proves the condition again on the refined input. *)
    result = Switch[exact, "Log", seriesLog[s, OptionValue["Cutoff"], limit],
      "Exp", seriesExp[s, OptionValue["Cutoff"], limit],
      "Power", seriesPower[s, body[[2]], OptionValue["Cutoff"], limit]];
    Return[GeneralizedSeries[Join[result[[1]], <|"SeriesRecipe" -> {"Observable", {s}, e, x},
      "ObservableCondition" -> condition|>]], Module]];
  (* A modulus of a nonzero remainder keeps only the magnitude bound: a
     smooth input with infinitely many sign changes gives |F| infinitely many
     cusps, so no classical derivative contract survives (report 42 N01). *)
  j = Block[{$absorbedAbsRemainder = False},
    {seriesJetApply[body, x, d["Jet"], d, h, limit], $absorbedAbsRemainder}];
  result = seriesMake[Join[d, <|"Jet" -> j[[1]]|>,
    If[TrueQ[j[[2]]] && j[[1, 2]] =!= Infinity, <|"RemainderDerivativeOrder" -> 0|>, <||>]],
    {"Observable", {s}, e, x}, h];
  GeneralizedSeries[Join[result[[1]], <|"InverseFunctionBranches" -> $inverseFunctionBranchSelections,
    "InverseFunctionProvenance" -> DeleteDuplicates[$inverseFunctionProvenance]|>]]]]];

(* The coefficients alone do not record all fixed data of a remainder: a
   parameter may occur only in the discarded source or an operand recipe.
   Source variables of inverse equations and operand variables are bound. *)
seriesCompositionScope[s : GeneralizedSeries[data_Association], variable_] := Module[
  {outerVariable = Lookup[data, "Variable", None], sourceVariable, dependencies,
   source, recipe, operands = {}, extra = {}, scopes, known, captured},
  If[outerVariable === variable, Return[{True, False}, Module]];
  sourceVariable = Lookup[data, "SourceVariable",
    Replace[Lookup[data, "Variables", {}], {{x_Symbol, _Symbol} :> x, _ :> outerVariable}]];
  dependencies = KeyTake[data, {"Expression", "Assumptions", "TargetDomain", "Remainder",
    "RemainderScaleExpression", "RemainderPower", "RemainderLogDegree", "Prefactor", "Offset",
    "ExpansionPoint", "FixedParameters"}];
  source = If[sourceVariable === variable, {}, KeyTake[data, {"Function", "SourceDomain",
    "ConditionalSourceReplay", "ForwardModel", "InputRemainder", "DeclaredInputRemainder", "InputDomains"}]];
  recipe = Lookup[data, "SeriesRecipe", None];
  If[ListQ[recipe] && Length[recipe] >= 2 && ListQ[recipe[[2]]],
    operands = Select[recipe[[2]], MatchQ[#, _GeneralizedSeries] &];
    extra = Drop[recipe, 2];
    If[recipe[[1]] === "Observable" && Length[recipe] >= 4,
      extra = If[recipe[[4]] === variable, {}, {recipe[[3]]}]]];
  If[MatchQ[Lookup[data, "CoordinateSeries", None], _GeneralizedSeries],
    AppendTo[operands, data["CoordinateSeries"]];
    extra = {extra, Last /@ Lookup[data, "CoordinateSubstitution", {}]}];
  scopes = seriesCompositionScope[#, variable] & /@ DeleteDuplicates[operands];
  known = Lookup[data, "Remainder", None] === 0 || KeyExistsQ[data, "Function"] ||
    (scopes =!= {} && And @@ scopes[[All, 1]]);
  captured = ! FreeQ[{dependencies, source, extra}, variable] ||
    (scopes =!= {} && Or @@ scopes[[All, 2]]);
  {known, captured}];

seriesCompositionJointData[a_, b_, limit_] := Module[{ignored, ass, condition, u, rule, d},
  {ignored, ass, condition} = splitApproachInput[True, b["Variable"],
    a["Assumptions"] && b["Assumptions"]];
  If[TrueQ[Simplify[Not[ass]]], fail["IncompatibleDomains", "The operands have conflicting parameter assumptions."]];
  d = Join[b, <|"Assumptions" -> ass|>];
  u = Unique["jointScale$"]; rule = seriesCoordinateRule[d, u];
  If[rule === $Failed || ! inverseFunctionEventually[condition /. rule, u, ass],
    fail["IncompatibleCompositionParameters", "The outer parameter assumptions are not proved along the inner approach.",
      <|"Condition" -> condition, "Variable" -> b["Variable"]|>]];
  Join[d, <|"Domain" -> Lookup[d, "Domain", True] && condition|>]];

seriesCompositionCoordinate[a_, b_, h_, limit_, ass_] := Module[{wj, lc, ell = b["LogVariable"]},
  wj = seriesJetApply[a["ScaleVariable"], a["Variable"], b["Jet"], b, h, limit];
  If[wj[[1]] === {} || ! less[0, jetValuation[wj[[1]]]],
    fail["IncompatibleLimits", "The inner expansion must approach the outer expansion point from its recorded positive local side."]];
  lc = wj[[1, 1, 2]];
  If[! FreeQ[lc, ell] || ! provablyPositive[lc, ass],
    fail["UnsupportedCompositionScale", "Composition requires a positive monomial leading block for the outer local coordinate."]];
  wj];

(* Replay only a complete forward source along an exact forward inner germ.
   The old outer tail is discarded, not relabeled as uniform. The strict
   analytic constructor rechecks all original conditions in the new regime. *)
seriesCompositionSourceReplay[outer_, inner_, cut_, limit_] := Module[
  {oa = outer[[1]], ia = inner[[1]], source, a, b, h, expression, condition, result},
  If[Lookup[oa, "Kind", None] =!= "Forward" || ! KeyExistsQ[oa, "Function"] ||
     Lookup[ia, "Kind", None] =!= "Forward" || Lookup[ia, "Remainder", None] =!= 0 ||
     ! TrueQ[Lookup[ia, "Exact", False]], Return[$Failed, Module]];
  source = oa["Function"];
  If[! FreeQ[source, _PowerLogRemainder | _GeneralizedSeries | _SeriesData | _InverseFunction],
    Return[$Failed, Module]];
  a = seriesFlat[seriesData[outer, limit], limit]; b = seriesFlat[seriesData[inner, limit], limit];
  If[a === $Failed || b === $Failed, Return[$Failed, Module]];
  b = seriesCompositionJointData[a, b, limit]; h = seriesWorkingCut[b, cut];
  seriesCompositionCoordinate[a, b, h, limit, seriesAss[b]];
  If[! TrueQ[inverseFunctionConditionOnJet[Lookup[oa, "TargetDomain", True],
      oa["Variable"], b["Jet"], b, h, limit]],
    fail["IncompatibleTargetCondition", "The outer source condition is not proved on the joint approach.",
      <|"Condition" -> Lookup[oa, "TargetDomain", True]|>]];
  expression = Normal[inner];
  condition = Lookup[ia, "TargetDomain", True] && (Lookup[oa, "TargetDomain", True] /. oa["Variable"] -> expression);
  result = AsymptoticExpansion[ConditionalExpression[source /. oa["Variable"] -> expression, condition],
    {ia["Variable"], ia["ExpansionPoint"], h}, Assumptions -> (oa["Assumptions"] && ia["Assumptions"]),
    Direction -> ia["Direction"], "Backend" -> "Package", "MaxTerms" -> limit];
  If[! MatchQ[result, _GeneralizedSeries], Return[result, Module]];
  GeneralizedSeries[Join[result[[1]], <|"CompositionScope" -> <|
    "Method" -> "ReplayExactForwardSources", "CapturedParameter" -> ia["Variable"],
    "OuterVariable" -> oa["Variable"], "OriginalOuterRemainderTransported" -> False,
    "UniformParameterBoundAsserted" -> False|>|>]]];

seriesCompositionAdmission[outer_, inner_, cut_, limit_, replay_: True] := Module[{scope, captured, result},
  requireAnalyticSeries[outer]; requireAnalyticSeries[inner];
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[cut =!= Automatic && ! exactRealQ[cut], fail["InvalidCutoff", "A series operation cutoff must be an exact real number."]];
  scope = seriesCompositionScope[outer, Lookup[inner[[1]], "Variable", None]]; captured = scope[[2]];
  If[Lookup[outer[[1]], "Remainder", None] =!= 0,
    If[captured,
      result = If[TrueQ[replay], seriesCompositionSourceReplay[outer, inner, cut, limit], $Failed];
      If[result =!= $Failed, Return[{True, result}, Module]];
      fail["ParameterCapture", "The inner variable was fixed data of the outer remainder. A joint source expansion or a separately proved uniform bound is required.",
        <|"OuterVariable" -> outer["Variable"], "CapturedParameter" -> inner["Variable"], "UniformityEstablished" -> False|>]];
    If[! TrueQ[scope[[1]]], fail["MissingParameterScope", "The outer remainder has no retained source or operation provenance establishing its fixed-parameter scope."]]];
  {captured, $Failed}];

AsymptoticAnalysis`SeriesCompose[outer_GeneralizedSeries, inner_GeneralizedSeries, opts : OptionsPattern[]] := catch[Module[
  {a, b, wj, term, result, p, deg, alpha, ell, ass, h, captured,
   cut = OptionValue["Cutoff"], limit = OptionValue["MaxTerms"]},
  {captured, result} = seriesCompositionAdmission[outer, inner, cut, limit];
  If[result =!= $Failed, Return[result, Module]];
  If[! captured,
    result = reciprocalLogCompose[outer, inner, cut, limit];
    If[result =!= $Failed, Return[result, Module]]];
  a = seriesFlat[seriesData[outer, limit], limit]; b = seriesFlat[seriesData[inner, limit], limit];
  If[a === $Failed || b === $Failed, fail["UnsupportedScale", "Composition currently requires a single power-log representation of both operands."]];
  If[captured, b = seriesCompositionJointData[a, b, limit]];
  ell = b["LogVariable"]; ass = If[captured, seriesAss[b], seriesAss[a] && seriesAss[b]];
  h = seriesWorkingCut[b, cut];
  wj = seriesCompositionCoordinate[a, b, h, limit, ass]; alpha = jetValuation[wj[[1]]];
  If[captured && ! TrueQ[inverseFunctionConditionOnJet[Lookup[a, "Domain", True],
      a["Variable"], b["Jet"], b, h, limit]],
    fail["IncompatibleCompositionParameters", "The exact outer expression's domain is not proved on the joint approach."]];
  result = pConst[0, ell, ass];
  Do[term = pMul[fwdPower[wj, row[[1]], Unique["w$"], ell, ass, h, limit],
      seriesJetApply[row[[2]], a["LogVariable"], fwdLog[wj, Unique["w$"], ell, ass, h, limit], b, h, limit], ell, ass, limit];
    result = pAdd[result, term, ell, ass], {row, a["Jet"][[1]]}];
  {p, deg} = a["Jet"][[{2, 3}]];
  If[p =!= Infinity, result = pAdd[result, {{}, canon[alpha p], deg}, ell, ass]];
  seriesMake[Join[b, <|"Jet" -> result,
    "Assumptions" -> If[captured, b["Assumptions"], a["Assumptions"] && b["Assumptions"]],
    "Domain" -> Lookup[b, "Domain", True] && (Lookup[a, "Domain", True] /.
      a["Variable"] -> seriesJetExpression[b["Jet"], b["ScaleVariable"], b["LogVariable"]]),
    "RemainderDerivativeOrder" -> Min[Lookup[a, "RemainderDerivativeOrder", 0], Lookup[b, "RemainderDerivativeOrder", 0]]|>], {"Compose", {outer, inner}}, h]]];

AsymptoticAnalysis`SeriesTruncate[s_GeneralizedSeries, h_, opts : OptionsPattern[]] := catch[Module[{d},
  requireAnalyticSeries[s];
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[s[[1]], "Kind", ""]], Return[gammaInverseTruncate[s, h, OptionValue["MaxTerms"]], Module]];
  d = seriesData[s, OptionValue["MaxTerms"]];
  If[! exactRealQ[h], fail["InvalidCutoff", "The truncation cutoff must be an exact real number."]];
  seriesTransportRemainderBound[s, d, seriesMake[d, {"Truncate", {s}}, h]]]];

(* A quantitative forward tail bound survives truncation: the omitted tail
   after truncation is the discarded finite part plus the original tail, so
   |new tail| <= |discarded part| + old absolute bound on the same conditions.
   A signed lower bound and a constant-form bound describe only the original
   tail; they are retained only when truncation discards nothing. Bare
   asymptotic remainders carry no bound to transport. Sums and products
   transport the absolute bound through seriesTransportArithmeticBound. *)
seriesTransportRemainderBound[s : GeneralizedSeries[a_Association], d_, result : GeneralizedSeries[r_Association]] :=
  Module[{ell, w, p, before, after, removed, discarded, keys, retained, transported},
  If[! KeyExistsQ[a, "AbsoluteRemainderBound"] || ! KeyExistsQ[a, "RemainderBoundConditions"],
    Return[result, Module]];
  ell = d["LogVariable"]; w = d["ScaleVariable"]; p = d["Prefactor"];
  before = d["Jet"][[1]]; after = r["SeriesRepresentation"]["Jet"][[1]];
  (* A cutoff keeps a prefix of the ordered rows, so the discarded rows are
     the suffix; membership queries are needed only if the rows were
     reordered (wave-5 report 42 N03). *)
  removed = If[Length[after] <= Length[before] && Take[before, Length[after]] === after,
    Drop[before, Length[after]], Select[before, ! MemberQ[after, #] &]];
  If[! SubsetQ[before, after], Return[result, Module]];
  (* Dirichlet scales use w = E^(-S) with exponents Log[n]; present the
     discarded integer powers as n^(-S), the constructor's own form. *)
  discarded = p seriesJetExpression[{removed, r["RemainderPower"], r["RemainderLogDegree"]}, w, ell] /.
    (E^u_)^Log[n_Integer?Positive] :> n^u;
  (* A no-op truncation keeps every bound field, including the discarded
     part recorded by an earlier transport (wave-5 report 39 N01). *)
  keys = {"AbsoluteRemainderBound", "RemainderBoundConditions", "RemainderLowerBound",
    "RemainderBoundConstant", "ForwardRemainderContract", "FirstOmittedInteger", "FiniteSourceExpansion",
    "TruncationDiscardedPart"};
  If[removed === {}, Return[GeneralizedSeries[Join[r, KeyTake[a, keys]]], Module]];
  retained = KeyTake[a, {"AbsoluteRemainderBound", "RemainderBoundConditions"}];
  transported = <|"AbsoluteRemainderBound" -> a["AbsoluteRemainderBound"] + Simplify[Abs[discarded], a["RemainderBoundConditions"]],
    "RemainderBoundConditions" -> a["RemainderBoundConditions"],
    "TruncationDiscardedPart" -> discarded,
    "ForwardRemainderContract" -> <|"Type" -> "TransportedThroughTruncation",
      "OriginalContract" -> Lookup[a, "ForwardRemainderContract", Missing["NotAvailable"]],
      "OriginalAbsoluteRemainderBound" -> retained["AbsoluteRemainderBound"],
      "Statement" -> "The omitted tail of the truncated expansion is TruncationDiscardedPart plus the original tail, so its absolute value is at most Abs[TruncationDiscardedPart] plus the original AbsoluteRemainderBound under the unchanged RemainderBoundConditions. Signed lower bounds and constant-form bounds are not transported."|>|>;
  GeneralizedSeries[Join[r, transported]]];

seriesDerivative[s_, n_, declared_, cut_, limit_] := Module[{d, contract, ell, ass, j, q, wprime, pprime, first, second, result, k},
  If[! IntegerQ[n] || n < 0, fail["InvalidDerivativeOrder", "The derivative order must be a nonnegative integer."]];
  If[n =!= 0 || cut =!= Automatic, requireAnalyticSeries[s]];
  result = reciprocalLogDifferentiate[s, n, declared, cut, limit];
  If[result =!= $Failed, Return[result, Module]];
  If[n === 0, Return[s, Module]];
  d = seriesData[s, limit]; contract = Lookup[d, "RemainderDerivativeOrder", 0];
  If[declared =!= Automatic,
    If[declared =!= Infinity && (! IntegerQ[declared] || declared < 0), fail["InvalidDerivativeContract", "RemainderDerivativeOrder must be a nonnegative integer or Infinity."]];
    contract = Max[contract, declared]];
  If[contract < n, fail["UnprovedRemainderDerivative", "A magnitude Big-O bound cannot be differentiated. Supply RemainderDerivativeOrder -> n only when the corresponding derivative bounds are known.", <|"AvailableDerivativeOrder" -> contract, "RequestedDerivativeOrder" -> n|>]];
  result = s;
  Do[d = seriesData[result, limit]; ell = d["LogVariable"]; ass = seriesAss[d]; j = d["Jet"];
    q = {jetMerge[({#[[1]] - 1, #[[1]] #[[2]] + D[#[[2]], ell]} & /@ j[[1]]), ell, ass],
      If[j[[2]] === Infinity, Infinity, j[[2]] - 1], j[[3]]};
    wprime = D[d["ScaleVariable"], d["Variable"]]; pprime = D[d["Prefactor"], d["Variable"]];
    first = seriesMake[Join[d, <|"Jet" -> q, "Prefactor" -> d["Prefactor"] wprime,
      "Offset" -> D[d["Offset"], d["Variable"]], "RemainderDerivativeOrder" -> contract - k|>], {"DerivativeStep", {result}}];
    result = If[pprime === 0, first,
      second = seriesMake[Join[d, <|"Prefactor" -> pprime, "Offset" -> 0, "RemainderDerivativeOrder" -> contract - k|>], {"DerivativeStep", {result}}];
      seriesBinary["Add", first, second, Automatic, limit]], {k, n}];
  d = seriesData[result, limit];
  seriesMake[d, {"Differentiate", {s}, n, declared}, If[cut === Automatic, Automatic, seriesWorkingCut[d, cut]]]];
AsymptoticAnalysis`SeriesDifferentiate[s_GeneralizedSeries, n_Integer : 1, opts : OptionsPattern[]] :=
  catch[seriesDerivative[s, n, OptionValue["RemainderDerivativeOrder"], OptionValue["Cutoff"], OptionValue["MaxTerms"]]];

seriesRefinementResult[result_, original_, cutoff_] := Module[{data, stats},
  If[! MatchQ[result, _GeneralizedSeries], Return[result, Module]];
  data = result[[1]];
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[original[[1]], "Kind", ""]],
    data = Join[data, <|"TargetDomain" -> Lookup[original[[1]], "TargetDomain", True] &&
      Lookup[data, "TargetDomain", True]|>]];
  If[KeyExistsQ[data, "RefinementStatistics"], Return[GeneralizedSeries[data], Module]];
  stats = <|"Strategy" -> If[Lookup[original[[1]], "Kind", ""] === "Derived" &&
      KeyExistsQ[original[[1]], "SeriesRecipe"], "ReplayOperationRecipe", "ReplayOriginalSource"],
    "SourceCutoff" -> Lookup[original[[1]], "Cutoff", Missing["NotAvailable"]], "RequestedCutoff" -> cutoff,
    "ModelReused" -> False, "ReusedBlocks" -> 0,
    "NewCoefficientEvaluations" -> Missing["ReplayNotInstrumented"],
    "Evidence" -> "Recomputed from retained source or operation recipe; no coefficient reuse or work count is claimed."|>;
  GeneralizedSeries[Join[data, <|"RefinementStatistics" -> stats,
    "RefinementHistory" -> Append[Lookup[original[[1]], "RefinementHistory", {}], stats]|>]]];

AsymptoticAnalysis`SeriesRefine[s : GeneralizedSeries[a_Association], h_, opts : OptionsPattern[]] := catch[seriesRefinementResult[Module[
  {recipe, args, operands, r, limit = OptionValue["MaxTerms"], rules, base, x, y, sourceOptions, declared},
  requireAnalyticSeries[s];
  If[! exactRealQ[h], fail["InvalidCutoff", "The refinement cutoff must be an exact real number."]];
  If[KeyExistsQ[a, "InverseFunctionExpression"],
    Return[AsymptoticExpansion[a["InverseFunctionExpression"], {a["Variable"], a["InverseFunctionExpansionPoint"], h},
      Assumptions -> a["Assumptions"], Direction -> a["InverseFunctionExpansionDirection"],
      "InverseFunctionBranches" -> Lookup[a, "InverseFunctionBranches", Automatic], "MaxTerms" -> limit], Module]];
  r = refineStoredInverse[s, h, limit];
  If[r =!= $Failed, Return[r, Module]];
  If[KeyExistsQ[a, "ConditionalSourceReplay"] && MatchQ[Lookup[a, "Variables", None], {_Symbol, _Symbol}],
    {x, y} = a["Variables"];
    Return[AsymptoticInverse[a["ConditionalSourceReplay"], {x, a["ExpansionPoint"]}, {y, h},
      Assumptions -> a["Assumptions"], Direction -> a["Direction"],
      Method -> Lookup[a, "RequestedMethod", Lookup[a, "Method", "Lagrange"]],
      "Power" -> Lookup[a, "Power", 1], "InputRemainder" -> Lookup[a, "DeclaredInputRemainder", Automatic],
      "InverseFunctionBranches" -> Lookup[a, "InverseFunctionBranches", Automatic], "MaxTerms" -> limit], Module]];
  If[Lookup[a, "Kind", ""] === "SpecialInverse" && ListQ[Lookup[a, "AdapterOptions", None]],
    {x, y} = a["Variables"];
    Return[AsymptoticAnalysis`AsymptoticSpecialInverse[a["Adapter"], {x, a["ExpansionPoint"]}, {y, h},
      Sequence @@ a["AdapterOptions"], "MaxTerms" -> limit], Module]];
  If[Lookup[a, "Kind", ""] === "LogarithmicInverse",
    {x, y} = a["Variables"];
    Return[AsymptoticAnalysis`AsymptoticLogarithmicInverse[a["Function"], {x, a["ExpansionPoint"]}, {y, h},
      Assumptions -> a["Assumptions"], Direction -> a["Direction"], "Power" -> a["Power"],
      "LogarithmicLevels" -> a["LogarithmicLevels"], "MaxTerms" -> limit], Module]];
  If[Lookup[a, "Kind", ""] === "Forward", Return[AsymptoticExpansion[a["Function"], {a["Variable"], a["ExpansionPoint"], h},
    Assumptions -> a["Assumptions"], Direction -> a["Direction"],
    "InverseFunctionBranches" -> Lookup[a, "InverseFunctionBranches", Automatic], "MaxTerms" -> limit], Module]];
  If[MemberQ[{"Inverse", "GammaInverse", "BarnesGInverse"}, Lookup[a, "Kind", ""]] && MatchQ[Lookup[a, "Variables", None], {_Symbol, _Symbol}],
    {x, y} = a["Variables"];
    sourceOptions = {Assumptions -> a["Assumptions"], Direction -> a["Direction"],
      Method -> Lookup[a, "RequestedMethod", a["Method"]], "Power" -> a["Power"],
      "Truncation" -> Lookup[a, "Truncation", "Exponent"], "MaxTerms" -> limit};
    declared = Lookup[a, "DeclaredInputRemainder", Lookup[a, "InputRemainder", Automatic]];
    If[MemberQ[{None, Automatic}, declared] || ListQ[declared],
      AppendTo[sourceOptions, "InputRemainder" -> declared]];
    Return[AsymptoticInverse[a["Function"], {x, a["ExpansionPoint"]}, {y, h}, Sequence @@ sourceOptions], Module]];
  If[MatchQ[Lookup[a, "CoordinateSeries", None], _GeneralizedSeries],
    base = AsymptoticAnalysis`SeriesRefine[a["CoordinateSeries"], h, "MaxTerms" -> limit];
    If[FailureQ[base], Return[base, Module]];
    rules = Lookup[a, "CoordinateSubstitution", {}]; r = seriesData[base, limit] /. rules;
    Return[seriesMake[Join[r, <|"Variable" -> a["Variable"]|>], {"CoordinateRefine", {s}}, h], Module]];
  recipe = Lookup[a, "SeriesRecipe", Missing["NoRecipe"]];
  If[MissingQ[recipe], fail["MissingRefinementSource", "The expansion has no retained source or operation recipe; its existing remainder cannot be improved by truncation."]];
  operands = recipe[[2]];
  (* Recompute operands with a guard margin. The final operation still clips
     to its actual transported precision, so this never invents coefficients. *)
  args = AsymptoticAnalysis`SeriesRefine[#, h + 2 + Abs[Min[0, Lookup[seriesData[#, limit], "Jet"][[2]] /. Infinity -> 0]], "MaxTerms" -> limit] & /@ operands;
  If[AnyTrue[args, FailureQ], Return[First[Select[args, FailureQ]], Module]];
  Switch[recipe[[1]],
    "Add", seriesBinary["Add", args[[1]], args[[2]], h, limit],
    "Multiply", seriesBinary["Multiply", args[[1]], args[[2]], h, limit],
    "Power", seriesPower[First[args], recipe[[3]], h, limit],
    "Log", seriesLog[First[args], h, limit],
    "Exp", seriesExp[First[args], h, limit],
    "Observable", AsymptoticAnalysis`SeriesObservable[First[args], recipe[[3]], recipe[[4]], "Cutoff" -> h,
      "InverseFunctionBranches" -> Lookup[a, "InverseFunctionBranches", Automatic], "MaxTerms" -> limit],
    "Compose", AsymptoticAnalysis`SeriesCompose[args[[1]], args[[2]], "Cutoff" -> h, "MaxTerms" -> limit],
    "Truncate", AsymptoticAnalysis`SeriesTruncate[First[args], h, "MaxTerms" -> limit],
    "Constant", seriesConstant[recipe[[3]], First[args], limit],
    "RegularOperand", seriesRegularOperand[recipe[[3]], First[args], recipe[[4]], h, limit],
    "Differentiate", If[recipe[[4]] =!= Automatic &&
      Lookup[seriesData[First[args], limit], "RemainderDerivativeOrder", 0] < recipe[[3]],
        fail["UnprovedRefinedDerivative", "A derivative bound declared for the old remainder does not establish the stronger bound for the refined remainder. Refine the source first, then supply its derivative contract."]];
      seriesDerivative[First[args], recipe[[3]], Automatic, h, limit],
    _, fail["MissingRefinementSource", "This internal derived representation has no replayable public recipe."]]], s, h]];
