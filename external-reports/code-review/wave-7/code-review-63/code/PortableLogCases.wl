(* Load a baseline or candidate package first, then Get this file.
   The public calls below were exercised in Wolfram 15.0.0. The packaged
   script itself, and execution under Mathics3, require separate validation. *)
If[Length[DownValues[AsymptoticAnalysis`AsymptoticInverse]] == 0,
  Print["Load AsymptoticAnalysis.wl before this probe."]; Abort[]];
If[StringContainsQ[$Version, "Mathics"], $IterationLimit = 1000000];

AsymptoticAuditSummary[result_, root_] := If[AssociationQ[result],
  <|"Outcome" -> "Association", "Certified" -> result["Certified"],
    "ContainsKnownRoot" -> TrueQ[result["RootEnclosure"][[1]] <= root <=
       result["RootEnclosure"][[2]]],
    "CertifiedErrorBound" -> result["CertifiedErrorBound"]|>,
  <|"Outcome" -> ToString[Head[result], InputForm], "Result" -> result|>];

AsymptoticAuditLogCases[] := Module[{x, y, d = 2^-200, a, b, c, rows, ctx},
  a = AsymptoticAnalysis`AsymptoticInverse[Log[x], {x, 1}, {y, 3},
    Direction -> "FromBelow"];
  b = AsymptoticAnalysis`AsymptoticInverse[Log[1 + x], {x, 0}, {y, 3}];
  c = AsymptoticAnalysis`AsymptoticInverse[Log[1 + x], {x, 0}, {y, 3},
    Direction -> "FromBelow"];
  rows = {
    {"A: below-one argument", AsymptoticAuditSummary[
      AsymptoticAnalysis`InverseCertificate[a, Log[1 - d],
        "Interval" -> {1 - 2 d, 1 - d/2}, "Center" -> 1 - d,
        "EnclosureOrder" -> 2, "MaxRefinements" -> 0], 1 - d]},
    {"B: positive log1p", AsymptoticAuditSummary[
      AsymptoticAnalysis`InverseCertificate[b, Log[1 + d],
        "Interval" -> {d/2, 2 d}, "Center" -> d,
        "EnclosureOrder" -> 2, "MaxRefinements" -> 0], d]},
    {"C: negative log1p", AsymptoticAuditSummary[
      AsymptoticAnalysis`InverseCertificate[c, Log[1 - d],
        "Interval" -> {-2 d, -d/2}, "Center" -> -d,
        "EnclosureOrder" -> 2, "MaxRefinements" -> 0], -d]}
  };
  ctx = <|"SeriesOrder" -> 2, "Bits" -> 48,
    "ExponentMagnitudeLimit" -> 10000|>;
  <|"Version" -> $Version, "Cases" -> rows,
    "PointLog" -> AsymptoticAnalysis`Private`certLogPoint[1 - d, ctx],
    "AffineLog" -> AsymptoticAnalysis`Private`certLogExpression[
      1 + x, x, {d, d}, ctx]|>];

Print[InputForm[AsymptoticAuditLogCases[]]];
