(* Fresh-kernel probe for the actual upstream proof helpers.
   Set $AuditRepositoryRoot to a PINNED checkout. Do not run concurrently with
   another query in the same kernel: helper bodies are temporarily instrumented.
   The Mathics runner itself remains untested in this review. *)
If[! StringQ[$AuditRepositoryRoot] || ! DirectoryQ[$AuditRepositoryRoot],
  Print["Set $AuditRepositoryRoot to the pinned Asymptotic checkout."]; Abort[]];
If[! IntegerQ[$AuditMaximumN], $AuditMaximumN = 6];
If[$AuditMaximumN < 0 || $AuditMaximumN > 12, Print["Use MaximumN in 0..12."]; Abort[]];
If[StringContainsQ[$Version, "Mathics"],
 Get[FileNameJoin[{$AuditRepositoryRoot, "AsymptoticAnalysis.wl"}]],
 Block[{$ContextPath = Prepend[$ContextPath, "AsymptoticAnalysis`Mathics`"]},
  Get[FileNameJoin[{$AuditRepositoryRoot, "src", "Kernel", "MathicsAssumptions.wl"}]]]];
Module[{calls = 0, rows, result, a, originalR, originalS,
  r = AsymptoticAnalysis`Mathics`mathicsRealProof,
  s = AsymptoticAnalysis`Mathics`mathicsSignProof},
 originalR = DownValues[r]; originalS = DownValues[s];
 If[originalR === {} || originalS === {}, Print["Proof helpers did not load."]; Abort[]];
 Scan[(DownValues[#] = DownValues[#] /.
    HoldPattern[RuleDelayed[lhs_, rhs_]] :> RuleDelayed[lhs, (calls++; rhs)]) &, {r, s}];
 rows = CheckAbort[
   Table[calls = 0;
    result = System`TimeConstrained[r[Nest[Cosh[#]^2 &, a, n], {{}, {}}, 24],
      20, "TimedOut"];
    {n, result, calls}, {n, 0, $AuditMaximumN}],
   DownValues[r] = originalR; DownValues[s] = originalS; Abort[]];
 DownValues[r] = originalR; DownValues[s] = originalS;
 Print[{$Version, rows}]];
