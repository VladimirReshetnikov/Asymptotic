(* Standalone proposed helpers, NOT native-validated and NOT installed into
   AsymptoticInverse`Private`. SPDX-License-Identifier: MIT-0 *)
BeginPackage["AsymptoticAuditHelpers`"];
PrimitiveFlatLattice::usage = "PrimitiveFlatLattice[rates] returns a common positive rate and primitive positive integer degrees when all rate ratios are rational. It does not handle irrationally independent exponential rates.";
PowerInputPrecision::usage = "PowerInputPrecision[outputOrder, leadingPower, r] gives the required input remainder exponent for a nonzero fixed power r, assuming a proved nonzero real branch.";
Begin["`Private`"];
Options[PrimitiveFlatLattice] = {Assumptions :> $Assumptions, "MaxSectorDegree" -> 20000};
PrimitiveFlatLattice[rates_List, OptionsPattern[]] := Module[
 {ass = OptionValue[Assumptions], limit = OptionValue["MaxSectorDegree"], first, ratios, den, ints, divisor, degrees},
 If[rates === {} || ! IntegerQ[limit] || limit < 1,
  Return[Failure["InvalidInput", <|"MessageTemplate" -> "Give nonempty exact positive rates and a positive integer degree budget."|>], Module]];
 If[! FreeQ[rates, _Real] || ! AllTrue[rates, TrueQ[FullSimplify[# > 0, ass]] &],
  Return[Failure["UnprovedPositiveRates", <|"Rates" -> rates|>], Module]];
 first = First[rates]; ratios = FullSimplify[#/first, ass] & /@ rates;
 If[! AllTrue[ratios, IntegerQ[#] || Head[#] === Rational &],
  Return[Failure["NonrationalRateRatios", <|"Ratios" -> ratios|>], Module]];
 den = LCM @@ (Denominator /@ ratios); ints = den ratios;
 divisor = GCD @@ ints; degrees = ints/divisor;
 If[Max[degrees] > limit,
  Return[Failure["SectorDegreeLimit", <|"RequiredMaximumDegree" -> Max[degrees], "Limit" -> limit|>], Module]];
 <|"PhaseRate" -> FullSimplify[first divisor/den, ass], "SectorDegrees" -> degrees,
   "Assumptions" -> ass, "Contract" -> "rates == PhaseRate SectorDegrees; GCD of SectorDegrees is one"|>];
PrimitiveFlatLattice[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use PrimitiveFlatLattice[{c1,c2,...}]."|>];
PowerInputPrecision[h_, alpha_, r_] := If[TrueQ[r == 0],
 Missing["ExactConstantObservable"], h - (r - 1) alpha];
End[];
EndPackage[];
