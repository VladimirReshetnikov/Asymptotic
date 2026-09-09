(* Opt-in external adapter. Does not modify AsymptoticInverse definitions.
   Load the original standalone package first. The original certificate engine
   remains the sole authority for every returned mathematical certificate. *)
BeginPackage["AsymptoticAudit`", {"AsymptoticInverse`"}];
AccuracyAwareInverseCertificate::usage =
 "AccuracyAwareInverseCertificate[s,y,opts] supplies an accuracy-aware initial enclosure order and retries only AccuracyNotReached failures at higher arithmetic precision. Every certificate is produced by the original InverseCertificate implementation.";
Options[AccuracyAwareInverseCertificate] = Join[
 Options[AsymptoticInverse`InverseCertificate],
 {"PrecisionPasses" -> 3, "MaximumEnclosureOrder" -> 2000}];
Begin["`Private`"];
accuracyDigits[t_] := If[(IntegerQ[t] || Head[t] === Rational) && TrueQ[t > 0],
 Max[0, IntegerLength[Denominator[t]] - IntegerLength[Numerator[t]]], 0];
AccuracyAwareInverseCertificate[s_, target_, opts : OptionsPattern[]] := Module[
 {raw = Flatten[{opts}], inherited, allowed, unknown, wp = OptionValue[WorkingPrecision],
  passes = OptionValue["PrecisionPasses"], cap = OptionValue["MaximumEnclosureOrder"],
  order = OptionValue["EnclosureOrder"], history = {}, result, next, pass},
 allowed = First /@ Options[AccuracyAwareInverseCertificate];
 unknown = Select[raw, ! MemberQ[allowed, First[#]] &];
 If[unknown =!= {}, Return[Failure["InvalidOption", <|"Options" -> unknown|>]]];
 If[! IntegerQ[passes] || passes < 0 || ! IntegerQ[cap] || cap < 5 || cap > 2000,
  Return[Failure["InvalidOption", <|"MessageTemplate" ->
    "PrecisionPasses must be nonnegative and MaximumEnclosureOrder an integer in [5,2000]."|>]]];
 inherited = FilterRules[raw, Options[AsymptoticInverse`InverseCertificate]];
 If[! IntegerQ[wp] || wp < 10,
  Return[AsymptoticInverse`InverseCertificate[s, target, Sequence @@ inherited]]];
 If[order === Automatic, order = Min[cap, Max[wp + 10,
   15 + accuracyDigits[OptionValue["TargetError"]],
   15 + accuracyDigits[OptionValue["RelativeError"]]]]];
 If[! IntegerQ[order] || order < 5 || order > cap,
  Return[Failure["InvalidEnclosureOrder", <|"RequestedOrder" -> order,
    "MaximumEnclosureOrder" -> cap|>]]];
 inherited = DeleteCases[inherited, (Rule | RuleDelayed)["EnclosureOrder", _]];
 Do[
  result = AsymptoticInverse`InverseCertificate[s, target,
    "EnclosureOrder" -> order, Sequence @@ inherited];
  AppendTo[history, <|"Pass" -> pass, "InitialEnclosureOrder" -> order,
    "Outcome" -> If[FailureQ[result], result[[1]], "CertificateReturned"]|>];
  If[AssociationQ[result], Return[Join[result,
    <|"AccuracyAdapterHistory" -> history|>]]];
  If[! MatchQ[result, Failure["AccuracyNotReached", _Association]], Return[result]];
  next = Min[cap, 2 order];
  If[next === order, Break[]]; order = next,
  {pass, 0, passes}];
 If[MatchQ[result, Failure[_, _Association]],
  Failure[result[[1]], Join[result[[2]], <|"AccuracyAdapterHistory" -> history|>]], result]
];
End[];
EndPackage[];
