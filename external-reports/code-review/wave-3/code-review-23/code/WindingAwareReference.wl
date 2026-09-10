(* Formula-level constructive reference from the accompanying proof.
   NOT EXECUTED in the audit. No GeneralizedSeries/InverseCertificate is fabricated.
   New code: MIT-0. All bounds below concern positive real arguments. *)
BeginPackage["AsymptoticAudit`WindingReference`"];
WindingForward::usage = "WindingForward[x] is the real monotone source on the proved local interval.";
WindingInverseApproximation::usage = "WindingInverseApproximation[y] retains the exact bounded periodic coefficient.";
WindingInverseErrorBound::usage = "WindingInverseErrorBound[y] is the conditional analytic upper-bound formula proved in the article, not a native interval-certificate transcript.";
WindingInverseDomain::usage = "WindingInverseDomain[y] gives the sufficient target interval for the bound.";
Begin["`Private`"];
delta = 1/(4 (Pi^2 + Pi));
boundConstant = 112 Pi^4/27 + 32 Pi^3/9;
WindingForward[x_] := ConditionalExpression[x - x^2 Arg[x^I]^2, 0 < x < delta];
WindingInverseDomain[y_] := 0 < y < 3 delta/4;
WindingInverseApproximation[y_] := ConditionalExpression[
 y + y^2 Arg[y^I]^2, WindingInverseDomain[y]];
WindingInverseErrorBound[y_] := ConditionalExpression[
 boundConstant y^3, WindingInverseDomain[y]];
End[];
EndPackage[];
