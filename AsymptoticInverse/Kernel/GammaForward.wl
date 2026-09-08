(* Gamma on a positive growing argument is Exp[LogGamma]. Expand its
   logarithm in the existing power-log algebra, then let the explicit series
   exponential extract the exact growing prefactor. This transports a
   vanishing absolute logarithmic error to a relative Gamma error.
   Stirling's expansion is Poincare asymptotic, not a convergent series:
   https://dlmf.nist.gov/5.11.E3 and https://dlmf.nist.gov/5.11.ii . *)

gammaForwardExpansion[f_, x_, x0_, cutoff0_, ass_, coord_, goal_, limit_] := Module[
  {arg, localArg, argumentLimit, cutoff = cutoff0, working, tries = 0,
   logarithmic, expanded, data, rows, omitted, frontier, prefactor, domain, result, magnitude},
  If[! MatchQ[f, Gamma[_]] || FreeQ[f, x], Return[$Failed, Module]];
  validateInput[f, limit];
  If[cutoff === Automatic,
    If[! IntegerQ[goal] || goal < 1,
      fail["InvalidCutoff", "Give an exponent cutoff or SeriesTermGoal -> n."]];
    If[goal + 1 > limit, fail["ResourceLimit", "The Gamma term goal and its frontier exceed MaxTerms."]],
    If[! exactRealQ[cutoff], fail["InvalidCutoff", "The cutoff must be an exact real number."]]];
  arg = f[[1]]; localArg = arg /. x -> coord["Substitution"];
  argumentLimit = inverseBranchTry[Limit[localArg, coord["u"] -> 0,
    Direction -> "FromAbove", Assumptions -> ass]];
  If[argumentLimit =!= Infinity || ! inverseFunctionEventually[localArg > 0, coord["u"], ass],
    Return[$Failed, Module]];
  domain = coord["LocalVariable"] > 0 && arg > 0;
  working = If[cutoff === Automatic, 1, Max[1, cutoff]];
  While[True,
    If[++tries > 12 || Ceiling[working] + 2 > limit,
      fail["ResourceLimit", "Gamma logarithmic normalization exceeded its working-order budget."]];
    logarithmic = forwardCore[LogGamma[arg], x, x0, working + 1,
      Assumptions -> ass, Direction -> coord["Direction"], "MaxTerms" -> limit];
    expanded = seriesExp[logarithmic, working + 1, limit];
    data = seriesData[expanded, limit]; rows = data["Jet"][[1]];
    If[cutoff =!= Automatic || Length[rows] > goal || data["Jet"][[2]] === Infinity, Break[]];
    working = 2 working + 1];
  If[cutoff === Automatic, cutoff = If[Length[rows] > goal, rows[[goal + 1, 1]], Infinity]];
  If[IntegerQ[goal] && goal > 0 && Length[Select[rows, less[#[[1]], cutoff] &]] > goal,
    cutoff = rows[[goal + 1, 1]]];
  omitted = Select[rows, ! less[#[[1]], cutoff] &];
  prefactor = FullSimplify[data["Prefactor"], ass && domain];
  data = Join[data, <|"Prefactor" -> prefactor, "Domain" -> domain,
    "RemainderDerivativeOrder" -> 0|>];
  result = seriesMake[data, {"GammaForward", {}}, cutoff];
  magnitude = FullSimplify[Abs[prefactor], ass && domain];
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
    "Transformation" -> "Gamma[arg] == Exp[LogGamma[arg]] on the positive real argument approach.",
    "AsymptoticReference" -> "https://dlmf.nist.gov/5.11.E3"|>]]];
