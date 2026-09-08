(* Normalize multiplicative elementary factors without asking Log to
   rediscover the exponent of Exp. A varying real power uses its positive
   base; ordinary factors retain a separately proved eventual sign. *)
logarithmicProductData[e_, x_] := Module[{parts},
  Which[
    FreeQ[e, x], {e, 0, True, {}},
    Head[e] === Times,
      parts = logarithmicProductData[#, x] & /@ List @@ e;
      {Times @@ parts[[All, 1]], Total[parts[[All, 2]]],
        And @@ parts[[All, 3]], Join @@ parts[[All, 4]]},
    MatchQ[e, Power[E, _]], {1, e[[2]], Element[e[[2]], Reals], {e[[2]]}},
    Head[e] === Power && (! FreeQ[e[[2]], x] || ! FreeQ[e[[1]], Power[E, _]]),
      {1, e[[2]] Log[e[[1]]], e[[1]] > 0 && Element[e[[2]], Reals], {e[[2]] Log[e[[1]]]}},
    True, {e, 0, True, {}}]];

logarithmicRealCondition[condition_, ass_, coord_] := Module[{simple, expression, parameters, domain},
  simple = FullSimplify[condition, ass && coord["u"] > 0];
  (* Keep inequalities describing a smaller real tail, but do not let
     quantifier elimination assume undeclared parameters are real. *)
  If[! FreeQ[simple, _Element],
    expression = condition[[1]];
    parameters = DeleteDuplicates[Cases[expression,
      z_ /; FreeQ[z, coord["u"]] && ! NumericQ[z], {0, Infinity}]];
    If[! AllTrue[parameters, TrueQ[FullSimplify[Element[#, Reals], ass]] &], Return[False, Module]];
    domain = Quiet[TimeConstrained[FunctionDomain[expression, coord["u"], Reals], 3, $Failed]];
    If[domain === $Failed || domain === False ||
      ! TrueQ[FullSimplify[condition, ass && coord["u"] > 0 && domain]], Return[False, Module]];
    simple = domain];
  inverseFunctionEventually[simple, coord["u"], ass]];

logarithmicProductSource[e_, x_, ass_, coord_] := Module[{parts, coefficient, sign, domain, condition, logarithm, simplified},
  parts = logarithmicProductData[e, x]; coefficient = parts[[1]];
  condition = parts[[3]] /. x -> coord["Substitution"];
  (* Resolve[..., Reals] would silently treat free parameters as real.
     Discharge realness from explicit assumptions before that fallback. *)
  condition = condition /. HoldPattern[Element[z_, Reals]] :>
    logarithmicRealCondition[Element[z, Reals], ass, coord];
  If[! inverseFunctionEventually[condition, coord["u"], ass],
    fail["UnprovedLogarithmicDomain", "Exponential arguments must be real and varying powers need positive real bases."]];
  sign = Which[
    inverseFunctionEventually[(coefficient /. x -> coord["Substitution"]) > 0, coord["u"], ass], 1,
    inverseFunctionEventually[(coefficient /. x -> coord["Substitution"]) < 0, coord["u"], ass], -1,
    True, fail["UnprovedLogarithmicCoefficientSign", "The ordinary multiplicative factor must have an eventual real nonzero sign.",
      <|"Coefficient" -> coefficient|>]];
  domain = coord["LocalVariable"] > 0 && parts[[3]] && sign coefficient > 0;
  logarithm = parts[[2]] + FullSimplify[Log[sign coefficient], ass && domain];
  simplified = TimeConstrained[FullSimplify[logarithm, ass && domain], 3, logarithm];
  If[FreeQ[simplified, _Gamma], logarithm = simplified];
  <|"Sign" -> sign, "Domain" -> domain, "Logarithm" -> logarithm|>];

exponentialForwardExpansion[f_, x_, x0_, cutoff_, ass_, coord_, goal_, limit_] := Module[
  {parts, growing = False, localSource, sourceLimit, source},
  parts = logarithmicProductData[f, x];
  If[parts[[4]] === {}, Return[$Failed, Module]];
  validateInput[f, limit];
  Do[
    localSource = exponent /. x -> coord["Substitution"];
    sourceLimit = inverseBranchTry[Limit[localSource/Log[coord["u"]], coord["u"] -> 0,
      Direction -> "FromAbove", Assumptions -> ass]];
    If[MemberQ[{Infinity, -Infinity}, sourceLimit], growing = True], {exponent, parts[[4]]}];
  (* A merely logarithmic source represents an ordinary power-law factor.
     Require growth beyond Log[u] so regular Laurent/Puiseux germs keep
     their absolute cutoff convention, even when written using Exp. *)
  If[! growing, Return[$Failed, Module]];
  source = logarithmicProductSource[f, x, ass, coord];
  logarithmicForwardExpansion[f, source["Logarithm"], source["Sign"], source["Domain"],
    x, x0, cutoff, ass, coord, goal, limit,
    <|"Transformation" -> "The expression equals Sign[coefficient] Exp[LogarithmicFunction] on the proved real domain."|>]];
