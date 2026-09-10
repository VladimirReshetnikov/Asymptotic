(* SPDX-License-Identifier: MIT-0
   Focused reproducer. Load this file, then call:
     AuditNativeReview["/absolute/path/AsymptoticAnalysis.wl", "Baseline"]
   or "Candidate" after applying the proposed modular changes and rebuilding.
   Equivalent expressions, not this complete file, were run in the authoring
   session. The final record is returned; this file does not write reports. *)

ClearAll[AuditNativeReview];
AuditNativeReview[packagePath_String, mode_String : "Baseline"] := Module[
 {loaded, x, y, s, s2, si, si2, a, b, ra, rb, cc, counter, value,
  options, checks, metadata, polynomials, methods, powers, oracle,
  rows = {}, probe, difference, i, r, method},
 If[! MemberQ[{"Baseline", "Candidate"}, mode],
   Return[Failure["InvalidMode", <|"Mode" -> mode|>]]];
 If[! FileExistsQ[packagePath],
   Return[Failure["MissingPackage", <|"Path" -> packagePath|>]]];
 If[StringContainsQ[$Version, "Mathics"],
   Return[Failure["WrongEvaluator", <|"MessageTemplate" ->
     "Use MathicsProbes.wl for the unrun Mathics-specific probes."|>]]];
 loaded = Check[Get[packagePath]; True, False];
 If[! TrueQ[loaded], Return[Failure["PackageLoad", <|"Path" -> packagePath|>]]];
 s = AsymptoticAnalysis`AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
 If[! MatchQ[s, AsymptoticAnalysis`GeneralizedSeries[_Association]],
   Return[Failure["SmokeFailed", <|"Result" -> s|>]]];
 cc[v_Association] := {v["Exponent"], v["Coefficient"]};
 cc[v_] := v;
 options = <|
   "String" -> cc[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, "Power" -> 2]],
   "Symbol" -> cc[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, Power -> 2]],
   "Mixed" -> cc[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, Power -> 2, "Power" -> 3]],
   "Nested" -> cc[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, {"Power" -> 2}]],
   "Delayed" -> cc[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, "Power" :> 2]]|>;
 s2 = AsymptoticAnalysis`AsymptoticInverse[x + x^2, {x, 0}, {y, 4}, "Power" -> 2];
 si = AsymptoticAnalysis`AsymptoticInverse[x^2 + x, {x, Infinity}, {y, 3}];
 si2 = AsymptoticAnalysis`AsymptoticInverse[x^2 + x, {x, Infinity}, {y, 3}, "Power" -> 2];
 checks = <|
   "string" -> (options["String"] === {3, -2}),
   "symbol" -> (options["Symbol"] === {3, -2}),
   "mixed-first-wins" -> (options["Mixed"] === {3, -2}),
   "mixed-reversed" -> (cc[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, "Power" -> 3, Power -> 2]] === {4, -3}),
   "nested" -> (cc[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, {{"Power" -> 2}}]] === {3, -2}),
   "stored-power-default" -> (cc[AsymptoticAnalysis`InverseExpansionCoefficient[s2, {1}]] === {3, -2}),
   "infinite-symbol" -> (cc[AsymptoticAnalysis`InverseExpansionCoefficient[si, {1}, Power -> 2]] ===
      cc[AsymptoticAnalysis`InverseExpansionCoefficient[si2, {1}]]),
   "other-context" -> (cc[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, AuditOptions`Power -> 2]] === {3, -2})|>;
 counter = 0;
 value = AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, "Power" :> (counter++; 2)];
 AssociateTo[checks, "selected-delayed-once" -> ({cc[value], counter} === {{3, -2}, 1})];
 counter = 0;
 value = AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, "Power" -> 2, "Power" :> (counter++; 3)];
 AssociateTo[checks, "shadowed-delayed-not-evaluated" -> ({cc[value], counter} === {{3, -2}, 0})];
 a = AsymptoticAnalysis`AsymptoticInverse[x^2, {x, 0}, {y, 3}, "Power" -> 2];
 b = AsymptoticAnalysis`AsymptoticInverse[x^2, {x, 0}, {y, 3}, Direction -> "FromBelow", "Power" -> 3];
 ra = AsymptoticAnalysis`InverseNumericalCheck[a, 4, WorkingPrecision -> 30];
 rb = AsymptoticAnalysis`InverseNumericalCheck[b, 4, WorkingPrecision -> 30];
 metadata = <|
   "square-source-coordinate" -> TrueQ[ra["LocalRoot"] == 2],
   "square-observable" -> TrueQ[ra["LocalReferenceObservable"] == 4],
   "square-power-field" -> (ra["ObservablePower"] === 2),
   "cube-source-coordinate" -> TrueQ[rb["LocalRoot"] == 2],
   "cube-signed-observable" -> TrueQ[rb["LocalReferenceObservable"] == -8],
   "cube-power-field" -> (rb["ObservablePower"] === 3),
   "square-math-unchanged" -> TrueQ[ra["Error"] == 0 && ra["Approximation"] == 4],
   "cube-math-unchanged" -> TrueQ[rb["Error"] == 0 && rb["Approximation"] == -8]|>;
 polynomials = {x + x^2, x - x^2, x + x^3, x + 2 x^2 - x^3, 2 x + x^2};
 methods = {"Lagrange", "GroupedLagrange", "Newton"}; powers = {-1, 1, 2};
 Do[
   oracle = Normal[InverseSeries[Series[polynomials[[i]], {x, 0, 8}]]] /. x -> y;
   Do[
     probe = TimeConstrained[
       value = AsymptoticAnalysis`AsymptoticInverse[polynomials[[i]], {x, 0}, {y, 4}, "Power" -> r, Method -> method];
       If[! MatchQ[value, AsymptoticAnalysis`GeneralizedSeries[_Association]],
         <|"Status" -> "NotSeries", "Result" -> value|>,
         difference = FullSimplify[Normal[Series[Normal[value] - oracle^r, {y, 0, 3}]], y > 0];
         <|"Status" -> If[difference === 0, "Pass", "Mismatch"], "Difference" -> difference|>],
       3, <|"Status" -> "Timeout"|>];
     AppendTo[rows, Join[<|"SourceIndex" -> i, "Power" -> r, "Method" -> method|>, probe]],
     {r, powers}, {method, methods}], {i, Length[polynomials]}];
 <|"Version" -> $Version, "PackagePath" -> packagePath, "Mode" -> mode,
   "CoefficientObservations" -> options, "PositiveSquare" -> ra, "NegativeCube" -> rb,
   "DesiredOptionChecks" -> checks, "DesiredMetadataChecks" -> metadata,
   "DesiredCandidateChecksAllPassed" -> (And @@ Join[Values[checks], Values[metadata]]),
   "MatrixDefinition" -> "Five polynomial sources, three powers, three methods, native InverseSeries oracle",
   "MatrixTotal" -> Length[rows], "MatrixPassed" -> Count[Lookup[rows, "Status"], "Pass"],
   "MatrixOtherResults" -> Select[rows, #["Status"] =!= "Pass" &],
   "Scope" -> "Focused probe only; baseline is expected to fail some desired candidate checks."|>
];
