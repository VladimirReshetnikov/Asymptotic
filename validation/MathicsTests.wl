(* Portable exact regressions. Run through run_mathics_tests.py; it selects
   one test in each fresh kernel and enforces a process timeout. The expected
   coefficients are independent low-order oracles from src/Tests/*.wlt.
   No TestReport, VerificationTest, or JSON Export implementation is needed. *)
portableSource = Environment["ASYMPTOTIC_PORTABLE_SOURCE"];
portableSelection = Environment["ASYMPTOTIC_PORTABLE_CASE"];
If[! StringQ[portableSource] || ! StringQ[portableSelection], Exit[2]];
Print["ASYMPTOTIC_PORTABLE_KERNEL\t", $Version];
(* Mathics counts every nonliteral OwnValue substitution against the current
   input's iteration budget. Complex finite package requests need a larger
   session budget than its default 4096. This is an explicit test environment
   setting, not a package side effect; MaxTerms and OS timeouts still apply. *)
If[StringContainsQ[$Version, "Mathics"], $IterationLimit = 1000000];
Print["ASYMPTOTIC_PORTABLE_ITERATION_LIMIT\t", $IterationLimit];
portableLoadResult = CheckAbort[Check[Get[portableSource], $Failed], $Aborted];
(* Every selection requires a completed package load, including primitive
   cases that could otherwise pass using only interpreter builtins. Keep
   this check in a separate input from Get for Mathics Check semantics. *)
If[portableLoadResult === $Failed || portableLoadResult === $Aborted ||
    ! MemberQ[$Packages, "AsymptoticAnalysis`"] ||
    ! MemberQ[$ContextPath, "AsymptoticAnalysis`"] || $Context =!= "Global`" ||
    Length[DownValues[AsymptoticAnalysis`AsymptoticInverse]] === 0 ||
    Length[DownValues[AsymptoticAnalysis`AsymptoticExpansion]] === 0 ||
    Length[SubValues[AsymptoticAnalysis`GeneralizedSeries]] === 0,
  Print["ASYMPTOTIC_PORTABLE_LOAD_FAILED"];
  Exit[2]];

SetAttributes[portableTest, HoldAll];
portableTest[id_String, group_String, actual_, expected_] :=
  If[id === portableSelection, Module[{a, e, success},
    (* Mathics 10's two-argument Check mistakes any earlier Print in the
       current evaluation for a message. Emit diagnostics only after the
       assertion has evaluated; Python supplies progress before each case. *)
    a = actual; e = expected; success = SameQ[a, e];
    Print["ASYMPTOTIC_PORTABLE_ACTUAL_BEGIN"];
    Print[ToString[a, InputForm]];
    Print["ASYMPTOTIC_PORTABLE_ACTUAL_END"];
    Print["ASYMPTOTIC_PORTABLE_EXPECTED_BEGIN"];
    Print[ToString[e, InputForm]];
    Print["ASYMPTOTIC_PORTABLE_EXPECTED_END"];
    Print["ASYMPTOTIC_PORTABLE_RESULT\t", id, "\t", If[success, "Success", "Failure"]];
    Exit[If[success, 0, 1]]
  ]];

(* The compatibility helpers are private to package source evaluation. Test
   them explicitly on Mathics and the unchanged System functions on Wolfram,
   without exposing the compatibility context to subsequent user input. *)
portablePrimitive[held_HoldComplete] := ReleaseHold[
  If[StringContainsQ[$Version, "Mathics"], held /. {
      System`Module -> AsymptoticAnalysis`Mathics`Module,
      System`Return -> AsymptoticAnalysis`Mathics`Return,
      System`Lookup -> AsymptoticAnalysis`Mathics`Lookup,
      System`AssociateTo -> AsymptoticAnalysis`Mathics`AssociateTo,
      System`KeyDrop -> AsymptoticAnalysis`Mathics`KeyDrop,
      System`KeyTake -> AsymptoticAnalysis`Mathics`KeyTake,
      System`Element -> AsymptoticAnalysis`Mathics`Element,
      System`Simplify -> AsymptoticAnalysis`Mathics`Simplify,
      System`FullSimplify -> AsymptoticAnalysis`Mathics`FullSimplify,
      System`RootReduce -> AsymptoticAnalysis`Mathics`RootReduce,
      System`Refine -> AsymptoticAnalysis`Mathics`Refine,
      System`Map -> AsymptoticAnalysis`Private`mathicsMap,
      System`FirstPosition -> AsymptoticAnalysis`Mathics`FirstPosition}, held]];

portableTest["loading-no-messages", "loading", portableLoadResult =!= $Failed, True];

portableTest["loading-public-context", "loading",
  {$Context, Context[AsymptoticInverse], Context[GeneralizedSeries],
    MemberQ[$Packages, "AsymptoticAnalysis`"],
    MemberQ[$ContextPath, "AsymptoticAnalysis`"], Names["Global`GeneralizedSeries"]},
  {"Global`", "AsymptoticAnalysis`", "AsymptoticAnalysis`", True, True, {}}];

portableTest["loading-public-symbols", "loading",
  Sort[Last[StringSplit[#, "`"]] & /@ Names["AsymptoticAnalysis`*"]],
  Sort[{"AsymptoticCoreInverse", "AsymptoticExpand", "AsymptoticExpansion",
    "AsymptoticExponentialCoreInverse", "AsymptoticFlatInverse", "AsymptoticFourierInverse",
    "AsymptoticInverse", "AsymptoticLogarithmicInverse", "AsymptoticSpecialInverse",
    "FlatSeriesDifferentiate", "FlatSeriesMultiply", "FlatSeriesObservable", "FlatSeriesTruncate",
    "FourierInverseCoefficient", "FourierInverseResidual", "GeneralizedSeries",
    "InverseCertificate", "InverseExpansionCoefficient", "InverseNumericalCheck", "InverseResidual",
    "LogarithmicInverseResidual", "PerturbativeInverse", "PowerLogModel", "PowerLogRemainder",
    "ReciprocalLogCompose", "ReciprocalLogDifferentiate", "SeriesAdd", "SeriesCompose",
    "SeriesDifferentiate", "SeriesExp", "SeriesLog", "SeriesMultiply", "SeriesNormalize",
    "SeriesObservable", "SeriesPower", "SeriesRefine", "SeriesTruncate", "SpecialInverseNumericalCheck"}]];

portableTest["loading-reload", "loading",
  Module[{before = Length[UpValues[GeneralizedSeries]]}, Get[portableSource];
    {Length[UpValues[GeneralizedSeries]] === before, $Context,
      Names["AsymptoticInverse`*"], Names["AsymptoticInverse`Private`*"]}],
  {True, "Global`", {}, {}}];

portableTest["loading-no-compatibility-context-leak", "loading",
  {MemberQ[$ContextPath, "AsymptoticAnalysis`Mathics`"], Context[Module], Context[Return],
    Context[Lookup], Context[FirstPosition]},
  {False, "System`", "System`", "System`", "System`"}];

portableTest["primitive-module-return-through-loop", "primitive",
  portablePrimitive[HoldComplete[Module[{},
    Do[If[k === 2, Return[17, Module]], {k, 1, 3}]; 99]]],
  17];

portableTest["primitive-check-is-unpolluted", "primitive", Check[1 + 1, $Failed], 2];

(* A retained symbolic branch value must not become an unconditional truth
   or falsehood through Mathics' reversed two-argument SymPy conversion.
   The branch point is kept in assumptions so caller-side evaluation cannot
   destroy the expression before it reaches the package adapter. *)
portableTest["primitive-productlog-branch-proof-is-conservative", "primitive",
  portablePrimitive[HoldComplete[Module[{z},
    {Simplify[ProductLog[-1, z] == -1] =!= False,
      FullSimplify[ProductLog[-1, z] != -1] =!= True,
      Simplify[ProductLog[-1, z] == -1, z == -1/E] =!= False,
      FullSimplify[ProductLog[-1, z] != -1, z == -1/E] =!= True,
      System`RootReduce[ProductLog[-1, z]] === ProductLog[-1, z],
      Refine[ProductLog[-1, z] == -1] =!= False}]]],
  {True, True, True, True, True, True}];

portableTest["primitive-empty-lookup-preserves-list-state", "primitive",
  portablePrimitive[HoldComplete[Module[{keys = {}, associations = {}, count = 0, a, b},
    a = Lookup[<|"present" -> 1|>, keys, count++; 9];
    b = Lookup[associations, "present", count++; 9];
    {a, b, count, {keys, associations, 2, 0}}]]],
  {{}, 9, 1, {{}, {}, 2, 0}}];

portableTest["primitive-lookup-shares-one-lazy-default", "primitive",
  portablePrimitive[HoldComplete[Module[{count = 0, a, b, c},
    a = Lookup[<|"a" -> 7|>, {"a", "b", "c"}, ++count];
    b = Lookup[{<||>, <|"a" -> 3|>, <||>}, "a", ++count];
    c = Lookup[<|"a" -> 7|>, {"a", "a"}, ++count];
    {a, b, c, count}]]],
  {{7, 1, 1}, {2, 3, 2}, {7, 7}, 2}];

portableTest["operations-empty-inverse-multi-index", "operations",
  Module[{index = {}, model, coefficient},
    model = PowerLogModel[x, x];
    coefficient = InverseExpansionCoefficient[model, index];
    {coefficient["Weight"], coefficient["Exponent"], coefficient["Coefficient"], {index, 2, 0}}],
  {0, 1, 1, {{}, 2, 0}}];

portableTest["primitive-nested-module-return", "primitive",
  portablePrimitive[HoldComplete[Module[{value},
    value = Module[{}, Do[Return[7, Module], {2}]; 90]; value + 1]]],
  8];

portableTest["primitive-lookup-default-is-lazy", "primitive",
  portablePrimitive[HoldComplete[Module[{count = 0, a = <|"present" -> 4|>, found, absent},
    found = Lookup[a, "present", count++; 90];
    absent = Lookup[a, "missing", count++; 91];
    {found, absent, count}]]],
  {4, 91, 1}];

portableTest["primitive-lookup-key-lists", "primitive",
  portablePrimitive[HoldComplete[Lookup[<|"a" -> 3, "b" -> 5|>, {"b", "missing", "a"}, 9]]],
  {5, 9, 3}];

portableTest["primitive-association-update", "primitive",
  portablePrimitive[HoldComplete[Module[{a = <|"a" -> 1, "b" -> 2|>},
    System`AssociateTo[a, {"a" -> 3, "c" -> 4}];
    {a, System`KeyDrop[a, {"b"}], System`KeyTake[a, {"c", "a"}]}]]],
  {<|"a" -> 3, "b" -> 2, "c" -> 4|>, <|"a" -> 3, "c" -> 4|>, <|"c" -> 4, "a" -> 3|>}];

portableTest["primitive-first-position-pattern", "primitive",
  portablePrimitive[HoldComplete[Module[{count = 0, found, absent},
    found = FirstPosition[{a, 2, b}, _Integer, count++; {99}];
    absent = FirstPosition[{a, b}, _Integer, count++; {99}];
    {found, absent, count}]]],
  {{2}, {99}, 1}];

portableTest["assumptions-positive-real-calculus", "assumptions",
  portablePrimitive[HoldComplete[Module[{u},
    {TrueQ[FullSimplify[Element[-1/u, Reals], u > 0]],
      TrueQ[FullSimplify[1/u > 0, u > 0]],
      TrueQ[FullSimplify[Element[Log[u], Reals], u > 0]],
      Expand[FullSimplify[Sqrt[(1 + 2 u)^2], u > 0] - (1 + 2 u)]}]]],
  {True, True, True, 0}];

portableTest["assumptions-nonreal-branches-are-not-admitted", "assumptions",
  portablePrimitive[HoldComplete[Module[{a},
    {FullSimplify[Element[Log[a], Reals], a < 0],
      TrueQ[FullSimplify[Element[Log[a], Reals], Element[a, Reals]]],
      TrueQ[FullSimplify[Element[(-a)^(1/3), Reals], a > 0]]}]]],
  {False, False, False}];

portableTest["assumptions-square-root-keeps-sign", "assumptions",
  portablePrimitive[HoldComplete[Module[{a},
    {FullSimplify[Sqrt[a^2], a < 0] === -a,
      FullSimplify[Sqrt[a^2], Element[a, Reals]] === Abs[a]}]]],
  {True, True}];

portableTest["assumptions-disjunction-does-not-imply-a-disjunct", "assumptions",
  portablePrimitive[HoldComplete[Module[{a, b}, TrueQ[FullSimplify[a > 0, a > 0 || b > 0]]]]],
  False];

(* The finite Mathics proof helpers require each ordered operand to be
   provably real; cancelling a shared complex or unproved-real offset is
   insufficient. Wolfram's ordinary Simplify permits cancellation of a
   symbolic offset, so its independent oracle includes explicit realness
   guards. Every branch below checks actual proof results; neither is skipped. *)
portableTest["assumptions-affine-proofs-require-real-operands", "assumptions",
  Module[{u, a}, If[StringContainsQ[$Version, "Mathics"],
    {AsymptoticAnalysis`Private`mathicsAffineIntervalTruth[u + I > I, u, True, 1/2] === None,
     AsymptoticAnalysis`Private`mathicsAffineIntervalTruth[u + a > a, u, True, 1/2] === None,
     AsymptoticAnalysis`Private`mathicsAffineIntervalTruth[u + a > a, u, Element[a, Reals], 1/2] === True,
     AsymptoticAnalysis`Private`mathicsConvexRealDomainQ[u + I > I, u, True] === False,
     AsymptoticAnalysis`Private`mathicsConvexRealDomainQ[u + a > a, u, True] === False,
     AsymptoticAnalysis`Private`mathicsConvexRealDomainQ[u + a > a, u, Element[a, Reals]] === True,
     ! TrueQ[AsymptoticAnalysis`Mathics`FullSimplify[u + a > a, u > 0]],
     TrueQ[AsymptoticAnalysis`Mathics`FullSimplify[u + a > a, u > 0 && Element[a, Reals]]]},
    { ! TrueQ[FullSimplify[Element[u + I, Reals] && Element[I, Reals] && u + I > I, 0 < u < 1/2]],
      ! TrueQ[FullSimplify[Element[u + a, Reals] && Element[a, Reals] && u + a > a, 0 < u < 1/2]],
      TrueQ[FullSimplify[Element[u + a, Reals] && u + a > a, 0 < u < 1/2 && Element[a, Reals]]],
      ! TrueQ[FullSimplify[Element[u + I, Reals], Element[u, Reals]]],
      ! TrueQ[FullSimplify[Element[u + a, Reals], Element[u, Reals]]],
      TrueQ[FullSimplify[Element[u + a, Reals], Element[u, Reals] && Element[a, Reals]]],
      ! TrueQ[FullSimplify[Element[u + a, Reals] && Element[a, Reals] && u + a > a, u > 0]],
      TrueQ[FullSimplify[Element[u + a, Reals] && u + a > a, u > 0 && Element[a, Reals]]]}]],
  {True, True, True, True, True, True, True, True}];

portableTest["assumptions-symbolic-inverse-coefficient", "assumptions",
  Module[{a, x, y, s}, s = AsymptoticInverse[a x + x^2, {x, 0}, {y, 4}, Assumptions -> a > 0];
    Together[Normal[s] - (y/a - y^2/a^3 + 2 y^3/a^5)]],
  0];

portableTest["assumptions-positive-product-coefficient", "assumptions",
  Module[{a, b, x, y, s}, s = AsymptoticInverse[a b x + x^2, {x, 0}, {y, 4},
      Assumptions -> a b > 0];
    Together[Normal[s] - (y/(a b) - y^2/(a b)^3 + 2 y^3/(a b)^5)]],
  0];

portableTest["forward-polynomial-exact", "forward",
  Module[{x, s}, s = AsymptoticExpansion[1 + x + x^2, {x, 0, 4}, "Backend" -> "Package"];
    {Expand[Normal[s] - (1 + x + x^2)], s["Exact"], s["Remainder"]}],
  {0, True, 0}];

portableTest["forward-exponential", "forward",
  Module[{x, s}, s = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Package"];
    {Expand[Normal[s] - (1 + x + x^2/2)], s["RemainderPower"], s["Exact"]}],
  {0, 3, False}];

portableTest["forward-logarithmic-coefficients", "forward",
  Module[{x, s}, s = AsymptoticExpansion[x^x, {x, 0}, SeriesTermGoal -> 3, "Backend" -> "Package"];
    {Expand[Normal[s] - (1 + x Log[x] + x^2 Log[x]^2/2)],
      s["RemainderPower"], s["RemainderLogDegree"]}],
  {0, 3, 3}];

portableTest["forward-irrational-exponent", "forward",
  Module[{x, s}, s = AsymptoticExpansion[1 + x + x^Sqrt[2], {x, 0, 2}, "Backend" -> "Package"];
    {Expand[Normal[s] - (1 + x + x^Sqrt[2])], s["Exact"], s["Remainder"]}],
  {0, True, 0}];

portableTest["forward-finite-point-from-below", "forward",
  Module[{x, s}, s = AsymptoticExpansion[1/(1 - x), {x, 1, 3},
      Direction -> "FromBelow", "Backend" -> "Package"];
    {Together[Normal[s] - 1/(1 - x)], s["Exact"]}],
  {0, True}];

portableTest["forward-decaying-exponential", "forward",
  Module[{x, s}, s = AsymptoticExpansion[Exp[-1/x], {x, 0, 2}, "Backend" -> "Package"];
    {Normal[s] === Exp[-1/x], s["Remainder"], s["Exact"], s["Terms"]}],
  {True, 0, True, {{0, 1}}}];

portableTest["callable-named-function", "callable",
  Module[{t, x, s}, s = AsymptoticExpansion[Function[{t}, Exp[t]], {x, 0, 4}];
    {Expand[Normal[s] - (1 + x + x^2/2 + x^3/6)], s["RemainderPower"]}],
  {0, 4}];

portableTest["callable-slot-function", "callable",
  Module[{x, s}, s = AsymptoticExpansion[Sin[#] &, {x, 0, 5}];
    {Expand[Normal[s] - (x - x^3/6)], s["RemainderPower"]}],
  {0, 5}];

portableTest["callable-inverse-function", "callable",
  Module[{y, s}, s = AsymptoticExpansion[
      InverseFunction[ConditionalExpression[# + #^2, 0 < # < 1] &], {y, 0, 4}];
    {Expand[Normal[s] - (y - y^2 + 2 y^3)], s["RemainderPower"]}],
  {0, 4}];

portableTest["callable-formal-parameter-ownvalue", "callable",
  Module[{t, x, s}, s = Block[{t = 17},
      AsymptoticExpansion[Function[t, Exp[t]], {x, 0, 3}]];
    {Expand[Normal[s] - (1 + x + x^2/2)], s["RemainderPower"]}],
  {0, 3}];

portableTest["callable-nested-formal-binding", "callable",
  Module[{t, x, s}, s = AsymptoticExpansion[
      Function[t, t + Function[t, t^2][t]], {x, 0, 3}];
    {Expand[Normal[s] - (x + x^2)], s["Remainder"]}],
  {0, 0}];

portableTest["callable-negative-inverse-branch", "callable",
  Module[{y, s}, s = AsymptoticExpansion[
      InverseFunction[ConditionalExpression[#^2, # < 0] &], {y, 0, 2}];
    {Expand[Normal[s] + Sqrt[y]], s["Remainder"]}],
  {0, 0}];

(* Wolfram evaluates these InverseFunction operators before package dispatch,
   choosing the negative square root with its native inverse-function warning.
   Mathics retains the operator, and the bounded package proof must reject a
   domain whose monotonicity/connectedness has not been proved. Check both
   runtime contracts explicitly, including the unchanged native expansion. *)
portableTest["callable-crossing-inverse-domain-contract", "callable",
  Module[{y, s}, s = AsymptoticExpansion[
    InverseFunction[ConditionalExpression[#^2, -1 < # < 1] &],
    {y, 0, 2}, "Backend" -> "Package"];
    If[MatchQ[s, _Failure], "ConservativeFailure",
      {"SelectedExpansion", Expand[Normal[s] + Sqrt[y]]}]],
  If[StringContainsQ[$Version, "Mathics"], "ConservativeFailure", {"SelectedExpansion", 0}]];

portableTest["callable-disconnected-inverse-domain-contract", "callable",
  Module[{y, s}, s = AsymptoticExpansion[
    InverseFunction[ConditionalExpression[#^2, #^2 > 1] &],
    {y, 4, 2}, "Backend" -> "Package"];
    If[MatchQ[s, _Failure], "ConservativeFailure",
      {"SelectedExpansion", Expand[Normal[s] - (-2 + (4 - y)/4)]}]],
  If[StringContainsQ[$Version, "Mathics"], "ConservativeFailure", {"SelectedExpansion", 0}]];

portableTest["callable-complex-function-rejected", "callable",
  Module[{y}, MatchQ[AsymptoticExpansion[
    InverseFunction[I # &], {y, 0, 2}, "Backend" -> "Package"], _Failure]],
  True];

portableTest["inverse-quadratic", "inverse",
  Module[{x, y, s}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
    {Expand[Normal[s] - (y - y^2 + 2 y^3)], s["RemainderPower"]}],
  {0, 4}];

portableTest["inverse-depth-quadratic", "inverse",
  Module[{x, y, s}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}, "Truncation" -> "Depth"];
    {Expand[Normal[s] - (y - y^2 + 2 y^3 - 5 y^4)], s["RemainderPower"]}],
  {0, 5}];

portableTest["inverse-logarithmic-coefficients", "inverse",
  Module[{x, y, s}, s = AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}];
    {Expand[Normal[s] - (y - y^2 (1 + Log[y]) + y^3 (2 Log[y]^2 + 5 Log[y] + 3))],
      s["RemainderPower"], s["RemainderLogDegree"]}],
  {0, 4, 3}];

portableTest["inverse-irrational-exponent", "inverse",
  Module[{x, y, s}, s = AsymptoticInverse[x + x^Sqrt[2], {x, 0}, y, SeriesTermGoal -> 3];
    {TrueQ[FullSimplify[Normal[s] == y - y^Sqrt[2] + Sqrt[2] y^(2 Sqrt[2] - 1), y > 0]],
      TrueQ[FullSimplify[s["RemainderPower"] == 3 Sqrt[2] - 2]]}],
  {True, True}];

portableTest["inverse-infinity", "inverse",
  Module[{x, y, s}, s = AsymptoticInverse[x + 1/x, {x, Infinity}, {y, 4}];
    Together[Normal[s] - (y - 1/y - 1/y^3)]],
  0];

portableTest["inverse-finite-point", "inverse",
  Module[{x, y, s}, s = AsymptoticInverse[x - x^2, {x, 1}, {y, 3}];
    Expand[Normal[s] - (1 - y - y^2)]],
  0];

portableTest["inverse-ramified", "inverse",
  Module[{x, y, s}, s = AsymptoticInverse[x^2 + x^3, {x, 0}, {y, 2}];
    TrueQ[FullSimplify[Normal[s] == Sqrt[y] - y/2 + 5 y^(3/2)/8, y > 0]]],
  True];

portableTest["inverse-exact-termination", "inverse",
  Module[{x, y, s}, s = AsymptoticInverse[(Sqrt[1 + 4 x] - 1)/2, {x, 0}, y,
      SeriesTermGoal -> 3];
    {Expand[Normal[s] - (y + y^2)], s["Remainder"],
      s["ExactTerminationCertificate"]["Verified"]}],
  {0, 0, True}];

portableTest["inverse-residual", "inverse",
  Module[{x, y}, InverseResidual[AsymptoticInverse[x + x^2, {x, 0}, {y, 4}]]["ZeroBelowCutoff"]],
  True];

portableTest["inverse-perturbative-formula", "inverse",
  Module[{x, y}, Simplify[PerturbativeInverse[x^2 (1 + Log[x]), {x, y}, 2] -
    (y - y^2 (1 + Log[y]) + y^3 (2 Log[y]^2 + 5 Log[y] + 3))]],
  0];

portableTest["inverse-perturbative-general-core", "inverse",
  Module[{x, y}, Expand[PerturbativeInverse[Sqrt[y], x^3, {x, y}, 2] -
    (Sqrt[y] - y/2 + 5 y^(3/2)/8)]],
  0];

portableTest["inverse-perturbative-zero-order", "inverse",
  Module[{x, y}, PerturbativeInverse[x^2, {x, y}, 0] === y],
  True];

portableTest["arithmetic-add", "arithmetic",
  Module[{x, a, b, s}, a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
    b = AsymptoticExpansion[Cos[x], {x, 0, 4}]; s = a + b;
    {Expand[Normal[s] - (1 + x - x^2/2 - x^3/6)], s["RemainderPower"]}],
  {0, 4}];

portableTest["arithmetic-multiply", "arithmetic",
  Module[{x, a, b, s}, a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
    b = AsymptoticExpansion[Cos[x], {x, 0, 4}]; s = a b;
    {Expand[Normal[s] - (x - 2 x^3/3)], s["RemainderPower"]}],
  {0, 5}];

portableTest["arithmetic-cancellation-preserves-remainder", "arithmetic",
  Module[{x, a, b, s}, a = AsymptoticExpansion[Sin[x], {x, 0, 3}];
    b = AsymptoticExpansion[x, {x, 0, 3}]; s = a - b;
    {Normal[s], s["RemainderPower"], s["Remainder"] =!= 0}],
  {0, 3, True}];

portableTest["arithmetic-refinement", "arithmetic",
  Module[{x, y, s, refined}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
    refined = SeriesRefine[s, 5];
    {Expand[Normal[refined] - (y - y^2 + 2 y^3 - 5 y^4)], refined["RemainderPower"]}],
  {0, 5}];

portableTest["arithmetic-refinement-retained-state", "arithmetic",
  Module[{x, y, s, first, second}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
    first = SeriesRefine[s, 5]; second = SeriesRefine[first, 7];
    {Expand[Normal[second] - (y - y^2 + 2 y^3 - 5 y^4 + 14 y^5 - 42 y^6)],
      second["RemainderPower"], second["RefinementStatistics"]["StateOrigin"],
      Expand[Normal[s] - (y - y^2)], s["RemainderPower"]}],
  {0, 7, "RetainedLagrangeState", 0, 3}];

portableTest["arithmetic-truncation", "arithmetic",
  Module[{x, s}, s = SeriesTruncate[AsymptoticExpansion[Exp[x], {x, 0, 5}], 3];
    {Expand[Normal[s] - (1 + x + x^2/2)], s["RemainderPower"]}],
  {0, 3}];

portableTest["native-explicit-series", "native",
  Module[{x, s}, s = AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
    {s["Kind"], s["NativeBackend"], s["RemainderContract"],
      s["NativeResult"] === Series[Exp[I x], {x, 0, 3}],
      s["Exact"] === Missing["NotEstablished"]}],
  {"Native", "Series", "NativeFormalOrder", True, True}];

portableTest["native-held-alias", "native",
  Module[{x, a, b}, a = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"];
    b = AsymptoticExpand[Exp[x], {x, 0, 3}, "Backend" -> "Series"];
    Normal[a] === Normal[b] && b["NativeBackend"] === "Series"],
  True];

portableTest["contracts-inexact-exponent", "contracts",
  Module[{x, y}, MatchQ[AsymptoticInverse[x + x^1.5, {x, 0}, {y, 3}], _Failure]],
  True];

portableTest["contracts-cutoff-below-leading", "contracts",
  Module[{x, y}, MatchQ[AsymptoticInverse[x + x^2, {x, 0}, {y, 1/2}], _Failure]],
  True];

portableTest["contracts-input-remainder", "contracts",
  Module[{x, y}, MatchQ[AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4},
      "InputRemainder" -> {3, 1}], _Failure]],
  True];

portableTest["contracts-perturbative-variables", "contracts",
  Module[{x, y},
    {MatchQ[PerturbativeInverse[x^2, {x, x}, 2], Failure["InvalidVariables", _Association]],
      MatchQ[PerturbativeInverse[x^2 + y, {x, y}, 2], Failure["InvalidVariables", _Association]]}],
  {True, True}];

portableTest["contracts-complex-inputs", "contracts",
  Module[{x, y},
    {MatchQ[AsymptoticExpansion[I + x, {x, 0, 3}, "Backend" -> "Package"], _Failure],
      MatchQ[AsymptoticInverse[I x + x^2, {x, 0}, {y, 3}], _Failure]}],
  {True, True}];

portableTest["flat-first-exponential-sector", "flat",
  Module[{x, y, s}, s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 1}];
    {s["Sectors"], Expand[Normal[s] - (y - Exp[-1/y])]}],
  {{{1, -1}}, 0}];

portableTest["certificate-exact-rational-root", "certificate",
  Module[{x, y, s, c}, s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
    c = InverseCertificate[s, 4, "Interval" -> {1, 3}, "Center" -> 2,
      "TargetError" -> 10^-20, "MaxRefinements" -> 0, "RefineExpansion" -> False];
    AssociationQ[c] && TrueQ[c["Certified"]] && TrueQ[c["AccuracyGoalReached"]] &&
      c["CertifiedErrorBound"] === 0 && TrueQ[c["RootEnclosure"][[1]] <= 2 <= c["RootEnclosure"][[2]]]],
  True];

portableTest["certificate-fixed-center-accuracy-floor", "certificate",
  Module[{x, y, s, c, best}, s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
    c = InverseCertificate[s, 4, "Interval" -> {1, 3}, "Center" -> 3/2,
      "TargetError" -> 1/10, "MaxRefinements" -> 0, "RefineExpansion" -> False];
    If[! MatchQ[c, Failure["AccuracyFloor", _Association]], False,
      best = c[[2]]["BestCertificate"];
      TrueQ[best["Certified"]] && ! TrueQ[best["AccuracyGoalReached"]] &&
        TrueQ[best["CertifiedErrorLowerBound"] > 1/10] && Length[c[[2]]["History"]] === 1]],
  True];

portableTest["certificate-omitted-interval-diagnostic", "certificate",
  Module[{x, y, s, omitted, unordered}, s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
    omitted = InverseCertificate[s, 4];
    unordered = InverseCertificate[s, 4, "Interval" -> {3, 1}];
    {MatchQ[omitted, Failure["InvalidInterval", _Association]], omitted[[2]]["Reason"],
      omitted[[2]]["Certified"], MatchQ[unordered, Failure["InvalidInterval", _Association]],
      unordered[[2]]["Reason"], unordered[[2]]["Interval"]}],
  {True, "IntervalNotSupplied", False, True, "MalformedInterval", {3, 1}}];

portableTest["certificate-exact-affine-translation", "certificate",
  Module[{x, y, a = 2^300 + 1, s, c}, s = AsymptoticInverse[x - a, {x, a}, {y, 2}];
    c = InverseCertificate[s, 1/2, "Interval" -> {a + 1/4, a + 3/4}, "Center" -> a + 1/2,
      "EnclosureOrder" -> 2, "MaxRefinements" -> 0, "RefineExpansion" -> False];
    AssociationQ[c] && TrueQ[c["Certified"]] && c["CertifiedErrorBound"] === 0 &&
      c["RootEnclosure"] === {a + 1/2, a + 1/2} && c["ResidualEnclosure"] === {0, 0}],
  True];

portableTest["numerical-exact-quadratic-inverse", "numerical",
  Module[{x, y, s, c}, s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
    c = InverseNumericalCheck[s, 4, WorkingPrecision -> 30];
    AssociationQ[c] && TrueQ[Abs[c["ReferenceRoot"] - 2] < 10^-15] &&
      TrueQ[N[Precision[c["ReferenceRoot"]]] >= 30] &&
      TrueQ[Abs[c["ForwardResidual"]] < 10^-15]],
  True];

portableTest["numerical-local-coordinate-huge-offset", "numerical",
  Module[{x, y, a = 10^100, s, c, exact}, s = AsymptoticInverse[(x - a) + (x - a)^2, {x, a}, {y, 4}];
    c = InverseNumericalCheck[s, 1/1000, WorkingPrecision -> 10];
    exact = 2/1000/(1 + Sqrt[1 + 4/1000]);
    AssociationQ[c] && c["SourceOffset"] === a && c["SourceSide"] === 1 &&
      TrueQ[Abs[c["LocalRoot"] - exact] < 10^-8] && TrueQ[c["LocalRoot"] > 0] &&
      TrueQ[Abs[c["RootResidual"]] < 10^-8] && TrueQ[c["Ratio"] < 10]],
  True];

(* These contracts explicitly distinguish an unavailable Mathics precision
   from an official-kernel high-precision result. Both branches execute the
   public numerical check and verify its actual result. *)
portableTest["numerical-noninteger-quadratic-precision", "numerical",
  Module[{x, y, s, c}, s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
    c = InverseNumericalCheck[s, 2, WorkingPrecision -> 30];
    If[StringContainsQ[$Version, "Mathics"],
      MatchQ[c, Failure["MathicsNumericalPrecisionUnavailable", _Association]],
      AssociationQ[c] && TrueQ[Precision[c["ReferenceRoot"]] >= 25] &&
        TrueQ[Abs[c["ReferenceRoot"] - Sqrt[2]] < 10^-25]]],
  True];

portableTest["numerical-rational-root-precision", "numerical",
  Module[{x, y, s, c}, s = AsymptoticInverse[3 x, {x, 0}, {y, 2}];
    c = InverseNumericalCheck[s, 1, WorkingPrecision -> 30];
    If[StringContainsQ[$Version, "Mathics"],
      MatchQ[c, Failure["MathicsNumericalPrecisionUnavailable", _Association]],
      AssociationQ[c] && TrueQ[Precision[c["ReferenceRoot"]] >= 25] &&
        TrueQ[Abs[c["ReferenceRoot"] - 1/3] < 10^-25]]],
  True];

portableTest["numerical-machine-capability-is-usable", "numerical",
  Module[{x, y, s, c}, s = AsymptoticInverse[3 x, {x, 0}, {y, 2}];
    c = InverseNumericalCheck[s, 1, WorkingPrecision -> 10];
    AssociationQ[c] && TrueQ[N[Precision[c["ReferenceRoot"]]] >= 10] &&
      TrueQ[Abs[c["ReferenceRoot"] - 1/3] < 10^-9]],
  True];

portableTest["special-gamma-stirling", "special",
  Module[{x, s}, s = AsymptoticExpansion[Gamma[x], x -> Infinity, SeriesTermGoal -> 3];
    {s["Terms"], s["RemainderPower"], s["Scale"], s["Exact"]}],
  {{{0, 1}, {1, 1/12}, {2, 1/288}}, 3, "Factored", False}];

portableTest["special-barnes-stirling", "special",
  Module[{x, s}, s = AsymptoticExpansion[BarnesG[x + 1], x -> Infinity, SeriesTermGoal -> 3];
    {s["Terms"], s["RemainderPower"], s["Exact"]}],
  {{{0, 1}, {2, -1/240}, {4, 269/268800}}, 6, False}];

portableTest["special-bessel-origin", "special",
  Module[{x, s}, s = AsymptoticExpansion[BesselJ[0, x], x -> 0, SeriesTermGoal -> 3];
    {Expand[Normal[s] - (1 - x^2/4 + x^4/64)], s["RemainderPower"]}],
  {0, 6}];

portableTest["special-error-function", "special",
  Module[{x, s}, s = AsymptoticExpansion[Erf[x], {x, 0, 5}];
    {Expand[Normal[s] - 2/Sqrt[Pi] (x - x^3/3)], s["RemainderPower"]}],
  {0, 5}];

portableTest["special-polylog-origin", "special",
  Module[{x, s}, s = AsymptoticExpansion[PolyLog[2, x], {x, 0, 4}];
    {Expand[Normal[s] - (x + x^2/4 + x^3/9)], s["RemainderPower"]}],
  {0, 4}];

portableTest["special-zeta-truncation-transports-bound", "special",
  Module[{x, s, t, u, value = 10, tail, upper},
    s = AsymptoticExpansion[Zeta[x], x -> Infinity, SeriesTermGoal -> 3];
    t = SeriesTruncate[s, Log[3]]; u = SeriesTruncate[s, s["Cutoff"]];
    tail = N[Zeta[value] - (Normal[t] /. x -> value), 30];
    upper = N[t["AbsoluteRemainderBound"] /. x -> value, 30];
    {TrueQ[Abs[N[(Normal[t] - (1 + 2^-x)) /. x -> value, 30]] < 10^-20],
      TrueQ[Abs[N[(t["AbsoluteRemainderBound"] - s["AbsoluteRemainderBound"] - 3^-x) /. x -> value, 30]] < 10^-20],
      Head[t["RemainderLowerBound"]] === Missing, t["RemainderBoundConditions"] === s["RemainderBoundConditions"],
      t["ForwardRemainderContract"]["Type"], TrueQ[0 < tail <= upper],
      u["AbsoluteRemainderBound"] === s["AbsoluteRemainderBound"],
      u["RemainderLowerBound"] === s["RemainderLowerBound"]}],
  {True, True, True, True, "TransportedThroughTruncation", True, True, True}];

portableTest["special-zeta-dirichlet", "special",
  Module[{x, s}, s = AsymptoticExpansion[Zeta[x], x -> Infinity, SeriesTermGoal -> 3];
    {Simplify[Normal[s] - (1 + 2^-x + 3^-x)], s["RemainderPower"], s["Exact"]}],
  {0, Log[4], False}];

portableTest["logarithmic-reciprocal-core", "logarithmic",
  Module[{x, y, s}, s = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, 3}];
    {s["Terms"], s["RemainderPower"], s["RemainderLogDegree"]}],
  {{{0, 1}, {1, 1}, {2, 1}}, 3, 0}];

portableTest["families-single-index-coefficient", "families",
  Module[{x, model, c}, model = PowerLogModel[x + x^2 (1 + Log[x]), {x, 0}];
    c = InverseExpansionCoefficient[model, {2}];
    Expand[c["Coefficient"] - (3 + 5 \[FormalL] + 2 \[FormalL]^2)]],
  0];

portableTest["families-lambert-negative-branch", "families",
  Module[{x, y, s}, s = AsymptoticInverse[x Log[x], {x, 0}, y, SeriesTermGoal -> 3];
    {s["Blocks"] /. s["LogVariable"] -> \[FormalL], s["Scale"], s["LambertBranch"]}],
  {{{0, 1}, {1, \[FormalL]}, {2, \[FormalL]^2 + \[FormalL]}}, "Logarithmic", -1}];

portableTest["families-fourier-first-correction", "families",
  Module[{x, y, s}, s = AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 3}];
    {Simplify[Normal[s] - (y - y^2 Sin[Log[y]])],
      s["RemainderPower"], s["RemainderLogDegree"]}],
  {0, 3, 0}];

portableTest["families-gamma-inverse-first-correction", "families",
  Module[{x, y, s, core}, s = AsymptoticInverse[Gamma[x], {x, Infinity}, y, SeriesTermGoal -> 2];
    core = Log[y]/ProductLog[Log[y]/E];
    {Together[Normal[s] - (core + 1/2 - Log[2 Pi]/(2 Log[core]))],
      s["Scale"], s["ReturnedTermCount"], s["RemainderPower"]}],
  {0, "GammaInverse", 2, 1}];

portableTest["families-barnes-inverse-leading-core", "families",
  Module[{x, y, s, core}, s = AsymptoticInverse[BarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 1];
    core = Sqrt[4 Log[y]/ProductLog[4 Log[y]/Exp[3]]];
    {Together[Normal[s] - core], s["Scale"], s["ReturnedTermCount"],
      s["RemainderPower"], s["RemainderInverseLogPower"]}],
  {0, "BarnesGInverse", 1, 0, 0}];

portableTest["families-exponential-core-first-sector", "families",
  Module[{x, y, s, v, core}, s = AsymptoticExponentialCoreInverse[
      x Exp[x], x^2, {x, Infinity}, {y, 1}];
    v = s["LocalVariable"]; core = s["CoreLocalInverse"];
    {Together[s["LocalSectorCoefficients"][[1, 2]] + v^2/(v + 1)],
      Together[Normal[s] - (core - core^3/((core + 1) y))],
      s["SectorDepth"], Length[s["Sectors"]], Length[s["Terms"]],
      FreeQ[{s["Sectors"], s["Terms"]}, _Take]}],
  {0, 0, 1, 1, 2, True}];

portableTest["families-exponential-core-exact-specialization", "families",
  Module[{x, y, s, core}, s = AsymptoticExponentialCoreInverse[
      x Exp[x], x^2, {x, Infinity}, {y, 1}];
    core = s["CoreInverse"];
    {core === ProductLog[y], core /. y -> E, s["LambertBranch"]}],
  {True, 1, 0}];

portableTest["operations-series-power", "operations",
  Module[{x, s}, s = SeriesPower[AsymptoticExpansion[x + x^2 + x^3, {x, 0, 3}], -1, 3];
    {Simplify[Normal[s] - (1/x - 1)], s["RemainderPower"]}],
  {0, 1}];

portableTest["operations-series-log-and-exp", "operations",
  Module[{x, a, l, e}, a = AsymptoticExpansion[x + x^2, {x, 0, 5}];
    l = SeriesLog[a, 4]; e = SeriesExp[AsymptoticExpansion[x, {x, 0, 5}], 4];
    {Simplify[Normal[l] - (Log[x] + x - x^2/2 + x^3/3)], l["RemainderPower"],
      Simplify[Normal[e] - (1 + x + x^2/2 + x^3/6)], e["RemainderPower"]}],
  {0, 4, 0, 4}];

portableTest["operations-series-compose-transports-inner-error", "operations",
  Module[{x, y, s}, s = SeriesCompose[AsymptoticExpansion[Log[1 + x], {x, 0, 4}],
      AsymptoticExpansion[y^2 + y^3, {y, 0, 3}], "Cutoff" -> 7];
    {Simplify[Normal[s] - y^2], s["RemainderPower"]}],
  {0, 3}];

portableTest["operations-series-derivative-contract", "operations",
  Module[{x, s, r}, s = SeriesDifferentiate[AsymptoticExpansion[x Log[x] + x^2, {x, 0, 4}]];
    r = SeriesDifferentiate[AsymptoticExpansion[Sin[x], {x, 0, 4}]];
    {Simplify[Normal[s] - (1 + Log[x] + 2 x)], s["Remainder"], MatchQ[r, _Failure]}],
  {0, 0, True}];

portableTest["operations-series-observable", "operations",
  Module[{x, z, s}, s = SeriesObservable[AsymptoticExpansion[x + x^2, {x, 0, 5}],
      Sin[z], z, "Cutoff" -> 4];
    {Simplify[Normal[s] - (x + x^2 - x^3/6)], s["RemainderPower"]}],
  {0, 4}];

portableTest["operations-series-normalize-composite", "operations",
  Module[{x, a, s}, a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
    s = SeriesNormalize[Sin[a] + Log[1 + a] + Exp[a], "Cutoff" -> 4];
    {Simplify[Normal[s] - (1 + 3 x - x^3/6)], s["RemainderPower"]}],
  {0, 4}];

portableTest["operations-flat-series-calculus-and-error", "operations",
  Module[{x, y, z, s, t, m, o, d},
    s = AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 1}];
    t = FlatSeriesTruncate[s, 2]; m = FlatSeriesMultiply[s, 2];
    o = FlatSeriesObservable[s, 2 z + 1, z]; d = FlatSeriesDifferentiate[s];
    {Simplify[Normal[t] - y],
      t["InnerRemainders"] /. PowerLogRemainder[_, beta_, degree_] :> {beta, degree},
      Simplify[Normal[m] - 2 (y - y^2 Exp[-1/y])],
      Simplify[Normal[o] - (1 + 2 y - 2 y^2 Exp[-1/y])],
      Simplify[Normal[d] - (1 - (1 + 2 y) Exp[-1/y])],
      d["Remainder"] =!= 0, s["SectorRemainder"] =!= 0}],
  {0, {{1, {2, 0}}}, 0, 0, 0, True, True}];

portableTest["operations-reciprocal-log-differentiate", "operations",
  Module[{x, y, t, s, d}, s = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, 3}];
    d = ReciprocalLogDifferentiate[s];
    {Simplify[(Expand[Normal[d]] /. Log[y] -> -1/t) - (1 + t + 2 t^2)],
      d["RemainderPower"], d["AnalyticRemainderContract"]["AllFixedDerivativeOrders"]}],
  {0, 3, True}];

portableTest["operations-reciprocal-log-compose", "operations",
  Module[{x, y, z, t, a, b, s},
    a = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {z, 3}];
    b = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, 3}];
    s = ReciprocalLogCompose[a, b];
    {Simplify[(Expand[Normal[s]/y] /. Log[y] -> -1/t) - (1 + 2 t + 3 t^2)],
      s["RemainderPower"], s["RemainderDerivativeOrder"]}],
  {0, 3, Infinity}];

portableTest["operations-core-inverse-marker-frontier", "operations",
  Module[{x, y, s, terms}, s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 2}];
    terms = s["MarkerTerms"];
    {terms[[All, 1]], Simplify[terms[[All, 2]] - {y, -y^2, 2 y^3}],
      Simplify[s["FirstOmittedMarkerTerm"] + 5 y^4], s["RemainderPower"], s["RemainderLogDegree"]}],
  {{0, 1, 2}, {0, 0, 0}, 0, 4, 0}];

portableTest["operations-special-inverse-quadratic-threshold", "operations",
  Module[{x, y, s}, s = AsymptoticSpecialInverse["QuadraticThreshold", {x, 3}, {y, 2},
      "TargetOffset" -> 7, "TargetScale" -> -2, "QuadraticCoefficient" -> 3];
    {Simplify[Normal[s] - (3 + Sqrt[(7 - y)/6])], s["Remainder"], s["ThresholdTarget"]}],
  {0, 0, 7}];

portableTest["operations-fourier-coefficient-and-residual", "operations",
  Module[{x, y, s, c, r}, s = AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 3}];
    c = FourierInverseCoefficient[s, {1}]; r = FourierInverseResidual[s];
    {Simplify[c["Expression"] + Sin[c["LogVariable"]]], c["Weight"],
      r["ZeroBelowCutoff"], r["ResidualBlocks"], s["RemainderPower"]}],
  {0, 1, True, {}, 3}];

portableTest["primitive-empty-map-preserves-list-state", "primitive",
  portablePrimitive[HoldComplete[Module[{f, g, h, z, a = {}, b, counter = 0, calls = 0, emptyEffects},
    f[z_] := (calls++; z + 1);
    b = Map[(counter++; f), a]; emptyEffects = {counter, calls};
    {emptyEffects, {a, 2, 0}, b, Map[f, {1, 2}],
      Map[g, h[a, b]] === h[g[{}], g[{}]],
      Map[g, {}, {0}] === g[{}], Map[g, {}, {1}, Heads -> True] === g[List][]}]]],
  {{1, 0}, {{}, 2, 0}, {}, {2, 3}, True, True, True}];

portableTest["operations-explicit-series-binary-wrappers", "operations",
  Module[{x, s, a, b, c, d}, s = AsymptoticExpansion[Exp[x], {x, 0, 3}];
    a = SeriesAdd[s, 2]; b = SeriesAdd[2, s];
    c = SeriesMultiply[s, 2]; d = SeriesMultiply[2, s];
    {Simplify[Normal[a] - (3 + x + x^2/2)], Simplify[Normal[a] - Normal[b]],
      Simplify[Normal[c] - (2 + 2 x + x^2)], Simplify[Normal[c] - Normal[d]],
      a["RemainderPower"], c["RemainderPower"]}],
  {0, 0, 0, 0, 3, 3}];

portableTest["operations-logarithmic-inverse-residual", "operations",
  Module[{x, y, s, r}, s = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, 3}];
    r = LogarithmicInverseResidual[s];
    {r["Residual"], r["Vanishes"], r["ZeroBelowCutoff"], r["Cutoff"]}],
  {0, True, True, 3}];

portableTest["operations-special-numerical-exact-threshold", "operations",
  Module[{x, y, s, c}, s = AsymptoticSpecialInverse["QuadraticThreshold", {x, 3}, {y, 2},
      "TargetOffset" -> 7, "TargetScale" -> -2, "QuadraticCoefficient" -> 3];
    c = SpecialInverseNumericalCheck[s, 1, WorkingPrecision -> 30];
    {AssociationQ[c], TrueQ[Abs[c["ReferenceRoot"] - 4] < 10^-20],
      TrueQ[c["Error"] == 0], c["Adapter"], c["Certified"]}],
  {True, True, True, "QuadraticThreshold", False}];

portableTest["operations-series-data-reconstruction", "operations",
  Module[{x, s, copy, truncated}, s = AsymptoticExpansion[1 + x, {x, 0, 3}];
    copy = GeneralizedSeries[s[[1]]];
    truncated = SeriesTruncate[AsymptoticExpansion[x + x^2, {x, 0, 3}], 2];
    {Normal[copy] === 1 + x, copy[1/2], copy["Exact"], copy["Remainder"],
      truncated["Remainder"] === PowerLogRemainder[x, 2, 0]}],
  {True, 3/2, True, 0, True}];

(* Keep inline assumptions held until package dispatch. Mathics otherwise weakens
   Element[Sin[a], Reals] to Element[a, Reals] before the realness proof. *)
portableTest["assumptions-inline-composite-does-not-prove-argument-real", "assumptions",
  Module[{a, x, s}, s = AsymptoticExpansion[a x, {x, 0, 2},
      Assumptions -> Element[Sin[a], Reals], "Backend" -> "Package"];
    MatchQ[s, Failure["UnprovedRealCoefficient", _]]],
  True];

portableTest["assumptions-delayed-inline-evaluates-once", "assumptions",
  Module[{a, x, s, count = 0}, s = AsymptoticExpansion[a x, {x, 0, 2},
      Assumptions :> (count++; Element[Sin[a], Reals]), "Backend" -> "Package"];
    {count, MatchQ[s, Failure["UnprovedRealCoefficient", _]]}],
  {1, True}];

portableTest["assumptions-nested-delayed-composite-coefficient", "assumptions",
  Module[{a, x, s, count = 0}, s = AsymptoticExpansion[Sin[a] x, {x, 0, 2},
      {Assumptions :> (count++; Element[Sin[a], Reals])}, "Backend" -> "Package"];
    {count, Simplify[Normal[s] - Sin[a] x], s["Remainder"]}],
  {1, 0, 0}];

portableTest["assumptions-inline-inverse-and-model-preserve-composite", "assumptions",
  Module[{a, x, y, s, m}, s = AsymptoticInverse[x + a x^2, {x, 0}, {y, 3},
      Assumptions -> Element[Sin[a], Reals]];
    m = PowerLogModel[x + a x^2, {x, 0}, Assumptions -> Element[Sin[a], Reals]];
    {MatchQ[s, Failure["UnprovedRealCoefficient", _]],
      MatchQ[m, Failure["UnprovedRealCoefficient", _]]}],
  {True, True}];

portableTest["operations-newton-inverse-and-retained-refinement", "operations",
  Module[{x, y, a, b, c},
    a = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}, Method -> "Newton"];
    b = SeriesRefine[a, 5]; c = SeriesRefine[b, 7];
    {Simplify[Normal[a] - (y - y^2)], a["Method"],
      Simplify[Normal[c] - (y - y^2 + 2 y^3 - 5 y^4 + 14 y^5 - 42 y^6)],
      c["RemainderPower"], c["RefinementStatistics"]["StateOrigin"],
      Take[c["ComputationState"]["StepCutoffs"], Length[b["ComputationState"]["StepCutoffs"]]] ===
        b["ComputationState"]["StepCutoffs"],
      InverseResidual[c]["ZeroBelowCutoff"]}],
  {0, "Newton", 0, 7, "RetainedNewtonState", True, True}];

portableTest["operations-refinement-additional-blocks-request", "operations",
  Module[{x, y, s, r}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
    r = SeriesRefine[s, <|"AdditionalBlocks" -> 3|>];
    {Length[r["Blocks"]], r["RefinementRequest"]["GoalReached"],
      InverseResidual[r]["ZeroBelowCutoff"],
      Simplify[Normal[r] - (y - y^2 + 2 y^3 - 5 y^4 + 14 y^5)]}],
  {5, True, True, 0}];

portableTest["operations-refinement-replays-product-recipe", "operations",
  Module[{x, y, s, r}, s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
    r = SeriesRefine[SeriesMultiply[s, s], 5];
    {Simplify[Normal[r] - (y^2 - 2 y^3 + 5 y^4)], r["RemainderPower"],
      r["RefinementStatistics"]["Strategy"],
      r["RefinementStatistics"]["NewCoefficientEvaluations"]}],
  {0, 5, "ReplayOperationRecipe", Missing["ReplayNotInstrumented"]}];

(* A typo in the Python/WL test selection must never look like an empty pass. *)
Print["No portable test matched: ", portableSelection];
Exit[2];
