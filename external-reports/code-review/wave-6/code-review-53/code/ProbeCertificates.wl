(* Public and private characterization probes. UNRUN in this review.
   Start a fresh Wolfram 15 or Mathics3 kernel, then:
     auditRepository = "/absolute/path/to/Asymptotic";
     Get["/absolute/path/to/this/ProbeCertificates.wl"]
   Capture InputForm output. Do not mistake model test results for this run. *)
If[! StringQ[auditRepository],
  Print["Set auditRepository to the repository directory first."];
  Abort[]];
Get[FileNameJoin[{auditRepository, "src", "Kernel", "AsymptoticAnalysis.wl"}]];
Clear[auditX, auditY];
auditContext = <|"SeriesOrder" -> 2, "Bits" -> 48,
  "ExponentMagnitudeLimit" -> 10000|>;

SetAttributes[auditProbe, HoldRest];
auditProbe[id_, expression_] := Module[{value},
  value = expression;
  Print[InputForm[<|"ID" -> id, "Kernel" -> $Version, "Result" -> value|>]];
  value];

auditProbe["N01-private-power",
  AsymptoticAnalysis`Private`certIntegerPower[{-1/4, 1}, 3, auditContext]];
(* Baseline inferred from source: {-1/4,1}; candidate target: {-1/64,1}. *)
auditProbe["N01-private-derivative",
  AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`certEnclose[1 + 4 auditX^3,
      auditX, {-1/4, 1}, auditContext]]];
(* Baseline inferred: {0,5}; candidate target: {15/16,5}. *)

auditN01 = auditProbe["N01-public-construction",
  AsymptoticAnalysis`AsymptoticInverse[auditX + auditX^4,
    {auditX, -1/2}, {auditY, 3}, Direction -> "FromAbove"]];
If[MatchQ[auditN01, _AsymptoticAnalysis`GeneralizedSeries],
  auditProbe["N01-public-certificate",
    AsymptoticAnalysis`InverseCertificate[auditN01, 0,
      "Interval" -> {-1/4, 1}, "Center" -> 0,
      "EnclosureOrder" -> 2, "RefineExpansion" -> False,
      "MaxRefinements" -> 0]]];

auditProbe["N02-private-root-magnitude",
  AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`certEnclose[Sqrt[auditX], auditX,
      {2^39998, 2^40002}, auditContext]]];
(* Baseline inferred: CertificateResourceLimit. A root primitive avoids Exp. *)

auditN02 = auditProbe["N02-public-construction",
  AsymptoticAnalysis`AsymptoticInverse[Sqrt[auditX],
    {auditX, Infinity}, {auditY, 3}]];
If[MatchQ[auditN02, _AsymptoticAnalysis`GeneralizedSeries],
  auditProbe["N02-public-certificate",
    AsymptoticAnalysis`InverseCertificate[auditN02, 2^20000,
      "Interval" -> {2^39998, 2^40002}, "Center" -> 2^40000,
      "EnclosureOrder" -> 2, "RefineExpansion" -> False,
      "MaxRefinements" -> 0]]];

auditN03 = auditProbe["N03-public-construction",
  AsymptoticAnalysis`AsymptoticInverse[auditX + auditX^2,
    {auditX, 0}, {auditY, 3}, Direction -> "FromAbove"]];
If[MatchQ[auditN03, _AsymptoticAnalysis`GeneralizedSeries],
  auditProbe["N03-public-invariant-side-failure",
    AsymptoticAnalysis`InverseCertificate[auditN03, 1/10,
      "Interval" -> {-2, -1}, "Center" -> -3/2,
      "MaxRefinements" -> 6, "RefineExpansion" -> False]]];
(* The interval is deliberately on the wrong side. Baseline source predicts
   seven OutsideBranch attempts; a terminal arithmetic-failure policy needs one. *)
