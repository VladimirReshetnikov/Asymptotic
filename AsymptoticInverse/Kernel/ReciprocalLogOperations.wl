(* Analytic calculus for C y^alpha A(epsilon/Log[y]), epsilon = +/-1.
   Hooks return $Failed outside their proved reciprocal-log scope. *)

AsymptoticInverse`ReciprocalLogCompose::usage =
"ReciprocalLogCompose[outer,inner] composes supported positive-target reciprocal-log inverse carriers, transporting both analytic logarithmic remainders. The inner carrier must approach the outer target endpoint with a positive constant unit.";
AsymptoticInverse`ReciprocalLogDifferentiate::usage =
"ReciprocalLogDifferentiate[s,n] differentiates a supported reciprocal-log carrier n times. Its exact rational-log implicit model proves all fixed derivative orders; omitted higher-power sectors and declared unknown errors are excluded.";
Options[AsymptoticInverse`ReciprocalLogCompose] = {"Cutoff" -> Automatic, "MaxTerms" -> 20000};
Options[AsymptoticInverse`ReciprocalLogDifferentiate] = {"Cutoff" -> Automatic, "MaxTerms" -> 20000};

reciprocalLogData[s : GeneralizedSeries[a_Association], limit_] := Module[
  {stored, y, p, power, endpoint, rint, alpha, coefficient, epsilon, t, scale,
   beta, polynomial, rows, ass, side, expected, exactRechart = False, originalCutoff},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  stored = Lookup[a, "ReciprocalLogRepresentation", None];
  If[AssociationQ[stored], Return[stored, Module]];
  If[Lookup[a, "Kind", ""] =!= "LogarithmicInverse" ||
     Lookup[a, "Scale", ""] =!= "ReciprocalLogUnit" ||
     ! TrueQ[Lookup[a, "ExactModel", False]] ||
     TrueQ[Lookup[a, "LeadingCoreOnly", True]], Return[$Failed, Module]];
  endpoint = a["ExpansionPoint"];
  If[! MemberQ[{0, Infinity, -Infinity}, endpoint] || ! MemberQ[{0, Infinity}, a["Limit"]] ||
     a["Offset"] =!= 0, Return[$Failed, Module]];
  y = a["Variable"]; ass = a["Assumptions"]; p = a["LeadingPower"]; power = a["Power"];
  If[! provablyPositive[a["LeadingCoefficient"], ass], Return[$Failed, Module]];
  expected = (y/a["LeadingCoefficient"])^(1/p);
  If[! TrueQ[FullSimplify[a["LeadingLocalApproximation"] == expected, ass && y > 0]], Return[$Failed, Module]];
  rint = If[MemberQ[{Infinity, -Infinity}, endpoint], -power, power];
  alpha = canon[rint/p]; epsilon = If[less[0, p], -1, 1];
  side = Which[endpoint === Infinity, 1, endpoint === -Infinity, -1,
    a["Direction"] === "FromBelow", -1, True, 1];
  coefficient = Simplify[side^power a["LeadingCoefficient"]^(-alpha), ass];
  If[! provablyPositive[coefficient, ass], Return[$Failed, Module]];
  t = Unique["reciprocalLog$"]; beta = a["RemainderPower"];
  If[beta === Infinity,
    If[a["Remainder"] =!= 0 ||
       ! TrueQ[Lookup[Lookup[a, "ExactTerminationCertificate", <||>], "Verified", False]],
      Return[$Failed, Module]];
    originalCutoff = a["Cutoff"];
    If[! exactRealQ[originalCutoff] || ! less[0, originalCutoff],
      fail["InvalidCutoff", "Recharting an exact reciprocal-log Taylor unit requires a positive finite cutoff."]];
    (* Even a finite exact polynomial in the old reciprocal coordinate can
       have an infinite Taylor series after an affine logarithmic shift.
       Keep a conservative analytic tail, including for a polynomial rechart. *)
    beta = Ceiling[originalCutoff]; exactRechart = True];
  If[! IntegerQ[beta] || beta < 1 || beta + 1 > limit,
    fail["ResourceLimit", "The analytic reciprocal-log conversion exceeds MaxTerms or lacks a positive integer Taylor remainder."]];
  scale = Abs[p] t/(1 - epsilon Log[a["LeadingCoefficient"]] t);
  polynomial = logarithmicTaylor[Total[(scale^#[[1]] #[[2]]) & /@ a["Blocks"]],
    t, beta - 1, ass, limit];
  rows = jetMerge[Table[{k, Coefficient[polynomial, t, k]}, {k, 0, beta - 1}], t, ass];
  <|"Variable" -> y, "EndpointSign" -> epsilon, "CarrierConstant" -> coefficient,
    "CarrierPower" -> alpha, "Jet" -> {rows, beta, 0}, "LogVariable" -> t,
    "Assumptions" -> ass, "Domain" -> (a["TargetDomain"] && y > 0 && epsilon Log[y] > 0), "Cutoff" -> a["Cutoff"],
    "AnalyticRemainder" -> True, "InputDomains" -> {a["TargetDomain"]},
    "RechartPrecisionSource" -> If[exactRechart,
      "ConservativeTaylorTruncationOfExactUnit", "TransportedAnalyticTaylorRemainder"],
    "Origin" -> "Exact rational reciprocal-log implicit inverse"|>];
reciprocalLogData[_, _] := $Failed;

reciprocalLogMake[d0_, recipe_, cut_, limit_] := Module[
  {d = d0, y, epsilon, alpha, c, ell, t, j, h, representation, result},
  {y, epsilon, alpha, c, ell, j} = Lookup[d,
    {"Variable", "EndpointSign", "CarrierPower", "CarrierConstant", "LogVariable", "Jet"}];
  h = If[cut === Automatic, Lookup[d, "Cutoff", j[[2]]], cut];
  If[! exactRealQ[h] || ! less[0, h], fail["InvalidCutoff", "A reciprocal-log cutoff must be a positive exact real number."]];
  j = seriesTrim[j, h, ell, d["Assumptions"]];
  If[LeafCount[j] > limit, fail["ResourceLimit", "The reciprocal-log result exceeded MaxTerms expression leaves."]];
  t = epsilon/Log[y];
  d = Join[d, <|"Jet" -> j, "Cutoff" -> h|>];
  representation = <|"Variable" -> y, "ScaleVariable" -> t, "LogVariable" -> ell,
    "Prefactor" -> c y^alpha, "Offset" -> 0, "Jet" -> j,
    "Assumptions" -> d["Assumptions"], "Domain" -> d["Domain"], "Cutoff" -> h,
    "RemainderDerivativeOrder" -> Infinity|>;
  result = seriesMake[representation, recipe, h];
  GeneralizedSeries[Join[result[[1]], <|"Scale" -> "ReciprocalLogCalculus",
    "ReciprocalLogRepresentation" -> d,
    "AnalyticRemainderContract" -> <|"Type" -> "HolomorphicReciprocalLogarithmicUnit",
      "AllFixedDerivativeOrders" -> True, "NumericCertificate" -> False,
      "Statement" -> "The exact carrier is retained and the coefficient function is holomorphic near t=0. An omitted O(t^beta) Taylor tail has derivatives O(t^(beta-j)) for each fixed j. Composition and differentiation preserve this contract; constants and a source threshold are existential."|>,
    "TermConvention" -> "CarrierConstant y^CarrierPower times a Taylor jet in t=EndpointSign/Log[y]>0. Cutoff is exclusive in the coefficient jet. A requested cutoff does not override operand precision.",
    "InputDomains" -> d["InputDomains"]|>]]];

reciprocalLogCompose[outer_, inner_, cut_, limit_] := Module[
  {a, b, ass, ell, y, epsilon, outerSign, alpha, bpower, ca, cb, ja, jb,
   constant, logarithm, denominator, coordinate, composed, unitPower, result,
   h, tjet, d, outerPolynomial, formal},
  a = reciprocalLogData[outer, limit]; b = reciprocalLogData[inner, limit];
  If[a === $Failed || b === $Failed, Return[$Failed, Module]];
  ass = a["Assumptions"] && b["Assumptions"]; ell = b["LogVariable"];
  y = b["Variable"]; epsilon = b["EndpointSign"]; outerSign = a["EndpointSign"];
  alpha = a["CarrierPower"]; bpower = b["CarrierPower"];
  If[bpower === 0 || ! less[0, outerSign bpower epsilon],
    fail["IncompatibleLimits", "The positive inner carrier must approach the outer reciprocal-log target endpoint."]];
  ja = a["Jet"] /. a["LogVariable"] -> ell; jb = b["Jet"];
  If[jb[[1]] === {} || jb[[1, 1, 1]] =!= 0 ||
     ! provablyPositive[jb[[1, 1, 2]], ass],
    fail["UnsupportedReciprocalLogComposition", "The inner coefficient jet must have a proved positive nonzero constant term; additional powers of log-log require a larger composition scale."]];
  constant = jb[[1, 1, 2]]; ca = a["CarrierConstant"]; cb = b["CarrierConstant"] constant;
  jb = pMul[pConst[1/constant, ell, ass], jb, ell, ass, limit];
  h = If[cut === Automatic, minOf[a["Cutoff"], b["Cutoff"]], cut];
  If[! exactRealQ[h] || ! less[0, h], fail["InvalidCutoff", "A reciprocal-log composition cutoff must be positive and exact."]];
  tjet = {{{1, 1}}, Infinity, 0};
  logarithm = fwdLog[jb, Unique["t$"], ell, ass, h, limit];
  denominator = pAdd[pConst[bpower epsilon, ell, ass],
    pMul[tjet, pAdd[pConst[Log[cb], ell, ass], logarithm, ell, ass], ell, ass, limit], ell, ass];
  coordinate = pMul[{{{1, outerSign}}, Infinity, 0},
    fwdPower[denominator, -1, Unique["t$"], ell, ass, h + 1, limit], ell, ass, limit];
  formal = Unique["outerLog$"];
  outerPolynomial = Total[(formal^#[[1]] #[[2]]) & /@ ja[[1]]];
  d = <|"Variable" -> y, "ScaleVariable" -> epsilon/Log[y], "LogVariable" -> ell,
    "Assumptions" -> ass, "Domain" -> (b["Domain"] && y > 0 && epsilon Log[y] > 0)|>;
  composed = seriesJetApply[outerPolynomial, formal, coordinate, d, h, limit];
  If[ja[[2]] =!= Infinity, composed = pAdd[composed, {{}, ja[[2]], ja[[3]]}, ell, ass]];
  unitPower = fwdPower[jb, alpha, Unique["t$"], ell, ass, h, limit];
  result = pMul[unitPower, composed, ell, ass, limit];
  reciprocalLogMake[Join[b, <|"Assumptions" -> ass, "Domain" -> d["Domain"],
    "CarrierConstant" -> Simplify[ca cb^alpha, ass], "CarrierPower" -> canon[alpha bpower],
    "Jet" -> result, "Cutoff" -> h,
    "InputDomains" -> Join[a["InputDomains"], b["InputDomains"]],
    "Origin" -> "Analytic reciprocal-log composition with both operand remainders"|>],
    {"Compose", {outer, inner}}, h, limit]];

reciprocalLogDifferentiate[s_, n_, declared_, cut_, limit_] := Module[
  {d, j, ell, ass, alpha, epsilon, derivative, ordinary, k, h},
  d = reciprocalLogData[s, limit]; If[d === $Failed, Return[$Failed, Module]];
  If[! IntegerQ[n] || n < 0, fail["InvalidDerivativeOrder", "The derivative order must be a nonnegative integer."]];
  If[n > limit, fail["ResourceLimit", "The derivative order exceeds MaxTerms."]];
  If[declared =!= Automatic && declared =!= Infinity && (! IntegerQ[declared] || declared < 0),
    fail["InvalidDerivativeContract", "RemainderDerivativeOrder must be nonnegative or Infinity."]];
  If[n === 0, Return[s, Module]];
  j = d["Jet"]; ell = d["LogVariable"]; ass = d["Assumptions"];
  alpha = d["CarrierPower"]; epsilon = d["EndpointSign"];
  Do[
    derivative = {jetMerge[({#[[1]] - 1, #[[1]] #[[2]]} & /@ j[[1]]), ell, ass],
      If[j[[2]] === Infinity, Infinity, j[[2]] - 1], j[[3]]};
    ordinary = If[zeroQ[alpha - k, ass], pConst[0, ell, ass],
      pMul[pConst[alpha - k, ell, ass], j, ell, ass, limit]];
    j = pAdd[ordinary, pMul[{{{2, -epsilon}}, Infinity, 0}, derivative, ell, ass, limit], ell, ass];
    If[LeafCount[j] > limit, fail["ResourceLimit", "A reciprocal-log derivative exceeded MaxTerms expression leaves."]],
    {k, 0, n - 1}];
  h = If[cut === Automatic, d["Cutoff"], cut];
  reciprocalLogMake[Join[d, <|"CarrierPower" -> canon[alpha - n], "Jet" -> j,
    "Origin" -> "Exact carrier differentiation with a holomorphic Taylor remainder"|>],
    {"Differentiate", {s}, n, Automatic}, h, limit]];

AsymptoticInverse`ReciprocalLogCompose[outer_GeneralizedSeries, inner_GeneralizedSeries, opts : OptionsPattern[]] := catch[
  Module[{result = reciprocalLogCompose[outer, inner, OptionValue["Cutoff"], OptionValue["MaxTerms"]]},
    If[result === $Failed, fail["UnsupportedReciprocalLogComposition", "Use exact reciprocal-log-unit inverse carriers with zero offsets and positive monomial prefactors."], result]]];
AsymptoticInverse`ReciprocalLogDifferentiate[s_GeneralizedSeries, n_Integer : 1, opts : OptionsPattern[]] := catch[
  Module[{result = reciprocalLogDifferentiate[s, n, Automatic, OptionValue["Cutoff"], OptionValue["MaxTerms"]]},
    If[result === $Failed, fail["UnsupportedReciprocalLogDerivative", "A retained exact reciprocal-log implicit model or its supported calculus result is required; unknown and omitted higher-power input sectors are excluded."], result]]];
