(* Loaded in AsymptoticAnalysis`Private`.  Inverse-logarithmic expansions of
   real Lambert-W cores.  The finite bracket is an actual power-log jet in
   t = 1/A, with an exact, separately recorded leading prefactor. *)

lambertMonomial[e_, u_, ass_] := Module[{a = 1, p = 0, factors},
  factors = If[Head[e] === Times, List @@ e, {e}];
  Do[Which[
    FreeQ[v, u], a *= v,
    v === u, p++,
    Head[v] === Power && v[[1]] === u && FreeQ[v[[2]], u], p += v[[2]],
    True, Return[$Failed, Module]], {v, factors}];
  If[! exactRealQ[p], Return[$Failed, Module]];
  {Simplify[a, ass], canon[p]}];

lambertLogProduct[e_, u_, ell_, ass_] := Module[
  {a = 1, p = 0, b = 0, c = 0, q = 0, factors, base, power, lb},
  factors = If[Head[e] === Times, List @@ e, {e}];
  Do[Which[
    FreeQ[v, u], a *= v,
    v === u, p++,
    Head[v] === Power && v[[1]] === u && FreeQ[v[[2]], u], p += v[[2]],
    True,
    {base, power} = If[Head[v] === Power, {v[[1]], v[[2]]}, {v, 1}];
    lb = Expand[base /. Log[u] -> ell];
    If[q =!= 0 || ! FreeQ[lb, u] || ! PolynomialQ[lb, ell] || Exponent[lb, ell] =!= 1 || ! exactRealQ[power],
      Return[$Failed, Module]];
    b = Coefficient[lb, ell, 0]; c = Coefficient[lb, ell, 1]; q = power], {v, factors}];
  If[q === 0 || ! exactRealQ[p] || p === 0, Return[$Failed, Module]];
  <|"a" -> Simplify[a, ass], "p" -> canon[p], "b" -> b, "c" -> c, "q" -> canon[q]|>];

