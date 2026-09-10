(* Sufficient real domains for the original function, before a native
   asymptotic expansion is projected onto its real part. This is not an
   asymptotic validity or continuity certificate. In particular it neither
   removes Stokes terms nor assigns errors to an unevaluated native result.

   Every successful result describes an eventually valid real domain in
   both the source variable and the positive local coordinate. Failure to
   prove a sufficient domain returns $Failed without throwing. *)

SetAttributes[specialFunctionDomainTry, HoldAll];
specialFunctionDomainTry[e_] := Quiet[TimeConstrained[Check[e, $Failed], 1, $Failed]];

specialFunctionDomainParametersRealQ[e_, u_, ass_] := Module[{parameters},
  parameters = DeleteDuplicates[Cases[e, s_Symbol /;
    s =!= u && Context[s] =!= "System`", {0, Infinity}]];
  AllTrue[parameters,
    TrueQ[specialFunctionDomainTry[FullSimplify[Element[#, Reals], ass]]] &]];

specialFunctionDomainEventuallyQ[condition_, u_, ass_, source_] := Module[{simple},
  simple = specialFunctionDomainTry[FullSimplify[condition, ass && u > 0]];
  If[TrueQ[simple], Return[True, Module]];
  If[simple === $Failed || simple === False || ! FreeQ[simple, _Element] ||
     ! specialFunctionDomainParametersRealQ[source, u, ass], Return[False, Module]];
  (* Resolve[..., Reals] must not supply missing real parameter assumptions.
     Integer membership and other unresolved Element predicates are also
     discharged before calling the shared eventual-neighborhood prover. *)
  TrueQ[TimeConstrained[inverseFunctionEventually[simple, u, ass], 2, False]]];

specialFunctionRealDomain[f_, x_, coord_, ass_, limit_] := Module[{result},
  If[! AssociationQ[coord] || ! AllTrue[{"u", "Substitution", "LocalVariable"},
      KeyExistsQ[coord, #] &] || Head[x] =!= Symbol ||
     ! IntegerQ[limit] || limit < 1 || ! exactQ[f] ||
     ! FreeQ[f, Indeterminate | _DirectedInfinity] ||
     LeafCount[f] > Max[64, Min[4096, limit]], Return[$Failed, Module]];
  result = Quiet[TimeConstrained[
    specialFunctionRealDomainCore[f, x, coord, ass], 8, $Failed]];
  If[AssociationQ[result], result, $Failed]];

specialFunctionRealDomainCore[f_, x_, coord_, ass_] := Module[
  {u = coord["u"], local, condition, domain, references = {},
   walk, allReal, fixedRealQ, validDenominatorQ, record, generic,
   method = "PrincipalRealDomainContracts"},
  local = f /. x -> coord["Substitution"];
  generic = specialFunctionDomainTry[FullSimplify[Element[local, Reals], ass && u > 0]];
  If[TrueQ[generic],
    Return[<|"Domain" -> (coord["LocalVariable"] > 0), "LocalDomain" -> (u > 0),
      "RealFunctionVerified" -> True, "Method" -> "SymbolicRealnessProof",
      "References" -> {}, "Assumptions" -> ass|>, Module]];

  fixedRealQ[values_List] := FreeQ[values, u] && AllTrue[values,
    TrueQ[specialFunctionDomainTry[FullSimplify[Element[#, Reals], ass]]] &];
  validDenominatorQ[b_] := TrueQ[specialFunctionDomainTry[
    FullSimplify[b > 0 || ! Element[b, Integers], ass]]];
  allReal[values_List] := Module[{parts = walk /@ values},
    If[MemberQ[parts, $Failed], $Failed, And @@ parts]];
  record[values_List, restriction_, reference_] := Module[{real = allReal[values]},
    If[real === $Failed, Return[$Failed, Module]];
    If[reference =!= None, AppendTo[references, reference]];
    real && restriction];

  walk[e_] := walk[e] = Module[{a, head = Head[e], n},
    If[e === u, Return[True, Module]];
    If[FreeQ[e, u], Return[If[TrueQ[specialFunctionDomainTry[
      FullSimplify[Element[e, Reals], ass]]], True, $Failed], Module]];
    If[AtomQ[e], Return[$Failed, Module]];
    a = List @@ e; n = Length[a];
    Which[
      MemberQ[{Plus, Times}, head], allReal[a],
      head === Power && n === 2,
        If[IntegerQ[a[[2]]], record[{a[[1]]}, If[a[[2]] < 0, a[[1]] != 0, True], None],
          record[a, a[[1]] > 0, None]],
      head === Log && n === 1, record[a, a[[1]] > 0, None],
      MemberQ[{Sin, Cos, Sinh, Cosh, Tanh, ArcTan, ArcSinh, Abs}, head] && n === 1,
        record[a, True, None],
      MemberQ[{ArcSin, ArcCos}, head] && n === 1,
        record[a, -1 <= a[[1]] <= 1, None],
      head === ArcCosh && n === 1, record[a, a[[1]] >= 1, None],
      head === ArcTanh && n === 1, record[a, -1 < a[[1]] < 1, None],
      MemberQ[{Tan, Sec}, head] && n === 1, record[a, Cos[a[[1]]] != 0, None],
      MemberQ[{Cot, Csc}, head] && n === 1, record[a, Sin[a[[1]]] != 0, None],
      MemberQ[{Coth, Csch}, head] && n === 1, record[a, a[[1]] != 0, None],
      head === Sech && n === 1, record[a, True, None],

      (* Defining real integrals / real initial data establish entire
         real-valued restrictions: https://dlmf.nist.gov/7.2 and /9.2. *)
      MemberQ[{Erf, Erfc, Erfi, DawsonF, FresnelC, FresnelS}, head] && n === 1,
        record[a, True, "https://dlmf.nist.gov/7.2"],
      head === Erf && n === 2, record[a, True, "https://dlmf.nist.gov/7.2"],
      MemberQ[{AiryAi, AiryBi, AiryAiPrime, AiryBiPrime}, head] && n === 1,
        record[a, True, "https://dlmf.nist.gov/9.2"],
      (* Positive arguments avoid the principal logarithmic cuts of Ci,
         Chi and Ei. Si and Shi have real entire continuations. *)
      MemberQ[{SinIntegral, SinhIntegral}, head] && n === 1,
        record[a, True, "https://dlmf.nist.gov/6.2"],
      MemberQ[{CosIntegral, CoshIntegral, ExpIntegralEi}, head] && n === 1,
        record[a, a[[1]] > 0, "https://dlmf.nist.gov/6.2"],
      head === LogIntegral && n === 1,
        record[a, a[[1]] > 0 && a[[1]] != 1, "https://dlmf.nist.gov/6.2"],
      head === ExpIntegralE && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, a[[2]] > 0, "https://dlmf.nist.gov/8.19"],

      (* DLMF 10.2(ii), 10.25(ii), and 11.2: the principal cylinder and
         Struve functions are real for real order and positive argument.
         Integer J/I orders additionally give an entire real restriction. *)
      MemberQ[{BesselJ, BesselI}, head] && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, If[TrueQ[specialFunctionDomainTry[
          FullSimplify[Element[a[[1]], Integers], ass]]], True, a[[2]] > 0],
          If[head === BesselJ, "https://dlmf.nist.gov/10.2", "https://dlmf.nist.gov/10.25"]],
      MemberQ[{BesselY, BesselK}, head] && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, a[[2]] > 0,
          If[head === BesselY, "https://dlmf.nist.gov/10.2", "https://dlmf.nist.gov/10.25"]],
      MemberQ[{StruveH, StruveL}, head] && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, a[[2]] > 0, "https://dlmf.nist.gov/11.2"],
      head === ParabolicCylinderD && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, True, "https://dlmf.nist.gov/12.2"],

      (* Positive-axis gamma integrals and real analytic continuation in
         fixed parameters: https://dlmf.nist.gov/8.2. No assertion is made
         across infinitely many negative-axis gamma poles or Barnes zeros. *)
      MemberQ[{Gamma, LogGamma, BarnesG, LogBarnesG}, head] && n === 1,
        record[a, a[[1]] > 0, If[MemberQ[{BarnesG, LogBarnesG}, head],
          "https://dlmf.nist.gov/5.17", "https://dlmf.nist.gov/5.2"]],
      head === PolyGamma && n === 2 && fixedRealQ[{a[[1]]}] &&
        TrueQ[specialFunctionDomainTry[FullSimplify[
          Element[a[[1]], Integers] && a[[1]] >= 0, ass]]],
        record[{a[[2]]}, a[[2]] > 0, "https://dlmf.nist.gov/5.15"],
      head === Gamma && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, a[[2]] > 0, "https://dlmf.nist.gov/8.2"],
      head === Gamma && n === 3 && fixedRealQ[{a[[1]]}],
        record[Rest[a], (a[[2]] > 0 && a[[3]] > 0) ||
          (a[[1]] > 0 && a[[2]] >= 0 && a[[3]] >= 0), "https://dlmf.nist.gov/8.2"],
      head === GammaRegularized && MemberQ[{2, 3}, n] && fixedRealQ[{a[[1]]}],
        record[Rest[a], a[[1]] > 0 && And @@ (# >= 0 & /@ Rest[a]), "https://dlmf.nist.gov/8.2"],
      head === Beta && n === 2, record[a, And @@ (# > 0 & /@ a), "https://dlmf.nist.gov/5.12"],
      MemberQ[{Beta, BetaRegularized}, head] && n === 3 && fixedRealQ[Rest[a]],
        record[{a[[1]]}, 0 < a[[1]] < 1 && a[[2]] > 0 && a[[3]] > 0,
          "https://dlmf.nist.gov/8.17"],

      (* Real Taylor coefficients and continuation avoiding [1,Infinity)
         give the hypergeometric principal real branch. Denominator poles
         are excluded explicitly; regularized functions remove them.
         https://dlmf.nist.gov/13.2 and https://dlmf.nist.gov/16.2. *)
      MemberQ[{Hypergeometric0F1, Hypergeometric0F1Regularized}, head] && n === 2 &&
        fixedRealQ[{a[[1]]}] && (head === Hypergeometric0F1Regularized || validDenominatorQ[a[[1]]]),
        record[{a[[2]]}, True, "https://dlmf.nist.gov/16.2"],
      MemberQ[{Hypergeometric1F1, Hypergeometric1F1Regularized}, head] && n === 3 &&
        fixedRealQ[Most[a]] && (head === Hypergeometric1F1Regularized || validDenominatorQ[a[[2]]]),
        record[{a[[3]]}, True, "https://dlmf.nist.gov/13.2"],
      MemberQ[{Hypergeometric2F1, Hypergeometric2F1Regularized}, head] && n === 4 &&
        fixedRealQ[Most[a]] && (head === Hypergeometric2F1Regularized || validDenominatorQ[a[[3]]]),
        record[{a[[4]]}, a[[4]] < 1, "https://dlmf.nist.gov/16.2"],
      MemberQ[{HypergeometricPFQ, HypergeometricPFQRegularized}, head] && n === 3 &&
        ListQ[a[[1]]] && ListQ[a[[2]]] && fixedRealQ[Join[a[[1]], a[[2]]]] &&
        Length[a[[1]]] <= Length[a[[2]]] + 1 &&
        (head === HypergeometricPFQRegularized || AllTrue[a[[2]], validDenominatorQ]),
        record[{a[[3]]}, If[Length[a[[1]]] <= Length[a[[2]]], True, a[[3]] < 1],
          "https://dlmf.nist.gov/16.2"],
      head === HypergeometricU && n === 3 && fixedRealQ[Most[a]],
        record[{a[[3]]}, a[[3]] > 0, "https://dlmf.nist.gov/13.2"],
      MemberQ[{WhittakerM, WhittakerW}, head] && n === 3 && fixedRealQ[Most[a]] &&
        (head === WhittakerW || validDenominatorQ[2 a[[2]] + 1]),
        record[{a[[3]]}, a[[3]] > 0, "https://dlmf.nist.gov/13.14"],

      (* Hurwitz zeta is meromorphic in s with its sole pole at 1 for
         positive a. Polylogarithms use the cut [1,Infinity). The Lerch
         contract uses its convergent real defining series. *)
      head === Zeta && n === 1,
        record[a, a[[1]] != 1, "https://dlmf.nist.gov/25.2"],
      MemberQ[{Zeta, HurwitzZeta}, head] && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, a[[1]] != 1 && a[[2]] > 0, "https://dlmf.nist.gov/25.11"],
      head === PolyLog && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, a[[2]] < 1, "https://dlmf.nist.gov/25.12"],
      head === LerchPhi && n === 3 && fixedRealQ[{a[[2]]}],
        record[{a[[1]], a[[3]]}, -1 < a[[1]] < 1 && a[[3]] > 0,
          "https://dlmf.nist.gov/25.14"],

      (* Wolfram uses the parameter m=k^2. The sufficient conditions m<1
         and n<1 keep the defining elliptic integrands real and finite on
         every real amplitude interval: https://dlmf.nist.gov/19.2. *)
      MemberQ[{EllipticK, EllipticE}, head] && n === 1,
        record[a, a[[1]] < 1, "https://dlmf.nist.gov/19.2"],
      MemberQ[{EllipticF, EllipticE}, head] && n === 2,
        record[a, a[[2]] < 1, "https://dlmf.nist.gov/19.2"],
      head === EllipticPi && n === 2,
        record[a, a[[1]] < 1 && a[[2]] < 1, "https://dlmf.nist.gov/19.2"],
      head === EllipticPi && n === 3,
        record[a, a[[1]] < 1 && a[[3]] < 1, "https://dlmf.nist.gov/19.2"],

      (* Nonnegative integral degrees give real polynomials; general
         Legendre Q and associated/type-dependent branches are not covered.
         Polynomial formulas: https://dlmf.nist.gov/18.5. *)
      MemberQ[{ChebyshevT, ChebyshevU, HermiteH, LaguerreL, LegendreP}, head] && n === 2 &&
        fixedRealQ[{a[[1]]}] && TrueQ[specialFunctionDomainTry[
          FullSimplify[Element[a[[1]], Integers] && a[[1]] >= 0, ass]]],
        record[{a[[2]]}, True, "https://dlmf.nist.gov/18.5"],
      MemberQ[{LaguerreL, GegenbauerC}, head] && n === 3 && fixedRealQ[Most[a]] &&
        TrueQ[specialFunctionDomainTry[FullSimplify[
          Element[a[[1]], Integers] && a[[1]] >= 0, ass]]],
        record[{a[[3]]}, If[head === GegenbauerC, a[[2]] > 0, True],
          "https://dlmf.nist.gov/18.5"],
      head === JacobiP && n === 4 && fixedRealQ[Most[a]] &&
        TrueQ[specialFunctionDomainTry[FullSimplify[
          Element[a[[1]], Integers] && a[[1]] >= 0, ass]]],
        record[{a[[4]]}, True, "https://dlmf.nist.gov/18.5"],
      True,
        If[TrueQ[specialFunctionDomainTry[FullSimplify[Element[e, Reals], ass && u > 0]]],
          True, $Failed]
    ]
  ];

  condition = walk[local];
  If[condition === $Failed ||
     ! specialFunctionDomainEventuallyQ[condition, u, ass, local],
    (* FunctionDomain is a final generic route, after explicit parameter
       reality. Rechecking Element under the returned domain prevents a
       domain merely assumed by the symbolic solver from becoming proof. *)
    If[! specialFunctionDomainParametersRealQ[local, u, ass], Return[$Failed, Module]];
    domain = specialFunctionDomainTry[FunctionDomain[local, u, Reals]];
    If[domain === $Failed || ! FreeQ[domain, _FunctionDomain | _ConditionalExpression | _Element] ||
       ! specialFunctionDomainEventuallyQ[domain, u, ass, local] ||
       ! TrueQ[specialFunctionDomainTry[FullSimplify[Element[local, Reals], ass && u > 0 && domain]]],
      Return[$Failed, Module]];
    condition = domain; references = {}; method = "SymbolicFunctionDomainProof"];
  condition = u > 0 && condition;
  <|"Domain" -> (condition /. u -> coord["LocalVariable"]),
    "LocalDomain" -> condition, "RealFunctionVerified" -> True,
    "Method" -> method, "References" -> DeleteDuplicates[references], "Assumptions" -> ass|>
];
