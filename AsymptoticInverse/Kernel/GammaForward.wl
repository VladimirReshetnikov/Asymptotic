(* Combine real Gamma products in the logarithmic domain. Stirling's
   expansion is Poincare asymptotic, not a convergent series:
   https://dlmf.nist.gov/5.11.E3 and https://dlmf.nist.gov/5.11.ii . *)

(* Separate ordinary factors before distributing powers over positive
   Gamma factors. Retain original exponents as well as their products,
   so an unsupported exponent cannot disappear by cancellation. *)
gammaProductData[e_, x_] := Module[{parts, base, r},
  If[FreeQ[e, _Gamma] || FreeQ[e, x], Return[{e, {}, {}}, Module]];
  Which[
    MatchQ[e, Gamma[_]], {1, {{e[[1]], 1}}, {}},
    Head[e] === Times,
      parts = gammaProductData[#, x] & /@ List @@ e;
      If[MemberQ[parts, $Failed], $Failed,
        {Times @@ parts[[All, 1]], Join @@ parts[[All, 2]], Join @@ parts[[All, 3]]}],
    Head[e] === Power,
      base = gammaProductData[e[[1]], x]; r = e[[2]];
      If[base === $Failed || base[[2]] === {}, $Failed,
        {base[[1]]^r, {#[[1]], r #[[2]]} & /@ base[[2]], Append[base[[3]], r]}],
    True, $Failed]];

gammaRelatedExpression[e_] := e /. {
  HoldPattern[Factorial[z_]] :> Gamma[z + 1],
  HoldPattern[Binomial[n_, k_]] :> Gamma[n + 1]/(Gamma[k + 1] Gamma[n - k + 1]),
  HoldPattern[Beta[a_, b_]] :> Gamma[a] Gamma[b]/Gamma[a + b],
  HoldPattern[Pochhammer[a_, n_]] :> Gamma[a + n]/Gamma[a]};

gammaForwardExpansion[f_, x_, x0_, cutoff_, ass_, coord_, goal_, limit_] := Module[
  {lowered, product, factors, coefficient, localArg, argumentLimit, growing = False,
   logFunction, simplified, domain, ordinary, powers},
  If[FreeQ[f, _Gamma | _Factorial | _Binomial | _Beta | _Pochhammer], Return[$Failed, Module]];
  validateInput[f, limit];
  lowered = gammaRelatedExpression[f];
  product = gammaProductData[lowered, x];
  If[product === $Failed || product[[2]] === {}, Return[$Failed, Module]];
  coefficient = product[[1]]; factors = product[[2]];
  Do[
    localArg = arg /. x -> coord["Substitution"];
    If[! inverseFunctionEventually[localArg > 0, coord["u"], ass], Return[$Failed, Module]];
    argumentLimit = inverseBranchTry[Limit[localArg, coord["u"] -> 0,
      Direction -> "FromAbove", Assumptions -> ass]];
    If[argumentLimit === Infinity, growing = True], {arg, DeleteDuplicates[factors[[All, 1]]]}];
  If[! growing, Return[$Failed, Module]];
  powers = DeleteDuplicates[Join[product[[3]], factors[[All, 2]]]];
  If[! AllTrue[powers, logarithmicRealCondition[Element[# /. x -> coord["Substitution"], Reals], ass, coord] &],
    fail["UnsupportedGammaPower", "Gamma powers require exact exponents that are eventually real.", <|"Powers" -> powers|>]];
  domain = coord["LocalVariable"] > 0 && And @@ (#[[1]] > 0 & /@ factors) && And @@ (Element[#, Reals] & /@ powers);
  ordinary = logarithmicProductSource[coefficient, x, ass, coord];
  domain = domain && ordinary["Domain"];
  logFunction = Total[#[[2]] LogGamma[#[[1]]] & /@ factors];
  simplified = TimeConstrained[FullSimplify[logFunction, ass && domain], 3, logFunction];
  (* FullSimplify can recombine LogGamma into Log[Gamma]. Keep only
     simplifications the power-log parser can still expand, such as Log[x]
     from the exact recurrence. Finite Stirling cancellation is not an
     exact identity of the original functions. *)
  If[FreeQ[simplified, _Gamma], logFunction = simplified];
  logFunction += ordinary["Logarithm"];
  logarithmicForwardExpansion[f, logFunction, ordinary["Sign"], domain,
    x, x0, cutoff, ass, coord, goal, limit, <|
      "GammaPower" -> If[Length[factors] === 1, factors[[1, 2]], Missing["NotSingleGamma"]],
      "GammaFactors" -> factors, "GammaExpression" -> lowered,
      "Transformation" -> "A signed product of positive Gamma factors with real powers equals Sign[coefficient] Exp[Log[Abs[coefficient]] + Sum[power LogGamma[arg]]].",
      "AsymptoticReference" -> "https://dlmf.nist.gov/5.11.E3"|>]];

(* Absolute vanishing logarithmic errors become relative errors. Extract
   every nonvanishing logarithmic block into the exact prefactor before
   counting correction terms. *)
logarithmicForwardExpansion[f_, logFunction_, sign_, domain_, x_, x0_, cutoff0_, ass_, coord_, goal_, limit_, metadata_] := Module[
  {cutoff = cutoff0, working, tries = 0, logarithmic, expanded, data, rows,
   omitted, frontier, prefactor, result, magnitude, normalized, exactCorrection},
  If[cutoff === Automatic,
    If[! IntegerQ[goal] || goal < 1,
      fail["InvalidCutoff", "Give an exponent cutoff or SeriesTermGoal -> n."]];
    If[goal + 1 > limit, fail["ResourceLimit", "The normalized term goal and its frontier exceed MaxTerms."]],
    If[! exactRealQ[cutoff], fail["InvalidCutoff", "The cutoff must be an exact real number."]]];
  working = If[cutoff === Automatic, 1, Max[1, cutoff]];
  While[True,
    If[++tries > 12 || Ceiling[working] + 2 > limit,
      fail["ResourceLimit", "Logarithmic normalization exceeded its working-order budget."]];
    logarithmic = forwardCore[logFunction, x, x0, working + 1,
      Assumptions -> ass, Direction -> coord["Direction"], "MaxTerms" -> limit];
    expanded = seriesExp[logarithmic, working + 1, limit];
    data = seriesData[expanded, limit];
    (* A finite exact factor can disappear into Log and acquire a spurious
       Taylor tail. Recover it from the exact logarithmic identity, never
       from cancellation in a finite asymptotic model. *)
    If[tries === 1 && FreeQ[logFunction, _LogGamma | _Gamma],
      normalized = TimeConstrained[FullSimplify[Exp[logFunction]/data["Prefactor"], ass && domain], 3, $Failed];
      If[normalized =!= $Failed,
        exactCorrection = exactJet[normalized /. x -> coord["Substitution"], coord["u"], data["LogVariable"], ass, limit];
        If[exactCorrection =!= $Failed && exactCorrection[[2]] === Infinity,
          data = Join[data, <|"Jet" -> exactCorrection|>]]]];
    rows = data["Jet"][[1]];
    If[cutoff =!= Automatic || Length[rows] > goal || data["Jet"][[2]] === Infinity, Break[]];
    working = 2 working + 1];
  If[cutoff === Automatic, cutoff = If[Length[rows] > goal, rows[[goal + 1, 1]], Infinity]];
  If[IntegerQ[goal] && goal > 0 && Length[Select[rows, less[#[[1]], cutoff] &]] > goal,
    cutoff = rows[[goal + 1, 1]]];
  omitted = Select[rows, ! less[#[[1]], cutoff] &];
  prefactor = TimeConstrained[FullSimplify[sign data["Prefactor"], ass && domain], 3, sign data["Prefactor"]];
  data = Join[data, <|"Prefactor" -> prefactor, "Domain" -> domain,
    "RemainderDerivativeOrder" -> 0|>];
  result = seriesMake[data, {"LogarithmicForward", {}}, cutoff];
  (* The carrier is the exponential of a real logarithmic expansion;
     its only sign is the separately proved sign of the coefficient. *)
  magnitude = sign prefactor;
  frontier = If[omitted === {}, If[result["Remainder"] === 0, 0, Missing["Unknown"]],
    prefactor seriesJetExpression[{{First[omitted]}, Infinity, 0}, data["ScaleVariable"], data["LogVariable"]]];
  PowerLogSeries[Join[result[[1]], <|"Kind" -> "Forward", "Function" -> f,
    "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "Remainder" -> If[result["Remainder"] === 0, 0,
      magnitude PowerLogRemainder[data["ScaleVariable"], result["RemainderPower"], result["RemainderLogDegree"]]],
    "RemainderScaleExpression" -> If[result["Remainder"] === 0, 0,
      magnitude data["ScaleVariable"]^result["RemainderPower"]
        (1 + Abs[Log[data["ScaleVariable"]]])^result["RemainderLogDegree"]],
    "FrontierTerm" -> frontier, "RequestedTermGoal" -> goal,
    "ReturnedTermCount" -> Length[result["Terms"]], "LogarithmicExpansion" -> logarithmic,
    "ExactModel" -> TrueQ[result["Exact"]], "ExpansionNature" -> "Poincare",
    "LogarithmicFunction" -> logFunction|>, metadata]]];
