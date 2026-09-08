(* Ordered inverse-Gamma corrections around an exact Lambert core.
   The coefficients are polynomials in q=1/Log[X], retained whole at each
   power of t=1/X. Stirling is used only to a finite, justified order. *)

gammaInverseModel[f_, x_, ass_] := Module[
  {parts, offset, dependent, factors, constant, variable, factor, family, power = 1,
   argument, slope, shift, barnes, logarithmic},
  If[FreeQ[f, _Gamma | _LogGamma | _BarnesG | _LogBarnesG], Return[$Failed, Module]];
  parts = If[Head[f] === Plus, List @@ f, {f}];
  offset = Total[Select[parts, FreeQ[#, x] &]];
  dependent = Select[parts, ! FreeQ[#, x] &];
  If[Length[dependent] =!= 1, Return[$Failed, Module]];
  factors = If[Head[First[dependent]] === Times, List @@ First[dependent], dependent];
  constant = Times @@ Select[factors, FreeQ[#, x] &];
  variable = Select[factors, ! FreeQ[#, x] &];
  If[Length[variable] =!= 1, Return[$Failed, Module]];
  factor = First[variable];
  If[MatchQ[factor, Power[_Gamma | _BarnesG, p_] /; FreeQ[p, x]],
    power = factor[[2]]; factor = factor[[1]]];
  If[! MatchQ[factor, Gamma[_] | LogGamma[_] | BarnesG[_] | LogBarnesG[_] | Log[BarnesG[_]]], Return[$Failed, Module]];
  barnes = MatchQ[factor, BarnesG[_] | LogBarnesG[_] | Log[BarnesG[_]]];
  logarithmic = MemberQ[{Log, LogGamma, LogBarnesG}, Head[factor]];
  family = If[barnes, If[logarithmic, "LogBarnesG", "BarnesG"],
    If[logarithmic, "LogGamma", "Gamma"]];
  argument = If[Head[factor] === Log, factor[[1, 1]], First[factor]];
  If[! PolynomialQ[argument, x] || Exponent[argument, x] =!= 1, Return[$Failed, Module]];
  slope = Coefficient[argument, x]; shift = argument /. x -> 0;
  If[! And @@ (TrueQ[FullSimplify[Element[#, Reals], ass]] & /@ {offset, shift}) ||
     ! (provablyPositive[constant, ass] || provablyNegative[constant, ass]) ||
     ! (provablyPositive[slope, ass] || provablyNegative[slope, ass]) ||
     ! (provablyPositive[power, ass] || provablyNegative[power, ass]),
    fail["UnprovedGammaInverseParameters", "Gamma/Barnes inverse affine parameters must be real, with proved nonzero source/target scales and a fixed nonzero real forward-function power."]];
  <|"Family" -> family, "Argument" -> argument, "SourceScale" -> slope,
    "SourceOffset" -> shift, "TargetScale" -> constant, "TargetOffset" -> offset,
    "IsBarnes" -> barnes, "Logarithmic" -> logarithmic,
    "CoreArgumentOffset" -> If[barnes, 1, 0], "SourceThreshold" -> If[barnes, 3, 2],
    "InverseScale" -> If[barnes, "BarnesGInverse", "GammaInverse"],
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
    If[LeafCount[unit] > limit, fail["ResourceLimit", "The inverse Gamma/Barnes G coefficient expansion exceeds MaxTerms."]],
    {j, 1, n}];
  unit];

gammaInverseRows[n_, r_, slope_, shift_, t_, q_, ass_, limit_, barnes_: False] := Module[{unit, observable, rows},
  unit = If[barnes, barnesInverseUnit[n, t, q, limit], gammaInverseUnit[n, t, q, limit]];
  observable = Normal[Series[(1 + unit + (If[barnes, 1, 0] - shift) t)^r, {t, 0, n}]];
  rows = Table[{canon[j - r], Expand[Coefficient[observable, t, j]/slope^r]}, {j, 0, n}];
  rows = Select[rows, ! TrueQ[FullSimplify[#[[2]] == 0, ass]] &];
  If[LeafCount[rows] > limit, fail["ResourceLimit", "The inverse Gamma/Barnes G observable exceeds MaxTerms."]];
  rows];

gammaInverseBound[frontier_, core_, q_, ass_, coefficientLog_: Automatic] := Module[{poly, degree, log},
  poly = Expand[frontier[[2]]];
  degree = Min[First /@ (First /@ CoefficientRules[poly, q])];
  log = If[coefficientLog === Automatic, Log[core], coefficientLog];
  <|"RemainderPower" -> frontier[[1]], "RemainderLogDegree" -> 0,
    "RemainderInverseLogPower" -> degree, "RemainderVariable" -> 1/core,
    "Remainder" -> PowerLogRemainder[1/core, frontier[[1]], 0]/log^degree,
    "RemainderScaleExpression" -> core^(-frontier[[1]])/log^degree|>];

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
   n, rows, retained, frontier, requested = cutoff, bound, expression, sourceSign, targetLimit,
   barnes, scale, coefficientLog, modelTerms, contract},
  model = gammaInverseModel[f, x, ass];
  If[model === $Failed, Return[$Failed, Module]];
  barnes = model["IsBarnes"]; scale = model["InverseScale"];
  sourceSign = If[provablyPositive[model["SourceScale"], ass], 1, -1];
  If[x0 =!= sourceSign Infinity, Return[$Failed, Module]];
  validateInput[f, limit];
  If[x === y || ! FreeQ[f, y] || ! FreeQ[ass, x | y],
    fail["InvalidVariables", "Use distinct source and target variables, a target-free forward expression, and parameter-only assumptions."]];
  coord = localCoordinate[x, x0, dir];
  If[! exactRealQ[r] || r === 0 || (sourceSign === -1 && ! IntegerQ[r]),
    fail["InvalidPower", "The inverse observable needs a nonzero exact real power; a negative source branch requires an integer power."]];
  If[! MemberQ[{"Lagrange", "Newton", "GroupedLagrange"}, method],
    fail["UnsupportedMethod", "These inverse families use ordered reversion of their logarithmic asymptotic model; the requested method is not supported."]];
  If[! MemberQ[{Automatic, None}, input],
    fail["UnsupportedInputRemainder", "A declared additive error must first be transported to the logarithmic Gamma or Barnes equation."]];
  If[truncation =!= "Exponent", fail["UnsupportedTruncation", "These inverse families use an exclusive core-power cutoff."]];
  If[cutoff === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give a core-power cutoff or a positive integer SeriesTermGoal."]]; n = goal,
    If[! exactRealQ[cutoff] || ! less[-r, cutoff], fail["InvalidCutoff", "The core-power cutoff must exceed the leading exponent -Power."]];
    n = Ceiling[cutoff + r]];
  If[! IntegerQ[n] || n > limit, fail["ResourceLimit", "The inverse Gamma/Barnes G order exceeds MaxTerms."]];
  rows = gammaInverseRows[n, r, model["SourceScale"], model["SourceOffset"], t, q, ass, limit, barnes];
  If[cutoff === Automatic,
    While[Length[rows] < goal + 1,
      n++; If[n > limit, fail["ResourceLimit", "The inverse Gamma/Barnes G nonzero-block search exceeds MaxTerms."]];
      rows = gammaInverseRows[n, r, model["SourceScale"], model["SourceOffset"], t, q, ass, limit, barnes]];
    retained = Take[rows, goal]; frontier = rows[[goal + 1]]; requested = frontier[[1]],
    retained = Select[rows, less[#[[1]], cutoff] &];
    While[Select[rows, ! less[#[[1]], cutoff] &] === {},
      n++; If[n > limit, fail["ResourceLimit", "The inverse Gamma/Barnes G frontier search exceeds MaxTerms."]];
      rows = gammaInverseRows[n, r, model["SourceScale"], model["SourceOffset"], t, q, ass, limit, barnes]];
    frontier = First[Select[rows, ! less[#[[1]], cutoff] &]]];
  target = If[! model["Logarithmic"],
    Log[(y - model["TargetOffset"])/model["TargetScale"]]/model["GammaPower"],
    (y - model["TargetOffset"])/model["TargetScale"]];
  core = If[barnes, Sqrt[4 target/ProductLog[4 target/E^3]], target/ProductLog[target/E]];
  coefficientLog = Log[core] - If[barnes, 1, 0];
  expression = Total[(core^(-#[[1]]) (#[[2]] /. q -> 1/coefficientLog)) & /@ retained];
  bound = gammaInverseBound[frontier, core, q, ass, coefficientLog];
  targetLimit = If[! model["Logarithmic"] && provablyNegative[model["GammaPower"], ass],
    model["TargetOffset"], If[provablyPositive[model["TargetScale"], ass], Infinity, -Infinity]];
  modelTerms = If[barnes, Max[0, Floor[(n - 2)/2]], Floor[n/2]];
  contract = If[barnes, <|"Type" -> "FiniteBarnesPoincare", "ConvergentForwardSeries" -> False,
      "LogBarnesRemainderPower" -> 2 modelTerms + 2, "Reference" -> "https://dlmf.nist.gov/5.17.E5"|>,
    <|"Type" -> "FiniteStirlingPoincare", "ConvergentForwardSeries" -> False,
      "LogGammaRemainderPower" -> 2 modelTerms + 1, "Reference" -> "https://dlmf.nist.gov/5.11.ii"|>];
  PowerLogSeries[Join[<|"Kind" -> scale, "Scale" -> scale,
    "Expression" -> expression, "Terms" -> retained, "Blocks" -> retained,
    "CoreInverse" -> core, "CoreLogExpression" -> coefficientLog,
    "CoreArgumentOffset" -> model["CoreArgumentOffset"],
    "RootSeedExpression" -> (core + model["CoreArgumentOffset"] - model["SourceOffset"])/model["SourceScale"],
    "CoefficientVariable" -> q, "CoefficientSubstitution" -> {q -> 1/coefficientLog},
    "CoefficientFrontier" -> frontier,
    "FrontierTerm" -> core^(-frontier[[1]]) (frontier[[2]] /. q -> 1/coefficientLog),
    "Function" -> f, "Variables" -> {x, y}, "Variable" -> y, "SourceVariable" -> x,
    "ExpansionPoint" -> x0, "Direction" -> coord["Direction"], "Limit" -> targetLimit,
    "Assumptions" -> ass, "SourceDomain" -> model["Argument"] > model["SourceThreshold"],
    (* Express the logarithmic target condition using real inequalities
       before evaluating a logarithm, including on invalid target values. *)
    "TargetDomain" -> ass && If[! model["Logarithmic"],
      If[provablyPositive[model["GammaPower"], ass],
        (y - model["TargetOffset"])/model["TargetScale"] > 1,
        0 < (y - model["TargetOffset"])/model["TargetScale"] < 1], target > 0],
    "TargetCoordinateExpression" -> target,
    "ExactTransformedFunction" -> If[barnes, LogBarnesG[model["Argument"]], LogGamma[model["Argument"]]],
    "SourceScale" -> model["SourceScale"], "SourceOffset" -> model["SourceOffset"],
    "TargetScale" -> model["TargetScale"], "TargetOffset" -> model["TargetOffset"],
    "Power" -> r, "Method" -> If[barnes, "OrderedBarnesReversion", "OrderedStirlingReversion"], "RequestedMethod" -> method,
    "Cutoff" -> requested, "RequestedCutoff" -> cutoff, "Truncation" -> "Exponent",
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Length[retained],
    "ModelTerms" -> modelTerms, "Exact" -> False, "ExactModel" -> False,
    "DeclaredInputRemainder" -> input,
    "ForwardRemainderContract" -> contract,
    "SeriesData" -> Missing["PolynomialInverseLogCoefficients"],
    "TermConvention" -> "Complete polynomials in 1/CoreLogExpression at each power of 1/CoreInverse. The cutoff is exclusive in that coordinate; SeriesTermGoal counts nonzero complete blocks.",
    "RemainderExplanation" -> "Finite logarithmic asymptotic errors, a uniform finite-model implicit-function argument, and a derivative lower bound justify the first omitted core-power block. This is a Poincare expansion, not a convergence or pointwise certificate."|>,
    If[barnes, <|"BarnesFamily" -> model["Family"], "BarnesPower" -> model["GammaPower"]|>,
      <|"GammaFamily" -> model["Family"], "GammaPower" -> model["GammaPower"]|>], bound]]];

gammaInverseTruncate[s : PowerLogSeries[a_Association], h_, limit_] := Module[{kept, omitted, frontier, q, core, bound},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  validateInput[{a["Terms"], h}, limit];
  If[! exactRealQ[h], fail["InvalidCutoff", "The core-power cutoff must be an exact real number."]];
  kept = Select[a["Terms"], less[#[[1]], h] &];
  omitted = Select[a["Terms"], ! less[#[[1]], h] &];
  If[omitted === {}, Return[s, Module]];
  frontier = First[omitted]; q = a["CoefficientVariable"]; core = a["CoreInverse"];
  bound = gammaInverseBound[frontier, core, q, a["Assumptions"], a["CoreLogExpression"]];
  PowerLogSeries[Join[a, <|"Terms" -> kept, "Blocks" -> kept, "Cutoff" -> h,
    "Expression" -> Total[(core^(-#[[1]]) (#[[2]] /. a["CoefficientSubstitution"])) & /@ kept],
    "CoefficientFrontier" -> frontier,
    "FrontierTerm" -> core^(-frontier[[1]]) (frontier[[2]] /. a["CoefficientSubstitution"]),
    "ReturnedTermCount" -> Length[kept]|>, bound]]];
