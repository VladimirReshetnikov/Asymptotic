(* Two convergent defining sums supply expansions unavailable from native
   Series. All parameters are fixed on the target approach. Zeta uses the
   exponential coordinate exp(-S); Lerch uses the reciprocal argument 1/a.
   https://dlmf.nist.gov/25.2.E1
   https://dlmf.nist.gov/25.14.E1 *)

dirichletSpecialBudget[e_, limit_] :=
  If[LeafCount[e] > limit, fail["ResourceLimit", "The Dirichlet special-function expansion exceeds MaxTerms expression leaves."]];

dirichletSpecialOptions[cut_, goal_, limit_] := (
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[goal =!= Automatic && (! IntegerQ[goal] || goal < 1),
    fail["InvalidTermGoal", "SeriesTermGoal must be a positive integer or Automatic."]];
  If[cut === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give a real exponent cutoff or a positive integer SeriesTermGoal."]],
    If[! exactRealQ[cut], fail["InvalidCutoff", "The cutoff must be an exact real number."]]]);

dirichletSpecialLargeArgumentQ[argument_, x_, coord_, ass_] := Module[{local, parameters},
  parameters = DeleteDuplicates[Cases[{argument},
    p_Symbol /; p =!= x && Context[p] =!= "System`", Infinity]];
  If[! AllTrue[parameters, TrueQ[inverseBranchTry[FullSimplify[Element[#, Reals], ass]]] &],
    Return[False, Module]];
  local = argument /. x -> coord["Substitution"];
  TrueQ[inverseBranchTry[inverseFunctionEventually[local > 0, coord["u"], ass]]] &&
    inverseBranchTry[Limit[local, coord["u"] -> 0, Direction -> "FromAbove", Assumptions -> ass]] === Infinity];

(* An affine combination alpha atom + beta of one defining-sum atom, with
   fixed exact coefficients free of the variable, is expanded with the atom:
   every retained row is scaled by alpha and the constant joins the zero
   exponent (wave-6 report 55 N01). Anything else, including a variable
   coefficient or two atoms, is left to the later dispatchers. *)
dirichletSpecialAffineForm[f_, x_, ass_] := Module[{atoms, atom, t, g, alpha, beta},
  atoms = DeleteDuplicates[Cases[f, Zeta[_] | LerchPhi[_, _, _], {0, Infinity}]];
  If[Length[atoms] =!= 1, Return[$Failed, Module]];
  atom = First[atoms];
  If[f === atom, Return[{atom, 1, 0}, Module]];
  t = Unique["dirichletAtom$"];
  g = f /. atom -> t;
  If[! PolynomialQ[g, t] || Exponent[g, t] =!= 1, Return[$Failed, Module]];
  alpha = Simplify[Coefficient[g, t, 1], ass]; beta = Simplify[Coefficient[g, t, 0], ass];
  If[! FreeQ[{alpha, beta}, x | t] || ! exactQ[{alpha, beta}] ||
      ! TrueQ[Simplify[Element[beta, Reals], ass]] ||
      ! (provablyPositive[alpha, ass] || provablyNegative[alpha, ass]), Return[$Failed, Module]];
  {atom, alpha, beta}];

(* The affine constant joins the retained rows at exponent zero when that
   exponent lies below the cutoff; otherwise it is dominated by the remainder
   and is charged to the absolute bound instead. Returns {rows, charged}. *)
dirichletSpecialAffineConstant[rows_, beta_, actualCut_, ass_] := Module[{merged, index},
  If[beta === 0, Return[{rows, 0}, Module]];
  If[! less[0, actualCut], Return[{rows, beta}, Module]];
  index = Select[Range[Length[rows]], zeroQ[rows[[#, 1]], ass] &];
  merged = If[index === {}, Append[rows, {0, beta}],
    ReplacePart[rows, {First[index], 2} -> rows[[First[index], 2]] + beta]];
  merged = DeleteCases[merged, {_, c_} /; zeroQ[c, ass]];
  {Sort[merged, less[#1[[1]], #2[[1]]] &], 0}];

dirichletSpecialMake[f_, rows_, rho_, w_, domain_, x_, x0_, coord_, ass_, cut_, goal_, metadata_, limit_] := Module[
  {ell = Unique["dirichletLog$"], representation, result, actualCut},
  dirichletSpecialBudget[rows, limit];
  actualCut = If[cut === Automatic, rho, cut];
  representation = <|"Variable" -> x, "ScaleVariable" -> w, "LogVariable" -> ell,
    "Assumptions" -> ass, "Domain" -> domain, "Offset" -> 0, "Prefactor" -> 1,
    "Jet" -> {rows, rho, 0}, "Cutoff" -> actualCut,
    "RemainderDerivativeOrder" -> If[rho === Infinity, Infinity, 0]|>;
  result = seriesMake[representation, {"DirichletSpecialExpansion", {}}, Automatic];
  dirichletSpecialBudget[{result["Expression"], result["Remainder"]}, limit];
  GeneralizedSeries[Join[result[[1]], <|"Kind" -> "Forward", "Function" -> f,
    "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "SeriesApproach" -> <|"Variable" -> x, "Point" -> x0, "Direction" -> coord["Direction"]|>,
    "Cutoff" -> actualCut, "RequestedCutoff" -> cut, "RequestedTermGoal" -> goal,
    "ReturnedTermCount" -> Length[rows], "Precision" -> {rho, 0},
    "SeriesRepresentation" -> Join[result["SeriesRepresentation"], <|"Cutoff" -> actualCut|>],
    "ParameterScope" -> "Parameters are fixed on the recorded real target approach; no uniformity as parameters vary is asserted."|>, metadata]]];

dirichletZetaForward[f_, argument_, x_, x0_, cut_, ass_, coord_, goal_, limit_, alpha_: 1, beta_: 0] := Module[
  {count, low, high, middle, first, w, rows, rho, domain, expression, bound, charged, metadata},
  If[! MemberQ[{Infinity, -Infinity}, x0] || ! PolynomialQ[argument, x] ||
      Exponent[argument, x] =!= 1 || ! dirichletSpecialLargeArgumentQ[argument, x, coord, ass],
    Return[$Failed, Module]];
  dirichletSpecialOptions[cut, goal, limit];
  If[cut === Automatic,
    count = goal;
    If[count > limit, fail["ResourceLimit", "The Zeta Dirichlet term goal exceeds MaxTerms."]],
    (* Log[n]<cut is exclusive. Binary search avoids enumerating exp(cut)
       candidates, and the initial comparison rejects excessive requests.
       An explicit cutoff and a term goal are two independent reasons to stop,
       as in the ordinary constructor: an active goal caps the search and a
       cutoff-based refusal applies only when no goal keeps the retained count
       within the budget (report 16 N04 under D01; report 55 N02). *)
    If[less[Log[limit + 1], cut] && (goal === Automatic || goal > limit),
      fail["ResourceLimit", "The Zeta exponential-coordinate cutoff exceeds MaxTerms."]];
    low = 0; high = If[goal === Automatic, limit + 1, Min[limit, goal] + 1];
    While[high - low > 1,
      middle = Quotient[low + high, 2];
      If[less[Log[middle], cut], low = middle, high = middle]];
    count = low];
  first = count + 1; w = Exp[-argument]; rho = Log[first]; domain = ass && argument > 1;
  rows = Table[{Log[n], alpha}, {n, 1, count}];
  {rows, charged} = dirichletSpecialAffineConstant[rows, beta, If[cut === Automatic, rho, cut], ass];
  expression = alpha Total[Table[n^(-argument), {n, 1, count}]] + beta - charged;
  (* For decreasing t^-S, sum_(n=m)^Infinity n^-S lies between
     m^-S and m^-S + Integrate[t^-S,{t,m,Infinity}], S>1. *)
  bound = Abs[alpha] first^(-argument) (1 + first/(argument - 1)) + Abs[charged];
  metadata = <|
    "Expression" -> expression, "RemainderScaleExpression" -> first^(-argument),
    "FrontierTerm" -> alpha first^(-argument) + charged, "FirstOmittedInteger" -> first,
    "SpecialFunctionBackend" -> "ConvergentDirichletSeries", "SpecialFunctionFamily" -> "Zeta",
    "SourceArgument" -> argument, "ExpansionNature" -> "ConvergentDirichlet",
    "AbsoluteRemainderBound" -> bound, "RemainderLowerBound" -> alpha first^(-argument),
    "RemainderBoundConditions" -> domain,
    "ForwardRemainderContract" -> <|"Type" -> "DirichletIntegralComparison",
      "ConvergentForwardSeries" -> True, "NumericCertificate" -> False,
      "Statement" -> "The positive omitted Dirichlet tail is bounded by its first term plus the integral of t^(-SourceArgument) from FirstOmittedInteger to Infinity."|>,
    "TermConvention" -> "The positive coordinate is w=Exp[-SourceArgument]. The n-th Dirichlet term is w^Log[n]; the exclusive cutoff is in this coordinate and SeriesTermGoal includes the constant n=1 term.",
    "AsymptoticReferences" -> {"https://dlmf.nist.gov/25.2.E1"}|>;
  If[alpha =!= 1 || beta =!= 0,
    metadata = Join[metadata, <|"AffineCoefficients" -> {alpha, beta}, "SpecialFunctionAtom" -> Zeta[argument],
      "ForwardRemainderContract" -> Join[metadata["ForwardRemainderContract"], <|
        "Statement" -> "The omitted Dirichlet tail of the Zeta atom, scaled by the affine coefficient alpha, is bounded in absolute value by Abs[alpha] times its first term plus the integral of t^(-SourceArgument) from FirstOmittedInteger to Infinity; an affine constant above the cutoff is charged to the bound."|>]|>];
    (* The signed lower bound describes a positive tail; a negative alpha or a
       charged constant leaves only the absolute bound. *)
    If[! provablyPositive[alpha, ass] || charged =!= 0, metadata = KeyDrop[metadata, "RemainderLowerBound"]]];
  dirichletSpecialMake[f, rows, rho, w, domain, x, x0, coord, ass, cut, goal, metadata, limit]];

dirichletSpecialMoment[z_, 0] := 1/(1 - z);
dirichletSpecialMoment[z_, k_Integer?Positive] := If[z === 0, 0, PolyLog[-k, z]];

dirichletLerchCoefficient[z_, s_, k_, ass_, limit_] := Module[{coefficient},
  coefficient = inverseBranchTry[FullSimplify[(-1)^k Pochhammer[s, k] dirichletSpecialMoment[z, k]/Factorial[k], ass]];
  If[coefficient === $Failed, fail["ResourceLimit", "A Lerch moment exceeded the symbolic time budget."]];
  dirichletSpecialBudget[coefficient, limit]; coefficient];

(* Taylor's theorem for h(t)=(1+t)^(-s), t>=0, gives
   |h(t)-sum_(k<N) (-1)^k (s)_k t^k/k!|
       <= |(s)_N| t^N (1+t)^D/N!, D=max(0,ceil(-s-N)).
   For a>=1, t=n/a<=n. Summing absolute values against |z|^n
   yields the finite polylogarithmic moment constant below. This includes
   N=0, with M_0 containing the n=0 term, and every fixed real s. *)
dirichletLerchBoundConstant[z_, s_, n_, ass_, limit_] := Module[{d, constant},
  d = Max[0, Ceiling[-s - n]];
  If[n + d > limit, fail["ResourceLimit", "The Lerch remainder moment degree exceeds MaxTerms."]];
  constant = inverseBranchTry[FullSimplify[Abs[Pochhammer[s, n]]/Factorial[n] *
    Sum[Binomial[d, j] dirichletSpecialMoment[Abs[z], n + j], {j, 0, d}], ass]];
  If[constant === $Failed, fail["ResourceLimit", "The Lerch remainder bound exceeded the symbolic time budget."]];
  dirichletSpecialBudget[constant, limit]; constant];

dirichletLerchForward[f_, z_, s_, argument_, x_, x0_, cut_, ass_, coord_, goal_, limit_, alpha_: 1, beta_: 0] := Module[
  {degree, rows = {}, k = 0, coefficient, frontier = None, rho, w, domain, boundConstant,
    expression, exactSource, bound, conditions, charged, metadata, scaleExpression, frontierTerm},
  If[! FreeQ[{z, s}, x] || ! exactRealQ[z] || ! exactRealQ[s] ||
      ! less[-1, z] || ! less[z, 1] || ! dirichletSpecialLargeArgumentQ[argument, x, coord, ass],
    Return[$Failed, Module]];
  dirichletSpecialOptions[cut, goal, limit];
  degree = Which[z === 0, 0, IntegerQ[s] && s <= 0, -s, True, Infinity];
  While[k <= degree,
    If[k > limit, fail["ResourceLimit", "The Lerch nonzero-moment search exceeds MaxTerms."]];
    coefficient = dirichletLerchCoefficient[z, s, k, ass, limit];
    If[! zeroQ[coefficient, ass],
      (* The cutoff and the goal stop independently, whichever comes first. *)
      If[(cut =!= Automatic && ! less[s + k, cut]) || (goal =!= Automatic && Length[rows] >= goal),
        frontier = {s + k, coefficient, k}; Break[]];
      AppendTo[rows, {s + k, coefficient}]; dirichletSpecialBudget[rows, limit]];
    k++];
  rho = If[frontier === None, Infinity, frontier[[1]]];
  w = 1/argument; domain = ass && argument > 0;
  rows = {#[[1]], alpha #[[2]]} & /@ rows;
  {rows, charged} = dirichletSpecialAffineConstant[rows, beta, If[cut === Automatic, rho, cut], ass];
  expression = Total[(argument^(-#[[1]]) #[[2]]) & /@ rows];
  exactSource = degree =!= Infinity;
  If[frontier === None, boundConstant = 0; bound = 0; conditions = domain,
    boundConstant = Abs[alpha] dirichletLerchBoundConstant[z, s, frontier[[3]], ass, limit];
    bound = boundConstant argument^(-rho); conditions = domain && argument >= 1];
  scaleExpression = If[frontier === None, 0, argument^(-rho)];
  frontierTerm = If[frontier === None, 0, alpha frontier[[2]] argument^(-rho)];
  If[charged =!= 0,
    (* A charged constant is O(1). It is dominated by the atom's tail only
       when rho <= 0; for a positive rho the omitted constant is the leading
       omitted term, so the remainder order drops to zero and the constant is
       added to the bound as a separate term rather than folded into the
       a^(-rho) coefficient (wave-7 report 57). *)
    If[less[0, rho],
      bound = bound + Abs[charged]; rho = 0; scaleExpression = 1; frontierTerm = charged;
      conditions = domain && argument >= 1,
      boundConstant = boundConstant + Abs[charged]; bound = boundConstant argument^(-rho)]];
  metadata = <|
    "Expression" -> expression,
    "RemainderScaleExpression" -> scaleExpression,
    "FrontierTerm" -> frontierTerm,
    "FirstOmittedMoment" -> If[frontier === None, None, frontier[[3]]],
    "SpecialFunctionBackend" -> "GeometricMomentExpansion", "SpecialFunctionFamily" -> "LerchPhi",
    "SourceArgument" -> argument, "LerchParameters" -> {z, s},
    "ExpansionNature" -> If[exactSource, "Finite", "Poincare"],
    "FiniteSourceExpansion" -> exactSource, "AbsoluteRemainderBound" -> bound,
    "RemainderBoundConstant" -> boundConstant, "RemainderBoundConditions" -> conditions,
    "ForwardRemainderContract" -> <|"Type" -> "TaylorRemainderSummedAgainstGeometricWeights",
      "ConvergentForwardSeries" -> exactSource, "NumericCertificate" -> False,
      "Statement" -> "For fixed real z and s with |z|<1 and positive a>=1, Taylor's theorem applied to (1+n/a)^(-s) bounds the omitted terms by RemainderBoundConstant a^(-RemainderPower). Negative integer s and z=0 give finite exact source expansions."|>,
    "TermConvention" -> "The positive coordinate is w=1/SourceArgument. Blocks have absolute exponents s+k with coefficients (-1)^k Pochhammer[s,k] M_k(z)/k!, where M_0(z)=1/(1-z) and M_k(z)=PolyLog[-k,z] for k>0. SeriesTermGoal counts nonzero blocks; cutoff is exclusive in w.",
    "AsymptoticReferences" -> {"https://dlmf.nist.gov/25.14.E1", "https://dlmf.nist.gov/25.12.E10"}|>;
  If[alpha =!= 1 || beta =!= 0,
    metadata = Join[metadata, <|"AffineCoefficients" -> {alpha, beta}, "SpecialFunctionAtom" -> LerchPhi[z, s, argument],
      "ForwardRemainderContract" -> Join[metadata["ForwardRemainderContract"], <|
        "Statement" -> "For fixed real z and s with |z|<1 and positive a>=1, Taylor's theorem applied to (1+n/a)^(-s) bounds the omitted terms of the LerchPhi atom; RemainderBoundConstant includes the factor Abs[alpha] of the affine coefficient and any affine constant charged above the cutoff."|>]|>]];
  dirichletSpecialMake[f, rows, rho, w, domain, x, x0, coord, ass, cut, goal, metadata, limit]];

dirichletSpecialForwardExpansion[f_, x_, x0_, cut_, ass_, coord_, goal_, limit_] := Module[{form, atom, alpha, beta},
  If[FreeQ[f, Zeta[_] | LerchPhi[_, _, _]], Return[$Failed, Module]];
  form = dirichletSpecialAffineForm[f, x, ass];
  If[form === $Failed, Return[$Failed, Module]];
  {atom, alpha, beta} = form;
  validateInput[f, limit]; dirichletSpecialBudget[f, limit];
  If[Head[atom] === Zeta,
    dirichletZetaForward[f, First[atom], x, x0, cut, ass, coord, goal, limit, alpha, beta],
    dirichletLerchForward[f, atom[[1]], atom[[2]], atom[[3]], x, x0, cut, ass, coord, goal, limit, alpha, beta]]];
