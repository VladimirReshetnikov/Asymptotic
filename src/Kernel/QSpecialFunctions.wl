(* q-special functions whose base tends to one. Loaded inside
   AsymptoticAnalysis`Private` after the logarithmic forward calculus.

   With q = Exp[-t] and t -> 0+, the logarithms of the four q-functions are
   explicit series in t whose coefficients are Bernoulli numbers, Bernoulli
   polynomials and polylogarithms of nonpositive order:

     Log[QPochhammer[a, q]]      (a fixed, a < 1)
       = -PolyLog[2, a]/t + Log[1 - a]/2
         - Sum[BernoulliB[2r]/(2r)! PolyLog[2 - 2r, a] t^(2r - 1), r >= 1]
     Log[QPochhammer[q^x, q]]    (x > 0 fixed, the coalescing parameter)
       = -Pi^2/(6 t) + (1/2 - x) Log[t] + Log[2 Pi]/2 - LogGamma[x]
         + BernoulliB[2, x] t/4
         - Sum[BernoulliB[2r] BernoulliB[2r + 1, x]/(2r (2r + 1)!) t^(2r), r >= 1]
     Log[QPochhammer[a, q, n]]   (n a nonnegative integer, a < 1)
       = n Log[1 - a] + Sum[(-1)^(m + 1)/m! PolyLog[1 - m, a] S_m(n) t^m, m >= 1],
         S_m(n) = Sum[j^m, {j, 0, n - 1}]
     Log[QPochhammer[q^x, q, n]] (x > 0)
       = n Log[t] + LogGamma[x + n] - LogGamma[x] + Sum[ell((x + j) t), {j, 0, n - 1}]
     Log[QFactorial[n, q]]       = LogGamma[n + 1] + Sum[ell(j t) - ell(t), {j, 1, n}]
     Log[QBinomial[n, k, q]]     = Log[Binomial[n, k]]
                                   + Sum[ell((n - k + j) t) - ell(j t), {j, 1, k}]
     Log[QGamma[x, q]]           (x > 0)
       = LogGamma[x] + (x - 1)(2 - x) t/4
         + Sum[BernoulliB[2r]/(2r (2r)!) (1 - x + BernoulliB[2r + 1, x]/(2r + 1)) t^(2r), r >= 1]

   where ell(y) = Log[(1 - Exp[-y])/y] = -y/2 + Sum[BernoulliB[2r]/(2r (2r)!) y^(2r)]
   and the finite sums are evaluated with Faulhaber's formula so that n, k
   may stay symbolic. The finite products, QFactorial and QBinomial series
   converge for |t| < 2 Pi/n; the infinite product and QGamma expansions are
   Poincare asymptotic with exponentially small remainders (Mellin transform
   of the Lambert series). The fixed-argument product expansion is proved in
   the vendored q-series monograph for |a| < 1; the Euler-Maclaurin form of
   the same expansion holds for every real a < 1, where each factor 1 - a q^j
   is positive and the logarithm is real.

     QPolyGamma[n, x, q]         (x > 0, n >= 0)
       = PolyGamma[n, x] + D[c_k(x), {x, n + 1}] t^k summed over k >= 1,
         c_k the coefficients of Log[QGamma[x, q]] above (a value model,
         not a logarithmic one; c_1'(x) = (3 - 2x)/4 vanishes at x = 3/2,
         where the base inverse is a square-root fold)

   The expansion variable is the base itself (any real base expression that
   tends to 1 from below); t = -Log[base] is expanded first and the series
   above is composed with that jet. A base that tends to 0 with a symbolic
   product length uses the stable coefficients of the q-product (section
   "Symbolic product lengths near base 0"); any other base is left to the
   ordinary native expansion. A fixed base with a growing argument is
   handled through the exponential chart w = q^x at the end of this file
   (the q-polygamma being a Lambert series in that chart), the argument
   inverses at the zeros a = q^-m of the infinite product split off the
   vanishing factors, and the double scaling q = Exp[-tau/n] with lengths
   proportional to n has its own Euler-Maclaurin models in 1/n. *)

$qSpecialHeads = {QPochhammer, QGamma, QFactorial, QBinomial, QPolyGamma};
qSpecialHeadQ[h_] := MemberQ[$qSpecialHeads, h];
qSpecialQ[e_] := MatchQ[e, QPochhammer[_, _] | QPochhammer[_, _, _] | QGamma[_, _] | QFactorial[_, _] | QBinomial[_, _, _] | QPolyGamma[_, _, _]];
(* The base is the second argument of QPochhammer and the last one otherwise. *)
qSpecialBase[e_QPochhammer] := e[[2]];
qSpecialBase[e_] := Last[e];

(* Dispatcher predicates; the defaults in the core file are False. A varying
   base is expanded through the logarithmic models below; a varying
   argument of the infinite product at a fixed base is checked for the
   product's zeros first and otherwise expanded natively, and a varying
   q-polygamma argument at a fixed base is a Lambert series in q^z. *)
qSpecialForwardHookQ[e_, u_] := qSpecialQ[e] &&
  (! FreeQ[qSpecialBase[e], u] || (MatchQ[e, QPochhammer[_, _]] && ! FreeQ[First[e], u]) ||
   (MatchQ[e, QPolyGamma[_, _, _]] && ! FreeQ[e[[2]], u]));
qSpecialLogHookQ[e_, u_] := MatchQ[e, Log[_]] && qSpecialForwardHookQ[First[e], u];

(* QPolyGamma[n, z, q] at a fixed base 0 < q < 1 is the Lambert series
     QPolyGamma[n, z, q] = -Log[1 - q] KroneckerDelta[n, 0]
                           + Log[q]^(n + 1) Sum[m^n q^(m z)/(1 - q^m), m >= 1],
   convergent for Re z > 0 (differentiate DLMF 5.18.8 in z). In the chart
   u = q^x the argument is z = c + lambda Log[u]/Log[q], so q^z = q^c u^lambda
   is an exact power and the series is an ordinary power series in u. *)
qSpecialLogLinearPower[z_, u_, q_] := Module[{l = Log[u], slope, c},
  If[! PolynomialQ[z, l] || Exponent[z, l] =!= 1, Return[$Failed, Module]];
  slope = Coefficient[z, l, 1]; c = Coefficient[z, l, 0];
  If[! FreeQ[{slope, c}, u], Return[$Failed, Module]];
  slope = Simplify[slope Log[q]];
  If[! (exactRealQ[slope] && slope > 0), Return[$Failed, Module]];
  {slope, q^c}];

(* A q-polygamma whose argument is Log[x]/Log[q]-linear is already a chart
   phase in x; the logarithmic source chart leaves it alone. *)
qSpecialChartPhaseQ[f_, x_] := ! FreeQ[f, QPolyGamma[_, z_, q_] /; FreeQ[q, x] && exactRealQ[q] && 0 < q < 1 &&
  qSpecialLogLinearPower[z, x, q] =!= $Failed];

