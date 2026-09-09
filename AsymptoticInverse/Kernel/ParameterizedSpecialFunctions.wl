(* Fixed-parameter special functions in the finite-argument composition
   calculus. Realness of the original expression is checked independently;
   a successful native series still has to satisfy fwdAnalytic's existing
   coefficient and precision checks. No definitions are installed on a
   temporary function symbol. *)

specialParameterizedArgumentPosition[e_, u_] := Module[{h = Head[e], n, varying, allowed},
  If[AtomQ[e] || Head[h] =!= Symbol || Context[Evaluate[h]] =!= "System`", Return[$Failed, Module]];
  n = Length[e];
  varying = Select[Range[n], ! FreeQ[e[[#]], u] &];
  If[Length[varying] =!= 1, Return[$Failed, Module]];
  allowed = Which[
    MemberQ[{BesselJ, BesselI, BesselY, BesselK, StruveH, StruveL,
      ParabolicCylinderD, PolyGamma, PolyLog, ExpIntegralE,
      Zeta, HurwitzZeta, Hypergeometric0F1, Hypergeometric0F1Regularized,
      ChebyshevT, ChebyshevU, HermiteH, LaguerreL, LegendreP}, h] && n === 2, {2},
    MemberQ[{Gamma, GammaRegularized}, h] && MemberQ[{2, 3}, n], Range[2, n],
    MemberQ[{Hypergeometric1F1, Hypergeometric1F1Regularized, HypergeometricU,
      HypergeometricPFQ, HypergeometricPFQRegularized, WhittakerM, WhittakerW,
      LaguerreL, GegenbauerC}, h] && n === 3, {3},
    MemberQ[{Hypergeometric2F1, Hypergeometric2F1Regularized, JacobiP}, h] && n === 4, {4},
    MemberQ[{Beta, BetaRegularized}, h] && n === 3, {1},
    h === LerchPhi && n === 3, {1, 3},
    MemberQ[{EllipticF, EllipticE, EllipticPi, Erf}, h] && n === 2, {1, 2},
    h === EllipticPi && n === 3, {1, 2, 3},
    True, {}];
  If[MemberQ[allowed, First[varying]], First[varying], $Failed]];

(* At zero the displayed special function can have an irrational leading
   power outside SeriesData. These defining-series identities separate that
   power from an analytic function with ordinary integer Taylor exponents.
   The result is {power, analytic body, constant offset, multiplier}.
   Positive arguments make every power identity a principal-real identity.
   References: DLMF 10.2.2, 10.25.2, 11.2.1-2, and 8.7.1. *)
specialParameterizedFrobenius[e_, position_, z_, ass_] := Module[
  {h = Head[e], a = e[[1]], mu, body, offset = 0, multiplier = 1, fixed},
  If[! exactRealQ[a], Return[$Failed, Module]];
  Which[
    MemberQ[{BesselJ, BesselI}, h] && position === 2 && provablyPositive[a + 1, ass],
      mu = a;
      body = Hypergeometric0F1[1 + a, If[h === BesselJ, -1, 1] z^2/4]/
        (2^a Gamma[1 + a]),
    MemberQ[{StruveH, StruveL}, h] && position === 2 && provablyPositive[a + 3/2, ass],
      mu = a + 1;
      body = HypergeometricPFQ[{1}, {3/2, a + 3/2},
        If[h === StruveH, -1, 1] z^2/4]/(2^(a + 1) Gamma[3/2] Gamma[a + 3/2]),
    MemberQ[{Gamma, GammaRegularized}, h] && provablyPositive[a, ass],
      mu = a; body = Hypergeometric1F1[a, a + 1, -z]/a;
      If[h === GammaRegularized, body = body/Gamma[a]];
      If[Length[e] === 2,
        offset = If[h === Gamma, Gamma[a], 1]; multiplier = -1,
        fixed = e[[If[position === 2, 3, 2]]];
        multiplier = If[position === 2, -1, 1];
        offset = -multiplier If[h === Gamma, Gamma[a, 0, fixed], GammaRegularized[a, 0, fixed]]],
    True, Return[$Failed, Module]];
  {mu, body, offset, multiplier}];

specialParameterizedForwardJet[e_, u_, ell_, ass_, Kw_, limit_] := Module[
  {position, result},
  If[TrueQ[$specialParameterizedForwardActive] || ! IntegerQ[limit] || limit < 1 ||
    ! exactQ[e] || ! FreeQ[e, Indeterminate | _DirectedInfinity] ||
    LeafCount[e] > Max[64, Min[4096, limit]], Return[$Failed, Module]];
  position = specialParameterizedArgumentPosition[e, u];
  If[position === $Failed, Return[$Failed, Module]];
  result = Quiet[TimeConstrained[Catch[
    specialParameterizedForwardJetCore[e, position, u, ell, ass, Kw, limit], $tag], 30, $Failed]];
  (* Let the ordinary dispatcher handle inapplicable input and finite-order
     failures. In particular an exact-jet probe is never made artificially
     finite here. The re-entry guard prevents fallback composition cycles. *)
  If[MatchQ[result, {_List, _, _}], result, $Failed]];

specialParameterizedForwardJetCore[e_, position_, u_, ell_, ass_, Kw_, limit_] := Module[
  {domain, argument, jet, negative, center, small, z = Unique["specialArgument$"],
   body, unary, normalized, factor, regular, result, relativeCut, weight},
  argument = e[[position]];
  jet = fwd[argument, u, ell, ass, Kw, limit];
  If[! MatchQ[jet, {_List, _, _}] || ! less[0, jet[[2]]], Return[$Failed, Module]];
  {negative, center, small} = splitJet[jet[[1]]];
  If[negative =!= {} || ! FreeQ[center, ell] ||
    ! TrueQ[TimeConstrained[FullSimplify[Element[center, Reals], ass], 1, False]],
    Return[$Failed, Module]];
  (* fwdAnalytic cannot return an exact jet for a nonconstant increment.
     Reject that probe before proving the whole special function real;
     arguments constant under the assumptions still take the usual path. *)
  If[Kw === Infinity && small =!= {}, Return[$Failed, Module]];
  domain = specialFunctionRealDomain[e, u,
    <|"u" -> u, "Substitution" -> u, "LocalVariable" -> u|>, ass, limit];
  If[! AssociationQ[domain] || ! TrueQ[domain["RealFunctionVerified"]], Return[$Failed, Module]];
  normalized = If[zeroQ[center, ass], specialParameterizedFrobenius[e, position, z, ass], $Failed];
  result = Block[{$specialParameterizedForwardActive = True},
    If[ListQ[normalized] &&
       TrueQ[specialFunctionDomainEventuallyQ[argument > 0, u, ass, e]],
      factor = fwdPower[jet, normalized[[1]], u, ell, ass, Kw, limit];
      weight = If[jet[[1]] === {}, jet[[2]], jetValuation[jet[[1]]]];
      relativeCut = If[Kw === Infinity, Infinity, Kw - normalized[[1]] weight];
      body = normalized[[2]];
      unary = Apply[Function, {{z}, body}];
      regular = fwdAnalytic[unary, jet, body /. z -> argument,
        u, ell, ass, relativeCut, limit];
      pAdd[pConst[normalized[[3]], ell, ass],
        pScale[pMul[factor, regular, ell, ass, limit], normalized[[4]], ell, ass], ell, ass],
      body = ReplacePart[e, position -> z];
      unary = Apply[Function, {{z}, body}];
      fwdAnalytic[unary, jet, e, u, ell, ass, Kw, limit]]];
  If[! MatchQ[result, {_List, _, _}] ||
    ! AllTrue[result[[1]], PolynomialQ[#[[2]], ell] &&
      TrueQ[TimeConstrained[FullSimplify[Element[#[[2]], Reals],
        ass && Element[ell, Reals]], 1, False]] &], Return[$Failed, Module]];
  result];
