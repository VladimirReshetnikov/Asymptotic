(* Loaded late in Private, only on Mathics. Two bounded exact facts fill the
   polynomial branch-inference path without emulating Reduce: a polynomial
   with real constant coefficients is real on the whole real axis, and an
   intersection of affine real half-lines is convex. The ordinary branch
   validator still proves the source condition, limit, target side and local
   derivative sign. Unsupported domains retain the conservative failure. *)

mathicsPolynomialFunctionDomain[body_, x_Symbol, Reals] :=
  If[PolynomialQ[body, x] && And @@ (exactRealQ /@ CoefficientList[body, x]),
    True, System`FunctionDomain[body, x, Reals]];

(* Replace only this private consumer's unavailable FunctionDomain call.
   No definition or attribute of a System symbol is changed. *)
DownValues[inverseFunctionSelectBranchInternal] =
  DownValues[inverseFunctionSelectBranchInternal] /.
    System`FunctionDomain -> mathicsPolynomialFunctionDomain;

mathicsAffineRealExpressionQ[expression_, x_, ass_] :=
  PolynomialQ[expression, x] && Exponent[expression, x] <= 1 &&
    And @@ (TrueQ[FullSimplify[Element[#, Reals], ass]] & /@ CoefficientList[expression, x]);

mathicsConvexRealDomainQ[domain_, x_, ass_] := Module[{head = Head[domain], parts},
  If[FreeQ[domain, x], Return[True, Module]];
  If[head === And,
    Return[And @@ (mathicsConvexRealDomainQ[#, x, ass] & /@ List @@ domain), Module]];
  If[MemberQ[{Element, System`Element}, head],
    Return[SameQ[domain[[1]], x] && SameQ[domain[[2]], Reals], Module]];
  If[MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal}, head],
    parts = List @@ domain;
    If[head =!= Equal &&
      ! And @@ (mathicsAffineRealExpressionQ[#, x, ass] & /@ parts), Return[False, Module]];
    Return[And @@ (mathicsAffineRealExpressionQ[Subtract @@ #, x, ass] & /@
      Partition[parts, 2, 1]), Module]];
  If[head === Inequality,
    parts = List @@ domain;
    If[! And @@ (MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal}, #] & /@
        parts[[2 ;; -1 ;; 2]]), Return[False, Module]];
    If[! And @@ (mathicsAffineRealExpressionQ[#, x, ass] & /@ parts[[1 ;; -1 ;; 2]]),
      Return[False, Module]];
    Return[And @@ (mathicsAffineRealExpressionQ[Subtract @@ #, x, ass] & /@
      Partition[parts[[1 ;; -1 ;; 2]], 2, 1]), Module]];
  False];

(* Retain the existing general proof path as a fallback. Clear the dispatch
   symbol before installing its wrapper: Mathics otherwise evaluates an old
   definition while reading the left-hand side of a new definition. *)
If[DownValues[mathicsOriginalGlobalMonotonicity] === {},
  DownValues[mathicsOriginalGlobalMonotonicity] =
    DownValues[inverseBranchGlobalMonotonicity] /.
      inverseBranchGlobalMonotonicity -> mathicsOriginalGlobalMonotonicity];
Clear[inverseBranchGlobalMonotonicity];
inverseBranchGlobalMonotonicity[body_, x_, domain_, ass_] := Module[
  {derivative = D[body, x], positive, negative},
  If[! PolynomialQ[body, x] || ! mathicsConvexRealDomainQ[domain, x, ass],
    Return[mathicsOriginalGlobalMonotonicity[body, x, domain, ass], Module]];
  positive = inverseBranchTry[FullSimplify[derivative > 0,
    ass && domain && Element[x, Reals]]];
  If[TrueQ[positive],
    Return[<|"Type" -> "StrictDerivativeOnRealInterval", "Sign" -> 1,
      "Domain" -> domain, "Derivative" -> derivative|>, Module]];
  negative = inverseBranchTry[FullSimplify[derivative < 0,
    ass && domain && Element[x, Reals]]];
  If[TrueQ[negative],
    Return[<|"Type" -> "StrictDerivativeOnRealInterval", "Sign" -> -1,
      "Domain" -> domain, "Derivative" -> derivative|>, Module]];
  None];

(* For an affine expression on 0<u<r, every value is a strict convex
   combination of the endpoint values. This proves the whole deleted
   interval, including strict inequalities with one zero endpoint. *)
mathicsAffineIntervalRelation[left_, head_, right_, u_, ass_, radius_] := Module[
  {difference = Expand[left - right], endpoints, nonnegative, nonpositive,
   positive, negative, zero},
  If[! mathicsAffineRealExpressionQ[difference, u, ass], Return[None, Module]];
  If[MemberQ[{Less, LessEqual, Greater, GreaterEqual}, head] &&
    ! (TrueQ[FullSimplify[Element[left, Reals], ass && Element[u, Reals]]] &&
       TrueQ[FullSimplify[Element[right, Reals], ass && Element[u, Reals]]]),
    Return[None, Module]];
  endpoints = {difference /. u -> 0, difference /. u -> radius};
  nonnegative = And @@ (TrueQ[FullSimplify[# >= 0, ass]] & /@ endpoints);
  nonpositive = And @@ (TrueQ[FullSimplify[# <= 0, ass]] & /@ endpoints);
  positive = nonnegative && Or @@ (provablyPositive[#, ass] & /@ endpoints);
  negative = nonpositive && Or @@ (provablyNegative[#, ass] & /@ endpoints);
  zero = And @@ (TrueQ[FullSimplify[# == 0, ass]] & /@ endpoints);
  Switch[head,
    Greater, Which[positive, True, nonpositive, False, True, None],
    GreaterEqual, Which[nonnegative, True, negative, False, True, None],
    Less, Which[negative, True, nonnegative, False, True, None],
    LessEqual, Which[nonpositive, True, positive, False, True, None],
    Equal, Which[zero, True, positive || negative, False, True, None],
    Unequal, Which[positive || negative, True, zero, False, True, None],
    _, None]];

mathicsAffineIntervalTruth[predicate_, u_, ass_, radius_] := Module[
  {head = Head[predicate], parts, truths},
  If[predicate === True || predicate === False, Return[predicate, Module]];
  (* Unequal with more than two operands asserts every pair is unequal;
     the consecutive-pair reduction used for ordered chains is insufficient. *)
  If[head === Unequal && Length[predicate] =!= 2, Return[None, Module]];
  If[head === And,
    truths = mathicsAffineIntervalTruth[#, u, ass, radius] & /@ List @@ predicate,
    If[MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal, Unequal}, head],
      truths = mathicsAffineIntervalRelation[#[[1]], head, #[[2]], u, ass, radius] & /@
        Partition[List @@ predicate, 2, 1],
      If[head === Inequality,
        parts = List @@ predicate;
        truths = Table[mathicsAffineIntervalRelation[parts[[j]], parts[[j + 1]],
          parts[[j + 2]], u, ass, radius], {j, 1, Length[parts] - 2, 2}],
        Return[None, Module]]]];
  Which[MemberQ[truths, False], False, And @@ (TrueQ /@ truths), True, True, None]];

If[DownValues[mathicsOriginalBranchEventualQ] === {},
  DownValues[mathicsOriginalBranchEventualQ] = DownValues[inverseBranchEventualQ] /.
    inverseBranchEventualQ -> mathicsOriginalBranchEventualQ];
Clear[inverseBranchEventualQ];
inverseBranchEventualQ[predicate_, u_, ass_, radius_] := Module[{truth},
  If[exactRealQ[radius] && less[0, radius],
    truth = mathicsAffineIntervalTruth[predicate, u, ass, radius];
    If[truth === True || truth === False, Return[truth, Module]]];
  mathicsOriginalBranchEventualQ[predicate, u, ass, radius]];

(* Exact eventual sign of a real polynomial in u as u -> 0+: the lowest-
   order coefficient with a proved sign decides, so a condition such as
   0 < u < 10^-30 is proved on its own arbitrarily small neighborhood
   without trial radii. A coefficient whose sign or realness is unproved
   gives None; unproved is not false (wave-4 W4-03). *)
mathicsPolynomialEventualSign[difference_, u_, ass_] := Module[{coefficients, k},
  If[! PolynomialQ[difference, u], Return[None, Module]];
  coefficients = CoefficientList[difference, u];
  If[! And @@ (TrueQ[FullSimplify[Element[#, Reals], ass]] & /@ coefficients), Return[None, Module]];
  Do[Which[TrueQ[FullSimplify[coefficients[[k]] == 0, ass]], Null,
     provablyPositive[coefficients[[k]], ass], Return[1, Module],
     provablyNegative[coefficients[[k]], ass], Return[-1, Module],
     True, Return[None, Module]], {k, Length[coefficients]}];
  0];
mathicsPolynomialEventualRelation[left_, head_, right_, u_, ass_] := Module[{sign},
  If[MemberQ[{Less, LessEqual, Greater, GreaterEqual}, head] &&
    ! (TrueQ[FullSimplify[Element[left, Reals], ass && Element[u, Reals]]] &&
       TrueQ[FullSimplify[Element[right, Reals], ass && Element[u, Reals]]]),
    Return[None, Module]];
  sign = mathicsPolynomialEventualSign[Expand[left - right], u, ass];
  If[sign === None, Return[None, Module]];
  Switch[head,
    Greater, sign === 1, GreaterEqual, sign >= 0, Less, sign === -1, LessEqual, sign <= 0,
    Equal, sign === 0, Unequal, sign =!= 0, _, None]];
mathicsPolynomialEventualTruth[predicate_, u_, ass_] := Module[{head = Head[predicate], parts, truths},
  If[predicate === True || predicate === False, Return[predicate, Module]];
  If[head === Unequal && Length[predicate] =!= 2, Return[None, Module]];
  If[head === And,
    truths = mathicsPolynomialEventualTruth[#, u, ass] & /@ List @@ predicate,
    If[MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal, Unequal}, head],
      truths = mathicsPolynomialEventualRelation[#[[1]], head, #[[2]], u, ass] & /@
        Partition[List @@ predicate, 2, 1],
      If[head === Inequality,
        parts = List @@ predicate;
        truths = Table[mathicsPolynomialEventualRelation[parts[[j]], parts[[j + 1]],
          parts[[j + 2]], u, ass], {j, 1, Length[parts] - 2, 2}],
        Return[None, Module]]]];
  Which[MemberQ[truths, False], False, And @@ (TrueQ /@ truths), True, True, None]];

(* The exact eventual-sign certificate comes first; the seven dyadic trial
   radii remain for nonpolynomial conditions, since failure at any trial
   radius says nothing about smaller neighborhoods. *)
If[DownValues[mathicsOriginalFunctionEventually] === {},
  DownValues[mathicsOriginalFunctionEventually] = DownValues[inverseFunctionEventually] /.
    inverseFunctionEventually -> mathicsOriginalFunctionEventually];
Clear[inverseFunctionEventually];
inverseFunctionEventually[condition_, u_, ass_] := Module[{simple, exact},
  simple = FullSimplify[condition, ass && u > 0];
  If[simple === True || simple === False, Return[simple, Module]];
  exact = mathicsPolynomialEventualTruth[simple, u, ass];
  If[exact === True || exact === False, Return[exact, Module]];
  Do[If[TrueQ[mathicsAffineIntervalTruth[simple, u, ass, 2^-j]],
    Return[True, Module]], {j, 0, 6}];
  mathicsOriginalFunctionEventually[condition, u, ass]];
