(* Real special-function adapters with explicit forward-model provenance.
   Finite Poincare models are never labelled convergent exact forward data. *)

AsymptoticAnalysis`AsymptoticSpecialInverse::usage =
"AsymptoticSpecialInverse[family,{x,x0},{y,cutoff}] supports Erfc, LogGamma, Gamma, LambertThreshold and QuadraticThreshold. Erfc uses a power cutoff in its logarithmic target coordinate; gamma adapters use an integer exact-core marker depth; threshold adapters use a local target-power cutoff. ModelTerms controls the finite asymptotic forward model. TargetOffset and TargetScale apply an exact real affine change of target.";
AsymptoticAnalysis`SpecialInverseNumericalCheck::usage =
"SpecialInverseNumericalCheck[result,target] compares an adapter with the original special-function equation at high precision, using logarithmic equations for gamma and erfc tails. This is numerical evidence, not an interval certificate.";

Options[AsymptoticAnalysis`AsymptoticSpecialInverse] = {
  Assumptions :> $Assumptions, Direction -> Automatic, "ModelTerms" -> Automatic,
  "TargetOffset" -> 0, "TargetScale" -> 1, "QuadraticCoefficient" -> 1,
  "LambertBranch" -> Automatic, "MaxTerms" -> 20000};
Options[AsymptoticAnalysis`SpecialInverseNumericalCheck] = {WorkingPrecision -> 60};

specialModelTerms[requested_, default_, limit_] := Module[{m = If[requested === Automatic, default, requested]},
  If[! IntegerQ[m] || m < 1, fail["InvalidModelTerms", "ModelTerms must be a positive integer or Automatic."]];
  If[m > limit, fail["ResourceLimit", "The special-function forward model exceeds MaxTerms."]]; m];

