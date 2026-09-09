(* Explicit calculus for expansions.  A representation means
   Offset + Prefactor (Jet + remainder), in the positive ScaleVariable.
   The prefactor is exact; the jet precision is relative to that prefactor. *)

Scan[(Options[#] = {"Cutoff" -> Automatic, "MaxTerms" -> 20000}) &,
  {AsymptoticInverse`SeriesAdd, AsymptoticInverse`SeriesMultiply,
   AsymptoticInverse`SeriesPower, AsymptoticInverse`SeriesLog,
   AsymptoticInverse`SeriesExp, AsymptoticInverse`SeriesCompose,
   AsymptoticInverse`SeriesObservable}];
Options[AsymptoticInverse`SeriesTruncate] = {"MaxTerms" -> 20000};
Options[AsymptoticInverse`SeriesRefine] = {"MaxTerms" -> 20000, "MaxRefinements" -> 128};
Options[AsymptoticInverse`SeriesDifferentiate] = {
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

seriesData[s : PowerLogSeries[a_Association], limit_] := Module[
  {d, base, rules, ell, w, j, var, off = 0, pref = 1, u, rows, coord},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[a, "Kind", ""]],
    fail["UnsupportedScale", "This operation requires polynomial logarithmic coefficients. The Gamma/Barnes inverse scales support SeriesTruncate, SeriesRefine, SeriesPower, inverse checks, and the constructor's Power observable."]];
  If[AssociationQ[Lookup[a, "SeriesRepresentation", None]], Return[a["SeriesRepresentation"], Module]];
  If[MatchQ[Lookup[a, "CoordinateSeries", None], _PowerLogSeries],
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
seriesCoordinateRule[d_, u_] := Module[{w = d["ScaleVariable"], x = d["Variable"], sol},
  If[w === x, Return[x -> u, Module]];
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
  If[cutoff =!= Automatic, j = seriesTrim[j, cutoff, ell, seriesAss[d]]];
  If[j[[1]] === {} && j[[2]] === Infinity, p = 1];
  d = Join[d, <|"Jet" -> j, "Prefactor" -> p, "Cutoff" -> cutoff,
    "RemainderDerivativeOrder" -> If[j[[2]] === Infinity, Infinity, Lookup[d, "RemainderDerivativeOrder", 0]]|>];
  expr = off + p seriesJetExpression[j, w, ell];
  rem = If[j[[2]] === Infinity, 0, Abs[p] PowerLogRemainder[w, j[[2]], j[[3]]]];
  terms = {#[[1]], #[[2]] /. ell -> Log[w]} & /@ j[[1]];
  PowerLogSeries[<|"Kind" -> "Derived", "Scale" -> If[p === 1, "PowerLog", "Factored"],
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

seriesAlign[a_, b_] := Join[b /. b["LogVariable"] -> a["LogVariable"],
  <|"Assumptions" -> a["Assumptions"] && b["Assumptions"],
    "Domain" -> Lookup[a, "Domain", True] && Lookup[b, "Domain", True]|>];

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
  d = Join[d, <|"Assumptions" -> a["Assumptions"] && b["Assumptions"],
    "Domain" -> Lookup[a, "Domain", True] && Lookup[b, "Domain", True], "RemainderDerivativeOrder" -> order|>];
  h = If[cut === Automatic, Automatic, seriesWorkingCut[d, cut]];
  seriesMake[d, {op, {s, t}}, h]];

AsymptoticInverse`SeriesAdd[s_PowerLogSeries, t_PowerLogSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Add", s, t, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticInverse`SeriesMultiply[s_PowerLogSeries, t_PowerLogSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Multiply", s, t, OptionValue["Cutoff"], OptionValue["MaxTerms"]];

seriesConstant[c_, s_, limit_] := Module[{d = seriesData[s, limit]},
  If[! FreeQ[c, d["Variable"]], fail["InvalidConstant", "The scalar must be independent of the expansion variable."]];
  validateInput[c, limit];
  If[! TrueQ[Simplify[Element[c, Reals], seriesAss[d]]], fail["UnprovedRealCoefficient", "The scalar must be provably real under the series assumptions."]];
  seriesMake[Join[d, <|"Offset" -> 0, "Prefactor" -> 1,
    "Jet" -> pConst[c, d["LogVariable"], seriesAss[d]], "RemainderDerivativeOrder" -> Infinity|>], {"Constant", {s}, c}]];
AsymptoticInverse`SeriesAdd[s_PowerLogSeries, c_ /; FreeQ[c, _PowerLogSeries], opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Add", s, c, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticInverse`SeriesAdd[c_ /; FreeQ[c, _PowerLogSeries], s_PowerLogSeries, opts : OptionsPattern[]] :=
  AsymptoticInverse`SeriesAdd[s, c, opts];
AsymptoticInverse`SeriesMultiply[s_PowerLogSeries, c_ /; FreeQ[c, _PowerLogSeries], opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Multiply", s, c, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticInverse`SeriesMultiply[c_ /; FreeQ[c, _PowerLogSeries], s_PowerLogSeries, opts : OptionsPattern[]] :=
  AsymptoticInverse`SeriesMultiply[s, c, opts];

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
AsymptoticInverse`SeriesPower[s_PowerLogSeries, r_, opts : OptionsPattern[]] :=
  seriesArithmeticPublicPower[s, r, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticInverse`SeriesPower[s_PowerLogSeries, r_, h_?exactRealQ, opts : OptionsPattern[]] :=
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
AsymptoticInverse`SeriesLog[s_PowerLogSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicUnary[Log, s, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticInverse`SeriesLog[s_PowerLogSeries, h_?exactRealQ, opts : OptionsPattern[]] :=
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
AsymptoticInverse`SeriesExp[s_PowerLogSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicUnary[Exp, s, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticInverse`SeriesExp[s_PowerLogSeries, h_?exactRealQ, opts : OptionsPattern[]] :=
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

seriesJetApply[e_, x_, input_, d_, cut_, limit_] := Module[{h = Head[e], ell = d["LogVariable"], ass = seriesAss[d], j, parts, c, u, native, n, cf, res},
  Which[inverseFunctionApplicationQ[e], inverseFunctionJetApply[e, x, input, d, cut, limit],
    FreeQ[e, x], seriesIndependentJet[e, d, cut, limit], e === x, input,
    h === Plus, Fold[pAdd[#1, seriesJetApply[#2, x, input, d, cut, limit], ell, ass] &, pConst[0, ell, ass], List @@ e],
    h === Times, Fold[pMul[#1, seriesJetApply[#2, x, input, d, cut, limit], ell, ass, limit] &, pConst[1, ell, ass], List @@ e],
    h === Power && e[[1]] === E, fwdExp[seriesJetApply[e[[2]], x, input, d, cut, limit], x, ell, ass, cut, limit],
    h === Power && FreeQ[e[[2]], x], fwdPower[seriesJetApply[e[[1]], x, input, d, cut, limit], e[[2]], x, ell, ass, cut, limit],
    h === Log && Length[e] === 1, fwdLog[seriesJetApply[e[[1]], x, input, d, cut, limit], x, ell, ass, cut, limit],
    h === Abs, fwdAbs[seriesJetApply[e[[1]], x, input, d, cut, limit], ell, ass],
    Length[e] === 1,
      j = seriesJetApply[e[[1]], x, input, d, cut, limit]; parts = splitJet[j[[1]]];
      If[parts[[1]] =!= {} || ! FreeQ[parts[[2]], ell] || ! less[0, j[[2]]],
        fail["UnsupportedObservable", "A general analytic observable needs an argument tending to a finite constant."]];
      c = parts[[2]]; u = Unique["v$"];
      n = If[parts[[3]] === {}, 1, Max[1, Ceiling[minOf[cut, j[[2]]]/jetValuation[parts[[3]]]]]];
      If[n > limit, fail["ResourceLimit", "Observable Taylor expansion exceeded MaxTerms."]];
      native = Quiet[Series[h[c + u], {u, 0, n}, Assumptions -> ass]];
      If[! MatchQ[native, _SeriesData] || native[[4]] < 0 || native[[6]] =!= 1 || ! FreeQ[native[[3]], u],
        fail["UnsupportedObservable", "The observable must have a regular Taylor expansion at the limiting argument."]];
      If[! And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@ native[[3]]),
        fail["UnprovedRealCoefficient", "The observable's Taylor coefficients must be provably real on the selected branch."]];
      cf = Function[k, If[k >= native[[4]] && k - native[[4]] + 1 <= Length[native[[3]]], native[[3, k - native[[4]] + 1]], 0]];
      If[parts[[3]] === {}, Return[{jetMerge[{{0, h[c]}}, ell, ass], j[[2]], j[[3]]}, Module]];
      res = pUnitSeries[parts[[3]], j[[2]], j[[3]], cf, cut, ell, ass, limit];
      pAdd[pConst[h[c], ell, ass], res, ell, ass],
    True, fail["UnsupportedObservable", "This observable is not in the supported algebra of regular unary analytic functions, powers, logarithms and exponentials."]]];

AsymptoticInverse`SeriesObservable[s_PowerLogSeries, e_, x_Symbol, opts : OptionsPattern[]] := catch[Block[
  {$inverseFunctionBranchSelections = OptionValue["InverseFunctionBranches"], $inverseFunctionProvenance = {},
    $inverseFunctionSyntaxCache = <||>, $inverseFunctionBranchCache = <||>},
  Module[{d, h, j, body = e, condition = True, result, limit = OptionValue["MaxTerms"]},
  validateInput[e, limit];
  If[e === Log[x], Return[seriesLog[s, OptionValue["Cutoff"], limit], Module]];
  If[e === Exp[x], Return[seriesExp[s, OptionValue["Cutoff"], limit], Module]];
  If[Head[e] === Power && e[[1]] === x && FreeQ[e[[2]], x], Return[seriesPower[s, e[[2]], OptionValue["Cutoff"], limit], Module]];
  d = seriesFlat[seriesData[s, limit], limit];
  If[d === $Failed, fail["UnsupportedScale", "This observable requires a single power-log representation of its argument."]];
  h = seriesWorkingCut[d, OptionValue["Cutoff"]];
  While[Head[body] === ConditionalExpression, condition = condition && body[[2]]; body = body[[1]]];
  If[! TrueQ[inverseFunctionConditionOnJet[condition, x, d["Jet"], d, h, limit]],
    fail["IncompatibleObservableCondition", "The observable condition is not proved on the precision-tracked input germ.", <|"Condition" -> condition|>]];
  j = seriesJetApply[body, x, d["Jet"], d, h, limit];
  result = seriesMake[Join[d, <|"Jet" -> j|>], {"Observable", {s}, e, x}, h];
  PowerLogSeries[Join[result[[1]], <|"InverseFunctionBranches" -> $inverseFunctionBranchSelections,
    "InverseFunctionProvenance" -> DeleteDuplicates[$inverseFunctionProvenance]|>]]]]];

AsymptoticInverse`SeriesCompose[outer_PowerLogSeries, inner_PowerLogSeries, opts : OptionsPattern[]] := catch[Module[
  {a, b, input, wj, term, result, p, deg, alpha, lc, ell, ass, h, limit = OptionValue["MaxTerms"]},
  result = reciprocalLogCompose[outer, inner, OptionValue["Cutoff"], limit];
  If[result =!= $Failed, Return[result, Module]];
  a = seriesFlat[seriesData[outer, limit], limit]; b = seriesFlat[seriesData[inner, limit], limit];
  If[a === $Failed || b === $Failed, fail["UnsupportedScale", "Composition currently requires a single power-log representation of both operands."]];
  ell = b["LogVariable"]; ass = seriesAss[a] && seriesAss[b]; h = seriesWorkingCut[b, OptionValue["Cutoff"]];
  wj = seriesJetApply[a["ScaleVariable"], a["Variable"], b["Jet"], b, h, limit];
  If[wj[[1]] === {} || ! less[0, jetValuation[wj[[1]]]],
    fail["IncompatibleLimits", "The inner expansion must approach the outer expansion point from its recorded positive local side."]];
  alpha = jetValuation[wj[[1]]]; lc = wj[[1, 1, 2]];
  If[! FreeQ[lc, ell] || ! provablyPositive[lc, ass],
    fail["UnsupportedCompositionScale", "Composition requires a positive monomial leading block for the outer local coordinate."]];
  result = pConst[0, ell, ass];
  Do[term = pMul[fwdPower[wj, row[[1]], Unique["w$"], ell, ass, h, limit],
      seriesJetApply[row[[2]], a["LogVariable"], fwdLog[wj, Unique["w$"], ell, ass, h, limit], b, h, limit], ell, ass, limit];
    result = pAdd[result, term, ell, ass], {row, a["Jet"][[1]]}];
  {p, deg} = a["Jet"][[{2, 3}]];
  If[p =!= Infinity, result = pAdd[result, {{}, canon[alpha p], deg}, ell, ass]];
  seriesMake[Join[b, <|"Jet" -> result, "Assumptions" -> a["Assumptions"] && b["Assumptions"],
    "Domain" -> Lookup[b, "Domain", True] && (Lookup[a, "Domain", True] /.
      a["Variable"] -> seriesJetExpression[b["Jet"], b["ScaleVariable"], b["LogVariable"]]),
    "RemainderDerivativeOrder" -> Min[Lookup[a, "RemainderDerivativeOrder", 0], Lookup[b, "RemainderDerivativeOrder", 0]]|>], {"Compose", {outer, inner}}, h]]];

AsymptoticInverse`SeriesTruncate[s_PowerLogSeries, h_, opts : OptionsPattern[]] := catch[Module[{d},
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[s[[1]], "Kind", ""]], Return[gammaInverseTruncate[s, h, OptionValue["MaxTerms"]], Module]];
  d = seriesData[s, OptionValue["MaxTerms"]];
  If[! exactRealQ[h], fail["InvalidCutoff", "The truncation cutoff must be an exact real number."]];
  seriesMake[d, {"Truncate", {s}}, h]]];

seriesDerivative[s_, n_, declared_, cut_, limit_] := Module[{d, contract, ell, ass, j, q, wprime, pprime, first, second, result, k},
  If[! IntegerQ[n] || n < 0, fail["InvalidDerivativeOrder", "The derivative order must be a nonnegative integer."]];
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
AsymptoticInverse`SeriesDifferentiate[s_PowerLogSeries, n_Integer : 1, opts : OptionsPattern[]] :=
  catch[seriesDerivative[s, n, OptionValue["RemainderDerivativeOrder"], OptionValue["Cutoff"], OptionValue["MaxTerms"]]];

seriesRefinementResult[result_, original_, cutoff_] := Module[{data, stats},
  If[! MatchQ[result, _PowerLogSeries], Return[result, Module]];
  data = result[[1]];
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[original[[1]], "Kind", ""]],
    data = Join[data, <|"TargetDomain" -> Lookup[original[[1]], "TargetDomain", True] &&
      Lookup[data, "TargetDomain", True]|>]];
  If[KeyExistsQ[data, "RefinementStatistics"], Return[PowerLogSeries[data], Module]];
  stats = <|"Strategy" -> If[Lookup[original[[1]], "Kind", ""] === "Derived" &&
      KeyExistsQ[original[[1]], "SeriesRecipe"], "ReplayOperationRecipe", "ReplayOriginalSource"],
    "SourceCutoff" -> Lookup[original[[1]], "Cutoff", Missing["NotAvailable"]], "RequestedCutoff" -> cutoff,
    "ModelReused" -> False, "ReusedBlocks" -> 0,
    "NewCoefficientEvaluations" -> Missing["ReplayNotInstrumented"],
    "Evidence" -> "Recomputed from retained source or operation recipe; no coefficient reuse or work count is claimed."|>;
  PowerLogSeries[Join[data, <|"RefinementStatistics" -> stats,
    "RefinementHistory" -> Append[Lookup[original[[1]], "RefinementHistory", {}], stats]|>]]];

AsymptoticInverse`SeriesRefine[s : PowerLogSeries[a_Association], h_, opts : OptionsPattern[]] := catch[seriesRefinementResult[Module[
  {recipe, args, operands, r, limit = OptionValue["MaxTerms"], rules, base, x, y, sourceOptions, declared},
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
    Return[AsymptoticInverse`AsymptoticSpecialInverse[a["Adapter"], {x, a["ExpansionPoint"]}, {y, h},
      Sequence @@ a["AdapterOptions"], "MaxTerms" -> limit], Module]];
  If[Lookup[a, "Kind", ""] === "LogarithmicInverse",
    {x, y} = a["Variables"];
    Return[AsymptoticInverse`AsymptoticLogarithmicInverse[a["Function"], {x, a["ExpansionPoint"]}, {y, h},
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
  If[MatchQ[Lookup[a, "CoordinateSeries", None], _PowerLogSeries],
    base = AsymptoticInverse`SeriesRefine[a["CoordinateSeries"], h, "MaxTerms" -> limit];
    If[FailureQ[base], Return[base, Module]];
    rules = Lookup[a, "CoordinateSubstitution", {}]; r = seriesData[base, limit] /. rules;
    Return[seriesMake[Join[r, <|"Variable" -> a["Variable"]|>], {"CoordinateRefine", {s}}, h], Module]];
  recipe = Lookup[a, "SeriesRecipe", Missing["NoRecipe"]];
  If[MissingQ[recipe], fail["MissingRefinementSource", "The expansion has no retained source or operation recipe; its existing remainder cannot be improved by truncation."]];
  operands = recipe[[2]];
  (* Recompute operands with a guard margin. The final operation still clips
     to its actual transported precision, so this never invents coefficients. *)
  args = AsymptoticInverse`SeriesRefine[#, h + 2 + Abs[Min[0, Lookup[seriesData[#, limit], "Jet"][[2]] /. Infinity -> 0]], "MaxTerms" -> limit] & /@ operands;
  If[AnyTrue[args, FailureQ], Return[First[Select[args, FailureQ]], Module]];
  Switch[recipe[[1]],
    "Add", seriesBinary["Add", args[[1]], args[[2]], h, limit],
    "Multiply", seriesBinary["Multiply", args[[1]], args[[2]], h, limit],
    "Power", seriesPower[First[args], recipe[[3]], h, limit],
    "Log", seriesLog[First[args], h, limit],
    "Exp", seriesExp[First[args], h, limit],
    "Observable", AsymptoticInverse`SeriesObservable[First[args], recipe[[3]], recipe[[4]], "Cutoff" -> h,
      "InverseFunctionBranches" -> Lookup[a, "InverseFunctionBranches", Automatic], "MaxTerms" -> limit],
    "Compose", AsymptoticInverse`SeriesCompose[args[[1]], args[[2]], "Cutoff" -> h, "MaxTerms" -> limit],
    "Truncate", AsymptoticInverse`SeriesTruncate[First[args], h, "MaxTerms" -> limit],
    "Constant", seriesConstant[recipe[[3]], First[args], limit],
    "RegularOperand", seriesRegularOperand[recipe[[3]], First[args], recipe[[4]], h, limit],
    "Differentiate", If[recipe[[4]] =!= Automatic &&
      Lookup[seriesData[First[args], limit], "RemainderDerivativeOrder", 0] < recipe[[3]],
        fail["UnprovedRefinedDerivative", "A derivative bound declared for the old remainder does not establish the stronger bound for the refined remainder. Refine the source first, then supply its derivative contract."]];
      seriesDerivative[First[args], recipe[[3]], Automatic, h, limit],
    _, fail["MissingRefinementSource", "This internal derived representation has no replayable public recipe."]]], s, h]];
