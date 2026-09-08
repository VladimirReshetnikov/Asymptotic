If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

callableExpansionEqual[s_, expected_, ass_: True] :=
  MatchQ[s, _PowerLogSeries] && TrueQ[FullSimplify[Normal[s] == expected, ass]];

(* Independent infinity oracle for t+t^Sqrt[2]=y. Set p=1/Sqrt[2],
   t=y^p z and epsilon=y^(p-1). Then z^Sqrt[2]+epsilon z=1.
   Coefficient comparison, equivalently Lagrange inversion of
   epsilon z=epsilon (1-epsilon z)^p, gives
   [epsilon^n]z=(-1)^n Binomial[(n+1)p,n]/(n+1).
   The next omitted term after five blocks has local power 5-6p. *)
callableExpansionInfinityOracle[y_, count_Integer] := Module[{p = 1/Sqrt[2], c},
  c = {1, -p, p (3 p - 1)/2, -p (4 p - 1) (4 p - 2)/6,
    p (5 p - 1) (5 p - 2) (5 p - 3)/24};
  Sum[c[[n + 1]] y^(p + n (p - 1)), {n, 0, count - 1}]];

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[InverseFunction[
    x |-> ConditionalExpression[x + x^Sqrt[2], x > 0]],
    x -> Infinity, SeriesTermGoal -> 5];
  {callableExpansionEqual[s, callableExpansionInfinityOracle[x, 5], x > 0],
    Length[s["Terms"]], TrueQ[FullSimplify[s["RemainderPower"] == 5 - 3 Sqrt[2]]],
    s["RemainderLogDegree"], s["RemainderVariable"] === 1/x,
    s["Variable"] === x, s["ExpansionPoint"],
    s["InverseFunctionBranch"]["ConditionalDomainVerified"],
    InverseResidual[s]["ZeroBelowCutoff"]}],
  {True, 5, True, 0, True, True, Infinity, True, True},
  TestID -> "callable-expansion-user-irrational-inverse-rule-five-block-oracle"]

VerificationTest[Module[{t, x, s},
  s = AsymptoticExpansion[InverseFunction[
    Function[t, ConditionalExpression[t + t^Sqrt[2], t > 0]]],
    {x, Infinity}, SeriesTermGoal -> 5];
  {callableExpansionEqual[s, callableExpansionInfinityOracle[x, 5], x > 0],
    FreeQ[Normal[s], t], Length[s["Terms"]]}],
  {True, True, 5}, TestID -> "callable-expansion-list-form-keeps-source-binding-local"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[InverseFunction[
    ConditionalExpression[# + #^Sqrt[2], # > 0] &], {x, Infinity, 0}];
  {callableExpansionEqual[s, callableExpansionInfinityOracle[x, 3], x > 0],
    Length[s["Terms"]], TrueQ[FullSimplify[s["RemainderPower"] == 3 - 2 Sqrt[2]]]}],
  {True, 3, True}, TestID -> "callable-expansion-slot-inverse-honors-explicit-local-cutoff"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Function[x, Abs[x]], x -> 0,
    Direction -> "FromBelow", SeriesTermGoal -> 2];
  {callableExpansionEqual[s, -x, x < 0], s["Remainder"], s["Direction"]}],
  {True, 0, "FromBelow"}, TestID -> "callable-expansion-named-function-same-symbol-left-direction"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Sin[#] &, {x, 0}, SeriesTermGoal -> 3];
  {callableExpansionEqual[s, x - x^3/6 + x^5/120], s["RemainderPower"]}],
  {True, 7}, TestID -> "callable-expansion-slot-function-counts-nonzero-blocks"]

VerificationTest[Module[{t, x, s},
  s = AsymptoticExpansion[Function[{t}, Exp[t]], {x, 0, 4}];
  {callableExpansionEqual[s, 1 + x + x^2/2 + x^3/6], s["RemainderPower"]}],
  {True, 4}, TestID -> "callable-expansion-named-parameter-list-explicit-cutoff"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[InverseFunction[Exp], x -> Infinity, SeriesTermGoal -> 5];
  {callableExpansionEqual[s, Log[x], x > 0], s["Remainder"], Length[s["Terms"]]}],
  {True, 0, 1}, TestID -> "callable-expansion-native-simplified-inverse-remains-callable-rule"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[InverseFunction[Exp], {x, 1, 3}];
  {callableExpansionEqual[s, (x - 1) - (x - 1)^2/2], s["RemainderPower"]}],
  {True, 3}, TestID -> "callable-expansion-native-simplified-inverse-list-finite-point"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Sin[x], x -> 0, SeriesTermGoal -> 2];
  {callableExpansionEqual[s, x - x^3/6], s["RemainderPower"]}],
  {True, 5}, TestID -> "callable-expansion-rule-also-accepts-ordinary-expressions"]