qSpecialPolyGammaJet[e : QPolyGamma[n_, z_, q_], u_, ell_, ass_, Kw_, limit_] := Module[{power, series},
  power = If[IntegerQ[n] && n >= 0 && exactRealQ[q] && 0 < q < 1, qSpecialLogLinearPower[z, u, q], $Failed];
  If[power === $Failed, Return[fwdSeries[e, u, ell, ass, Kw, limit], Module]];
  If[Kw === Infinity, fail["InfiniteSeries", "A q-polygamma expansion at a fixed base is an infinite series; a finite working order is needed."]];
  series = pUnitSeries[{{power[[1]], power[[2]]}}, Infinity, 0, With[{qq = q, nn = n}, Function[m, m^nn/(1 - qq^m)]], Kw, ell, ass, limit];
  pAdd[pConst[If[n === 0, -Log[1 - q], 0], ell, ass], pScale[series, Log[q]^(n + 1), ell, ass], ell, ass]];

(* (a; q)_inf at a fixed base 0 < q < 1 vanishes exactly at a = q^-m, m >= 0,
   where the native derivative formula (QPolyGamma) is singular. Split off
   the m + 1 factors that carry the zero: (a; q)_inf = (a; q)_(m+1) (a q^(m+1); q)_inf,
   the second factor being analytic and nonzero near the limit argument. *)
qSpecialArgumentZeroSplit[e : QPochhammer[a_, q_], u_, ell_, ass_, limit_] := Module[{jet, a0, m},
  If[! (exactRealQ[q] && 0 < q < 1), Return[$Failed, Module]];
  jet = Catch[fwd[a, u, ell, ass, 1, limit], $tag];
  If[FailureQ[jet] || jet[[1]] === {} || ! zeroQ[jet[[1, 1, 1]], ass] || ! FreeQ[jet[[1, 1, 2]], ell], Return[$Failed, Module]];
  a0 = jet[[1, 1, 2]];
  If[! (exactRealQ[a0] && a0 >= 1), Return[$Failed, Module]];
  m = Simplify[-Log[a0]/Log[q]];
  If[! IntegerQ[m] || m < 0, Return[$Failed, Module]];
  (* The finite product is written out: the native derivative rules do not
     cover the three-argument form. *)
  Product[1 - a q^j, {j, 0, m}] QPochhammer[a q^(m + 1), q]];

qSpecialArgumentJet[e_, u_, ell_, ass_, Kw_, limit_] := Module[{split},
  If[MatchQ[e, QPolyGamma[_, _, _]], Return[qSpecialPolyGammaJet[e, u, ell, ass, Kw, limit], Module]];
  split = If[MatchQ[e, QPochhammer[_, _]], qSpecialArgumentZeroSplit[e, u, ell, ass, limit], $Failed];
  If[split === $Failed, fwdSeries[e, u, ell, ass, Kw, limit], fwd[split, u, ell, ass, Kw, limit]]];

(* Sum[(x + j)^m, {j, 0, n - 1}] by Faulhaber; also valid for symbolic n. *)
qSpecialPowerSum[m_, x_, n_] := Together[(BernoulliB[m + 1, x + n] - BernoulliB[m + 1, x])/(m + 1)];

(* Coefficient of y^m in Log[(1 - Exp[-y])/y]. *)
qSpecialBernoulliLog[1] = -1/2;
qSpecialBernoulliLog[m_Integer] := If[EvenQ[m], BernoulliB[m]/(m m!), 0];

qSpecialProve[condition_, ass_] := TrueQ[Quiet[TimeConstrained[Simplify[condition, ass], 3, False]]];
qSpecialIntegerQ[n_, ass_] := IntegerQ[n] || qSpecialProve[Element[n, Integers], ass];

(* Coefficient of t^k in Log[QGamma[x, Exp[-t]]] as an expression in s. *)
qSpecialGammaCoefficient[k_Integer, s_] := Which[k === 1, (s - 1) (2 - s)/4,
  EvenQ[k], BernoulliB[k]/(k k!) (1 - s + BernoulliB[k + 1, s]/(k + 1)), True, 0];
(* The q-polygamma coefficients are the (n + 1)-st argument derivatives of
   the q-gamma coefficients; the expansion is locally uniform with uniform
   differentiated remainders (monograph, q-digamma inversion). *)
qSpecialPolyGammaCoefficient[k_Integer, n_Integer, x_] := Module[{s},
  Together[D[qSpecialGammaCoefficient[k, s], {s, n + 1}] /. s -> x]];

(* Double scaling q = Exp[-tau/n] with k = alpha n (Gaussian coefficient
   calculus, "Uniform all-order logarithmic expansion"): with b = 1 - alpha,
     Log[QBinomial[n, alpha n, Exp[-tau/n]]]
       = n S + Log[u]/2 - Log[2 Pi alpha b]/2 + (h[1] - h[alpha] - h[b])/2
         + Sum[C[2r - 1] n^(1 - 2r), r >= 1],   u = 1/n,
     S = (PolyLog[2, E^-tau] - PolyLog[2, E^(-tau alpha)] - PolyLog[2, E^(-tau b)] + Pi^2/6)/tau,
     h[y] = Log[(1 - E^(-tau y))/(tau y)],
     h^(s)[y] = (-1)^(s - 1) (tau^s PolyLog[1 - s, E^(-tau y)] - (s - 1)!/y^s),
     h'[0] = -tau/2, h^(2r + 1)[0] = 0,
     C[2r - 1] = BernoulliB[2r]/(2r (2r - 1)) (1 - alpha^(1 - 2r) - b^(1 - 2r))
               + BernoulliB[2r]/(2r)! (h^(2r-1)[1] - h^(2r-1)[alpha] - h^(2r-1)[b] + h^(2r-1)[0]).
   The same Euler-Maclaurin blocks give the q-factorial, whose n factors
   1/(1 - q) contribute -n h[1/n] = -h[u]/u exactly:
     Log[QFactorial[n, Exp[-tau/n]]] = LogGamma[n + 1] + n I1 + h[1]/2 + tau/2
         + Sum[(BernoulliB[2r]/(2r)! (h^(2r-1)[1] - h^(2r-1)[0])
                - BernoulliB[2r] tau^(2r)/(2r (2r)!)) n^(1 - 2r), r >= 1],
     I1 = (PolyLog[2, E^-tau] - Pi^2/6)/tau - Log[tau] + 1,
   whose Stirling part is composed separately. Both are Poincare expansions
   uniform for alpha and tau in compact subsets of (0, 1) and (0, Infinity),
   along integers n with alpha n integral. *)
qSpecialScalingH[tau_, y_] := Log[(1 - Exp[-tau y])/(tau y)];
qSpecialScalingHDerivative[s_Integer, tau_, y_] := If[y === 0,
  Which[s === 1, -tau/2, EvenQ[s], BernoulliB[s] tau^s/s, True, 0],
  (-1)^(s - 1) (tau^s PolyLog[1 - s, Exp[-tau y]] - (s - 1)!/y^s)];
