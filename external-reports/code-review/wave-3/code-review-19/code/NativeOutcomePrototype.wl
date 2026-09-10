(* Additive prototype: does NOT alter the upstream wrapper or its status field.
   Inspection is held: the supplied result expression is not re-executed.
   This prototype was not natively executed during the audit. It distinguishes
   failure markers from unresolved syntax but does not prove native success,
   analyticity, exactness, branch validity, or correctness. *)
BeginPackage["AsymptoticAuditOutcome`"];
InspectHeldNativeOutcome::usage = "InspectHeldNativeOutcome[HoldComplete[result]] returns separate diagnostic flags without evaluating result.";
Begin["`Private`"];
InspectHeldNativeOutcome[h_HoldComplete] := Module[
 {topFailure, nestedFailure, unresolved, singular},
 topFailure = MatchQ[h, HoldComplete[$Failed | $Aborted | _Failure]];
 nestedFailure = ! FreeQ[h, $Failed | $Aborted | _Failure];
 unresolved = ! FreeQ[h, _System`Series | _System`Asymptotic];
 singular = ! FreeQ[h, Indeterminate | _DirectedInfinity];
 <|"TopLevelFailure" -> topFailure, "ContainsFailureMarker" -> nestedFailure,
 "ContainsUnresolvedExpansion" -> unresolved, "ContainsNonfiniteExpression" -> singular,
 "EvaluationOutcome" -> Which[topFailure, "Failed", nestedFailure, "ContainsFailure",
   unresolved, "Unresolved", True, "Returned"],
 "AnalyticValidity" -> Missing["NotEstablished"]|>];
InspectHeldNativeOutcome[___] := Failure["HeldInputRequired", <|
 "MessageTemplate" -> "Pass HoldComplete[result]; this inspector must not evaluate the result."|>];
End[]; EndPackage[];
