(* Finite logarithmic hierarchies. Loaded in AsymptoticInverse`Private`.
   Exact source-coordinate charts live separately in SourceCoordinates.wl. *)

AsymptoticInverse`AsymptoticLogarithmicInverse::usage =
"AsymptoticLogarithmicInverse[f,{x,x0},{y,cutoff}] inverts supported finite logarithmic hierarchies. Reciprocal-logarithmic units and leading logarithmic monomials use a positive exclusive relative cutoff in the recorded inverse-logarithmic coordinate. Generalized logarithmic coefficients use an exact target-power cutoff above the leading observable power, which may be negative at infinity. AsymptoticLogarithmicInverse[f,{x,x0},y,SeriesTermGoal->n] retains the first n complete nonzero blocks, or a certified exact terminating expansion, subject to MaxTerms and a bounded refinement search. LogarithmicLevels bounds the explicitly represented positive logarithmic hierarchy.";
AsymptoticInverse`LogarithmicInverseResidual::usage =
"LogarithmicInverseResidual[result] checks a logarithmic-unit inverse by exact formal composition of its normalized forward equation. Generalized logarithmic coefficients currently return UnsupportedResidual; their retained coefficients and original equation remain available on the expansion object for independent checking.";

Options[AsymptoticInverse`AsymptoticLogarithmicInverse] = Join[Options[AsymptoticInverse], {"LogarithmicLevels" -> 3}];

logarithmicMerge[rows_, ass_] := Module[{g, merged},
  g = GatherBy[({canon[#[[1]]], #[[2]]} & /@ rows), First];
  merged = ({#[[1, 1]], Simplify[Total[#[[All, 2]]], ass]} & /@ g);
  Sort[Select[merged, ! zeroQ[#[[2]], ass] &], less[#1[[1]], #2[[1]]] &]];

logarithmicLevels[u_, n_] := NestList[Log, -Log[u], n - 1];

(* Each listed coordinate is strictly positive on the admitted local
   branch. Consequently a positive monomial can be extracted from an exact
   real power: (M c)^r = M^r c^r for M > 0. The constant c keeps its principal
   power and must independently pass the real-coefficient check below. This
   handles Simplify combining Sqrt[u] Sqrt[level] without PowerExpand. *)
logarithmicMonomialFactor[e_, variables_List] := Module[{parts, part, position},
  Which[
    FreeQ[e, Alternatives @@ variables], {e, ConstantArray[0, Length[variables]]},
    MemberQ[variables, e],
      position = First[FirstPosition[variables, e]];
      {1, UnitVector[Length[variables], position]},
    Head[e] === Times,
      parts = logarithmicMonomialFactor[#, variables] & /@ List @@ e;
      If[MemberQ[parts, $Failed], $Failed,
        {Times @@ parts[[All, 1]], Total[parts[[All, 2]]]}],
    Head[e] === Power && exactRealQ[e[[2]]],
      part = logarithmicMonomialFactor[e[[1]], variables];
      If[part === $Failed, $Failed, {part[[1]]^e[[2]], e[[2]] part[[2]]}],
    True, $Failed]];

logarithmicRead[f_, x_, coord_, levels_, ass_] := Module[
  {u = coord["u"], fu, mapped, terms, rows = {}, part, j},
  fu = Simplify[f /. x -> coord["Substitution"], ass && u > 0];
  mapped = fu /. Log[u] -> -First[levels];
  Do[mapped = mapped /. Log[levels[[j]]] -> levels[[j + 1]], {j, Length[levels] - 1}];
  mapped = Expand[mapped]; terms = If[Head[mapped] === Plus, List @@ mapped, {mapped}];
  Do[
    part = logarithmicMonomialFactor[term, {u}];
    If[part === $Failed, Return[$Failed, Module]];
    AppendTo[rows, {First[part[[2]]], part[[1]]}], {term, terms}];
  If[! And @@ (exactRealQ[#[[1]]] & /@ rows), Return[$Failed, Module]];
  <|"LocalFunction" -> fu, "MappedFunction" -> mapped,
    "Rows" -> logarithmicMerge[rows, ass]|>];

(* Every accepted coefficient is a finite generalized Laurent polynomial
   in the positive levels. Its Euler derivative stays in the same algebra. *)
logarithmicMonomials[e_, levels_, ass_] := Module[
  {expanded = Expand[e], terms, rows = {}, coefficient, powers, part},
  terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  Do[
    part = logarithmicMonomialFactor[term, levels];
    If[part === $Failed, Return[$Failed, Module]];
    {coefficient, powers} = part;
    If[! TrueQ[Simplify[Element[coefficient, Reals], ass]], Return[$Failed, Module]];
    If[! zeroQ[coefficient, ass], AppendTo[rows, {coefficient, powers}]], {term, terms}];
  rows];

logarithmicCoefficientBound[e_, levels_, ass_] := Module[{monomials, rational, numerator, denominator},
  monomials = logarithmicMonomials[e, levels, ass];
  If[monomials =!= $Failed,
    Return[If[monomials === {}, 0, Ceiling[Max[Total[Max[0, #] & /@ #[[2]]] & /@ monomials]]], Module]];
  If[! FreeQ[e, Alternatives @@ Rest[levels]], Return[$Failed, Module]];
  rational = Together[e]; numerator = Numerator[rational]; denominator = Denominator[rational];
  If[! PolynomialQ[numerator, First[levels]] || ! PolynomialQ[denominator, First[levels]], Return[$Failed, Module]];
  If[! And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@
       Join[CoefficientList[numerator, First[levels]], CoefficientList[denominator, First[levels]]]), Return[$Failed, Module]];
  If[! TrueQ[Simplify[Last[CoefficientList[denominator, First[levels]]] != 0, ass]], Return[$Failed, Module]];
  Max[0, Exponent[numerator, First[levels]] - Exponent[denominator, First[levels]]]];

logarithmicEuler[e_, levels_] := -Sum[D[e, levels[[j]]]/(Times @@ Take[levels, j - 1]), {j, Length[levels]}];

logarithmicTaylor[e_, t_, degree_, ass_, limit_] := Module[{result},
  result = Quiet[Check[Normal[Series[e, {t, 0, degree}]], $Failed]];
  If[result === $Failed || ! FreeQ[result, _SeriesData | Indeterminate | _DirectedInfinity],
    fail["LogarithmicSeriesFailure", "The normalized logarithmic unit could not be expanded on the selected branch."]];
  result = Expand[result];
  If[LeafCount[result] > limit, fail["ResourceLimit", "The logarithmic coefficient expression exceeded MaxTerms leaves."]];
  result];

logarithmicUnitSolve[rhs_, w_, t_, degree_, ass_, limit_] := Module[{current = 1, next},
  If[degree + 2 > limit, fail["ResourceLimit", "The logarithmic iteration count exceeds MaxTerms."]];
  Do[
    next = logarithmicTaylor[rhs /. w -> current, t, degree, ass, limit];
    If[next === current, Break[]]; current = next,
    {degree + 2}]; current];

logarithmicUnitData[coefficient_, levels_, p_, ass_] := Module[
  {rational, numerator, denominator, a, h, t = Unique["logt$"], w = Unique["logw$"],
   monomials, powers, reciprocals, shift = Unique["logshift$"], ratios, rhs},
  If[FreeQ[coefficient, Alternatives @@ Rest[levels]],
    rational = Together[coefficient]; numerator = Numerator[rational]; denominator = Denominator[rational];
    If[PolynomialQ[numerator, First[levels]] && PolynomialQ[denominator, First[levels]] &&
       Exponent[numerator, First[levels]] === Exponent[denominator, First[levels]],
      a = Simplify[Last[CoefficientList[numerator, First[levels]]]/Last[CoefficientList[denominator, First[levels]]], ass];
      h = Together[(coefficient /. First[levels] -> 1/t)/a];
      If[! TrueQ[Simplify[h == 1, ass]],
        rhs = (h /. t -> t/(1 - t Log[w]))^(-1/p);
        Return[<|"Type" -> "ReciprocalLogUnit", "Amplitude" -> a,
          "FormalVariable" -> t, "UnitVariable" -> w, "UnitRightHandSide" -> rhs,
          "NormalizedForward" -> w^p (h /. t -> t/(1 - t Log[w])) - 1,
          "LeadingLogPowers" -> ConstantArray[0, Length[levels]], "LogarithmicUnit" -> h|>, Module]]]];
  monomials = logarithmicMonomials[coefficient, levels, ass];
  If[monomials === $Failed || Length[monomials] =!= 1, Return[$Failed, Module]];
  {a, powers} = First[monomials];
  If[And @@ (zeroQ[#, ass] & /@ powers), Return[$Failed, Module]];
  reciprocals = Table[Unique["inverseLogLevel$"], {Length[levels] - 1}];
  ratios = FoldList[1 + #2 Log[#1] &, 1 + t (shift - Log[w]), reciprocals];
  rhs = Times @@ MapThread[Power, {ratios, -powers/p}];
  <|"Type" -> "LeadingLogMonomial", "Amplitude" -> a, "FormalVariable" -> t,
    "UnitVariable" -> w, "UnitRightHandSide" -> rhs,
    "NormalizedForward" -> w^p (Times @@ MapThread[Power, {ratios, powers}]) - 1,
    "LeadingLogPowers" -> powers, "ShiftVariable" -> shift,
    "ReciprocalLevelVariables" -> reciprocals|>];

logarithmicUnitConstruct[data_, rows_, offset_, p_, levels_, f_, x_, x0_, y_, coord_, cutoff_, r_, ass_, limit_] := Module[
  {a = data["Amplitude"], t = data["FormalVariable"], w = data["UnitVariable"],
   target, baseLevels, z, variable, substitutions = {}, shift, unit, observable, degree,
   blocks, omitted, beta, logdegree, powers = data["LeadingLogPowers"], rint,
   prefactor, expression, rem, remainderScale, domain, sign, finiteOffset,
   extra, extraBounds, gap, beyondScale, representation, targetScale, targetLimit,
   allCoefficients, terms, formalAssumptions, inputKind, sourceLevels},
  If[! (provablyPositive[a, ass] || provablyNegative[a, ass]), fail["UnprovedSign", "The leading logarithmic amplitude must have a provable nonzero real sign."]];
  sign = If[provablyPositive[a, ass], 1, -1]; target = (y - offset)/a;
  rint = If[coord["Infinite"], -r, r]; finiteOffset = If[r === 1 && ! coord["Infinite"], x0, 0];
  If[coord["Sign"] === -1 && ! IntegerQ[r], fail["NonrealObservable", "A negative selected source branch requires integer observable powers."]];
  If[data["Type"] === "ReciprocalLogUnit",
    z = target^(1/p); variable = -1/Log[z]; domain = target > 0 && 0 < z < 1;
    logdegree = 0; formalAssumptions = ass,
    targetScale = -Log[target]/p;
    baseLevels = NestList[Log, targetScale, Length[levels] - 1];
    shift = Total[MapThread[#1 Log[#2] &, {powers, baseLevels}]]/p;
    z = target^(1/p) (Times @@ MapThread[Power, {baseLevels, -powers/p}]);
    variable = 1/targetScale;
    substitutions = Join[{data["ShiftVariable"] -> shift},
      Thread[data["ReciprocalLevelVariables"] -> (1/Rest[baseLevels])]];
    domain = target > 0 && And @@ (# > 1 & /@ baseLevels);
    logdegree = Ceiling[cutoff]; formalAssumptions = ass];
  degree = Ceiling[cutoff] + 1;
  unit = logarithmicUnitSolve[data["UnitRightHandSide"], w, t, degree, formalAssumptions, limit];
  observable = logarithmicTaylor[unit^rint, t, degree, formalAssumptions, limit];
  allCoefficients = Select[Table[{n, Simplify[Coefficient[observable, t, n], ass]}, {n, 0, degree}], ! zeroQ[#[[2]], ass] &];
  blocks = Select[allCoefficients, less[#[[1]], cutoff] &];
  omitted = Select[allCoefficients, ! less[#[[1]], cutoff] &];
  beta = If[omitted === {}, Ceiling[cutoff], omitted[[1, 1]]];
  If[data["Type"] =!= "ReciprocalLogUnit", logdegree = beta];
  prefactor = coord["Sign"]^r z^rint;
  terms = blocks /. substitutions;
  expression = finiteOffset + prefactor Total[(variable^#[[1]] #[[2]]) & /@ terms];
  extra = Rest[rows]; extraBounds = logarithmicCoefficientBound[#[[2]], levels, ass] & /@ extra;
  If[MemberQ[extraBounds, $Failed], Return[$Failed, Module]];
  beyondScale = If[extra === {}, 0,
    gap = Min[canon[#[[1]] - p] & /@ extra];
    Abs[prefactor] z^gap (1 + Abs[Log[z]])^(Max[extraBounds] + Ceiling[Total[Abs /@ powers]])];
  rem = Abs[prefactor] PowerLogRemainder[variable, beta, logdegree];
  remainderScale = Abs[prefactor] variable^beta (1 + Abs[Log[variable]])^logdegree;
  targetLimit = If[less[0, p], offset, sign Infinity];
  representation = If[data["Type"] === "ReciprocalLogUnit",
    <|"Variable" -> y, "ScaleVariable" -> variable, "LogVariable" -> Unique["ell$"],
      "Offset" -> finiteOffset, "Prefactor" -> prefactor, "Jet" -> {blocks, beta, 0},
      "Assumptions" -> ass, "Domain" -> domain, "Cutoff" -> cutoff, "RemainderDerivativeOrder" -> 0|>,
    Missing["NestedLogarithmicCoefficients"]];
  sourceLevels = logarithmicLevels[coord["u"], Length[levels]];
  GeneralizedSeries[<|"Kind" -> "LogarithmicInverse", "Scale" -> data["Type"],
    "Expression" -> expression, "Remainder" -> rem, "RemainderScaleExpression" -> remainderScale,
    "RemainderVariable" -> variable, "RemainderPower" -> beta, "RemainderLogDegree" -> logdegree,
    "Prefactor" -> prefactor, "Offset" -> finiteOffset, "Terms" -> terms, "Blocks" -> blocks,
    "Uniformizer" -> variable, "LogarithmicVariable" -> variable, "LogarithmicLevels" -> Length[levels],
    "CoefficientLevelSubstitutions" -> substitutions, "LeadingLocalApproximation" -> z,
    "LogarithmicEquationData" -> data, "LogarithmicUnitPolynomial" -> unit,
    "LogarithmicObservablePolynomial" -> observable, "FormalVariable" -> t,
    "TermConvention" -> "Offset + Prefactor Sum[t^n C_n], with the displayed positive inverse-logarithmic t. Cutoff is exclusive in n. Nested lower-logarithmic coefficients are retained exactly.",
    "Cutoff" -> cutoff, "Truncation" -> "LogarithmicExponent", "Power" -> r,
    "Function" -> f, "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> x0,
    "Direction" -> coord["Direction"], "LocalVariable" -> coord["u"],
    "LocalSubstitution" -> (x -> coord["Substitution"]), "SourceLogarithmicLevels" -> sourceLevels,
    "SourceDomain" -> And @@ (# > 1 & /@ sourceLevels),
    "TargetDomain" -> (ass && domain), "Limit" -> targetLimit,
    "Assumptions" -> ass, "LeadingPower" -> p, "LeadingCoefficient" -> a,
    "LeadingCoreOnly" -> (extra =!= {}), "ExactModel" -> (extra === {}),
    "BeyondLogarithmicOrders" -> Total[(coord["u"]^#[[1]] (#[[2]] /. Thread[levels -> sourceLevels])) & /@ extra],
    "BeyondLogarithmicRemainderScale" -> beyondScale,
    "RemainderExplanation" -> "A joint analytic implicit equation bounds the complete logarithmic tail. Higher positive source-power gaps are smaller than every fixed inverse-logarithmic order and are recorded separately. Constants and source threshold are not computed numerical certificates.",
    "ConvergenceContract" -> <|"Type" -> "AnalyticImplicitFunction", "NumericCertificate" -> False,
      "Parameters" -> If[data["Type"] === "ReciprocalLogUnit", {variable},
        Join[{variable, variable shift}, 1/Rest[baseLevels]]]|>,
    "SeriesRepresentation" -> representation, "SeriesData" -> Missing["LogarithmicScale"],
    "RemainderDerivativeOrder" -> 0|>]];

logarithmicCoefficient[k_, gaps_, coefficients_, p_, r_, levels_, ass_, limit_] := Module[{n = Total[k], weight, c},
  If[n === 0, Return[{0, 1}, Module]];
  weight = canon[k . gaps]; c = Expand[Times @@ MapThread[Power, {coefficients, k}]];
  Do[c = Expand[logarithmicEuler[c, levels] + (r + weight + p j) c];
    If[LeafCount[c] > limit, fail["ResourceLimit", "The generalized logarithmic coefficient exceeded MaxTerms leaves."]], {j, 1, n - 1}];
  {weight, Simplify[(-1)^n r c/(p^n (Times @@ (Factorial /@ k))), ass && And @@ (# > 1 & /@ levels)]}];

(* One builder belongs to one constructor call and its fixed logarithmic
   symbols. Cache complete multi-indices, including zero coefficients;
   regions and merged blocks are rebuilt when the goal changes the cutoff. *)
logarithmicPowerBuilder[rows_, offset_, p_, levels_, f_, x_, x0_, y_, coord_, r_, ass_, limit_] := Module[
  {a = rows[[1, 2]], gaps, coefficients, monomials, degreeBounds, rint, coefficient, prepared = False},
  coefficient[k_] := coefficient[k] = logarithmicCoefficient[k, gaps, coefficients, p, rint, levels, ass, limit];
  Function[cutoff, Module[{h, region, blocks, boundary, beta, degree, z, target, sign,
    w, levelValues, terms, expression, domain, offsetValue},
  (* Keep preparation lazy so public option and goal checks still run first. *)
  If[! prepared,
    If[! FreeQ[a, Alternatives @@ levels] || ! TrueQ[Simplify[Element[a, Reals], ass]], Return[$Failed, Module]];
    If[! (provablyPositive[a, ass] || provablyNegative[a, ass]), fail["UnprovedSign", "The leading source coefficient must have a provable nonzero real sign."]];
    coefficients = Simplify[#[[2]]/a, ass] & /@ Rest[rows];
    monomials = logarithmicMonomials[#, levels, ass] & /@ coefficients;
    If[MemberQ[monomials, $Failed], Return[$Failed, Module]];
    If[FreeQ[coefficients, Alternatives @@ Rest[levels]] &&
       And @@ (PolynomialQ[#, First[levels]] & /@ coefficients), Return[$Failed, Module]];
    gaps = canon[#[[1]] - p] & /@ Rest[rows];
    rint = If[coord["Infinite"], -r, r]; prepared = True];
  h = Abs[p] cutoff - rint;
  If[! less[0, h], fail["CutoffTooSmall", "The cutoff must exceed the leading target power of the requested observable."]];
  If[coord["Sign"] === -1 && ! IntegerQ[r], fail["NonrealObservable", "A negative selected source branch requires integer observable powers."]];
  region = indexRegion[gaps, h, False, limit];
  blocks = logarithmicMerge[coefficient /@ region["Inside"], ass];
  boundary = region["Boundary"];
  beta = If[boundary === {}, Infinity, Min[canon[# . gaps] & /@ boundary]];
  If[! ListQ[degreeBounds], degreeBounds = logarithmicCoefficientBound[#, levels, ass] & /@ coefficients];
  degree = If[boundary === {}, 0, Max[(# . degreeBounds) & /@ boundary]];
  sign = If[provablyPositive[a, ass], 1, -1]; target = (y - offset)/a;
  z = target^(1/p); w = If[less[0, p], sign (y - offset), sign/(y - offset)];
  levelValues = logarithmicLevels[z, Length[levels]];
  terms = {canon[(rint + #[[1]])/Abs[p]],
      coord["Sign"]^r Abs[a]^(-(rint + #[[1]])/p) (#[[2]] /. Thread[levels -> levelValues])} & /@ blocks;
  offsetValue = If[r === 1 && ! coord["Infinite"], x0, 0];
  expression = offsetValue + Total[(w^#[[1]] #[[2]]) & /@ terms];
  domain = ass && target > 0 && And @@ (# > 1 & /@ levelValues);
  GeneralizedSeries[<|"Kind" -> "LogarithmicInverse", "Scale" -> "GeneralizedLogarithmicCoefficients",
    "Expression" -> expression, "Terms" -> terms, "Blocks" -> blocks,
    "Remainder" -> If[beta === Infinity, 0, PowerLogRemainder[w, (rint + beta)/Abs[p], degree]],
    "RemainderScaleExpression" -> If[beta === Infinity, 0, w^((rint + beta)/Abs[p]) (1 + Abs[Log[w]])^degree],
    "RemainderVariable" -> w, "RemainderPower" -> (rint + beta)/Abs[p], "RemainderLogDegree" -> degree,
    "Uniformizer" -> z, "LogarithmicLevels" -> Length[levels], "CoefficientLevels" -> levels,
    "CoefficientLevelValues" -> levelValues, "IndexRegion" -> region, "PowerGaps" -> gaps,
    "NormalizedCoefficients" -> coefficients, "CoefficientDegreeBounds" -> degreeBounds,
    "TermConvention" -> "Each {beta,C} contributes w^beta C, with w the recorded positive target coordinate. C is an exact generalized Laurent polynomial in the finite positive logarithmic hierarchy of Uniformizer. Cutoff is exclusive in beta.",
    "Cutoff" -> cutoff, "NormalizedSourceWeightCutoff" -> h, "Truncation" -> "Exponent", "Power" -> r,
    "Function" -> f, "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> x0,
    "Direction" -> coord["Direction"], "LocalVariable" -> coord["u"], "LocalSubstitution" -> (x -> coord["Substitution"]),
    "Limit" -> If[less[0, p], offset, sign Infinity], "TargetDomain" -> domain,
    "Assumptions" -> ass, "LeadingPower" -> p, "LeadingCoefficient" -> a,
    "ExactModel" -> True, "LeadingCoreOnly" -> False,
    "RemainderExplanation" -> "The complete multi-index tail is bounded by the least excluded source weight and a conservative logarithmic envelope over the finite boundary. Exact nonpolynomial logarithmic coefficients remain unexpanded.",
    "ConvergenceContract" -> <|"Type" -> "FiniteAnalyticLogarithmicLift", "NumericCertificate" -> False|>,
    "SeriesData" -> Missing["GeneralizedLogarithmicCoefficients"], "RemainderDerivativeOrder" -> 0|>]]]];

(* A finite zero prefix is not an exact-termination certificate. Verify a
   candidate against the original equation, with the already selected real
   source branch, before removing a remainder. Failure or timeout only means
   that the bounded term search must continue. *)
logarithmicGoalTermination[GeneralizedSeries[a_Association]] := Module[
  {x, y, rint, sign, magnitude, candidate, domain, verified, representation},
  If[! TrueQ[Lookup[a, "ExactModel", False]] || LeafCount[a["Function"]] > 300 ||
     LeafCount[a["Expression"]] > 500, Return[None, Module]];
  {x, y} = a["Variables"];
  rint = If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], -a["Power"], a["Power"]];
  sign = Which[a["ExpansionPoint"] === Infinity, 1, a["ExpansionPoint"] === -Infinity, -1,
    a["Direction"] === "FromBelow", -1, True, 1];
  magnitude = (a["Expression"] - Lookup[a, "Offset", If[a["Power"] === 1 &&
      ! MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], a["ExpansionPoint"], 0]])/sign^a["Power"];
  candidate = a["LocalSubstitution"][[2]] /. a["LocalVariable"] -> magnitude^(1/rint);
  domain = a["TargetDomain"] && magnitude > 0;
  verified = TimeConstrained[
    Quiet[Check[FullSimplify[(a["Function"] /. x -> candidate) == y, domain], False]], 2, False];
  If[! TrueQ[verified], Return[None, Module]];
  representation = Lookup[a, "SeriesRepresentation", Missing["Unavailable"]];
  If[AssociationQ[representation], representation = Join[representation,
    <|"Jet" -> {a["Blocks"], Infinity, 0}|>]];
  GeneralizedSeries[Join[a, <|"Remainder" -> 0, "RemainderScaleExpression" -> 0,
    "RemainderPower" -> Infinity, "RemainderLogDegree" -> 0,
    "SeriesRepresentation" -> representation,
    "ExactTerminationCertificate" -> <|"Verified" -> True,
      "Verification" -> "Exact symbolic composition with the original forward expression",
      "Candidate" -> candidate, "Target" -> y, "BranchAssumptions" -> domain|>|>]]];

(* All constructor calls retain complete weight blocks. A goal advances past
   cancellations; it is never used as an exponent cutoff. Generalized-power
   searches may cross several weights at once, in which case rebuilding at
   the next excluded weight keeps exactly the first requested blocks. *)
logarithmicGoalConstruct[make_, unitQ_, rows_, p_, rint_, goal_, limit_] := Module[
  {cutoff, gaps, step, result = None, next, count, tries = 0, previousCount = -1, nextCutoff,
   maximum = Min[limit, 50 goal + 10], termination, triedBlocks = None, boundary},
  If[goal > limit, fail["ResourceLimit", "SeriesTermGoal exceeds MaxTerms.",
    <|"RequestedTermGoal" -> goal, "MaxTerms" -> limit|>]];
  If[unitQ, cutoff = goal,
    gaps = canon[#[[1]] - p] & /@ Rest[rows];
    step = If[gaps === {}, 1, Min[gaps]]/2;
    cutoff = canon[(rint + step)/Abs[p]]];
  While[True,
    If[tries >= maximum,
      fail["ResourceLimit", "The logarithmic nonzero-block search exceeded its bounded refinement budget.",
        <|"RequestedTermGoal" -> goal, "MaxTerms" -> limit,
          "ConstructionCalls" -> tries, "BestExpansion" -> result|>]];
    tries++; next = catch[make[cutoff]];
    If[FailureQ[next], Throw[Failure[next[[1]], Join[next[[2]],
      <|"RequestedTermGoal" -> goal, "ConstructionCalls" -> tries,
        "BestExpansion" -> result|>]], $tag]];
    If[next === $Failed, Return[$Failed, Module]];
    result = next; count = Length[result["Blocks"]];
    If[count > goal,
      cutoff = result["Terms"][[goal + 1, 1]];
      Continue[]];
    If[count === goal || result["Remainder"] === 0, Break[]];
    If[result["Blocks"] =!= triedBlocks,
      triedBlocks = result["Blocks"]; termination = logarithmicGoalTermination[result];
      If[MatchQ[termination, GeneralizedSeries[_Association]], result = termination; Break[]]];
    If[unitQ,
      nextCutoff = If[count === previousCount, Min[2 cutoff, limit - 3], cutoff + 1];
      If[! less[cutoff, nextCutoff], fail["ResourceLimit", "The logarithmic search cannot advance within MaxTerms.",
        <|"RequestedTermGoal" -> goal, "MaxTerms" -> limit,
          "ConstructionCalls" -> tries, "BestExpansion" -> result|>]];
      cutoff = nextCutoff; previousCount = count,
      boundary = result["IndexRegion"]["Boundary"];
      If[boundary === {}, Break[]];
      cutoff = canon[(rint + Min[canon[# . gaps] & /@ boundary] + step)/Abs[p]]]];
  GeneralizedSeries[Join[result[[1]], <|"RequestedTermGoal" -> goal,
    "ReturnedTermCount" -> Length[result["Blocks"]],
    "TermGoalReached" -> (Length[result["Blocks"]] === goal),
    "TermSelection" -> "CompleteNonzeroBlocks", "TermGoalConstructionCalls" -> tries|>]]];

logarithmicConstruct[f_, x_, x0_, y_, cutoff0_, opts : OptionsPattern[AsymptoticInverse`AsymptoticLogarithmicInverse]] := Module[
  {ass = OptionValue[AsymptoticInverse`AsymptoticLogarithmicInverse, {opts}, Assumptions],
   dir = OptionValue[AsymptoticInverse`AsymptoticLogarithmicInverse, {opts}, Direction],
   limit = OptionValue[AsymptoticInverse`AsymptoticLogarithmicInverse, {opts}, "MaxTerms"],
   depth = OptionValue[AsymptoticInverse`AsymptoticLogarithmicInverse, {opts}, "LogarithmicLevels"],
   r = OptionValue[AsymptoticInverse`AsymptoticLogarithmicInverse, {opts}, "Power"],
   method = OptionValue[AsymptoticInverse`AsymptoticLogarithmicInverse, {opts}, Method], result,
   input = OptionValue[AsymptoticInverse`AsymptoticLogarithmicInverse, {opts}, "InputRemainder"],
   trunc = OptionValue[AsymptoticInverse`AsymptoticLogarithmicInverse, {opts}, "Truncation"],
   goal = OptionValue[AsymptoticInverse`AsymptoticLogarithmicInverse, {opts}, SeriesTermGoal],
   coord, levels, read, rows, offset, p, data, cutoff = cutoff0, bounds, used, make},
  If[FreeQ[f, Log], Return[$Failed, Module]];
  validateInput[f, limit];
  If[! MemberQ[{"Lagrange", "Newton", "Lambert", "GroupedLagrange"}, method],
    fail["InvalidOption", "Method must be Lagrange, Newton, Lambert or GroupedLagrange; the logarithmic algebra records its own selected algorithm."]];
  If[! IntegerQ[depth] || depth < 1 || depth > 8, fail["InvalidLogarithmicDepth", "LogarithmicLevels must be an integer from 1 through 8."]];
  If[x === y || ! FreeQ[f, y], fail["InvalidVariables", "Use distinct source and target symbols, with no target symbol in the input."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters only."]];
  coord = localCoordinate[x, x0, dir]; levels = Table[Unique["loglevel$"], {depth}];
  read = logarithmicRead[f, x, coord, levels, ass]; If[read === $Failed, Return[$Failed, Module]];
  rows = read["Rows"];
  used = Select[Range[depth], ! FreeQ[rows, levels[[#]]] &];
  If[used === {}, Return[$Failed, Module]];
  levels = Take[levels, Max[used]];
  bounds = logarithmicCoefficientBound[#[[2]], levels, ass] & /@ rows;
  If[MemberQ[bounds, $Failed], Return[$Failed, Module]];
  offset = Total[Cases[rows, {0, c_} /; FreeQ[c, Alternatives @@ levels] :> c]];
  rows = Select[rows, ! (#[[1]] === 0 && FreeQ[#[[2]], Alternatives @@ levels]) &];
  If[rows === {}, Return[$Failed, Module]];
  p = rows[[1, 1]]; If[p === 0, Return[$Failed, Module]];
  data = logarithmicUnitData[rows[[1, 2]], levels, p, ass];
  If[! exactRealQ[r] || r === 0, fail["InvalidOption", "Power must be a nonzero exact real number."]];
  If[trunc =!= "Exponent", fail["UnsupportedOption", "Finite logarithmic hierarchies require an explicit exponent cutoff, not marker-depth truncation."]];
  If[! MemberQ[{None, Automatic}, input], fail["UnsupportedOption", "InputRemainder for this logarithmic hierarchy requires a separately supplied transport contract."]];
  make = If[data =!= $Failed,
    Function[h, logarithmicUnitConstruct[data, rows, offset, p, levels, f, x, x0, y, coord, h, r, ass, limit]],
    logarithmicPowerBuilder[rows, offset, p, levels, f, x, x0, y, coord, r, ass, limit]];
  result = If[cutoff === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give a positive logarithmic cutoff or SeriesTermGoal -> n."]];
    logarithmicGoalConstruct[make, data =!= $Failed, rows, p, If[coord["Infinite"], -r, r], goal, limit],
    If[! exactRealQ[cutoff] || (data =!= $Failed && ! less[0, cutoff]),
      fail["InvalidCutoff", "The cutoff must be an exact real number, positive for a logarithmic unit. A target-power cutoff must exceed the leading observable power."]];
    make[cutoff]];
  If[result === $Failed, Return[$Failed, Module]];
  GeneralizedSeries[Join[result[[1]], <|"RequestedMethod" -> method,
    "Method" -> If[data === $Failed, "GeneralizedLogarithmicLagrange", "LogarithmicFixedPoint"]|>]]];

logarithmicPublic[f_, x_, x0_, y_, cutoff_, opts___] := Module[{result = logarithmicConstruct[f, x, x0, y, cutoff, opts]},
  If[result === $Failed, fail["UnsupportedLogarithmicScale", "The expression is outside the admitted finite real logarithmic hierarchy or its selected sign domain."], result]];

(* Preserve the established ordinary engine for polynomial log coefficients.
   The automatic hook handles only expressions that need the larger algebra. *)
logarithmicDispatch[f_, x_, x0_, y_, cutoff_, opts : OptionsPattern[AsymptoticInverse]] := Module[
  {coord, u, ell = Unique["ell$"], ordinary,
   ass = OptionValue[AsymptoticInverse, {opts}, Assumptions],
   dir = OptionValue[AsymptoticInverse, {opts}, Direction]},
  If[FreeQ[f, Log], Return[$Failed, Module]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"];
  ordinary = parseFinite[Simplify[f /. x -> coord["Substitution"], ass && u > 0], u, ell, ass];
  If[ordinary =!= $Failed, Return[$Failed, Module]];
  logarithmicConstruct[f, x, x0, y, cutoff, opts]];

AsymptoticInverse`AsymptoticLogarithmicInverse[f_, {x_Symbol, x0_}, {y_Symbol, cutoff_}, opts : OptionsPattern[]] :=
  catch[logarithmicPublic[f, x, x0, y, cutoff, opts]];
AsymptoticInverse`AsymptoticLogarithmicInverse[f_, {x_Symbol, x0_}, y_Symbol, opts : OptionsPattern[]] :=
  catch[logarithmicPublic[f, x, x0, y, Automatic, opts]];
AsymptoticInverse`AsymptoticLogarithmicInverse[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use AsymptoticLogarithmicInverse[f,{x,x0},{y,cutoff}]."|>];

logarithmicResidual[a_, requested_, limit_] := Module[{data, t, w, polynomial, order, residual},
  If[! MemberQ[{"ReciprocalLogUnit", "LeadingLogMonomial"}, Lookup[a, "Scale", ""]],
    fail["UnsupportedResidual", "This helper checks normalized logarithmic-unit equations. Generalized logarithmic coefficient jets require an independent coefficient-algebra composition."]];
  data = a["LogarithmicEquationData"]; t = data["FormalVariable"]; w = data["UnitVariable"];
  order = If[requested === Automatic, a["Cutoff"], requested];
  If[! exactRealQ[order] || ! less[0, order] || less[a["Cutoff"], order],
    fail["InvalidCutoff", "Residual order must be positive and cannot exceed the returned logarithmic cutoff."]];
  polynomial = Total[(t^#[[1]] #[[2]]) & /@ Select[
    Table[{n, Coefficient[a["LogarithmicUnitPolynomial"], t, n]}, {n, 0, Ceiling[a["Cutoff"]]}], less[#[[1]], a["Cutoff"]] &]];
  residual = logarithmicTaylor[data["NormalizedForward"] /. w -> polynomial, t, Ceiling[order] - 1, a["Assumptions"], limit];
  <|"Residual" -> Simplify[residual /. a["CoefficientLevelSubstitutions"], a["Assumptions"]],
    "Vanishes" -> zeroQ[residual, a["Assumptions"]],
    "ZeroBelowCutoff" -> zeroQ[residual, a["Assumptions"]], "Cutoff" -> order,
    "Scope" -> "Exact formal composition of the normalized leading logarithmic core; separately recorded higher source-power sectors are beyond this logarithmic cutoff.",
    "OriginalFunction" -> a["Function"], "LeadingCoreOnly" -> a["LeadingCoreOnly"]|>];

AsymptoticInverse`LogarithmicInverseResidual[GeneralizedSeries[a_Association]] := catch[logarithmicResidual[a, Automatic, 200000]];
AsymptoticInverse`LogarithmicInverseResidual[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Supply a logarithmic-unit expansion object."|>];
