(* DESIRED-CONTRACT tests: three findings should fail on the pinned baseline.
   The package must be loaded before TestReport is called. Each test is isolated.
   These are proposed integration tests, not an assertion that this complete file
   has been executed in the audit environment. *)
VerificationTest[
 Module[{x, y, s, c}, Block[{$Assumptions = True},
  s = AsymptoticInverse`AsymptoticInverse[ConditionalExpression[x, x > 100],
    {x, Infinity}, {y, 2}]];
  c = Block[{$Assumptions = x > 100}, AsymptoticInverse`InverseCertificate[s, 2,
    "Interval" -> {1, 3}, "Center" -> 2, "MaxRefinements" -> 0]];
  MatchQ[c, Failure["OutsideBranch", _Association]]], True,
 TestID -> "N01-ambient-assumptions-do-not-prove-interval-domain"]

VerificationTest[
 Module[{x, y, s, c}, Block[{$Assumptions = True},
  s = AsymptoticInverse`AsymptoticInverse[ConditionalExpression[x, x > 100],
    {x, Infinity}, {y, 2}]];
  c = Block[{$Assumptions = x > 100}, AsymptoticInverse`InverseCertificate[s, 102,
    "Interval" -> {101, 103}, "Center" -> 102, "MaxRefinements" -> 0]];
  AssociationQ[c] && TrueQ[c["Certified"]] && c["RootEnclosure"] === {102, 102}], True,
 TestID -> "N01-valid-interval-still-certifies"]

VerificationTest[
 Module[{x, c = Root[5 + 5*# + #^5 &, 2]}, Block[{$Assumptions = True},
  FailureQ[AsymptoticInverse`AsymptoticExpansion[c/x, {x, 0, -2}]]]], True,
 TestID -> "N02-nonreal-algebraic-source-rejected-before-truncation"]

VerificationTest[
 Module[{x, a}, Block[{$Assumptions = True},
  Normal[AsymptoticInverse`AsymptoticExpansion[a*x, {x, 0, 2},
    Assumptions -> Element[a, Reals]]] === a*x]], True,
 TestID -> "N02-explicit-real-parameter-accepted"]

VerificationTest[
 Module[{x, s}, Block[{$Assumptions = True},
  s = AsymptoticInverse`AsymptoticExpansion[Exp[x], {x, 0, 3}];
  Normal[s] === 1 + x + x^2/2 && MatchQ[s["SeriesData"], _SeriesData]]], True,
 TestID -> "N02-N03-ordinary-taylor-control"]

VerificationTest[
 Module[{x, s}, s = Quiet[AsymptoticInverse`AsymptoticExpansion[
   1 + x^(2^100), {x, 0, 2}]];
  MatchQ[s, AsymptoticInverse`GeneralizedSeries[_Association]] &&
   Normal[s] === 1 && MissingQ[s["SeriesData"]]], True,
 TestID -> "N03-unrepresentable-native-remainder-index-is-optional"]

VerificationTest[
 Module[{x, s, q = 2^100}, s = Quiet[AsymptoticInverse`AsymptoticExpansion[
   x^(1/q) + x^(3/q), {x, 0, 2/q}]];
  MatchQ[s, AsymptoticInverse`GeneralizedSeries[_Association]] &&
   Normal[s] === x^(1/q) && MissingQ[s["SeriesData"]]], True,
 TestID -> "N03-unrepresentable-native-denominator-is-optional"]

VerificationTest[
 Module[{x, y, s, n}, s = AsymptoticInverse`AsymptoticInverse[x + x^3,
   {x, 0}, {y, 6}]; n = InverseSeries[Series[x + x^3, {x, 0, 6}], y];
  Simplify[Normal[s] - Normal[n]] === 0], True,
 TestID -> "shared-native-polynomial-inversion"]
