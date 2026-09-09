(* Review 4 R03 / review 7 F03: a native endpoint does not record the
   logarithmic degree of its unknown tail. Expected elliptic and Bessel
   coefficients come from the convergent formulas DLMF 19.12.1 and 10.8.1,
   not from a second Wolfram Series calculation used as an oracle.
   https://dlmf.nist.gov/19.12.E1
   https://dlmf.nist.gov/10.8.E1 *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

reviewNativeTailExpression[j_, u_, ell_] :=
  Total[(u^#[[1]] (#[[2]] /. ell -> Log[u])) & /@ j[[1]]];
reviewNativeTailCovers[precision_, term_, u_] := Module[{ratio},
  ratio = Limit[Abs[term]/(u^precision[[1]] (1 - Log[u])^precision[[2]]),
    u -> 0, Direction -> "FromAbove"];
  NumericQ[ratio] && TrueQ[ratio >= 0]];

VerificationTest[Module[{x, s, l, expected},
  l = Log[4/x];
  expected = l/x^3 + (l - 1)/(4 x) + 9 x (l - 7/6)/64;
  s = AsymptoticExpansion[EllipticK[1 - x^2]/x^3, {x, 0, 3}];
  MatchQ[s, _GeneralizedSeries] &&
    TrueQ[FullSimplify[Normal[s] == expected, x > 0]]],
  True, TestID -> "review-native-tail-shifted-elliptic-retains-correct-finite-blocks"]

VerificationTest[Module[{x, s, precision},
  s = AsymptoticExpansion[EllipticK[1 - x^2]/x^3, {x, 0, 3}];
  MatchQ[s, _GeneralizedSeries] && Module[{},
    precision = {s["RemainderPower"], s["RemainderLogDegree"]};
    MemberQ[{{3, 1}, {5/2, 0}}, precision] &&
      reviewNativeTailCovers[precision, 25 x^3 (Log[4/x] - 37/30)/256, x]]],
  True, TestID -> "review-native-tail-shifted-elliptic-does-not-claim-log-free-boundary"]

VerificationTest[Module[{u, ell, j},
  j = AsymptoticInverse`Private`fwdSeries[EllipticK[1 - u^2], u, ell, True, 2, 20000];
  {j[[{2, 3}]], reviewNativeTailCovers[j[[{2, 3}]],
    9 u^4 (Log[4/u] - 7/6)/64, u]}],
  {{7/2, 0}, True},
  TestID -> "review-native-tail-lacunary-elliptic-order-two-keeps-power-margin"]

VerificationTest[Module[{u, ell, j},
  j = AsymptoticInverse`Private`fwdSeries[EllipticK[1 - u^2], u, ell, True, 4, 20000];
  {j[[{2, 3}]], reviewNativeTailCovers[j[[{2, 3}]],
    25 u^6 (Log[4/u] - 37/30)/256, u]}],
  {{11/2, 0}, True},
  TestID -> "review-native-tail-lacunary-elliptic-order-four-keeps-power-margin"]

VerificationTest[Module[{u, ell, j},
  j = AsymptoticInverse`Private`fwdSeries[EllipticK[1 - u^2], u, ell, True, 3, 20000];
  {j[[{2, 3}]], TrueQ[FullSimplify[reviewNativeTailExpression[j, u, ell] ==
    Log[4/u] + u^2 (Log[4/u] - 1)/4, u > 0]]}],
  {{4, 1}, True},
  TestID -> "review-native-tail-visible-elliptic-boundary-retains-log-degree"]

VerificationTest[Module[{u, ell, j, h},
  h = Function[t, BesselY[4, t]];
  j = AsymptoticInverse`Private`fwdAnalytic[h, {{{1, 1}}, Infinity, 0},
    BesselY[4, u], u, ell, True, 3, 20000];
  {j[[{2, 3}]], reviewNativeTailCovers[j[[{2, 3}]],
    u^4 (Log[u/2] + EulerGamma - 25/24)/(192 Pi), u]}],
  {{7/2, 0}, True},
  TestID -> "review-native-tail-log-free-bessel-prefix-does-not-prove-log-free-laurent-tail"]

VerificationTest[Module[{u, ell, j, h},
  h = Function[t, BesselY[4, t]];
  j = AsymptoticInverse`Private`fwdAnalytic[h, {{{Sqrt[2], 1}}, Infinity, 0},
    BesselY[4, u^Sqrt[2]], u, ell, True, 3, 20000];
  {TrueQ[FullSimplify[j[[2]] == 7 Sqrt[2]/2]], j[[3]],
    reviewNativeTailCovers[j[[{2, 3}]], u^(4 Sqrt[2]) Log[u], u]}],
  {True, 0, True},
  TestID -> "review-native-tail-laurent-composition-transports-native-margin"]

VerificationTest[Module[{u, sd, precision},
  sd = SeriesData[u, 0, {1, 2, 3}, 0, 3, 1];
  precision = AsymptoticInverse`Private`nativeSeriesTailPrecision[sd];
  {precision, reviewNativeTailCovers[precision, u^3 Log[u]^25, u]}],
  {{5/2, 0}, True},
  TestID -> "review-native-tail-constant-coefficients-do-not-bound-unseen-log-degree"]

VerificationTest[Module[{u, sd, precision},
  sd = SeriesData[u, 0, {1, 2, 3}, 0, 3, 2];
  precision = AsymptoticInverse`Private`nativeSeriesTailPrecision[sd];
  {precision, reviewNativeTailCovers[precision, u^(3/2) Log[u]^25, u]}],
  {{5/4, 0}, True},
  TestID -> "review-native-tail-margin-is-half-a-puiseux-lattice-step"]

VerificationTest[Module[{u, ell, sd, j},
  sd = SeriesData[u, 0, {1 + Log[u], 2}, 0, 2, 1] + u^-2;
  j = AsymptoticInverse`Private`nativePowerLogSeries[sd, u, ell, True, 2, 20000];
  {j[[{2, 3}]], Expand[reviewNativeTailExpression[j, u, ell] -
    (u^-2 + 1 + Log[u] + 2 u)] === 0}],
  {{3/2, 0}, True},
  TestID -> "review-native-tail-import-normalizes-log-coefficients-and-exact-rest"]

VerificationTest[Module[{u, v, ell},
  FailureQ[AsymptoticInverse`Private`catch[
    AsymptoticInverse`Private`nativePowerLogSeries[
      SeriesData[v, 0, {1, 2}, 0, 2, 1], u, ell, True, 2, 20000]]]],
  True, TestID -> "review-native-tail-import-rejects-an-unrelated-native-coordinate"]

VerificationTest[Module[{ell, first, second, result},
  first = {{{0, 1}, {1, ell}}, 5/2, 0};
  second = {{{0, 1}, {1, ell}, {3, Expand[(ell + 1)^3 - 3 ell^2 - 3 ell - 1]}}, 7/2, 0};
  result = AsymptoticInverse`Private`nativeRefineSeriesTail[first, second, ell, True];
  {result[[1]] === first[[1]], result[[{2, 3}]]}],
  {True, {3, 3}},
  TestID -> "review-native-tail-reconciliation-uses-the-complete-normalized-difference"]

VerificationTest[Module[{ell, first, second},
  first = {{{0, 1}, {1, ell}}, 5/2, 0};
  second = {first[[1]], 7/2, 0};
  AsymptoticInverse`Private`nativeRefineSeriesTail[first, second, ell, True][[{2, 3}]]],
  {7/2, 0},
  TestID -> "review-native-tail-empty-probe-difference-does-not-imply-exactness"]

VerificationTest[Module[{ell, first, inconsistent, weaker},
  first = {{{0, 1}, {1, ell}}, 5/2, 0};
  inconsistent = {{{0, 2}, {1, ell}, {3, 1}}, 7/2, 0};
  weaker = {first[[1]], 2, 0};
  (AsymptoticInverse`Private`nativeRefineSeriesTail[first, #, ell, True] === first) & /@
    {inconsistent, weaker}],
  {True, True},
  TestID -> "review-native-tail-reconciliation-rejects-inconsistent-or-weaker-evidence"]

VerificationTest[Module[{u, ell, j},
  j = AsymptoticInverse`Private`fwdAnalytic[Sin, {{{1, 1}}, Infinity, 0},
    Sin[u], u, ell, True, 4, 20000];
  {Expand[reviewNativeTailExpression[j, u, ell] - (u - u^3/6)] === 0,
    reviewNativeTailCovers[j[[{2, 3}]], u^5/120, u]}],
  {True, True},
  TestID -> "review-native-tail-regular-taylor-composition-remains-supported"]

VerificationTest[Module[{u, ell, j},
  j = AsymptoticInverse`Private`fwdSeries[Exp[u], u, ell, True, 2, 20000];
  {j[[{2, 3}]], Expand[reviewNativeTailExpression[j, u, ell] -
    (1 + u + u^2/2)] === 0}],
  {{3, 0}, True},
  TestID -> "review-native-tail-visible-ordinary-boundary-can-remain-sharp"]
