(* UNEXECUTED NATIVE PROBES: run after loading the PINNED AsymptoticAnalysis.
   Results characterize behavior, not a predeclared package pass/fail claim.
   No definitions in System` or AsymptoticAnalysis` are changed. *)
Begin["AsymptoticAudit`"];
ClearAll[x, a, record, describe, results];
results = {};
SetAttributes[record, HoldRest];
record[id_String, expression_] := Module[{value},
  value = Quiet[Check[TimeConstrained[expression, 30, $Aborted], $Failed]];
  AppendTo[results, <|"ID" -> id, "Value" -> ToString[value, InputForm]|>];
  Print[id, ": ", ToString[value, InputForm]];
  value
];
describe[value_] := If[Head[value] === AsymptoticAnalysis`GeneralizedSeries,
  <|"Head" -> Head[value], "Expression" -> value["Expression"],
    "TargetDomain" -> value["TargetDomain"], "Assumptions" -> value["Assumptions"],
    "Function" -> value["Function"]|>, value];
record["environment", {$Version, $VersionNumber, $SystemID}];

If[DownValues[AsymptoticAnalysis`AsymptoticExpansion] === {},
  Print["STOP: Load the pinned package before this file."],
  record["N1-exact-predicate-counterexample",
    {Element[Log[-1], Reals], Element[-1, Reals]}];
  If[StringContainsQ[$Version, "Mathics"],
    record["N1-native-symbolic-predicate", Element[Log[a], Reals]];
    record["N1-source-guard-omission",
      AsymptoticAnalysis`Private`mathicsProtectInputAssumptions[
        HoldComplete[AsymptoticAnalysis`Private`packageEvaluatedEntry[
          AsymptoticAnalysis`Private`forwardHeldExpression[
            ConditionalExpression[x, System`Element[Log[a], Reals]]],
          {x, 0, 2}, Assumptions -> a < 0]]] ===
        HoldComplete[AsymptoticAnalysis`Private`packageEvaluatedEntry[
          AsymptoticAnalysis`Private`forwardHeldExpression[
            ConditionalExpression[x, System`Element[Log[a], Reals]]],
          {x, 0, 2}, Assumptions -> a < 0]]];
    record["N1-option-guard-positive-control",
      FreeQ[AsymptoticAnalysis`Private`mathicsProtectInputAssumptions[
        HoldComplete[f[Assumptions -> System`Element[Log[a], Reals]]]],
        System`Element]];
  ];
  (* IMPORTANT: the source ConditionalExpression is inline, not pre-evaluated
     into a variable. The package's advertised holding boundary is exercised. *)
  record["N1-inline-negative-a",
    describe[AsymptoticAnalysis`AsymptoticExpansion[
      ConditionalExpression[x, Element[Log[a], Reals]], {x, 0, 2},
      Assumptions -> a < 0, "Backend" -> "Package"]]];
  record["N1-inline-positive-a-control",
    describe[AsymptoticAnalysis`AsymptoticExpansion[
      ConditionalExpression[x, Element[Log[a], Reals]], {x, 0, 2},
      Assumptions -> a > 0, "Backend" -> "Package"]]];
  record["N1-explicit-domain-control",
    describe[AsymptoticAnalysis`AsymptoticExpansion[
      ConditionalExpression[x, a > 0], {x, 0, 2},
      Assumptions -> a < 0, "Backend" -> "Package"]]];
  record["E2-zeta-input-contract",
    Module[{s = AsymptoticAnalysis`AsymptoticExpansion[
      Zeta[x], {x, Infinity}, SeriesTermGoal -> 3,
      "Backend" -> "Package"]},
      If[Head[s] === AsymptoticAnalysis`GeneralizedSeries,
        {s["Expression"], s["SeriesRepresentation"]}, s]]];
  record["E2-zeta-first-derivative",
    Module[{s = AsymptoticAnalysis`AsymptoticExpansion[
      Zeta[x], {x, Infinity}, SeriesTermGoal -> 3,
      "Backend" -> "Package"]},
      AsymptoticAnalysis`SeriesDifferentiate[s, 1]]];
  record["E2-zeta-proof-declared-derivative",
    Module[{s = AsymptoticAnalysis`AsymptoticExpansion[
      Zeta[x], {x, Infinity}, SeriesTermGoal -> 3,
      "Backend" -> "Package"]},
      AsymptoticAnalysis`SeriesDifferentiate[s, 1,
        "RemainderDerivativeOrder" -> Infinity]]];
];
AsymptoticAuditResults = <|"Kernel" -> $Version,
  "PinnedRevision" -> "8cee870994f506b501bae3ea6bd4a3a7edb895c1",
  "Records" -> results|>;
End[];
