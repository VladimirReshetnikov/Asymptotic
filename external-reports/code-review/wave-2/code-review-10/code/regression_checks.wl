(* Ten focused desired-contract checks. Baseline is expected to fail the
   polluted-domain and sparse-budget checks. Not an upstream full-suite run. *)
BeginPackage["AsymptoticAudit`"];
RunChecks::usage = "RunChecks[] returns named Boolean outcomes on a loaded package.";
Begin["`Private`"];
RunChecks[] := Block[{$Assumptions = True}, Module[
  {x, y, z, s, bad, polluted, good, boundary, f, c, product, polynomial, logarithmic},
  s = AsymptoticInverse`AsymptoticInverse[
    ConditionalExpression[x + x^2, x < 1/4], {x, 0}, {y, 3}];
  bad = AsymptoticInverse`InverseCertificate[s, 2,
    "Interval" -> {9/10, 11/10}, "Center" -> 1, "MaxRefinements" -> 0];
  polluted = Block[{$Assumptions = x < 1/4},
    AsymptoticInverse`InverseCertificate[s, 2,
      "Interval" -> {9/10, 11/10}, "Center" -> 1, "MaxRefinements" -> 0]];
  good = AsymptoticInverse`InverseCertificate[s, 11/100,
    "Interval" -> {9/100, 11/100}, "Center" -> 1/10, "MaxRefinements" -> 0];
  boundary = AsymptoticInverse`InverseCertificate[s, 5/16,
    "Interval" -> {1/5, 1/4}, "Center" -> 9/40, "MaxRefinements" -> 0];
  f = AsymptoticInverse`AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 8}];
  c = AsymptoticInverse`FlatSeriesObservable[f, 1, z];
  product = AsymptoticInverse`FlatSeriesMultiply[c, 1, "MaxTerms" -> 60];
  polynomial = AsymptoticInverse`AsymptoticInverse[x + x^2, {x, 0}, {y, 6}];
  logarithmic = AsymptoticInverse`AsymptoticExpansion[x^x, {x, 0, 3}];
  <|
    "C01-clean-domain-rejection" -> MatchQ[bad, Failure["OutsideBranch", _Association]],
    "C02-polluted-domain-rejection" -> MatchQ[polluted, Failure["OutsideBranch", _Association]],
    "C03-valid-domain-certificate" -> (AssociationQ[good] && TrueQ[good["Certified"]] && TrueQ[good["SourceDomainVerified"]]),
    "C04-valid-enclosure-contains-root" -> (AssociationQ[good] && TrueQ[good["RootEnclosure"][[1]] <= 1/10 <= good["RootEnclosure"][[2]]]),
    "C05-strict-endpoint-rejection" -> MatchQ[boundary, Failure["OutsideBranch", _Association]],
    "F01-sparse-exact-constant-product" -> (MatchQ[product, AsymptoticInverse`GeneralizedSeries[_Association]] && Normal[product] === 1 && product["Remainder"] === 0),
    "F02-exact-zero-recognition" -> TrueQ[AsymptoticInverse`Private`flatOpsExactZeroQ[{{}, Infinity, 0}]],
    "F03-uncertain-zero-not-annihilated" -> !TrueQ[AsymptoticInverse`Private`flatOpsExactZeroQ[{{}, 3, 0}]],
    "B01-native-polynomial-agreement" -> TrueQ[Simplify[Normal[polynomial] - Normal[InverseSeries[Series[x + x^2, {x, 0, 5}], y]]] == 0],
    "B02-native-logarithmic-agreement" -> TrueQ[Simplify[Normal[logarithmic] - Normal[Series[x^x, {x, 0, 2}]]] == 0]
  |>
]];
End[];
EndPackage[];
