(* Exact special-function identities applied before any finite asymptotic
   expansion. A terminating dominant expansion need not be the exact function:
   I_(1/2)(z), for example, contains both exp(z) and exp(-z).
   This module never derives an identity from a truncated asymptotic series. *)

specialIdentityRecord[expression_, domain_, references_, limit_] :=
  If[LeafCount[expression] > limit, $Failed,
    <|"Expression" -> expression, "Domain" -> domain, "References" -> references|>];

specialIdentityProve[condition_, ass_] :=
  TrueQ[inverseBranchTry[FullSimplify[condition, ass]]];

(* This only discharges a side condition of an exact identity. The caller's
   separate real-domain analysis remains responsible for the original input. *)
specialIdentityTailQ[condition_, x_, coord_, ass_] := Module[{parameters, local},
  parameters = DeleteDuplicates[Cases[{condition},
    p_Symbol /; p =!= x && Context[p] =!= "System`", Infinity]];
  If[! AllTrue[parameters, specialIdentityProve[Element[#, Reals], ass] &],
    Return[False, Module]];
  local = condition /. x -> coord["Substitution"];
  TrueQ[inverseBranchTry[inverseFunctionEventually[local, coord["u"], ass]]]];

(* DLMF 10.39.1--2, 10.29.1 and 10.27.2--3. Recurrence is performed on
   finite expressions in the two exponentials, with the square root outside. *)
specialFunctionHalfBessel[head_, order_, z_, limit_] := Module[
  {n = Abs[order] - 1/2, previous, current, next, k, result},
  If[! IntegerQ[n] || n < 0 || n > Min[32, limit], Return[$Failed, Module]];
  If[head === BesselK,
    result = Sqrt[Pi/2] Exp[-z]/Sqrt[z] Sum[
      Factorial[n + k]/(Factorial[k] Factorial[n - k] (2 z)^k), {k, 0, n}],
    If[head =!= BesselI, Return[$Failed, Module]];
    previous = (Exp[z] + Exp[-z])/2; current = (Exp[z] - Exp[-z])/2;
    Do[next = Expand[previous - (2 k - 1) current/z];
      previous = current; current = next;
      If[LeafCount[current] > limit, Return[$Failed, Module]], {k, 1, n}];
    result = Sqrt[2/Pi] current/Sqrt[z];
    If[order < 0, result += 2 (-1)^n/Pi specialFunctionHalfBessel[BesselK, -order, z, limit]]];
  If[! FreeQ[result, $Failed] || LeafCount[result] > limit, $Failed, result]];

(* Finite defining hypergeometric sums. Ordinary denominator parameters are
   excluded from their poles even when a numerator also terminates. Such
   simultaneous singular parameter limits must be specified separately.
   Regularized functions instead have reciprocal-Gamma coefficients. *)
specialFunctionTerminatingHypergeometric[upper_List, lower_List, z_, regularized_, ass_, limit_] := Module[
  {degrees, n, condition, coefficients, k, polynomial},
  degrees = Cases[upper, (a_Integer /; a <= 0) :> -a];
  If[degrees === {}, Return[$Failed, Module]];
  n = Min[degrees];
  If[n > Min[32, limit], Return[$Failed, Module]];
  condition = If[TrueQ[regularized], True,
    And @@ ((# > 0 || ! Element[#, Integers]) & /@ lower)];
  If[! specialIdentityProve[condition, ass], Return[$Failed, Module]];
  coefficients = Table[(Times @@ (Pochhammer[#, k] & /@ upper))/Factorial[k] *
    If[TrueQ[regularized], Times @@ (1/Gamma[# + k] & /@ lower),
      1/(Times @@ (Pochhammer[#, k] & /@ lower))], {k, 0, n}];
  polynomial = Total[MapIndexed[#1 z^(First[#2] - 1) &, coefficients]];
  specialIdentityRecord[polynomial, condition, {"https://dlmf.nist.gov/16.2"}, limit]];

specialFunctionIdentity[e_, x_, coord_, ass_, limit_] := Module[
  {head = Head[e], z, a, b, c, n, upper, lower, regularized, result, condition, endpoint},
  If[MemberQ[{BesselI, BesselK}, head] && Length[e] === 2,
    {a, z} = List @@ e;
    If[FreeQ[a, x] && IntegerQ[2 a] && OddQ[2 a] &&
        specialIdentityTailQ[z > 0, x, coord, ass],
      result = specialFunctionHalfBessel[head, a, z, limit];
      If[result =!= $Failed, Return[specialIdentityRecord[result, z > 0,
        {"https://dlmf.nist.gov/10.39", "https://dlmf.nist.gov/10.29", "https://dlmf.nist.gov/10.27"}, limit], Module]]]];

  If[MemberQ[{Hypergeometric1F1, Hypergeometric1F1Regularized,
      Hypergeometric2F1, Hypergeometric2F1Regularized, HypergeometricPFQ, HypergeometricPFQRegularized}, head],
    regularized = MemberQ[{Hypergeometric1F1Regularized, Hypergeometric2F1Regularized, HypergeometricPFQRegularized}, head];
    Which[
      MemberQ[{Hypergeometric1F1, Hypergeometric1F1Regularized}, head] && Length[e] === 3,
        upper = {e[[1]]}; lower = {e[[2]]}; z = e[[3]],
      MemberQ[{Hypergeometric2F1, Hypergeometric2F1Regularized}, head] && Length[e] === 4,
        upper = {e[[1]], e[[2]]}; lower = {e[[3]]}; z = e[[4]],
      MemberQ[{HypergeometricPFQ, HypergeometricPFQRegularized}, head] && Length[e] === 3 &&
          MatchQ[e[[1]], _List] && MatchQ[e[[2]], _List],
        upper = e[[1]]; lower = e[[2]]; z = e[[3]],
      True, Return[$Failed, Module]];
    If[! FreeQ[{upper, lower}, x], Return[$Failed, Module]];
    result = specialFunctionTerminatingHypergeometric[upper, lower, z, regularized, ass, limit];
    If[result =!= $Failed, Return[result, Module]];
    (* Nonterminating elementary cases below use ordinary normalization. *)
    If[TrueQ[regularized], Return[$Failed, Module]];
    condition = And @@ ((# > 0 || ! Element[#, Integers]) & /@ lower);
    If[! specialIdentityProve[condition, ass], Return[$Failed, Module]];
    If[head === Hypergeometric1F1,
      {a, b} = {First[upper], First[lower]};
      If[specialIdentityProve[a == b, ass],
        Return[specialIdentityRecord[Exp[z], condition, {"https://dlmf.nist.gov/13.6.E1"}, limit], Module]];
      (* Repeated integration by parts in M(n,n+1,z)=n Integrate[
         Exp[z t] t^(n-1),{t,0,1}] retains the endpoint contribution at t=0. *)
      If[IntegerQ[a] && 0 < a <= Min[32, limit] && b === a + 1 &&
          specialIdentityTailQ[z != 0, x, coord, ass],
        result = (-1)^(a - 1) Factorial[a]/z^a *
          (Exp[z] Sum[(-z)^n/Factorial[n], {n, 0, a - 1}] - 1);
        Return[specialIdentityRecord[result, condition && z != 0,
          {"https://dlmf.nist.gov/13.4.E1", "https://dlmf.nist.gov/13.6.E2"}, limit], Module]]];
    If[head === Hypergeometric2F1,
      {a, b, c} = {upper[[1]], upper[[2]], First[lower]};
      If[specialIdentityTailQ[1 - z > 0, x, coord, ass],
        If[specialIdentityProve[c == a, ass],
          Return[specialIdentityRecord[(1 - z)^(-b), condition && 1 - z > 0,
            {"https://dlmf.nist.gov/15.4.E6"}, limit], Module]];
        If[specialIdentityProve[c == b, ass],
          Return[specialIdentityRecord[(1 - z)^(-a), condition && 1 - z > 0,
            {"https://dlmf.nist.gov/15.4.E6"}, limit], Module]];
        If[{a, b, c} === {1, 1, 2} && specialIdentityTailQ[z != 0, x, coord, ass],
          Return[specialIdentityRecord[-Log[1 - z]/z, condition && 1 - z > 0 && z != 0,
            {"https://dlmf.nist.gov/15.4.E1"}, limit], Module]]]]];

  If[head === HypergeometricU && Length[e] === 3,
    {a, b, z} = List @@ e;
    If[FreeQ[{a, b}, x],
      If[IntegerQ[a] && -Min[32, limit] <= a <= 0,
        n = -a;
        result = Sum[(-1)^(n + k) Binomial[n, k] Pochhammer[b + k, n - k] z^k, {k, 0, n}];
        Return[specialIdentityRecord[result, True, {"https://dlmf.nist.gov/13.6.E19"}, limit], Module]];
      If[specialIdentityProve[b == a + 1, ass] && specialIdentityTailQ[z > 0, x, coord, ass],
        Return[specialIdentityRecord[z^(-a), z > 0, {"https://dlmf.nist.gov/13.6.E4"}, limit], Module]]]];

  If[head === Gamma && Length[e] === 2 && IntegerQ[e[[1]]] && 0 < e[[1]] <= Min[32, limit],
    {n, z} = List @@ e;
    Return[specialIdentityRecord[Factorial[n - 1] Exp[-z] Sum[z^k/Factorial[k], {k, 0, n - 1}],
      True, {"https://dlmf.nist.gov/8.4.E8"}, limit], Module]];
  If[head === ExpIntegralE && Length[e] === 2 && IntegerQ[e[[1]]] &&
      -Min[32, limit] <= e[[1]] <= 0 && specialIdentityTailQ[e[[2]] > 0, x, coord, ass],
    n = -e[[1]]; z = e[[2]];
    Return[specialIdentityRecord[Exp[-z] Sum[Factorial[n]/(Factorial[n - k] z^(k + 1)), {k, 0, n}],
      z > 0, {"https://dlmf.nist.gov/8.19.E1", "https://dlmf.nist.gov/8.4.E8"}, limit], Module]];
  If[head === ExpIntegralEi && Length[e] === 1 && specialIdentityTailQ[First[e] < 0, x, coord, ass],
    Return[specialIdentityRecord[-ExpIntegralE[1, -First[e]], First[e] < 0,
      {"https://dlmf.nist.gov/6.2.E6"}, limit], Module]];

  If[MemberQ[{Erf, Erfc, Erfi}, head] && Length[e] === 1 &&
      specialIdentityTailQ[First[e] < 0, x, coord, ass],
    z = -First[e]; result = If[head === Erfc, 2 - Erfc[z], -head[z]];
    Return[specialIdentityRecord[result, First[e] < 0, {"https://dlmf.nist.gov/7.4.i"}, limit], Module]];
  (* Native evaluation of half-integer I may already have produced Sinh/Cosh.
     Keep the exact second exponential instead of expanding only the dominant one. *)
  If[MemberQ[{Sinh, Cosh}, head] && Length[e] === 1,
    z = First[e]; endpoint = inverseBranchTry[Limit[z /. x -> coord["Substitution"],
      coord["u"] -> 0, Direction -> "FromAbove", Assumptions -> ass]];
    If[MemberQ[{Infinity, -Infinity}, endpoint],
      Return[specialIdentityRecord[(Exp[z] + If[head === Sinh, -1, 1] Exp[-z])/2,
        True, {"https://dlmf.nist.gov/4.28"}, limit], Module]]];
  $Failed];

specialFunctionNormalize[f_, x_, coord_, ass_, limit_] := Module[
  {walk, domains = {}, references = {}, normalized},
  validateInput[f, limit];
  If[LeafCount[f] > limit, fail["ResourceLimit", "Exact special-function normalization exceeds MaxTerms expression leaves."]];
  walk[e_] := Module[{value, identity},
    If[AtomQ[e] || FreeQ[e, x] || ! MatchQ[Head[e], _Symbol] ||
        MemberQ[{Piecewise, ConditionalExpression}, Head[e]] ||
        ! FreeQ[With[{h = Head[e]}, Attributes[h]], HoldAll | HoldAllComplete | HoldFirst | HoldRest],
      Return[e, Module]];
    value = Map[walk, e]; identity = specialFunctionIdentity[value, x, coord, ass, limit];
    If[AssociationQ[identity] && identity["Expression"] =!= value,
      AppendTo[domains, identity["Domain"]]; references = Join[references, identity["References"]];
      value = identity["Expression"]];
    value];
  normalized = walk[f];
  validateInput[normalized, limit];
  If[LeafCount[normalized] > limit,
    fail["ResourceLimit", "Exact special-function normalization exceeds MaxTerms expression leaves."]];
  <|"Expression" -> normalized, "Domain" -> And @@ domains,
    "Changed" -> (normalized =!= f), "References" -> DeleteDuplicates[references]|>];
