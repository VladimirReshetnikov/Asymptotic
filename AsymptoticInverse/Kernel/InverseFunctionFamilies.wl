(* Loaded in AsymptoticInverse`Private`.

   Exact scalar family reduction, before choosing a source inverse branch:
       A(x) F(t) + B(x) == Y(x)  <=>  F(t) == (Y(x)-B(x))/A(x).
   The equivalence requires A(x) != 0.  This helper has no endpoint or approach
   direction, so it records that obligation explicitly; its caller MUST prove
   eventual nonvanishing of Amplitude in the requested target germ.  The
   algebraic decomposition is independently verified without assuming A != 0.
   No varying parameter is replaced by a limiting or numerical value. *)

SetAttributes[inverseFamilyTry, HoldAll];
inverseFamilyTry[expr_] := TimeConstrained[Quiet[Check[expr, $Failed]], 2,
  fail["ResourceLimit", "Exact inverse-family reduction exceeded its two-second algebraic-operation limit.",
    <|"Stage" -> "InverseFunctionFamilyReduction", "TimeLimit" -> 2|>]];

(* Bound the number of terms before Expand can distribute a large product.
   A power of a sum of m terms has at most Binomial[n+m-1,m-1] distinct
   commutative products.  This is an upper bound, not an exact support count. *)
