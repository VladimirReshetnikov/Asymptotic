(* Finite commensurate flat sectors around an exact monomial core.
   This module is loaded in Private` and uses a separate exponential degree.
   It never represents a finite power-log truncation as an exact zero sector. *)

AsymptoticAnalysis`AsymptoticFlatInverse::usage =
"AsymptoticFlatInverse[f,{x,x0},{y,n}] inverts an exact monomial core plus finite commensurate flat exponentials, retaining complete exponential sectors through degree n. Coefficients remain finite exact power-log expressions in the monomial core inverse; the full omitted tail has a separate asymptotic contract.";
Options[AsymptoticAnalysis`AsymptoticFlatInverse] = {
 Assumptions :> $Assumptions, Direction -> Automatic, "Power" -> 1, "MaxTerms" -> 20000};

flatTrim[expression_, z_, n_, limit_] := Module[{v = Expand[expression], result},
 If[! PolynomialQ[v, z], fail["FlatSectorInvariant", "An exponential-sector coefficient ceased to be polynomial in its marker."]];
 result = Sum[Coefficient[v, z, k] z^k, {k, 0, Min[n, Exponent[v, z]]}];
 If[LeafCount[result] > limit, fail["ResourceLimit", "The finite flat-sector polynomial exceeded MaxTerms expression leaves."]];
 result];

flatModel[f_, x_, coord_, ell_, ass_, limit_] := Module[
 {u = coord["u"], local, terms, ordinary = 0, rows = {}, factors, exponentials,
   exp, parsed, c, p, coefficient, powers, rates, base, degrees, coreRows,
   active, offset, q, a, z = Unique["flat$"], rr, coeffRows, realQ},
 local = Expand[Simplify[f /. x -> coord["Substitution"], ass && u > 0]];
 terms = If[Head[local] === Plus, List @@ local, {local}];
 Do[
  factors = If[Head[term] === Times, List @@ term, {term}];
  exponentials = Select[factors, MatchQ[#, Power[E, _]] && ! FreeQ[#[[2]], u] &];
  If[exponentials === {}, ordinary += term,
   exp = Total[#[[2]] & /@ exponentials];
   parsed = parseFinite[exp, u, ell, ass];
   If[parsed === $Failed || Length[parsed] =!= 1 || ! FreeQ[parsed[[1, 2]], ell],
    fail["UnsupportedFlatPhase", "Each flat phase must be -c/u^p with positive exact real c and p."]];
   {p, c} = {-parsed[[1, 1]], -parsed[[1, 2]]};
   If[! exactRealQ[p] || ! exactRealQ[c] || ! less[0, p] || ! less[0, c],
    fail["UnsupportedFlatPhase", "Each flat phase must have positive exact numeric c and p."]];
   coefficient = Simplify[term/(Times @@ exponentials), ass && u > 0];
   coeffRows = parseFinite[coefficient, u, ell, ass];
   If[coeffRows === $Failed || ! And @@ (exactRealQ[#[[1]]] &&
      corePerturbationRealPolynomialQ[#[[2]], ell, ass] & /@ coeffRows),
    fail["UnsupportedFlatCoefficient", "Flat-sector coefficients must be finite real power-log expressions."]];
   AppendTo[rows, {c, p, coefficient, coeffRows}]], {term, terms}];
 If[rows === {}, fail["NoFlatSectors", "The forward expression contains no supported flat exponential."]];
 powers = DeleteDuplicates[rows[[All, 2]], equal];
 If[Length[powers] =!= 1, fail["IncompatibleFlatScales", "This finite sector engine requires a common positive phase power."]];
 p = First[powers]; rates = rows[[All, 1]]; base = First[Sort[rates, leq]];
 degrees = canon[#/base] & /@ rates;
 If[! And @@ (IntegerQ[#] && # > 0 & /@ degrees),
  fail["IncommensurateFlatRates", "Every phase rate must be an integer multiple of the smallest rate."]];
 coreRows = parseFinite[ordinary, u, ell, ass];
 If[coreRows === $Failed, fail["UnsupportedFlatCore", "The nonflat part must be an exact shifted monomial core."]];
 coreRows = jetMerge[coreRows, ell, ass];
 offset = Total[Cases[coreRows, {0, b_} /; FreeQ[b, ell] :> b]];
 If[! TrueQ[Simplify[Element[offset, Reals], ass]],
  fail["UnprovedRealOffset", "The target offset must be provably real under the parameter assumptions."]];
 active = Select[coreRows, ! (#[[1]] === 0 && FreeQ[#[[2]], ell]) &];
 If[Length[active] =!= 1 || ! FreeQ[active[[1, 2]], ell],
  fail["UnsupportedFlatCore", "A truncated algebraic inverse cannot serve as the exact zero sector; use an exact shifted monomial core."]];
 {q, a} = First[active];
 If[! exactRealQ[q] || q === 0 || ! (provablyPositive[a, ass] || provablyNegative[a, ass]),
  fail["UnsupportedFlatCore", "The exact monomial core needs a nonzero exact leading power and a provable real sign."]];
 rr = Total[MapThread[#1[[3]] z^#2 &, {rows, degrees}]];
 <|"PhasePower" -> p, "PhaseRate" -> base, "SectorDegrees" -> degrees,
   "FlatRows" -> rows, "CorePower" -> q, "CoreCoefficient" -> a, "Offset" -> offset,
   "Marker" -> z, "PerturbationPolynomial" -> flatTrim[rr, z, Max[degrees], limit]|>];

flatConstruct[f_, x_, x0_, y_, n_, opts : OptionsPattern[AsymptoticAnalysis`AsymptoticFlatInverse]] := Module[
 {ass = optionAssumptions[AsymptoticAnalysis`AsymptoticFlatInverse, {opts}],
  dir = OptionValue[AsymptoticAnalysis`AsymptoticFlatInverse, {opts}, Direction],
  r = OptionValue[AsymptoticAnalysis`AsymptoticFlatInverse, {opts}, "Power"],
  limit = OptionValue[AsymptoticAnalysis`AsymptoticFlatInverse, {opts}, "MaxTerms"],
  coord, u, ell = Unique["ell$"], model, z, q, a, p, c, fp, hp, rr,
  u0, rint, polynomial, term, k, j, sectors, allSectors, expression, zero,
  rem, tail, rowBounds, b, d, envelope, phase, powerPolynomial, boundBase},
 validateInput[f, limit];
 If[x === y || ! FreeQ[f, y] || ! FreeQ[ass, x | y],
  fail["InvalidVariables", "Use distinct source and target symbols and parameter-only assumptions."]];
 If[! IntegerQ[n] || n < 1 || n + 1 > limit,
  fail["InvalidSectorDepth", "The sector depth must be a positive integer below MaxTerms."]];
 If[! exactRealQ[r] || r === 0, fail["InvalidPower", "Power must be a nonzero exact real number."]];
 coord = localCoordinate[x, x0, dir]; u = coord["u"];
 If[coord["Sign"] === -1 && ! IntegerQ[r], fail["NonrealObservable", "A negative source branch requires an integer observable power."]];
 model = flatModel[f, x, coord, ell, ass, limit];
 {z, q, a, p, c, rr} = Lookup[model, {"Marker", "CorePower", "CoreCoefficient", "PhasePower", "PhaseRate", "PerturbationPolynomial"}];
 rint = If[coord["Infinite"], -r, r];
 u0 = ((y - model["Offset"])/a)^(1/q);
 fp = a q u^(q - 1); hp = coord["Sign"]^r rint u^(rint - 1);
 zero = If[r === 1 && ! coord["Infinite"], x0, 0] + coord["Sign"]^r u0^rint;
 polynomial = 0; powerPolynomial = 1;
 Do[
  powerPolynomial = flatTrim[powerPolynomial rr, z, n + 1, limit];
  term = flatTrim[hp powerPolynomial/fp, z, n + 1, limit];
  Do[term = flatTrim[(D[term, u] + c p u^(-p - 1) z D[term, z])/fp, z, n + 1, limit], {j, 1, k - 1}];
  polynomial = flatTrim[polynomial + (-1)^k term/k!, z, n + 1, limit], {k, 1, n + 1}];
 phase = Exp[-c/u0^p];
 allSectors = Table[{k, Simplify[Coefficient[polynomial, z, k], ass && u > 0] /. u -> u0}, {k, 1, n + 1}];
 sectors = Select[Take[allSectors, n], ! zeroQ[#[[2]], ass] &];
 expression = zero + Total[(#[[2]] phase^#[[1]]) & /@ sectors];
 (* A common analytic majorant uses |u-u0| = O(u0^(p+1)).
    Choose an envelope R/(u^q u^p) = O(u^-b M^d E), b,d >= 0. *)
 rowBounds = Flatten[model["FlatRows"][[All, 4]], 1];
 b = Max[0, Max[(q + p - #[[1]]) & /@ rowBounds]];
 d = Max[0, Max[polyDegree[#[[2]], ell] & /@ rowBounds]];
 envelope = u0^(-b) (1 + Abs[Log[u0]])^d;
 rem = phase^(n + 1) PowerLogRemainder[u0, canon[rint + p - (n + 1) b], (n + 1) d];
 GeneralizedSeries[<|"Kind" -> "FlatInverse", "Scale" -> "FiniteFlatSectors",
  "Expression" -> expression, "Variable" -> y, "Variables" -> {x, y}, "Function" -> f,
  "ExpansionPoint" -> x0, "Direction" -> coord["Direction"], "Power" -> r,
  "Assumptions" -> ass, "TargetDomain" -> ass && (y - model["Offset"])/a > 0,
  "CoreInverseCoordinate" -> u0, "ZeroSector" -> zero, "FlatScale" -> phase,
  "SectorDepth" -> n, "Sectors" -> sectors, "Terms" -> Join[{{0, zero}}, sectors],
  "TermConvention" -> "Each {k,C} contributes C FlatScale^k; SectorDepth includes k<=n. The zero sector is exact.",
  "FirstOmittedSector" -> Last[allSectors], "Remainder" -> rem,
  "RemainderScaleExpression" -> phase^(n + 1) u0^(rint + p - (n + 1) b) (1 + Abs[Log[u0]])^((n + 1) d),
  "MajorantContract" -> <|"Type" -> "AsymptoticExistence", "NumericCertificate" -> False,
    "SmallScale" -> envelope phase, "ObservableScale" -> u0^(rint + p),
    "Statement" -> "For fixed data, the complete omitted sector tail is at most C u0^(rint+p) (K chi)^(n+1)/(1-K chi) for chi=u0^(-b) M^d E sufficiently small. Constants and threshold are existential."|>,
  "ExactModel" -> True, "Model" -> model, "RemainderDerivativeOrder" -> 0,
  "FlatAnalyticRemainder" -> <|"Type" -> "ExactMonomialFlatIFT", "SourceDiskRadiusPower" -> 1 + p,
    "TargetDerivativePowerLoss" -> p + q, "AllFixedOrders" -> True|>,
  "SeriesData" -> Missing["IndependentFlatSectorTruncation"]|>]];

AsymptoticAnalysis`AsymptoticFlatInverse[f_, {x_Symbol, x0_}, {y_Symbol, n_}, opts : OptionsPattern[]] :=
 catch[flatConstruct[f, x, x0, y, n, opts]];
AsymptoticAnalysis`AsymptoticFlatInverse[___] := Failure["InvalidArguments", <|
 "MessageTemplate" -> "Use AsymptoticFlatInverse[f,{x,x0},{y,positiveIntegerSectorDepth}]."|>];
