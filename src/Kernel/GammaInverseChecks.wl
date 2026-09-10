(* Checks for inverse Gamma expansions in powers of the retained Lambert
   core. Numerical comparisons use the original logarithmic equation.
   Formal residuals independently expand a finite Stirling model; they do
   not turn that Poincare model into an exact defining equation. *)

gammaInverseNumerical[a_Association, target_, wp_] := Module[
  {x, y, power, scale, offset, coordinate, equation, approximate, seed, root,
   observed, error, remainder, phaseResidual, rootResidual},
  If[! IntegerQ[wp] || wp < 10,
    fail["InvalidPrecision", "WorkingPrecision must be an integer of at least 10 digits."]];
  If[! NumericQ[target] || (! exactQ[target] && Precision[target] < wp),
    fail["InsufficientPrecision", "Supply an exact target or at least WorkingPrecision digits."]];
  {x, y} = a["Variables"]; power = a["Power"];
  scale = N[a["SourceScale"] /. y -> target, wp + 20];
  offset = N[a["SourceOffset"] /. y -> target, wp + 20];
  If[! And @@ (NumericQ /@ {scale, offset, power}),
    fail["UnresolvedParameters", "Substitute numerical values for the expansion's fixed parameters before numerical checking."]];
  If[! TrueQ[Quiet[Check[N[a["TargetDomain"] /. y -> target, wp + 20], False]]],
    fail["OutsideBranch", "The target does not satisfy the retained real inverse Gamma/Barnes G branch conditions."]];
  (* Substitute the exact target before numerical evaluation, preserving
     identities such as Log[Exp[v]] == v for a real exact v. *)
  coordinate = N[a["TargetCoordinateExpression"] /. y -> target, wp + 20];
  If[! finiteNumericQ[coordinate] || ! TrueQ[Im[coordinate] == 0],
    fail["UnresolvedParameters", "The logarithmic target coordinate must have a real numerical value."]];
  If[Precision[coordinate] < wp,
    fail["InsufficientPrecision", "The transformed target lost precision through cancellation; supply a more precise or exact target."]];
  approximate = N[a["Expression"] /. y -> target, wp + 20];
  seed = N[Lookup[a, "RootSeedExpression", (a["CoreInverse"] - a["SourceOffset"])/a["SourceScale"]] /. y -> target, wp + 20];
  If[! And @@ (finiteNumericQ /@ {approximate, seed}) ||
     ! TrueQ[Im[approximate] == 0 && Im[seed] == 0],
    fail["InvalidSeed", "The inverse Gamma/Barnes G expansion and retained core must give real numerical values."]];
  equation = a["ExactTransformedFunction"];
  root = With[{xx = x, ff = equation, rhs = coordinate, start = seed,
      precision = wp + 20, goal = wp},
    Quiet[Check[xx /. FindRoot[ff == rhs, {xx, start},
      WorkingPrecision -> precision, AccuracyGoal -> Infinity,
      PrecisionGoal -> goal, MaxIterations -> 500], $Failed]]];
  If[root === $Failed || ! finiteNumericQ[root] || ! TrueQ[Im[root] == 0],
    fail["ReferenceRootNotFound", "The exact logarithmic Gamma/Barnes equation did not yield a real numerical reference."]];
  numericalSourceDomainCheck[a, root, target, wp];
  observed = N[root^power, wp + 20];
  If[! finiteNumericQ[observed] || ! TrueQ[Im[observed] == 0],
    fail["OutsideBranch", "The requested power observable is not real at the recovered source root."]];
  remainder = N[a["RemainderScaleExpression"] /. y -> target, wp];
  If[! finiteNumericQ[remainder] || ! TrueQ[Im[remainder] == 0 && remainder >= 0],
    fail["InvalidRemainderScale", "The stored absolute remainder scale must evaluate to a nonnegative real value."]];
  error = N[Abs[observed - approximate], wp];
  phaseResidual = N[(equation /. x -> seed) - coordinate, wp];
  rootResidual = N[(equation /. x -> root) - coordinate, wp];
  Join[<|"ReferenceRoot" -> N[root, wp], "ExactInverse" -> N[root, wp],
    "ReferenceObservable" -> N[observed, wp], "Approximation" -> N[approximate, wp],
    "RootSeed" -> N[seed, wp], "Error" -> error,
    "RemainderScale" -> remainder,
    "Ratio" -> If[TrueQ[remainder == 0], Indeterminate, error/remainder],
    "SourceDomainChecked" -> inverseEvidenceSourceDomain[a, x],
    "SourceDomainVerified" -> True, "SeedPhaseResidual" -> phaseResidual,
    "RootResidual" -> rootResidual, "Certified" -> False,
    "Scope" -> "The exact logarithmic " <> If[a["Kind"] === "BarnesGInverse", "Barnes G", "Gamma"] <> " equation on the retained real source branch.",
    "Evidence" -> "High-precision numerical comparison, not an interval certificate. ExactInverse is a legacy alias for ReferenceRoot."|>,
    If[power === 1, <|"ApproximationSourceRoot" -> N[approximate, wp],
      "PhaseResidual" -> N[(equation /. x -> approximate) - coordinate, wp]|>, <||>]]];

