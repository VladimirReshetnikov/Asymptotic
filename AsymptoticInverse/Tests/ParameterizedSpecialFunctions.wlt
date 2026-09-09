(* Fixed-parameter composition with irrational input powers. Expected
   coefficients come from defining series and derivatives, not Series. *)

parameterizedSpecialEqual[s_, expected_, ass_: True] :=
  MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[s] == expected, ass]];

VerificationTest[Module[{x, s, nu = Sqrt[2]},
  s = AsymptoticExpansion[BesselJ[nu, x^nu], {x, 0, 5}];
  parameterizedSpecialEqual[s,
    x^2/(2^nu Gamma[1 + nu]) (1 - x^(2 nu)/(4 (1 + nu))), x > 0]],
  True, TestID -> "parameterized-bessel-j-irrational-order-and-argument"]

VerificationTest[Module[{x, s, nu = Sqrt[2]},
  s = AsymptoticExpansion[BesselI[nu, x^nu], {x, 0, 5}];
  parameterizedSpecialEqual[s,
    x^2/(2^nu Gamma[1 + nu]) (1 + x^(2 nu)/(4 (1 + nu))), x > 0]],
  True, TestID -> "parameterized-bessel-i-irrational-order-and-argument"]

VerificationTest[Module[{x, s, r = Sqrt[2]},
  s = AsymptoticExpansion[PolyGamma[1, 1 + x^r], {x, 0, 5}];
  parameterizedSpecialEqual[s,
    Pi^2/6 - 2 Zeta[3] x^r + Pi^4 x^(2 r)/30 - 4 Zeta[5] x^(3 r), x > 0]],
  True, TestID -> "parameterized-trigamma-positive-center-derivative-formula"]

VerificationTest[Module[{x, s, r = Sqrt[2]},
  s = AsymptoticExpansion[Gamma[3/2, 0, x^r], {x, 0, 5}];
  parameterizedSpecialEqual[s,
    2 x^(3 r/2)/3 - 2 x^(5 r/2)/5 + x^(7 r/2)/7, x > 0]],
  True, TestID -> "parameterized-lower-gamma-irrational-input"]

VerificationTest[Module[{x, s, r = Sqrt[2]},
  s = AsymptoticExpansion[Gamma[r, x^r], {x, 0, 5}];
  parameterizedSpecialEqual[s,
    Gamma[r] - x^2/r + x^(2 + r)/(r + 1) - x^(2 + 2 r)/(2 (r + 2)), x > 0]],
  True, TestID -> "parameterized-upper-gamma-irrational-shape-and-input"]

VerificationTest[Module[{x, s, r = Sqrt[2]},
  s = AsymptoticExpansion[Gamma[3/2, x^r, 2], {x, 0, 5}];
  parameterizedSpecialEqual[s, Gamma[3/2, 0, 2] -
    2 x^(3 r/2)/3 + 2 x^(5 r/2)/5 - x^(7 r/2)/7, x > 0]],
  True, TestID -> "parameterized-gamma-varying-lower-integration-limit"]

VerificationTest[Module[{x, s, r = Sqrt[2]},
  s = AsymptoticExpansion[GammaRegularized[3/2, 0, x^r], {x, 0, 5}];
  parameterizedSpecialEqual[s,
    (2 x^(3 r/2)/3 - 2 x^(5 r/2)/5 + x^(7 r/2)/7)/Gamma[3/2], x > 0]],
  True, TestID -> "parameterized-regularized-lower-gamma-normalization"]

VerificationTest[Module[{x, b, s, r = Sqrt[2]},
  s = AsymptoticExpansion[Hypergeometric0F1[b, x^r], {x, 0, 5}, Assumptions -> b > 0];
  parameterizedSpecialEqual[s,
    1 + x^r/b + x^(2 r)/(2 b (b + 1)) + x^(3 r)/(6 b (b + 1) (b + 2)),
    b > 0 && x > 0]],
  True, TestID -> "parameterized-symbolic-fixed-positive-parameter"]

VerificationTest[Module[{x, s, r = Sqrt[2], expected},
  s = AsymptoticExpansion[Hypergeometric2F1[1/3, 2/3, 5/4, x^r], {x, 0, 5}];
  expected = Sum[Pochhammer[1/3, k] Pochhammer[2/3, k]/
    (Pochhammer[5/4, k] k!) x^(k r), {k, 0, 3}];
  parameterizedSpecialEqual[s, expected, 0 < x < 1]],
  True, TestID -> "parameterized-gauss-function-irrational-input"]

VerificationTest[Module[{x, s, r = Sqrt[2]},
  s = AsymptoticExpansion[StruveL[0, x^r], {x, 0, 5}];
  parameterizedSpecialEqual[s, 2 x^r/Pi + 2 x^(3 r)/(9 Pi), x > 0]],
  True, TestID -> "parameterized-struve-normalized-defining-series"]

VerificationTest[Module[{x, y, s, r = Sqrt[2]},
  (* f(x)=x-x^(2 r)/4+..., so reversion first changes the sign. *)
  s = AsymptoticInverse[x + BesselJ[0, x^r] - 1, {x, 0}, {y, 4}];
  parameterizedSpecialEqual[s, y + y^(2 r)/4, y > 0]],
  True, TestID -> "parameterized-bessel-composition-reused-by-inverse"]

VerificationTest[Module[{u, ell, unknown},
  AsymptoticInverse`Private`specialParameterizedForwardJet[#, u, ell, True, 5, 20000] & /@
    {unknown[1, u], BesselJ[u, u], BesselJ[u, 1], BesselJ[0, 1/u]}],
  ConstantArray[$Failed, 4], TestID -> "parameterized-unrecognized-varying-parameter-and-infinite-endpoint-decline"]

VerificationTest[Module[{u, ell},
  AsymptoticInverse`Private`specialParameterizedForwardJet[
    BesselJ[Sqrt[2], -u^Sqrt[2]], u, ell, True, 5, 20000]],
  $Failed, TestID -> "parameterized-principal-complex-branch-not-admitted"]

VerificationTest[Module[{u, ell, jet},
  jet = AsymptoticInverse`Private`specialParameterizedForwardJet[
    PolyGamma[1, 1 + u^Sqrt[2]], u, ell, True, 5, 20000];
  MatchQ[jet, {_List, _, _}] &&
    TrueQ[FullSimplify[Total[(u^#[[1]] #[[2]] &) /@ jet[[1]]] ==
      Pi^2/6 - 2 Zeta[3] u^Sqrt[2] + Pi^4 u^(2 Sqrt[2])/30 - 4 Zeta[5] u^(3 Sqrt[2]), u > 0]] &&
    TrueQ[jet[[2]] >= 5] && jet[[3]] === 0],
  True, TestID -> "parameterized-private-jet-contract-and-propagated-precision"]
