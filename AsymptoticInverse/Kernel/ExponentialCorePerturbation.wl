(* Exact growing exponential cores with finite power-log perturbations.
   Loaded in Private`.  Exact Lambert/elementary cores remain unexpanded. *)

AsymptoticInverse`AsymptoticExponentialCoreInverse::usage =
"AsymptoticExponentialCoreInverse[core,perturbation,{x,x0},{y,n}] retains the exact inverse of a growing exponential core a v^b Exp[c v^p]+offset, c,p>0, and computes complete corrections through exponential degree n for a finite power-log perturbation. The positive v tends to Infinity. At source infinities SourceShift may translate v; finite endpoints use reciprocal source distance. InputRemainder->{rho,k} declares O(v^-rho (1+Log[v])^k) with matching derivative control and is transported as a separate first-sector error.";
Options[AsymptoticInverse`AsymptoticExponentialCoreInverse] = {
  Assumptions -> True, Direction -> Automatic, "SourceShift" -> Automatic,
  "CoreInverse" -> Automatic, "CoreCheckTimeConstraint" -> 3,
  "InputRemainder" -> None, "MaxTerms" -> 20000};

exponentialCoreShifts[core_, x_, ass_] := Module[{candidates},
  candidates = Cases[core, e_Plus /; PolynomialQ[e, x] && Exponent[e, x] === 1 :>
    Simplify[-Coefficient[e, x, 0]/Coefficient[e, x, 1], ass], {0, Infinity}];
  DeleteDuplicates[Prepend[Select[candidates, FreeQ[#, x] && TrueQ[Simplify[Element[#, Reals], ass]] &], 0]]];

exponentialCoreCoordinates[core_, x_, endpoint_, direction_, shift_, ass_] := Module[
  {coord, v = Unique["exponentialCoreSource$"], shifts, source, normalized, parsed, selected},
  coord = localCoordinate[x, endpoint, direction];
  If[coord["Infinite"],
    shifts = If[shift === Automatic, exponentialCoreShifts[core, x, ass], {shift}];
    If[! And @@ (exactQ[#] && FreeQ[#, x] && TrueQ[Simplify[Element[#, Reals], ass]] & /@ shifts),
      fail["InvalidSourceShift", "SourceShift must be an exact provably real parameter independent of the source."]];
    selected = $Failed;
    Do[
      source = candidate + coord["Sign"] v;
      normalized = Simplify[core /. x -> source, ass && v > 0];
      parsed = lambertExponentialCore[normalized, v, ass];
      If[AssociationQ[parsed] && TrueQ[parsed["Exact"]] && provablyPositive[parsed["c"], ass],
        selected = <|"Variable" -> v, "Reconstruction" -> source, "SourceShift" -> candidate,
          "CoreLocal" -> normalized, "CoreParameters" -> parsed,
          "Direction" -> coord["Direction"], "Sign" -> coord["Sign"], "ObservablePower" -> 1,
          "InfiniteSource" -> True|>; Break[]], {candidate, shifts}];
    selected,
    If[shift =!= Automatic && shift =!= 0, fail["UnsupportedSourceShift", "At a finite source endpoint the endpoint itself fixes the source distance."]];
    source = endpoint + coord["Sign"]/v;
    normalized = Simplify[core /. x -> source, ass && v > 0];
    parsed = lambertExponentialCore[normalized, v, ass];
    If[! AssociationQ[parsed] || ! TrueQ[parsed["Exact"]] || ! provablyPositive[parsed["c"], ass], Return[$Failed, Module]];
    <|"Variable" -> v, "Reconstruction" -> source, "SourceShift" -> endpoint,
      "CoreLocal" -> normalized, "CoreParameters" -> parsed, "Direction" -> coord["Direction"],
      "Sign" -> coord["Sign"], "ObservablePower" -> -1, "InfiniteSource" -> False|>]];

exponentialCoreExactInverse[coordinates_, y_, requested_, ass_, seconds_] := Module[
  {parameters = coordinates["CoreParameters"], a, b, c, p, offset, positiveTarget,
   v0, argument, branch, exactSource, base, domain, equality},
  {a, b, c, p, offset} = Lookup[parameters, {"a", "b", "c", "p", "Offset"}];
  If[! And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@ {a, c, offset}) ||
     ! (provablyPositive[a, ass] || provablyNegative[a, ass]),
    fail["UnprovedExponentialCoreData", "The core amplitude and offset must be provably real, and the amplitude must have a provable nonzero sign."]];
  positiveTarget = (y - offset)/a;
  If[b === 0,
    v0 = (Log[positiveTarget]/c)^(1/p); branch = Missing["Elementary"];
    argument = Missing["Elementary"]; domain = positiveTarget > 1,
    argument = (c p/b) positiveTarget^(p/b);
    branch = If[less[0, b], 0, -1];
    base = (b/(c p)) ProductLog[branch, argument];
    v0 = base^(1/p); domain = positiveTarget > 0 && base > 0;
    If[branch === -1, domain = domain && -1/E < argument < 0]];
  domain = ass && domain && Element[v0, Reals] && v0 > 1 && b + c p v0^p > 0;
  exactSource = coordinates["Reconstruction"] /. coordinates["Variable"] -> v0;
  If[requested =!= Automatic,
    If[! exactQ[requested] || ! FreeQ[requested, coordinates["Variable"] | Indeterminate | _DirectedInfinity],
      fail["InvalidCoreInverse", "CoreInverse must be a finite exact target expression."]];
    equality = Quiet[TimeConstrained[FullSimplify[requested == exactSource, domain], seconds, $Failed]];
    If[! TrueQ[equality], fail["UnverifiedCoreInverse", "The supplied expression could not be proved equal to the selected exact exponential-core inverse."]];
    exactSource = requested];
  <|"LocalInverse" -> v0, "SourceInverse" -> exactSource, "PositiveTarget" -> positiveTarget,
    "TargetDomain" -> domain, "LambertBranch" -> branch, "LambertArgument" -> argument,
    "Certificate" -> <|"Type" -> "RecognizedExactGrowingExponentialCore",
      "Identity" -> True, "Branch" -> branch,
      "Statement" -> "The positive local inverse tends to Infinity on the eventually monotone branch of a v^b Exp[c v^p], c,p>0."|>|>];

exponentialCoreCoefficient[n_, perturbation_, hprime_, denominator_, v_, c_, p_, ass_, limit_] := Module[{q, j},
  q = Together[hprime perturbation^n/denominator];
  Do[
    q = Together[(D[q, v] - j c p v^(p - 1) q)/denominator];
    If[LeafCount[q] > limit, fail["ResourceLimit", "An exponential-core coefficient derivative exceeded MaxTerms leaves."]],
    {j, 1, n - 1}];
  q = Simplify[(-1)^n q/n!, ass && v > 0];
  If[LeafCount[q] > limit, fail["ResourceLimit", "An exponential-core coefficient exceeded MaxTerms leaves."]]; q];

exponentialCoreConstruct[core_, perturbation_, x_, endpoint_, y_, depth_, opts : OptionsPattern[AsymptoticInverse`AsymptoticExponentialCoreInverse]] := Module[
  {ass = OptionValue[AsymptoticInverse`AsymptoticExponentialCoreInverse, {opts}, Assumptions],
   direction = OptionValue[AsymptoticInverse`AsymptoticExponentialCoreInverse, {opts}, Direction],
   shift = OptionValue[AsymptoticInverse`AsymptoticExponentialCoreInverse, {opts}, "SourceShift"],
   requested = OptionValue[AsymptoticInverse`AsymptoticExponentialCoreInverse, {opts}, "CoreInverse"],
   seconds = OptionValue[AsymptoticInverse`AsymptoticExponentialCoreInverse, {opts}, "CoreCheckTimeConstraint"],
   input = OptionValue[AsymptoticInverse`AsymptoticExponentialCoreInverse, {opts}, "InputRemainder"],
   limit = OptionValue[AsymptoticInverse`AsymptoticExponentialCoreInverse, {opts}, "MaxTerms"],
   coordinates, parameters, v, ell = Unique["ell$"], localPerturbation, rows,
   a, b, c, p, offset, inverse, v0, exactSource, denominator, hprime, localCoefficients,
   coefficients, sectors, exponential, targetSector, expression, d, k, rint, envelope,
   sectorRemainder, sectorScale, inputRemainder = 0, inputScale = 0, inputContract = None,
   rho, logdegree, remainder, coefficientList, exact, targetLimit},
  validateInput[{core, perturbation}, limit];
  If[x === y || ! FreeQ[{core, perturbation}, y] || ! FreeQ[ass, x | y] || ! FreeQ[{shift, requested}, x],
    fail["InvalidVariables", "Use distinct source and target symbols, parameter-only assumptions, and a source-independent CoreInverse and SourceShift."]];
  If[! IntegerQ[depth] || depth < 0, fail["InvalidDepth", "Exponential sector depth must be a nonnegative integer."]];
  If[depth + 1 > limit, fail["ResourceLimit", "The requested depth and first omitted coefficient exceed MaxTerms."]];
  If[! NumericQ[seconds] || ! TrueQ[seconds > 0], fail["InvalidOption", "CoreCheckTimeConstraint must be positive."]];
  coordinates = exponentialCoreCoordinates[core, x, endpoint, direction, shift, ass];
  If[coordinates === $Failed, fail["UnsupportedExponentialCore", "The selected source chart must expose an exact growing core a v^b Exp[c v^p]+offset with c,p>0; additional core terms are not silently truncated."]];
  v = coordinates["Variable"]; parameters = coordinates["CoreParameters"];
  {a, b, c, p, offset} = Lookup[parameters, {"a", "b", "c", "p", "Offset"}];
  localPerturbation = Simplify[perturbation /. x -> coordinates["Reconstruction"], ass && v > 0];
  rows = parseFinite[localPerturbation, v, ell, ass];
  If[rows === $Failed, fail["UnsupportedExponentialPerturbation", "The perturbation must be a finite power-log expression in the positive divergent core coordinate."]];
  rows = jetMerge[rows, ell, ass];
  If[! And @@ (exactRealQ[#[[1]]] && corePerturbationRealPolynomialQ[#[[2]], ell, ass] & /@ rows),
    fail["UnprovedPerturbationData", "Perturbation exponents must be exact real constants and all logarithmic coefficients must be provably real."]];
  inverse = exponentialCoreExactInverse[coordinates, y, requested, ass, seconds];
  v0 = inverse["LocalInverse"]; exactSource = inverse["SourceInverse"];
  denominator = a v^(b - 1) (b + c p v^p); hprime = D[coordinates["Reconstruction"], v];
  exact = rows === {};
  localCoefficients = If[exact, {}, Table[{n,
    exponentialCoreCoefficient[n, localPerturbation, hprime, denominator, v, c, p, ass, limit]}, {n, 1, depth + 1}]];
  coefficients = localCoefficients /. v -> v0; sectors = Take[coefficients, UpTo[depth]];
  exponential = Exp[-c v0^p]; targetSector = v0^b/inverse["PositiveTarget"];
  expression = exactSource + Total[(#[[2]] targetSector^#[[1]]) & /@ sectors];
  rint = coordinates["ObservablePower"];
  d = If[exact, 0, Max[0, Max[#[[1]] - b & /@ rows]]];
  k = If[exact, 0, Max[polyDegree[#[[2]], ell] & /@ rows]];
  envelope = v0^d (1 + Abs[Log[v0]])^k;
  sectorRemainder = If[exact, 0, targetSector^(depth + 1)
    PowerLogRemainder[1/v0, canon[p - rint - (depth + 1) d], (depth + 1) k]];
  sectorScale = If[exact, 0, targetSector^(depth + 1)
    v0^(rint - p + (depth + 1) d) (1 + Abs[Log[v0]])^((depth + 1) k)];
  If[! MemberQ[{None, Automatic}, input],
    If[! MatchQ[input, {_, _Integer?NonNegative}] || ! exactRealQ[input[[1]]],
      fail["InvalidInputRemainder", "InputRemainder must be {rho,k}: O(v^-rho M(v)^k) with matching derivative O(v^-rho-1 M(v)^k)."]];
    {rho, logdegree} = input;
    inputRemainder = targetSector PowerLogRemainder[1/v0, canon[b + p + rho - rint], logdegree];
    inputScale = targetSector v0^(rint - b - p - rho) (1 + Abs[Log[v0]])^logdegree;
    inputContract = <|"ForwardPair" -> {rho, logdegree}, "DerivativePair" -> {rho + 1, logdegree},
      "Coordinate" -> 1/v, "InverseSector" -> 1,
      "Statement" -> "A declared unknown polynomial-scale forward error induces a first-exponential-sector inverse error. This accuracy ceiling is independent of the retained model's sector depth."|>];
  remainder = sectorRemainder + inputRemainder;
  targetLimit = If[provablyPositive[a, ass], Infinity, -Infinity];
  PowerLogSeries[<|"Kind" -> "ExponentialCoreInverse", "Scale" -> "ExactExponentialCoreSectors",
    "Expression" -> expression, "Remainder" -> remainder, "RemainderScaleExpression" -> sectorScale + inputScale,
    "Core" -> core, "Perturbation" -> perturbation, "Function" -> core + perturbation,
    "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> endpoint, "Direction" -> coordinates["Direction"],
    "SourceShift" -> coordinates["SourceShift"], "SourceCoordinate" -> coordinates,
    "LocalVariable" -> v, "LocalSubstitution" -> (x -> coordinates["Reconstruction"]),
    "CoreInverse" -> exactSource, "CoreLocalInverse" -> v0, "CoreParameters" -> parameters,
    "CoreCertificate" -> inverse["Certificate"], "LambertBranch" -> inverse["LambertBranch"],
    "LambertArgument" -> inverse["LambertArgument"], "Limit" -> targetLimit,
    "TargetDomain" -> inverse["TargetDomain"], "Assumptions" -> ass,
    "ExactExponentialScale" -> exponential, "SectorVariable" -> targetSector,
    "SectorVariableIdentity" -> "Exp[-c v0^p] = v0^b/((y-offset)/a), by the exact core inverse identity.",
    "Sectors" -> sectors, "Terms" -> Join[{{0, exactSource}}, sectors],
    "LocalSectorCoefficients" -> localCoefficients, "SectorDepth" -> depth,
    "FirstOmittedSector" -> If[exact, {depth + 1, 0}, Last[coefficients]],
    "TermConvention" -> "The zero term is the exact selected core inverse. Each {n,Cn}, n>=1, contributes Cn SectorVariable^n; coefficients retain the exact core inverse and sector depth is inclusive.",
    "SectorRemainder" -> sectorRemainder, "SectorRemainderScale" -> sectorScale,
    "InputRemainder" -> input, "InputRemainderContract" -> inputContract,
    "InputRemainderTerm" -> inputRemainder, "InputRemainderScale" -> inputScale,
    "MajorantContract" -> <|"Type" -> "AsymptoticExistence", "NumericCertificate" -> False,
      "Envelope" -> envelope, "SmallScale" -> envelope targetSector,
      "ObservableScale" -> v0^(rint - p), "EnvelopePower" -> d, "EnvelopeLogDegree" -> k,
      "Statement" -> "For fixed data, the complete omitted model tail is at most C v0^(rint-p) (K chi)^(N+1)/(1-K chi), chi=v0^d M(v0)^k Exp[-c v0^p], sufficiently near the endpoint. Constants and threshold are existential."|>,
    "RemainderExplanation" -> "The model's complete sector tail is bounded independently of its first omitted coefficient. A declared unknown input error is transported separately and can dominate every additional retained model sector.",
    "ExactModel" -> MemberQ[{None, Automatic}, input], "ExactInverse" -> (remainder === 0),
    "Power" -> 1, "Truncation" -> "ExponentialSectorDepth", "SeriesData" -> Missing["ExactExponentialCoreScale"],
    "RemainderDerivativeOrder" -> 0|>]];

AsymptoticInverse`AsymptoticExponentialCoreInverse[core_, perturbation_, {x_Symbol, endpoint_}, {y_Symbol, depth_}, opts : OptionsPattern[]] :=
  catch[exponentialCoreConstruct[core, perturbation, x, endpoint, y, depth, opts]];
AsymptoticInverse`AsymptoticExponentialCoreInverse[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use AsymptoticExponentialCoreInverse[core,perturbation,{x,endpoint},{y,depth}]."|>];
