If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[Module[{x, y, s, t},
  s = AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 2}]; t = FlatSeriesTruncate[s, 3];
  {TrueQ[FullSimplify[Normal[t] == y - y^2 Exp[-1/y] + y^2 Exp[-2/y], y > 0]],
    t["ZeroSector"] === y, t["InnerRemainders"] /. y -> \[FormalY]}],
  {True, True, {{2, PowerLogRemainder[\[FormalY], 3, 0]}}},
  TestID -> "flat-operations-inner-truncation-has-separate-sector-error"]

VerificationTest[Module[{x, y, s, t},
  s = AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 2}]; t = FlatSeriesTruncate[s, 1];
  {Normal[t] === y, t["InnerRemainders"][[All, 1]], t["SectorRemainder"] =!= 0,
    Length[Cases[t["Remainder"], _PowerLogRemainder, Infinity]]}],
  {True, {1, 2}, True, 3}, TestID -> "flat-operations-zero-sector-is-exact-even-above-inner-cutoff"]

VerificationTest[Module[{x, y, s, t, raised},
  s = AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 2}]; t = FlatSeriesTruncate[s, 3];
  raised = FlatSeriesTruncate[t, 8];
  {Normal[raised] === Normal[t], raised["InnerRemainders"] === t["InnerRemainders"]}],
  {True, True}, TestID -> "flat-operations-larger-inner-cutoff-does-not-invent-discarded-coefficients"]

VerificationTest[Module[{x, y, s, product, z, oracle},
  s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 2}]; product = FlatSeriesMultiply[s, s];
  oracle = Normal[Series[(y - z + z^2/y^2)^2, {z, 0, 2}]] /. z -> Exp[-1/y];
  {TrueQ[FullSimplify[Normal[product] == oracle, y > 0]], product["SectorRemainder"] =!= 0}],
  {True, True}, TestID -> "flat-operations-product-agrees-with-independent-marker-polynomial"]

VerificationTest[Module[{x, y, s, product},
  s = FlatSeriesTruncate[AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 2}], 3];
  product = FlatSeriesMultiply[s, 1/y];
  {TrueQ[FullSimplify[Normal[product] == 1 - y Exp[-1/y] + y Exp[-2/y], y > 0]],
    product["InnerRemainders"] /. y -> \[FormalY]}],
  {True, {{2, PowerLogRemainder[\[FormalY], 2, 0]}}},
  TestID -> "flat-operations-scalar-power-transports-inner-precision"]

VerificationTest[Module[{x, y, a, b, product},
  a = FlatSeriesTruncate[AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 2}], 1];
  b = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 2}]; product = FlatSeriesMultiply[a, b];
  {TrueQ[FullSimplify[Normal[product] == y^2 - y Exp[-1/y] + Exp[-2/y]/y, y > 0]],
    product["InnerRemainders"] /. y -> \[FormalY]}],
  {True, {{1, PowerLogRemainder[\[FormalY], 3, 0]}, {2, PowerLogRemainder[\[FormalY], 2, 0]}}},
  TestID -> "flat-operations-unknown-inner-errors-stay-in-their-convolution-sectors"]

VerificationTest[Module[{x, y, s, z, marker, g, oracle, result},
  s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 2}]; g = y - marker + marker^2/y^2;
  oracle = Normal[Series[2 g^2 - 3 g + 7, {marker, 0, 2}]] /. marker -> Exp[-1/y];
  result = FlatSeriesObservable[s, 2 z^2 - 3 z + 7, z];
  {TrueQ[FullSimplify[Normal[result] == oracle, y > 0]],
    TrueQ[FullSimplify[result["ZeroSector"] == 2 y^2 - 3 y + 7]]}],
  {True, True}, TestID -> "flat-operations-polynomial-observable-has-exact-zero-sector"]

VerificationTest[Module[{x, y, s, z, marker, g, oracle, result},
  s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 2}]; g = y - marker + marker^2/y^2;
  oracle = Normal[Series[Log[y] g^2 + y g, {marker, 0, 2}]] /. marker -> Exp[-1/y];
  result = FlatSeriesObservable[s, Log[y] z^2 + y z, z];
  TrueQ[FullSimplify[Normal[result] == oracle, y > 0]]], True,
  TestID -> "flat-operations-polynomial-observable-allows-exact-target-power-log-coefficients"]

VerificationTest[Module[{x, y, s, z, result},
  s = FlatSeriesTruncate[AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 2}], 1];
  result = FlatSeriesObservable[s, 0, z]; {Normal[result], result["Remainder"], result["ZeroSector"]}],
  {0, 0, 0}, TestID -> "flat-operations-exact-zero-observable-annihilates-all-errors"]

VerificationTest[Module[{x, y, s, z, result},
  s = FlatSeriesTruncate[AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 2}], 1];
  result = FlatSeriesObservable[s, (z - y)^2, z];
  {result["ZeroSector"], result["Remainder"] =!= 0}], {0, True},
  TestID -> "flat-operations-cancellation-does-not-erase-unknown-sector-errors"]

VerificationTest[Module[{x, y, s, derivative},
  s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 2}]; derivative = FlatSeriesDifferentiate[s];
  {TrueQ[FullSimplify[Normal[derivative] == D[Normal[s], y], y > 0]],
    Cases[derivative["SectorRemainder"], PowerLogRemainder[_, rho_, degree_] :> {rho, degree}, Infinity]}],
  {True, {{-6, 0}}}, TestID -> "flat-operations-differentiates-phase-and-transports-complete-tail"]

