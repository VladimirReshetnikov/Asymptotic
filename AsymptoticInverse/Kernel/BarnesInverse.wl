(* Reversion about H(X)=X^2 (Log[X]-3/2)/2, with the Barnes argument
   equal to 1+X(1+U). q=1/(Log[X]-1) normalizes H'(X)=X/q.
   Each finite coefficient is polynomial in q. The Bernoulli model is
   used only to its stated Poincare order, never as an exact equation. *)

barnesInverseUnit[n_Integer, t_, q_, limit_] := Module[
  {unit = 0, phase, coefficient, j, k},
  Do[
    phase = unit + unit^2/2 + q ((1 + unit)^2 Log[1 + unit] - unit - unit^2/2)/2 +
      Log[2 Pi] q t (1 + unit)/2 - t^2 (1/12 + Log[Glaisher] q) -
      q t^2 Log[1 + unit]/12 +
      q Sum[BernoulliB[2 k + 2] t^(2 k + 2) (1 + unit)^(-2 k)/(2 k (2 k + 2)),
        {k, 1, Max[0, Floor[(j - 2)/2]]}];
    coefficient = Expand[-Coefficient[Normal[Series[phase, {t, 0, j}]], t, j]];
    unit += coefficient t^j;
    If[LeafCount[unit] > limit,
      fail["ResourceLimit", "The inverse-Barnes coefficient expansion exceeds MaxTerms."]],
    {j, 1, n}];
  unit];

(* On v>3, put z=v-1>2. The digamma midpoint bound
     psi(z+1)>Log[z+1/2]
   gives (Log G)'(v)>z(Log[z+1/2]-1)+(Log[2 Pi]-1)/2>1/9.
   The last expression increases for z>=2. Elementary logarithm bounds
   Log[5/2]>8/9 and Log[2 Pi]>5/3 prove its lower bound at z=2.
   See the article's Barnes inverse section and DLMF 5.17.4.
   Automatic selection requires a condition contained in this branch;
   explicit endpoint selection validates the retained source tail. *)
barnesInverseBranch[data_, target_, targetSide_, ass_, limit_, selection_] := Module[
  {body, x, condition, model, implication, sourceSign, point, coord, expected,
   side, derivativeSign, selectionDirection, radius, boundary, domain, proof},
  {body, x, condition} = Lookup[data, {"Body", "SourceVariable", "Condition"}];
  If[FreeQ[body, _BarnesG], Return[$Failed, Module]];
  model = gammaInverseModel[body, x, ass];
  If[model === $Failed || ! TrueQ[model["IsBarnes"]], Return[$Failed, Module]];
  implication = inverseBranchTry[FullSimplify[Implies[condition, model["Argument"] > 3],
    ass && Element[x, Reals]]];
  If[! TrueQ[implication],
    implication = inverseBranchTry[Reduce[ass && condition && model["Argument"] <= 3, x, Reals]] === False];
  If[selection === Automatic && ! TrueQ[implication], Return[$Failed, Module]];
  sourceSign = If[provablyPositive[model["SourceScale"], ass], 1, -1];
  point = sourceSign Infinity; coord = localCoordinate[x, point, Automatic];
  If[! inverseFunctionEventually[(condition && model["Argument"] > 3) /. x -> coord["Substitution"], coord["u"], ass],
    Return[$Failed, Module]];
  side = If[provablyPositive[model["TargetScale"], ass], 1, -1];
  expected = If[! model["Logarithmic"] && provablyNegative[model["GammaPower"], ass],
    model["TargetOffset"], side Infinity];
  If[! TrueQ[inverseBranchTry[FullSimplify[target == expected, ass]]] ||
      (! MemberQ[{Infinity, -Infinity}, expected] && targetSide =!= side), Return[$Failed, Module]];
  If[selection =!= Automatic,
    If[! AssociationQ[selection] || ! KeyExistsQ[selection, "SourcePoint"] ||
        Complement[Keys[selection], {"SourcePoint", "Direction"}] =!= {},
      fail["InvalidInverseBranchSelection", "Use an association with SourcePoint and optional Direction."]];
    selectionDirection = Lookup[selection, "Direction", Automatic] /. {-1 -> "FromAbove", 1 -> "FromBelow"};
    If[! MemberQ[{Automatic, "FromAbove", "FromBelow"}, selectionDirection],
      fail["InvalidInverseBranchSelection", "Direction must be Automatic, FromAbove, FromBelow, -1 or 1."]];
    If[selection["SourcePoint"] =!= point || ! MemberQ[{Automatic, coord["Direction"]}, selectionDirection],
      fail["NoInverseFunctionBranch", "The selected endpoint or direction does not describe the increasing positive-argument Barnes branch."]]];
  domain = condition && model["Argument"] > 3;
  boundary = inverseBranchBoundaryData[domain, x, ass];
  radius = inverseBranchRadius[point, boundary["Points"]];
  (* The condition proof is eventual; record a fixed radius only when it
     has also been verified throughout that particular neighborhood. *)
  derivativeSign = sourceSign side If[provablyPositive[model["GammaPower"], ass], 1, -1];
  proof = <|"Type" -> "PositiveBarnesLogarithmicDerivative", "Sign" -> derivativeSign,
    "Domain" -> domain, "LogBarnesDerivativeLowerBound" -> 1/9,
    "Reference" -> "https://dlmf.nist.gov/5.17.E4",
    "Proof" -> "For Barnes argument v>3, the exact logarithmic derivative and the digamma midpoint inequality give d Log[G(v)]/dv>1/9. Positive G, fixed real powers, and proved affine scale signs preserve strict monotonicity on the retained domain."|>;
  <|"SourcePoint" -> point, "Direction" -> coord["Direction"], "SourceDomain" -> domain,
    "SourceCondition" -> condition, "TargetLimit" -> expected, "TargetSide" -> targetSide,
    "LocalSourceVariable" -> coord["u"], "LocalSubstitution" -> (x -> coord["Substitution"]),
    "DeletedNeighborhood" -> If[TrueQ[inverseBranchEventualQ[domain /. x -> coord["Substitution"],
        coord["u"], ass, radius]], 0 < coord["u"] < radius, Missing["UncomputedEventualRadius"]],
    "ConditionalDomainVerified" -> True, "LimitVerified" -> True,
    "TargetSideProof" -> <|"Type" -> "PositiveBarnesGrowthAndExactTargetTransformation", "Sign" -> side|>,
    "MonotonicityProof" -> proof, "GlobalMonotonicityProof" -> proof,
    "SelectionMethod" -> If[selection === Automatic, "ProvedPositiveBarnesBranch", "ExplicitEndpointAndValidatedLocalBranch"],
    "InferenceComplete" -> True, "ParameterAssumptions" -> ass,
    "OriginalCondition" -> condition, "RealFunctionDomain" -> model["Argument"] > 3,
    "RealFunctionDomainScope" -> If[selection === Automatic,
      "A proved sufficient real domain containing the entire retained source condition, not the maximal real domain of Barnes G.",
      "A proved sufficient real domain containing the explicitly selected source tail; the original condition is retained separately."],
    "OriginalInverseExpression" -> Lookup[data, "OriginalExpression", Missing["NotRecorded"]],
    "BranchProofScope" -> "Strict monotonicity on the positive Barnes branch and the verified source tail establish its unique inverse germ. No asymptotic validity threshold is claimed."|>];
