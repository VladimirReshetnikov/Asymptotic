(* Exact rational residual certificates. Decimal arithmetic is used only to
   choose a center; every successful proof uses rational interval endpoints. *)

certFail[tag_, message_, data_: <||>] := fail[tag, message, Join[<|"Certified" -> False|>, data]];
certRationalQ[q_] := IntegerQ[q] || Head[q] === Rational;

(* Directed rounding to a dyadic grid with a fixed number of significant bits.
   Floor and Ceiling act on exact rationals. No floating-point predicate enters
   interval arithmetic or the final containment test. *)
certRound[q_, bits_, upper_] := Module[{a, exponent, grid},
  If[q === 0, Return[0, Module]];
  a = Abs[q];
  exponent = IntegerLength[Numerator[a], 2] - IntegerLength[Denominator[a], 2];
  If[a < 2^exponent, exponent--];
  grid = 2^(exponent - bits + 1);
  grid If[upper, Ceiling[q/grid], Floor[q/grid]]];
certRoundInterval[{lo_, hi_}, ctx_] :=
  {certRound[lo, ctx["Bits"], False], certRound[hi, ctx["Bits"], True]};
certAdd[a_, b_, ctx_] := certRoundInterval[a + b, ctx];
certNeg[{lo_, hi_}] := {-hi, -lo};
certMul[a_, b_, ctx_] := Module[{products = Flatten[Outer[Times, a, b]]},
  certRoundInterval[{Min[products], Max[products]}, ctx]];
certReciprocal[{lo_, hi_}, ctx_] := (
  If[lo <= 0 <= hi, certFail["IntervalSingularity", "An interval reciprocal contains zero.",
    <|"UnprovedCondition" -> (hi < 0 || lo > 0), "ArgumentEnclosure" -> {lo, hi}|>]];
  certRoundInterval[{1/hi, 1/lo}, ctx]);
certIntegerPower[a_, n_Integer, ctx_] := Module[{base = a, power = Abs[n], answer = {1, 1}},
  If[power > 100000, certFail["CertificateResourceLimit", "The integer power exceeds the certificate arithmetic budget."]];
  If[n < 0, base = certReciprocal[base, ctx]];
  While[power > 0,
   If[OddQ[power], answer = certMul[answer, base, ctx]];
   power = Quotient[power, 2];
   If[power > 0,
    (* Squaring a real interval is tighter than multiplying independent copies. *)
    base = certRoundInterval[If[base[[1]] <= 0 <= base[[2]],
       {0, Max[base[[1]]^2, base[[2]]^2]}, Sort[base^2]], ctx]]];
  answer];

certExpPoint[q_?certRationalQ, ctx_] := Module[{z, reductions = 0, n, sum, tail, answer},
  If[q === 0, Return[{1, 1}, Module]];
  If[Abs[q] > ctx["ExponentMagnitudeLimit"],
   certFail["CertificateResourceLimit", "The exponential argument exceeds the exact enclosure budget; use a logarithmic phase when available.",
    <|"Argument" -> q, "ExponentMagnitudeLimit" -> ctx["ExponentMagnitudeLimit"]|>]];
  If[q < 0, Return[certReciprocal[certExpPoint[-q, ctx], ctx], Module]];
  z = q;
  While[z > 1/2, z /= 2; reductions++];
  n = ctx["SeriesOrder"];
  sum = Sum[z^k/k!, {k, 0, n}];
  tail = z^(n + 1)/(n + 1)!/(1 - z/(n + 2));
  answer = certRoundInterval[{sum, sum + tail}, ctx];
  Do[answer = certIntegerPower[answer, 2, ctx], {reductions}];
  answer];
certExp[a_, ctx_] := {certExpPoint[a[[1]], ctx][[1]], certExpPoint[a[[2]], ctx][[2]]};

certLogUnit[q_?certRationalQ, ctx_] := Module[{u, n, sum, tail},
  If[q === 1, Return[{0, 0}, Module]];
  u = (q - 1)/(q + 1); n = ctx["SeriesOrder"];
  (* This helper is used only for 1 <= q <= 2, hence 0 <= u <= 1/3. *)
  sum = 2 Sum[u^(2 k + 1)/(2 k + 1), {k, 0, n - 1}];
  tail = 2 u^(2 n + 1)/((2 n + 1) (1 - u^2));
  certRoundInterval[{sum, sum + tail}, ctx]];
