(* Conservative arithmetic when no common ordered coefficient algebra applies.
   Each input denotes e + O(R), with R a nonnegative asymptotic envelope.
   Separate error summands are retained; cancellation of finite expressions
   does not cancel independent errors or create a single-scale precision. *)

SetAttributes[seriesEnvelopeTry, HoldAllComplete];
seriesEnvelopeTry[e_] := Quiet[TimeConstrained[e, 3, $Failed]];

seriesEnvelopeBudget[e_, limit_] := (
  If[! IntegerQ[limit] || limit < 1,
    fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[LeafCount[e] > limit,
    fail["ResourceLimit", "The composite expression and remainder exceed MaxTerms expression leaves."]]; e);

seriesEnvelopeOptions[cut_, limit_] := (
  If[! IntegerQ[limit] || limit < 1,
    fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[cut =!= Automatic,
    fail["UnsupportedCompositeCutoff", "A composite expansion retains separate error scales; an exponent cutoff requires a compatible ordered series representation."]]);

seriesEnvelopeAssociation[a_, key_] := Replace[Lookup[a, key, <||>], Except[_Association] -> <||>];

seriesEnvelopeSmallCoordinates[a_] := DeleteDuplicates[DeleteCases[
  Join[{Lookup[a, "RemainderVariable", Missing["Absent"]],
    Lookup[seriesEnvelopeAssociation[a, "SeriesRepresentation"], "ScaleVariable", Missing["Absent"]],
    Lookup[a, "CoreInverseCoordinate", Missing["Absent"]]},
    Cases[Lookup[a, "Remainder", 0], PowerLogRemainder[w_, _, _] :> w, {0, Infinity}]],
  _Missing]];

seriesEnvelopeSubstitution[approach_, u_] := Switch[approach["Point"],
  Infinity, 1/u, -Infinity, -1/u,
  _, approach["Point"] + If[approach["Direction"] === "FromAbove", u, -u]];

seriesEnvelopeTailQ[condition_, variable_, approach_, assumptions_] := Module[{u, local, ass, simple},
  u = Unique["envelopeTail$"];
  local = condition /. variable -> seriesEnvelopeSubstitution[approach, u];
  ass = assumptions /. variable -> seriesEnvelopeSubstitution[approach, u];
  simple = seriesEnvelopeTry[FullSimplify[local, ass && u > 0]];
  If[TrueQ[simple], Return[True, Module]];
  If[simple === False, Return[False, Module]];
  TrueQ[seriesEnvelopeTry[inverseFunctionEventually[local, u, ass]]]];

seriesEnvelopeLimit[e_, variable_, approach_, assumptions_, domain_: True] := Module[
  {u, substitution, simplified, direct, clauses, parameterAssumptions},
  simplified = seriesEnvelopeTry[Refine[e, assumptions && domain]];
  If[simplified === $Failed, simplified = e];
  clauses = If[Head[assumptions && domain] === And, List @@ (assumptions && domain), {assumptions && domain}];
  parameterAssumptions = And @@ Select[clauses, FreeQ[#, variable] &];
  (* Native limits of Lambert cores are substantially easier in the recorded
     target variable than after introducing a reciprocal of that variable.
     Limit ignores assumptions involving its variable; the recorded direction
     supplies that approach, while independent parameter conditions remain. *)
  direct = Quiet[TimeConstrained[Limit[simplified, variable -> approach["Point"],
    Direction -> If[MemberQ[{Infinity, -Infinity}, approach["Point"]], Automatic, approach["Direction"]],
    Assumptions -> parameterAssumptions], 10, $Failed]];
  If[direct =!= $Failed && FreeQ[direct, _Limit], Return[direct, Module]];
  u = Unique["envelopeLimit$"]; substitution = variable -> seriesEnvelopeSubstitution[approach, u];
  seriesEnvelopeTry[Limit[simplified /. substitution, u -> 0, Direction -> "FromAbove",
    Assumptions -> parameterAssumptions]]];

seriesEnvelopeApproach[a_, limit_] := Module[
  {stored, variable, point, direction = Automatic, ass, domain, coordinates, candidates,
   valid, coefficient, u, rule, endpoint, d},
  variable = Lookup[a, "Variable", Missing["Variable"]];
  If[! MatchQ[variable, _Symbol],
    fail["InvalidCompositeOperand", "A series operand must retain its target variable."]];
  stored = Lookup[a, "SeriesApproach", None];
  If[AssociationQ[stored] && Lookup[stored, "Variable", variable] === variable &&
      KeyExistsQ[stored, "Point"] && MemberQ[{"FromAbove", "FromBelow"}, Lookup[stored, "Direction", None]],
    Return[stored, Module]];
  ass = Lookup[a, "Assumptions", True];
  domain = Lookup[a, "TargetDomain", Lookup[seriesEnvelopeAssociation[a, "SeriesRepresentation"], "Domain", True]];
  coordinates = Select[seriesEnvelopeSmallCoordinates[a], ! FreeQ[#, variable] &];
  point = Which[
    KeyExistsQ[a, "InverseFunctionExpansionPoint"],
      direction = Lookup[a, "InverseFunctionExpansionDirection", Automatic]; a["InverseFunctionExpansionPoint"],
    Lookup[a, "Kind", ""] === "Forward", direction = Lookup[a, "Direction", Automatic]; a["ExpansionPoint"],
    KeyExistsQ[a, "Limit"], a["Limit"],
    AssociationQ[Lookup[a, "FlatRepresentation", None]], a["FlatRepresentation"]["TargetOffset"],
    Lookup[a, "Kind", ""] === "FlatInverse" && AssociationQ[Lookup[a, "Model", None]], a["Model"]["Offset"],
    True, Missing["UnknownEndpoint"]];
  If[MissingQ[point],
    (* Invert only a recorded independent coordinate, never the represented
       unknown function. This also recognizes reciprocal-log derived charts. *)
    Do[
      u = Unique["envelopeCoordinate$"];
      d = <|"Variable" -> variable, "ScaleVariable" -> coordinate|>;
      rule = seriesCoordinateRule[d, u];
      If[rule === $Failed, Continue[]];
      endpoint = seriesEnvelopeTry[Limit[variable /. rule, u -> 0,
        Direction -> "FromAbove", Assumptions -> ass]];
      If[MemberQ[{Infinity, -Infinity}, endpoint], point = endpoint; Break[]];
      If[endpoint === $Failed || ! FreeQ[endpoint, u | _Limit] ||
          ! TrueQ[seriesEnvelopeTry[FullSimplify[Element[endpoint, Reals], ass]]], Continue[]];
      If[TrueQ[seriesEnvelopeTry[inverseFunctionEventually[(variable /. rule) > endpoint, u, ass]]],
        point = endpoint; direction = "FromAbove"; Break[]];
      If[TrueQ[seriesEnvelopeTry[inverseFunctionEventually[(variable /. rule) < endpoint, u, ass]]],
        point = endpoint; direction = "FromBelow"; Break[]], {coordinate, coordinates}]];
  If[MissingQ[point],
    fail["UnknownCompositeApproach", "The operand does not retain a recoverable target approach."]];
  If[MemberQ[{Infinity, -Infinity}, point],
    direction = If[point === Infinity, "FromBelow", "FromAbove"]];
  If[direction === Automatic,
    coefficient = Lookup[a, "TargetScale", Lookup[a, "LeadingCoefficient",
      Lookup[seriesEnvelopeAssociation[a, "FlatRepresentation"], "CoreCoefficient",
        Lookup[seriesEnvelopeAssociation[a, "Model"], "CoreCoefficient", Missing["Coefficient"]]]]];
    If[! MissingQ[coefficient],
      If[TrueQ[seriesEnvelopeTry[FullSimplify[coefficient > 0, ass]]], direction = "FromAbove"];
      If[TrueQ[seriesEnvelopeTry[FullSimplify[coefficient < 0, ass]]], direction = "FromBelow"]]];
  If[direction === Automatic,
    candidates = (<|"Variable" -> variable, "Point" -> point, "Direction" -> #|> &) /@
      {"FromAbove", "FromBelow"};
    valid = Select[candidates, Function[candidate,
      seriesEnvelopeTailQ[domain && And @@ (# > 0 & /@ coordinates), variable, candidate, ass] &&
        AllTrue[coordinates, seriesEnvelopeLimit[#, variable, candidate, ass, domain] === 0 &]]];
    If[Length[valid] =!= 1,
      fail["UnknownCompositeApproach", "The target side could not be recovered uniquely from the operand's domain and positive coordinates."]];
    direction = First[valid]["Direction"]];
  If[! MemberQ[{"FromAbove", "FromBelow"}, direction],
    fail["InvalidCompositeApproach", "The retained target approach is not a supported real one-sided approach."]];
  <|"Variable" -> variable, "Point" -> point, "Direction" -> direction|>];

(* Each summand is a nonnegative coefficient times a product of inert O terms.
   Multiplication combines only literally identical positive coordinates. *)
seriesEnvelopeErrorTerm[term_] := Module[{factors, errors, ordinary, groups},
  factors = If[Head[term] === Times, List @@ term, {term}];
  factors = factors /. HoldPattern[Power[PowerLogRemainder[w_, p_, k_], n_Integer?Positive]] :>
    PowerLogRemainder[w, n p, n k];
  errors = Select[factors, MatchQ[#, PowerLogRemainder[_, _, _]] &];
  ordinary = Select[factors, FreeQ[#, _PowerLogRemainder] &];
  If[Length[errors] + Length[ordinary] =!= Length[factors] || errors === {},
    fail["UnsupportedCompositeRemainder", "A nonzero remainder must be a sum of exact coefficients times inert power-log remainder factors."]];
  groups = GatherBy[errors, First];
  Abs[Times @@ ordinary] Times @@ (PowerLogRemainder[#[[1, 1]], Total[#[[All, 2]]],
      Total[#[[All, 3]]]] & /@ groups)];

seriesEnvelopeErrorExpansionSize[e_, limit_] := Module[{sizes, size, power},
  If[FreeQ[e, _PowerLogRemainder], Return[1, Module]];
  Which[Head[e] === Plus,
    Min[limit + 1, Total[seriesEnvelopeErrorExpansionSize[#, limit] & /@ List @@ e]],
    Head[e] === Times,
    sizes = seriesEnvelopeErrorExpansionSize[#, limit] & /@ List @@ e;
    Fold[Min[limit + 1, #1 #2] &, 1, sizes],
    Head[e] === Power && IntegerQ[e[[2]]] && e[[2]] > 0,
    size = seriesEnvelopeErrorExpansionSize[e[[1]], limit]; power = e[[2]];
    If[size <= 1, 1, If[power > IntegerLength[limit, 2], limit + 1, Min[limit + 1, size^power]]],
    True, 1]];

seriesEnvelopeErrorNormalize[remainder_, limit_] := Module[{expanded, terms},
  If[remainder === 0, Return[0, Module]];
  seriesEnvelopeBudget[remainder, limit];
  If[seriesEnvelopeErrorExpansionSize[remainder, limit] > limit,
    fail["ResourceLimit", "The composite remainder product exceeds MaxTerms distributed error summands."]];
  (* Treat ordinary coefficients as exact atoms. Only distribute factors
     containing the inert remainder head. *)
  expanded = seriesEnvelopeTry[Expand[remainder, _PowerLogRemainder]];
  If[expanded === $Failed,
    fail["ResourceLimit", "Normalizing the composite error product exceeded the symbolic time budget."]];
  seriesEnvelopeBudget[expanded, limit];
  terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  Total[seriesEnvelopeErrorTerm /@ terms]];

seriesEnvelopeData[s : GeneralizedSeries[a_Association], limit_] := Module[{expression, remainder, bound, assumptions, domain, approach},
  If[! KeyExistsQ[a, "Expression"] || ! KeyExistsQ[a, "Remainder"],
    fail["InvalidCompositeOperand", "A series operand must retain both its finite expression and its remainder."]];
  expression = a["Expression"]; remainder = a["Remainder"];
  validateInput[{expression, remainder}, limit];
  seriesEnvelopeBudget[{expression, remainder}, limit];
  If[! FreeQ[{expression, remainder}, _GeneralizedSeries],
    fail["InvalidCompositeOperand", "Normalize nested series operands before constructing a composite envelope."]];
  remainder = seriesEnvelopeErrorNormalize[remainder, limit];
  bound = remainder /. rr_PowerLogRemainder :> remainderScale[rr];
  assumptions = Lookup[a, "Assumptions", True];
  domain = Lookup[a, "TargetDomain", Lookup[seriesEnvelopeAssociation[a, "SeriesRepresentation"], "Domain", True]];
  If[seriesEnvelopeTry[FullSimplify[assumptions && domain]] === False,
    fail["IncompatibleDomains", "The series operand has a contradictory target domain."]];
  approach = seriesEnvelopeApproach[a, limit];
  <|"Expression" -> expression, "Remainder" -> remainder, "Bound" -> bound,
    "Variable" -> a["Variable"], "Assumptions" -> assumptions, "Domain" -> domain,
    "Approach" -> approach|>];

seriesEnvelopeMake[expression_, remainder0_, data_, recipe_, limit_] := Module[{remainder, bound, domain},
  remainder = seriesEnvelopeErrorNormalize[remainder0, limit];
  bound = remainder /. rr_PowerLogRemainder :> remainderScale[rr];
  domain = data["Domain"];
  validateInput[{expression, remainder, bound}, limit];
  seriesEnvelopeBudget[{expression, remainder, bound}, limit];
  GeneralizedSeries[<|"Kind" -> "Derived", "Scale" -> "Composite",
    "Expression" -> expression, "Remainder" -> remainder, "RemainderScaleExpression" -> bound,
    "Variable" -> data["Variable"], "Assumptions" -> data["Assumptions"],
    "TargetDomain" -> domain, "SeriesApproach" -> data["Approach"],
    "Exact" -> (remainder === 0), "RemainderDerivativeOrder" -> If[remainder === 0, Infinity, 0],
    "CompositeRecipe" -> recipe,
    "MajorantContract" -> <|"Type" -> "CompositeAsymptoticEnvelope", "NumericCertificate" -> False,
      "Statement" -> "For fixed data on the retained common target approach, the exact represented function differs from Expression by O(RemainderScaleExpression). Separate error summands are preserved; cancellation of finite expressions does not cancel unknown errors."|>,
    "TermConvention" -> "The finite expression is retained exactly and the remainder is a sum of envelopes in possibly different positive coordinates; no single exponent cutoff is asserted.",
    "SeriesData" -> Missing["CompositeErrorScales"]|>]];

seriesEnvelopeBinary[op_String, s_GeneralizedSeries, t_, cut_, limit_] := Module[
  {a, b, assumptions, domain, expression, remainder, exact = t, condition = True, compatible},
  seriesEnvelopeOptions[cut, limit];
  If[! MemberQ[{"Add", "Multiply"}, op],
    fail["UnsupportedCompositeOperation", "Composite binary arithmetic supports addition and multiplication."]];
  a = seriesEnvelopeData[s, limit];
  If[MatchQ[t, _GeneralizedSeries],
    b = seriesEnvelopeData[t, limit];
    assumptions = a["Assumptions"] && b["Assumptions"];
    compatible = a["Variable"] === b["Variable"] &&
      a["Approach"]["Direction"] === b["Approach"]["Direction"] &&
      (a["Approach"]["Point"] === b["Approach"]["Point"] ||
       TrueQ[seriesEnvelopeTry[FullSimplify[a["Approach"]["Point"] == b["Approach"]["Point"], assumptions]]]);
    If[! TrueQ[compatible],
      fail["IncompatibleApproaches", "Composite arithmetic requires the same target variable, endpoint, and real approach side."]];
    domain = a["Domain"] && b["Domain"],
    If[! FreeQ[t, _GeneralizedSeries],
      fail["UnsupportedCompositeOperand", "Normalize nested series before combining them with another series."]];
    While[Head[exact] === ConditionalExpression, condition = condition && exact[[2]]; exact = exact[[1]]];
    validateInput[exact, limit]; seriesEnvelopeBudget[exact, limit];
    assumptions = a["Assumptions"]; domain = a["Domain"] && condition;
    If[! seriesEnvelopeTailQ[condition && Element[exact, Reals], a["Variable"], a["Approach"],
        assumptions && a["Domain"]],
      fail["UnprovedRealCoefficient", "The ordinary operand must be exact and eventually real on the series target approach."]];
    b = <|"Expression" -> exact, "Remainder" -> 0|>];
  If[seriesEnvelopeTry[FullSimplify[assumptions && domain]] === False,
    fail["IncompatibleDomains", "The series operands have incompatible target domains."]];
  If[op === "Add",
    expression = a["Expression"] + b["Expression"];
    remainder = a["Remainder"] + b["Remainder"],
    expression = a["Expression"] b["Expression"];
    remainder = Abs[a["Expression"]] b["Remainder"] +
      Abs[b["Expression"]] a["Remainder"] + a["Remainder"] b["Remainder"]];
  seriesEnvelopeMake[expression, remainder,
    Join[a, <|"Assumptions" -> assumptions, "Domain" -> domain|>],
    <|"Operation" -> op, "Operands" -> {s, t}|>, limit]];

seriesEnvelopePower[s_GeneralizedSeries, r_, cut_, limit_] := Module[
  {a, expression, remainder, domain, nonzero, positive, relative, result},
  seriesEnvelopeOptions[cut, limit];
  If[! exactRealQ[r], fail["InvalidPower", "A composite series power must be an exact real number."]];
  If[r === 1, Return[s, Module]];
  a = seriesEnvelopeData[s, limit]; expression = a["Expression"]; domain = a["Domain"];
  (* Polynomial powers need no nonvanishing or relative-error hypothesis.
     This also admits positive integer powers of a pure remainder. *)
  If[IntegerQ[r] && r > 0,
    If[r > limit, fail["ResourceLimit", "The composite polynomial power exceeds MaxTerms."]];
    remainder = If[a["Remainder"] === 0, 0,
      Total[Table[Binomial[r, k] If[k === r, 1, Abs[expression]^(r - k)] a["Remainder"]^k, {k, 1, r}]]];
    Return[seriesEnvelopeMake[expression^r, remainder, a,
      <|"Operation" -> "Power", "Operands" -> {s}, "Exponent" -> r|>, limit], Module]];
  If[expression === 0,
    If[a["Remainder"] === 0 && TrueQ[r > 0],
      Return[seriesEnvelopeMake[0, 0, a,
        <|"Operation" -> "Power", "Operands" -> {s}, "Exponent" -> r|>, limit], Module]];
    fail["UnknownLeadingTerm", "This power requires a proved nonzero leading approximation; a pure remainder cannot supply it."]];
  nonzero = seriesEnvelopeTailQ[Element[expression, Reals] && expression != 0,
    a["Variable"], a["Approach"], a["Assumptions"] && domain];
  If[! nonzero,
    fail["UnprovedNonzeroBase", "The finite approximation must be eventually real and nonzero before this power can transport its error."]];
  positive = IntegerQ[r] || seriesEnvelopeTailQ[expression > 0,
    a["Variable"], a["Approach"], a["Assumptions"] && domain];
  If[! positive,
    fail["NonpositiveBase", "A noninteger composite power requires an eventually positive real approximation."]];
  relative = If[a["Remainder"] === 0, 0,
    seriesEnvelopeLimit[a["Bound"]/Abs[expression], a["Variable"], a["Approach"], a["Assumptions"], domain]];
  If[relative =!= 0,
    fail["InsufficientRelativePrecision", "This power requires a remainder proved smaller than the finite approximation on the retained target approach."]];
  domain = domain && If[IntegerQ[r], expression != 0, expression > 0];
  remainder = If[r === 0, 0, Abs[expression]^(r - 1) a["Remainder"]];
  result = If[r === 0, 1, expression^r];
  seriesEnvelopeMake[result, remainder, Join[a, <|"Domain" -> domain|>],
    <|"Operation" -> "Power", "Operands" -> {s}, "Exponent" -> r,
      "RelativeRemainderLimit" -> 0|>, limit]];

(* These bounds use only the stated scalar inequalities, not an unproved
   Taylor expansion of a multiscale remainder. Abs, Sin and Cos are globally
   1-Lipschitz on the real line. Log requires relative smallness, whereas
   Exp requires absolute smallness of the unknown perturbation. *)
seriesEnvelopeUnary[head_, s_GeneralizedSeries, cut_, limit_] := Module[
  {a, expression, domain, remainder, boundLimit, transport, evidence = <||>},
  seriesEnvelopeOptions[cut, limit];
  If[! MemberQ[{Log, Exp, Abs, Sin, Cos}, head],
    fail["UnsupportedCompositeObservable", "Composite unary bounds support Log, Exp, Abs, Sin and Cos on their proved real domains."]];
  a = seriesEnvelopeData[s, limit]; expression = a["Expression"]; domain = a["Domain"];
  If[head === Log,
    If[! seriesEnvelopeTailQ[expression > 0, a["Variable"], a["Approach"], a["Assumptions"] && domain],
      fail["NonpositiveBase", "A real logarithm of a composite expansion requires an eventually positive finite approximation."]],
    If[! seriesEnvelopeTailQ[Element[expression, Reals], a["Variable"], a["Approach"], a["Assumptions"] && domain],
      fail["UnprovedRealCoefficient", "This composite observable requires an eventually real finite approximation."]]];
  Switch[head,
    Log,
      domain = domain && expression > 0;
      boundLimit = If[a["Remainder"] === 0, 0,
        seriesEnvelopeLimit[a["Bound"]/expression, a["Variable"], a["Approach"], a["Assumptions"], domain]];
      If[boundLimit =!= 0,
        fail["InsufficientRelativePrecision", "Taking this logarithm requires a remainder proved smaller than the positive finite approximation."]];
      remainder = a["Remainder"]/Abs[expression];
      transport = "For a positive e and R/e tending to zero, Log[e+O(R)] = Log[e] + O(R/e).";
      evidence = <|"RelativeRemainderLimit" -> 0|>,
    Exp,
      boundLimit = If[a["Remainder"] === 0, 0,
        seriesEnvelopeLimit[a["Bound"], a["Variable"], a["Approach"], a["Assumptions"], domain]];
      If[boundLimit =!= 0,
        fail["InsufficientObservablePrecision", "Exponentiating a composite expansion requires an absolute remainder proved to tend to zero."]];
      remainder = Exp[expression] a["Remainder"];
      transport = "For real e and R tending to zero, Exp[e+O(R)] = Exp[e] + Exp[e] O(R).";
      evidence = <|"AbsoluteRemainderLimit" -> 0|>,
    Abs | Sin | Cos,
      remainder = a["Remainder"];
      transport = "The real scalar function is globally 1-Lipschitz, so its output error is O(R) without a smallness or nonvanishing hypothesis.";
      evidence = <|"LipschitzConstant" -> 1|>];
  seriesEnvelopeMake[head[expression], remainder, Join[a, <|"Domain" -> domain|>],
    Join[<|"Operation" -> "Unary", "FunctionHead" -> head, "Operands" -> {s},
      "ErrorTransport" -> transport|>, evidence], limit]];