specialErfc[fam_, x_, endpoint_, y_, cutoff_, ass_, direction_, modelTerms_, offset_, scale_, limit_] := Module[
  {m, v = Unique["erfcTarget$"], z = Unique["erfcSource$"], w = Unique["erfcPower$"],
   s, polynomial, phase, inner, target, positiveTail, sign, alpha, delta,
   exactPhase, forwardBound, derivativeBound, phaseBound, phaseDerivativeBound,
   expression, remainder, tailScale, domain, original, innerData, terms, tailModel, representation},
  If[! MemberQ[{Infinity, -Infinity}, endpoint], fail["UnsupportedEndpoint", "The Erfc tail adapter requires a source infinity."]];
  localCoordinate[x, endpoint, direction];
  If[! exactRealQ[cutoff] || ! less[0, cutoff], fail["InvalidCutoff", "The Erfc logarithmic-target cutoff must be a positive exact real number."]];
  m = specialModelTerms[modelTerms, Max[1, Ceiling[cutoff + 1/2]], limit];
  If[less[m + 1/2, cutoff], fail["InsufficientModelOrder", "The Erfc model transports inverse precision only through ModelTerms+1/2.", <|"MaximumCutoff" -> m + 1/2|>]];
  s = Sum[(-1)^k Pochhammer[1/2, k] w^k, {k, 0, m - 1}];
  polynomial = Expand[Normal[Series[-Log[s], {w, 0, m - 1}]]];
  phase = z^2 + Log[z] + (polynomial /. w -> z^-2);
  inner = construct[phase, z, Infinity, v, cutoff, Assumptions -> ass,
    "InputRemainder" -> {2 m, 0}, "MaxTerms" -> limit];
  If[FailureQ[inner], Return[inner, Module]];
  sign = If[endpoint === Infinity, 1, -1];
  positiveTail = If[sign === 1, (y - offset)/scale, 2 - (y - offset)/scale];
  target = -Log[Sqrt[Pi] positiveTail];
  innerData = inner[[1]] /. v -> target;
  expression = sign innerData["Expression"]; remainder = innerData["Remainder"];
  tailScale = remainder /. rr_PowerLogRemainder :> remainderScale[rr];
  alpha = Pochhammer[1/2, m]; delta = alpha z^(-2 m); s = s /. w -> z^-2;
  forwardBound = Exp[-z^2] delta/(Sqrt[Pi] z);
  derivativeBound = 2 m alpha z^(-2 m - 1);
  exactPhase = z^2 + Log[z] - Log[s];
  phaseBound = delta/(s - delta) + Abs[exactPhase - phase];
  phaseDerivativeBound = derivativeBound/(s - delta) + Abs[D[s, z]] delta/(s (s - delta)) + Abs[D[exactPhase - phase, z]];
  domain = ass && 0 < positiveTail < 1 && target > 1;
  original = offset + scale Erfc[x];
  tailModel = Exp[-z^2] s/(Sqrt[Pi] z);
  terms = ({#[[1]], sign #[[2]]} & /@ innerData["Terms"]);
  representation = seriesData[inner, limit] /. v -> target;
  representation = Join[representation, <|"Variable" -> y, "Domain" -> domain,
    "Prefactor" -> sign representation["Prefactor"], "Offset" -> sign representation["Offset"]|>];
  GeneralizedSeries[Join[innerData, <|"Kind" -> "SpecialInverse", "Scale" -> "SpecialFunction",
    "Adapter" -> "Erfc", "Expression" -> expression, "Terms" -> terms,
    "SeriesRepresentation" -> representation,
    "Remainder" -> remainder, "RemainderScaleExpression" -> tailScale,
    "Function" -> original, "Variable" -> y, "Variables" -> {x, y},
    "ExpansionPoint" -> endpoint, "Direction" -> If[sign === 1, "FromBelow", "FromAbove"],
    "Limit" -> If[sign === 1, offset, offset + 2 scale], "TargetDomain" -> domain,
    "TargetOffset" -> offset, "TargetScale" -> scale, "TargetCoordinateExpression" -> target,
    "PositiveTailExpression" -> positiveTail, "SourceSign" -> sign,
    "SourceDomain" -> sign x > 0, "CoordinateSeries" -> inner,
    "CoordinateSubstitution" -> {v -> target}, "CoordinateSourceSign" -> sign,
    "TransformedFunction" -> (phase /. z -> sign x),
    "ExactTransformedFunction" -> -Log[Sqrt[Pi] Erfc[sign x]],
    "ForwardModel" -> (offset + scale If[sign === 1, tailModel, 2 - tailModel] /. z -> sign x),
    "NormalizedTailPolynomial" -> (s /. z -> sign x), "ModelTerms" -> m,
    "ForwardRemainderBound" -> (Abs[scale] forwardBound /. z -> sign x),
    "NormalizedTailRemainderBound" -> (delta /. z -> sign x),
    "NormalizedTailDerivativeRemainderBound" -> (derivativeBound /. z -> sign x),
    "PhaseRemainderBound" -> (phaseBound /. z -> sign x),
    "PhaseDerivativeRemainderBound" -> (phaseDerivativeBound /. z -> sign x),
    "ForwardBoundConditions" -> sign x > 0,
    "PhaseBoundConditions" -> (z > 0 && s > delta /. z -> sign x),
    "ForwardRemainderContract" -> <|"Type" -> "PoincareWithFirstNeglectedTermBound", "ConvergentForwardSeries" -> False,
      "PhaseAsymptoticPair" -> {2 m, 0}, "MatchingDerivativePair" -> {2 m + 1, 0},
      "Reference" -> "https://dlmf.nist.gov/7.12.i",
      "BoundMeaning" -> "For positive source magnitude the erfc remainder is bounded by the first neglected term. Phase bounds additionally require the finite normalized polynomial to exceed that error bound."|>,
    "ExactModel" -> False, "InputRemainder" -> {2 m, 0},
    "AccuracyFloor" -> <|"Coordinate" -> 1/target, "Power" -> m + 1/2|>,
    "TermConvention" -> "An ordinary inverse expansion in v=-Log[Sqrt[Pi] positiveTail], composed with its exact target transformation; cutoff is exclusive in the positive coordinate 1/v.",
    "SeriesData" -> Missing["SpecialFunctionTargetCoordinate"],
    "SwitchingContract" -> "Explicit tail adapter. No automatic numerical crossover threshold is asserted."|>]]];

specialGamma[fam_, x_, endpoint_, y_, depth_, ass_, direction_, modelTerms_, offset_, scale_, limit_] := Module[
  {m, v = Unique["gammaTarget$"], core, perturbation, inner, data, target, alpha, rho, original, domain},
  If[endpoint =!= Infinity, fail["UnsupportedEndpoint", "Gamma adapters currently use the increasing positive branch at +Infinity."]];
  localCoordinate[x, endpoint, direction];
  If[! IntegerQ[depth] || depth < 0, fail["InvalidDepth", "Gamma adapters use a nonnegative integer exact-core marker depth."]];
  m = specialModelTerms[modelTerms, Max[1, Ceiling[(depth + 1)/2]], limit];
  core = x (Log[x] - 1);
  perturbation = -Log[x]/2 + Log[2 Pi]/2 + Sum[BernoulliB[2 k]/(2 k (2 k - 1) x^(2 k - 1)), {k, 1, m - 1}];
  rho = 2 m - 1; alpha = Abs[BernoulliB[2 m]]/(2 m (2 m - 1));
  inner = AsymptoticAnalysis`AsymptoticCoreInverse[core, perturbation, {x, Infinity}, {v, depth},
    Assumptions -> ass, "InputRemainder" -> {rho, 0}, "MaxTerms" -> limit];
  If[FailureQ[inner], Return[inner, Module]];
  target = If[fam === "Gamma", Log[(y - offset)/scale], (y - offset)/scale];
  data = inner[[1]] /. v -> target;
  original = offset + scale If[fam === "Gamma", Gamma[x], LogGamma[x]];
  domain = ass && If[fam === "Gamma", (y - offset)/scale > 1, (y - offset)/scale > 0];
  GeneralizedSeries[Join[data, <|"Kind" -> "SpecialInverse", "Scale" -> "SpecialFunction", "Adapter" -> fam,
    "Function" -> original, "Variable" -> y, "Variables" -> {x, y}, "TargetDomain" -> domain,
    "ExpansionPoint" -> Infinity, "Direction" -> "FromBelow", "Limit" -> If[provablyPositive[scale, ass], Infinity, -Infinity],
    "TargetOffset" -> offset, "TargetScale" -> scale, "TargetCoordinateExpression" -> target,
    "SourceDomain" -> x > 2, "CoordinateSeries" -> inner, "CoordinateSubstitution" -> {v -> target},
    "ExactTransformedFunction" -> LogGamma[x], "TransformedFunction" -> core + perturbation,
    "ForwardModel" -> core + perturbation, "ForwardModelScope" -> "LogGamma in the exact transformed target equation", "ModelTerms" -> m,
    "ForwardRemainderBound" -> alpha x^-rho,
    "ForwardDerivativeRemainderBound" -> rho alpha x^(-rho - 1),
    "ForwardBoundConditions" -> x > 0,
    (* The Stirling bound Log[x] - 1/(2x) - 1/(12x^2) <= PolyGamma[0, x] is a
       lower bound for the derivative of LogGamma in the transformed target
       equation. The stored original function is offset + scale f[x], so the
       bound for the original equation carries the scale, and for Gamma the
       factor Gamma[x]; each field names its scope (wave-5 report 38 N2). *)
    "TransformedDerivativeLowerBound" -> Log[x] - 1/(2 x) - 1/(12 x^2),
    "OriginalDerivativeLowerBound" -> Abs[scale] If[fam === "Gamma", Gamma[x], 1] (Log[x] - 1/(2 x) - 1/(12 x^2)),
    "DerivativeLowerBoundScope" -> <|"TransformedDerivativeLowerBound" -> "D[LogGamma[x], x] in the transformed target equation, valid for x > 0",
      "OriginalDerivativeLowerBound" -> "Abs[D[" <> ToString[original, InputForm] <> ", x]] on the source branch x > 2"|>,
    "ForwardRemainderContract" -> <|"Type" -> "StirlingPoincareWithFirstNeglectedTermBound",
      "ConvergentForwardSeries" -> False, "BoundAppliesTo" -> "LogGamma in the transformed target equation",
      "Reference" -> "https://dlmf.nist.gov/5.11.ii", "InputRemainderPair" -> {rho, 0},
      "DerivativeRemainderPair" -> {rho + 1, 0}|>,
    "ExactModel" -> False, "InputRemainder" -> {rho, 0},
    "AccuracyFloor" -> <|"Coordinate" -> data["CoreLocalInverse"], "Power" -> rho|>,
    "AdapterCutoffMeaning" -> "Inclusive marker depth around the retained exact Lambert inverse of x(Log[x]-1). It is not an exponent-sorted jet; the Stirling input remainder may coarsen the marker-tail bound.",
    "SeriesData" -> Missing["RetainedExactCoreSpecialFunction"],
    "SwitchingContract" -> "The increasing real source branch x>2 is selected explicitly; no automatic near-minimum or crossover adapter is asserted."|>]]];

specialThreshold[fam_, x_, endpoint_, y_, cutoff_, ass_, direction_, branch_, offset_, scale_, quadratic_, limit_] := Module[
  {dir = direction, chosen = branch, v = Unique["thresholdTarget$"], inner, data, target, domain,
   original, exactInverse, coefficient, sign},
  If[! exactRealQ[cutoff] || ! less[1/2, cutoff], fail["InvalidCutoff", "A threshold cutoff must exceed the leading square-root power 1/2."]];
  If[fam === "LambertThreshold",
    If[endpoint =!= -1, fail["UnsupportedEndpoint", "The real Lambert threshold is centered at the source point -1."]];
    If[chosen === Automatic, chosen = If[dir === "FromBelow", -1, 0]];
    If[! MemberQ[{0, -1}, chosen], fail["InvalidLambertBranch", "The real threshold branches are 0 and -1."]];
    If[dir === Automatic, dir = If[chosen === 0, "FromAbove", "FromBelow"]];
    If[dir =!= If[chosen === 0, "FromAbove", "FromBelow"], fail["ConflictingBranch", "LambertBranch and source Direction select different real branches."]];
    inner = construct[x Exp[x], x, -1, v, cutoff, Assumptions -> ass, Direction -> dir, "MaxTerms" -> limit];
    If[FailureQ[inner], Return[inner, Module]];
    target = (y - offset)/scale; data = inner[[1]] /. v -> target;
    domain = ass && -1/E < target < 0; original = offset + scale x Exp[x];
    exactInverse = ProductLog[chosen, target],
    If[! exactRealQ[endpoint], fail["UnsupportedEndpoint", "The quadratic vertex must be an exact real finite source point."]];
    If[! (provablyPositive[quadratic, ass] || provablyNegative[quadratic, ass]), fail["UnprovedSign", "QuadraticCoefficient needs a provable nonzero real sign."]];
    If[dir === Automatic, dir = "FromAbove"];
    localCoordinate[x, endpoint, dir]; sign = If[dir === "FromAbove", 1, -1];
    coefficient = scale quadratic; original = offset + coefficient (x - endpoint)^2;
    inner = construct[original, x, endpoint, y, cutoff, Assumptions -> ass, Direction -> dir, "MaxTerms" -> limit];
    If[FailureQ[inner], Return[inner, Module]];
    data = inner[[1]]; target = (y - offset)/coefficient;
    domain = ass && target > 0; exactInverse = endpoint + sign Sqrt[target]; chosen = Missing["QuadraticSourceDirection"]];
  GeneralizedSeries[Join[data, <|"Kind" -> "SpecialInverse", "Scale" -> "SpecialFunction", "Adapter" -> fam,
    "Function" -> original, "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> endpoint,
    "Direction" -> dir, "TargetDomain" -> domain, "TargetOffset" -> offset, "TargetScale" -> scale,
    "ExactInverseExpression" -> exactInverse, "ThresholdBranch" -> chosen,
    "Limit" -> If[fam === "LambertThreshold", offset - scale/E, offset],
    "ThresholdTarget" -> If[fam === "LambertThreshold", offset - scale/E, offset],
    "ThresholdUniformizer" -> If[fam === "LambertThreshold", Sqrt[2 (1 + E target)], Sqrt[target]],
    "CoordinateSeries" -> inner, "CoordinateSubstitution" -> If[fam === "LambertThreshold", {v -> target}, {}],
    "ForwardRemainderContract" -> <|"Type" -> "ExactLocalRamifiedEquation", "ConvergentForwardSeries" -> True,
      "Reference" -> If[fam === "LambertThreshold", "https://dlmf.nist.gov/4.13", "Exact quadratic formula"]|>,
    "ExactForwardModel" -> True, "SeriesData" -> Missing["ExplicitThresholdCoordinate"],
    "SwitchingContract" -> "Explicit real local branch. Neighboring representations can be compared at a user-selected overlap point; no unproved automatic switching threshold is used."|>]]];

specialConstruct[fam_, x_, endpoint_, y_, cutoff_, opts : OptionsPattern[AsymptoticAnalysis`AsymptoticSpecialInverse]] := Module[
  {ass = optionAssumptions[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}],
   dir = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, Direction],
   m = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, "ModelTerms"],
   offset = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, "TargetOffset"],
   scale = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, "TargetScale"],
   q = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, "QuadraticCoefficient"],
   branch = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, "LambertBranch"],
   limit = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, "MaxTerms"], result},
  validateInput[{offset, scale, q}, limit];
  If[x === y || ! FreeQ[{offset, scale, q, ass}, x | y], fail["InvalidVariables", "Source and target symbols must be distinct, with parameter-only options and assumptions."]];
  If[! TrueQ[Simplify[Element[offset, Reals], ass]] ||
     ! (provablyPositive[scale, ass] || provablyNegative[scale, ass]), fail["UnprovedSign", "TargetOffset must be provably real and TargetScale must have a provable nonzero real sign."]];
  result = Switch[fam,
    "Erfc", specialErfc[fam, x, endpoint, y, cutoff, ass, dir, m, offset, scale, limit],
    "LogGamma" | "Gamma", specialGamma[fam, x, endpoint, y, cutoff, ass, dir, m, offset, scale, limit],
    "LambertThreshold" | "QuadraticThreshold", specialThreshold[fam, x, endpoint, y, cutoff, ass, dir, branch, offset, scale, q, limit],
    _, fail["UnknownSpecialFunctionAdapter", "Available adapters are Erfc, LogGamma, Gamma, LambertThreshold and QuadraticThreshold."]];
  If[FailureQ[result], Return[result, Module]];
  GeneralizedSeries[Join[result[[1]], <|"RequestedCutoff" -> cutoff,
    "AdapterOptions" -> {Assumptions -> ass, Direction -> dir, "ModelTerms" -> m,
      "TargetOffset" -> offset, "TargetScale" -> scale, "QuadraticCoefficient" -> q,
      "LambertBranch" -> branch}|>]]];