(* The two residuals share their input checks and coefficient bookkeeping.
   Their finite phase formulas below and in BarnesInverseChecks remain
   independent of the inverse constructors and their coefficient recurrences. *)
inverseCoreResidualSize[expression_, limit_, family_] := If[LeafCount[expression] > limit,
  fail["ResourceLimit", "An intermediate exact " <> family <> " residual expression exceeded MaxTerms."], expression];

inverseCoreResidualSetup[a_Association, h_, limit_, family_, argumentOffset_] := Module[
  {cut, order, t = Unique[ToLowerCase[family] <> "ResidualPower$"], q, ass, rows, source, unit},
  If[Lookup[a, "Power", 1] =!= 1,
    fail["UnsupportedObservable", If[family === "Gamma",
      "A Gamma/Barnes inverse residual currently requires the source-point observable Power -> 1; a finite powered approximation is not inverted to recover a source root.",
      "A Barnes-inverse residual requires the source-point observable Power -> 1."]]];
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  cut = If[h === Automatic, a["RemainderPower"] + 1, h];
  If[! exactRealQ[cut] || ! less[0, cut],
    fail["InvalidCutoff", "The normalized " <> family <> " residual cutoff must be a positive exact real number."]];
  order = Ceiling[cut] - 1;
  If[order + 2 > limit,
    fail["ResourceLimit", "The " <> If[family === "Gamma", "requested ", ""] <>
      "normalized " <> family <> " residual order exceeds MaxTerms."]];
  q = a["CoefficientVariable"]; ass = a["Assumptions"]; rows = a["Terms"];
  validateInput[rows, limit];
  If[! ListQ[rows] || ! And @@ (MatchQ[#, {_Integer, _}] && #[[1]] >= -1 & /@ rows),
    fail["UnsupportedResidualScale", "The source-point " <> family <>
      " residual requires integer powers of the reciprocal Lambert core."]];
  source = Total[(t^#[[1]] #[[2]]) & /@ rows];
  unit = inverseCoreResidualSize[FullSimplify[
    Expand[t (a["SourceScale"] source + a["SourceOffset"] - argumentOffset)], ass], limit, family];
  If[! PolynomialQ[unit, t] || ! TrueQ[FullSimplify[(unit /. t -> 0) == 1, ass]],
    fail["Invalid" <> family <> "InverseNormalization", If[family === "Gamma",
      "The retained source approximation must give a Gamma argument whose ratio to its Lambert core tends to one.",
      "The Barnes argument minus one must have ratio one to its Lambert core."]]];
  <|"Cutoff" -> cut, "Order" -> order, "PowerVariable" -> t, "CoefficientVariable" -> q,
    "Assumptions" -> ass, "Unit" -> unit, "Family" -> family, "MaxTerms" -> limit,
    "Logarithm" -> inverseCoreResidualSize[Normal[Series[Log[unit], {t, 0, order}]], limit, family]|>];

inverseCoreResidualReport[a_Association, data_, polynomial_, modelTerms_, modelPower_, normalizer_, tailLog_, metadata_] := Module[
  {t, q, ass, order, limit, family, coefficient, blocks, residual, x},
  {t, q, ass, order, limit, family} = Lookup[data,
    {"PowerVariable", "CoefficientVariable", "Assumptions", "Order", "MaxTerms", "Family"}];
  blocks = Reap[Do[
    coefficient = inverseCoreResidualSize[FullSimplify[Coefficient[polynomial, t, n], ass], limit, family];
    If[! TrueQ[coefficient === 0], Sow[{n, coefficient}]], {n, 0, order}]][[2]];
  blocks = If[blocks === {}, {}, First[blocks]];
  residual = Total[(t^#[[1]] #[[2]]) & /@ blocks] /.
    Join[{t -> 1/a["CoreInverse"]}, a["CoefficientSubstitution"]];
  x = First[a["Variables"]];
  <|"ZeroBelowCutoff" -> (blocks === {}), "Residual" -> residual,
    "NormalizedResidual" -> residual, "ResidualBlocks" -> blocks,
    "Cutoff" -> data["Cutoff"], "RelativeCutoff" -> data["Cutoff"],
    "ScaleVariable" -> 1/a["CoreInverse"], "CoefficientVariable" -> q,
    "CoefficientSubstitution" -> a["CoefficientSubstitution"],
    "ExactEquationResidualExpression" -> ((a["ExactTransformedFunction"] /. x -> a["Expression"]) -
      a["TargetCoordinateExpression"])/normalizer,
    "Normalization" -> metadata["Normalization"],
    "ForwardModelTerms" -> modelTerms, "ModelRemainderPower" -> modelPower,
    "ModelRemainderScaleExpression" -> 1/(a["CoreInverse"]^modelPower tailLog),
    "ForwardRemainderContract" -> metadata["ForwardRemainderContract"],
    "ExactModel" -> False, "Scope" -> metadata["Scope"]|>];

gammaInverseResidual[a_Association, h_, limit_] := Module[
  {data, t, q, unit, logarithm, order, correction = 0, polynomial, modelTerms, checkSize},
  data = inverseCoreResidualSetup[a, h, limit, "Gamma", 0];
  {t, q, unit, logarithm, order} = Lookup[data,
    {"PowerVariable", "CoefficientVariable", "Unit", "Logarithm", "Order"}];
  checkSize[expression_] := inverseCoreResidualSize[expression, limit, "Gamma"];
  modelTerms = Floor[order/2];
  Do[
    correction = checkSize[Expand[correction +
      BernoulliB[2 k] t^(2 k)/(2 k (2 k - 1))
        Normal[Series[unit^(1 - 2 k), {t, 0, order - 2 k}]]]],
    {k, 1, modelTerms}];
  (* With Gamma argument = unit/t and Log[t] = -1/q, this is
     q t (StirlingPhase - (1/t)(1/q - 1)). *)
  polynomial = checkSize[Expand[Normal[Series[
    (1 - q) (unit - 1) - t/2 + q (unit - t/2) logarithm +
      q t Log[2 Pi]/2 + q correction, {t, 0, order}]]]];
  inverseCoreResidualReport[a, data, polynomial, modelTerms, 2 modelTerms + 2,
    a["CoreInverse"] Log[a["CoreInverse"]], Log[a["CoreInverse"]],
    <|"Normalization" -> "(LogGamma[SourceScale source + SourceOffset] - targetCoordinate)/(CoreInverse Log[CoreInverse]).",
      "ForwardRemainderContract" -> <|"Type" -> "StirlingPoincareAtFixedOrder",
        "ConvergentForwardSeries" -> False, "Reference" -> "https://dlmf.nist.gov/5.11.ii"|>,
      "Scope" -> "Formal normalized residual of a finite Stirling model evaluated at the retained source approximation. ZeroBelowCutoff means cancellation only below the stated cutoff; it does not assert that the exact Gamma equation is solved identically. The first omitted Stirling term has the separately reported normalized remainder scale."|>]];
