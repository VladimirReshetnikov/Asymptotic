(* Real local branches for unevaluated InverseFunction nodes. This module
   never equates a bounded candidate search with a completeness proof. *)

SetAttributes[inverseBranchTry, HoldAll];
inverseBranchTry[expression_] := Quiet[TimeConstrained[Check[expression, $Failed], 2, $Failed]];
inverseBranchResolvedQ[e_] := e =!= $Failed &&
  FreeQ[e, _Reduce | _Resolve | _Solve | _FunctionDomain | _Limit | _ConditionalExpression | _C];

inverseBranchFiniteRoots[condition_, x_, ass_] := Module[{reduced, points, equality},
  reduced = inverseBranchTry[Reduce[ass && condition, x, Reals]];
  If[! inverseBranchResolvedQ[reduced], Return[<|"Points" -> {}, "Complete" -> False|>, Module]];
  points = Join[Cases[reduced, Equal[x, c_] /; FreeQ[c, x] && exactRealQ[c] :> c, {0, Infinity}],
    Cases[reduced, Equal[c_, x] /; FreeQ[c, x] && exactRealQ[c] :> c, {0, Infinity}]];
  points = DeleteDuplicates[canon /@ points, equal];
  equality = Or @@ ((x == #) & /@ points);
  <|"Points" -> points,
    "Complete" -> TrueQ[inverseBranchTry[FullSimplify[Equivalent[reduced, equality], ass]]],
    "ReducedCondition" -> reduced|>];

inverseBranchBoundaryData[domain_, x_, ass_] := Module[
  {atoms, points = {}, complete = True, sides, expressions, roots, atom, expression},
  atoms = Cases[domain, a_ /; ! FreeQ[a, x] &&
    MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal, Unequal, Inequality, Element}, Head[a]], {0, Infinity}];
  Do[
    If[Head[atom] === Element,
      If[atom =!= Element[x, Reals], complete = False]; Continue[]];
    sides = If[Head[atom] === Inequality, (List @@ atom)[[1 ;; -1 ;; 2]], List @@ atom];
    expressions = (Subtract @@ #) & /@ Partition[sides, 2, 1];
    Do[
      expression = Together[expression];
      If[! PolynomialQ[Numerator[expression], x] || ! PolynomialQ[Denominator[expression], x],
        complete = False; Continue[]];
      roots = inverseBranchFiniteRoots[Numerator[expression] == 0 || Denominator[expression] == 0, x, ass];
      points = Join[points, roots["Points"]]; complete = complete && roots["Complete"],
      {expression, expressions}], {atom, atoms}];
  If[! FreeQ[domain, _C | _Exists | _ForAll] ||
    (! FreeQ[domain, x] && atoms === {}), complete = False];
  <|"Points" -> DeleteDuplicates[points, equal], "Complete" -> TrueQ[complete]|>];

inverseBranchRealQ[value_, ass_] := exactQ[value] &&
  TrueQ[inverseBranchTry[FullSimplify[Element[value, Reals], ass]]];

inverseBranchContinuousQ[body_, x_] := Module[{heads},
  heads = DeleteDuplicates[Head /@ Cases[body, e_ /; ! AtomQ[e] && ! FreeQ[e, x], {0, Infinity}]];
  FreeQ[body, ArcTan[_, _]] &&
  And @@ (MemberQ[{Plus, Times, Power, Log, Exp, Abs, Sin, Cos, Tan, Cot, Sec, Csc,
    Sinh, Cosh, Tanh, Coth, Sech, Csch, ArcSin, ArcCos, ArcTan,
    ArcSinh, ArcCosh, ArcTanh, Erf, Erfc, Gamma, LogGamma, BarnesG, LogBarnesG, ProductLog}, #] & /@ heads)];

(* Polynomial monotonicity certificate (wave-5 report 43 E01). A polynomial
   with exact rational coefficients is strictly monotone on the whole real
   line when its derivative keeps one sign and vanishes only at isolated
   points: the derivative's factors of odd multiplicity (Yun's squarefree
   decomposition, computed with exact rational coefficient lists) must have no
   real root, which a Sturm chain of that odd part certifies exactly, and the
   derivative's leading coefficient gives the direction. Stationary points of
   even multiplicity, such as the two real zeros of (1 - t^2)^2, do not break
   strict monotonicity. Whole-line strictness implies strictness and
   injectivity on every real domain, so no domain proof is needed. Nothing
   here asserts a positive slope lower bound or an inverse error bound. *)
inverseBranchRationalQ[v_] := IntegerQ[v] || Head[v] === Rational;
inverseBranchPolyTrim[c_List] := Module[{list = c},
  While[list =!= {} && Last[list] === 0, list = Most[list]]; list];
inverseBranchPolyDegree[c_List] := Length[c] - 1;
inverseBranchPolyDerivative[c_List] := inverseBranchPolyTrim[Table[k c[[k + 1]], {k, 1, Length[c] - 1}]];
inverseBranchPolyMultiply[a_List, b_List] := inverseBranchPolyTrim[
  Table[Sum[If[1 <= k - j + 1 <= Length[b], a[[j]] b[[k - j + 1]], 0], {j, 1, Length[a]}], {k, 1, Length[a] + Length[b] - 1}]];
inverseBranchPolyRemainder[a_List, b_List] := Module[{r = inverseBranchPolyTrim[a], shift, factor},
  While[r =!= {} && Length[r] >= Length[b],
    shift = Length[r] - Length[b]; factor = Last[r]/Last[b];
    r = inverseBranchPolyTrim[r - factor Join[ConstantArray[0, shift], b]]];
  r];
inverseBranchPolyQuotient[a_List, b_List] := Module[{r = inverseBranchPolyTrim[a], q, shift, factor},
  q = ConstantArray[0, Max[Length[a] - Length[b] + 1, 1]];
  While[r =!= {} && Length[r] >= Length[b],
    shift = Length[r] - Length[b]; factor = Last[r]/Last[b];
    q[[shift + 1]] = factor;
    r = inverseBranchPolyTrim[r - factor Join[ConstantArray[0, shift], b]]];
  inverseBranchPolyTrim[q]];
inverseBranchPolyMonic[c_List] := If[c === {}, c, c/Last[c]];
inverseBranchPolyGCD[a_List, b_List] := Module[{x = inverseBranchPolyTrim[a], y = inverseBranchPolyTrim[b], r},
  While[y =!= {}, r = inverseBranchPolyRemainder[x, y]; x = y; y = r];
  inverseBranchPolyMonic[x]];
(* Yun: the product of the squarefree factors of odd multiplicity. *)
inverseBranchPolyOddPart[c_List] := Module[{d = inverseBranchPolyTrim[c], g, b, cc, factor, i = 1, odd = {1}, guard = 0},
  If[Length[d] <= 1, Return[odd, Module]];
  g = inverseBranchPolyGCD[d, inverseBranchPolyDerivative[d]];
  b = inverseBranchPolyQuotient[d, g];
  cc = inverseBranchPolyTrim[inverseBranchPolyQuotient[inverseBranchPolyDerivative[d], g] - inverseBranchPolyDerivative[b]];
  While[Length[b] > 1 && guard++ < 128,
    factor = inverseBranchPolyGCD[b, cc];
    If[Length[factor] > 1 && OddQ[i], odd = inverseBranchPolyMultiply[odd, factor]];
    b = inverseBranchPolyQuotient[b, factor];
    cc = inverseBranchPolyTrim[inverseBranchPolyQuotient[cc, factor] - inverseBranchPolyDerivative[b]];
    i++];
  odd];
inverseBranchSturmChain[c_List] := Module[{chain, r, guard = 0},
  chain = {c, inverseBranchPolyDerivative[c]};
  If[Last[chain] === {}, Return[{c}, Module]];
  While[guard++ < 128,
    r = inverseBranchPolyRemainder[chain[[-2]], chain[[-1]]];
    If[r === {}, Break[]];
    AppendTo[chain, -r]];
  chain];
inverseBranchSignAtInfinity[c_List, direction_] := If[c === {}, 0,
  Sign[Last[c]] If[direction === 1 || EvenQ[Length[c] - 1], 1, -1]];
inverseBranchSignVariations[signs_List] := Module[{nonzero = DeleteCases[signs, 0]},
  Count[Partition[nonzero, 2, 1], {a_, b_} /; a =!= b]];
inverseBranchRealRootCount[c_List] := Module[{chain = inverseBranchSturmChain[c]},
  inverseBranchSignVariations[inverseBranchSignAtInfinity[#, -1] & /@ chain] -
    inverseBranchSignVariations[inverseBranchSignAtInfinity[#, 1] & /@ chain]];
(* The certificate for a polynomial body: None when the body is not a
   rational polynomial of degree at most 64, is constant, or is not strictly
   monotone on the real line. *)
inverseBranchPolynomialMonotonicity[body_, x_] := Module[{coefficients, derivative, odd, sign},
  If[! PolynomialQ[body, x], Return[None, Module]];
  coefficients = inverseBranchPolyTrim[CoefficientList[body, x]];
  If[Length[coefficients] <= 1 || Length[coefficients] > 65 ||
      ! And @@ (inverseBranchRationalQ /@ coefficients), Return[None, Module]];
  derivative = inverseBranchPolyDerivative[coefficients];
  odd = inverseBranchPolyOddPart[derivative];
  If[OddQ[Length[odd] - 1] || inverseBranchRealRootCount[odd] =!= 0, Return[None, Module]];
  sign = Sign[Last[derivative]];
  <|"Type" -> "PolynomialSturmCertificate", "Sign" -> sign,
    "Derivative" -> D[body, x], "StationaryRealRoots" -> inverseBranchRealRootCount[derivative],
    "OddMultiplicityPart" -> odd,
    "Proof" -> "The derivative's factors of odd multiplicity have no real root (Sturm count 0), so the derivative keeps the sign of its leading coefficient and vanishes only at isolated points; the body is strictly monotone on the whole real line."|>];

inverseBranchGlobalMonotonicity[body_, x_, domain_, ass_] := Module[
  {left = Unique["left$"], right = Unique["right$"], middle = Unique["middle$"],
   convex, derivative, positive, negative, ratio, certificate},
  If[! inverseBranchContinuousQ[body, x], Return[None, Module]];
  convex = inverseBranchTry[Reduce[ass && (domain /. x -> left) && (domain /. x -> right) &&
    left < middle < right && ! (domain /. x -> middle), {left, middle, right}, Reals]];
  If[convex =!= False, Return[None, Module]];
  derivative = D[body, x];
  positive = inverseBranchTry[FullSimplify[derivative > 0, ass && domain && Element[x, Reals]]];
  If[! TrueQ[positive], positive = inverseBranchTry[Reduce[ass && domain && derivative <= 0, x, Reals]] === False];
  If[TrueQ[positive], Return[<|"Type" -> "StrictDerivativeOnRealInterval", "Sign" -> 1,
    "Domain" -> domain, "Derivative" -> derivative|>, Module]];
  negative = inverseBranchTry[FullSimplify[derivative < 0, ass && domain && Element[x, Reals]]];
  If[! TrueQ[negative], negative = inverseBranchTry[Reduce[ass && domain && derivative >= 0, x, Reals]] === False];
  If[TrueQ[negative], Return[<|"Type" -> "StrictDerivativeOnRealInterval", "Sign" -> -1,
    "Domain" -> domain, "Derivative" -> derivative|>, Module]];
  (* A rational polynomial body with an even-multiplicity stationary point
     (report 43 E01) is certified exactly when the sign proofs above fail. *)
  certificate = inverseBranchPolynomialMonotonicity[body, x];
  If[AssociationQ[certificate], Return[Join[certificate, <|"Domain" -> domain|>], Module]];
  (* Article Proposition 4.2: x(3+2 Log[x]) has minimum -2 Exp[-5/2]
     on x>0. A nonzero real scalar preserves strict monotonicity. *)
  If[TrueQ[inverseBranchTry[FullSimplify[x > 0, ass && domain && Element[x, Reals]]]],
    ratio = inverseBranchTry[FullSimplify[derivative/(1 + x (3 + 2 Log[x])), ass && x > 0]];
    If[ratio =!= $Failed && FreeQ[ratio, x] &&
       (provablyPositive[ratio, ass] || provablyNegative[ratio, ass]),
      Return[<|"Type" -> "OriginalLogarithmicExampleSlopeLemma",
        "Sign" -> If[provablyPositive[ratio, ass], 1, -1], "Domain" -> domain,
        "DerivativeLowerAbsoluteBound" -> Abs[ratio] (1 - 2 Exp[-5/2]),
        "Proof" -> "The derivative of x(3+2 Log[x]) is 5+2 Log[x], so its global minimum on x>0 is -2 Exp[-5/2]."|>, Module]]];
  None];

inverseBranchRadius[point_, boundaries_] := Module[{distances},
  If[MemberQ[{Infinity, -Infinity}, point],
    Return[1/(2 + 2 If[boundaries === {}, 0, Max[Abs /@ boundaries]]), Module]];
  distances = Select[Abs[point - #] & /@ boundaries, less[0, #] &];
  If[distances === {}, 1/2, Min[1/2, Min[distances]/2]]];

(* True/False prove truth/falsity throughout this deleted interval; None is
   inconclusive. In particular, a failed proof is never a rejected branch. *)
inverseBranchEventualQ[predicate_, u_, ass_, radius_] := Module[{simple, bad, good},
  simple = inverseBranchTry[FullSimplify[predicate, ass && 0 < u < radius]];
  If[TrueQ[simple], Return[True, Module]];
  If[simple === False, Return[False, Module]];
  bad = inverseBranchTry[Reduce[ass && 0 < u < radius && ! predicate, u, Reals]];
  If[bad === False, Return[True, Module]];
  good = inverseBranchTry[Reduce[ass && 0 < u < radius && predicate, u, Reals]];
  If[good === False, False, None]];

inverseBranchSign[expression_, u_, ass_, radius_, limit_] := Module[{ell = Unique["branchLog$"], jet, row, degree, leading},
  (* A polynomial sign question is decided exactly by the eventual-sign
     prover before any jet is formed: on Mathics the jet of a quintic exceeds
     the validator's time budget (about 11 s against 8), which left the
     quintic of report 43 E01 unresolved although its certificate held. *)
  If[PolynomialQ[expression, u] && FreeQ[ass, u],
    If[TrueQ[inverseFunctionEventually[expression > 0, u, ass]],
      Return[<|"Sign" -> 1, "Type" -> "ExactEventualSign"|>, Module]];
    If[TrueQ[inverseFunctionEventually[expression < 0, u, ass]],
      Return[<|"Sign" -> -1, "Type" -> "ExactEventualSign"|>, Module]]];
  jet = inverseBranchTry[catch[forwardJet[expression, u, ell, ass, 1, limit]]];
  If[ListQ[jet] && Length[jet] === 3 && jet[[1]] =!= {},
    row = First[jet[[1]]]; degree = polyDegree[row[[2]], ell];
    leading = (-1)^degree Coefficient[row[[2]], ell, degree];
    If[provablyPositive[leading, ass], Return[<|"Sign" -> 1, "Type" -> "LeadingPowerLogBlock", "Block" -> row|>, Module]];
    If[provablyNegative[leading, ass], Return[<|"Sign" -> -1, "Type" -> "LeadingPowerLogBlock", "Block" -> row|>, Module]]];
  If[TrueQ[inverseBranchEventualQ[expression > 0, u, ass, radius]],
    Return[<|"Sign" -> 1, "Type" -> "ExactSignOnDeletedNeighborhood", "Radius" -> radius|>, Module]];
  If[TrueQ[inverseBranchEventualQ[expression < 0, u, ass, radius]],
    Return[<|"Sign" -> -1, "Type" -> "ExactSignOnDeletedNeighborhood", "Radius" -> radius|>, Module]];
  None];

inverseBranchValidate[body_, x_, domain_, point_, direction_, target_, targetSide_, ass_, boundaries_, limit_] := Module[
  {coord, u, radius, localDomain, domainTruth, localBody, value, matches, sign, derivative, derivativeSign},
  coord = catch[localCoordinate[x, point, direction]];
  If[FailureQ[coord], Return[None, Module]];
  u = coord["u"]; radius = inverseBranchRadius[point, boundaries];
  localDomain = domain /. x -> coord["Substitution"];
  domainTruth = inverseBranchEventualQ[localDomain, u, ass, radius];
  If[domainTruth === False, Return[False, Module]];
  If[! TrueQ[domainTruth], Return[None, Module]];
  localBody = inverseBranchTry[FullSimplify[body /. x -> coord["Substitution"], ass && u > 0]];
  If[localBody === $Failed, Return[None, Module]];
  value = inverseBranchTry[Limit[localBody, u -> 0, Direction -> -1, Assumptions -> ass]];
  If[! inverseBranchResolvedQ[value] ||
     (! MemberQ[{Infinity, -Infinity}, value] && ! inverseBranchRealQ[value, ass]), Return[None, Module]];
  matches = inverseBranchTry[FullSimplify[value == target, ass]];
  If[matches === False, Return[False, Module]];
  If[! TrueQ[matches], Return[None, Module]];
  If[! MemberQ[{Infinity, -Infinity}, target],
    sign = inverseBranchSign[localBody - target, u, ass, radius, limit];
    If[! AssociationQ[sign], Return[None, Module]];
    If[sign["Sign"] =!= targetSide, Return[False, Module]],
    sign = <|"Type" -> "ProvedInfiniteLimit", "Sign" -> If[target === Infinity, 1, -1]|>];
  derivative = D[body, x] /. x -> coord["Substitution"];
  derivativeSign = inverseBranchSign[derivative, u, ass, radius, limit];
  If[! AssociationQ[derivativeSign],
    Return[If[TrueQ[inverseBranchEventualQ[derivative == 0, u, ass, radius]], False, None], Module]];
  <|"SourcePoint" -> point, "Direction" -> coord["Direction"], "SourceDomain" -> domain,
    "SourceCondition" -> domain, "TargetLimit" -> target, "TargetSide" -> targetSide,
    "LocalSourceVariable" -> u, "LocalSubstitution" -> (x -> coord["Substitution"]),
    "DeletedNeighborhood" -> (0 < u < radius), "ConditionalDomainVerified" -> True,
    "LimitVerified" -> True, "TargetSideProof" -> sign, "MonotonicityProof" -> derivativeSign,
    "BranchProofScope" -> "Unique inverse germ on the selected sufficiently small deleted real source neighborhood. The recorded condition radius is not a computed power-log asymptotic threshold."|>];

inverseFunctionSelectBranchInternal[data_, target_, targetSide_, ass_, limit_, selection_] := Module[
  {body, x, condition, realDomain, domain, domainReduced, boundary, roots,
   candidates, points, monotonicity, complete, choices = {}, unresolved = {}, choice,
   directions, point, mode, sourceDirection},
  If[! AssociationQ[data] || ! And @@ (KeyExistsQ[data, #] & /@ {"Body", "SourceVariable", "Condition"}),
    fail["InvalidInverseFunctionData", "The inverse node needs a Body, SourceVariable and Condition."]];
  {body, x, condition} = Lookup[data, {"Body", "SourceVariable", "Condition"}];
  If[Head[x] =!= Symbol || ! FreeQ[ass, x],
    fail["InvalidInverseFunctionData", "Use a source symbol and parameter-only assumptions."]];
  validateInput[body, limit];
  If[! MemberQ[{Infinity, -Infinity}, target] && (! inverseBranchRealQ[target, ass] || ! MemberQ[{-1, 1}, targetSide]),
    fail["UnprovedInverseTargetLimit", "The inverse argument needs an exact real endpoint and a proved one-sided approach, or a signed infinity."]];
  choice = barnesInverseBranch[data, target, targetSide, ass, limit, selection];
  If[AssociationQ[choice], Return[choice, Module]];
  If[! inverseBranchContinuousQ[body, x],
    fail["UnsupportedInverseFunctionBody", "Branch inference requires an explicit supported continuous elementary or special-function body."]];
  realDomain = inverseBranchTry[FunctionDomain[body, x, Reals]];
  If[! inverseBranchResolvedQ[realDomain],
    fail["UnprovedInverseRealDomain", "The real domain of the principal forward expression could not be established; no branch was guessed."]];
  domain = inverseBranchTry[FullSimplify[condition && realDomain, ass && Element[x, Reals]]];
  If[domain === $Failed, domain = condition && realDomain];
  domainReduced = inverseBranchTry[Reduce[ass && domain, x, Reals]];
  If[inverseBranchResolvedQ[domainReduced], domain = domainReduced];
  If[domain === False, fail["EmptyInverseFunctionDomain", "The conditional real source domain is empty under the assumptions."]];
  boundary = inverseBranchBoundaryData[domain, x, ass];
  If[selection =!= Automatic,
    If[! AssociationQ[selection] || ! KeyExistsQ[selection, "SourcePoint"] ||
       Complement[Keys[selection], {"SourcePoint", "Direction"}] =!= {},
      fail["InvalidInverseBranchSelection", "Use an association with SourcePoint and optional Direction."]];
    point = selection["SourcePoint"]; sourceDirection = Lookup[selection, "Direction", Automatic];
    If[! MemberQ[{Automatic, "FromAbove", "FromBelow", -1, 1}, sourceDirection],
      fail["InvalidInverseBranchSelection", "Direction must be Automatic, FromAbove, FromBelow, -1 or 1."]];
    sourceDirection = sourceDirection /. {-1 -> "FromAbove", 1 -> "FromBelow"};
    If[! MemberQ[{Infinity, -Infinity}, point] && ! exactRealQ[point],
      fail["InvalidInverseBranchSelection", "The selected source endpoint must be an exact real constant or a signed infinity."]];
    directions = If[sourceDirection === Automatic && ! MemberQ[{Infinity, -Infinity}, point],
      {"FromAbove", "FromBelow"}, {sourceDirection}];
    Do[choice = inverseBranchValidate[body, x, domain, point, direction, target, targetSide, ass, boundary["Points"], limit];
      If[AssociationQ[choice], AppendTo[choices, choice],
        If[choice =!= False, AppendTo[unresolved, {point, direction}]]], {direction, directions}];
    mode = "ExplicitEndpointAndValidatedLocalBranch"; complete = unresolved === {},
    roots = If[MemberQ[{Infinity, -Infinity}, target], <|"Points" -> {}, "Complete" -> True|>,
      inverseBranchFiniteRoots[domain && body == target, x, ass]];
    points = DeleteDuplicates[Join[{0}, roots["Points"], boundary["Points"]], equal];
    candidates = Join[Flatten[({{#, "FromAbove"}, {#, "FromBelow"}} &) /@ points, 1],
      {{Infinity, "FromBelow"}, {-Infinity, "FromAbove"}}];
    If[Length[candidates] > Min[limit, 64],
      fail["ResourceLimit", "The inverse branch candidate set exceeds its bounded search budget.",
        <|"CandidateCount" -> Length[candidates], "MaxCandidates" -> Min[limit, 64]|>]];
    Do[choice = inverseBranchValidate[body, x, domain, candidate[[1]], candidate[[2]], target, targetSide,
        ass, boundary["Points"], limit];
      If[AssociationQ[choice], AppendTo[choices, choice],
        If[choice =!= False, AppendTo[unresolved, candidate]]], {candidate, candidates}];
    complete = TrueQ[boundary["Complete"] && roots["Complete"]] && unresolved === {};
    mode = "CompleteRealFiberAndBoundaryEnumeration";
    If[Length[choices] == 1 && ! complete,
      monotonicity = inverseBranchGlobalMonotonicity[body, x, domain, ass];
      If[AssociationQ[monotonicity], complete = True; mode = "StrictMonotonicityOnConnectedRealDomain"]]];
  If[Length[choices] > 1,
    fail["AmbiguousInverseFunctionBranch", "Several real source germs have the requested target limit and side; restrict the function domain or select SourcePoint and Direction.",
      <|"Candidates" -> choices, "SourceDomain" -> domain, "TargetLimit" -> target|>]];
  If[! TrueQ[complete],
    fail["IncompleteInverseBranchInference", "A bounded candidate search did not prove completeness or unique monotonic selection; supply an explicit source branch.",
      <|"Candidates" -> choices, "UnresolvedCandidates" -> unresolved,
        "SourceDomain" -> domain, "BoundaryInference" -> boundary|>]];
  If[choices === {},
    fail["NoInverseFunctionBranch", "No selected real source neighborhood satisfies the target limit, approach side and conditional domain.",
      <|"SourceDomain" -> domain, "TargetLimit" -> target, "TargetSide" -> targetSide|>]];
  Join[First[choices], <|"SelectionMethod" -> mode, "ParameterAssumptions" -> ass,
    "InferenceComplete" -> True, "GlobalMonotonicityProof" -> If[AssociationQ[monotonicity], monotonicity, Missing["NotRequired"]],
    "OriginalCondition" -> condition, "RealFunctionDomain" -> realDomain,
    "OriginalInverseExpression" -> Lookup[data, "OriginalExpression", Missing["NotRecorded"]]|>]];

inverseFunctionSelectBranch[data_, target_, targetSide_, ass_, limit_, selection_: Automatic] :=
  catch[inverseFunctionSelectBranchInternal[data, target, targetSide, ass, limit, selection]];
