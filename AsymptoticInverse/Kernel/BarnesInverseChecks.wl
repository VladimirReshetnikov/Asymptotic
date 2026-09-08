(* Independently evaluate the retained source in a finite Barnes phase.
   The normalization is X^2(Log[X]-1), so a source error at power P
   first appears at normalized residual power P+1. *)
barnesInverseResidual[a_Association, h_, limit_] := Module[
  {cut, order, t = Unique["barnesResidualPower$"], q, ass, rows, source, unit,
   logarithm, correction = 0, polynomial, coefficient, blocks, residual,
   substitutions, modelTerms, modelPower, x, y, exactResidual, checkSize},
  If[Lookup[a, "Power", 1] =!= 1,
    fail["UnsupportedObservable", "A Barnes-inverse residual requires the source-point observable Power -> 1."]];
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  cut = If[h === Automatic, a["RemainderPower"] + 1, h];
  If[! exactRealQ[cut] || ! less[0, cut],
    fail["InvalidCutoff", "The normalized Barnes residual cutoff must be a positive exact real number."]];
  order = Ceiling[cut] - 1;
  If[order + 2 > limit, fail["ResourceLimit", "The normalized Barnes residual order exceeds MaxTerms."]];
  q = a["CoefficientVariable"]; ass = a["Assumptions"]; rows = a["Terms"];
  validateInput[rows, limit];
  If[! ListQ[rows] || ! And @@ (MatchQ[#, {_Integer, _}] && #[[1]] >= -1 & /@ rows),
    fail["UnsupportedResidualScale", "The source-point Barnes residual requires integer powers of the reciprocal Lambert core."]];
  checkSize[expression_] := If[LeafCount[expression] > limit,
    fail["ResourceLimit", "An intermediate exact Barnes residual expression exceeded MaxTerms."], expression];
  source = Total[(t^#[[1]] #[[2]]) & /@ rows];
  unit = checkSize[FullSimplify[Expand[t (a["SourceScale"] source + a["SourceOffset"] - 1)], ass]];
  If[! PolynomialQ[unit, t] || ! TrueQ[FullSimplify[(unit /. t -> 0) == 1, ass]],
    fail["InvalidBarnesInverseNormalization", "The Barnes argument minus one must have ratio one to its Lambert core."]];
  logarithm = checkSize[Normal[Series[Log[unit], {t, 0, order}]]];
  modelTerms = Max[0, Floor[(order - 2)/2]];
  Do[
    correction = checkSize[Expand[correction + BernoulliB[2 k + 2] t^(2 k + 2)/(2 k (2 k + 2))
      Normal[Series[unit^(-2 k), {t, 0, order - 2 k - 2}]]]], {k, 1, modelTerms}];
  polynomial = checkSize[Expand[Normal[Series[
    (1/2 - q/4) (unit^2 - 1) + q unit^2 logarithm/2 + Log[2 Pi] q t unit/2 -
      t^2 (1 + q)/12 - q t^2 logarithm/12 + (1/12 - Log[Glaisher]) q t^2 + q correction,
    {t, 0, order}]]]];
  blocks = Reap[Do[
    coefficient = checkSize[FullSimplify[Coefficient[polynomial, t, n], ass]];
    If[! TrueQ[coefficient === 0], Sow[{n, coefficient}]], {n, 0, order}]][[2]];
  blocks = If[blocks === {}, {}, First[blocks]];
  substitutions = Join[{t -> 1/a["CoreInverse"]}, a["CoefficientSubstitution"]];
  residual = Total[(t^#[[1]] #[[2]]) & /@ blocks] /. substitutions;
  {x, y} = a["Variables"];
  exactResidual = ((a["ExactTransformedFunction"] /. x -> a["Expression"]) -
    a["TargetCoordinateExpression"])/(a["CoreInverse"]^2 a["CoreLogExpression"]);
  modelPower = 2 modelTerms + 4;
  <|"ZeroBelowCutoff" -> (blocks === {}), "Residual" -> residual,
    "NormalizedResidual" -> residual, "ResidualBlocks" -> blocks,
    "Cutoff" -> cut, "RelativeCutoff" -> cut,
    "ScaleVariable" -> 1/a["CoreInverse"], "CoefficientVariable" -> q,
    "CoefficientSubstitution" -> a["CoefficientSubstitution"],
    "ExactEquationResidualExpression" -> exactResidual,
    "Normalization" -> "(Log[BarnesG[SourceScale source+SourceOffset]]-targetCoordinate)/(CoreInverse^2 CoreLogExpression).",
    "ForwardModelTerms" -> modelTerms, "ModelRemainderPower" -> modelPower,
    "ModelRemainderScaleExpression" -> 1/(a["CoreInverse"]^modelPower a["CoreLogExpression"]),
    "ForwardRemainderContract" -> <|"Type" -> "BarnesPoincareAtFixedOrder",
      "ConvergentForwardSeries" -> False, "Reference" -> "https://dlmf.nist.gov/5.17.E5"|>,
    "ExactModel" -> False,
    "Scope" -> "Formal normalized residual of a finite Barnes model at the retained source approximation. ZeroBelowCutoff asserts cancellation only below the stated cutoff; the omitted Barnes tail is reported separately. This is not an exact identity or an interval certificate."|>];
