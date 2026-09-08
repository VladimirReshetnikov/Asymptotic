(* Ordered inverse-Gamma corrections around an exact Lambert core.
   The coefficients are polynomials in q=1/Log[X], retained whole at each
   power of t=1/X. Stirling is used only to a finite, justified order. *)

gammaInverseModel[f_, x_, ass_] := Module[
  {parts, offset, dependent, factors, constant, variable, factor, family, power = 1,
   argument, slope, shift},
  If[FreeQ[f, _Gamma | _LogGamma], Return[$Failed, Module]];
  parts = If[Head[f] === Plus, List @@ f, {f}];
  offset = Total[Select[parts, FreeQ[#, x] &]];
  dependent = Select[parts, ! FreeQ[#, x] &];
  If[Length[dependent] =!= 1, Return[$Failed, Module]];
  factors = If[Head[First[dependent]] === Times, List @@ First[dependent], dependent];
  constant = Times @@ Select[factors, FreeQ[#, x] &];
  variable = Select[factors, ! FreeQ[#, x] &];
  If[Length[variable] =!= 1, Return[$Failed, Module]];
  factor = First[variable];
  If[MatchQ[factor, Power[_Gamma, p_] /; FreeQ[p, x]],
    power = factor[[2]]; factor = factor[[1]]];
  If[! MatchQ[factor, Gamma[_] | LogGamma[_]], Return[$Failed, Module]];
  family = If[Head[factor] === Gamma, "Gamma", "LogGamma"];
  argument = First[factor];
  If[! PolynomialQ[argument, x] || Exponent[argument, x] =!= 1, Return[$Failed, Module]];
  slope = Coefficient[argument, x]; shift = argument /. x -> 0;
  If[! And @@ (TrueQ[FullSimplify[Element[#, Reals], ass]] & /@ {offset, shift}) ||
     ! (provablyPositive[constant, ass] || provablyNegative[constant, ass]) ||
     ! (provablyPositive[slope, ass] || provablyNegative[slope, ass]) ||
     ! (provablyPositive[power, ass] || provablyNegative[power, ass]),
    fail["UnprovedGammaInverseParameters", "Gamma inverse affine parameters must be real, with proved nonzero source/target scales and a fixed nonzero real Gamma power."]];
  <|"Family" -> family, "Argument" -> argument, "SourceScale" -> slope,
    "SourceOffset" -> shift, "TargetScale" -> constant, "TargetOffset" -> offset,
    "GammaPower" -> power|>];

gammaInverseUnit[n_Integer, t_, q_, limit_] := Module[
  {unit = 0, phase, coefficient, k, j, c = Log[2 Pi]},
  Do[
    phase = unit + q ((1 + unit) Log[1 + unit] - unit) - t/2 + c t q/2
      - t q Log[1 + unit]/2
      + Sum[BernoulliB[2 k] q t^(2 k) (1 + unit)^(-(2 k - 1))/(2 k (2 k - 1)),
          {k, 1, Floor[j/2]}];
    coefficient = Expand[-Coefficient[Normal[Series[phase, {t, 0, j}]], t, j]];
    unit += coefficient t^j;
    If[LeafCount[unit] > limit, fail["ResourceLimit", "The inverse-Gamma coefficient expansion exceeds MaxTerms."]],
    {j, 1, n}];
  unit];

gammaInverseRows[n_, r_, slope_, shift_, t_, q_, ass_, limit_] := Module[{unit, observable, rows},
  unit = gammaInverseUnit[n, t, q, limit];
  observable = Normal[Series[(1 + unit - shift t)^r, {t, 0, n}]];
  rows = Table[{canon[j - r], Expand[Coefficient[observable, t, j]/slope^r]}, {j, 0, n}];
  rows = Select[rows, ! TrueQ[FullSimplify[#[[2]] == 0, ass]] &];
  If[LeafCount[rows] > limit, fail["ResourceLimit", "The inverse-Gamma observable exceeds MaxTerms."]];
  rows];

gammaInverseBound[frontier_, core_, q_, ass_] := Module[{poly, degree},
  poly = Expand[frontier[[2]]];
  degree = Min[First /@ (First /@ CoefficientRules[poly, q])];
  <|"RemainderPower" -> frontier[[1]], "RemainderLogDegree" -> 0,
    "RemainderInverseLogPower" -> degree, "RemainderVariable" -> 1/core,
    "Remainder" -> PowerLogRemainder[1/core, frontier[[1]], 0]/Log[core]^degree,
    "RemainderScaleExpression" -> core^(-frontier[[1]])/Log[core]^degree|>];

gammaInverseConstruct[f_, x_, x0_, y_, cutoff_, opts : OptionsPattern[AsymptoticInverse]] := Module[
  {ass = OptionValue[AsymptoticInverse, {opts}, Assumptions],
   dir = OptionValue[AsymptoticInverse, {opts}, Direction],
   goal = OptionValue[AsymptoticInverse, {opts}, SeriesTermGoal],
   limit = OptionValue[AsymptoticInverse, {opts}, "MaxTerms"],
   r = OptionValue[AsymptoticInverse, {opts}, "Power"],
   method = OptionValue[AsymptoticInverse, {opts}, Method],
   input = OptionValue[AsymptoticInverse, {opts}, "InputRemainder"],
   truncation = OptionValue[AsymptoticInverse, {opts}, "Truncation"],
   model, coord, target, core, q = Unique["inverseLog$"], t = Unique["inversePower$"],
   n, rows, retained, frontier, requested = cutoff, bound, expression, sourceSign, targetLimit},
  model = gammaInverseModel[f, x, ass];
  If[model === $Failed, Return[$Failed, Module]];
  sourceSign = If[provablyPositive[model["SourceScale"], ass], 1, -1];
  If[x0 =!= sourceSign Infinity, Return[$Failed, Module]];
  validateInput[f, limit];
  If[x === y || ! FreeQ[f, y] || ! FreeQ[ass, x | y],
    fail["InvalidVariables", "Use distinct source and target variables, a target-free forward expression, and parameter-only assumptions."]];
  coord = localCoordinate[x, x0, dir];
  If[! exactRealQ[r] || r === 0 || (sourceSign === -1 && ! IntegerQ[r]),
    fail["InvalidPower", "The inverse observable needs a nonzero exact real power; a negative source branch requires an integer power."]];
  If[! MemberQ[{"Lagrange", "Newton", "GroupedLagrange"}, method],
    fail["UnsupportedMethod", "The Gamma inverse uses ordered Stirling reversion; the requested method is not supported."]];
  If[! MemberQ[{Automatic, None}, input],
    fail["UnsupportedInputRemainder", "A declared additive error must first be transported to the LogGamma equation."]];
  If[truncation =!= "Exponent", fail["UnsupportedTruncation", "The automatic Gamma inverse uses an exclusive core-power cutoff. Use AsymptoticSpecialInverse for marker depth."]];
  If[cutoff === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give a core-power cutoff or a positive integer SeriesTermGoal."]]; n = goal,
    If[! exactRealQ[cutoff] || ! less[-r, cutoff], fail["InvalidCutoff", "The core-power cutoff must exceed the leading exponent -Power."]];
    n = Ceiling[cutoff + r]];
  If[! IntegerQ[n] || n > limit, fail["ResourceLimit", "The inverse-Gamma order exceeds MaxTerms."]];
  rows = gammaInverseRows[n, r, model["SourceScale"], model["SourceOffset"], t, q, ass, limit];
  If[cutoff === Automatic,
    While[Length[rows] < goal + 1,
      n++; If[n > limit, fail["ResourceLimit", "The inverse-Gamma nonzero-block search exceeds MaxTerms."]];
      rows = gammaInverseRows[n, r, model["SourceScale"], model["SourceOffset"], t, q, ass, limit]];
    retained = Take[rows, goal]; frontier = rows[[goal + 1]]; requested = frontier[[1]],
    retained = Select[rows, less[#[[1]], cutoff] &];
    While[Select[rows, ! less[#[[1]], cutoff] &] === {},
      n++; If[n > limit, fail["ResourceLimit", "The inverse-Gamma frontier search exceeds MaxTerms."]];
      rows = gammaInverseRows[n, r, model["SourceScale"], model["SourceOffset"], t, q, ass, limit]];
    frontier = First[Select[rows, ! less[#[[1]], cutoff] &]]];
  target = If[model["Family"] === "Gamma",
    Log[(y - model["TargetOffset"])/model["TargetScale"]]/model["GammaPower"],
    (y - model["TargetOffset"])/model["TargetScale"]];
  core = target/ProductLog[target/E];
  expression = Total[(core^(-#[[1]]) (#[[2]] /. q -> 1/Log[core])) & /@ retained];
  bound = gammaInverseBound[frontier, core, q, ass];
  targetLimit = If[model["Family"] === "Gamma" && provablyNegative[model["GammaPower"], ass],
    model["TargetOffset"], If[provablyPositive[model["TargetScale"], ass], Infinity, -Infinity]];
  PowerLogSeries[Join[<|"Kind" -> "GammaInverse", "Scale" -> "GammaInverse",
    "Expression" -> expression, "Terms" -> retained, "Blocks" -> retained,
    "CoreInverse" -> core, "CoreLogExpression" -> Log[core],
    "CoefficientVariable" -> q, "CoefficientSubstitution" -> {q -> 1/Log[core]},
    "CoefficientFrontier" -> frontier,
    "FrontierTerm" -> core^(-frontier[[1]]) (frontier[[2]] /. q -> 1/Log[core]),
    "Function" -> f, "Variables" -> {x, y}, "Variable" -> y, "SourceVariable" -> x,
    "ExpansionPoint" -> x0, "Direction" -> coord["Direction"], "Limit" -> targetLimit,
    "Assumptions" -> ass, "SourceDomain" -> model["Argument"] > 2,
    (* Express the logarithmic target condition using real inequalities
       before evaluating a logarithm, including on invalid target values. *)
    "TargetDomain" -> ass && If[model["Family"] === "Gamma",
      If[provablyPositive[model["GammaPower"], ass],
        (y - model["TargetOffset"])/model["TargetScale"] > 1,
        0 < (y - model["TargetOffset"])/model["TargetScale"] < 1], target > 0],
    "TargetCoordinateExpression" -> target, "ExactTransformedFunction" -> LogGamma[model["Argument"]],
    "SourceScale" -> model["SourceScale"], "SourceOffset" -> model["SourceOffset"],
    "GammaFamily" -> model["Family"], "GammaPower" -> model["GammaPower"],
    "TargetScale" -> model["TargetScale"], "TargetOffset" -> model["TargetOffset"],
    "Power" -> r, "Method" -> "OrderedStirlingReversion", "RequestedMethod" -> method,
    "Cutoff" -> requested, "RequestedCutoff" -> cutoff, "Truncation" -> "Exponent",
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Length[retained],
    "ModelTerms" -> Floor[n/2], "Exact" -> False, "ExactModel" -> False,
    "DeclaredInputRemainder" -> input,
    "ForwardRemainderContract" -> <|"Type" -> "FiniteStirlingPoincare", "ConvergentForwardSeries" -> False,
      "LogGammaRemainderPower" -> 2 Floor[n/2] + 1, "Reference" -> "https://dlmf.nist.gov/5.11.ii"|>,
    "SeriesData" -> Missing["PolynomialInverseLogCoefficients"],
    "TermConvention" -> "Complete polynomials in 1/Log[CoreInverse] at each power of 1/CoreInverse. The cutoff is exclusive in that coordinate; SeriesTermGoal counts nonzero complete blocks.",
    "RemainderExplanation" -> "Finite Stirling value/derivative bounds and a uniform finite-model implicit-function argument justify the first omitted core-power block. This is a Poincare expansion, not a convergence or pointwise certificate."|>, bound]]];

gammaInverseTruncate[s : PowerLogSeries[a_Association], h_, limit_] := Module[{kept, omitted, frontier, q, core, bound},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  validateInput[{a["Terms"], h}, limit];
  If[! exactRealQ[h], fail["InvalidCutoff", "The core-power cutoff must be an exact real number."]];
  kept = Select[a["Terms"], less[#[[1]], h] &];
  omitted = Select[a["Terms"], ! less[#[[1]], h] &];
  If[omitted === {}, Return[s, Module]];
  frontier = First[omitted]; q = a["CoefficientVariable"]; core = a["CoreInverse"];
  bound = gammaInverseBound[frontier, core, q, a["Assumptions"]];
  PowerLogSeries[Join[a, <|"Terms" -> kept, "Blocks" -> kept, "Cutoff" -> h,
    "Expression" -> Total[(core^(-#[[1]]) (#[[2]] /. a["CoefficientSubstitution"])) & /@ kept],
    "CoefficientFrontier" -> frontier,
    "FrontierTerm" -> core^(-frontier[[1]]) (frontier[[2]] /. a["CoefficientSubstitution"]),
    "ReturnedTermCount" -> Length[kept]|>, bound]]];
