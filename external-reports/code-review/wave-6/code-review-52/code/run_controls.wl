(* Reproduce the 42-case numerical diagnostic screen. Wolfram 15 run completed
   in this audit. This is a HEURISTIC, not an interval certificate or proof.
   Set $AuditPackage as in reproduce.wl. Use a fresh kernel. *)
If[! StringQ[$AuditPackage], $AuditPackage = Environment["ASYMPTOTIC_PACKAGE"]];
If[! StringQ[$AuditPackage] || ! FileExistsQ[$AuditPackage],
  Print["Set $AuditPackage or ASYMPTOTIC_PACKAGE to a local package file."]; Abort[]];
Get[$AuditPackage];
Clear[AuditControl`x];
AuditControl`germs = With[{x = AuditControl`x},
  {x + x^2 Log[x], x^2 + x^3 Log[x], x + x^(3/2),
   x^(1/2) + x Log[x], x + x^2 Log[x]^2, x - x^3}];
AuditControl`functions = Flatten[Table[
  {Exp[g], Sin[g], Cos[g], Log[1 + g], (1 + g)^(1/3), (1 + g)^(-3), g^2},
  {g, AuditControl`germs}]];
AuditControl`results = Table[
  Module[{r, e, bound, values},
    r = TimeConstrained[AsymptoticAnalysis`AsymptoticExpansion[
      f, {AuditControl`x, 0, 3}, "Backend" -> "Package"], 2, $Aborted];
    If[Head[r] =!= AsymptoticAnalysis`GeneralizedSeries,
      {"Refusal", f, r},
      e = Normal[r]; bound = r["RemainderScaleExpression"];
      If[r["Remainder"] === 0,
        {"Exact", f, TimeConstrained[FullSimplify[f - e, AuditControl`x > 0], 1, "Unresolved"]},
        values = Quiet[Table[N[(f - e)/bound /. AuditControl`x -> 10^(-k), 100],
          {k, {6, 12, 24}}]];
        {"BoundedCheck", f, values}]]],
  {f, AuditControl`functions}];
AuditControl`flags = Select[AuditControl`results,
  First[#] === "BoundedCheck" && VectorQ[Last[#], NumericQ] &&
    Abs[Last[Last[#]]] > 1000 Max[1, Abs[First[Last[#]]]] &];
Print[InputForm[{"Runtime", $Version, "Cases", Length[AuditControl`results],
  "Categories", Tally[First /@ AuditControl`results], "RatioFlags", AuditControl`flags}]];
If[StringQ[$AuditOutput],
  Export[$AuditOutput, ToString[AuditControl`results, InputForm], "Text"]];
AuditControl`results
