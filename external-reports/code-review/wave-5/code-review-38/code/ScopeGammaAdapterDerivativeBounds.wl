(* Original audit helper. UNEXECUTED in Wolfram/Mathics during this review.
   Load the repository first. This helper returns a new object; it never
   patches package definitions or mutates the supplied object.
   Scope: package-created SpecialInverse Gamma/LogGamma adapters only. *)
BeginPackage["AsymptoticAudit`", {"AsymptoticAnalysis`"}];
ScopeGammaAdapterDerivativeBounds::usage =
  "ScopeGammaAdapterDerivativeBounds[s] replaces the ambiguous original-derivative key by explicitly scoped pointwise bounds for a Gamma/LogGamma special inverse adapter.";
Begin["`Private`"];
ScopeGammaAdapterDerivativeBounds[
    AsymptoticAnalysis`GeneralizedSeries[a_Association]] := Module[
  {family, x, scale, b, domain, magnitude, updated},
  family = Lookup[a, "Adapter", None];
  If[Lookup[a, "Kind", None] =!= "SpecialInverse" ||
      ! MemberQ[{"Gamma", "LogGamma"}, family] ||
      ! MatchQ[Lookup[a, "Variables", {}], {_Symbol, _Symbol}] ||
      ! And @@ (KeyExistsQ[a, #] & /@
        {"TargetScale", "Function", "Assumptions", "SourceDomain"}),
    Return[Failure["UnsupportedAuditAdapter", <|
      "MessageTemplate" -> "Use an existing package-created Gamma or LogGamma special-inverse adapter."|>]]];
  x = First[a["Variables"]]; scale = a["TargetScale"];
  b = Log[x] - 1/(2 x) - 1/(12 x^2);
  domain = a["Assumptions"] && a["SourceDomain"] && x > 2;
  magnitude = Abs[scale] If[family === "Gamma", Gamma[x], 1] b;
  updated = Join[KeyDrop[a, {"OriginalDerivativeLowerBound"}], <|
    "TransformedDerivativeLowerBound" -> b,
    "DerivativeBoundContract" -> <|
      "Type" -> "PointwiseMagnitudeLowerBound",
      "Function" -> a["Function"], "Variable" -> x,
      "Domain" -> domain, "LowerBound" -> magnitude,
      "DerivativeSign" -> Sign[scale],
      "TransformedFunction" -> LogGamma[x],
      "TransformedDerivativeLowerBound" -> b,
      "Scope" -> "Pointwise in the original source variable. An interval lower bound requires a separately verified infimum over that interval.",
      "Reference" -> "https://dlmf.nist.gov/5.9.E15"|>|>];
  AsymptoticAnalysis`GeneralizedSeries[updated]
];
ScopeGammaAdapterDerivativeBounds[___] := Failure[
  "InvalidArguments", <|"MessageTemplate" -> "Supply one package-created special-inverse object."|>];
End[];
EndPackage[];
