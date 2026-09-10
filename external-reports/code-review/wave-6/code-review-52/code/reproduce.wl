(* Audit regression runner. Use a FRESH kernel.
   $AuditPackage = "/absolute/path/to/AsymptoticAnalysis.wl";
   Get["/absolute/path/to/reproduce.wl"];
   Or set environment ASYMPTOTIC_PACKAGE before running the script.
   The output is observations, not automatic proof of all package contracts.
   This file is intended for Wolfram 15 and Mathics3; Mathics execution has
   NOT been performed in this audit. No network access is required here. *)

If[! StringQ[$AuditPackage], $AuditPackage = Environment["ASYMPTOTIC_PACKAGE"]];
If[! StringQ[$AuditPackage] || ! FileExistsQ[$AuditPackage],
  Print["Set $AuditPackage or ASYMPTOTIC_PACKAGE to a local package file."]; Abort[]];
Get[$AuditPackage];
Clear[Audit`record, Audit`summary, Audit`x, Audit`y, Audit`z, Audit`a];
$AuditResults = {};
Audit`summary[r_AsymptoticAnalysis`GeneralizedSeries] :=
  {"Series", Normal[r], r["Remainder"], r["Variable"]};
Audit`summary[r_] := r;
SetAttributes[Audit`record, HoldRest];
Audit`record[label_, expression_] := Module[{r},
  r = Quiet[TimeConstrained[expression, 30, $Aborted]];
  AppendTo[$AuditResults, {label, Audit`summary[r]}];
  Print[InputForm[Last[$AuditResults]]]; r];
Print[InputForm[{"Runtime", $Version, $SystemID}]];

Audit`record["N1/native-Series-rejects-Pi",
  Series[1/(1 + Pi), {Pi, 0, 3}]];
Audit`record["N1/forward-Pi",
  AsymptoticAnalysis`AsymptoticExpansion[1/(1 + Pi), {Pi, 0, 3}, "Backend" -> "Package"]];
Audit`record["N1/inverse-target-Pi",
  AsymptoticAnalysis`AsymptoticInverse[Audit`x + Audit`x^2, {Audit`x, 0}, {Pi, 3}]];
Audit`record["N1/control-user-context-Pi",
  AsymptoticAnalysis`AsymptoticExpansion[1/(1 + AuditVars`Pi),
    {AuditVars`Pi, 0, 3}, "Backend" -> "Package"]];
Audit`record["control/sine",
  AsymptoticAnalysis`AsymptoticExpansion[Sin[Audit`x], {Audit`x, 0, 5}, "Backend" -> "Package"]];

Audit`fourier = Audit`record["setup/Fourier",
  AsymptoticAnalysis`AsymptoticFourierInverse[
    Audit`x + Audit`x^2 Sin[Log[Audit`x]], {Audit`x, 0}, {Audit`y, 3}]];
If[Head[Audit`fourier] === AsymptoticAnalysis`GeneralizedSeries,
  Audit`record["N2/option-only",
    AsymptoticAnalysis`FourierInverseResidual[Audit`fourier, "MaxTerms" -> 1000]];
  Audit`record["N2/explicit-Automatic",
    AsymptoticAnalysis`FourierInverseResidual[Audit`fourier, Automatic, "MaxTerms" -> 1000]];
  Audit`record["N2/nested-options",
    AsymptoticAnalysis`FourierInverseResidual[Audit`fourier, {{"MaxTerms" -> 1000}}]];
  Audit`optionEvaluations = 0;
  Audit`record["N2/delayed-option",
    AsymptoticAnalysis`FourierInverseResidual[Audit`fourier,
      "MaxTerms" :> (Audit`optionEvaluations++; 1000)]];
  Audit`record["N2/delayed-evaluation-count", Audit`optionEvaluations];
];

Audit`input = Audit`record["setup/reciprocal",
  AsymptoticAnalysis`AsymptoticExpansion[1/Audit`x, {Audit`x, 0, 3}, "Backend" -> "Package"]];
If[Head[Audit`input] === AsymptoticAnalysis`GeneralizedSeries,
  Audit`record["N3/plain-exponential",
    AsymptoticAnalysis`SeriesObservable[Audit`input, Exp[Audit`z], Audit`z]];
  Audit`wrapped = Audit`record["N3/true-condition",
    AsymptoticAnalysis`SeriesObservable[Audit`input,
      ConditionalExpression[Exp[Audit`z], Audit`z > 0], Audit`z]];
  Audit`record["N3/false-condition",
    AsymptoticAnalysis`SeriesObservable[Audit`input,
      ConditionalExpression[Exp[Audit`z], Audit`z < 0], Audit`z]];
  If[Head[Audit`wrapped] === AsymptoticAnalysis`GeneralizedSeries,
    Audit`record["N3/retained-recipe", Audit`wrapped["SeriesRecipe"][[{1, 3, 4}]]]];
];

(* Optional persistence; plain text avoids reliance on JSON exporters. *)
If[StringQ[$AuditOutput],
  Export[$AuditOutput, ToString[$AuditResults, InputForm], "Text"]];
$AuditResults