qSpecialScalingIntegral[tau_, y_] := (PolyLog[2, Exp[-tau y]] - Pi^2/6)/tau - y Log[tau y] + y;

(* The double-scaling data {tau, alpha} of a q-factorial or Gaussian binomial
   in the local variable u = 1/n, or $Failed when the expression is not of
   that form. The base must be exactly Exp[-tau u] with a fixed positive tau. *)
qSpecialDoubleScalingData[e_, u_, ass_] := Module[{base = qSpecialBase[e], tau, n, k, alpha},
  If[! MatchQ[e, QFactorial[_, _] | QBinomial[_, _, _]] || FreeQ[base, u], Return[$Failed, Module]];
  tau = Quiet[TimeConstrained[Simplify[-Log[base]/u, ass && u > 0], 3, $Failed]];
  If[tau === $Failed || ! FreeQ[tau, u] || ! qSpecialProve[tau > 0, ass], Return[$Failed, Module]];
  n = e[[1]];
  If[Simplify[n u] =!= 1, Return[$Failed, Module]];
  If[Head[e] === QFactorial, Return[{tau, None}, Module]];
  k = e[[2]]; alpha = Simplify[k u];
  If[! FreeQ[alpha, u] || ! qSpecialProve[0 < alpha < 1, ass], Return[$Failed, Module]];
  {tau, alpha}];

qSpecialDoubleScalingModel[e_, {tau_, alpha_}, ass_] := Module[{b = 1 - alpha, cf, pole, constant, type, domain},
  If[alpha === None,
    type = "ScaledFactorial"; domain = tau > 0;
    pole = qSpecialScalingIntegral[tau, 1];
    constant = qSpecialScalingH[tau, 1]/2 + tau/2;
    cf = With[{tt = tau}, Function[k, If[OddQ[k], With[{r = (k + 1)/2},
      With[{c = BernoulliB[2 r]/(2 r)! (qSpecialScalingHDerivative[2 r - 1, tt, 1] - qSpecialScalingHDerivative[2 r - 1, tt, 0]) -
        BernoulliB[2 r] tt^(2 r)/(2 r (2 r)!)}, c]], 0]]],
    type = "ScaledGaussianBinomial"; domain = tau > 0 && 0 < alpha < 1;
    pole = (PolyLog[2, Exp[-tau]] - PolyLog[2, Exp[-tau alpha]] - PolyLog[2, Exp[-tau b]] + Pi^2/6)/tau;
    constant = -Log[2 Pi alpha b]/2 + (qSpecialScalingH[tau, 1] - qSpecialScalingH[tau, alpha] - qSpecialScalingH[tau, b])/2;
    cf = With[{tt = tau, aa = alpha, bb = b}, Function[k, If[OddQ[k], With[{r = (k + 1)/2},
      With[{c = BernoulliB[2 r]/(2 r (2 r - 1)) (1 - aa^(1 - 2 r) - bb^(1 - 2 r)) +
        BernoulliB[2 r]/(2 r)! (qSpecialScalingHDerivative[2 r - 1, tt, 1] - qSpecialScalingHDerivative[2 r - 1, tt, aa] -
          qSpecialScalingHDerivative[2 r - 1, tt, bb] + qSpecialScalingHDerivative[2 r - 1, tt, 0])}, c]], 0]]]];
  <|"Type" -> type, "Pole" -> pole, "LogCoefficient" -> If[alpha === None, 0, 1/2], "Constant" -> constant,
    "Coefficient" -> cf, "Domain" -> domain, "Convergent" -> False, "Composition" -> "Local",
    "Stirling" -> If[alpha === None, LogGamma[e[[1]] + 1], 0]|>];

(* The coalescing exponent x with a = base^x, or $Failed. *)
qSpecialCoalescingExponent[a_, base_, u_, ass_] := Module[{x},
  If[a === base, Return[1, Module]];
  If[MatchQ[a, Power[base, _]] && FreeQ[a[[2]], u], Return[a[[2]], Module]];
  x = Quiet[TimeConstrained[Simplify[Log[a]/Log[base], ass && u > 0 && 0 < base < 1], 3, $Failed]];
  If[x === $Failed || ! FreeQ[x, u], $Failed, x]];

(* The logarithmic model of one q-function in the local variable u:
   pole coefficient (of 1/t), logarithm coefficient (of Log[t]), constant,
   and the Taylor coefficient function of t^k for k >= 1 (a zero coefficient
   is 0, never Null: Null ends a unit series). Every parameter condition is
   proved from the assumptions before the model is returned. *)
