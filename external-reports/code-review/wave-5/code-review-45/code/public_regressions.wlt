(* DESIRED-CONTRACT MUnit tests; native and Mathics integration UNRUN.
   Load the package first. On Mathics, use a suitable supported test runner.
   Baseline Mathics failures are expected for the rational-root cases. *)
ClearAll[auditX, auditY];
auditMake[f_] := AsymptoticAnalysis`AsymptoticInverse[
  f, {auditX, 0}, {auditY, 3}, Direction -> "FromAbove"];
auditRootAt[f_, t_] := Module[{s = auditMake[f], result},
  If[Head[s] === Failure, Return[s]];
  result = AsymptoticAnalysis`InverseNumericalCheck[s, t, WorkingPrecision -> 50];
  If[AssociationQ[result], result["ReferenceRoot"], result]];
VerificationTest[TrueQ[auditRootAt[auditX, 1] == 1], True,
  TestID -> "integer-control"];
VerificationTest[TrueQ[auditRootAt[auditX, 1/2] == 1/2], True,
  TestID -> "dyadic-half-identity"];
VerificationTest[TrueQ[auditRootAt[auditX, 3/8] == 3/8], True,
  TestID -> "dyadic-three-eighths"];
VerificationTest[TrueQ[auditRootAt[2 auditX, 1] == 1/2], True,
  TestID -> "affine-target-scale-invariance"];
VerificationTest[Head[auditRootAt[auditX, -1/2]], Failure,
  TestID -> "target-side-preserved"];
VerificationTest[Head[auditRootAt[ConditionalExpression[auditX, auditX < 1/3], 1/2]],
  Failure, TestID -> "source-condition-preserved"];
