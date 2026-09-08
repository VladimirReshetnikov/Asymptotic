If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];
If[DownValues[AsymptoticInverse`Private`inverseFunctionApplicationData] === {},
  Block[{$Context = "AsymptoticInverse`Private`", $ContextPath = {"AsymptoticInverse`", "System`"}},
    Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "InverseFunctionSyntax.wl"}]]]];

inverseSyntaxData[e_, ass_: True, limit_: 20000] :=
  AsymptoticInverse`Private`catch[
    AsymptoticInverse`Private`inverseFunctionApplicationData[e, ass, limit]];

VerificationTest[Module[{f, y},
  {AsymptoticInverse`Private`inverseFunctionApplicationQ[InverseFunction[f][y]],
    AsymptoticInverse`Private`inverseFunctionApplicationQ[InverseFunction[f]],
    AsymptoticInverse`Private`inverseFunctionApplicationQ[Inactive[InverseFunction][f][y]],
    inverseSyntaxData[Sin[y]]}],
  {True, False, False, $Failed}, TestID -> "inverse-syntax-recognizes-only-applied-active-operators"]

VerificationTest[Module[{f, y, z, e}, e = InverseFunction[f][y][z];
  Length[Cases[e, q_?AsymptoticInverse`Private`inverseFunctionApplicationQ :> q,
    {0, Infinity}, Heads -> True]] === 1],
  True,
  TestID -> "inverse-syntax-head-aware-traversal-finds-inverse-application"]

VerificationTest[Module[{f, y, a}, a = inverseSyntaxData[InverseFunction[f][y]];
  {a["Body"] === f[a["SourceVariable"]], a["TargetExpression"] === y,
    a["Condition"], a["Parameters"], a["ParameterPositions"],
    a["ArgumentIndex"], a["ArgumentCount"],
    a["OriginalExpression"] === InverseFunction[f][y],
    a["OriginalOperator"] === InverseFunction[f]}],
  {True, True, True, {}, {}, 1, 1, True, True}, TestID -> "inverse-syntax-preserves-undefined-symbol-and-provenance"]

VerificationTest[Module[{t, y, a},
  a = inverseSyntaxData[InverseFunction[Function[t, Sin[t] - t]][y]];
  Expand[a["Body"] - (Sin[a["SourceVariable"]] - a["SourceVariable"]) ]],
  0, TestID -> "inverse-syntax-applies-named-single-parameter-function"]

VerificationTest[Module[{t, y, a},
  a = inverseSyntaxData[InverseFunction[Function[{t}, Sin[t] - t]][y]];
  Expand[a["Body"] - (Sin[a["SourceVariable"]] - a["SourceVariable"]) ]],
  0, TestID -> "inverse-syntax-applies-named-parameter-list-function"]

