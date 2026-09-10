(* Loaded in AsymptoticAnalysis`Private`.

   Parse an applied ACTIVE InverseFunction after ordinary Wolfram evaluation.
   The expression dispatcher must visit heads as well as arguments: an inverse
   application can itself occur in the head of a larger expression.  Already
   simplified native inverses belong to that dispatcher's ordinary route.

   InverseFunction[f,k,n][a1,...,an] replaces argument k of f by its inverse:
   f[a1,...,x,...,an] == ak.  See the selected-argument example at
   https://reference.wolfram.com/language/ref/InverseFunction.html .
   Applying Function, rather than replacing its slots or formal parameters,
   retains its documented lexical-renaming and nested-scoping behavior:
   https://reference.wolfram.com/language/ref/Function.html .
*)

inverseFunctionApplicationQ[e_] := ! AtomQ[e] && Head[Head[e]] === InverseFunction;
inverseFunctionApplicationQ[___] := False;

inverseFunctionSyntaxBudget[e_, limit_, stage_] :=
  If[LeafCount[e] > limit,
    fail["ResourceLimit", "InverseFunction syntax exceeded the MaxTerms expression-size budget.",
      <|"Stage" -> stage, "LeafCount" -> LeafCount[e], "MaxTerms" -> limit|>]];

(* Hold the formal-parameter declaration while inspecting it: an OwnValue on
   a global symbol used as a formal parameter must not change its arity. *)
inverseFunctionCallableArity[callable_, n_Integer] := Module[
  {size, declaration, arity, formals},
  If[Head[callable] === Symbol, Return[Null, Module]];
  If[Head[callable] =!= Function,
    fail["UnsupportedInverseFunction", "The forward callable must be a symbol or a pure Function.",
      <|"ForwardFunction" -> callable|>]];
  size = Length[callable];
  If[! MemberQ[{1, 2, 3}, size],
    fail["MalformedInverseFunction", "The pure Function has an invalid number of parts."]];
  If[size === 1, Return[Null, Module]];
  declaration = Extract[callable, {1}, HoldComplete];
  If[declaration === HoldComplete[Null], Return[Null, Module]];
  arity = Which[
    MatchQ[declaration, HoldComplete[_Symbol]], 1,
    MatchQ[declaration, HoldComplete[{___Symbol}]],
      declaration /. HoldComplete[{parameters___}] :> Length[HoldComplete[parameters]],
    True, fail["MalformedInverseFunction", "Named Function parameters must be a symbol or a list of distinct symbols."]];
  If[MatchQ[declaration, HoldComplete[{___Symbol}]],
    formals = Table[Extract[declaration, {1, j}, HoldComplete], {j, arity}];
    If[Length[DeleteDuplicates[formals]] =!= arity,
      fail["MalformedInverseFunction", "Named Function parameters must be distinct."]]];
  If[arity =!= n,
    fail["InverseFunctionArity", "The declared inverse arity does not match the named Function parameters.",
      <|"ExpectedArguments" -> arity, "DeclaredArguments" -> n|>]];
  Null];

(* ConditionalExpression normally propagates to the outside of mathematical
   expressions.  This walk also handles nested conditions and conditions in
   non-holding symbolic heads.  Do not hoist a condition out of an unevaluated
   binder or a control branch; doing that would change its logical meaning. *)
inverseFunctionConditions[e_, limit_] := Module[
  {conditions = {}, visited = 0, walk, body, condition, forbidden},
  forbidden = {Function, Module, Block, With, DynamicModule, Hold, HoldForm,
    HoldComplete, Unevaluated, Defer, Inactive, InverseFunction, Piecewise,
    If, Which, Switch, Condition, RuleDelayed, SetDelayed, ForAll, Exists};
  walk[expr_] := Module[{head, result, c},
    visited++;
    If[visited > limit,
      fail["ResourceLimit", "ConditionalExpression extraction exceeded MaxTerms.",
        <|"MaxTerms" -> limit|>]];
    If[AtomQ[expr], Return[expr, Module]];
    head = Head[expr];
    If[head === ConditionalExpression,
      If[Length[expr] =!= 2,
        fail["MalformedInverseFunction", "A forward ConditionalExpression must have two arguments."]];
      result = walk[expr[[1]]]; c = walk[expr[[2]]];
      AppendTo[conditions, c]; Return[result, Module]];
    If[FreeQ[expr, _ConditionalExpression], Return[expr, Module]];
    If[MemberQ[forbidden, head] ||
        (Head[head] === Symbol &&
          Intersection[Attributes[head], {HoldAll, HoldAllComplete, HoldFirst, HoldRest}] =!= {}),
      fail["ScopedInverseCondition", "A condition remains inside an unevaluated binding, holding, or control construct; its domain cannot be hoisted safely.",
        <|"Expression" -> expr|>]];
    If[! FreeQ[head, _ConditionalExpression],
      fail["ScopedInverseCondition", "ConditionalExpression in an unevaluated function head is unsupported.",
        <|"Expression" -> expr|>]];
    Map[walk, expr]];
  body = walk[e]; condition = And @@ conditions;
  If[body === Undefined || condition === False,
    fail["EmptyInverseDomain", "The forward function has an explicitly false domain condition."]];
  <|"Body" -> body, "Condition" -> condition|>];

