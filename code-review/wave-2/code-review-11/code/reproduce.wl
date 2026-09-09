(* Observation harness: baseline bugs are observations, NOT passing assertions.
   Equivalent expressions, rather than this packaged wrapper, were executed
   through the native connector. See evidence/native-observations.json. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "load_pinned.wl"}]];
ClearAll[AuditSummary, AuditEmit, AuditProbe];
AuditSummary[r_AsymptoticInverse`GeneralizedSeries] := KeyTake[r[[1]],
  {"Kind", "Expression", "Remainder", "RemainderScaleExpression", "Assumptions",
   "TargetDomain", "SourceDomain", "Exact"}];
AuditSummary[r_] := r;
AuditEmit[label_, value_] := Print[ExportString[<|"case" -> label,
  "result_inputform" -> ToString[value, InputForm]|>, "RawJSON"]];
SetAttributes[AuditProbe, HoldAll];
AuditProbe[label_, expression_] := AuditEmit[label,
  TimeConstrained[expression, 30, "HARNESS_TIME_LIMIT"]];
$Assumptions = True;
Clear[x, y, a, z, g];
AuditProbe["N01", Module[{s, clean, ambient},
  s = AsymptoticInverse`AsymptoticInverse[ConditionalExpression[x, x > 2],
    {x, Infinity}, {y, 2}];
  clean = AsymptoticInverse`InverseCertificate[s, 1, "Interval" -> {1/2, 3/2},
    "Center" -> 1, "MaxRefinements" -> 0];
  ambient = Assuming[x > 2, AsymptoticInverse`InverseCertificate[s, 1,
    "Interval" -> {1/2, 3/2}, "Center" -> 1, "MaxRefinements" -> 0]];
  <|"source" -> AuditSummary[s], "clean" -> clean,
    "ambient" -> If[AssociationQ[ambient], KeyTake[ambient,
      {"Certified", "RootEnclosure", "CertifiedSourceDomain", "SourceDomainVerified",
       "CertifiedFunction", "CertifiedTarget"}], ambient]|>]];
AuditProbe["N02", Module[{outer, inner, result},
  outer = AsymptoticInverse`AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 0];
  inner = AsymptoticInverse`AsymptoticExpansion[a, {a, 0, 4}];
  result = AsymptoticInverse`SeriesCompose[outer, inner];
  <|"outer" -> AuditSummary[outer], "inner" -> AuditSummary[inner],
    "composition" -> AuditSummary[result], "exact_diagonal" -> 1/2|>]];
AuditProbe["N03", Module[{result},
  g[t_?NumericQ] := If[TrueQ[t == 0], 0, t^2 Log[1 + Abs[Log[Abs[t]]]]];
  g'[0] = 0;
  result = AsymptoticInverse`AsymptoticExpansion[g[x], {x, 0, 2}];
  <|"derivative_at_zero" -> g'[0], "expansion" -> AuditSummary[result],
    "true_scaled_limit" -> Limit[Log[1 - Log[x]], x -> 0, Direction -> "FromAbove"]|>]];
AuditProbe["N04", Module[{base, direct, observed, scalar, inverse},
  base = AsymptoticInverse`AsymptoticExpansion[x, {x, 0, 3}, Assumptions -> a > 0];
  direct = AsymptoticInverse`AsymptoticExpansion[Sqrt[-a] + x, {x, 0, 2}, Assumptions -> a > 0];
  observed = AsymptoticInverse`SeriesObservable[base, z + Sqrt[-a], z];
  scalar = AsymptoticInverse`SeriesAdd[base, Sqrt[-a]];
  inverse = AsymptoticInverse`AsymptoticInverse[x + Sqrt[-a] x^2, {x, 0}, {y, 3}, Assumptions -> a > 0];
  <|"direct" -> AuditSummary[direct], "observable" -> AuditSummary[observed],
    "scalar_control" -> scalar, "inverse_control" -> inverse|>]];