qSpecialLogModel[e_, u_, ass_] := Module[{h = Head[e], base = qSpecialBase[e], a, n, k, x, m, r, cf, domain, type, constant, pole = 0, logCoefficient = 0, scaling},
  If[MatchQ[e, QFactorial[_, _] | QBinomial[_, _, _]] && ! FreeQ[Most[List @@ e], u],
    scaling = qSpecialDoubleScalingData[e, u, ass];
    If[scaling =!= $Failed, Return[qSpecialDoubleScalingModel[e, scaling, ass], Module]]];
  Switch[h,
    QPolyGamma,
      {n, x} = {e[[1]], e[[2]]};
      If[! FreeQ[{n, x}, u] || ! (IntegerQ[n] && n >= 0) || ! qSpecialProve[x > 0, ass],
        fail["UnsupportedQArgument", "A q-polygamma expansion near base 1 needs a fixed nonnegative integer order and a fixed provably positive argument; state x > 0 in Assumptions.", <|"Order" -> n, "Argument" -> x|>]];
      type = "PolyGamma"; domain = x > 0; constant = PolyGamma[n, x];
      cf = With[{xx = x, nn = n}, Function[k, With[{c = qSpecialPolyGammaCoefficient[k, nn, xx]}, c]]],
    QPochhammer,
      a = e[[1]];
      If[Length[e] === 3, n = e[[3]];
        If[! FreeQ[n, u] || ! (qSpecialIntegerQ[n, ass] && qSpecialProve[n >= 0, ass]),
          fail["UnsupportedQArgument", "A finite q-Pochhammer expansion near base 1 needs a fixed nonnegative integer product length; state Element[n, Integers] && n >= 0 in Assumptions.", <|"Length" -> n|>]]];
      If[FreeQ[a, u],
        If[! qSpecialProve[a < 1, ass],
          fail["UnsupportedQArgument", "The q-Pochhammer argument must be provably real and less than 1 so that every factor 1 - a q^j is positive; state the range in Assumptions.", <|"Argument" -> a|>]];
        domain = a < 1;
        If[Length[e] === 2,
          type = "FixedArgumentInfiniteProduct";
          pole = -PolyLog[2, a]; constant = Log[1 - a]/2;
          cf = With[{aa = a}, Function[k, If[OddQ[k], With[{rr = (k + 1)/2}, -BernoulliB[2 rr]/(2 rr)! PolyLog[2 - 2 rr, aa]], 0]]],
          type = "FixedArgumentFiniteProduct";
          constant = n Log[1 - a];
          cf = With[{aa = a, nn = n}, Function[k, With[{c = (-1)^(k + 1)/k! PolyLog[1 - k, aa] qSpecialPowerSum[k, 0, nn]}, c]]]],
        x = qSpecialCoalescingExponent[a, base, u, ass];
        If[x === $Failed || ! qSpecialProve[x > 0, ass],
          fail["UnsupportedQArgument", "A q-Pochhammer argument that varies with the base must be a fixed positive power base^x of that base (the coalescing parameter).", <|"Argument" -> a, "Base" -> base|>]];
        domain = x > 0;
        If[Length[e] === 2,
          type = "CoalescingInfiniteProduct";
          pole = -Pi^2/6; logCoefficient = 1/2 - x; constant = Log[2 Pi]/2 - Log[Gamma[x]];
          cf = With[{xx = x}, Function[k, Which[k === 1, BernoulliB[2, xx]/4, EvenQ[k], With[{c = -BernoulliB[k] BernoulliB[k + 1, xx]/(k (k + 1)!)}, c], True, 0]]],
          type = "CoalescingFiniteProduct";
          logCoefficient = n; constant = Log[Pochhammer[x, n]];
          cf = With[{xx = x, nn = n}, Function[k, With[{c = qSpecialBernoulliLog[k] qSpecialPowerSum[k, xx, nn]}, c]]]]],
    QFactorial,
      n = e[[1]];
      If[! FreeQ[n, u] || ! (qSpecialIntegerQ[n, ass] && qSpecialProve[n >= 0, ass]),
        fail["UnsupportedQArgument", "A q-factorial expansion near base 1 needs a fixed nonnegative integer argument; state Element[n, Integers] && n >= 0 in Assumptions.", <|"Argument" -> n|>]];
      type = "Factorial"; domain = n >= 0;
      constant = Log[Gamma[n + 1]];
      cf = With[{nn = n}, Function[k, With[{c = qSpecialBernoulliLog[k] (qSpecialPowerSum[k, 1, nn] - nn)}, c]]],
    QBinomial,
      {n, k} = {e[[1]], e[[2]]};
      If[! FreeQ[{n, k}, u] || ! (qSpecialIntegerQ[n, ass] && qSpecialIntegerQ[k, ass] && qSpecialProve[0 <= k <= n, ass]),
        fail["UnsupportedQArgument", "A Gaussian binomial expansion near base 1 needs fixed integers 0 <= k <= n; state them in Assumptions.", <|"Arguments" -> {n, k}|>]];
      type = "GaussianBinomial"; domain = 0 <= k <= n;
      constant = Log[Binomial[n, k]];
      cf = With[{nn = n, kk = k}, Function[m, With[{c = qSpecialBernoulliLog[m] (qSpecialPowerSum[m, 1, nn] - qSpecialPowerSum[m, 1, kk] - qSpecialPowerSum[m, 1, nn - kk])}, c]]],
    QGamma,
      x = e[[1]];
      If[! FreeQ[x, u] || ! qSpecialProve[x > 0, ass],
        fail["UnsupportedQArgument", "A q-gamma expansion near base 1 needs a fixed provably positive argument; state x > 0 in Assumptions.", <|"Argument" -> x|>]];
      type = "Gamma"; domain = x > 0; constant = Log[Gamma[x]];
      cf = With[{xx = x}, Function[k, Which[k === 1, With[{c = (xx - 1) (2 - xx)/4}, c],
        EvenQ[k], With[{c = BernoulliB[k]/(k k!) (1 - xx + BernoulliB[k + 1, xx]/(k + 1))}, c], True, 0]]],
    _, fail["UnsupportedQArgument", "Unsupported q-function form.", <|"Expression" -> e|>]];
  <|"Type" -> type, "Pole" -> pole, "LogCoefficient" -> logCoefficient, "Constant" -> constant,
    "Coefficient" -> cf, "Domain" -> domain, "Convergent" -> MemberQ[{"FixedArgumentFiniteProduct", "CoalescingFiniteProduct", "Factorial", "GaussianBinomial"}, type],
    "Composition" -> "Base", "Stirling" -> 0|>];

(* ------------------------------------------------------------------ *)
(* Symbolic product lengths near base 0                                 *)
(* ------------------------------------------------------------------ *)