inverseFunctionApplicationData[e_, parameterAss_, limit_] := Module[
  {operator, parts, callable, k, n, arguments, source, sourceArguments,
    parameterPositions, body, extracted, original = e},
  If[! inverseFunctionApplicationQ[e], Return[$Failed, Module]];
  If[! IntegerQ[limit] || limit < 1,
    fail["InvalidOption", "MaxTerms must be a positive integer."]];
  inverseFunctionSyntaxBudget[e, limit, "AppliedInverse"];
  operator = Head[e]; parts = List @@ operator;
  Switch[Length[parts],
    1, callable = parts[[1]]; k = 1; n = 1,
    3, callable = parts[[1]]; k = parts[[2]]; n = parts[[3]],
    _, fail["MalformedInverseFunction", "Use InverseFunction[f] or InverseFunction[f,k,n].",
      <|"OriginalOperator" -> operator|>]];
  If[! IntegerQ[n] || n < 1 || ! IntegerQ[k] || k < 1 || k > n,
    fail["InverseFunctionArity", "The selected argument and total arity must be integers satisfying 1 <= k <= n.",
      <|"ArgumentIndex" -> k, "ArgumentCount" -> n|>]];
  arguments = List @@ e;
  If[Length[arguments] =!= n,
    fail["InverseFunctionArity", "The inverse application must supply its declared number of arguments.",
      <|"ExpectedArguments" -> n, "SuppliedArguments" -> Length[arguments]|>]];
  inverseFunctionCallableArity[callable, n];
  source = Unique["inverseSource$"];
  sourceArguments = ReplacePart[arguments, k -> source];
  (* Evaluate exactly one ordinary callable application.  This is neither
     textual substitution into Function nor string evaluation.  The finite
     guard protects this parser from recursive user-defined callables. *)
  body = TimeConstrained[Quiet[Check[Apply[callable, sourceArguments], $Failed]], 5,
    fail["ResourceLimit", "Applying the forward callable exceeded the five-second syntax-evaluation limit.",
      <|"Stage" -> "ForwardFunctionApplication", "TimeLimit" -> 5|>]];
  If[FailureQ[body], Throw[body, $tag]];
  If[body === $Failed || body === $Aborted,
    fail["InverseFunctionApplication", "The forward callable could not be applied to its scalar source arguments.",
      <|"ForwardFunction" -> callable, "SourceArguments" -> sourceArguments|>]];
  inverseFunctionSyntaxBudget[body, limit, "ForwardFunctionApplication"];
  If[MemberQ[{List, Association, Function}, Head[body]] ||
      ! FreeQ[body /. _Function -> inverseFunctionBoundCallable, _Slot | _SlotSequence],
    fail["UnsupportedInverseFunction", "The forward callable must produce a scalar expression with all formal slots resolved.",
      <|"ForwardExpression" -> body|>]];
  extracted = inverseFunctionConditions[body, limit];
  If[MemberQ[{List, Association, Function}, Head[extracted["Body"]]],
    fail["UnsupportedInverseFunction", "The conditional forward callable must produce a scalar expression.",
      <|"ForwardExpression" -> extracted["Body"]|>]];
  parameterPositions = Delete[Range[n], k];
  <|"Body" -> extracted["Body"], "SourceVariable" -> source,
    "Condition" -> extracted["Condition"], "TargetExpression" -> arguments[[k]],
    "Parameters" -> arguments[[parameterPositions]],
    "ParameterPositions" -> parameterPositions, "ParameterAssumptions" -> parameterAss,
    "SourceArguments" -> sourceArguments, "ArgumentIndex" -> k, "ArgumentCount" -> n,
    "OriginalExpression" -> original, "OriginalOperator" -> operator|>];

inverseFunctionApplicationData[___] :=
  fail["InvalidArguments", "InverseFunction syntax parsing requires an expression, parameter assumptions, and MaxTerms."];