AsymptoticAnalysis`AsymptoticSpecialInverse[fam_String, {x_Symbol, endpoint_}, {y_Symbol, cutoff_}, opts : OptionsPattern[]] :=
  catch[specialConstruct[fam, x, endpoint, y, cutoff, opts]];
AsymptoticAnalysis`AsymptoticSpecialInverse[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use AsymptoticSpecialInverse[family,{x,endpoint},{y,cutoff}]."|>];

specialNumerical[a_, target_, wp_] := Module[{x, y, approximate, reference, equation, tt, bound},
  If[! IntegerQ[wp] || wp < 20, fail["InvalidPrecision", "WorkingPrecision must be an integer of at least 20 digits."]];
  If[! NumericQ[target] || (! exactQ[target] && Precision[target] < wp), fail["InsufficientPrecision", "Supply an exact target or enough input precision."]];
  {x, y} = a["Variables"];
  If[! TrueQ[N[a["TargetDomain"] /. y -> target, wp + 20]], fail["OutsideBranch", "The target is outside the adapter's selected real branch."]];
  (* Substitute exact target expressions before N so small reflected erfc
     tails and Log[Exp[v]] do not lose digits by subtracting rounded values. *)
  approximate = N[a["Expression"] /. y -> target, wp + 20];
  If[! finiteNumericQ[approximate] || ! TrueQ[Im[approximate] == 0], fail["InvalidSeed", "The adapter did not produce a real numerical seed."]];
  If[MemberQ[{"LambertThreshold", "QuadraticThreshold"}, a["Adapter"]],
    reference = N[a["ExactInverseExpression"] /. y -> target, wp + 20],
    equation = a["ExactTransformedFunction"]; tt = N[a["TargetCoordinateExpression"] /. y -> target, wp + 20];
    If[Precision[tt] < wp, fail["InsufficientPrecision", "The transformed target lost precision through cancellation; supply a more precise or exact target."]];
    reference = With[{xx = x, ff = equation, rhs = tt, start = approximate, precision = wp + 20, goal = wp},
      Quiet[Check[xx /. FindRoot[ff == rhs, {xx, start}, WorkingPrecision -> precision,
        AccuracyGoal -> Infinity, PrecisionGoal -> goal, MaxIterations -> 200], $Failed]]]];
  If[reference === $Failed || ! finiteNumericQ[reference] || ! TrueQ[Im[reference] == 0], fail["ReferenceRootNotFound", "The original special-function equation did not yield a real numerical reference."]];
  If[KeyExistsQ[a, "SourceDomain"] && ! TrueQ[a["SourceDomain"] /. x -> reference], fail["OutsideBranch", "The numerical reference left the selected source branch."]];
  bound = N[Lookup[a, "RemainderScaleExpression", a["Remainder"] /. rr_PowerLogRemainder :> remainderScale[rr]] /. y -> target, wp];
  <|"ReferenceRoot" -> N[reference, wp], "Approximation" -> N[approximate, wp],
    "Error" -> N[Abs[reference - approximate], wp], "RemainderScale" -> bound,
    (* A positive test: Mathics' tolerant Equal treats a small scale as zero. *)
    "Ratio" -> If[TrueQ[bound > 0], N[Abs[reference - approximate]/bound, wp], Indeterminate],
    "Evidence" -> "High-precision comparison with the original special-function equation or exact local inverse; no interval certificate.",
    "Adapter" -> a["Adapter"], "Certified" -> False|>];

AsymptoticAnalysis`SpecialInverseNumericalCheck[GeneralizedSeries[a_Association], target_, opts : OptionsPattern[]] :=
  catch[If[Lookup[a, "Kind", None] =!= "SpecialInverse", fail["InvalidAdapterObject", "Supply a special-function adapter result."]]; specialNumerical[a, target, OptionValue[WorkingPrecision]]];
AsymptoticAnalysis`SpecialInverseNumericalCheck[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use SpecialInverseNumericalCheck[adapterResult,target]."|>];