(* Near q = 0 the coefficient of q^r in a finite q-product depends on the
   length only through the factors of index at most r, so it is stable once
   the length exceeds r:
     Log[(a; q)_n / (1 - a)] = -Sum[q^r Sum[a^d/d, d | r], r >= 1]        (n >= r + 1)
     Log[QFactorial[n, q]]   = Sum[(n - DivisorSigma[1, r]) q^r/r, r >= 1] (n >= r)
     Log[QBinomial[n, k, q]] = Sum[DivisorSigma[1, r] q^r/r, r >= 1]      (k, n - k >= r)
     QGamma[n, q]            = QFactorial[n - 1, q]                        (n integer)
   (monograph, "Exact coefficient engine at q = 0" and "Zero-base factorial
   inverse"; the Gaussian series is Euler's Log[1/(q; q)_inf]). Each
   coefficient is used only through the order whose length bound is proved
   from the assumptions; the remainder is capped at the first unproved order. *)
qSpecialZeroBaseModel[e_, u_, ass_] := Module[{a, n, k, prefactor, cf, bound},
  (* A numeric length is an exact finite product; the ordinary expansion
     keeps every coefficient. *)
  If[AnyTrue[Flatten[{Switch[e, QPochhammer[_, _, _], e[[3]], QBinomial[_, _, _], {e[[1]], e[[2]]}, _, e[[1]]]}], NumericQ], Return[$Failed, Module]];
  Switch[e,
    QPochhammer[_, _, _],
      {a, n} = {e[[1]], e[[3]]};
      If[! FreeQ[{a, n}, u] || ! qSpecialIntegerQ[n, ass], Return[$Failed, Module]];
      prefactor = 1 - a;
      cf = With[{aa = a}, Function[r, -Total[aa^#/# & /@ Divisors[r]]]];
      bound = With[{nn = n}, Function[r, nn >= r + 1]],
    QFactorial[_, _] | QGamma[_, _],
      n = If[Head[e] === QGamma, e[[1]] - 1, e[[1]]];
      If[! FreeQ[n, u] || ! qSpecialIntegerQ[n, ass], Return[$Failed, Module]];
      prefactor = 1;
      cf = With[{nn = n}, Function[r, (nn - DivisorSigma[1, r])/r]];
      bound = With[{nn = n}, Function[r, nn >= r]],
    QBinomial[_, _, _],
      {n, k} = {e[[1]], e[[2]]};
      If[! FreeQ[{n, k}, u] || ! qSpecialIntegerQ[n, ass] || ! qSpecialIntegerQ[k, ass], Return[$Failed, Module]];
      prefactor = 1;
      cf = Function[r, DivisorSigma[1, r]/r];
      bound = With[{nn = n, kk = k}, Function[r, kk >= r && nn - kk >= r]],
    _, Return[$Failed, Module]];
  <|"Prefactor" -> prefactor, "Coefficient" -> cf, "Bound" -> bound|>];

(* The largest order r <= max whose length bound is proved, or 0. *)
qSpecialProvedOrder[model_, max_, ass_] := Module[{r = 0},
  While[r < max && qSpecialProve[model["Bound"][r + 1], ass], r++];
  r];

qSpecialZeroBaseJet[e_, u_, ell_, ass_, Kw_, limit_] := Module[{model, jet, valuation, order, cut, series},
  model = qSpecialZeroBaseModel[e, u, ass];
  If[model === $Failed, Return[$Failed, Module]];
  jet = Catch[fwd[qSpecialBase[e], u, ell, ass, Max[1, Kw], limit], $tag];
  If[FailureQ[jet] || (jet[[1]] === {} && jet[[2]] === Infinity), Return[$Failed, Module]];
  If[! (jet[[1]] === {} || less[0, jetValuation[jet[[1]]]]), Return[$Failed, Module]];
  If[Kw === Infinity, fail["InfiniteSeries", "A q-product expansion near base 0 with a symbolic length is an infinite series; a finite working order is needed."]];
  valuation = If[jet[[1]] === {}, jet[[2]], jetValuation[jet[[1]]]];
  order = qSpecialProvedOrder[model, Ceiling[Kw/valuation], ass];
  If[order === 0,
    fail["UnsupportedQArgument", "A q-product expansion near base 0 with a symbolic length needs a proved lower bound on the length; state it in Assumptions (the coefficient of the r-th power is stable once the length exceeds r).", <|"Expression" -> e, "RequiredBound" -> model["Bound"][1]|>]];
  cut = Min[Kw, (order + 1) valuation];
  series = pUnitSeries[jet[[1]], jet[[2]], jet[[3]], model["Coefficient"], cut, ell, ass, limit];
  pScale[fwdExp[series, u, ell, ass, cut, limit], model["Prefactor"], ell, ass]];

(* The jet of t = -Log[base] when the base tends to 1 from below, else $Failed.
   Failures of the base expansion itself are not this module's business. *)
qSpecialBaseJet[base_, u_, ell_, ass_, Kw_, limit_] := Module[{jet, lead, K = Max[1, Kw], tries = 0},
  While[True,
    jet = Catch[fwd[-Log[base], u, ell, ass, K, limit], $tag];
    If[FailureQ[jet], Return[$Failed, Module]];
    (* A low working order can hide the leading term behind the remainder. *)
    If[jet[[1]] =!= {} || jet[[2]] === Infinity || ++tries > 6, Break[]];
    K = 2 K + 1];
  If[jet[[1]] === {}, Return[$Failed, Module]];
  lead = jet[[1, 1]];
  If[! less[0, lead[[1]]] || ! FreeQ[lead[[2]], ell] || ! provablyPositive[lead[[2]], ass], Return[$Failed, Module]];
  jet];

(* Compose the logarithmic model with the jet of t. *)
qSpecialComposeLog[model_, baseJet_, u_, ell_, ass_, Kw_, limit_] := Module[{T, P, D, res, series},
  {T, P, D} = baseJet;
  res = pConst[model["Constant"], ell, ass];
  If[! zeroQ[model["Pole"], ass],
    res = pAdd[res, pScale[fwdPower[baseJet, -1, u, ell, ass, Kw, limit], model["Pole"], ell, ass], ell, ass]];
  If[! zeroQ[model["LogCoefficient"], ass],
    res = pAdd[res, pScale[fwdLog[baseJet, u, ell, ass, Kw, limit], model["LogCoefficient"], ell, ass], ell, ass]];
  If[Kw === Infinity, fail["InfiniteSeries", "A q-function expansion near base 1 is an infinite series; a finite working order is needed."]];
  series = pUnitSeries[T, P, D, model["Coefficient"], Kw, ell, ass, limit];
  pAdd[res, series, ell, ass]];

qSpecialLogJet[e_, u_, ell_, ass_, Kw_, limit_] := Module[{model, jet, nu, res},
  model = qSpecialLogModel[e, u, ass];
  If[model["Composition"] === "Local",
    (* Double scaling: the model is a series in the local variable itself,
       and the q-factorial keeps its Stirling part in the ordinary calculus. *)
    res = qSpecialComposeLog[model, pVar, u, ell, ass, Kw, limit];
    If[model["Stirling"] =!= 0, res = pAdd[res, fwd[model["Stirling"], u, ell, ass, Kw, limit], ell, ass]];
    Return[res, Module]];
  jet = qSpecialBaseJet[qSpecialBase[e], u, ell, ass, Max[1, Kw] + 2, limit];
  If[jet === $Failed, Return[$Failed, Module]];
  nu = jet[[1, 1, 1]];
  If[less[1, nu], jet = qSpecialBaseJet[qSpecialBase[e], u, ell, ass, Max[1, Kw] + 2 nu, limit]];
  qSpecialComposeLog[model, jet, u, ell, ass, Kw, limit]];

(* The q-polygamma models are value models, not logarithmic ones. *)
qSpecialValueModelQ[e_] := MatchQ[e, QPolyGamma[_, _, _]];

(* The base tends to 1 from below, or the expression is in double scaling. *)
qSpecialNearOneJetQ[e_, u_, ell_, ass_, limit_] :=
  qSpecialBaseJet[qSpecialBase[e], u, ell, ass, 1, limit] =!= $Failed ||
  (MatchQ[e, QFactorial[_, _] | QBinomial[_, _, _]] && qSpecialDoubleScalingData[e, u, ass] =!= $Failed);

(* Jets used by the ordinary dispatcher. A base that tends to 0 with a
   symbolic product length uses the stable-coefficient models; any other
   base is expanded natively as before. *)
qSpecialForwardJet[e_, u_, ell_, ass_, Kw_, limit_] := Module[{jet},
  If[FreeQ[qSpecialBase[e], u], Return[qSpecialArgumentJet[e, u, ell, ass, Kw, limit], Module]];
  If[! qSpecialNearOneJetQ[e, u, ell, ass, limit],
    jet = qSpecialZeroBaseJet[e, u, ell, ass, Kw, limit];
    Return[If[jet === $Failed, fwdSeries[e, u, ell, ass, Kw, limit], jet], Module]];
  jet = qSpecialLogJet[e, u, ell, ass, Kw, limit];
  If[jet === $Failed, Return[fwdSeries[e, u, ell, ass, Kw, limit], Module]];
  If[qSpecialValueModelQ[e], jet, fwdExp[jet, u, ell, ass, Kw, limit]]];

qSpecialLogForwardJet[e_, u_, ell_, ass_, Kw_, limit_] := Module[{jet},
  If[FreeQ[qSpecialBase[e], u], Return[fwdLog[qSpecialArgumentJet[e, u, ell, ass, Kw, limit], u, ell, ass, Kw, limit], Module]];
  If[! qSpecialNearOneJetQ[e, u, ell, ass, limit],
    jet = qSpecialZeroBaseJet[e, u, ell, ass, Kw, limit];
    Return[fwdLog[If[jet === $Failed, fwdSeries[e, u, ell, ass, Kw, limit], jet], u, ell, ass, Kw, limit], Module]];
  jet = qSpecialLogJet[e, u, ell, ass, Kw, limit];
  Which[jet === $Failed, fwdLog[fwdSeries[e, u, ell, ass, Kw, limit], u, ell, ass, Kw, limit],
    qSpecialValueModelQ[e], fwdLog[jet, u, ell, ass, Kw, limit],
    True, jet]];

(* The infinite products whose base varies with x. *)
qSpecialInfiniteProducts[f_, x_] :=
  DeleteDuplicates[Cases[f, QPochhammer[_, b_] /; ! FreeQ[b, x], {0, Infinity}]];

qSpecialNearOneQ[f_, x_, coord_, ass_, limit_] := Module[{products, ell = Unique["ell$"]},
  products = qSpecialInfiniteProducts[f, x];
  products =!= {} && AllTrue[products,
    qSpecialBaseJet[qSpecialBase[#] /. x -> coord["Substitution"], coord["u"], ell, ass, 1, limit] =!= $Failed &]];

(* Double-scaling q-factorials and Gaussian binomials, which are
   exponentially large like the infinite products. *)
qSpecialDoubleScalingFunctions[f_, x_, coord_, ass_] := DeleteDuplicates[Cases[f,
  e : (QFactorial[_, _] | QBinomial[_, _, _]) /; ! FreeQ[qSpecialBase[e], x] &&
    qSpecialDoubleScalingData[e /. x -> coord["Substitution"], coord["u"], ass] =!= $Failed, {0, Infinity}]];

qSpecialLogarithmicRouteQ[f_, x_, coord_, ass_, limit_] :=
  qSpecialNearOneQ[f, x, coord, ass, limit] || qSpecialDoubleScalingFunctions[f, x, coord, ass] =!= {};

(* A product of q-functions with real powers and ordinary factors, in the
   logarithmic domain. Each q-factor is positive on its proved parameter
   domain; the ordinary factors keep their separately proved eventual sign.
   A q-polygamma factor has no sign of its own and stays ordinary. *)
qSpecialProductData[e_, x_] := Module[{parts, base, r},
  If[FreeQ[e, _QPochhammer | _QGamma | _QFactorial | _QBinomial] || FreeQ[e, x] || Head[e] === QPolyGamma, Return[{e, {}, {}}, Module]];
  Which[
    qSpecialQ[e], {1, {{e, 1}}, {}},
    Head[e] === Times,
      parts = qSpecialProductData[#, x] & /@ List @@ e;
      If[MemberQ[parts, $Failed], $Failed,
        {Times @@ parts[[All, 1]], Join @@ parts[[All, 2]], Join @@ parts[[All, 3]]}],
    Head[e] === Power && FreeQ[e[[2]], x],
      base = qSpecialProductData[e[[1]], x]; r = e[[2]];
      If[base === $Failed || base[[2]] === {}, $Failed,
        {base[[1]]^r, {#[[1]], r #[[2]]} & /@ base[[2]], Append[base[[3]], r]}],
    True, $Failed]];

qSpecialProductSource[f_, x_, ass_, coord_] := Module[
  {product, factors, powers, models, ordinary, logarithm, domain, u = coord["u"]},
  product = qSpecialProductData[f, x];
  If[product === $Failed || product[[2]] === {}, Return[$Failed, Module]];
  factors = product[[2]];
  If[! AllTrue[factors, ! FreeQ[qSpecialBase[#[[1]]], x] &], Return[$Failed, Module]];
  powers = DeleteDuplicates[Join[product[[3]], factors[[All, 2]]]];
  If[! AllTrue[powers, exactRealQ[#] || qSpecialProve[Element[#, Reals], ass] &],
    fail["UnsupportedQPower", "q-function powers require exact exponents that are provably real.", <|"Powers" -> powers|>]];
  models = qSpecialLogModel[#[[1]] /. x -> coord["Substitution"], u, ass] & /@ factors;
  ordinary = logarithmicProductSource[product[[1]], x, ass, coord];
  logarithm = Total[MapThread[#1[[2]] Log[#1[[1]]] &, {factors}]] + ordinary["Logarithm"];
  domain = ordinary["Domain"] && And @@ (#["Domain"] & /@ models);
  <|"Factors" -> factors, "Models" -> models, "Sign" -> ordinary["Sign"], "Logarithm" -> logarithm, "Domain" -> domain,
    "Convergent" -> And @@ (#["Convergent"] & /@ models)|>];

qSpecialMetadata[source_] := Module[{scaled = AnyTrue[source["Models"], StringStartsQ[#["Type"], "Scaled"] &]},
  <|"QSpecialFactors" -> MapThread[<|"Function" -> #1[[1]], "Power" -> #1[[2]], "Model" -> #2["Type"]|> &, {source["Factors"], source["Models"]}],
  "Transformation" -> If[scaled,
    "Each double-scaling q-function (base Exp[-tau/n], length proportional to n) equals Exp of its Euler-Maclaurin logarithmic expansion in 1/n, whose coefficients are dilogarithms and polylogarithms of nonpositive order at Exp[-tau], Exp[-tau alpha] and Exp[-tau (1 - alpha)].",
    "Each q-function equals Exp of its explicit logarithmic expansion in t = -Log[base] (Bernoulli numbers, Bernoulli polynomials and polylogarithms of nonpositive order), composed with the expansion of t."],
  "ExpansionNature" -> If[TrueQ[source["Convergent"]], "Convergent", "Poincare"],
  "AsymptoticReference" -> If[scaled,
    "Vendored Gaussian coefficient calculus, 'Uniform all-order logarithmic expansion' (double scaling q = Exp[-tau/n]); https://dlmf.nist.gov/2.10 (Euler-Maclaurin)",
    "https://dlmf.nist.gov/17.2 (q-Pochhammer), https://dlmf.nist.gov/5.18 (q-gamma); Lambert-series/Mellin derivation as in the vendored q-Pochhammer monograph, chapters 2-5"]|>];

(* Top-level forward route: an infinite product whose base tends to 1, or a
   double-scaling q-factorial or Gaussian binomial, is exponentially large
   or small, so the ordinary power-log jet refuses it. Products of
   q-functions and ordinary factors go through the logarithmic forward
   expansion; bounded q-functions need no special route. *)
qSpecialForwardExpansion[f_, x_, x0_, cutoff_, ass_, coord_, goal_, limit_] := Module[{source},
  If[FreeQ[f, _QPochhammer | _QGamma | _QFactorial | _QBinomial | _QPolyGamma], Return[$Failed, Module]];
  If[qSpecialFixedBaseFunctions[f, x] =!= {},
    Return[qSpecialArgumentForwardExpansion[f, x, x0, cutoff, ass, coord, goal, limit], Module]];
  If[FreeQ[f, _QPochhammer | _QFactorial | _QBinomial] || ! qSpecialLogarithmicRouteQ[f, x, coord, ass, limit], Return[$Failed, Module]];
  validateInput[f, limit];
  source = qSpecialProductSource[f, x, ass, coord];
  If[source === $Failed, Return[$Failed, Module]];
  logarithmicForwardExpansion[f, source["Logarithm"], source["Sign"], source["Domain"],
    x, x0, cutoff, ass, coord, goal, limit, qSpecialMetadata[source]]];

(* Inverse route: the same logarithm is the phase of a logarithmic target
   coordinate, y = offset + Sign Exp[phase]. *)
qSpecialExponentialPhase[f_, x_, x0_, dir_, ass_, limit_] := Module[{coord, parts, offset, dependent, source},
  If[FreeQ[f, _QPochhammer | _QFactorial | _QBinomial], Return[$Failed, Module]];
  coord = localCoordinate[x, x0, dir];
  If[! qSpecialLogarithmicRouteQ[f, x, coord, ass, limit], Return[$Failed, Module]];
  parts = If[Head[f] === Plus, List @@ f, {f}];
  offset = Total[Select[parts, FreeQ[#, x] &]];
  dependent = Select[parts, ! FreeQ[#, x] &];
  If[Length[dependent] =!= 1, Return[$Failed, Module]];
  dependent = First[dependent];
  source = qSpecialProductSource[dependent, x, ass, coord];
  If[source === $Failed, Return[$Failed, Module]];
  If[! TrueQ[Simplify[Element[offset, Reals], ass]],
    fail["UnprovedRealCoefficient", "The target offset must be provably real."]];
  <|"Phase" -> source["Logarithm"], "AmplitudeSign" -> source["Sign"], "AmplitudeScale" -> 1, "Offset" -> offset,
    "Coordinate" -> coord, "PositiveAmplitude" -> source["Sign"] dependent, "QSpecialSource" -> source|>];

(* ------------------------------------------------------------------ *)
(* Fixed base, growing argument: the exponential source chart w = q^x   *)
(* ------------------------------------------------------------------ *)

(* For a fixed base 0 < q < 1 and x -> Infinity every q-function is an
   ordinary power-log expression in the chart variable w = q^x, through
     QGamma[z, q]       = (1 - q)^(1 - z) (q; q)_inf / (q^z; q)_inf
     QFactorial[n, q]   = (q; q)_inf / ((1 - q)^n (q^(n + 1); q)_inf)
     QBinomial[n, k, q] = (q^(k + 1); q)_inf (q^(n - k + 1); q)_inf / ((q; q)_inf (q^(n + 1); q)_inf)
     (a; q)_n           = (a; q)_inf / (a q^n; q)_inf
   with q^(lambda x + c) = q^c w^lambda for arguments linear in x. The
   remaining infinite products are analytic at w = 0 (Euler's series), so
   the ordinary engine expands the chart phase at w -> 0+. DLMF 5.18.4,
   17.2.6 and 17.5.1. *)

qSpecialFixedBaseFunctions[f_, x_] := DeleteDuplicates[Cases[f,
  e_ /; qSpecialQ[e] && FreeQ[qSpecialBase[e], x] && ! FreeQ[e, x], {0, Infinity}]];

qSpecialLinearArgument[z_, x_, ass_] := Module[{lambda, c},
  If[! PolynomialQ[z, x] || Exponent[z, x] > 1, Return[$Failed, Module]];
  lambda = Coefficient[z, x, 1]; c = Coefficient[z, x, 0];
  If[! (exactRealQ[lambda] && lambda >= 0) || ! qSpecialProve[Element[c, Reals], ass], $Failed, {lambda, c}]];

(* q^z in the chart, for z linear in x with a nonnegative slope (a constant
   argument is an ordinary constant factor). *)
qSpecialChartPower[z_, x_, q_, w_, ass_] := Module[{data = qSpecialLinearArgument[z, x, ass]},
  If[data === $Failed,
    fail["UnsupportedQArgument", "A q-function argument at a fixed base must be linear in the expansion variable with a nonnegative exact slope.", <|"Argument" -> z|>]];
  If[data[[1]] === 0, q^data[[2]], q^data[[2]] w^data[[1]]]];

qSpecialChartFactor[e_, x_, q_, w_, ass_] := Module[{z, n, k, a, domain, value},
  Switch[e,
    QGamma[_, q],
      z = e[[1]];
      value = (1 - q)^(1 - z) QPochhammer[q, q]/QPochhammer[qSpecialChartPower[z, x, q, w, ass], q];
      domain = z > 0,
    QFactorial[_, q],
      n = e[[1]];
      value = QPochhammer[q, q]/((1 - q)^n QPochhammer[q qSpecialChartPower[n, x, q, w, ass], q]);
      domain = n >= 0,
    QBinomial[_, _, q],
      {n, k} = {e[[1]], e[[2]]};
      value = QPochhammer[q qSpecialChartPower[k, x, q, w, ass], q] QPochhammer[q qSpecialChartPower[n - k, x, q, w, ass], q]/
        (QPochhammer[q, q] QPochhammer[q qSpecialChartPower[n, x, q, w, ass], q]);
      domain = 0 <= k <= n,
    QPochhammer[_, q, _],
      {a, n} = {e[[1]], e[[3]]};
      If[! FreeQ[a, x], fail["UnsupportedQArgument", "A finite q-Pochhammer symbol at a fixed base needs a fixed argument and a growing length.", <|"Expression" -> e|>]];
      If[! qSpecialProve[a < 1, ass],
        fail["UnsupportedQArgument", "The q-Pochhammer argument must be provably real and less than 1.", <|"Argument" -> a|>]];
      value = QPochhammer[a, q]/QPochhammer[a qSpecialChartPower[n, x, q, w, ass], q];
      domain = a < 1 && n >= 0,
    QPolyGamma[_, _, q],
      {n, z} = {e[[1]], e[[2]]};
      If[! (IntegerQ[n] && n >= 0), fail["UnsupportedQArgument", "A q-polygamma expansion at a fixed base needs a fixed nonnegative integer order.", <|"Order" -> n|>]];
      (* Validated here; the Lambert series is expanded by the jet hook once
         the argument has become linear in Log[w]. *)
      qSpecialChartPower[z, x, q, w, ass];
      value = e; domain = z > 0,
    QPochhammer[_, q],
      a = e[[1]];
      If[! MatchQ[a, Power[q, _] | Times[c_ /; FreeQ[c, x], Power[q, _]]],
        fail["UnsupportedQArgument", "The argument of an infinite q-Pochhammer symbol at a fixed base must be a constant multiple of a power q^z with z linear in the expansion variable.", <|"Argument" -> a|>]];
      If[Head[a] === Times && ! qSpecialProve[Element[First[a], Reals], ass],
        fail["UnsupportedQArgument", "The constant multiple in the q-Pochhammer argument must be provably real.", <|"Argument" -> a|>]];
      value = QPochhammer[a /. Power[q, z_] :> qSpecialChartPower[z, x, q, w, ass], q]; domain = True,
    _, fail["UnsupportedQArgument", "Unsupported q-function form at a fixed base.", <|"Expression" -> e|>]];
  (* A growing argument keeps every factor positive: the chart power tends to 0. *)
  <|"Value" -> value, "Domain" -> domain|>];

(* The chart phase Phi[w] with f = Phi[q^x], its base q and the domain. *)
qSpecialChartPhase[f_, x_, ass_] := Module[{functions, bases, q, w = Unique["qChart$"], factors, phase, domain},
  functions = qSpecialFixedBaseFunctions[f, x];
  If[functions === {}, Return[$Failed, Module]];
  bases = DeleteDuplicates[qSpecialBase /@ functions];
  If[Length[bases] =!= 1, fail["UnsupportedQArgument", "All q-functions must share one fixed base.", <|"Bases" -> bases|>]];
  q = First[bases];
  If[! (exactRealQ[q] && 0 < q < 1), fail["UnsupportedQArgument", "A fixed q-function base must be an exact real number in (0, 1).", <|"Base" -> q|>]];
  factors = qSpecialChartFactor[#, x, q, w, ass] & /@ functions;
  phase = f /. Thread[functions -> (#["Value"] & /@ factors)];
  phase = phase /. x -> Log[w]/Log[q];
  domain = And @@ (#["Domain"] & /@ factors);
  <|"Base" -> q, "ChartVariable" -> w, "Phase" -> phase, "Domain" -> domain,
    "Functions" -> functions, "Scale" -> -Log[q]|>];

(* Forward expansion at x -> Infinity in the chart w = q^x -> 0+. *)
qSpecialArgumentForwardExpansion[f_, x_, x0_, cutoff_, ass_, coord_, goal_, limit_] := Module[
  {chart, w, q, inner, a, sub, logRule, expression, remainder, terms, frontier},
  If[x0 =!= Infinity || qSpecialFixedBaseFunctions[f, x] === {}, Return[$Failed, Module]];
  chart = qSpecialChartPhase[f, x, ass];
  If[chart === $Failed, Return[$Failed, Module]];
  validateInput[f, limit];
  w = chart["ChartVariable"]; q = chart["Base"];
  inner = forwardCore[chart["Phase"], w, 0, cutoff, Assumptions -> ass, Direction -> "FromAbove",
    SeriesTermGoal -> goal, "MaxTerms" -> limit];
  If[! MatchQ[inner, _GeneralizedSeries], Return[inner, Module]];
  a = inner[[1]]; logRule = Log[w] -> x Log[q]; sub = w -> q^x;
  expression = a["Expression"] /. logRule /. sub;
  remainder = a["Remainder"] /. sub;
  terms = ({#[[1]], #[[2]] /. logRule} & /@ a["Terms"]);
  frontier = If[MissingQ[a["FrontierTerm"]] || a["FrontierTerm"] === 0, a["FrontierTerm"], a["FrontierTerm"] /. logRule /. sub];
  GeneralizedSeries[<|"Kind" -> "Forward", "Scale" -> "Transformed", "CoordinateKind" -> "SourceLog",
    "Expression" -> expression, "Remainder" -> remainder,
    "RemainderScaleExpression" -> If[remainder === 0, 0, remainder /. rr_PowerLogRemainder :> remainderScale[rr]],
    "RemainderPower" -> a["RemainderPower"], "RemainderLogDegree" -> a["RemainderLogDegree"],
    "RemainderVariable" -> q^x, "FrontierTerm" -> frontier, "Terms" -> terms, "Blocks" -> a["Blocks"],
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Length[terms],
    "TermConvention" -> "Each {beta, C} means w^beta C with w = q^x the exponential source chart (logarithms of w have been rewritten as x Log[q]); the cutoff is an exponent of q^x.",
    "LogVariable" -> a["LogVariable"], "LocalVariable" -> a["LocalVariable"],
    "Variable" -> x, "ExpansionPoint" -> Infinity, "Direction" -> "FromBelow",
    "Cutoff" -> a["Cutoff"], "Precision" -> a["Precision"], "Exact" -> a["Exact"],
    "Function" -> f, "Assumptions" -> ass, "TargetDomain" -> chart["Domain"],
    "SeriesData" -> Missing["TransformedCoordinate"],
    "CoordinateSeries" -> inner, "CoordinateSubstitution" -> {sub},
    "SourceCoordinateVariable" -> w, "SourceCoordinateExpression" -> q^x,
    "SourceTransformExpression" -> Log[w]/Log[q], "SourceScale" -> chart["Scale"],
    "TransformedFunction" -> chart["Phase"],
    "Transformations" -> {<|"Type" -> "SourceLog", "Expression" -> q^x, "InverseMap" -> Log[w]/Log[q]|>},
    "QSpecialChart" -> <|"Base" -> q, "Functions" -> chart["Functions"]|>,
    "Transformation" -> "Each q-function at the fixed base is rewritten through infinite q-Pochhammer symbols in the chart variable w = q^x (DLMF 5.18.4, 17.2.6, 17.5.1); the chart phase is an ordinary power-log expression at w -> 0+ and is expanded there.",
    "AsymptoticReference" -> "https://dlmf.nist.gov/5.18.E4, https://dlmf.nist.gov/17.2.E6"|>]];

(* The inverse route uses the same chart through the source-coordinate
   engine (SourceCoordinates.wl), which reconstructs x = Log[w]/Log[q]. *)
sourceQChart[f_, x_, x0_, dir_, ass_, limit_] := Module[{coord, chart},
  If[x0 =!= Infinity || qSpecialFixedBaseFunctions[f, x] === {}, Return[$Failed, Module]];
  coord = localCoordinate[x, x0, dir];
  chart = qSpecialChartPhase[f, x, ass];
  If[chart === $Failed, Return[$Failed, Module]];
  <|"Kind" -> "SourceLog", "Coordinate" -> coord, "ChartVariable" -> chart["ChartVariable"],
    "ChartEndpoint" -> 0, "ChartDirection" -> "FromAbove", "Phase" -> chart["Phase"],
    "SourceCoordinateExpression" -> chart["Base"]^x,
    "SourceTransformExpression" -> Log[chart["ChartVariable"]]/Log[chart["Base"]],
    "Scale" -> chart["Scale"], "QSpecialChart" -> <|"Base" -> chart["Base"], "Functions" -> chart["Functions"]|>,
    "Domain" -> chart["Domain"]|>];
