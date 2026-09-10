(* Focused diagnostic runner. Not the upstream suite.
   In a fresh Wolfram or Mathics session:
     $AuditPackage = "/absolute/path/to/AsymptoticAnalysis.wl";
     $AuditMode = "Baseline";  (* or "MergeOnly", "Candidate" *)
     Get["/absolute/path/to/code/run_condition_probes.wl"];
   The selected mechanisms were tested separately in Wolfram 15; this complete
   assembled runner has not been executed. Mathics execution is not claimed. *)
If[! StringQ[$AuditPackage] || ! MemberQ[{"Baseline", "MergeOnly", "Candidate"}, $AuditMode],
  Print["Set $AuditPackage to an existing package file and $AuditMode to Baseline, MergeOnly, or Candidate."];
  Abort[]];
Get[$AuditPackage];
If[Length[DownValues[AsymptoticAnalysis`AsymptoticExpansion]] == 0,
  Print["Package entry point did not load."]; Abort[]];
Clear[auditX, auditA, auditB, auditCheck, auditRecord, auditCount, auditProfile];
auditRecords = {};
auditCheck[id_, actual_, expected_] := AppendTo[auditRecords,
  <|"ID" -> id, "Actual" -> actual, "Expected" -> expected, "Passed" -> SameQ[actual, expected]|>];
auditCount[s_] := If[Head[s] === AsymptoticAnalysis`GeneralizedSeries,
  Count[s["TargetDomain"], HoldPattern[auditX > 0], {0, Infinity}], Missing["NoSeries"]];
auditS0 = AsymptoticAnalysis`AsymptoticExpansion[auditX, {auditX, 0, 3}, "Backend" -> "Package"];
auditZero = AsymptoticAnalysis`AsymptoticExpansion[0, {auditX, 0, 3}, "Backend" -> "Package"];
If[Head[auditS0] =!= AsymptoticAnalysis`GeneralizedSeries ||
   Head[auditZero] =!= AsymptoticAnalysis`GeneralizedSeries,
  Print["Baseline constructor precondition failed."]; Abort[]];
auditProfile[operation_] := Module[{value = auditS0},
  Table[value = operation[value]; {Normal[value], auditCount[value]}, {4}]];
auditFixed = auditProfile[AsymptoticAnalysis`SeriesAdd[#, auditZero] &];
auditScalar = auditProfile[AsymptoticAnalysis`SeriesAdd[#, 0] &];
auditProduct = auditProfile[AsymptoticAnalysis`SeriesMultiply[#, 1] &];
auditExpectedFixed = Switch[$AuditMode,
  "Baseline", {3, 7, 15, 31}, "MergeOnly", {2, 3, 4, 5}, "Candidate", {1, 1, 1, 1}];
auditExpectedScalar = Switch[$AuditMode,
  "Baseline", {3, 9, 27, 81}, "MergeOnly", {2, 4, 8, 16}, "Candidate", {1, 1, 1, 1}];
(* Baseline scalar multiplication and fixed-operand merge-only counts are
   source-derived expectations; the baseline observations file does not
   falsely label these particular cells as measured. *)
auditCheck["fixed-zero-expressions", auditFixed[[All, 1]], Table[auditX, {4}]];
auditCheck["fixed-zero-conditions", auditFixed[[All, 2]], auditExpectedFixed];
auditCheck["scalar-zero-expressions", auditScalar[[All, 1]], Table[auditX, {4}]];
auditCheck["scalar-zero-conditions", auditScalar[[All, 2]], auditExpectedScalar];
auditCheck["scalar-one-expressions", auditProduct[[All, 1]], Table[auditX, {4}]];
auditCheck["scalar-one-conditions", auditProduct[[All, 2]], auditExpectedScalar];
auditP = AsymptoticAnalysis`AsymptoticExpansion[auditA auditX,
  {auditX, 0, 3}, Assumptions -> auditA > 0, "Backend" -> "Package"];
auditQ = AsymptoticAnalysis`AsymptoticExpansion[auditB auditX,
  {auditX, 0, 3}, Assumptions -> auditB > 0, "Backend" -> "Package"];
auditNegative = AsymptoticAnalysis`AsymptoticExpansion[auditA auditX,
  {auditX, 0, 3}, Assumptions -> auditA < 0, "Backend" -> "Package"];
auditJoined = AsymptoticAnalysis`SeriesAdd[auditP, auditQ];
auditCheck["joint-expression", Expand[Normal[auditJoined] - (auditA + auditB) auditX], 0];
(* Membership is checked structurally, without asking a solver to infer it. *)
auditCheck["retain-left-condition", ! FreeQ[auditJoined["Assumptions"], HoldPattern[auditA > 0]], True];
auditCheck["retain-right-condition", ! FreeQ[auditJoined["Assumptions"], HoldPattern[auditB > 0]], True];
auditCheck["contradictory-conditions-rejected",
  MatchQ[AsymptoticAnalysis`SeriesAdd[auditP, auditNegative], Failure["IncompatibleDomains", _Association]], True];
auditFailures = Select[auditRecords, ! TrueQ[#["Passed"]] &];
auditResult = <|"Kernel" -> $Version, "Mode" -> $AuditMode,
  "Records" -> auditRecords, "FailureCount" -> Length[auditFailures],
  "EvidenceScope" -> "Focused condition propagation; not upstream-suite acceptance."|>;
Print[InputForm[auditResult]];
auditResult
