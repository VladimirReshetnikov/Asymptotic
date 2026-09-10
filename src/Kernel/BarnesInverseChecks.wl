(* Independently evaluate the retained source in a finite Barnes phase.
   The normalization is X^2(Log[X]-1), so a source error at power P
   first appears at normalized residual power P+1. *)
barnesInverseResidual[a_Association, h_, limit_] := Module[
  {data, t, q, unit, logarithm, order, correction = 0, polynomial, modelTerms, checkSize},
  data = inverseCoreResidualSetup[a, h, limit, "Barnes", 1];
  {t, q, unit, logarithm, order} = Lookup[data,
    {"PowerVariable", "CoefficientVariable", "Unit", "Logarithm", "Order"}];
  checkSize[expression_] := inverseCoreResidualSize[expression, limit, "Barnes"];
  modelTerms = Max[0, Floor[(order - 2)/2]];
  Do[
    correction = checkSize[Expand[correction + BernoulliB[2 k + 2] t^(2 k + 2)/(2 k (2 k + 2))
      Normal[Series[unit^(-2 k), {t, 0, order - 2 k - 2}]]]], {k, 1, modelTerms}];
  polynomial = checkSize[Expand[Normal[Series[
    (1/2 - q/4) (unit^2 - 1) + q unit^2 logarithm/2 + Log[2 Pi] q t unit/2 -
      t^2 (1 + q)/12 - q t^2 logarithm/12 + (1/12 - Log[Glaisher]) q t^2 + q correction,
    {t, 0, order}]]]];
  inverseCoreResidualReport[a, data, polynomial, modelTerms, 2 modelTerms + 4,
    a["CoreInverse"]^2 a["CoreLogExpression"], a["CoreLogExpression"],
    <|"Normalization" -> "(LogBarnesG[SourceScale source+SourceOffset]-targetCoordinate)/(CoreInverse^2 CoreLogExpression).",
      "ForwardRemainderContract" -> <|"Type" -> "BarnesPoincareAtFixedOrder",
        "ConvergentForwardSeries" -> False, "Reference" -> "https://dlmf.nist.gov/5.17.E5"|>,
      "Scope" -> "Formal normalized residual of a finite Barnes model at the retained source approximation. ZeroBelowCutoff asserts cancellation only below the stated cutoff; the omitted Barnes tail is reported separately. This is not an exact identity or an interval certificate."|>]];
