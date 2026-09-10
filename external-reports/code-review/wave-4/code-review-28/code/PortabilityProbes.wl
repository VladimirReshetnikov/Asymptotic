(* Characterization probes: not claimed to have been executed for this report.
   Each probe should run in a fresh kernel through run_audit_probes.py. *)
auditSource = Environment["ASYMPTOTIC_AUDIT_SOURCE"];
auditSelection = Environment["ASYMPTOTIC_AUDIT_CASE"];
If[! StringQ[auditSource] || ! StringQ[auditSelection], Exit[2]];
If[StringContainsQ[$Version, "Mathics"], $IterationLimit = 1000000];
Print["AUDIT_KERNEL\t", $Version];
auditLoad = Check[Get[auditSource], $Failed];
If[auditLoad === $Failed, Print["AUDIT_LOAD_FAILED"]; Exit[2]];

SetAttributes[auditProbe, HoldAll];
auditProbe[name_String, expression_] := If[name === auditSelection,
  Module[{answer}, answer = expression;
    Print["AUDIT_VALUE_BEGIN"];
    Print[ToString[answer, InputForm]];
    Print["AUDIT_VALUE_END"];
    Print["AUDIT_COMPLETED\t", name]; Exit[0]]];

auditPrimitive[held_HoldComplete] := ReleaseHold[
  If[StringContainsQ[$Version, "Mathics"], held /. {
    System`Limit -> AsymptoticAnalysis`Mathics`Limit,
    System`FirstPosition -> AsymptoticAnalysis`Mathics`FirstPosition}, held]];

auditProbe["root-precision",
  Module[{x, root},
    root = x /. FindRoot[Exp[x] == 2, {x, N[Log[2], 60]},
      WorkingPrecision -> 60, AccuracyGoal -> Infinity, PrecisionGoal -> 50];
    {root, Precision[root], N[Exp[root] - 2, 60], Options[FindRoot]}]];

auditProbe["public-numerical-precision",
  Module[{x, y, s, r},
    s = AsymptoticAnalysis`AsymptoticInverse[Exp[x] - 1, {x, 0}, {y, 6}];
    r = AsymptoticAnalysis`InverseNumericalCheck[s, 1/10, WorkingPrecision -> 50];
    {r, If[AssociationQ[r], Precision[r["ReferenceRoot"]], "No numerical result"]}]];

auditProbe["core-negative-lambert",
  Module[{x, y, s, value},
    s = AsymptoticAnalysis`AsymptoticCoreInverse[-x Log[x], 0, {x, 0}, {y, 0}];
    value = N[s[1/100], 50];
    {Head[s], Normal[s], value,
      If[NumericQ[value], N[-value Log[value] - 1/100, 40], "Non-numeric"]}]];

auditProbe["limit-default",
  auditPrimitive[HoldComplete[{
    Limit[Abs[x]/x, x -> 0],
    Limit[Abs[x]/x, x -> 0, Direction -> -1],
    Limit[Abs[x]/x, x -> 0, Direction -> 1]}]]];

auditProbe["first-position-options",
  auditPrimitive[HoldComplete[{
    FirstPosition[{a}, b, Heads -> False],
    FirstPosition[h[a], h, Heads -> False]}]]];

auditProbe["first-position-predicate-count",
  auditPrimitive[HoldComplete[Module[{n = 0, position},
    position = FirstPosition[Range[100], _Integer?(Function[v, n++; True]),
      Missing["NotFound"], {1}]; {position, n}]]]];

auditProbe["affine-small-radius",
  AsymptoticAnalysis`Private`inverseFunctionEventually[1/1000-u > 0, u, True]];

auditProbe["terminating-pfq",
  Module[{x, s},
    s = AsymptoticAnalysis`AsymptoticExpansion[
      HypergeometricPFQ[{-2,3,5},{7},x], {x,0,4}];
    {s, If[Head[s] === AsymptoticAnalysis`GeneralizedSeries,
      Expand[Normal[s]-(1-30 x/7+45 x^2/7)], "Not constructed"]}]];

Print["AUDIT_UNKNOWN_CASE\t", auditSelection];
Exit[2];
