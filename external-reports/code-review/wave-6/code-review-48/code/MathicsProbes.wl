(* SPDX-License-Identifier: MIT-0
   NOT EXECUTED in Mathics during this review.
   Load this file in Mathics3, then call AuditMathicsProbes[packagePath].
   These are observations rather than a claim that every baseline must fail.
   The fallback is only entered when the first N evaluation has Indeterminate. *)
ClearAll[AuditMathicsProbes];
AuditMathicsProbes[packagePath_String] := Module[
 {x, y, s, exponent, rational, expression, results, delayedCalls = 0},
 If[! StringContainsQ[$Version, "Mathics"],
   Return[Failure["WrongEvaluator", <|"Version" -> $Version|>]]];
 If[! FileExistsQ[packagePath], Return[Failure["MissingPackage", <||>]]];
 Get[packagePath];
 s = AsymptoticAnalysis`AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
 If[! MatchQ[s, AsymptoticAnalysis`GeneralizedSeries[_Association]],
   Return[Failure["SmokeFailed", <|"Result" -> s|>]]];
 results = Table[
   rational = 10^-exponent;
   expression = Log[Sqrt[Pi] rational];
   <|"DecimalExponent" -> exponent,
     "ExactRationalPositive" -> TrueQ[rational > 0],
     "MachineRational" -> N[rational],
     "MachineGuard" -> TrueQ[N[rational] > 0],
     "SplitHelperResult" -> AsymptoticAnalysis`Private`mathicsNumericalSplitLog[{Sqrt[Pi], rational}],
     "FirstNativeN" -> N[expression, 80],
     "RecoveryN" -> AsymptoticAnalysis`Private`mathicsNumericalN[expression, 80],
     "SplitOracle" -> N[Log[Pi]/2 - exponent Log[10], 80]|>,
   {exponent, {20, 323, 324, 400, 1000}}];
 <|"Version" -> $Version, "PackagePath" -> packagePath,
   "PrimitiveNestedFilter" -> System`FilterRules[{{"Power" -> 2}}, "Power"],
   "PrimitiveDelayedFilter" -> System`FilterRules[{"Power" :> 2}, "Power"],
   "SymbolCoefficient" -> AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, Power -> 2],
   "NestedCoefficient" -> AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, {"Power" -> 2}],
   "DelayedCoefficient" -> AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, "Power" :> (delayedCalls++; 2)],
   "DelayedEvaluationCount" -> delayedCalls,
   "LogarithmProbes" -> results,
   "Scope" -> "Primitive and focused package observations; not high-precision FindRoot acceptance."|>
];
