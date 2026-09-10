(* Local reproduction specification for a FRESH Wolfram/Mathics process.
   Set $AuditRepositoryRoot to a checkout of the pinned commit before Get.
   The native controls were executed via the connector; this local-path script
   and its Mathics execution have not independently been run in this session. *)
If[! StringQ[$AuditRepositoryRoot] || ! DirectoryQ[$AuditRepositoryRoot],
  Print["Set $AuditRepositoryRoot to the pinned Asymptotic checkout."]; Abort[]];
Get[FileNameJoin[{$AuditRepositoryRoot, "AsymptoticAnalysis.wl"}]];
If[Length[DownValues[AsymptoticAnalysis`AsymptoticExpansion]] === 0,
  Print["Package entry point did not load."]; Abort[]];
Module[{x, y, inputs, expected, rows, r, inv},
 inputs = {Exp[x], Sin[x], Log[1 + x], Sqrt[1 + x], 1/(1 - x), Exp[x + x^2]};
 expected = {1 + x + x^2/2 + x^3/6, x - x^3/6,
   x - x^2/2 + x^3/3, 1 + x/2 - x^2/8 + x^3/16,
   1 + x + x^2 + x^3, 1 + x + 3 x^2/2 + 7 x^3/6};
 rows = Table[
   r = System`TimeConstrained[
     AsymptoticAnalysis`AsymptoticExpansion[inputs[[k]], {x, 0, 4},
       "Backend" -> "Package"], 20, "TimedOut"];
   {k, Head[r] === AsymptoticAnalysis`GeneralizedSeries,
     TrueQ[Expand[Normal[r] - expected[[k]]] === 0]}, {k, Length[inputs]}];
 inv = System`TimeConstrained[
   AsymptoticAnalysis`AsymptoticInverse[x + x^2, {x, 0}, {y, 4}], 20, "TimedOut"];
 Print[{$Version, rows,
   {"InverseControl", Head[inv] === AsymptoticAnalysis`GeneralizedSeries,
    TrueQ[Expand[Normal[inv] - (y - y^2 + 2 y^3)] === 0]}}]];
