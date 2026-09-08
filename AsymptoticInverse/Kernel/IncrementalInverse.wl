(* Incremental exact-weight inversion helpers. Loaded in the package's Private
   context. State is returned by value; no process-global coefficient cache is
   retained, and a failed refinement does not alter its input state. *)

incrementalIndexKey[k_List] := ToString[k, InputForm];

incrementalInverseState[d_List, polys_List, p_, r_, ell_, ass_, limit_] := Module[{zero},
  zero = ConstantArray[0, Length[d]];
  <|"Gaps" -> d, "Polynomials" -> polys, "LeadingPower" -> p, "Power" -> r,
    "LogVariable" -> ell, "Assumptions" -> ass, "MaxTerms" -> limit,
    "Inside" -> {}, "Boundary" -> <|incrementalIndexKey[zero] -> {0, zero}|>,
    "Blocks" -> {}, "LastWeight" -> -Infinity, "NextWeight" -> 0,
    "CoefficientEvaluations" -> 0, "Layers" -> 0,
    "PolynomialPowerCache" -> ({1, #} & /@ polys),
    "PolynomialPowerCacheEntries" -> 0, "PolynomialPowerCacheCapacity" -> Max[0, limit - 1],
    "PolynomialPowerRequests" -> 0, "PolynomialPowerCacheHits" -> 0,
    "PolynomialPowerEvaluations" -> 0, "PolynomialPowerCacheEvictions" -> 0|>];

(* Only powers >=2 of nonconstant logarithmic polynomials occupy cache slots.
   Powers 0 and 1 merely refer to 1 and the already stored model coefficient.
   The optional cache uses spare index-budget slots and is trimmed before a
   larger frontier is admitted, so it cannot reduce the usable index region. *)
incrementalResizePolynomialCache[state_Association] := Module[
  {s = state, cache, capacity, entries, lengths, position, evictions = 0},
  cache = Lookup[s, "PolynomialPowerCache", ({1, #} & /@ s["Polynomials"])];
  capacity = Max[0, s["MaxTerms"] - Length[s["Inside"]] - Length[s["Boundary"]]];
  entries = Total[Length /@ cache] - 2 Length[cache];
  While[entries > capacity,
    lengths = Length /@ cache; position = First[FirstPosition[lengths, Max[lengths]]];
    cache[[position]] = Most[cache[[position]]]; entries--; evictions++];
  Join[s, <|"PolynomialPowerCache" -> cache, "PolynomialPowerCacheEntries" -> entries,
    "PolynomialPowerCacheCapacity" -> capacity,
    "PolynomialPowerRequests" -> Lookup[s, "PolynomialPowerRequests", 0],
    "PolynomialPowerCacheHits" -> Lookup[s, "PolynomialPowerCacheHits", 0],
    "PolynomialPowerEvaluations" -> Lookup[s, "PolynomialPowerEvaluations", 0],
    "PolynomialPowerCacheEvictions" -> Lookup[s, "PolynomialPowerCacheEvictions", 0] + evictions|>]];

incrementalPolynomialProduct[state_Association, k_List] := Module[
  {s = state, cache = state["PolynomialPowerCache"], polys = state["Polynomials"], ell = state["LogVariable"],
   entries = state["PolynomialPowerCacheEntries"], capacity = state["PolynomialPowerCacheCapacity"],
   requests = 0, hits = 0, evaluations = 0, factors, power, value, available, missing, j},
  factors = Table[power = k[[j]];
    If[power < 2 || FreeQ[polys[[j]], ell], polys[[j]]^power,
      requests++; available = Length[cache[[j]]] - 1;
      If[power <= available, hits++; cache[[j, power + 1]],
        While[available < power && entries < capacity,
          value = Expand[Last[cache[[j]]] polys[[j]]]; evaluations++;
          cache[[j]] = Append[cache[[j]], value]; available++; entries++];
        If[available === power, Last[cache[[j]]],
          (* A full cache is a performance condition, never an input failure. *)
          evaluations++; Expand[Last[cache[[j]]] polys[[j]]^(power - available)]]]],
    {j, Length[k]}];
  s = Join[s, <|"PolynomialPowerCache" -> cache, "PolynomialPowerCacheEntries" -> entries,
    "PolynomialPowerRequests" -> state["PolynomialPowerRequests"] + requests,
    "PolynomialPowerCacheHits" -> state["PolynomialPowerCacheHits"] + hits,
    "PolynomialPowerEvaluations" -> state["PolynomialPowerEvaluations"] + evaluations|>];
  {s, Expand[Times @@ factors]}];

(* Apply the Euler coefficient formula to a product supplied by the cache.
   lagrangeCoefficient remains the independent uncached reference route. *)
incrementalCoefficientFromProduct[k_, d_, p_, r_, ell_, ass_, product_] := Module[{n = Total[k], weight, q = product},
  If[n === 0, Return[{0, 1}, Module]];
  weight = canon[k . d];
  Do[q = Expand[D[q, ell] + (r + weight + p j) q], {j, 1, n - 1}];
  {weight, polyCanon[Expand[(-1)^n r q/(p^n (Times @@ (Factorial /@ k)))], ell, ass]}];

incrementalInverseRegion[state_Association] :=
  <|"Inside" -> state["Inside"], "Boundary" -> (Last /@ Values[state["Boundary"]])|>;

advanceInverseState[state_Association] := Module[
  {s = state, boundary, weight, layer, keys, inside, additions, d, ell, ass, limit,
   index, neighbor, key, nextWeight, coefficients, product},
  boundary = state["Boundary"];
  If[Length[boundary] == 0, Return[state, Module]];
  d = state["Gaps"]; ell = state["LogVariable"]; ass = state["Assumptions"];
  limit = state["MaxTerms"]; weight = state["NextWeight"];
  (* Positive gaps imply that every predecessor of an index of this weight has
     already been retained. All collisions are therefore present in this layer. *)
  layer = Select[Values[boundary], equal[First[#], weight] &];
  keys = incrementalIndexKey[Last[#]] & /@ layer;
  boundary = KeyDrop[boundary, keys];
  additions = Last /@ layer;
  inside = Join[state["Inside"], additions];
  Do[
   index = item[[2]];
   Do[
    neighbor = ReplacePart[index, j -> index[[j]] + 1];
    key = incrementalIndexKey[neighbor];
    If[! KeyExistsQ[boundary, key],
     AssociateTo[boundary, key -> {canon[weight + d[[j]]], neighbor}];
     If[Length[inside] + Length[boundary] > limit,
      fail["ResourceLimit", "Incremental multi-index enumeration exceeded MaxTerms.",
       <|"MaxTerms" -> limit|>]]],
    {j, Length[d]}],
   {item, layer}];
  If[Length[inside] + Length[boundary] > limit,
   fail["ResourceLimit", "Incremental multi-index enumeration exceeded MaxTerms.",
    <|"MaxTerms" -> limit|>]];
  s = incrementalResizePolynomialCache[Join[s, <|"Inside" -> inside, "Boundary" -> boundary|>]];
  coefficients = Table[
    {s, product} = incrementalPolynomialProduct[s, index];
    incrementalCoefficientFromProduct[index, d, state["LeadingPower"], state["Power"], ell, ass, product],
    {index, additions}];
  nextWeight = If[Length[boundary] == 0, Infinity,
    First[Sort[First /@ Values[boundary], leq]]];
  AssociateTo[s, {"Inside" -> inside, "Boundary" -> boundary,
    "Blocks" -> Join[state["Blocks"], jetMerge[coefficients, ell, ass]],
    "LastWeight" -> weight, "NextWeight" -> nextWeight,
    "CoefficientEvaluations" -> state["CoefficientEvaluations"] + Length[additions],
    "Layers" -> state["Layers"] + 1}];
  s];

(* Newton states certify correctness strictly below Precision. The initial
   zero jet is correct below the least gap, even when that weight cancels. *)
newtonInverseState[d_List, polys_List, p_, ell_, ass_, limit_] :=
  <|"Gaps" -> d, "Polynomials" -> polys, "LeadingPower" -> p,
    "LogVariable" -> ell, "Assumptions" -> ass, "MaxTerms" -> limit,
    "UnitJet" -> {}, "Precision" -> If[d === {}, Infinity, First[Sort[d, leq]]],
    "StepCutoffs" -> {}|>;

refineNewtonState[state_Association, cut_] := Module[
  {s = state, precision = state["Precision"], U = state["UnitJet"], d, polys,
   p, ell, ass, limit, work, residual, derivative, check, steps},
  If[leq[cut, precision], Return[state, Module]];
  If[cut === Infinity,
   fail["InvalidCutoff", "Newton refinement requires a finite exact cutoff for a nontrivial model."]];
  d = state["Gaps"]; polys = state["Polynomials"]; p = state["LeadingPower"];
  ell = state["LogVariable"]; ass = state["Assumptions"]; limit = state["MaxTerms"];
  steps = state["StepCutoffs"];
  While[less[precision, cut],
   work = minOf[canon[2 precision], cut];
   residual = modelEquation[U, d, polys, p, work, ell, ass, limit];
   If[residual =!= {},
    derivative = modelEquationDerivative[U, d, polys, p, work, ell, ass, limit];
    U = jetAdd[U,
      jetScale[jetMul[residual,
        jetReciprocalUnit[derivative, work, ell, ass, limit],
        work, ell, ass, limit], -1, ell, ass], work, ell, ass];
   (* This is an exact symbolic residual check, not a floating-point stopping
      criterion. It also catches a broken precision invariant in reused states. *)
    check = modelEquation[U, d, polys, p, work, ell, ass, limit];
    If[check =!= {}, fail["NewtonFailure", "Newton refinement left a residual below its claimed precision.",
      <|"Cutoff" -> work, "Residual" -> check|>]]];
   precision = work; AppendTo[steps, work]];
  AssociateTo[s, {"UnitJet" -> U, "Precision" -> precision, "StepCutoffs" -> steps}];
  s];

newtonSolveDoubling[d_List, polys_List, p_, cut_, ell_, ass_, limit_] := Module[{state},
  state = refineNewtonState[newtonInverseState[d, polys, p, ell, ass, limit], cut];
  jetTrim[state["UnitJet"], cut, ell, ass]];

(* If H(z,L)^n = Sum[z^w A[n,w](L)], the multinomial factor in A[n,w]
   replaces the individual k! denominator by n!. At fixed (n,w), all Euler
   operators are identical, so combine before differentiating. *)
groupedLagrangeBlocks[d_List, polys_List, p_, r_, cut_, ell_, ass_, limit_] := Module[
  {perturbation, powers = {{0, 1}}, result, n = 0, rows, q, weight},
  If[! less[0, cut], Return[{}, Module]];
  result = {{0, 1}};
  If[d === {}, Return[result, Module]];
  If[cut === Infinity,
   fail["InvalidCutoff", "Grouped Lagrange inversion requires a finite cutoff for a nontrivial model."]];
  perturbation = jetTrim[Transpose[{d, polys}], cut, ell, ass];
  While[powers =!= {} && perturbation =!= {},
   powers = jetMul[powers, perturbation, cut, ell, ass, limit];
   If[powers === {}, Break[]];
   n++;
   If[n > limit, fail["ResourceLimit", "Grouped Lagrange inversion exceeded MaxTerms.",
     <|"MaxTerms" -> limit|>]];
   rows = Table[
     weight = term[[1]]; q = term[[2]];
     Do[q = Expand[D[q, ell] + (r + weight + p j) q], {j, 1, n - 1}];
     {weight, polyCanon[(-1)^n r q/(p^n n!), ell, ass]},
     {term, powers}];
   result = jetAdd[result, rows, cut, ell, ass]];
  result];
