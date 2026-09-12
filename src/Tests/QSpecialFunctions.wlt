(* q-special functions: QPochhammer, QGamma, QFactorial and QBinomial in the
   three regimes the vendored q-series monograph and the Gaussian coefficient
   calculus treat (chapters 2-5 of the monograph, chapter "Three distinct
   asymptotic regimes" of the calculus). The expected coefficients below are
   the articles' displayed formulas, not package output: the fixed-argument
   q -> 1 expansion with its dilogarithmic scale and Bernoulli/polylogarithm
   corrections, the rigorous large-log base inverse, the coalescing
   expansion, the all-order q -> 1 expansion of the q-gamma function and its
   reversion, the complete Gaussian logarithmic expansion, the literal Taylor
   coordinate corollary, the ordinary Gaussian inverse, the finite-product
   base inverse, the exact coefficient engine at q = 0, the stable
   small-base jet, the endpoint argument jets, the zero-derivative germs,
   and the fixed-base large-argument expansions. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

qTestEqual[a_, b_, ass_: True] := TrueQ[FullSimplify[a == b, ass]];
qTestTerms[s_, expected_, ass_: True] := Length[s["Terms"]] === Length[expected] &&
  And @@ MapThread[TrueQ[Simplify[#1[[1]] == #2[[1]]]] && TrueQ[FullSimplify[#1[[2]] == #2[[2]], ass]] &, {s["Terms"], expected}];
(* Sum[j^m, {j, 0, n - 1}] *)
qTestPowerSum[m_, n_] := (BernoulliB[m + 1, n] - BernoulliB[m + 1])/(m + 1);

(* --- fixed argument, q -> 1: monograph "Uniform all-order fixed-argument expansion" --- *)
VerificationTest[
  Module[{a, t, s},
    s = AsymptoticExpansion[Log[QPochhammer[a, Exp[-t]]], {t, 0, 5}, Assumptions -> -1 < a < 1];
    {s["Kind"], qTestTerms[s, {{-1, -PolyLog[2, a]}, {0, Log[1 - a]/2}, {1, -a/(12 (1 - a))},
       {3, a (1 + a)/(720 (1 - a)^3)}}, -1 < a < 1], s["RemainderPower"]}],
  {"Forward", True, 5},
  TestID -> "q-special-fixed-argument-logarithmic-expansion-dilogarithm-scale-and-Bernoulli-polylog-terms"]

VerificationTest[
  Module[{t, s},
    s = AsymptoticExpansion[QPochhammer[1/2, Exp[-t]], {t, 0, 4}];
    {s["Scale"], qTestEqual[s["Prefactor"], Exp[-PolyLog[2, 1/2]/t]/Sqrt[2], t > 0],
     qTestTerms[s, {{0, 1}, {1, -1/12}, {2, 1/288}, {3, 1/120 - 1/10368}}],
     s["ExpansionNature"], s["RemainderVariable"], s["RemainderPower"],
     TrueQ[Abs[N[(Normal[s] /. t -> 1/100)/QPochhammer[1/2, Exp[-1/100]] - 1, 30]] < 10^-8]}],
  {"Factored", True, True, "Poincare", t, 4, True} /. t -> _Symbol, SameTest -> MatchQ,
  TestID -> "q-special-fixed-argument-product-factored-expansion-agrees-with-the-monograph-and-numerically"]

(* the same expansion in the base coordinate u = 1 - q and for a real argument below -1 *)
VerificationTest[
  Module[{u, t, s1, s2},
    s1 = AsymptoticExpansion[QPochhammer[1/2, 1 - u], {u, 0, 3}];
    s2 = AsymptoticExpansion[QPochhammer[-3, Exp[-t]], {t, 0, 3}];
    {s1["Scale"], TrueQ[Abs[N[(Normal[s1] /. u -> 1/200)/QPochhammer[1/2, 1 - 1/200] - 1, 30]] < 10^-6],
     qTestTerms[s2, {{0, 1}, {1, 1/16}, {2, 1/512}}], qTestEqual[s2["Prefactor"], 2 Exp[-PolyLog[2, -3]/t], t > 0]}],
  {"Factored", True, True, True},
  TestID -> "q-special-fixed-argument-product-in-the-base-coordinate-and-below-minus-one"]

(* --- rigorous large-log base inverse: t = A/X + D A^2/X^3 + A^3 (2 D^2 - A E)/X^5 --- *)
VerificationTest[
  Module[{t, y, X, s, a = 1/2, A, D, E1, expanded, expected},
    s = AsymptoticInverse[QPochhammer[a, Exp[-t]], {t, 0}, {y, 6}];
    A = PolyLog[2, a]; D = PolyLog[0, a]/12; E1 = PolyLog[-2, a]/720;
    expanded = Normal[Series[Normal[s] /. Log[y] -> -X + Log[1 - a]/2 /. X -> 1/X, {X, 0, 5}]] /. X -> 1/X;
    expected = A/X + D A^2/X^3 + A^3 (2 D^2 - A E1)/X^5;
    {s["Scale"], s["CoordinateKind"], FullSimplify[expanded - expected], s["RemainderPower"]}],
  {"Transformed", "TargetLog", 0, 6},
  TestID -> "q-special-large-log-base-inverse-odd-powers-agree-with-the-monograph-through-X-to-minus-five"]

VerificationTest[
  Module[{t, y, s, check},
    s = AsymptoticInverse[QPochhammer[1/2, Exp[-t]], {t, 0}, {y, 4}];
    check = InverseNumericalCheck[s, 1/1000];
    {check["Ratio"] < 1, check["Error"] < 10^-4, TrueQ[check["PhaseResidual"] == 0]}],
  {True, True, True},
  TestID -> "q-special-large-log-base-inverse-numerical-check-within-remainder-scale"]

(* --- Euler's product and the coalescing parameter a = q^x --- *)
VerificationTest[
  Module[{t, s},
    s = AsymptoticExpansion[QPochhammer[Exp[-t], Exp[-t]], {t, 0, 3}];
    {qTestEqual[s["Prefactor"], Sqrt[2 Pi/t] Exp[-Pi^2/(6 t)], t > 0], qTestTerms[s, {{0, 1}, {1, 1/24}, {2, 1/1152}}]}],
  {True, True},
  TestID -> "q-special-euler-product-near-one-sqrt-two-pi-over-t-scale-and-exp-t-over-24"]

VerificationTest[
  Module[{t, x, s},
    s = AsymptoticExpansion[Log[QPochhammer[Exp[-x t], Exp[-t]]], {t, 0, 3}, Assumptions -> x > 0];
    qTestTerms[s, {{-1, -Pi^2/6}, {0, Log[2 Pi]/2 - Log[Gamma[x]] + (1/2 - x) Log[t]},
      {1, BernoulliB[2, x]/4}, {2, -BernoulliB[2] BernoulliB[3, x]/(2 3!)}}, x > 0 && t > 0]],
  True,
  TestID -> "q-special-coalescing-expansion-logarithmic-terms-agree-with-the-monograph"]

VerificationTest[
  Module[{q, y, s, t0 = 1/300},
    s = AsymptoticInverse[QPochhammer[q, q], {q, 1}, {y, 3}, Direction -> "FromBelow"];
    {s["Scale"], TrueQ[Abs[N[(Normal[s] /. y -> QPochhammer[1 - t0, 1 - t0]) - (1 - t0), 30]] < 10^-5]}],
  {"Transformed", True},
  TestID -> "q-special-euler-product-base-inverse-from-below-numerically"]

(* --- q-gamma near q = 1: "All-order q -> 1 expansion" and its reversion --- *)
VerificationTest[
  Module[{t, x, s},
    s = AsymptoticExpansion[Log[QGamma[x, Exp[-t]]], {t, 0, 3}, Assumptions -> x > 0];
    qTestTerms[s, {{0, Log[Gamma[x]]}, {1, (x - 1) (2 - x)/4}, {2, (x - 2) (x - 1) (2 x + 3)/144}}, x > 0]],
  True,
  TestID -> "q-special-q-gamma-near-one-logarithmic-coefficients-c1-and-c2"]

VerificationTest[
  Module[{t, v, x = 7/2, c1, c2, s},
    c1 = (x - 1) (2 - x)/4; c2 = (x - 2) (x - 1) (2 x + 3)/144;
    s = AsymptoticInverse[Log[QGamma[x, Exp[-t]]/Gamma[x]], {t, 0}, {v, 4}];
    {qTestEqual[Normal[s], v/c1 - c2 v^2/c1^3 + 2 c2^2 v^3/c1^5], s["RemainderPower"]}],
  {True, 4},
  TestID -> "q-special-q-gamma-base-inverse-ordinary-reversion-of-the-monograph"]

VerificationTest[
  Module[{t, y, s, t0 = 1/200},
    s = AsymptoticExpansion[QGamma[x, Exp[-t]], {t, 0, 3}, Assumptions -> x > 0];
    {s["Kind"], qTestTerms[s, {{0, Gamma[x]}, {1, Gamma[x] (x - 1) (2 - x)/4},
       {2, Gamma[x] ((x - 2) (x - 1) (2 x + 3)/144 + (x - 1)^2 (2 - x)^2/32)}}, x > 0],
     TrueQ[Abs[N[(Normal[s] /. {x -> 7/2, t -> t0})/QGamma[7/2, Exp[-t0]] - 1, 30]] < 10^-6]}],
  {"Forward", True, True},
  TestID -> "q-special-q-gamma-near-one-symbolic-argument-forward-expansion"]

(* --- Gaussian binomials near q = 1: complete logarithmic expansion, literal
   Taylor coordinate, ordinary inverse --- *)
VerificationTest[
  Module[{t, n, k, s, ass, d, delta4},
    ass = Element[n, Integers] && Element[k, Integers] && 0 <= k <= n;
    d = k (n - k);
    delta4 = qTestPowerSum[4, n + 1] - qTestPowerSum[4, k + 1] - qTestPowerSum[4, n - k + 1];
    s = AsymptoticExpansion[Log[QBinomial[n, k, Exp[-t]]], {t, 0, 5}, Assumptions -> ass];
    qTestTerms[s, {{0, Log[Binomial[n, k]]}, {1, -d/2}, {2, d (n + 1)/24}, {4, BernoulliB[4] delta4/(4 4!)}}, ass]],
  True,
  TestID -> "q-special-gaussian-binomial-complete-logarithmic-expansion-has-no-cubic-term"]

VerificationTest[
  Module[{u, n, k, s, ass, d, expected},
    ass = Element[n, Integers] && Element[k, Integers] && 0 <= k <= n;
    d = k (n - k);
    (* h = q - 1 = -u in the corollary "Literal Taylor coordinate" *)
    expected = Binomial[n, k] (1 - d u/2 + d (3 d + n - 5)/24 u^2 - d (d - 2) (d + n - 3)/48 u^3);
    s = AsymptoticExpansion[QBinomial[n, k, 1 - u], {u, 0, 4}, Assumptions -> ass];
    {s["Kind"], Simplify[Expand[Normal[s] - expected]], s["RemainderPower"]}],
  {"Forward", 0, 4},
  TestID -> "q-special-gaussian-binomial-literal-taylor-coordinate-corollary"]

VerificationTest[
  Module[{t, v, s, n = 9, k = 4, d, delta2},
    d = k (n - k); delta2 = d (n + 1);
    s = AsymptoticInverse[Log[QBinomial[n, k, Exp[-t]]/Binomial[n, k]], {t, 0}, {v, 4}];
    qTestEqual[Normal[s], -2 v/d + delta2 v^2/(3 d^3) - delta2^2 v^3/(9 d^5)]],
  True,
  TestID -> "q-special-gaussian-binomial-ordinary-inverse-at-q-equal-one"]

(* --- q-factorials: q -> 1 forward for symbolic n and the zero-base inverse --- *)
VerificationTest[
  Module[{t, n, q, y, s, ass, inverse},
    ass = Element[n, Integers] && n >= 0;
    s = AsymptoticExpansion[Log[QFactorial[n, Exp[-t]]], {t, 0, 3}, Assumptions -> ass];
    inverse = AsymptoticInverse[QFactorial[5, q], {q, 0}, {y, 3}];
    {qTestTerms[s, {{0, Log[Gamma[n + 1]]}, {1, -n (n - 1)/4}, {2, (n (n + 1) (2 n + 1)/6 - n)/24}}, ass],
     qTestEqual[Normal[inverse], (y - 1)/4 - 9 (y - 1)^2/64]}],
  {True, True},
  TestID -> "q-special-q-factorial-near-one-and-the-zero-base-factorial-inverse"]

(* --- finite products: base inverse at q = 1 and the exact coefficient engine at q = 0 --- *)
VerificationTest[
  Module[{t, u, s, a = 1/3, n = 5, c},
    c[m_] := (-1)^(m + 1)/m! PolyLog[1 - m, a] qTestPowerSum[m, n];
    s = AsymptoticInverse[Log[QPochhammer[a, Exp[-t], n]/(1 - a)^n], {t, 0}, {u, 4}];
    qTestEqual[Normal[s], u/c[1] - c[2] u^2/c[1]^3 + (2 c[2]^2/c[1]^5 - c[3]/c[1]^4) u^3]],
  True,
  TestID -> "q-special-finite-product-all-order-regular-base-inverse-at-q-equal-one"]

VerificationTest[
  Module[{q, y, eta, a = 1/3, finite, infinite, expand, expected5, expected6},
    expand[s_, order_] := Normal[Series[Normal[s] /. y -> (1 - a) - a (1 - a) eta, {eta, 0, order}]];
    finite = AsymptoticInverse[QPochhammer[a, q, 6], {q, 0}, {y, 6}];
    infinite = AsymptoticInverse[QPochhammer[a, q], {q, 0}, {y, 7}];
    expected5 = eta - eta^2 + (1 + a) eta^3 - (1 + 4 a) eta^4 + (1 + 11 a + 3 a^2) eta^5;
    expected6 = expected5 - (1 + 26 a + 22 a^2) eta^6;
    {Expand[expand[finite, 5] - expected5], Expand[expand[infinite, 6] - expected6]}],
  {0, 0},
  TestID -> "q-special-exact-coefficient-engine-and-stable-small-base-jet-at-q-equal-zero"]

(* --- argument inverses at a fixed base: endpoint jets and zero germs --- *)
VerificationTest[
  Module[{a, y, q = 1/2, s, one, two, C, L1},
    s = AsymptoticInverse[QPochhammer[a, q], {a, 0}, {y, 4}];
    C = QPochhammer[q, q]; L1 = Sum[q^j/(1 - q^j), {j, 1, 300}];
    one = AsymptoticInverse[QPochhammer[a, q], {a, 1}, {y, 3}, Direction -> "FromBelow"];
    two = AsymptoticInverse[QPochhammer[a, q], {a, 2}, {y, 2}];
    {qTestEqual[Normal[s], (1 - q) (1 - y) + q (1 - q)/(1 + q) (1 - y)^2 + q^2 (1 - q) (q^2 + q + 2)/((1 + q)^2 (q^2 + q + 1)) (1 - y)^3],
     (* both sides are evaluated separately: N of an exact zero difference
        stops at the extra-precision limit *)
     TrueQ[Abs[N[Coefficient[Normal[one], y, 1], 30] + N[1/C, 30]] < 10^-25],
     TrueQ[Abs[N[Coefficient[Normal[one], y, 2], 30] - N[L1/C^2, 30]] < 10^-25],
     (* d_1 = (q; q)_1 (q; q)_inf at the zero a = q^-1 = 2 *)
     TrueQ[Abs[N[Coefficient[Normal[two], y, 1], 30] - N[1/((1 - q) C), 30]] < 10^-25], two["ExpansionPoint"]}],
  {True, True, True, True, 2},
  TestID -> "q-special-argument-inverses-endpoint-jets-and-zero-derivative-germ"]

(* --- fixed base, growing argument: q-gamma, central and fixed-column Gaussian binomials --- *)
VerificationTest[
  Module[{x, s, C = QPochhammer[1/2, 1/2]},
    s = AsymptoticExpansion[QGamma[x, 1/2], {x, Infinity, 3}];
    {s["Kind"], s["Scale"], qTestEqual[Normal[s], C (2^(x - 1) + 1 + 4/3 2^-x + 32/21 2^(-2 x))],
     s["RemainderVariable"], s["RemainderPower"], s["Terms"][[All, 1]],
     TrueQ[Abs[N[(Normal[s] /. x -> 40)/QGamma[40, 1/2] - 1, 40]] < 10^-40]}],
  {"Forward", "Transformed", True, 2^-x, 3, {-1, 0, 1, 2}, True} /. x -> _Symbol, SameTest -> MatchQ,
  TestID -> "q-special-q-gamma-fixed-base-large-argument-chart-expansion"]

VerificationTest[
  Module[{n, central, column, q = 1/2},
    central = AsymptoticExpansion[QBinomial[2 n, n, q], {n, Infinity, 2}];
    column = AsymptoticExpansion[QBinomial[n, 3, q], {n, Infinity, 2}];
    (* (q^4; q)_inf / (q; q)_inf = 1/(q; q)_3 is checked numerically: the
       simplifier does not prove the finite cancellation symbolically *)
    {qTestEqual[Normal[central], (1 - 2 q^(n + 1)/(1 - q))/QPochhammer[q, q]],
     column["Terms"][[All, 1]],
     TrueQ[Abs[N[column["Terms"][[1, 2]], 30] - N[1/QPochhammer[q, q, 3], 30]] < 10^-25],
     TrueQ[Abs[N[column["Terms"][[2, 2]], 30] + N[q^(-2) (1 + q + q^2)/QPochhammer[q, q, 3], 30]] < 10^-25],
     column["RemainderVariable"]}],
  {True, {0, 1}, True, True, 2^-n} /. n -> _Symbol, SameTest -> MatchQ,
  TestID -> "q-special-gaussian-binomials-fixed-base-both-large-and-fixed-column"]

VerificationTest[
  Module[{x, y, s, check, C = QPochhammer[1/2, 1/2]},
    s = AsymptoticInverse[QGamma[x, 1/2], {x, Infinity}, {y, 3}];
    check = InverseNumericalCheck[s, 10^12];
    {s["Scale"], s["CoordinateKind"], qTestEqual[Normal[s], Log[2 y/C]/Log[2] - C/(y Log[2]) - 7 C^2/(y^2 Log[64]), y > 0],
     check["Ratio"] < 1, check["Error"] < 10^-20}],
  {"Transformed", "SourceLog", True, True, True},
  TestID -> "q-special-q-gamma-fixed-base-argument-inverse-through-the-exponential-chart"]

(* --- refusals and result operations --- *)
VerificationTest[
  Module[{t, x, a, n},
    {AsymptoticExpansion[QPochhammer[2, Exp[-t]], {t, 0, 3}][[1]],
     AsymptoticExpansion[QGamma[x, Exp[-t]], {t, 0, 3}][[1]],
     AsymptoticExpansion[QFactorial[n, Exp[-t]], {t, 0, 3}][[1]],
     AsymptoticExpansion[QGamma[x, a], {x, Infinity, 2}, Assumptions -> 0 < a < 1][[1]]}],
  {"UnsupportedQArgument", "UnsupportedQArgument", "UnsupportedQArgument", "UnsupportedQArgument"},
  TestID -> "q-special-unproved-parameter-conditions-are-refused-with-one-tag"]

VerificationTest[
  Module[{t, a, s, refined, simplified},
    s = AsymptoticExpansion[QPochhammer[1/2, Exp[-t]], {t, 0, 2}];
    refined = SeriesRefine[s, 4];
    simplified = Simplify[AsymptoticExpansion[QPochhammer[a, Exp[-t]], {t, 0, 3}, Assumptions -> -1 < a < 1]];
    {refined["RemainderPower"], qTestTerms[refined, {{0, 1}, {1, -1/12}, {2, 1/288}, {3, 1/120 - 1/10368}}],
     qTestEqual[simplified["Prefactor"], Sqrt[1 - a] Exp[-PolyLog[2, a]/t], -1 < a < 1 && t > 0],
     qTestTerms[simplified, {{0, 1}, {1, -a/(12 (1 - a))}, {2, a^2/(288 (1 - a)^2)}}, -1 < a < 1]}],
  {4, True, True, True},
  TestID -> "q-special-results-refine-and-simplify"]

(* --- q-digamma and q-polygamma, q -> 1: monograph "Global argument inverse and the exceptional reciprocal fold" --- *)
VerificationTest[
  Module[{x, t, s0, s1},
    s0 = AsymptoticExpansion[QPolyGamma[x, Exp[-t]], {t, 0, 4}, Assumptions -> x > 0];
    s1 = AsymptoticExpansion[QPolyGamma[1, x, Exp[-t]], {t, 0, 3}, Assumptions -> x > 0];
    (* psi_q = psi + (3 - 2x)/4 t + c2'(x) t^2 with c2 = (x - 2)(x - 1)(2x + 3)/144; no t^3 term *)
    {s0["Kind"], qTestTerms[s0, {{0, PolyGamma[0, x]}, {1, (3 - 2 x)/4}, {2, (6 x^2 - 6 x - 5)/144}}, x > 0],
     qTestTerms[s1, {{0, PolyGamma[1, x]}, {1, -1/2}, {2, (2 x - 1)/24}}, x > 0]}],
  {"Forward", True, True},
  TestID -> "q-special-q-polygamma-q-to-one-expansion-differentiates-the-q-gamma-coefficients"]

VerificationTest[
  Module[{t, d, s, inv, t0 = 1/100, d0},
    s = AsymptoticExpansion[QPolyGamma[3/2, Exp[-t]], {t, 0, 4}];
    inv = AsymptoticInverse[QPolyGamma[3/2, Exp[-t]] - PolyGamma[0, 3/2], {t, 0}, {d, 2}];
    d0 = N[QPolyGamma[3/2, Exp[-t0]] - PolyGamma[0, 3/2], 40];
    (* the fold: Delta = -t^2/288 + O(t^4), t = Sqrt[-288 Delta] (1 + O(Delta)) *)
    {qTestTerms[s, {{0, PolyGamma[0, 3/2]}, {2, -1/288}}], inv["Terms"][[1, 1]], d0 < 0,
     TrueQ[Abs[N[Normal[inv] /. d -> d0, 30] - t0] < 10^-7]}],
  {True, 1/2, True, True},
  TestID -> "q-special-q-digamma-quadratic-endpoint-at-three-halves-inverts-as-a-square-root-fold"]

(* --- q-polygamma at a fixed base: the Lambert series in q^x --- *)
VerificationTest[
  Module[{x, y, s, s2, inv, check},
    s = AsymptoticExpansion[QPolyGamma[x, 1/2], {x, Infinity, 3}];
    s2 = AsymptoticExpansion[QPolyGamma[2, 2 x + y, 1/3], {x, Infinity, 5}, Assumptions -> y > 0];
    inv = AsymptoticInverse[QPolyGamma[x, 1/2], {x, Infinity}, {y, 3}];
    check = InverseNumericalCheck[inv, N[QPolyGamma[30, 1/2], 60]];
    (* psi_q(x) = -Log[1 - q] + Log[q] Sum[q^(m x)/(1 - q^m)], psi_q''(z) = Log[q]^3 Sum[m^2 q^(m z)/(1 - q^m)] *)
    {s["Scale"], qTestTerms[s, {{0, Log[2]}, {1, -2 Log[2]}, {2, -4 Log[2]/3}}], s["RemainderVariable"],
     qTestTerms[s2, {{2, -3 Log[3]^3 3^-y/2}, {4, -9 Log[3]^3 3^(-2 y)/2}}, y > 0],
     qTestEqual[Normal[inv], Log[Log[4]]/Log[2] - Log[Log[2] - y]/Log[2] + (Log[2] - y)/(3 Log[2]^2) - (Log[2] - y)^2/(42 Log[2]^3), y < Log[2]],
     check["Ratio"] < 1, TrueQ[Abs[check["ExactInverse"] - 30] < 10^-20]}],
  {"Transformed", True, 2^-x, True, True, True, True} /. x -> _Symbol, SameTest -> MatchQ,
  TestID -> "q-special-q-polygamma-fixed-base-lambert-series-forward-and-inverse"]

(* --- q-beta function B_q(x, y) = Gamma_q(x) Gamma_q(y)/Gamma_q(x + y): monograph "Coordinate monotonicity and base type change" --- *)
VerificationTest[
  Module[{x, y, t, s},
    s = AsymptoticExpansion[Log[QGamma[x, Exp[-t]] QGamma[y, Exp[-t]]/QGamma[x + y, Exp[-t]]], {t, 0, 4}, Assumptions -> x > 0 && y > 0];
    {qTestTerms[s, {{0, Log[Gamma[x] Gamma[y]/Gamma[x + y]]}, {1, (x y - 1)/2}, {2, -(x^2 y + x y^2 - x y - 1)/24}}, x > 0 && y > 0]}],
  {True},
  TestID -> "q-special-q-beta-q-to-one-logarithmic-expansion-b1-and-b2"]

VerificationTest[
  Module[{x, t, y, inv, x0 = 3, t0 = 1/100, y0},
    inv = AsymptoticInverse[QGamma[x, Exp[-t]] QGamma[1/x, Exp[-t]]/QGamma[x + 1/x, Exp[-t]], {t, 0}, {y, 2}, Assumptions -> x > 1];
    y0 = N[QGamma[x0, Exp[-t0]] QGamma[1/x0, Exp[-t0]]/QGamma[x0 + 1/x0, Exp[-t0]], 40];
    (* on x y = 1 the linear coefficient vanishes: t = Sqrt[-24 x Delta/(x - 1)^2] (1 + O(Delta)) *)
    {inv["Terms"][[1, 1]], TrueQ[Abs[N[Normal[inv] /. {x -> x0, y -> y0}, 30] - t0] < 10^-7]}],
  {1/2, True},
  TestID -> "q-special-q-beta-base-inverse-on-the-reciprocal-curve-is-a-square-root-fold"]

VerificationTest[
  Module[{x, y, z, s, inv, x0 = 30, y0 = 1/2, z0},
    s = AsymptoticExpansion[QGamma[x, 1/3] QGamma[y, 1/3]/QGamma[x + y, 1/3], {x, Infinity, 2}, Assumptions -> y > 0];
    inv = AsymptoticInverse[QGamma[x, 1/3] QGamma[y, 1/3]/QGamma[x + y, 1/3], {x, Infinity}, {z, 2}, Assumptions -> y > 0];
    z0 = N[QGamma[x0, 1/3] QGamma[y0, 1/3]/QGamma[x0 + y0, 1/3], 40];
    (* B_q(x, y) = (1 - q)^y Gamma_q(y) (q^y w; q)_inf/(w; q)_inf, w = q^x *)
    {s["Scale"], qTestTerms[s, {{0, (2/3)^y QGamma[y, 1/3]}, {1, (2/3)^(y - 1) (1 - 3^-y) QGamma[y, 1/3]}}, y > 0],
     inv["CoordinateKind"], TrueQ[Abs[N[Normal[inv] /. {y -> y0, z -> z0}, 30] - x0] < 10^-6]}],
  {"Transformed", True, "SourceLog", True},
  TestID -> "q-special-q-beta-fixed-base-argument-expansion-and-inverse-through-the-chart"]

(* --- symbolic product lengths near q = 0: monograph "Exact coefficient engine at q = 0", "Zero-base factorial inverse" --- *)
VerificationTest[
  Module[{n, k, a, q, y, sf, sp, sb, sg, inv},
    sf = AsymptoticExpansion[QFactorial[n, q], {q, 0, 4}, Assumptions -> Element[n, Integers] && n >= 5];
    sp = AsymptoticExpansion[QPochhammer[a, q, n], {q, 0, 5}, Assumptions -> Element[n, Integers] && n >= 6 && Element[a, Reals], "Backend" -> "Package"];
    sb = AsymptoticExpansion[QBinomial[n, k, q], {q, 0, 5}, Assumptions -> Element[n, Integers] && Element[k, Integers] && k >= 5 && n - k >= 5];
    sg = AsymptoticExpansion[QGamma[n, q], {q, 0, 3}, Assumptions -> Element[n, Integers] && n >= 5];
    inv = AsymptoticInverse[QFactorial[n, q], {q, 0}, {y, 3}, Assumptions -> Element[n, Integers] && n >= 5];
    {qTestEqual[Normal[sf], 1 + (n - 1) q + (n - 2) (n + 1)/2 q^2 + n (n^2 - 7)/6 q^3],
     Expand[Normal[sp] - Normal[Series[QPochhammer[a, q, 9], {q, 0, 4}]]],
     Normal[sb], Expand[(Normal[sg] /. n -> 6) - Normal[Series[QGamma[6, q], {q, 0, 2}]]],
     qTestEqual[Normal[inv], (y - 1)/(n - 1) - (n - 2) (n + 1) (y - 1)^2/(2 (n - 1)^3), Element[n, Integers] && n >= 5]}],
  {True, 0, 1 + q + 2 q^2 + 3 q^3 + 5 q^4, 0, True} /. q -> _Symbol, SameTest -> MatchQ,
  TestID -> "q-special-symbolic-product-lengths-near-base-zero-use-the-stable-coefficients"]

VerificationTest[
  Module[{n, q, capped, bounded, unbounded},
    unbounded = AsymptoticExpansion[QFactorial[n, q], {q, 0, 3}, Assumptions -> Element[n, Integers]];
    capped = AsymptoticExpansion[QFactorial[n, q], {q, 0, 4}, Assumptions -> Element[n, Integers] && n >= 2];
    bounded = AsymptoticExpansion[QFactorial[n, q], {q, 0, 2}, Assumptions -> Element[n, Integers] && n >= 2];
    (* the coefficient of q^r is stable once n >= r: n >= 2 proves two orders and no more *)
    {unbounded[[1]], capped[[1]], capped[[2]]["Reached"], bounded["Terms"]}],
  {"UnsupportedQArgument", "InsufficientOrder", 3, {{0, 1}, {1, -1 + n}}} /. n -> _Symbol, SameTest -> MatchQ,
  TestID -> "q-special-symbolic-length-orders-are-limited-by-the-proved-length-bound"]

(* --- double scaling q = Exp[-tau/n], k = alpha n: Gaussian coefficient calculus "Uniform all-order logarithmic expansion" --- *)
VerificationTest[
  Module[{n, a, t, y, s, sl, sf, inv, h, hd, S, C1, nn = 400, y0},
    h[tau_, x_] := Log[(1 - Exp[-tau x])/(tau x)];
    hd[tau_, x_] := tau Exp[-tau x]/(1 - Exp[-tau x]) - 1/x;
    S[tau_, al_] := (PolyLog[2, Exp[-tau]] - PolyLog[2, Exp[-tau al]] - PolyLog[2, Exp[-tau (1 - al)]] + Pi^2/6)/tau;
    C1 = BernoulliB[2]/2 (1 - 2 - 2) + BernoulliB[2]/2 (hd[2, 1] - 2 hd[2, 1/2] - 1);
    s = AsymptoticExpansion[QBinomial[n, n/2, Exp[-2/n]], {n, Infinity, 3}];
    sl = AsymptoticExpansion[Log[QBinomial[n, a n, Exp[-t/n]]], {n, Infinity, 4}, Assumptions -> 0 < a < 1 && t > 0];
    sf = AsymptoticExpansion[QFactorial[n, Exp[-2/n]], {n, Infinity, 2}];
    inv = AsymptoticInverse[QBinomial[n, n/2, Exp[-2/n]], {n, Infinity}, {y, 2}];
    y0 = N[QBinomial[nn, nn/2, Exp[-2/nn]], 60];
    {s["Scale"], s["ExpansionNature"],
     qTestEqual[s["Prefactor"], Exp[n S[2, 1/2]] Sqrt[2 (1 - Exp[-2])/(2 Pi n (1 - Exp[-1])^2)], n > 0],
     qTestTerms[s, {{0, 1}, {1, C1}, {2, C1^2/2}}],
     TrueQ[Abs[N[(Normal[s] /. n -> nn)/QBinomial[nn, nn/2, Exp[-2/nn]] - 1, 30]] < 10^-8],
     sl["Kind"], qTestEqual[sl["Terms"][[1, 2]], S[t, a], 0 < a < 1 && t > 0], sl["Terms"][[1, 1]],
     TrueQ[Abs[N[(Normal[sl] /. {n -> nn, a -> 1/4, t -> 3}) - Log[QBinomial[nn, nn/4, Exp[-3/nn]]], 30]] < 10^-10],
     TrueQ[Abs[N[(Normal[sf] /. n -> nn)/QFactorial[nn, Exp[-2/nn]] - 1, 30]] < 10^-7],
     inv["CoordinateKind"], TrueQ[Abs[N[Normal[inv] /. y -> y0, 30] - nn] < 10^-3]}],
  {"Factored", "Poincare", True, True, True, "Forward", True, -1, True, True, "TargetLog", True},
  TestID -> "q-special-double-scaling-gaussian-binomial-and-q-factorial-euler-maclaurin-expansions-and-inverse"]

(* --- varying arguments: the Euler q-exponentials (monograph "Exact inverse reduction and q -> 1 generator") --- *)
VerificationTest[
  Module[{h, x, y, e, ee, inv},
    e = AsymptoticExpansion[Log[1/QPochhammer[h x, 1 - h]], {h, 0, 3}, Assumptions -> x > 0];
    ee = AsymptoticExpansion[Log[QPochhammer[-h x, 1 - h]], {h, 0, 3}, Assumptions -> x > 0];
    inv = AsymptoticInverse[1/QPochhammer[h x, 1 - h], {h, 0}, {y, 2}, Assumptions -> x > 0];
    (* log e_q(x) = x + x^2 h/4 + (x^2/8 + x^3/9) h^2, log E_q(x) = x - x^2 h/4 + (-x^2/8 + x^3/9) h^2 *)
    {qTestTerms[e, {{0, x}, {1, x^2/4}, {2, x^2/8 + x^3/9}}, x > 0], qTestTerms[ee, {{0, x}, {1, -x^2/4}, {2, -x^2/8 + x^3/9}}, x > 0],
     qTestEqual[Normal[inv], 4 (Log[y] - x)/x^2, x > 0]}],
  {True, True, True},
  TestID -> "q-special-q-exponentials-expand-through-the-varying-argument-product-model"]

(* --- the real radial approach to q = -1 (monograph "Exact eta completions", negative radial path) --- *)
VerificationTest[
  Module[{a, q, s, q0 = -999/1000},
    s = AsymptoticExpansion[QPochhammer[a, q], {q, -1, 3}, Assumptions -> -1 < a < 1, Direction -> "FromAbove"];
    (* (a; q)_inf = (a; q^2)_inf (a q; q^2)_inf with both bases tending to 1 from below *)
    {s["Scale"], qTestEqual[s["QSpecialFactors"][[All, "Function"]], {QPochhammer[a, q^2], QPochhammer[a q, q^2]}],
     TrueQ[Abs[N[(Normal[s] /. {a -> 1/3, q -> q0})/QPochhammer[1/3, q0] - 1, 30]] < 10^-7]}],
  {"Factored", True, True},
  TestID -> "q-special-infinite-product-near-base-minus-one-separates-even-and-odd-factors"]

(* --- varying lengths: finite products, q-gamma and Gaussian binomials rewritten through infinite products --- *)
VerificationTest[
  Module[{n, u, x, y, nn = 400, sp, sc, sb, sg, sv, pv, inv, err, relative},
    err[s_, f_] := Abs[N[(Normal[s] /. n -> nn) - (f /. n -> nn), 30]];
    relative[s_, f_] := Abs[N[(Normal[s] /. n -> nn)/(f /. n -> nn) - 1, 30]];
    sp = AsymptoticExpansion[QPochhammer[1/3, Exp[-2/n], n], {n, Infinity, 2}];
    sc = AsymptoticExpansion[Log[QPochhammer[Exp[-3/n], Exp[-2/n], n]], {n, Infinity, 2}];
    sb = AsymptoticExpansion[QBinomial[n, n/2, Exp[-2/n - 1/n^2]], {n, Infinity, 2}];
    sg = AsymptoticExpansion[Log[QGamma[n, Exp[-2/n]]], {n, Infinity, 2}];
    sv = AsymptoticExpansion[QGamma[2 + u, 1 - u], {u, 0, 3}];
    pv = AsymptoticExpansion[QPolyGamma[2 + u, 1 - u], {u, 0, 2}];
    inv = AsymptoticInverse[QPochhammer[1/3, Exp[-2/n], n], {n, Infinity}, {y, 1}];
    {sp["QSpecialFactors"][[1, "Model"]], relative[sp, QPochhammer[1/3, Exp[-2/n], n]] < 10^-7,
     err[sc, Log[QPochhammer[Exp[-3/n], Exp[-2/n], n]]] < 10^-5, sb["QSpecialFactors"][[1, "Model"]],
     relative[sb, QBinomial[n, n/2, Exp[-2/n - 1/n^2]]] < 10^-6, err[sg, Log[QGamma[n, Exp[-2/n]]]] < 10^-5,
     sv["Kind"], TrueQ[Abs[N[(Normal[sv] /. u -> 1/100) - QGamma[2 + 1/100, 1 - 1/100], 30]] < 10^-5],
     TrueQ[Abs[N[(Normal[pv] /. u -> 1/100) - QPolyGamma[2 + 1/100, 1 - 1/100], 30]] < 10^-3],
     inv["CoordinateKind"], TrueQ[Abs[N[Normal[inv] /. y -> N[QPochhammer[1/3, Exp[-2/nn], nn], 60], 30] - nn] < 10^-2]}],
  {"FiniteProductRewrite", True, True, "GaussianBinomialRewrite", True, True, "Forward", True, True, "TargetLog", True},
  TestID -> "q-special-varying-lengths-and-arguments-rewrite-through-infinite-products"]

(* --- symbolic exponents near q = 0 (monograph "Exact generalized expansion at q = 0") --- *)
VerificationTest[
  Module[{x, q, u, a, s, short, p, e},
    s = AsymptoticExpansion[QGamma[x, q], {q, 0, 4}, Assumptions -> x >= 4];
    short = AsymptoticExpansion[QGamma[x, q], {q, 0, 4}, Assumptions -> x >= 2];
    p = AsymptoticExpansion[QPochhammer[q^x, q], {q, 0, 3}, Assumptions -> x >= 3];
    e = AsymptoticExpansion[(1 + u)^a, {u, 0, 3}, Assumptions -> a > 0];
    (* the generalized exponents m (x + r) lie at or beyond q^x: through q^3 the expansion is that of (1 - q)^(1 - x) (q; q)_inf *)
    {qTestTerms[s, {{0, 1}, {1, x - 2}, {2, x (x - 3)/2}, {3, (x^3 - 3 x^2 - 4 x + 6)/6}}],
     Expand[(Normal[s] /. x -> 9/2) - Normal[Series[QGamma[9/2, q], {q, 0, 3}]]], short[[1]], short[[2]]["Reached"],
     p["Terms"], p["RemainderPower"], qTestTerms[e, {{0, 1}, {1, a}, {2, a (a - 1)/2}}, a > 0]}],
  {True, 0, "InsufficientOrder", 2, {{0, 1}}, 3, True},
  TestID -> "q-special-symbolic-exponents-near-base-zero-expand-through-the-proved-bound"]