certLogPoint[q_?certRationalQ, ctx_] := Module[{exponent, z, unit, logTwo},
  If[q <= 0, certFail["IntervalDomain", "A logarithm argument is not strictly positive.",
    <|"UnprovedCondition" -> (q > 0), "Argument" -> q|>]];
  If[q === 1, Return[{0, 0}, Module]];
  exponent = IntegerLength[Numerator[q], 2] - IntegerLength[Denominator[q], 2];
  If[q < 2^exponent, exponent--];
  z = q/2^exponent;
  unit = certLogUnit[z, ctx];
  If[exponent === 0, Return[unit, Module]];
  logTwo = certLogUnit[2, ctx];
  certAdd[unit, certMul[{exponent, exponent}, logTwo, ctx], ctx]];
certLog[a_, ctx_] := (
  If[a[[1]] <= 0, certFail["IntervalDomain", "The logarithm enclosure reaches a nonpositive argument.",
    <|"UnprovedCondition" -> (a[[1]] > 0), "ArgumentEnclosure" -> a|>]];
  {certLogPoint[a[[1]], ctx][[1]], certLogPoint[a[[2]], ctx][[2]]});

(* Apply logarithmic identities only after each factor has acquired a real
   logarithm enclosure. No unrestricted PowerExpand is used. *)