VerificationTest[Module[{x, y, s, derivative},
  s = FlatSeriesTruncate[AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 2}], 3];
  derivative = FlatSeriesDifferentiate[s];
  {TrueQ[FullSimplify[Normal[derivative] == 1 - (1 + 2 y) Exp[-1/y] + 2 Exp[-2/y], y > 0]],
    derivative["InnerRemainders"] /. y -> \[FormalY]}],
  {True, {{2, PowerLogRemainder[\[FormalY], 1, 0]}}},
  TestID -> "flat-operations-derivative-lowers-inner-precision-before-trimming"]

VerificationTest[Module[{x, y, s, derivative},
  s = FlatSeriesTruncate[AsymptoticFlatInverse[x + x^2 Log[x] Exp[-1/x], {x, 0}, {y, 2}], 3];
  derivative = FlatSeriesDifferentiate[s]; derivative["InnerRemainders"] /. y -> \[FormalY]],
  {{2, PowerLogRemainder[\[FormalY], 1, 2]}},
  TestID -> "flat-operations-derivative-retains-logarithmic-envelope-degree"]

VerificationTest[Module[{x, y, s, derivative},
  s = FlatSeriesTruncate[AsymptoticFlatInverse[x + (x^2 Log[x]^4 + x^3) Exp[-1/x], {x, 0}, {y, 1}], 3];
  derivative = FlatSeriesDifferentiate[s]; derivative["InnerRemainders"] /. y -> \[FormalY]],
  {{1, PowerLogRemainder[\[FormalY], 1, 4]}},
  TestID -> "flat-operations-dropped-derivative-boundary-row-increases-log-bound"]

VerificationTest[Module[{x, y, s, derivative, before, after},
  s = AsymptoticFlatInverse[1/x + Exp[-1/x], {x, 0}, {y, 2}]; derivative = FlatSeriesDifferentiate[s];
  before = Cases[s["Remainder"], PowerLogRemainder[_, rho_, degree_] :> {rho, degree}, Infinity];
  after = Cases[derivative["SectorRemainder"], PowerLogRemainder[_, rho_, degree_] :> {rho, degree}, Infinity];
  {TrueQ[FullSimplify[Normal[derivative] == D[Normal[s], y], y > 0]], before === after}],
  {True, True}, TestID -> "flat-operations-negative-leading-power-uses-target-chain-rule"]

VerificationTest[Module[{x, y, s, derivative},
  s = AsymptoticFlatInverse[3 x^2 + x Exp[-2/x], {x, 0}, {y, 1}]; derivative = FlatSeriesDifferentiate[s, 2];
  TrueQ[FullSimplify[Normal[derivative] == D[Normal[s], {y, 2}], y > 0]]], True,
  TestID -> "flat-operations-two-derivatives-in-a-nonunit-monomial-chart"]

VerificationTest[Module[{x, y, s, withoutContract},
  s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 2}];
  withoutContract = GeneralizedSeries[KeyDrop[s[[1]], "FlatAnalyticRemainder"]];
  FlatSeriesDifferentiate[withoutContract]], Failure["UnprovedFlatRemainderDerivative", _Association], SameTest -> MatchQ,
  TestID -> "flat-operations-does-not-differentiate-an-unqualified-big-o"]

VerificationTest[Module[{x, y, a, b},
  a = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 1}];
  b = AsymptoticFlatInverse[x + Exp[-2/x], {x, 0}, {y, 1}]; FlatSeriesMultiply[a, b]],
  Failure["IncompatibleFlatScales", _Association], SameTest -> MatchQ,
  TestID -> "flat-operations-rejects-different-exponential-phases"]

VerificationTest[Module[{x, y, a, b},
  a = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 1}];
  b = AsymptoticFlatInverse[2 x + Exp[-1/x], {x, 0}, {y, 1}]; FlatSeriesMultiply[a, b]],
  Failure["IncompatibleFlatScales", _Association], SameTest -> MatchQ,
  TestID -> "flat-operations-rejects-different-monomial-target-charts"]

VerificationTest[Module[{x, y, z, s},
  s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 1}]; FlatSeriesObservable[s, Sin[z], z]],
  Failure["UnsupportedFlatObservable", _Association], SameTest -> MatchQ,
  TestID -> "flat-operations-nonpolynomial-observable-is-explicitly-outside-scope"]

VerificationTest[Module[{x, y, z, s},
  s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 1}];
  FlatSeriesObservable[s, z^4, z, "MaxPolynomialDegree" -> 3]],
  Failure["ResourceLimit", _Association], SameTest -> MatchQ,
  TestID -> "flat-operations-polynomial-degree-budget"]

VerificationTest[Module[{x, y, s}, s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 2}];
  FlatSeriesMultiply[s, s, "MaxTerms" -> 1]], Failure["ResourceLimit", _Association], SameTest -> MatchQ,
  TestID -> "flat-operations-representation-budget"]

VerificationTest[
  {FlatSeriesTruncate[], FlatSeriesMultiply[], FlatSeriesObservable[], FlatSeriesDifferentiate[]},
  ConstantArray[Failure["InvalidArguments", _Association], 4], SameTest -> MatchQ,
  TestID -> "flat-operations-malformed-public-calls-have-failures"]
