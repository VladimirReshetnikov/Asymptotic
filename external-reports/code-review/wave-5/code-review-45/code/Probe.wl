(* CHARACTERIZATION SCRIPT; NOT EXECUTED DURING THE REVIEW.
   In a fresh Wolfram/Mathics kernel:
   $AuditPackagePath = "/absolute/path/to/src/Kernel/AsymptoticAnalysis.wl";
   $AuditPatchPath = None;  (* or absolute path to ExactSeedCandidate.wl *)
   Get["/absolute/path/to/this/bundle/code/Probe.wl"];
   Do not load baseline and patched variants in the same session.
   This emits raw observations, NOT a passing acceptance receipt. *)
If[! ValueQ[$AuditPackagePath] || ! StringQ[$AuditPackagePath],
  Print["Set $AuditPackagePath before loading Probe.wl."],
  Print["RUNTIME ", $Version];
  Print["PACKAGE ", $AuditPackagePath];
  auditLoadResult = Get[$AuditPackagePath];
  If[ValueQ[$AuditPatchPath] && StringQ[$AuditPatchPath], Get[$AuditPatchPath]];
  ClearAll[auditX, auditY];
  auditObserve[label_, thunk_] := Module[{value},
    value = CheckAbort[thunk[], $Aborted];
    Print["CASE ", label, " => ", InputForm[value]]];
  If[StringContainsQ[$Version, "Mathics"],
    auditObserve["private-half", Function[{},
      AsymptoticAnalysis`Private`mathicsNumericalExactIntegerSeed[
        HoldComplete[2 auditX == 1], auditX, N[1/2, 60]]]];
    auditObserve["private-integer-control", Function[{},
      AsymptoticAnalysis`Private`mathicsNumericalExactIntegerSeed[
        HoldComplete[auditX == 1], auditX, N[1, 60]]]];
    auditObserve["private-near-not-equal", Function[{},
      AsymptoticAnalysis`Private`mathicsNumericalExactIntegerSeed[
        HoldComplete[2 auditX == 1], auditX, N[1/2 + 2^-100, 80]]]];
    auditObserve["private-inexact-equation", Function[{},
      AsymptoticAnalysis`Private`mathicsNumericalExactIntegerSeed[
        HoldComplete[2.0 auditX == 1], auditX, N[1/2, 60]]]]];
  auditObserve["identity-half-wp50", Function[{},
    Module[{s}, s = AsymptoticAnalysis`AsymptoticInverse[
      auditX, {auditX, 0}, {auditY, 3}, Direction -> "FromAbove"];
      If[Head[s] === Failure, s, AsymptoticAnalysis`InverseNumericalCheck[s, 1/2,
        WorkingPrecision -> 50]]]]];
  auditObserve["identity-integer-wp50", Function[{},
    Module[{s}, s = AsymptoticAnalysis`AsymptoticInverse[
      auditX, {auditX, 0}, {auditY, 3}, Direction -> "FromAbove"];
      If[Head[s] === Failure, s, AsymptoticAnalysis`InverseNumericalCheck[s, 1,
        WorkingPrecision -> 50]]]]];
  auditObserve["affine-half-wp50", Function[{},
    Module[{s}, s = AsymptoticAnalysis`AsymptoticInverse[
      2 auditX, {auditX, 0}, {auditY, 3}, Direction -> "FromAbove"];
      If[Head[s] === Failure, s, AsymptoticAnalysis`InverseNumericalCheck[s, 1,
        WorkingPrecision -> 50]]]]];
  auditObserve["source-domain-control", Function[{},
    Module[{s}, s = AsymptoticAnalysis`AsymptoticInverse[
      ConditionalExpression[auditX, auditX < 1/3], {auditX, 0}, {auditY, 3},
      Direction -> "FromAbove"];
      If[Head[s] === Failure, s, AsymptoticAnalysis`InverseNumericalCheck[s, 1/2,
        WorkingPrecision -> 50]]]]];
  Print["END CHARACTERIZATION; no automatic pass/fail claim"]
];
