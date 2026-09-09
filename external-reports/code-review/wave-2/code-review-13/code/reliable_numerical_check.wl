(* SPDX-License-Identifier: MIT-0
   Prototype diagnostic wrapper, not an interval certificate and not a
   validated package-wide replacement. Supplied wrapper was not executed
   against the package in this audit; the underlying precision-loss examples
   and the exact mathematical oracle were executed. *)
BeginPackage["AsymptoticAudit`"];
ResolvedInverseNumericalCheck::usage =
"ResolvedInverseNumericalCheck[s,target] repeats InverseNumericalCheck at increasing working precision until its nonzero Error and Ratio have enough reported digits. A numerical zero is unresolved, not proof of exactness. Exact inverses may therefore require a separate symbolic or interval check.";
Options[ResolvedInverseNumericalCheck] = {
  "InitialWorkingPrecision" -> 30, "MaximumWorkingPrecision" -> 300,
  "MinimumErrorDigits" -> 10, "MaximumAttempts" -> 6};
Begin["`Private`"];
ResolvedInverseNumericalCheck[s_, target_, OptionsPattern[]] := Module[
 {wp = OptionValue["InitialWorkingPrecision"], cap = OptionValue["MaximumWorkingPrecision"],
  digits = OptionValue["MinimumErrorDigits"], attempts = OptionValue["MaximumAttempts"],
  history = {}, result, err, ratio, ep, rp, k},
 If[!And @@ (IntegerQ[#] & /@ {wp, cap, digits, attempts}) ||
    wp < 10 || cap < wp || digits < 1 || attempts < 1,
   Return[Failure["InvalidOptions", <|"MessageTemplate" ->
     "Use integer precision bounds, initial >= 10, maximum >= initial, and positive digits/attempts."|>]]];
 If[!NumericQ[target], Return[Failure["NonNumericTarget", <||>]]];
 Do[
   If[Precision[target] =!= Infinity && !TrueQ[Precision[target] >= wp],
     Return[Failure["InsufficientTargetPrecision", <|"RequiredPrecision" -> wp,
       "SuppliedPrecision" -> Precision[target], "History" -> history|>]]];
   result = AsymptoticInverse`InverseNumericalCheck[s, target, WorkingPrecision -> wp];
   If[FailureQ[result], Return[result]];
   If[!AssociationQ[result], Return[Failure["UnexpectedResult", <|"Result" -> result|>]]];
   err = Lookup[result, "Error", Missing["Error"]];
   ratio = Lookup[result, "Ratio", Missing["Ratio"]];
   ep = If[NumberQ[err], Precision[err], -Infinity];
   rp = If[NumberQ[ratio], Precision[ratio], -Infinity];
   AppendTo[history, <|"WorkingPrecision" -> wp, "Error" -> err,
     "ErrorPrecision" -> ep, "RatioPrecision" -> rp|>];
   If[TrueQ[err > 0] && TrueQ[ratio > 0] && TrueQ[ep >= digits] && TrueQ[rp >= digits],
     Return[Join[result, <|"ErrorResolution" -> "NumericallyResolved",
       "MinimumErrorDigits" -> digits, "History" -> history,
       "Certified" -> False|>]]];
   If[wp >= cap, Break[]]; wp = Min[cap, 2 wp],
   {k, attempts}];
 Failure["ErrorNotResolved", <|"MessageTemplate" ->
   "The error was not numerically resolved; numerical zero does not establish exactness.",
   "LastResult" -> result, "History" -> history, "Certified" -> False|>]
];
End[]; EndPackage[];
