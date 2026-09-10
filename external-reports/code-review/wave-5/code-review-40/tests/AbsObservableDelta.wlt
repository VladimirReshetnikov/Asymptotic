(* Prospective focused regressions for the pinned repository.
   NOT EXECUTED during this review. Load the package in a fresh kernel first.
   A conforming richer implementation may return a correct modulus expansion
   instead of the narrow patch's structured refusal; adapt those policy tests.
*)
VerificationTest[
 Module[{ell, j = {{{0, 1}, {1, I}}, Infinity, 0}},
  MatchQ[AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`fwdAbs[j, ell, True]],
    Failure["UnprovedAbsoluteValueArgument", _Association]]],
 True, TestID -> "abs-delta-complex-subleading-refused"]

VerificationTest[
 Module[{ell, j = {{{0, 1}, {1, -2}}, Infinity, 0}},
  AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`fwdAbs[j, ell, True]] === j],
 True, TestID -> "abs-delta-real-positive-unit-preserved"]

VerificationTest[
 Module[{ell, j}, j = {{{0, ell + I}}, Infinity, 0};
  MatchQ[AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`fwdAbs[j, ell, True]],
    Failure["UnprovedAbsoluteValueArgument", _Association]]],
 True, TestID -> "abs-delta-complex-log-polynomial-refused"]

VerificationTest[
 Module[{ell, j = {{}, 2, 0}},
  AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`fwdAbs[j, ell, True]] === j],
 True, TestID -> "abs-delta-pure-tail-magnitude-is-valid"]

VerificationTest[
 Module[{u, z, s, answer},
  s = AsymptoticAnalysis`AsymptoticExpansion[u, {u, 0, 4}, "Backend" -> "Package"];
  If[! MatchQ[s, AsymptoticAnalysis`GeneralizedSeries[_Association]], Return[False]];
  answer = AsymptoticAnalysis`SeriesObservable[s, Abs[1 + I z] + Abs[1 - I z], z];
  MatchQ[answer, Failure["UnprovedAbsoluteValueArgument", _Association]]],
 True, TestID -> "abs-delta-public-conjugate-pair-narrow-patch-policy"]

VerificationTest[
 Module[{u, z, s, answer},
  s = AsymptoticAnalysis`AsymptoticExpansion[u, {u, 0, 4}, "Backend" -> "Package"];
  If[! MatchQ[s, AsymptoticAnalysis`GeneralizedSeries[_Association]], Return[False]];
  answer = AsymptoticAnalysis`SeriesObservable[s, Abs[Log[z] + I] + Abs[Log[z] - I], z];
  MatchQ[answer, Failure["UnprovedAbsoluteValueArgument", _Association]]],
 True, TestID -> "abs-delta-public-log-pair-narrow-patch-policy"]

VerificationTest[
 Module[{u, z, s, answer},
  s = AsymptoticAnalysis`AsymptoticExpansion[u, {u, 0, 4}, "Backend" -> "Package"];
  If[! MatchQ[s, AsymptoticAnalysis`GeneralizedSeries[_Association]], Return[False]];
  answer = AsymptoticAnalysis`SeriesObservable[s, 1 + Abs[z], z];
  MatchQ[answer, AsymptoticAnalysis`GeneralizedSeries[_Association]] &&
   FullSimplify[Normal[answer] == 1 + u, u > 0] && answer["Remainder"] === 0],
 True, TestID -> "abs-delta-public-real-positive-control"]

VerificationTest[
 Module[{u, z, s, answer},
  s = AsymptoticAnalysis`AsymptoticExpansion[u, {u, 0, 4}, "Backend" -> "Package"];
  If[! MatchQ[s, AsymptoticAnalysis`GeneralizedSeries[_Association]], Return[False]];
  answer = AsymptoticAnalysis`SeriesObservable[s, Abs[(1 + I z) + (1 - I z)], z];
  MatchQ[answer, AsymptoticAnalysis`GeneralizedSeries[_Association]] &&
   Normal[answer] === 2 && answer["Remainder"] === 0],
 True, TestID -> "abs-delta-cancellation-inside-abs-remains-valid"]

VerificationTest[
 Module[{x, y, z, s, differentiated, modulus, final},
  s = AsymptoticAnalysis`AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 2}];
  If[! MatchQ[s, AsymptoticAnalysis`GeneralizedSeries[_Association]], Return[False]];
  differentiated = AsymptoticAnalysis`SeriesDifferentiate[s, 1, "RemainderDerivativeOrder" -> 2];
  If[! MatchQ[differentiated, AsymptoticAnalysis`GeneralizedSeries[_Association]], Return[False]];
  modulus = AsymptoticAnalysis`SeriesObservable[differentiated, Abs[z - 1], z];
  If[! MatchQ[modulus, AsymptoticAnalysis`GeneralizedSeries[_Association]], Return[False]];
  final = AsymptoticAnalysis`SeriesDifferentiate[modulus];
  modulus["Remainder"] =!= 0 &&
   MatchQ[final, Failure["UnprovedRemainderDerivative", _Association]]],
 True, TestID -> "abs-delta-uncertain-modulus-does-not-inherit-derivatives"]