certLogExpression[argument_, x_, interval_, ctx_] := Module[{candidate},
  If[argument === E, Return[{1, 1}, Module]];
  If[Head[argument] === Power && argument[[1]] === E,
   Return[certEnclose[argument[[2]], x, interval, ctx], Module]];
  If[Head[argument] === Times,
   candidate = catch[Fold[certAdd[#1, #2, ctx] &, {0, 0},
      certLogExpression[#, x, interval, ctx] & /@ (List @@ argument)]];
   If[ListQ[candidate], Return[candidate, Module]]];
  If[Head[argument] === Power,
   candidate = catch[certMul[certEnclose[argument[[2]], x, interval, ctx],
      certLogExpression[argument[[1]], x, interval, ctx], ctx]];
   If[ListQ[candidate], Return[candidate, Module]]];
  (* A positive product can have negative factors: retain the direct route. *)
  certLog[certEnclose[argument, x, interval, ctx], ctx]];

certEnclose[expression_, x_Symbol, interval_, ctx_] := Module[{args, base, exponent, upper},
  Which[
   expression === x, interval,
   certRationalQ[expression], {expression, expression},
   expression === E, certExpPoint[1, ctx],
   Head[expression] === Plus,
    Fold[certAdd[#1, #2, ctx] &, {0, 0}, certEnclose[#, x, interval, ctx] & /@ (List @@ expression)],
   Head[expression] === Times,
    Fold[certMul[#1, #2, ctx] &, {1, 1}, certEnclose[#, x, interval, ctx] & /@ (List @@ expression)],
   Head[expression] === Log && Length[expression] == 1,
    certLogExpression[expression[[1]], x, interval, ctx],
   Head[expression] === Log && Length[expression] == 2,
    certMul[certLogExpression[expression[[2]], x, interval, ctx],
     certReciprocal[certLogExpression[expression[[1]], x, interval, ctx], ctx], ctx],
   Head[expression] === Power && expression[[1]] === E,
    certExp[certEnclose[expression[[2]], x, interval, ctx], ctx],
   Head[expression] === Power && IntegerQ[expression[[2]]],
    certIntegerPower[certEnclose[expression[[1]], x, interval, ctx], expression[[2]], ctx],
   Head[expression] === Power,
    base = certEnclose[expression[[1]], x, interval, ctx];
    exponent = certEnclose[expression[[2]], x, interval, ctx];
    If[base[[1]] === 0 && certRationalQ[expression[[2]]] && expression[[2]] > 0,
     If[base[[2]] === 0, {0, 0},
      upper = certExp[certMul[exponent, certLog[{base[[2]], base[[2]]}, ctx], ctx], ctx];
      {0, upper[[2]]}],
     If[base[[1]] <= 0,
      certFail["IntervalDomain", "A noninteger real power needs a strictly positive base on the certificate interval.",
       <|"UnprovedCondition" -> (base[[1]] > 0), "ArgumentEnclosure" -> base|>]];
     certExp[certMul[exponent, certLog[base, ctx], ctx], ctx]],
   True, certFail["UnsupportedEnclosure", "The exact interval evaluator does not support this expression.",
     <|"Expression" -> expression, "SupportedOperations" -> {"Rational constants", "Plus", "Times", "Power on a positive base", "Exp", "Log"}|>]]];

certPositiveCondition[condition_, x_, interval_, ctx_] := Module[{bound},
  Which[condition === True, True,
   Head[condition] === And, And @@ (certPositiveCondition[#, x, interval, ctx] & /@ (List @@ condition)),
   Head[condition] === Greater && Length[condition] == 2,
    bound = certEnclose[condition[[1]] - condition[[2]], x, interval, ctx]; bound[[1]] > 0,
   Head[condition] === Less && Length[condition] == 2,
    bound = certEnclose[condition[[2]] - condition[[1]], x, interval, ctx]; bound[[1]] > 0,
   True, False]];

certSourceInterval[a_, interval_, x_, ctx_] := Module[{endpoint, side},
  Which[a["ExpansionPoint"] === Infinity, interval[[1]] > 0,
   a["ExpansionPoint"] === -Infinity, interval[[2]] < 0,
   True,
    endpoint = certEnclose[a["ExpansionPoint"], x, interval, ctx];
    If[a["Direction"] === "FromBelow", interval[[2]] < endpoint[[1]], interval[[1]] > endpoint[[2]]]]];

certSeed[a_, yv_, wp_] := Module[{value, power, side, endpoint},
  value = Quiet[Check[N[a["Expression"] /. a["Variable"] -> yv, wp], $Failed]];
  If[value === $Failed || ! NumericQ[value] || ! TrueQ[Im[value] == 0], Return[$Failed, Module]];
  power = Lookup[a, "Power", 1];
  If[power =!= 1,
   side = Which[a["ExpansionPoint"] === Infinity, 1, a["ExpansionPoint"] === -Infinity, -1,
     a["Direction"] === "FromBelow", -1, True, 1];
   endpoint = If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], 0, a["ExpansionPoint"]];
   value = N[endpoint + side Abs[value]^(1/power), wp]];
  If[NumericQ[value] && TrueQ[Im[value] == 0], Rationalize[Re[value], 0], $Failed]];

certRefinedSeed[a_, yv_, iteration_, wp_] := Module[{s, goal, x, y, options},
  x = a["Variables"][[1]]; y = a["Variable"];
  If[Lookup[a, "Kind", None] === "CoreInverse",
   s = Quiet[TimeConstrained[catch[AsymptoticInverse`AsymptoticCoreInverse[
       a["Core"], a["Perturbation"], {x, a["ExpansionPoint"]}, {y, a["MarkerDepth"] + iteration},
       "CoreInverse" -> a["CoreInverse"], Assumptions -> Lookup[a, "Assumptions", True],
       Direction -> a["Direction"], "InputRemainder" -> Lookup[a, "InputRemainder", None],
       "SourceRadius" -> Lookup[a["CoreCertificate"], "SourceRadius", 1/E],
       "CoreCheckTimeConstraint" -> 1]], 5, $Failed]];
   Return[If[MatchQ[s, _PowerLogSeries], certSeed[s[[1]], yv, wp], $Failed], Module]];
  goal = Max[2, Lookup[a, "ReturnedTermCount", 1] + 2 iteration];
  options = {Assumptions -> Lookup[a, "Assumptions", True], Direction -> a["Direction"],
    Method -> If[Lookup[a, "Method", "Lagrange"] === "Lambert", "Lagrange", a["Method"]],
    "Power" -> 1, SeriesTermGoal -> goal};
  s = Quiet[TimeConstrained[catch[AsymptoticInverse[a["Function"], {x, a["ExpansionPoint"]}, y,
      Sequence @@ options]], 5, $Failed]];
  If[MatchQ[s, _PowerLogSeries], certSeed[s[[1]], yv, wp], $Failed]];

certAttempt[a_, function_, target_, x_, interval_, center_, ctx_, route_, knownRoot_: False] := Module[
  {forward, derivative, derivativeExpression, residual, epsilon, mu, radius, bracket, correction, sharp, domain,
   leftResidual, rightResidual, endpointBracket = False},
  If[! certSourceInterval[a, interval, x, ctx],
   certFail["OutsideBranch", "The certificate interval is not proved to lie on the selected source side.",
    <|"Interval" -> interval, "ExpansionPoint" -> a["ExpansionPoint"], "Direction" -> a["Direction"]|>]];
  If[route === "LogarithmicPhase" && ! certPositiveCondition[a["SourceDomain"], x, interval, ctx],
   certFail["OutsideBranch", "The transformed source-domain condition is not proved on the whole interval.",
    <|"UnprovedCondition" -> a["SourceDomain"]|>]];
  (* Successful structural evaluation also proves continuity on this interval. *)
  forward = certEnclose[function, x, interval, ctx];
  derivativeExpression = D[function, x];
  derivative = certEnclose[derivativeExpression, x, interval, ctx];
  mu = Which[derivative[[1]] > 0, derivative[[1]], derivative[[2]] < 0, -derivative[[2]], True, 0];
  If[mu === 0, certFail["DerivativeNotSeparated", "The derivative enclosure is not separated from zero.",
    <|"DerivativeEnclosure" -> derivative, "Interval" -> interval|>]];
  residual = certEnclose[function - target, x, {center, center}, ctx];
  epsilon = Max[Abs[residual]];
  radius = epsilon/mu;
  bracket = {center - radius, center + radius};
  If[! knownRoot && (bracket[[1]] < interval[[1]] || bracket[[2]] > interval[[2]]),
   leftResidual = certEnclose[function - target, x, ConstantArray[interval[[1]], 2], ctx];
   rightResidual = certEnclose[function - target, x, ConstantArray[interval[[2]], 2], ctx];
   endpointBracket = If[derivative[[1]] > 0,
     leftResidual[[2]] <= 0 && rightResidual[[1]] >= 0,
     leftResidual[[1]] >= 0 && rightResidual[[2]] <= 0];
   If[! endpointBracket,
    certFail["ResidualBracketOutsideInterval", "Neither residual containment nor exact endpoint signs establish a root in the verification interval.",
     <|"ResidualEnclosure" -> residual, "DerivativeLowerBound" -> mu,
       "ProposedRootBracket" -> bracket, "Interval" -> interval,
       "DefinitiveNoRoot" -> ((leftResidual[[1]] > 0 && rightResidual[[1]] > 0) ||
         (leftResidual[[2]] < 0 && rightResidual[[2]] < 0)),
       "EndpointResidualEnclosures" -> {leftResidual, rightResidual}|>]]];
  (* The root now exists. Apply the mean-value identity once more with the
     full signed derivative enclosure to obtain a sharper root interval. *)
  correction = certMul[residual, certReciprocal[derivative, ctx], ctx];
  sharp = {Max[interval[[1]], bracket[[1]], center - correction[[2]]],
    Min[interval[[2]], bracket[[2]], center - correction[[1]]]};
  If[sharp[[1]] > sharp[[2]], certFail["CertificateInvariant", "The exact root enclosure became empty."]];
  <|"Certified" -> True, "RootEnclosure" -> sharp, "Center" -> center,
    "CertifiedErrorBound" -> radius,
    "CertifiedErrorLowerBound" -> If[residual[[1]] <= 0 <= residual[[2]], 0,
      Min[Abs[residual]]/Max[Abs[derivative]]], "ResidualEnclosure" -> residual,
    "ResidualAbsoluteBound" -> epsilon, "DerivativeEnclosure" -> derivative,
    "DerivativeLowerBound" -> mu, "DerivativeSign" -> If[derivative[[1]] > 0, 1, -1],
    "VerificationInterval" -> interval, "CertifiedFunction" -> function,
    "CertifiedTarget" -> target, "Route" -> route,
    "ExistenceEvidence" -> Which[knownRoot, "The preceding certificate enclosed a root in this interval",
      endpointBracket, "Exact endpoint signs and continuity", True, "Residual bracket containment"],
    "EndpointResidualEnclosures" -> If[endpointBracket, {leftResidual, rightResidual}, Missing["NotNeeded"]],
    "OriginalForwardFunction" -> a["Function"], "SeedKind" -> a["Kind"],
    "InputRemainder" -> Lookup[a, "InputRemainder", None],
    "FunctionScope" -> If[MemberQ[{None, Automatic}, Lookup[a, "InputRemainder", None]],
      "ExplicitFunction", "StoredExpressionOnly"],
    "CertifiesInputRemainderFamily" -> False,
    "Arithmetic" -> "Exact rational intervals with directed dyadic rounding and explicit exponential/logarithm series tails",
    "Scope" -> "A unique real root of the stored explicit Function in VerificationInterval, on the selected source side. Unspecified terms represented by InputRemainder are not enclosed, and no global inverse-branch certificate is asserted."|>];

Options[AsymptoticInverse`InverseCertificate] = {"Interval" -> Automatic, "Center" -> Automatic,
  "TargetError" -> Automatic, "RelativeError" -> Automatic, WorkingPrecision -> 50, "EnclosureOrder" -> Automatic,
  "MaxRefinements" -> 6, "RefineExpansion" -> True, "ExponentMagnitudeLimit" -> 10000};

AsymptoticInverse`InverseCertificate[PowerLogSeries[a_Association], yv_, opts : OptionsPattern[]] := catch[Module[
  {interval = OptionValue["Interval"], center = OptionValue["Center"], tolerance = OptionValue["TargetError"],
   relative = OptionValue["RelativeError"], lowerMagnitude, upperMagnitude, goalBound, floorBound, absoluteTolerance,
   wp = OptionValue[WorkingPrecision], order = OptionValue["EnclosureOrder"],
   maximum = OptionValue["MaxRefinements"], refine = OptionValue["RefineExpansion"],
   magnitude = OptionValue["ExponentMagnitudeLimit"], fixed, x, y, f, target, route, ctx,
   result, best = Missing["NotCertified"], iteration = 0, seed, history = {}, initial, digits, knownRoot = False,
   certificateModel = a, phaseData},
  If[! MemberQ[{"Inverse", "CoreInverse"}, Lookup[a, "Kind", None]],
   certFail["Unsupported", "Certificates require an inverse or exact-core inverse expansion."]];
  If[! exactQ[yv] || ! NumericQ[yv], certFail["InexactTarget", "The certificate target must be an exact numeric expression."]];
  If[! MatchQ[interval, {_?certRationalQ, _?certRationalQ}] || ! TrueQ[interval[[1]] < interval[[2]]],
   certFail["InvalidInterval", "Supply Interval -> {lo, hi} with ordered exact rational endpoints."]];
  If[! IntegerQ[wp] || wp < 10 || ! IntegerQ[maximum] || maximum < 0 ||
    ! MemberQ[{True, False}, refine] || ! IntegerQ[magnitude] || magnitude < 1,
   certFail["InvalidOption", "WorkingPrecision must be at least 10, MaxRefinements nonnegative, RefineExpansion Boolean, and ExponentMagnitudeLimit a positive integer."]];
  If[tolerance =!= Automatic && (! certRationalQ[tolerance] || ! TrueQ[tolerance > 0]),
   certFail["InvalidTolerance", "TargetError must be a positive exact rational number."]];
  If[relative =!= Automatic && (! certRationalQ[relative] || ! TrueQ[relative > 0]),
   certFail["InvalidTolerance", "RelativeError must be a positive exact rational number."]];
  If[order === Automatic,
   digits = If[tolerance === Automatic, 0,
     Max[0, IntegerLength[Denominator[tolerance]] - IntegerLength[Numerator[tolerance]]]];
   order = Max[wp + 10, digits + 15]];
  If[! IntegerQ[order] || order < 2 || order > 2000,
   certFail["InvalidOption", "EnclosureOrder must be an integer between 2 and 2000."]];
  x = a["Variables"][[1]]; y = a["Variable"]; f = a["Function"]; target = yv; route = "OriginalFunction";
  If[Lookup[a, "CoordinateKind", None] === "TargetLog",
   f = a["TransformedFunction"]; target = a["TargetCoordinateExpression"] /. y -> yv;
   route = "LogarithmicPhase"];
  If[route === "OriginalFunction" && Lookup[a, "LambertCoreType", None] === "Exponential",
   phaseData = catch[coordinateExponentialPhase[a["Function"], x, a["ExpansionPoint"], a["Direction"],
      Lookup[a, "Assumptions", True], 20000]];
   If[AssociationQ[phaseData],
    f = phaseData["Phase"];
    target = Log[phaseData["AmplitudeSign"] (yv - phaseData["Offset"])/phaseData["AmplitudeScale"]];
    certificateModel = Join[a, <|"SourceDomain" -> (phaseData["PositiveAmplitude"] > 0)|>];
    route = "LogarithmicPhase"]];
  fixed = center =!= Automatic;
  If[! fixed,
   center = certSeed[a, yv, wp];
   If[center === $Failed || ! TrueQ[interval[[1]] < center < interval[[2]]], center = Mean[interval]]];
  If[! certRationalQ[center] || ! TrueQ[interval[[1]] < center < interval[[2]]],
   certFail["InvalidCenter", "Center must be an exact rational strictly inside the certificate interval."]];
  initial = interval;
  While[True,
   ctx = <|"SeriesOrder" -> order, "Bits" -> 4 (order + 10), "ExponentMagnitudeLimit" -> magnitude|>;
   result = catch[certAttempt[certificateModel, f, target, x, interval, center, ctx, route, knownRoot]];
   If[AssociationQ[result], result = Join[result, <|"OriginalTarget" -> yv|>]];
   AppendTo[history, <|"Iteration" -> iteration, "EnclosureOrder" -> order, "Center" -> center,
      "Outcome" -> If[AssociationQ[result], "Certified", result[[1]]]|>];
   If[FailureQ[result] && TrueQ[Lookup[result[[2]], "DefinitiveNoRoot", False]],
    Return[Failure[result[[1]], Join[result[[2]], <|"History" -> history|>]], Module]];
   If[AssociationQ[result],
    lowerMagnitude = If[result["RootEnclosure"][[1]] <= 0 <= result["RootEnclosure"][[2]], 0,
      Min[Abs[result["RootEnclosure"]]]];
    upperMagnitude = Max[Abs[result["RootEnclosure"]]];
    absoluteTolerance = If[tolerance === Automatic, 0, tolerance];
    goalBound = If[relative === Automatic, If[tolerance === Automatic, Infinity, tolerance],
      Max[absoluteTolerance, relative lowerMagnitude]];
    floorBound = If[relative === Automatic, goalBound, Max[absoluteTolerance, relative upperMagnitude]];
    result = Join[result, <|"RelativeError" -> relative, "ProvedRootMagnitudeLowerBound" -> lowerMagnitude,
      "CertifiedRelativeErrorBound" -> If[lowerMagnitude > 0, result["CertifiedErrorBound"]/lowerMagnitude,
        Missing["RootNotSeparatedFromZero"]], "SufficientAbsoluteTolerance" -> goalBound|>];
    best = result;
    If[relative =!= Automatic && tolerance === Automatic && upperMagnitude === 0,
     certFail["RelativeAccuracyAtZero", "A relative accuracy request at a zero root requires an explicit positive TargetError absolute fallback.",
       <|"BestCertificate" -> result, "History" -> history|>]];
    If[result["CertifiedErrorBound"] <= goalBound,
     Return[Join[result, <|"OriginalTarget" -> yv, "TargetError" -> tolerance, "AccuracyGoalReached" -> True,
        "Refinements" -> iteration, "History" -> history|>], Module]];
    If[fixed && result["CertifiedErrorLowerBound"] > floorBound,
     certFail["AccuracyFloor", "The fixed center's certified error lower bound exceeds the requested absolute or relative tolerance.",
      <|"TargetError" -> tolerance, "RelativeError" -> relative, "BestCertificate" -> result, "History" -> history,
        "CenterWasFixed" -> True|>]]];
   If[iteration >= maximum, Break[]];
   iteration++;
   If[AssociationQ[result] && ! fixed,
    knownRoot = True;
    If[result["RootEnclosure"][[1]] < result["RootEnclosure"][[2]],
     interval = result["RootEnclosure"]; center = Mean[interval],
     center = First[result["RootEnclosure"]]; interval = initial];
    If[refine,
     seed = certRefinedSeed[a, yv, iteration, wp + 10 iteration];
     If[certRationalQ[seed] && TrueQ[interval[[1]] < seed < interval[[2]]], center = seed]],
    (* More precise enclosures can resolve dependency-free sign or residual
       tests. A fixed center is deliberately never silently replaced. *)
    order = Min[2000, 2 order]]];
  If[AssociationQ[best],
   certFail["AccuracyNotReached", "The requested error was not certified within the refinement budget.",
    <|"TargetError" -> tolerance, "BestCertificate" -> best, "History" -> history,
      "CenterWasFixed" -> fixed|>],
   If[FailureQ[result], Return[Failure[result[[1]], Join[result[[2]], <|"History" -> history|>]], Module]];
   certFail["CertificateFailure", "No residual certificate was established."]]]];

AsymptoticInverse`InverseCertificate[___] := Failure["InvalidArguments", <|"Certified" -> False,
  "MessageTemplate" -> "Use InverseCertificate[expansion, exactTarget, Interval -> {lo, hi}]."|>];