inverseFamilyExpansionCount[e_, limit_] := Module[{head = Head[e], counts, m, n},
  Which[
    head === Plus,
      Min[limit + 1, Total[inverseFamilyExpansionCount[#, limit] & /@ (List @@ e)]],
    head === Times,
      counts = inverseFamilyExpansionCount[#, limit] & /@ (List @@ e);
      Fold[Min[limit + 1, #1 #2] &, 1, counts],
    head === Power && IntegerQ[e[[2]]] && e[[2]] >= 0,
      n = e[[2]]; m = inverseFamilyExpansionCount[e[[1]], limit];
      Which[n === 0 || m === 1, 1, m > limit || n >= limit, limit + 1,
        True, Min[limit + 1, Binomial[n + m - 1, m - 1]]],
    True, 1]];

inverseFunctionSeparateFamily[data_Association, x_Symbol, ass_, limit_] := Module[
  {source, body, condition, parameters, positions, expanded, terms, offset,
    dependent, pairs, factors, sourceFactors, sourcePart, coefficient,
    groups, rows, factored, amplitude, ratios, core, identity, target,
    fixed, removed, reduction},
  If[! IntegerQ[limit] || limit < 1,
    fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[! And @@ (KeyExistsQ[data, #] & /@
      {"Body", "SourceVariable", "Condition", "TargetExpression", "Parameters"}),
    fail["InvalidInverseFunctionData", "A scalar inverse family needs parsed body, source, condition, target and parameter data."]];
  {body, source, condition, parameters} = Lookup[data,
    {"Body", "SourceVariable", "Condition", "Parameters"}];
  If[Head[source] =!= Symbol || source === x || ! ListQ[parameters],
    fail["InvalidInverseFunctionData", "The inverse family needs a distinct source symbol and a list of frozen argument values."]];
  If[FreeQ[parameters, x] || ! FreeQ[condition, x], Return[$Failed, Module]];
  If[! FreeQ[ass, source],
    fail["InvalidAssumptions", "Inverse-family parameter assumptions must not contain the fresh source variable."]];
  inverseFunctionSyntaxBudget[body, limit, "InverseFunctionFamilyInput"];
  If[inverseFamilyExpansionCount[body, limit] > limit,
    fail["ResourceLimit", "Distributing the inverse-family expression would exceed the MaxTerms support budget.",
      <|"Stage" -> "InverseFunctionFamilyExpansion", "MaxTerms" -> limit|>]];
  expanded = inverseFamilyTry[Expand[body]];
  If[expanded === $Failed, Return[$Failed, Module]];
  inverseFunctionSyntaxBudget[expanded, limit, "InverseFunctionFamilyExpansion"];
  terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  offset = Total[Select[terms, FreeQ[#, source] &]];
  dependent = Select[terms, ! FreeQ[#, source] &];
  If[dependent === {}, Return[$Failed, Module]];
  pairs = {};
  Do[
    factors = If[Head[term] === Times, List @@ term, {term}];
    sourceFactors = Select[factors, ! FreeQ[#, source] &];
    sourcePart = Times @@ sourceFactors;
    If[! FreeQ[sourcePart, x], Return[$Failed, Module]];
    coefficient = Times @@ Select[factors, FreeQ[#, source] &];
    AppendTo[pairs, {sourcePart, coefficient}], {term, dependent}];
  (* Group first: Expand[(1+x) F(t)] produces separate constant and x
     terms, which must be recombined before extracting their common factor. *)
  groups = GatherBy[pairs, First];
  rows = Table[{group[[1, 1]], inverseFamilyTry[FullSimplify[Total[group[[All, 2]]], ass]]},
    {group, groups}];
  If[AnyTrue[rows, Last[#] === $Failed &], Return[$Failed, Module]];
  rows = Select[rows, Last[#] =!= 0 &];
  If[rows === {}, Return[$Failed, Module]];
  factored = inverseFamilyTry[Factor[rows[[1, 2]]]];
  If[factored === $Failed, Return[$Failed, Module]];
  factors = If[Head[factored] === Times, List @@ factored, {factored}];
  (* Strip source-independent FIXED factors from the chosen amplitude.  In
     a(1+x) t+b(1+x) t^2 this chooses A=1+x, avoiding an unnecessary a!=0. *)
  amplitude = Times @@ Select[factors, ! FreeQ[#, x] &];
  If[amplitude === 0 || ! FreeQ[amplitude, source], Return[$Failed, Module]];
  ratios = inverseFamilyTry[FullSimplify[Cancel[#[[2]]/amplitude], ass]] & /@ rows;
  If[MemberQ[ratios, $Failed] || ! FreeQ[ratios, x], Return[$Failed, Module]];
  core = Total[MapThread[Times, {rows[[All, 1]], ratios}]];
  If[! FreeQ[core, x] || FreeQ[core, source] || ! FreeQ[offset, source], Return[$Failed, Module]];
  identity = inverseFamilyTry[FullSimplify[body == amplitude core + offset, ass]];
  If[! TrueQ[identity], Return[$Failed, Module]];
  target = inverseFamilyTry[Cancel[(data["TargetExpression"] - offset)/amplitude]];
  If[target === $Failed, Return[$Failed, Module]];
  inverseFunctionSyntaxBudget[{core, target, amplitude, offset}, limit, "InverseFunctionFamilyResult"];
  positions = Lookup[data, "ParameterPositions", Range[Length[parameters]]];
  If[! ListQ[positions] || Length[positions] =!= Length[parameters],
    fail["InvalidInverseFunctionData", "Inverse-family parameter positions must match their values."]];
  fixed = Select[Range[Length[parameters]], FreeQ[parameters[[#]], x] &];
  removed = Complement[Range[Length[parameters]], fixed];
  reduction = <|"Type" -> "ExactAffineOutputFamily", "OriginalBody" -> body,
    "Core" -> core, "Amplitude" -> amplitude, "Offset" -> offset,
    "OriginalTargetExpression" -> data["TargetExpression"], "TransformedTargetExpression" -> target,
    "OriginalParameters" -> parameters, "RemovedParameterPositions" -> positions[[removed]],
    "RequiredCondition" -> (amplitude != 0), "IdentityVerified" -> True,
    "IdentityAssumptions" -> ass,
    "Proof" -> "Exact symbolic identity Body == Amplitude Core + Offset; inverse equivalence additionally requires eventual Amplitude != 0."|>;
  Join[data, <|"Body" -> core, "TargetExpression" -> target,
    "Parameters" -> parameters[[fixed]], "ParameterPositions" -> positions[[fixed]],
    "Amplitude" -> amplitude, "ExactFamilyReduction" -> reduction|>]];

inverseFunctionSeparateFamily[___] :=
  fail["InvalidArguments", "Inverse-family separation requires parsed inverse data, an expansion symbol, parameter assumptions and MaxTerms."];
