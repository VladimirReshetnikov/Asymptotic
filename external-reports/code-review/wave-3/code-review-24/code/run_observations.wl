(* Reproducible observations, not an acceptance suite. Run in a fresh kernel.
   By default downloads exactly the reviewed revision. To inspect a staged
   candidate, set $AuditPackagePath to its local path before Get[this file].
   Optional $AuditOutputPath selects an output JSON; default is current directory.
   This complete runner was supplied but was not executed as a unit in the audit.
   Evidence records selected successful connector evaluations instead. *)
$auditRevision = "6687962f3c858a4f93623cfc496f33e35c6763d4";
If[! ValueQ[$AuditPackagePath],
  $AuditPackagePath = URLDownload[
    "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/" <>
      $auditRevision <> "/AsymptoticAnalysis.wl"]];
If[! StringQ[$AuditPackagePath] || ! FileExistsQ[$AuditPackagePath],
  Print["Package acquisition failed."]; Abort[]];
Get[$AuditPackagePath];
If[! ValueQ[$AuditOutputPath], $AuditOutputPath = FileNameJoin[{Directory[], "observations.json"}]];
Clear[x, y, ell];
auditSummary[r_] := Which[FailureQ[r],
  <|"FailureTag" -> r[[1]], "Result" -> ToString[r, InputForm]|>,
  MatchQ[r, AsymptoticAnalysis`GeneralizedSeries[_Association]],
  <|"Head" -> ToString[Head[r], InputForm], "Kind" -> r["Kind"],
    "Scale" -> ToString[r["Scale"], InputForm],
    "Normal" -> ToString[Normal[r], InputForm],
    "Remainder" -> ToString[r["Remainder"], InputForm]|>,
  True, <|"UnexpectedResult" -> ToString[r, InputForm]|>];
$auditResults = <|"Revision" -> $auditRevision, "Version" -> $Version,
  "SystemID" -> $SystemID, "Execution" -> "Focused observations only"|>;
$savedExpansionOptions = Options[AsymptoticAnalysis`AsymptoticExpansion];
$savedAliasOptions = Options[AsymptoticAnalysis`AsymptoticExpand];
Internal`WithLocalSettings[Null,
  SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Series"];
  AssociateTo[$auditResults, "N01-default-Series" -> auditSummary[
    AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}]]];
  AssociateTo[$auditResults, "N01-explicit-Series" -> auditSummary[
    AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"]]];
  SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Package"];
  AssociateTo[$auditResults, "N01-default-Package" -> auditSummary[
    AsymptoticAnalysis`AsymptoticExpansion[Exp[I x], {x, 0, 3}]]];
  AssociateTo[$auditResults, "N01-explicit-Package" -> auditSummary[
    AsymptoticAnalysis`AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Package"]]];
  SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> Automatic];
  SetOptions[AsymptoticAnalysis`AsymptoticExpand, "Backend" -> "Series"];
  AssociateTo[$auditResults, "N01-alias-default" -> auditSummary[
    AsymptoticAnalysis`AsymptoticExpand[Exp[x], {x, 0, 3}]]];,
  Options[AsymptoticAnalysis`AsymptoticExpansion] = $savedExpansionOptions;
  Options[AsymptoticAnalysis`AsymptoticExpand] = $savedAliasOptions;
];
Module[{key = "Backend", opts = {"Backend" -> "Series"}},
  AssociateTo[$auditResults, "N02-computed-key" -> auditSummary[
    AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}, key -> "Series"]]];
  AssociateTo[$auditResults, "N02-computed-container" -> auditSummary[
    AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}, opts]]];
];
Module[{s, product},
  s = AsymptoticAnalysis`AsymptoticExpansion[LerchPhi[1/2, 2, x^2],
      {x, Infinity, 5}, "Backend" -> "Package"];
  product = AsymptoticAnalysis`SeriesMultiply[s, x];
  AssociateTo[$auditResults, "N03-source" -> auditSummary[s]];
  AssociateTo[$auditResults, "N03-product" -> auditSummary[product]];
];
AssociateTo[$auditResults, "F01-private-helper" -> ToString[
  AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`fourierComposeBlock[
      {{1, {{0, 1}}}, {2, {{0, 1}}}}, 1, {{0, 1}}, 5, ell, True, 3, 1]], InputForm]];
Module[{s},
  s = AsymptoticAnalysis`AsymptoticFourierInverse[x + x^2, {x, 0}, {y, 7}, "MaxTerms" -> 7];
  AssociateTo[$auditResults, "F01-public-control" -> ToString[
    AsymptoticAnalysis`FourierInverseResidual[s], InputForm]];
];
Export[$AuditOutputPath, $auditResults, "RawJSON"]
