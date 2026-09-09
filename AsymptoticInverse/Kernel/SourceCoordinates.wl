(* Exact source charts, loaded in AsymptoticInverse`Private` after the series
   calculus. Each underlying inverse is for the chart variable itself; the
   requested original observable is reconstructed with transported precision. *)

$sourceCoordinateDepth = 0;

sourceLogChart[f_, x_, x0_, dir_, ass_, limit_] := Module[{coord, u, h, fu, phase},
  If[FreeQ[f, Log], Return[$Failed, Module]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"]; h = Unique["logSource$"];
  fu = Simplify[f /. x -> coord["Substitution"], ass && u > 0];
  phase = Simplify[fu /. u -> Exp[-h], ass && h > 0];
  If[FreeQ[phase, h] || ! FreeQ[phase, Power[E, e_] /; ! FreeQ[e, h]], Return[$Failed, Module]];
  <|"Kind" -> "SourceExp", "Coordinate" -> coord, "ChartVariable" -> h,
    "ChartEndpoint" -> Infinity, "ChartDirection" -> "FromBelow", "Phase" -> phase,
    "SourceCoordinateExpression" -> -Log[coord["LocalVariable"]],
    "SourceTransformExpression" -> If[coord["Infinite"], coord["Sign"] Exp[h], x0 + coord["Sign"] Exp[-h]],
    "Scale" -> 1|>];

sourceExponentialChart[f_, x_, x0_, dir_, ass_, limit_] := Module[{coord, u, phase, ell, rows, active, side},
  If[! MemberQ[{Infinity, -Infinity}, x0] ||
    FreeQ[f, Power[b_, e_] /; FreeQ[b, x] && ! FreeQ[e, x]], Return[$Failed, Module]];
  coord = localCoordinate[x, x0, dir]; side = coord["Sign"]; u = Unique["expSource$"]; ell = Unique["ell$"];
  phase = Simplify[f /. x -> -side Log[u], ass && u > 0];
  rows = parseFinite[phase, u, ell, ass];
  If[rows === $Failed || ! And @@ (exactRealQ[#[[1]]] & /@ rows), Return[$Failed, Module]];
  rows = jetMerge[rows, ell, ass];
  active = Select[rows, ! (#[[1]] === 0 && FreeQ[#[[2]], ell]) &];
  If[active === {} || active[[1, 1]] === 0, Return[$Failed, Module]];
  <|"Kind" -> "SourceLog", "Coordinate" -> coord, "ChartVariable" -> u,
    "ChartEndpoint" -> 0, "ChartDirection" -> "FromAbove", "Phase" -> phase,
    "SourceCoordinateExpression" -> Exp[-side x], "SourceTransformExpression" -> -side Log[u],
    "Scale" -> 1|>];

sourceExactObservable[base_, expression_, limit_, certificate_] := Module[{d = seriesData[base, limit], s},
  s = seriesMake[Join[d, <|"Offset" -> 0, "Prefactor" -> expression,
    "Jet" -> {{{0, 1}}, Infinity, 0}, "RemainderDerivativeOrder" -> Infinity|>], {"ExactSourceObservable", {base}}];
  GeneralizedSeries[Join[s[[1]], <|"ExactSourceCertificate" -> certificate|>]]];

sourceBaseDomain[base_] := Module[{a = base[[1]], y = base["Variable"]},
  Lookup[a, "TargetDomain", If[MemberQ[{Infinity, -Infinity}, a["Limit"]], y, y - a["Limit"]]/a["LeadingCoefficient"] > 0]];

sourceReconstruct[base_, chart_, r_, cutoff_, ass_, limit_] := Module[
  {coord = chart["Coordinate"], side, offset, coefficient, b = base, answer, exact, source, obs, d, powerResult, check, certificate},
  side = coord["Sign"]; offset = If[! coord["Infinite"] && r === 1, coord["Substitution"] /. coord["u"] -> 0, 0];
  exact = Which[base["Remainder"] === 0, Normal[base],
    TrueQ[Lookup[base[[1]], "ExactModel", False]] && ! TrueQ[Lookup[base[[1]], "LeadingCoreOnly", False]],
      Lookup[base[[1]], "ExactInverseExpression", Missing["NoExactInverse"]],
    True, Missing["NoExactInverse"]];
  certificate = <|"Type" -> If[base["Remainder"] === 0, "ExactInnerSeries", "ExactInnerInverse"],
    "Domain" -> sourceBaseDomain[base]|>;
  If[MissingQ[exact] && LeafCount[Normal[base]] <= 250 && LeafCount[chart["Phase"]] <= 200,
    check = Quiet[TimeConstrained[Simplify[(chart["Phase"] /. chart["ChartVariable"] -> Normal[base]) - base["Variable"],
      ass && sourceBaseDomain[base]], 2, $Failed]];
    If[check === 0, exact = Normal[base]; certificate = <|"Type" -> "SymbolicChartComposition",
      "ChartResidual" -> 0, "ChartInverse" -> Normal[base], "Domain" -> sourceBaseDomain[base]|>]];
  (* An exact chart inverse may be retained as an exact carrier. This also
     handles repeated exact logarithmic charts without a false finite-scale
     approximation to an exponentially amplified intermediate remainder. *)
  If[! MissingQ[exact],
    source = chart["SourceTransformExpression"] /. chart["ChartVariable"] -> exact;
    obs = Which[r === 1, source, coord["Infinite"], source^r,
      True, (source - (coord["Substitution"] /. coord["u"] -> 0))^r];
    obs = Simplify[obs, ass && sourceBaseDomain[base]];
    Return[sourceExactObservable[base, obs, limit, certificate], Module]];
  If[chart["Kind"] === "SourceExp",
    coefficient = If[coord["Infinite"], r, -r];
    b = seriesMake[Join[seriesData[base, limit], <|"Domain" -> sourceBaseDomain[base]|>], {"SourceBase", {base}}];
    answer = catch[seriesExp[seriesBinary["Multiply", b, seriesConstant[coefficient, b, limit], Automatic, limit], cutoff, limit]];
    If[FailureQ[answer], Return[answer, Module]];
    answer = seriesBinary["Multiply", answer, seriesConstant[side^r, answer, limit], Automatic, limit];
    If[offset =!= 0, d = seriesData[answer, limit];
      answer = seriesMake[Join[d, <|"Offset" -> d["Offset"] + offset|>], {"SourceOffset", {answer}, offset}]],
    answer = catch[seriesLog[base, cutoff, limit]]; If[FailureQ[answer], Return[answer, Module]];
    answer = seriesBinary["Multiply", answer, seriesConstant[-side, answer, limit], Automatic, limit];
    If[r =!= 1,
      powerResult = catch[seriesPower[answer, r, cutoff, limit]];
      If[FailureQ[powerResult] && MemberQ[{"LogarithmicLeadingPower", "UnsupportedScale"}, powerResult[[1]]],
        (* Keep the finite logarithmic approximation inside the exact observable
           carrier. Since x~c Log[w], its relative error is no larger than the
           absolute power-log remainder already available for x. *)
        d = seriesFlat[seriesData[answer, limit], limit];
        If[d === $Failed || d["Jet"][[1]] === {} || d["Jet"][[1, 1, 1]] =!= 0 ||
          ! less[0, d["Jet"][[2]]], Return[powerResult, Module]];
        obs = side^r (side Normal[answer])^r;
        answer = seriesMake[Join[d, <|"Offset" -> 0, "Prefactor" -> obs,
          "Jet" -> {{{0, 1}}, d["Jet"][[2]], d["Jet"][[3]]}, "RemainderDerivativeOrder" -> 0|>],
          {"SourcePowerCarrier", {answer}, r}, cutoff],
        If[FailureQ[powerResult], Return[powerResult, Module]]; answer = powerResult]]];
  answer];

sourceCoordinateConstruct[f_, x_, x0_, y_, cutoff0_, opts : OptionsPattern[AsymptoticInverse]] := Module[
  {ass = OptionValue[AsymptoticInverse, {opts}, Assumptions], dir = OptionValue[AsymptoticInverse, {opts}, Direction],
   r = OptionValue[AsymptoticInverse, {opts}, "Power"], trunc = OptionValue[AsymptoticInverse, {opts}, "Truncation"],
   inputRem = OptionValue[AsymptoticInverse, {opts}, "InputRemainder"], goal = OptionValue[AsymptoticInverse, {opts}, SeriesTermGoal],
   limit = OptionValue[AsymptoticInverse, {opts}, "MaxTerms"], method = OptionValue[AsymptoticInverse, {opts}, Method],
   chart, coord, q = cutoff0, working, base, result, underlyingOptions, originalOptions, tries = 0,
   a, d, obs = Unique["observable$"], restore, positive, offset, coefficient, domain, exact, count, finalCut},
  If[$sourceCoordinateDepth >= 6, Return[$Failed, Module]];
  chart = sourceLogChart[f, x, x0, dir, ass, limit];
  If[chart === $Failed, chart = sourceExponentialChart[f, x, x0, dir, ass, limit]];
  If[chart === $Failed, Return[$Failed, Module]];
  validateInput[f, limit];
  If[x === y || ! FreeQ[f, y], fail["InvalidVariables", "Source and target variables must be distinct, and the target must not occur in the forward expression."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters only."]];
  If[trunc =!= "Exponent", fail["UnsupportedOption", "Source-chart reconstruction needs an exponent cutoff in its recorded target coordinate."]];
  If[! MemberQ[{Automatic, None}, inputRem], fail["UnsupportedOption", "Transport an omitted forward remainder into the source chart before declaring it; source-coordinate inversion currently requires the explicit forward expression."]];
  If[! exactRealQ[r] || r === 0, fail["InvalidOption", "Power must be a nonzero exact real number."]];
  coord = chart["Coordinate"];
  If[coord["Sign"] === -1 && ! IntegerQ[r], fail["InvalidOption", "A noninteger observable power requires a positive real source branch."]];
  If[q === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give a positive source-chart cutoff or SeriesTermGoal -> n."]]; q = Max[1, goal]];
  If[cutoff0 === Automatic && chart["Kind"] === "SourceLog" && !(IntegerQ[r] && r > 0),
    fail["UnsupportedTermGoal", "A non-polynomial power of a logarithmic source reconstruction retains its finite approximation as a carrier; request an explicit cutoff instead of a unit term count."]];
  If[! exactRealQ[q] || ! less[0, q], fail["InvalidCutoff", "A source-chart reconstruction cutoff must be a positive exact real number."]];
  originalOptions = {opts};
  underlyingOptions = Select[originalOptions, ! MemberQ[{"Power", Direction, SeriesTermGoal, "Truncation"}, First[#]] &];
  If[method === "Lambert", underlyingOptions = DeleteCases[underlyingOptions, Rule[Method, _]]; AppendTo[underlyingOptions, Method -> "Lagrange"]];
  underlyingOptions = Join[underlyingOptions, {"Power" -> 1, Direction -> chart["ChartDirection"], "Truncation" -> "Exponent"}];
  working = q + 2;
  While[True,
    tries++;
    base = Block[{$sourceCoordinateDepth = $sourceCoordinateDepth + 1},
      inverseDispatch[chart["Phase"], chart["ChartVariable"], chart["ChartEndpoint"], y, working, Sequence @@ underlyingOptions]];
    If[FailureQ[base], Return[base, Module]];
    result = sourceReconstruct[base, chart, r, q, ass, limit];
    If[FailureQ[result],
      If[MemberQ[{"InsufficientObservablePrecision", "UnsupportedScale"}, result[[1]]],
        fail["InsufficientSourceReconstructionPrecision", "The chart inverse is not known to a vanishing absolute error in a representable scale. A finite logarithmic-depth approximation cannot be exponentiated at this accuracy.", <|"ChartFailure" -> result|>], Return[result, Module]]];
    d = seriesData[result, limit]; count = Length[d["Jet"][[1]]];
    If[result["Remainder"] === 0 ||
      (! less[d["Jet"][[2]], q] && (cutoff0 =!= Automatic || count >= goal)), Break[]];
    If[tries >= 8, fail["InsufficientOrder", "Source reconstruction did not reach the requested transported precision."]];
    working = 2 working + 1; If[cutoff0 === Automatic, q = 2 q + 1]];
  finalCut = q;
  If[cutoff0 === Automatic && count > goal, finalCut = d["Jet"][[1, goal + 1, 1]]; result = seriesMake[d, {"SourceReconstruction", {base}}, finalCut]];
  a = result[[1]]; offset = If[! coord["Infinite"] && r === 1, x0, 0];
  coefficient = If[coord["Infinite"], r, -r];
  restore = If[chart["Kind"] === "SourceExp", Log[(obs - offset)/coord["Sign"]^r]/coefficient,
    If[r === 1, Exp[-coord["Sign"] obs], Exp[-(obs/coord["Sign"]^r)^(1/r)]]];
  domain = ass && sourceBaseDomain[base];
  positive = If[chart["ChartEndpoint"] === 0, Normal[base] > 0, True];
  exact = If[a["Remainder"] === 0 && r === 1, a["Expression"], Missing["NonexactSourceReconstruction"]];
  GeneralizedSeries[Join[a, <|"Kind" -> "Inverse", "Scale" -> "Transformed", "CoordinateKind" -> chart["Kind"],
    "CoordinateSeries" -> base, "CoordinateSubstitution" -> {}, "ReconstructedSeries" -> result,
    "SourceCoordinateVariable" -> chart["ChartVariable"], "SourceCoordinateEndpoint" -> chart["ChartEndpoint"],
    "SourceCoordinateDirection" -> chart["ChartDirection"], "SourceCoordinateExpression" -> chart["SourceCoordinateExpression"],
    "SourceTransformExpression" -> chart["SourceTransformExpression"], "SourceScale" -> chart["Scale"],
    "ObservableToCoordinateVariable" -> obs, "ObservableToCoordinateExpression" -> restore,
    "TransformedFunction" -> chart["Phase"], "TargetCoordinateExpression" -> y,
    "Function" -> f, "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> x0,
    "Direction" -> coord["Direction"], "Limit" -> base["Limit"], "Power" -> r,
    "Assumptions" -> ass, "Cutoff" -> finalCut,
    "Method" -> "SourceCoordinates", "RequestedMethod" -> method, "Truncation" -> "Exponent", "InputRemainder" -> inputRem,
    "TargetDomain" -> domain && positive, "SourceDomain" -> coord["LocalVariable"] > 0,
    "LeadingCoefficient" -> base["LeadingCoefficient"], "LeadingPower" -> base["LeadingPower"],
    "ExactModel" -> Lookup[base[[1]], "ExactModel", False], "Model" -> Missing["SourceCoordinate"],
    "ExactInverseExpression" -> exact, "ExactObservableExpression" -> If[a["Remainder"] === 0, a["Expression"], Missing["NonexactObservable"]],
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Length[a["Blocks"]],
    "SeriesData" -> Missing["SourceCoordinate"],
    "Transformations" -> {<|"Type" -> chart["Kind"], "Expression" -> chart["SourceCoordinateExpression"],
      "InverseMap" -> chart["SourceTransformExpression"]|>},
    "Branch" -> "The selected real source branch reconstructed from the positive source chart; TargetDomain contains necessary coordinate conditions."|>]]];

sourceResidualJet[a_, cutoff_, limit_] := Module[
  {s = a["ReconstructedSeries"], d, exact, chartSeries, side, r = a["Power"], offset, coefficient,
   work = cutoff + 6, phaseSeries, pd, ell, ass, targetJet, normalizer, normalizerJet, result},
  d = seriesData[s, limit];
  (* Compose the displayed finite expression. Its stored approximation error
     is not an extra unknown in this formal residual calculation. *)
  d = Join[d, <|"Jet" -> {d["Jet"][[1]], Infinity, 0}, "RemainderDerivativeOrder" -> Infinity,
    "Domain" -> a["TargetDomain"]|>];
  side = Which[a["ExpansionPoint"] === -Infinity, -1, a["ExpansionPoint"] === Infinity, 1,
    a["Direction"] === "FromBelow", -1, True, 1];
  If[a["CoordinateKind"] === "SourceExp",
    offset = If[! MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]] && r === 1, a["ExpansionPoint"], 0];
    d = Join[d, <|"Offset" -> (d["Offset"] - offset)/side^r,
      "Jet" -> pScale[d["Jet"], side^(-r), d["LogVariable"], seriesAss[d]]|>];
    exact = seriesMake[d, {"ResidualFinitePart", {s}}];
    chartSeries = seriesLog[exact, work, limit];
    coefficient = If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], r, -r];
    chartSeries = seriesBinary["Multiply", chartSeries, seriesConstant[1/coefficient, chartSeries, limit], Automatic, limit],
    If[r =!= 1, fail["UnsupportedObservableResidual", "The exact source residual is available, but its fractional reconstruction requires logarithmic coefficient arithmetic for a jet-order check."]];
    exact = seriesMake[d, {"ResidualFinitePart", {s}}];
    chartSeries = seriesExp[seriesBinary["Multiply", exact, seriesConstant[-side, exact, limit], Automatic, limit], work, limit]];
  phaseSeries = AsymptoticInverse`SeriesObservable[chartSeries, a["TransformedFunction"], a["SourceCoordinateVariable"],
    "Cutoff" -> work, "MaxTerms" -> limit];
  If[FailureQ[phaseSeries], Throw[phaseSeries, $tag]];
  pd = seriesFlat[seriesData[phaseSeries, limit], limit];
  If[pd === $Failed, fail["UnsupportedResidualScale", "The reconstructed chart residual has no single power-log representation."]];
  ell = pd["LogVariable"]; ass = seriesAss[pd];
  targetJet = seriesExpressionJet[a["Variable"], pd, limit];
  normalizer = If[MemberQ[{Infinity, -Infinity}, a["Limit"]], a["Variable"], a["Variable"] - a["Limit"]];
  normalizerJet = seriesExpressionJet[normalizer, pd, limit];
  If[targetJet === $Failed || normalizerJet === $Failed, fail["UnsupportedResidualScale", "The target normalization is outside the chart's power-log algebra."]];
  result = pAdd[pd["Jet"], pScale[targetJet, -1, ell, ass], ell, ass];
  result = pMul[result, fwdPower[normalizerJet, -1, Unique["w$"], ell, ass, work, limit], ell, ass, limit];
  result = seriesTrim[result, cutoff, ell, ass];
  If[less[result[[2]], cutoff], fail["InsufficientResidualPrecision", "Reconstruction precision did not reach the requested residual cutoff."]];
  <|"ZeroBelowCutoff" -> (result[[1]] === {}),
    "NormalizedResidual" -> seriesJetExpression[result, pd["ScaleVariable"], ell],
    "ResidualBlocks" -> result[[1]], "RelativeCutoff" -> cutoff,
    "ResidualVariable" -> pd["ScaleVariable"],
    "Normalization" -> "(F_chart(chart(returned observable))-y)/(y-limit), or division by y at an infinite target.",
    "Scope" -> "Formal composition of the returned finite observable, reconstructed in the exact source chart."|>];

sourceCoordinateResidual[a_, h_, limit_] := Module[{q, chartValue, raw, normalized, normalizer, ass, attempt},
  q = If[h === Automatic, a["Cutoff"], h];
  If[! exactRealQ[q] || ! less[0, q], fail["InvalidCutoff", "A source-chart residual cutoff must be a positive exact real number."]];
  ass = a["Assumptions"] && a["TargetDomain"] && Element[a["Variable"], Reals];
  chartValue = a["ObservableToCoordinateExpression"] /. a["ObservableToCoordinateVariable"] -> a["Expression"];
  raw = (a["TransformedFunction"] /. a["SourceCoordinateVariable"] -> chartValue) - a["Variable"];
  normalizer = If[MemberQ[{Infinity, -Infinity}, a["Limit"]], a["Variable"], a["Variable"] - a["Limit"]];
  normalized = Quiet[TimeConstrained[Simplify[raw/normalizer, ass], 2, raw/normalizer]];
  If[normalized === 0, Return[<|"ZeroBelowCutoff" -> True, "NormalizedResidual" -> 0,
    "ExactResidualExpression" -> 0, "ResidualBlocks" -> {}, "RelativeCutoff" -> q,
    "Scope" -> "Exact symbolic composition of the returned observable through the source chart."|>, Module]];
  attempt = catch[sourceResidualJet[a, q, limit]];
  If[FailureQ[attempt],
    If[attempt[[1]] === "ResourceLimit", Throw[attempt, $tag]];
    Return[<|"ZeroBelowCutoff" -> Missing["NotComputed"], "NormalizedResidual" -> normalized,
      "ExactResidualExpression" -> normalized, "RelativeCutoff" -> q,
      "FormalSeriesUnavailable" -> attempt,
      "Scope" -> "Exact residual expression of the returned observable; no power-log jet-order assertion is made for this reconstruction."|>, Module]];
  Join[attempt, <|"ExactResidualExpression" -> normalized, "OriginalFunction" -> a["Function"]|>]];

sourceCoordinateNumericalCheck[a_, yv_, wp_] := Module[
  {z = a["SourceCoordinateVariable"], y = a["Variable"], x = a["Variables"][[1]], yy, seed, zr, xr,
   approx, observed, error, scale, local, phase = a["TransformedFunction"], r = a["Power"]},
  If[! IntegerQ[wp] || wp < 10, fail["InvalidOption", "WorkingPrecision must be an integer of at least 10 digits."]];
  If[! NumericQ[yv] || (! exactQ[yv] && Precision[yv] < wp),
    fail["InsufficientPrecision", "Supply an exact target or at least WorkingPrecision digits."]];
  yy = yv;
  If[! TrueQ[N[a["TargetDomain"] /. y -> yy, wp + 10]], fail["OutsideBranch", "The target is outside the recorded real source-chart domain."]];
  seed = N[Normal[a["CoordinateSeries"]] /. y -> yy, wp + 10];
  zr = With[{zz = z, ff = phase, target = yy, start = seed, prec = wp + 10, goal = wp},
    Quiet[Check[zz /. FindRoot[ff == target, {zz, start}, WorkingPrecision -> prec,
      AccuracyGoal -> Infinity, PrecisionGoal -> goal, MaxIterations -> 500], $Failed]]];
  If[zr === $Failed || ! NumericQ[zr], fail["RootNotFound", "The source-chart equation did not converge from its asymptotic seed."]];
  If[! TrueQ[Im[zr] == 0] || ! TrueQ[zr > 0], fail["OutsideBranch", "The numerical chart root is outside the selected positive source chart."]];
  xr = N[a["SourceTransformExpression"] /. z -> zr, wp + 10];
  local = Which[a["ExpansionPoint"] === Infinity, 1/xr, a["ExpansionPoint"] === -Infinity, -1/xr,
    a["Direction"] === "FromAbove", xr - a["ExpansionPoint"], True, a["ExpansionPoint"] - xr];
  If[! TrueQ[Im[xr] == 0] || ! TrueQ[local > 0], fail["OutsideBranch", "The reconstructed numerical root is outside the selected original source branch."]];
  approx = N[a["Expression"] /. y -> yy, wp + 10];
  observed = Which[r === 1, xr, MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], xr^r,
    True, (xr - a["ExpansionPoint"])^r];
  error = N[Abs[observed - approx], wp]; scale = N[a["RemainderScaleExpression"] /. y -> yy, wp];
  <|"ReferenceRoot" -> N[xr, wp], "ExactInverse" -> N[xr, wp], "ReferenceObservable" -> N[observed, wp],
    "Approximation" -> N[approx, wp], "Error" -> error, "RemainderScale" -> scale,
    "Ratio" -> If[TrueQ[scale == 0], Indeterminate, error/scale],
    "ChartRoot" -> N[zr, wp], "ChartResidual" -> N[(phase /. z -> zr) - yy, wp],
    "Evidence" -> "High-precision comparison in the exact source chart; no interval certificate."|>];
