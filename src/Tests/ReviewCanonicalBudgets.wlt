(* P01: integer powers trim every intermediate product to the working
   cutoff, so an exact many-term operand is never expanded to a degree the
   request discards; an Automatic cutoff keeps an exact power exact. P05:
   logarithm canonicalization factors integers only within a bound and keeps
   a large composite cofactor as an opaque exact logarithm. *)

VerificationTest[
 Module[{x, e, timed, exact, forward},
  e = AsymptoticExpansion[Sum[x^k, {k, 0, 40}], {x, 0, 60}];
  timed = AbsoluteTiming[SeriesPower[e, 100, 3]];
  exact = SeriesPower[e, 3];
  forward = AbsoluteTiming[AsymptoticExpansion[(1 + x + x^2 + x^3 + x^4 + x^5 + x^6 + x^7 + x^8 + x^9 + x^10)^300, {x, 0, 3}]];
  {e["Exact"], timed[[1]] < 5, Normal[timed[[2]]] === 1 + 100 x + 5050 x^2, timed[[2]]["RemainderPower"], timed[[2]]["Cutoff"],
   exact["Exact"], Length[exact["Blocks"]], Normal[exact] === Expand[Normal[e]^3],
   forward[[1]] < 5, Normal[forward[[2]]] === 1 + 300 x + 45150 x^2, forward[[2]]["RemainderPower"]}],
 {True, True, True, 3, 3, True, 121, True, True, True, 3},
 TestID -> "integer-powers-of-exact-operands-respect-the-working-cutoff"]

VerificationTest[
 Module[{x, s, t, u},
  s = AsymptoticExpansion[(1 + x + x^2)^7 - 1, {x, 0, 4}];
  t = SeriesPower[AsymptoticExpansion[1 + x + x^2, {x, 0, 5}], 4, 4];
  u = SeriesPower[AsymptoticExpansion[Sin[x], {x, 0, 4}], 2, 5];
  {Normal[s] === 7 x + 28 x^2 + 77 x^3, s["RemainderPower"], Normal[t] === 1 + 4 x + 10 x^2 + 16 x^3, t["RemainderPower"], t["Exact"],
   Normal[u] === x^2 - x^4/3, u["RemainderPower"], u["Cutoff"]}],
 {True, 4, True, 4, False, True, 6, 5},
 TestID -> "trimmed-intermediate-products-keep-a-valid-remainder-power"]

VerificationTest[
 Module[{x, timed, p = 2^521 - 1, q = 2^607 - 1, small, prime, mixed},
  timed = AbsoluteTiming[AsymptoticExpansion[Log[p q] x + Log[8/9] x^2, {x, 0, 3}]];
  small = AsymptoticAnalysis`Private`logCanon[Log[360] + Log[7/12]];
  prime = AsymptoticAnalysis`Private`logCanon[Log[p]];
  mixed = AsymptoticAnalysis`Private`logCanon[Log[2^64 3^5 p]];
  {timed[[1]] < 30, Coefficient[Normal[timed[[2]]], x, 1] === Log[p q],
   Simplify[Coefficient[Normal[timed[[2]]], x, 2] - Log[8/9]] === 0,
   small, prime, mixed === 64 Log[2] + 5 Log[3] + Log[p],
   AsymptoticAnalysis`Private`logCanonFactor[-12], AsymptoticAnalysis`Private`logCanonFactor[p q] === {{p q, 1}},
   Expand[AsymptoticAnalysis`Private`logCanon[Log[p q] - Log[q p]]]}],
 {True, True, True, Log[2] + Log[3] + Log[5] + Log[7], Log[2^521 - 1], True, {{-1, 1}, {2, 2}, {3, 1}}, True, 0},
 TestID -> "logarithm-canonicalization-keeps-large-composite-arguments-opaque-within-its-factoring-budget"]
