(* Positive-real Barnes G products use the same logarithmic carrier calculus
   as Gamma products. barnesLog is an exact internal logarithm, not a finite
   asymptotic surrogate. Its parser always attaches the Bernoulli tail.
   https://dlmf.nist.gov/5.17.E5 *)

barnesProductData[e_, x_] := Module[{parts, base, r},
  If[FreeQ[e, _Gamma | _BarnesG] || FreeQ[e, x], Return[{e, {}, {}}, Module]];
  Which[
    MatchQ[e, Gamma[_] | BarnesG[_]], {1, {{e, 1}}, {}},
    Head[e] === Times,
      parts = barnesProductData[#, x] & /@ List @@ e;
      If[MemberQ[parts, $Failed], $Failed,
        {Times @@ parts[[All, 1]], Join @@ parts[[All, 2]], Join @@ parts[[All, 3]]}],
    Head[e] === Power,
      base = barnesProductData[e[[1]], x]; r = e[[2]];
      If[base === $Failed || base[[2]] === {}, $Failed,
        {base[[1]]^r, {#[[1]], r #[[2]]} & /@ base[[2]], Append[base[[3]], r]}],
    True, $Failed]];

(* Canonicalize bounded integer shifts before any finite tails are formed.
   Choosing the shift +1 also preserves the even correction lattice of G(x+1).
   Every intermediate Gamma argument must lie on the positive real branch. *)
barnesLogShift[arg_, x_, ass_, coord_, limit_] := Module[
  {terms, constant, shift, base, arguments},
  terms = If[Head[Expand[arg]] === Plus, List @@ Expand[arg], {arg}];
  constant = Total[Select[terms, FreeQ[#, x] &]];
  If[! IntegerQ[constant], Return[barnesLog[arg], Module]];
  shift = constant - 1;
  If[shift === 0 || Abs[shift] > Min[32, limit], Return[barnesLog[arg], Module]];
  base = Expand[arg - shift];
  arguments = If[shift > 0, Table[base + j, {j, 0, shift - 1}],
    Table[base - j, {j, 1, -shift}]];
  If[! AllTrue[arguments, inverseFunctionEventually[(# /. x -> coord["Substitution"]) > 0,
      coord["u"], ass] &], Return[barnesLog[arg], Module]];
  barnesLog[base] + Sign[shift] Total[LogGamma /@ arguments]];

(* Common offsets may be fractional or symbolic. Their difference, rather
   than either constant part separately, determines an exact recurrence. *)
barnesLogReduce[e_, x_, ass_, coord_, limit_] := Module[
  {atoms, bases = {}, rules = {}, domains = {}, replacement, shift, arguments, base},
  atoms = DeleteDuplicates[Cases[e, _barnesLog, {0, Infinity}]];
  Do[
    replacement = atom;
    Do[
      shift = Simplify[atom[[1]] - base, ass];
      If[! IntegerQ[shift] || Abs[shift] > Min[32, limit], Continue[]];
      arguments = If[shift >= 0, Table[base + j, {j, 0, shift - 1}],
        Table[base - j, {j, 1, -shift}]];
      If[! AllTrue[Prepend[arguments, base],
          inverseFunctionEventually[(# /. x -> coord["Substitution"]) > 0, coord["u"], ass] &], Continue[]];
      replacement = barnesLog[base] + Sign[shift] Total[LogGamma /@ arguments];
      AppendTo[domains, And @@ (# > 0 & /@ Prepend[arguments, base])];
      Break[], {base, bases}];
    If[replacement === atom, AppendTo[bases, atom[[1]]], AppendTo[rules, atom -> replacement]],
    {atom, atoms}];
  <|"Expression" -> (e /. rules), "Domain" -> And @@ domains|>];

barnesLogDomain[e_] := And @@ (First[#] > 0 & /@
  DeleteDuplicates[Cases[e, _barnesLog | _LogGamma, {0, Infinity}]]);

barnesProductLogSource[f_, x_, ass_, coord_, limit_, requireGrowth_] := Module[
  {lowered, product, factors, powers, domain, ordinary, localArg, growing = False,
   logFunction, simplified, reduced},
  If[FreeQ[f, _BarnesG], Return[$Failed, Module]];
  validateInput[f, limit];
  lowered = gammaRelatedExpression[f]; product = barnesProductData[lowered, x];
  If[product === $Failed || product[[2]] === {}, Return[$Failed, Module]];
  factors = product[[2]];
  Do[
    localArg = factor[[1, 1]] /. x -> coord["Substitution"];
    If[! inverseFunctionEventually[localArg > 0, coord["u"], ass], Return[$Failed, Module]];
    If[TrueQ[requireGrowth] && inverseBranchTry[Limit[localArg, coord["u"] -> 0,
        Direction -> "FromAbove", Assumptions -> ass]] === Infinity, growing = True],
    {factor, factors}];
  If[TrueQ[requireGrowth] && ! growing, Return[$Failed, Module]];
  powers = DeleteDuplicates[Join[product[[3]], factors[[All, 2]]]];
  If[! AllTrue[powers, logarithmicRealCondition[Element[# /. x -> coord["Substitution"], Reals], ass, coord] &],
    fail["UnsupportedBarnesPower", "Barnes G products require exact exponents that are eventually real.", <|"Powers" -> powers|>]];
  ordinary = logarithmicProductSource[product[[1]], x, ass, coord];
  domain = ordinary["Domain"] && And @@ (#[[1, 1]] > 0 & /@ factors) &&
    And @@ (Element[#, Reals] & /@ powers);
  logFunction = Total[#[[2]] If[Head[#[[1]]] === BarnesG,
      barnesLogShift[#[[1, 1]], x, ass, coord, limit], LogGamma[#[[1, 1]]]] & /@ factors];
  domain = domain && barnesLogDomain[logFunction];
  reduced = barnesLogReduce[logFunction, x, ass, coord, limit];
  logFunction = reduced["Expression"]; domain = domain && reduced["Domain"];
  simplified = TimeConstrained[FullSimplify[logFunction, ass && domain], 3, logFunction];
  If[FreeQ[simplified, _Gamma | _BarnesG], logFunction = simplified];
  <|"Logarithm" -> logFunction + ordinary["Logarithm"], "Sign" -> ordinary["Sign"],
    "Domain" -> domain, "BarnesExpression" -> lowered,
    "BarnesFactors" -> ({#[[1, 1]], #[[2]]} & /@ Select[factors, Head[#[[1]]] === BarnesG &]),
    "GammaFactors" -> ({#[[1, 1]], #[[2]]} & /@ Select[factors, Head[#[[1]]] === Gamma &])|>];

barnesForwardExpansion[f_, x_, x0_, cutoff_, ass_, coord_, goal_, limit_] := Module[{source},
  source = barnesProductLogSource[f, x, ass, coord, limit, True];
  If[source === $Failed, Return[$Failed, Module]];
  logarithmicForwardExpansion[f, source["Logarithm"], source["Sign"], source["Domain"],
    x, x0, cutoff, ass, coord, goal, limit, <|
      "BarnesFactors" -> source["BarnesFactors"], "GammaFactors" -> source["GammaFactors"],
      "BarnesExpression" -> source["BarnesExpression"],
      "Transformation" -> "Positive Barnes G and Gamma factors are combined in the real logarithmic domain, using exact positive integer-shift recurrences before expansion.",
      "AsymptoticReference" -> "https://dlmf.nist.gov/5.17.E5"|>]];

barnesLogJet[arg_, u_, ell_, ass_, Kw_, limit_] := Module[
  {z = arg - 1, leading, rate, count, model, result},
  If[Kw === Infinity, fail["InfiniteSeries", "The Barnes logarithm requires a finite Poincare working order."]];
  If[! inverseFunctionEventually[z > 0, u, ass] ||
      inverseBranchTry[Limit[z, u -> 0, Direction -> "FromAbove", Assumptions -> ass]] =!= Infinity,
    Return[fwdSeries[LogBarnesG[arg], u, ell, ass, Kw, limit], Module]];
  leading = fwd[z, u, ell, ass, Max[1, Kw], limit][[1]];
  If[leading === {} || ! less[leading[[1, 1]], 0] || ! FreeQ[leading[[1, 2]], ell],
    fail["UnsupportedBarnesArgument", "The growing Barnes argument must have a pure-power leading block."]];
  rate = -leading[[1, 1]];
  count = Max[0, Ceiling[Kw/(2 rate)] - 1];
  If[count + 1 > limit, fail["ResourceLimit", "The Barnes Bernoulli tail exceeds MaxTerms."]];
  model = (z^2/2 - 1/12) Log[z] - 3 z^2/4 + z Log[2 Pi]/2 + 1/12 - Log[Glaisher] +
    Sum[BernoulliB[2 k + 2]/(2 k (2 k + 2) z^(2 k)), {k, 1, count}];
  result = fwd[model, u, ell, ass, Kw, limit];
  pAdd[result, {{}, 2 (count + 1) rate, 0}, ell, ass]];