lambertLogCore[fu_, u_, ell_, ass_] := Module[{rows, y0 = 0, nonconstant, p, poly, q, a, b, core, parts, v, coefficients},
  rows = parseFinite[fu, u, ell, ass];
  If[rows =!= $Failed && And @@ (exactRealQ[#[[1]]] & /@ rows),
    rows = jetMerge[rows, ell, ass];
    y0 = Total[Cases[rows, {0, cc_} /; FreeQ[cc, ell] :> cc]];
    nonconstant = Select[rows, ! (#[[1]] === 0 && FreeQ[#[[2]], ell]) &];
    If[nonconstant === {}, Return[$Failed, Module]];
    {p, poly} = First[nonconstant]; q = Exponent[poly, ell];
    If[p === 0 || ! IntegerQ[q] || q < 1, Return[$Failed, Module]];
    a = Coefficient[poly, ell, q]; b = Simplify[Coefficient[poly, ell, q - 1]/(q a), ass];
    Do[If[! And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@ CoefficientList[row[[2]], ell]),
      fail["UnprovedRealCoefficient", "All coefficients of a real logarithmic model, including discarded higher-power terms, must be provably real.",
        <|"Polynomial" -> row[[2]]|>]], {row, rows}];
    coefficients = CoefficientList[Expand[v^q (poly /. ell -> -1/v - b)/(a (-1)^q)], v];
    coefficients = coefCanon[#, ass] & /@ coefficients;
    Return[<|"a" -> a, "p" -> p, "b" -> b, "c" -> 1, "q" -> q,
      "LogPolynomial" -> poly, "LogVariable" -> ell, "ResidualCoefficients" -> coefficients,
      "AffinePower" -> And @@ (zeroQ[#, ass] & /@ Rest[coefficients]),
      "Offset" -> y0, "Exact" -> (Length[nonconstant] === 1)|>, Module]];
  parts = If[Head[fu] === Plus, List @@ fu, {fu}];
  y0 = Total[Select[parts, FreeQ[#, u] &]];
  nonconstant = Select[parts, ! FreeQ[#, u] &];
  If[Length[nonconstant] =!= 1, Return[$Failed, Module]];
  core = lambertLogProduct[First[nonconstant], u, ell, ass];
  If[core === $Failed, Return[$Failed, Module]];
  Join[core, <|"Offset" -> y0, "Exact" -> True|>]];

lambertExponentialTerm[e_, x_, ass_] := Module[
  {parts, ef, rest, mono, arg, args, constant, dependent, emono},
  parts = If[Head[e] === Times, List @@ e, {e}];
  ef = Select[parts, Head[#] === Power && #[[1]] === E && ! FreeQ[#[[2]], x] &];
  If[Length[ef] =!= 1, Return[$Failed, Module]];
  rest = Times @@ DeleteCases[parts, First[ef]];
  mono = lambertMonomial[rest, x, ass]; If[mono === $Failed, Return[$Failed, Module]];
  arg = Expand[First[ef][[2]]]; args = If[Head[arg] === Plus, List @@ arg, {arg}];
  constant = Total[Select[args, FreeQ[#, x] &]];
  dependent = Select[args, ! FreeQ[#, x] &];
  If[Length[dependent] =!= 1, Return[$Failed, Module]];
  emono = lambertMonomial[First[dependent], x, ass];
  If[emono === $Failed || ! less[0, emono[[2]]], Return[$Failed, Module]];
  <|"a" -> Simplify[mono[[1]] Exp[constant], ass], "b" -> mono[[2]],
    "c" -> emono[[1]], "p" -> emono[[2]]|>];

lambertExponentialCore[f_, x_, ass_] := Module[{parts, y0, dependent, candidates, core, rest, u, ell, rows},
  parts = If[Head[f] === Plus, List @@ f, {f}];
  y0 = Total[Select[parts, FreeQ[#, x] &]];
  dependent = Select[parts, ! FreeQ[#, x] &];
  candidates = Select[dependent, ! FreeQ[#, Power[E, ee_] /; ! FreeQ[ee, x]] &];
  If[Length[candidates] =!= 1, Return[$Failed, Module]];
  core = lambertExponentialTerm[First[candidates], x, ass];
  If[core === $Failed, Return[$Failed, Module]];
  rest = Total[DeleteCases[dependent, First[candidates]]];
  If[rest =!= 0,
    If[! provablyPositive[core["c"], ass], Return[$Failed, Module]];
    rows = parseFinite[rest /. x -> 1/u, u, ell, ass];
    If[rows === $Failed || ! And @@ (exactRealQ[#[[1]]] & /@ rows), Return[$Failed, Module]];
    Do[If[! And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@ CoefficientList[row[[2]], ell]),
      fail["UnprovedRealCoefficient", "Discarded power-log perturbations of a real exponential core must have provably real coefficients.",
        <|"Polynomial" -> row[[2]]|>]], {row, rows}]];
  Join[core, <|"Offset" -> y0, "Exact" -> (rest === 0)|>]];

lambertRemainderJet[v_, coefficients_, scale_, cut_, ell_, ass_, limit_] := Module[{ans = {{0, 1}}, part},
  Do[If[less[j, cut] && ! zeroQ[coefficients[[j + 1]], ass],
    part = jetUnitPower[v, -j, cut - j, ell, ass, limit];
    ans = jetAdd[ans, jetScale[jetShift[part, j], coefficients[[j + 1]] scale^j, ell, ass], cut, ell, ass]],
    {j, Length[coefficients] - 1}];
  jetTrim[ans, cut, ell, ass]];

lambertCorrection[sign_, cut_, ell_, ass_, limit_, coefficients_: {1}, scale_: 1, degree_: 1] :=
 Module[{v = {}, next, iterations, extra},
  iterations = Ceiling[cut];
  If[iterations > limit, fail["ResourceLimit", "The logarithmic expansion exceeded MaxTerms.", <|"MaxTerms" -> limit|>]];
  Do[
    extra = jetAdd[lambertRemainderJet[v, coefficients, scale, cut, ell, ass, limit], {{0, -1}}, cut, ell, ass];
    next = jetAdd[jetUnitLog[v, cut, ell, ass, limit], jetScale[jetUnitLog[extra, cut, ell, ass, limit], 1/degree, ell, ass], cut, ell, ass];
    next = jetScale[jetShift[jetAdd[{{0, -ell}}, next, cut, ell, ass], 1], -sign, ell, ass];
    next = jetTrim[next, cut, ell, ass];
    If[next === v, Break[]]; v = next,
    {iterations}];
  v];

lambertConstruct[f_, x_, x0_, y_, cutoff0_, opts : OptionsPattern[AsymptoticInverse]] := Module[
  {ass = optionAssumptions[AsymptoticInverse, {opts}], dir = OptionValue[AsymptoticInverse, {opts}, Direction],
   goal = OptionValue[AsymptoticInverse, {opts}, SeriesTermGoal], limit = OptionValue[AsymptoticInverse, {opts}, "MaxTerms"],
   r = OptionValue[AsymptoticInverse, {opts}, "Power"], method = OptionValue[AsymptoticInverse, {opts}, Method],
   trunc = OptionValue[AsymptoticInverse, {opts}, "Truncation"], inputRem = OptionValue[AsymptoticInverse, {opts}, "InputRemainder"],
   coord, u, ell = Unique["ell$"], fu, core, kind, a, p, b, c, q, offset, amplitude, amplitudeSign, target,
   positiveTarget, Y, k, s, branch, argument, A, t, relativePower, prefactor, exactLocal, exactX, exactObservable,
   cutoff = cutoff0, work, v, allBlocks, blocks, omitted, beta, degree, terms, expression, remainder,
   domain, targetLimit, leadingCore, perturbation, frontier, pure = False, affineSign, rint,
   coefficients = {1}, polynomialCore = False, remainderJet, closedForm = True},
  core = $Failed;
  If[x0 === Infinity && ! FreeQ[f, Power[E, ee_] /; ! FreeQ[ee, x]],
    core = lambertExponentialCore[f, x, ass]; kind = "Exponential"];
  If[core === $Failed,
    If[FreeQ[f, Log], Return[$Failed, Module]];
    coord = localCoordinate[x, x0, dir]; u = coord["u"];
    fu = Simplify[f /. x -> coord["Substitution"], ass && u > 0];
    core = lambertLogCore[fu, u, ell, ass]; kind = "PowerLog"];
  If[core === $Failed, Return[$Failed, Module]];
  validateInput[f, limit];
  If[x === y || ! FreeQ[f, y], fail["InvalidVariables", "Source and target variables must be distinct, and the target must not occur in the forward expression."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters only."]];
  If[! MemberQ[{"Lagrange", "Newton", "Lambert"}, method], fail["InvalidOption", "Method must be Lagrange, Newton, or Lambert."]];
  If[trunc =!= "Exponent", fail["UnsupportedOption", "Lambert cores use exponent truncation in the inverse-logarithmic variable."]];
  If[! MemberQ[{Automatic, None}, inputRem], fail["UnsupportedOption", "Lambert cores currently require an explicit expression, without InputRemainder."]];
  If[! exactRealQ[r] || r === 0, fail["InvalidOption", "Power must be a nonzero exact real number."]];
  If[cutoff === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give a positive logarithmic cutoff or SeriesTermGoal -> n."]];
    cutoff = goal];
  If[! exactRealQ[cutoff] || ! less[0, cutoff], fail["InvalidCutoff", "A Lambert logarithmic cutoff must be a positive exact real number."]];
  {a, p, b, c} = Lookup[core, {"a", "p", "b", "c"}]; offset = core["Offset"];
  If[! And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@ {a, b, c, offset}),
    fail["UnprovedRealCoefficient", "The amplitude, logarithmic shift, exponential coefficient, and target offset must be provably real."]];
  If[! (provablyPositive[a, ass] || provablyNegative[a, ass]) ||
     ! (provablyPositive[c, ass] || provablyNegative[c, ass]), Return[$Failed, Module]];
  If[kind === "PowerLog",
    q = core["q"];
    coefficients = Lookup[core, "ResidualCoefficients", {1}];
    polynomialCore = ! TrueQ[Lookup[core, "AffinePower", True]]; closedForm = ! polynomialCore;
    If[provablyPositive[c, ass] && ! IntegerQ[q],
      fail["NonrealLambertCore", "A negative eventual logarithmic base requires an integer power on the real branch."]];
    amplitude = Simplify[a (-c)^q, ass];
    If[! (provablyPositive[amplitude, ass] || provablyNegative[amplitude, ass]), Return[$Failed, Module]];
    amplitudeSign = If[provablyPositive[amplitude, ass], 1, -1];
    target = y - offset; positiveTarget = amplitudeSign target; Y = target/amplitude;
    k = -p/q; s = If[less[0, k], 1, -1]; branch = If[s === 1, 0, -1];
    argument = k Y^(1/q) Exp[p b/(c q)];
    A = s (Log[Abs[k]] + Log[Y]/q + p b/(c q)); t = 1/A;
    rint = If[coord["Infinite"], -r, r];
    relativePower = -q rint/p;
    prefactor = Y^(rint/p) (A/Abs[k])^(-q rint/p);
    exactLocal = Y^(1/p) (ProductLog[branch, argument]/k)^(-q/p);
    affineSign = coord["Sign"];
    If[affineSign === -1 && ! IntegerQ[r], fail["InvalidOption", "Noninteger observable powers require a positive local branch."]];
    exactX = If[coord["Infinite"], affineSign/exactLocal, x0 + affineSign exactLocal];
    exactObservable = If[r === 1, exactX, affineSign^r exactLocal^rint];
    prefactor *= affineSign^r;
    targetLimit = If[less[0, p], offset, amplitudeSign Infinity];
    leadingCore = If[polynomialCore, offset + u^p (core["LogPolynomial"] /. core["LogVariable"] -> Log[u]),
      offset + a u^p (b + c Log[u])^q] /. u -> coord["LocalVariable"],
    coord = localCoordinate[x, x0, dir]; u = coord["u"];
    amplitude = a; amplitudeSign = If[provablyPositive[a, ass], 1, -1];
    target = y - offset; positiveTarget = amplitudeSign target; Y = target/a;
    If[b === 0,
      pure = True; A = If[provablyPositive[c, ass], Log[Y], -Log[Y]]; t = 1/A;
      prefactor = (Log[Y]/c)^(r/p); relativePower = 0; exactX = (Log[Y]/c)^(1/p);
      exactObservable = (Log[Y]/c)^(r/p); s = 0; branch = Missing["Elementary"]; argument = Missing["Elementary"],
      k = c p/b;
      If[! (provablyPositive[k, ass] || provablyNegative[k, ass]), Return[$Failed, Module]];
      s = If[provablyPositive[k, ass], 1, -1]; branch = If[s === 1, 0, -1];
      argument = k Y^(p/b); A = s (Log[Abs[k]] + (p/b) Log[Y]); t = 1/A;
      relativePower = r/p; prefactor = (A/Abs[k])^(r/p);
      exactX = (ProductLog[branch, argument]/k)^(1/p); exactObservable = (ProductLog[branch, argument]/k)^(r/p)];
    targetLimit = If[provablyPositive[c, ass], amplitudeSign Infinity, offset];
    leadingCore = offset + a x^b Exp[c x^p]];
  domain = ass && positiveTarget > 0 && A > 0;
  If[s === -1, domain = domain && argument >= -1/E && argument < 0];
  work = Ceiling[cutoff] + 2;
  If[pure,
    v = {}; allBlocks = {{0, 1}}; blocks = allBlocks;
    beta = If[TrueQ[core["Exact"]], Infinity, cutoff]; degree = 0; frontier = 0,
    v = If[kind === "PowerLog", lambertCorrection[s, work, ell, ass, limit, coefficients, Abs[k], q],
      lambertCorrection[s, work, ell, ass, limit]];
    allBlocks = jetUnitPower[v, relativePower, work, ell, ass, limit];
    If[polynomialCore,
      remainderJet = jetAdd[lambertRemainderJet[v, coefficients, Abs[k], work, ell, ass, limit], {{0, -1}}, work, ell, ass];
      allBlocks = jetMul[allBlocks, jetUnitPower[remainderJet, -rint/p, work, ell, ass, limit], work, ell, ass, limit]];
    blocks = Select[allBlocks, less[#[[1]], cutoff] &];
    omitted = Select[allBlocks, ! less[#[[1]], cutoff] &];
    If[omitted === {}, beta = Ceiling[cutoff]; degree = Ceiling[cutoff],
      beta = omitted[[1, 1]]; degree = polyDegree[omitted[[1, 2]], ell]];
    frontier = If[omitted === {}, Missing["NotComputed"], prefactor t^beta (omitted[[1, 2]] /. ell -> Log[t])]];
  terms = {#[[1]], #[[2]] /. ell -> Log[t]} & /@ blocks;
  expression = prefactor Total[(t^#[[1]] #[[2]]) & /@ terms];
  If[kind === "PowerLog" && r === 1 && ! coord["Infinite"], expression += x0];
  remainder = If[beta === Infinity, 0, Abs[prefactor] PowerLogRemainder[t, beta, degree]];
  perturbation = Simplify[f - leadingCore, ass];
  GeneralizedSeries[<|
    "Kind" -> "Inverse", "Scale" -> "Logarithmic", "Method" -> "Lambert", "RequestedMethod" -> method,
    "Expression" -> expression, "Prefactor" -> prefactor, "Terms" -> terms, "Blocks" -> blocks,
    "TermConvention" -> "Each {n,C} contributes Prefactor t^n C with t=LogarithmicVariable; a finite source endpoint is added when Power is 1. Cutoff bounds n in the normalized bracket.",
    "Remainder" -> remainder, "RemainderPower" -> beta, "RemainderLogDegree" -> degree,
    "RemainderVariable" -> t, "RemainderScaleExpression" -> If[beta === Infinity, 0, Abs[prefactor] t^beta (1 + Abs[Log[t]])^degree],
    "FrontierTerm" -> frontier, "LogarithmicVariable" -> t, "Uniformizer" -> t, "LogVariable" -> ell,
    "LambertSign" -> s, "LambertBranch" -> branch, "LambertArgument" -> argument, "LambertLogMagnitude" -> A,
    "LambertCorrectionBlocks" -> jetTrim[v, cutoff, ell, ass], "LambertUnitPower" -> relativePower,
    "LambertResidualCutoff" -> cutoff, "LambertCoreType" -> kind, "CoreParameters" -> core,
    "LambertPolynomialLog" -> polynomialCore, "LambertResidualCoefficients" -> coefficients,
    "LambertLocalObservablePower" -> If[kind === "PowerLog", rint, r],
    "LambertLogDegree" -> If[kind === "PowerLog", q, 0], "LambertScaleFactor" -> If[pure, 0, Abs[k]],
    "ExactInverseExpression" -> If[TrueQ[core["Exact"]] && closedForm, exactX, Missing["NoClosedFormInverse"]],
    "ExactObservableExpression" -> If[TrueQ[core["Exact"]] && closedForm, exactObservable, Missing["NoClosedFormInverse"]],
    "CoreInverseExpression" -> If[closedForm, exactX, Missing["NoClosedFormInverse"]],
    "CoreObservableExpression" -> If[closedForm, exactObservable, Missing["NoClosedFormInverse"]],
    "LambertSeedExpression" -> exactX,
    "LeadingCore" -> leadingCore, "LeadingCoreOnly" -> ! TrueQ[core["Exact"]], "BeyondLogarithmicOrders" -> perturbation,
    "RemainderExplanation" -> If[TrueQ[core["Exact"]], "Truncation of the analytic logarithmic unit expansion in t and t Log[t].",
      "The omitted higher-power terms change the inverse by less than its prefactor times every fixed power of t; the stated finite-order remainder also covers them."],
    "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "Limit" -> targetLimit, "TargetDomain" -> domain,
    "TargetDomainMeaning" -> "Necessary real coordinate conditions for the selected asymptotic source neighborhood; this is not a global injectivity certificate.",
    "LeadingCoefficient" -> amplitude, "LeadingPower" -> p,
    "Power" -> r, "Cutoff" -> cutoff, "Truncation" -> "Exponent", "Model" -> Missing["LogarithmicScale"],
    "ForwardExpansion" -> leadingCore, "Function" -> f, "Assumptions" -> ass,
    "LocalVariable" -> u, "LocalSubstitution" -> (x -> coord["Substitution"]),
    "ExactModel" -> TrueQ[core["Exact"]], "InputRemainder" -> None,
    "Branch" -> Which[pure, "The positive real elementary inverse tending to the source endpoint.",
      polynomialCore, "The asymptotic real inverse normalized about ProductLog branch " <> ToString[branch] <>
        "; lower logarithmic powers are included by the unit equation, and the inverse tends to the source endpoint.",
      True, "The real ProductLog branch " <> ToString[branch] <> " tending to the source endpoint; TargetDomain records necessary real coordinate conditions."],
    "SeriesData" -> Missing["LogarithmicScale"]|>]];

lambertResidual[a_Association, h_, limit_] := Module[
  {cut = If[h === Automatic, a["Cutoff"], h], ell = a["LogVariable"], ass = a["Assumptions"],
   power = a["LambertUnitPower"], sign = a["LambertSign"], t = a["LogarithmicVariable"], unit, v, res,
   localPower, logDegree, p, scale, rjet},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[! exactRealQ[cut] || ! less[0, cut], fail["InvalidCutoff", "The logarithmic residual cutoff must be a positive exact real number."]];
  If[power === 0,
    res = {},
    unit = Select[a["Blocks"], less[0, #[[1]]] &];
    If[TrueQ[Lookup[a, "LambertPolynomialLog", False]],
      localPower = a["LambertLocalObservablePower"]; logDegree = a["LambertLogDegree"];
      p = a["LeadingPower"]; scale = a["LambertScaleFactor"];
      (* Recover -Log[u]-b from the returned bracket itself.  This includes
         the polynomial R factor and checks actual source composition. *)
      v = jetShift[jetAdd[{{0, sign ell}}, jetScale[jetUnitLog[unit, cut, ell, ass, limit],
        -scale/localPower, ell, ass], cut, ell, ass], 1];
      rjet = lambertRemainderJet[v, a["LambertResidualCoefficients"], scale, cut, ell, ass, limit];
      res = jetMul[jetUnitPower[unit, p/localPower, cut, ell, ass, limit],
        jetMul[jetUnitPower[v, logDegree, cut, ell, ass, limit], rjet, cut, ell, ass, limit], cut, ell, ass, limit];
      res = jetAdd[res, {{0, -1}}, cut, ell, ass],
      v = jetAdd[jetUnitPower[unit, 1/power, cut, ell, ass, limit], {{0, -1}}, cut, ell, ass];
      res = jetAdd[v, jetScale[jetShift[jetAdd[{{0, -ell}}, jetUnitLog[v, cut, ell, ass, limit],
        cut, ell, ass], 1], sign, ell, ass], cut, ell, ass]]];
  <|"ZeroBelowCutoff" -> (res === {}),
    "NormalizedResidual" -> Total[(t^#[[1]] (#[[2]] /. ell -> Log[t])) & /@ res],
    "ResidualBlocks" -> res, "RelativeCutoff" -> cut,
    "Normalization" -> Which[power === 0, "The elementary exponential core is inverted exactly.",
      TrueQ[Lookup[a, "LambertPolynomialLog", False]], "(f_core(g)-offset)/(y-offset)-1, composed through the logarithm of the returned observable bracket.",
      True, "V + s t (-Log[t] + Log[1+V]); V is reconstructed from the returned truncated observable bracket."],
    "Scope" -> Which[TrueQ[a["LeadingCoreOnly"]],
      "Formal residual of the logarithmic leading core; higher-power perturbations are beyond every inverse-logarithmic order.",
      TrueQ[Lookup[a, "LambertPolynomialLog", False]], "Formal composition with the complete leading polynomial in the logarithm, in the inverse-logarithmic variable.",
      True, "Formal residual of the exact Lambert core in the inverse-logarithmic variable."]|>];
