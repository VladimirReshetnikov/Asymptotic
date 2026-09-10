(* Original candidate audit helpers. UNRUN in a Wolfram kernel.
   These helpers do not alter upstream definitions or install a global hotfix. *)
BeginPackage["AsymptoticBoundaryReview`", {"AsymptoticAnalysis`"}];
CheckedInverseCoefficient::usage =
  "CheckedInverseCoefficient[s,k,opts] validates the ordinary inverse coefficient-model capability before delegating. It does not fix the separately recorded option-precedence issue C09.";
NativeOutcome::usage =
  "NativeOutcome[raw] supplies a proposed diagnostic classification without claiming mathematical correctness. The full raw result must still be retained.";
Begin["`Private`"];
Options[CheckedInverseCoefficient] = Options[AsymptoticAnalysis`InverseExpansionCoefficient];
CheckedInverseCoefficient[s : AsymptoticAnalysis`GeneralizedSeries[a_Association], k_List,
    opts : OptionsPattern[]] := Module[{model, required},
  If[Lookup[a, "Kind", None] === "Native",
    Return[Failure["NativeSeriesContract", <|"MessageTemplate" ->
      "Native results do not carry an ordinary inverse coefficient model."|>]]];
  model = Lookup[a, "Model", Missing["NoCoefficientModel"]];
  required = {"Gaps", "Polynomials", "LeadingPower", "LogVariable", "Symbolic"};
  If[! AssociationQ[model] || ! AllTrue[required, KeyExistsQ[model, #] &],
    Return[Failure["UnsupportedCoefficientModel", <|
      "MessageTemplate" -> "This result does not carry the ordinary inverse coefficient-model capability.",
      "Kind" -> Lookup[a, "Kind", Missing["Unknown"]],
      "Scale" -> Lookup[a, "Scale", Missing["Unspecified"]]|>]]];
  AsymptoticAnalysis`InverseExpansionCoefficient[s, k, opts]
];
CheckedInverseCoefficient[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use CheckedInverseCoefficient[series, nonnegativeMultiIndex, options]."|>];

NativeOutcome[raw_] := Which[
  raw === $Aborted, "Aborted",
  raw === $Failed || FailureQ[raw], "Failed",
  ! FreeQ[raw, _Failure | $Failed | $Aborted], "ContainsFailure",
  ! FreeQ[raw, _System`Series | _System`Asymptotic], "Unresolved",
  ! FreeQ[raw, Indeterminate], "Indeterminate",
  True, "ReturnedWithoutFailureMarker"
];
End[];
EndPackage[];