VerificationTest[Module[{a, t, x, s, rules},
  rules = {Assumptions -> a > 0, Direction -> "FromBelow", SeriesTermGoal -> 2};
  s = AsymptoticExpansion[Function[t, Abs[a t]], x -> 0, Sequence @@ rules];
  {callableExpansionEqual[s, -a x, a > 0 && x < 0], s["Remainder"],
    s["Assumptions"] === (a > 0)}],
  {True, 0, True}, TestID -> "callable-expansion-forwards-parameter-assumptions-and-option-sequence"]

VerificationTest[Module[{x, s, refined, source, refinedSource},
  s = AsymptoticExpansion[InverseFunction[ConditionalExpression[
    # + #^2 (1 + Log[#]), 0 < # < 1] &], {x, 0, 3}];
  refined = SeriesRefine[s, 4];
  source = s["SourceVariable"]; refinedSource = refined["SourceVariable"];
  {callableExpansionEqual[refined,
      x - x^2 (1 + Log[x]) + x^3 (2 Log[x]^2 + 5 Log[x] + 3), x > 0],
    TrueQ[s["SourceDomain"] /. source -> 1/2],
    TrueQ[(s["SourceDomain"] /. source -> 2) === False],
    TrueQ[(refined["SourceDomain"] /. refinedSource -> 2) === False],
    refined["RemainderPower"]}],
  {True, True, True, True, 4}, TestID -> "callable-expansion-refinement-retains-source-condition"]

VerificationTest[Module[{x}, FailureQ[AsymptoticExpansion[InverseFunction[
    ConditionalExpression[# + #^Sqrt[2], 0 < # < 1] &],
    x -> Infinity, SeriesTermGoal -> 5]]],
  True, TestID -> "callable-expansion-rejects-source-domain-without-infinite-branch"]

VerificationTest[Module[{f, x}, Quiet[MatchQ[AsymptoticExpansion[
    InverseFunction[f, 2, 2], x -> 0, SeriesTermGoal -> 3],
    Failure["InverseFunctionArity", _Association]]]],
  True, TestID -> "callable-expansion-rejects-unapplied-multiargument-inverse"]

VerificationTest[Module[{t, u, x},
  {MatchQ[AsymptoticExpansion[Function[{t, u}, t + u], {x, 0, 3}],
     Failure["CallableArity", _Association]],
   MatchQ[AsymptoticExpansion[#1 + #2 &, x -> 0, SeriesTermGoal -> 2],
     Failure["CallableArity", _Association]]}],
  {True, True}, TestID -> "callable-expansion-rejects-multiargument-pure-functions"]

VerificationTest[Module[{a, t, f, g, x, constant, forward, inverse},
  f = Function[t, Exp[t]];
  g = InverseFunction[ConditionalExpression[# + #^Sqrt[2], # > 0] &];
  constant = AsymptoticExpansion[a, x -> 0, SeriesTermGoal -> 3,
    Assumptions -> Element[a, Reals]];
  forward = AsymptoticExpansion[f, {x, 0, 3}];
  inverse = AsymptoticExpansion[g, {x, Infinity, 0}];
  {callableExpansionEqual[constant, a], constant["Remainder"],
    callableExpansionEqual[forward, 1 + x + x^2/2],
    callableExpansionEqual[inverse, callableExpansionInfinityOracle[x, 3], x > 0]}],
  {True, 0, True, True},
  TestID -> "callable-expansion-resolves-assigned-callables-preserving-scalar-symbols"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[ConditionalExpression[Sin[#] &, x > 0],
    x -> 0, SeriesTermGoal -> 2];
  {callableExpansionEqual[s, x - x^3/6, x > 0], s["RemainderPower"]}],
  {True, 5}, TestID -> "callable-expansion-outer-target-condition-wraps-callable"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[ConditionalExpression[InverseFunction[Exp], x > 1],
    {x, 1, 3}];
  {callableExpansionEqual[s, (x - 1) - (x - 1)^2/2, x > 1],
    s["RemainderPower"],
    MatchQ[AsymptoticExpansion[ConditionalExpression[InverseFunction[Exp], x < 1],
      {x, 1, 3}], Failure["IncompatibleTargetCondition", _Association]]}],
  {True, 3, True}, TestID -> "callable-expansion-conditional-native-inverse-preserves-syntax-and-domain"]
