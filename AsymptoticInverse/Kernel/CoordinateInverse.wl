(* Exact changes of coordinates around the existing inverse engines.
   Loaded inside AsymptoticInverse`Private`. *)

coordinateExponentialPhase[f_, x_, x0_, dir_, ass_, limit_] := Module[
  {coord, u, ell = Unique["ell$"], parts, offset, dependent, factors, exponentials,
   exponent, amplitude, jet, coefficient, degree, sign, phase, argumentJet, scale},
  If[FreeQ[f, Power[_, e_] /; ! FreeQ[e, x]], Return[$Failed, Module]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"];
  parts = If[Head[f] === Plus, List @@ f, {f}];
  offset = Total[Select[parts, FreeQ[#, x] &]];
  dependent = Select[parts, ! FreeQ[#, x] &];
  If[Length[dependent] =!= 1, Return[$Failed, Module]];
  factors = If[Head[First[dependent]] === Times, List @@ First[dependent], dependent];
  exponentials = Select[factors, MatchQ[#, Power[_, e_] /; ! FreeQ[e, x]] &];
  If[exponentials === {}, Return[$Failed, Module]];
  exponent = Total[If[#[[1]] === E, #[[2]], #[[2]] Log[#[[1]]]] & /@ exponentials];
  amplitude = Times @@ Select[factors, ! MemberQ[exponentials, #] &];
  argumentJet = catch[forwardJet[exponent /. x -> coord["Substitution"], u, ell, ass, 1, limit]];
  If[FailureQ[argumentJet] || argumentJet[[1]] === {} || ! less[argumentJet[[1, 1, 1]], 0],
    Return[$Failed, Module]];
  jet = forwardJet[amplitude /. x -> coord["Substitution"], u, ell, ass, 1, limit];
  If[jet[[1]] === {}, Return[$Failed, Module]];
  degree = polyDegree[jet[[1, 1, 2]], ell];
  coefficient = (-1)^degree Coefficient[jet[[1, 1, 2]], ell, degree];
  sign = Which[provablyPositive[coefficient, ass], 1, provablyNegative[coefficient, ass], -1,
    True, fail["UnprovedSign", "The exponential amplitude must have a provable eventual real sign."]];
  scale = Simplify[Abs[Times @@ Select[If[Head[amplitude] === Times, List @@ amplitude, {amplitude}], FreeQ[#, x] &]], ass];
  If[! TrueQ[Simplify[Element[offset, Reals], ass]],
    fail["UnprovedRealCoefficient", "The target offset must be provably real."]];
  phase = exponent + Log[sign amplitude/scale];
  <|"Phase" -> phase, "AmplitudeSign" -> sign, "AmplitudeScale" -> scale, "Offset" -> offset,
    "Coordinate" -> coord, "PositiveAmplitude" -> sign amplitude|>];

coordinateConstruct[f_, x_, x0_, y_, cutoff_, opts : OptionsPattern[AsymptoticInverse]] := Module[
  {ass = OptionValue[AsymptoticInverse, {opts}, Assumptions],
   dir = OptionValue[AsymptoticInverse, {opts}, Direction],
   limit = OptionValue[AsymptoticInverse, {opts}, "MaxTerms"],
   inputRem = OptionValue[AsymptoticInverse, {opts}, "InputRemainder"],
   data, target = Unique["phaseTarget$"], targetExpression, base, a, sub, domain, targetLimit},
  data = coordinateExponentialPhase[f, x, x0, dir, ass, limit];
  If[data === $Failed, Return[$Failed, Module]];
  validateInput[f, limit];
  If[x === y || ! FreeQ[f, y], fail["InvalidVariables", "Source and target symbols must be distinct, and the target must not occur in the input."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters only."]];
  If[! MemberQ[{Automatic, None}, inputRem],
    fail["UnsupportedOption", "An additive input remainder must be transported through the logarithmic target coordinate before inversion."]];
  targetExpression = Log[data["AmplitudeSign"] (y - data["Offset"])/data["AmplitudeScale"]];
  base = inverseDispatch[data["Phase"], x, x0, target, cutoff, opts];
  If[FailureQ[base], Return[base, Module]];
  sub = target -> targetExpression;
  a = base[[1]] /. sub;
  (* The source positivity is an eventual hypothesis, not a target predicate. *)
  domain = data["AmplitudeSign"] (y - data["Offset"]) > 0 &&
    If[KeyExistsQ[base[[1]], "TargetDomain"], base["TargetDomain"] /. sub,
      If[MemberQ[{Infinity, -Infinity}, base["Limit"]], targetExpression, targetExpression - base["Limit"]]/base["LeadingCoefficient"] > 0];
  targetLimit = Which[base["Limit"] === Infinity, data["AmplitudeSign"] Infinity,
    base["Limit"] === -Infinity, data["Offset"], True, data["Offset"] + data["AmplitudeSign"] data["AmplitudeScale"] Exp[base["Limit"]]];
  PowerLogSeries[Join[a, <|"Scale" -> "Transformed", "CoordinateKind" -> "TargetLog",
    "CoordinateSeries" -> base, "CoordinateSubstitution" -> {sub},
    "TargetCoordinateExpression" -> targetExpression, "TransformedFunction" -> data["Phase"],
    "SourceDomain" -> data["PositiveAmplitude"] > 0,
    "Function" -> f, "Variable" -> y, "Variables" -> {x, y}, "Limit" -> targetLimit,
    "TargetDomain" -> domain, "RemainderScaleExpression" -> (a["Remainder"] /. q_PowerLogRemainder :> remainderScale[q]),
    "SeriesData" -> Missing["TransformedCoordinate"],
    "TermConvention" -> "Terms and cutoff use the underlying inverse coordinate, composed with TargetCoordinateExpression; CoordinateSeries records that convention.",
    "Transformations" -> {<|"Type" -> "TargetLog", "Expression" -> targetExpression,
      "InverseMap" -> data["Offset"] + data["AmplitudeSign"] data["AmplitudeScale"] Exp[target]|>}|>]]];

coordinateResidual[a_, h_, limit_] := Module[{result},
  result = residual[a["CoordinateSeries"][[1]], h, limit] /. a["CoordinateSubstitution"];
  Join[result, <|"TargetCoordinate" -> a["TargetCoordinateExpression"],
    "Scope" -> "Formal composition with the transformed forward model in the logarithmic target coordinate.",
    "OriginalFunction" -> a["Function"]|>]];

coordinateNumericalCheck[a_, yv_, wp_] := Module[
  {x = a["Variables"][[1]], y = a["Variable"], yy, approx, seed, xr, local,
   base = a["CoordinateSeries"], phase, target, r = a["Power"], observed, err, scale, z},
  If[! IntegerQ[wp] || wp < 10, fail["InvalidOption", "WorkingPrecision must be an integer of at least 10 digits."]];
  If[! NumericQ[yv] || (! exactQ[yv] && Precision[yv] < wp),
    fail["InsufficientPrecision", "Supply an exact target or at least WorkingPrecision digits."]];
  yy = N[yv, wp + 10];
  If[! TrueQ[a["TargetDomain"] /. y -> yy], fail["OutsideBranch", "The target is outside the transformed real branch domain."]];
  approx = N[a["Expression"] /. y -> yy, wp + 10];
  seed = If[r === 1, approx,
    With[{side = Which[a["ExpansionPoint"] === Infinity, 1, a["ExpansionPoint"] === -Infinity, -1,
        a["Direction"] === "FromBelow", -1, True, 1]},
      If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], 0, a["ExpansionPoint"]] + side Abs[approx]^(1/r)]];
  phase = a["TransformedFunction"]; target = N[a["TargetCoordinateExpression"] /. y -> yy, wp + 10];
  xr = With[{xx = x, ff = phase, tt = target, start = seed, prec = wp + 10, goal = wp},
    Quiet[Check[xx /. FindRoot[ff == tt, {xx, start}, WorkingPrecision -> prec,
      AccuracyGoal -> Infinity, PrecisionGoal -> goal, MaxIterations -> 500], $Failed]]];
  If[xr === $Failed || ! NumericQ[xr], fail["RootNotFound", "The transformed equation did not converge from the asymptotic seed."]];
  local = Which[a["ExpansionPoint"] === Infinity, 1/xr, a["ExpansionPoint"] === -Infinity, -1/xr,
    a["Direction"] === "FromAbove", xr - a["ExpansionPoint"], True, a["ExpansionPoint"] - xr];
  If[! TrueQ[Im[xr] == 0] || ! TrueQ[local > 0], fail["OutsideBranch", "The numerical root is outside the selected source branch."]];
  observed = Which[r === 1, xr, MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], xr^r,
    True, (xr - a["ExpansionPoint"])^r];
  err = N[Abs[observed - approx], wp]; scale = N[a["RemainderScaleExpression"] /. y -> yy, wp];
  <|"ReferenceRoot" -> N[xr, wp], "ExactInverse" -> N[xr, wp], "ReferenceObservable" -> N[observed, wp],
    "Approximation" -> N[approx, wp], "Error" -> err, "RemainderScale" -> scale,
    "Ratio" -> If[TrueQ[scale == 0], Indeterminate, err/scale],
    "PhaseResidual" -> N[(phase /. x -> xr) - target, wp],
    "Evidence" -> "High-precision numerical comparison; no interval certificate."|>];
