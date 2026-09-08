(* Exact-core marker expansions with a proved asymptotic contract for finite
   power-log cores and higher-power perturbations. Loaded in Private`. *)

AsymptoticInverse`AsymptoticCoreInverse::usage =
"AsymptoticCoreInverse[core, perturbation, {x,x0}, {y,n}, \"CoreInverse\"->phi] expands the selected real inverse of core+perturbation through marker degree n while retaining the exact core inverse phi. Supported finite power-log data have a nonzero leading source power and perturbation exponents strictly larger than that leading power. Marker terms are not an exponent-sorted power-log jet; the result records a proved asymptotic remainder and a separate first omitted marker term. CoreInverse->Automatic recognizes monomial and affine-log-power cores.";

Options[AsymptoticInverse`AsymptoticCoreInverse] = {
  Assumptions -> True, Direction -> Automatic, "CoreInverse" -> Automatic,
  "InputRemainder" -> None, "MaxTerms" -> 20000,
  "CoreCheckTimeConstraint" -> 3, "SourceRadius" -> 1/E};

corePerturbationRealPolynomialQ[p_, ell_, ass_] := PolynomialQ[p, ell] &&
  And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@ CoefficientList[p, ell]);

corePerturbationModel[core_, perturbation_, x_, coord_, ell_, ass_] := Module[
  {u = coord["u"], f0, rr, rows, remainderRows, offset, nonconstant,
   p, q, a, polynomial, gaps, d, b, simple},
  f0 = Simplify[core /. x -> coord["Substitution"], ass && u > 0];
  rr = Simplify[perturbation /. x -> coord["Substitution"], ass && u > 0];
  rows = parseFinite[f0, u, ell, ass];
  remainderRows = parseFinite[rr, u, ell, ass];
  If[rows === $Failed || remainderRows === $Failed,
    fail["UnsupportedCorePerturbation", "The core and perturbation must be finite power-log expressions in the positive source coordinate."]];
  rows = jetMerge[rows, ell, ass]; remainderRows = jetMerge[remainderRows, ell, ass];
  If[! And @@ (exactRealQ[#[[1]]] && corePerturbationRealPolynomialQ[#[[2]], ell, ass] & /@ Join[rows, remainderRows]),
    fail["UnprovedCoreData", "Exponents must be exact real numbers and every coefficient must be provably real."]];
  offset = Total[Cases[rows, {0, c_} /; FreeQ[c, ell] :> c]];
  nonconstant = Select[rows, ! (#[[1]] === 0 && FreeQ[#[[2]], ell]) &];
  If[nonconstant === {}, fail["ConstantCore", "A constant core has no local inverse."]];
  {p, polynomial} = First[nonconstant];
  If[p === 0, fail["UnsupportedCorePerturbation", "A purely logarithmic leading core needs a separate error-transport contract."]];
  q = polyDegree[polynomial, ell]; a = Coefficient[polynomial, ell, q];
  If[! (provablyPositive[a, ass] || provablyNegative[a, ass]),
    fail["UnprovedSign", "The eventual core sign must be provable from its leading logarithmic coefficient."]];
  gaps = canon[#[[1]] - p] & /@ remainderRows;
  If[! And @@ (less[0, #] & /@ gaps),
    fail["NonSmallCorePerturbation", "Every perturbation exponent must be strictly larger than the core's leading source exponent."]];
  d = If[remainderRows === {}, 0, Max[0, Max[polyDegree[#[[2]], ell] & /@ remainderRows] - q]];
  b = If[q === 0, 0, Simplify[Coefficient[polynomial, ell, q - 1]/(q a), ass]];
  simple = Length[nonconstant] === 1 && polyZeroQ[polynomial - a (ell + b)^q, ell, ass];
  <|"CoreLocal" -> f0, "PerturbationLocal" -> rr, "CoreRows" -> rows,
    "PerturbationRows" -> remainderRows, "Offset" -> offset, "LeadingPower" -> p,
    "LeadingLogDegree" -> q, "LeadingCoefficient" -> a,
    "Amplitude" -> Simplify[a (-1)^q, ass], "AffineLogShift" -> b,
    "AutomaticCore" -> simple, "Gaps" -> gaps,
    "MinimumGap" -> If[gaps === {}, Infinity, Min[gaps]], "RelativeLogDegree" -> d|>];

corePerturbationAutomaticInverse[model_, coord_, y_, x0_, ass_] := Module[
  {p = model["LeadingPower"], q = model["LeadingLogDegree"], a = model["LeadingCoefficient"],
   amp = model["Amplitude"], b = model["AffineLogShift"], v, u0, k, branch, argument, phi},
  If[! TrueQ[model["AutomaticCore"]], Return[$Failed, Module]];
  v = y - model["Offset"];
  If[q === 0,
    u0 = (v/a)^(1/p); branch = Missing["Monomial"]; argument = Missing["Monomial"],
    k = -p/q; branch = If[less[0, k], 0, -1];
    argument = k (v/amp)^(1/q) Exp[p b/q];
    u0 = (v/amp)^(1/p) (ProductLog[branch, argument]/k)^(-q/p)];
  phi = If[coord["Infinite"], coord["Sign"]/u0, x0 + coord["Sign"] u0];
  <|"Inverse" -> phi, "LocalInverse" -> u0, "LambertBranch" -> branch,
    "LambertArgument" -> argument,
    "Certificate" -> <|"Type" -> "RecognizedExactCore", "CoreIdentity" -> True,
      "BranchConstruction" -> If[q === 0, "Positive monomial root", "Real Lambert branch with positive source coordinate tending to zero"]|>|>];

corePerturbationChooseInverse[model_, requested_, core_, x_, x0_, y_, coord_, ass_, radius_, seconds_] := Module[
  {automatic, phi, u0, u = coord["u"], identity, comparison, certificate, conditions},
  automatic = corePerturbationAutomaticInverse[model, coord, y, x0, ass];
  If[requested === Automatic,
    If[automatic === $Failed, fail["CoreInverseRequired", "Supply an exact CoreInverse for this core; automatic inversion currently recognizes a monomial or affine-log power."]];
    Return[automatic, Module]];
  If[! FreeQ[requested, x] || ! exactQ[requested] || ! FreeQ[requested, Indeterminate | _DirectedInfinity],
    fail["InvalidCoreInverse", "CoreInverse must be an exact finite expression in the target and parameters, independent of the source symbol."]];
  phi = requested;
  If[automatic =!= $Failed,
    comparison = Quiet[TimeConstrained[FullSimplify[phi == automatic["Inverse"],
      ass && (y - model["Offset"])/model["Amplitude"] > 0], seconds, $Failed]];
    If[TrueQ[comparison], Return[Join[automatic, <|"Inverse" -> phi,
      "LocalInverse" -> If[coord["Infinite"], coord["Sign"]/phi, coord["Sign"] (phi - x0)]|>], Module]]];
  conditions = ass && 0 < u < radius;
  identity = Quiet[TimeConstrained[FullSimplify[
    (phi /. y -> model["CoreLocal"]) == coord["Substitution"], conditions], seconds, $Failed]];
  If[! TrueQ[identity],
    fail["UnverifiedCoreInverse", "The supplied inverse could not be proved to recover the selected source branch under the stated source-radius assumptions.",
      <|"Identity" -> identity, "SourceAssumptions" -> conditions|>]];
  u0 = If[coord["Infinite"], coord["Sign"]/phi, coord["Sign"] (phi - x0)];
  certificate = <|"Type" -> "SymbolicLeftInverse", "CoreIdentity" -> True,
    "SourceAssumptions" -> conditions, "SourceRadius" -> radius,
    "CheckedIdentity" -> HoldForm[phi /. y -> model["CoreLocal"]]|>;
  <|"Inverse" -> phi, "LocalInverse" -> u0, "Certificate" -> certificate,
    "LambertBranch" -> Missing["UserCore"], "LambertArgument" -> Missing["UserCore"]|>];

corePerturbationTerm[n_, rlocal_, hprime_, fprime_, u_, limit_] := Module[{term, j},
  term = Together[hprime rlocal^n/fprime];
  Do[
    term = Together[D[term, u]/fprime];
    If[LeafCount[term] > limit, fail["ResourceLimit", "An exact-core derivative exceeded MaxTerms expression leaves."]],
    {j, 1, n - 1}];
  term = (-1)^n term/n!;
  If[LeafCount[term] > limit, fail["ResourceLimit", "An exact-core marker coefficient exceeded MaxTerms expression leaves."]];
  term];

corePerturbationConstruct[core_, perturbation_, x_, x0_, y_, depth_, opts : OptionsPattern[AsymptoticInverse`AsymptoticCoreInverse]] := Module[
  {ass = OptionValue[AsymptoticInverse`AsymptoticCoreInverse, {opts}, Assumptions],
   dir = OptionValue[AsymptoticInverse`AsymptoticCoreInverse, {opts}, Direction],
   requested = OptionValue[AsymptoticInverse`AsymptoticCoreInverse, {opts}, "CoreInverse"],
   input = OptionValue[AsymptoticInverse`AsymptoticCoreInverse, {opts}, "InputRemainder"],
   limit = OptionValue[AsymptoticInverse`AsymptoticCoreInverse, {opts}, "MaxTerms"],
   seconds = OptionValue[AsymptoticInverse`AsymptoticCoreInverse, {opts}, "CoreCheckTimeConstraint"],
   radius = OptionValue[AsymptoticInverse`AsymptoticCoreInverse, {opts}, "SourceRadius"],
   coord, u, ell = Unique["ell$"], model, inverse, phi, u0, fp, hp, localTerms, markerTerms,
   expression, firstOmitted, n, p, q, delta, degree, rint, pd, truncationPair,
   inputPair = None, rho, logdegree, domain, side, targetLimit, rem, scale,
   exactPerturbation, majorant, sourceAssumptions},
  validateInput[core + perturbation, limit];
  If[x === y || ! FreeQ[core + perturbation, y], fail["InvalidVariables", "Use distinct source and target symbols, with no target symbol in the forward data."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters; the source branch is specified by endpoint and direction."]];
  If[! IntegerQ[depth] || depth < 0, fail["InvalidDepth", "The marker depth must be a nonnegative integer."]];
  If[depth + 1 > limit, fail["ResourceLimit", "Marker depth and its first omitted coefficient exceed MaxTerms."]];
  If[! NumericQ[seconds] || ! TrueQ[seconds > 0] || ! exactRealQ[radius] || ! less[0, radius],
    fail["InvalidOption", "CoreCheckTimeConstraint and the exact real SourceRadius must be positive."]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"];
  model = corePerturbationModel[core, perturbation, x, coord, ell, ass];
  inverse = corePerturbationChooseInverse[model, requested, core, x, x0, y, coord, ass, radius, seconds];
  phi = inverse["Inverse"]; u0 = inverse["LocalInverse"];
  {p, q, delta, degree} = Lookup[model, {"LeadingPower", "LeadingLogDegree", "MinimumGap", "RelativeLogDegree"}];
  rint = If[coord["Infinite"], -1, 1];
  exactPerturbation = model["PerturbationRows"] === {};
  fp = D[model["CoreLocal"], u]; hp = D[coord["Substitution"], u];
  localTerms = If[exactPerturbation, {}, Table[
    {n, corePerturbationTerm[n, model["PerturbationLocal"], hp, fp, u, limit]}, {n, 1, depth + 1}]];
  markerTerms = Join[{{0, phi}}, ({#[[1]], #[[2]] /. u -> u0} & /@ Take[localTerms, UpTo[depth]])];
  expression = Total[markerTerms[[All, 2]]];
  firstOmitted = If[exactPerturbation, 0, localTerms[[-1, 2]] /. u -> u0];
  truncationPair = If[exactPerturbation, {Infinity, 0},
    {canon[rint + (depth + 1) delta], (depth + 1) degree}];
  pd = truncationPair;
  If[! MemberQ[{None, Automatic}, input],
    If[! MatchQ[input, {_, _Integer?NonNegative}] || ! exactRealQ[input[[1]]] || ! less[p, input[[1]]],
      fail["InvalidInputRemainder", "InputRemainder must be {rho,k}, with exact real rho larger than the core leading power and nonnegative integer k; a matching derivative bound is required."]];
    {rho, logdegree} = input;
    inputPair = {canon[rint + rho - p], Max[0, logdegree - q]};
    pd = combinePrecision[pd, inputPair]];
  side = If[provablyPositive[model["Amplitude"], ass], 1, -1];
  targetLimit = If[less[0, p], model["Offset"], side Infinity];
  domain = ass && (y - model["Offset"])/model["Amplitude"] > 0 &&
    Element[u0, Reals] && 0 < u0 < radius;
  If[inverse["LambertBranch"] === -1,
    domain = domain && -1/E <= inverse["LambertArgument"] < 0];
  rem = If[pd[[1]] === Infinity, 0, PowerLogRemainder[u0, pd[[1]], pd[[2]]]];
  scale = If[rem === 0, 0, u0^pd[[1]] (1 + Abs[Log[u0]])^pd[[2]]];
  majorant = <|"Type" -> "AsymptoticExistence", "NumericCertificate" -> False,
    "RelativeSmallScale" -> If[exactPerturbation, 0, u0^delta (1 + Abs[Log[u0]])^degree],
    "Statement" -> "For fixed data there are C,K>0 and a source threshold such that the omitted marker tail is bounded by C u0^rint (K chi)^(n+1)/(1-K chi) whenever K chi<1. The constants and threshold are not computed numerical bounds.",
    "LocalObservablePower" -> rint, "MarkerDepth" -> depth,
    "Justification" -> "Joint analytic implicit function theorem in reciprocal logarithm, fixed core parameters and finite higher-power perturbation parameters."|>;
  sourceAssumptions = ass && 0 < u < radius;
  PowerLogSeries[<|"Kind" -> "CoreInverse", "Scale" -> "ExactCorePerturbation",
    "Expression" -> expression, "Variable" -> y, "Variables" -> {x, y},
    "Function" -> core + perturbation, "Core" -> core, "Perturbation" -> perturbation,
    "CoreInverse" -> phi, "CoreLocalInverse" -> u0, "CoreCertificate" -> inverse["Certificate"],
    "CoreModel" -> model, "MarkerTerms" -> markerTerms, "Terms" -> markerTerms,
    "LocalMarkerTerms" -> localTerms, "FirstOmittedMarkerTerm" -> firstOmitted,
    "FirstOmittedMarkerDegree" -> depth + 1, "MarkerDepth" -> depth,
    "TermConvention" -> "Each {n,c} is one complete coefficient of the perturbation marker lambda^n, evaluated at lambda=1; these coefficients are not exponent-sorted power-log blocks.",
    "Remainder" -> rem, "RemainderScaleExpression" -> scale,
    "RemainderVariable" -> u0, "RemainderPower" -> pd[[1]], "RemainderLogDegree" -> pd[[2]],
    "TruncationRemainderPair" -> truncationPair, "InputRemainderPair" -> inputPair,
    "InputRemainder" -> input, "MajorantContract" -> majorant,
    "RemainderExplanation" -> "The analytic marker majorant bounds the complete omitted tail independently of cancellation in the first omitted coefficient. A declared input remainder is separately transported and may coarsen the bound.",
    "ExpansionPoint" -> x0, "Direction" -> coord["Direction"], "LocalVariable" -> u,
    "LocalSubstitution" -> (x -> coord["Substitution"]), "Limit" -> targetLimit,
    "TargetDomain" -> domain, "SourceAssumptions" -> sourceAssumptions,
    "Assumptions" -> ass, "LeadingPower" -> p, "LeadingCoefficient" -> model["Amplitude"],
    "ExactModel" -> MemberQ[{None, Automatic}, input], "ExactInverse" -> (rem === 0),
    "Truncation" -> "Depth", "Power" -> 1, "Cutoff" -> Missing["MarkerDepth"],
    "SeriesData" -> Missing["ExactCoreMarkerScale"],
    "RemainderDerivativeOrder" -> 0|>]];

AsymptoticInverse`AsymptoticCoreInverse[core_, perturbation_, {x_Symbol, x0_}, {y_Symbol, depth_},
  opts : OptionsPattern[]] := catch[corePerturbationConstruct[core, perturbation, x, x0, y, depth, opts]];
AsymptoticInverse`AsymptoticCoreInverse[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use AsymptoticCoreInverse[core, perturbation, {x,x0}, {y,depth}, CoreInverse->phi], with CoreInverse written as a string option."|>];