VerificationTest[Module[{y, a},
  a = inverseSyntaxData[InverseFunction[Sin[#] - # &][y]];
  Expand[a["Body"] - (Sin[a["SourceVariable"]] - a["SourceVariable"]) ]],
  0, TestID -> "inverse-syntax-applies-slot-function"]

VerificationTest[Module[{t, y, a},
  a = Block[{t = 17}, inverseSyntaxData[InverseFunction[Function[t, Sin[t] - t]][y]]];
  Expand[a["Body"] - (Sin[a["SourceVariable"]] - a["SourceVariable"]) ]],
  0, TestID -> "inverse-syntax-does-not-evaluate-formal-parameter-ownvalue"]

VerificationTest[Module[{t, y, a},
  a = inverseSyntaxData[InverseFunction[Function[t, t + Function[t, t^2 Log[t]][t]]][y]];
  Expand[a["Body"] - (a["SourceVariable"] + a["SourceVariable"]^2 Log[a["SourceVariable"]])]],
  0, TestID -> "inverse-syntax-respects-shadowed-nested-named-function"]

VerificationTest[Module[{y, a},
  a = inverseSyntaxData[InverseFunction[Function[# + (#^2 Log[#] &)[#]]][y]];
  Expand[a["Body"] - (a["SourceVariable"] + a["SourceVariable"]^2 Log[a["SourceVariable"]])]],
  0, TestID -> "inverse-syntax-respects-nested-slot-binding"]

VerificationTest[Module[{f, t, y, a}, f[t_] := Sin[t] - t;
  a = inverseSyntaxData[InverseFunction[f][y]];
  Expand[a["Body"] - (Sin[a["SourceVariable"]] - a["SourceVariable"]) ]],
  0, TestID -> "inverse-syntax-applies-symbol-downvalues"]

VerificationTest[Module[{y, a}, a = inverseSyntaxData[InverseFunction[AiryAi][y]];
  a["Body"] === AiryAi[a["SourceVariable"]]],
  True, TestID -> "inverse-syntax-applies-surviving-built-in-function-head"]

VerificationTest[Module[{f, a, b, y, d},
  d = inverseSyntaxData[InverseFunction[f, 2, 3][a, y, b], a > 0];
  {d["Body"] === f[a, d["SourceVariable"], b], d["TargetExpression"] === y,
    d["Parameters"] === {a, b}, d["ParameterPositions"], d["ParameterAssumptions"] === (a > 0)}],
  {True, True, True, {1, 3}, True}, TestID -> "inverse-syntax-selected-target-stays-in-selected-argument-slot"]

VerificationTest[Module[{a, t, b, y, d, v},
  d = inverseSyntaxData[InverseFunction[Function[{a, t, b}, a + Sin[t] - t + b], 2, 3][2, y, 3]];
  v = d["SourceVariable"];
  {Expand[d["Body"] - (5 + Sin[v] - v)], d["TargetExpression"] === y, d["Parameters"]}],
  {0, True, {2, 3}}, TestID -> "inverse-syntax-freezes-named-multivariate-parameters"]

VerificationTest[Module[{a, y, d, v},
  d = inverseSyntaxData[InverseFunction[#1 + Sin[#2] - #2 &, 2, 2][a, y]];
  v = d["SourceVariable"];
  {Expand[d["Body"] - (a + Sin[v] - v)], d["TargetExpression"] === y, d["Parameters"] === {a}}],
  {0, True, True}, TestID -> "inverse-syntax-freezes-slot-multivariate-parameters"]

VerificationTest[Module[{a, y, d, v},
  d = inverseSyntaxData[InverseFunction[ConditionalExpression[
      ConditionalExpression[Sin[#] - #, # > 0], a > 0] &][y], Element[a, Reals]];
  v = d["SourceVariable"];
  {Expand[d["Body"] - (Sin[v] - v)], TrueQ[FullSimplify[Equivalent[d["Condition"], v > 0 && a > 0]]]}],
  {0, True}, TestID -> "inverse-syntax-extracts-nested-forward-domain-conditions"]

VerificationTest[Module[{y, d, v},
  d = inverseSyntaxData[InverseFunction[
      ConditionalExpression[Sin[#], # > 0] - ConditionalExpression[#, # < 1] &][y]];
  v = d["SourceVariable"];
  {Expand[d["Body"] - (Sin[v] - v)], TrueQ[FullSimplify[Equivalent[d["Condition"], 0 < v < 1]]]}],
  {0, True}, TestID -> "inverse-syntax-conjoins-conditions-from-mathematical-subexpressions"]

VerificationTest[Module[{f, y, first, second},
  first = inverseSyntaxData[InverseFunction[f][y]]; second = inverseSyntaxData[InverseFunction[f][y]];
  first["SourceVariable"] =!= second["SourceVariable"]],
  True, TestID -> "inverse-syntax-allocates-fresh-source-for-each-application"]

VerificationTest[Module[{f, y},
  {InverseFunction[InverseFunction[f]][y] === f[y],
    AsymptoticInverse`Private`inverseFunctionApplicationQ[InverseFunction[Exp][y]]}],
  {True, False}, TestID -> "inverse-syntax-leaves-native-simplification-on-ordinary-expression-route"]

VerificationTest[Module[{f, y}, Quiet[
  MatchQ[inverseSyntaxData[InverseFunction[f, 1, 2][y]], Failure["InverseFunctionArity", _Association]]]],
  True, TestID -> "inverse-syntax-rejects-inverse-application-arity-mismatch"]

VerificationTest[Module[{f, a, y}, Quiet[
  MatchQ[inverseSyntaxData[InverseFunction[f, 0, 2][a, y]], Failure["InverseFunctionArity", _Association]]]],
  True, TestID -> "inverse-syntax-rejects-invalid-selected-argument"]

VerificationTest[Module[{f, y}, Quiet[
  MatchQ[inverseSyntaxData[InverseFunction[f, 1][y]], Failure["MalformedInverseFunction", _Association]]]],
  True, TestID -> "inverse-syntax-rejects-malformed-operator-arity"]

VerificationTest[Module[{t}, MatchQ[AsymptoticInverse`Private`catch[
  AsymptoticInverse`Private`inverseFunctionCallableArity[Function[{t}, Sin[t] - t], 2]],
  Failure["InverseFunctionArity", _Association]]],
  True, TestID -> "inverse-syntax-validates-named-function-arity-before-application"]

VerificationTest[Module[{f, y}, MatchQ[inverseSyntaxData[InverseFunction[f][y], True, 1],
  Failure["ResourceLimit", _Association]]],
  True, TestID -> "inverse-syntax-enforces-expression-size-budget"]

VerificationTest[Module[{x}, MatchQ[AsymptoticInverse`Private`catch[
  AsymptoticInverse`Private`inverseFunctionConditions[Hold[ConditionalExpression[x, x > 0]], 100]],
  Failure["ScopedInverseCondition", _Association]]],
  True, TestID -> "inverse-syntax-does-not-hoist-a-held-condition"]

VerificationTest[Module[{x, t}, MatchQ[AsymptoticInverse`Private`catch[
  AsymptoticInverse`Private`inverseFunctionConditions[
    Function[t, ConditionalExpression[x + t, t > 0]], 100]],
  Failure["ScopedInverseCondition", _Association]]],
  True, TestID -> "inverse-syntax-does-not-hoist-a-bound-variable-condition"]

VerificationTest[MatchQ[AsymptoticInverse`Private`catch[
  AsymptoticInverse`Private`inverseFunctionApplicationData[]], Failure["InvalidArguments", _Association]],
  True, TestID -> "inverse-syntax-malformed-helper-call-fails-descriptively"]
