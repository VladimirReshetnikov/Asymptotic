(* A power of an inverse-Gamma observable is another observable of the
   same source root. Replaying its exact defining equation determines the
   coefficients, while the operand's error still caps output precision. *)

gammaInverseSeriesPower[s : PowerLogSeries[a_Association], k_, cut_, limit_] := Module[
  {x, y, ass, oldPower, newPower, alpha, precision, propagated, requested,
   effective, sourceDomain, targetDomain, result, data, inverseLogDegree,
   resultPower, resultDegree, core, bounded, operation, direction, representation, coefficientLog, kind},
  If[! IntegerQ[limit] || limit < 1,
    fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[! exactRealQ[k],
    fail["InvalidPower", "A Gamma/Barnes inverse series power must be an exact real number."]];
  If[cut =!= Automatic && ! exactRealQ[cut],
    fail["InvalidCutoff", "A Gamma/Barnes inverse operation cutoff must be an exact real number or Automatic."]];
  {x, y} = a["Variables"]; ass = a["Assumptions"]; kind = a["Kind"];
  oldPower = a["Power"]; targetDomain = a["TargetDomain"];
  If[! exactRealQ[oldPower] || oldPower === 0,
    fail["InvalidGammaInverseObservable", "The operand must retain a nonzero exact real source power."]];
  If[a["ExpansionPoint"] =!= Infinity && ! IntegerQ[k],
    fail["UnsupportedPowerBranch", "A noninteger power of a Gamma/Barnes inverse observable requires a positive source branch; powers on a negative source branch are supported only for integer exponents."]];
  If[k === 0,
    direction = Which[a["Limit"] === Infinity || a["Limit"] === -Infinity, Automatic,
      provablyPositive[a["TargetScale"], ass], "FromAbove", True, "FromBelow"];
    result = forwardCore[1, y, a["Limit"], 1, Assumptions -> ass,
      Direction -> direction, "MaxTerms" -> limit];
    If[FailureQ[result], Return[result, Module]];
    representation = seriesData[result, limit];
    Return[PowerLogSeries[Join[result[[1]], <|"TargetDomain" -> targetDomain,
      "Function" -> ConditionalExpression[1, targetDomain],
      "SeriesRepresentation" -> Join[representation, <|"Domain" -> targetDomain && representation["Domain"]|>],
      (kind <> "Operation") -> <|"Operation" -> "Power", "Exponent" -> 0,
        "InputPower" -> oldPower, "OutputPower" -> 0,
        "PrecisionMeaning" -> "The constant observable is exact and independent of the operand remainder."|>|>]], Module]];
  If[! ListQ[a["Terms"]] || a["Terms"] === {},
    fail["UnknownLeadingTerm", "The Gamma/Barnes inverse operand must retain its leading source-power block before taking a nonzero power."]];
  alpha = First[a["Terms"]][[1]];
  If[! equal[alpha, -oldPower],
    fail["InvalidGammaInverseObservable", "The operand's leading core exponent must equal minus its retained source power."]];
  newPower = canon[oldPower k]; precision = a["RemainderPower"];
  If[! exactRealQ[precision] || ! less[alpha, precision],
    fail["InsufficientInputPrecision", "A Gamma/Barnes inverse power requires a remainder strictly smaller than the operand's leading block."]];
  propagated = canon[precision + alpha (k - 1)];
  requested = If[cut === Automatic, propagated, cut];
  effective = minOf[requested, propagated];
  If[! less[-newPower, effective],
    fail["InvalidCutoff", "The output core-power cutoff must exceed the powered observable's leading exponent."]];
  sourceDomain = inverseEvidenceSourceDomain[a, x];
  validateInput[{a["Function"], sourceDomain, newPower}, limit];
  result = With[{function = a["Function"], domain = sourceDomain, source = x,
      endpoint = a["ExpansionPoint"], target = y, cutoff = effective,
      power = newPower, assumptions = ass, direction = a["Direction"],
      method = Lookup[a, "RequestedMethod", "Lagrange"], budget = limit},
    AsymptoticInverse[ConditionalExpression[function, domain],
      {source, endpoint}, {target, cutoff}, "Power" -> power,
      Assumptions -> assumptions, Direction -> direction, Method -> method,
      "MaxTerms" -> budget]];
  If[FailureQ[result], Return[result, Module]];
  If[! MatchQ[result, PowerLogSeries[_Association]] || result["Kind"] =!= kind,
    fail["UnsupportedGammaInverseReplay", "The retained source equation did not reconstruct a Gamma/Barnes inverse observable."]];
  data = result[[1]]; core = data["CoreInverse"]; coefficientLog = data["CoreLogExpression"];
  inverseLogDegree = Lookup[a, "RemainderInverseLogPower", 0];
  resultPower = data["RemainderPower"];
  resultDegree = Lookup[data, "RemainderInverseLogPower", 0];
  (* A cancelled first omitted coefficient in the reconstructed exact source
     cannot improve the uncertainty inherited from the operand. At equal
     core powers, a smaller reciprocal-log power is the coarser bound. *)
  bounded = If[less[propagated, resultPower] ||
      (equal[propagated, resultPower] && less[inverseLogDegree, resultDegree]),
    <|"RemainderPower" -> propagated, "RemainderLogDegree" -> 0,
      "RemainderInverseLogPower" -> inverseLogDegree,
      "RemainderVariable" -> 1/core,
      "Remainder" -> PowerLogRemainder[1/core, propagated, 0]/coefficientLog^inverseLogDegree,
      "RemainderScaleExpression" -> core^(-propagated)/coefficientLog^inverseLogDegree|>, <||>];
  operation = <|"Operation" -> "Power", "Exponent" -> k,
    "InputPower" -> oldPower, "OutputPower" -> newPower,
    "OperandRemainderPower" -> precision,
    "PropagatedRemainderPower" -> propagated,
    "RequestedCutoff" -> cut, "EffectiveCutoff" -> effective,
    "CoefficientConstruction" -> "Replay of the retained exact source equation with its original source-domain condition.",
    "PrecisionMeaning" -> "For operand valuation alpha and error power P, the output error power is capped by P+alpha(Exponent-1). Source replay supplies coefficients only below the clipped cutoff; it does not improve inherited uncertainty. Later refinement may replay the exact source for additional information."|>;
  PowerLogSeries[Join[data, bounded, <|
    "TargetDomain" -> targetDomain && data["TargetDomain"],
    (kind <> "Operation") -> operation|>]]];
