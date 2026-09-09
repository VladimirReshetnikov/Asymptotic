(* Corrected-behavior specifications. Load the desired package BEFORE TestReport.
   The baseline is expected to fail the N1-hostile and N2-tail tests.
   This complete file has not been run as a suite in this audit. The exact
   witnesses and their patched controls were run individually. *)
Clear[auditX, auditY];
VerificationTest[
 Module[{s, r},
  s = Block[{$Assumptions = True},
    AsymptoticInverse`AsymptoticInverse[
      ConditionalExpression[auditX, auditX > 10],
      {auditX, Infinity}, {auditY, 3}]];
  r = Block[{$Assumptions = auditX > 10},
    AsymptoticInverse`InverseCertificate[s, 2,
      "Interval" -> {1, 3}, "Center" -> 2, "MaxRefinements" -> 0]];
  MatchQ[r, Failure["OutsideBranch", _Association]]], True,
 TestID -> "N1-hostile-domain-is-not-interval-evidence"]
VerificationTest[
 Module[{s, r},
  s = Block[{$Assumptions = True},
    AsymptoticInverse`AsymptoticInverse[
      ConditionalExpression[auditX, auditX > 10],
      {auditX, Infinity}, {auditY, 3}]];
  r = Block[{$Assumptions = auditX > 10},
    AsymptoticInverse`InverseCertificate[s, 12,
      "Interval" -> {11, 13}, "Center" -> 12, "MaxRefinements" -> 0]];
  AssociationQ[r] && TrueQ[r["Certified"]] && r["RootEnclosure"] === {12, 12}],
 True, TestID -> "N1-valid-control-retained"]
VerificationTest[
 Module[{a, b, p},
  a = AsymptoticInverse`AsymptoticFlatInverse[
    auditX + Exp[-1/auditX], {auditX, 0}, {auditY, 1}];
  Table[b = AsymptoticInverse`AsymptoticFlatInverse[
    auditX + Exp[-1/auditX], {auditX, 0}, {auditY, n}];
   p = AsymptoticInverse`FlatSeriesMultiply[a, b];
   p["FlatRepresentation"]["SectorTail"], {n, 1, 3}]],
 {{-1, 0}, {-1, 0}, {-1, 0}}, TestID -> "N2-boundary-projection-preserves-exponential-degree"]
VerificationTest[
 Module[{a, p}, a = AsymptoticInverse`AsymptoticFlatInverse[
    auditX + Exp[-1/auditX], {auditX, 0}, {auditY, 1}];
  p = AsymptoticInverse`FlatSeriesMultiply[a, 0];
  {Normal[p], p["Remainder"]}], {0, 0}, TestID -> "N2-exact-zero-annihilation"]
VerificationTest[
 Module[{a, r}, a = AsymptoticInverse`AsymptoticFlatInverse[
    auditX + Exp[-1/auditX], {auditX, 0}, {auditY, 1}];
  r = AsymptoticInverse`InverseNumericalCheck[a, 1/1000, WorkingPrecision -> 50];
  (* This records inadequate resolution, NOT a mathematically exact zero. *)
  AssociationQ[r] && Accuracy[r["Ratio"]] < 0], True,
 TestID -> "N3-baseline-resolution-sentinel"]
VerificationTest[
 {Asymptotic[Zeta[auditX], auditX -> Infinity, SeriesTermGoal -> 3],
  Normal[Series[Zeta[auditX], {auditX, Infinity, 3}]]},
 ConstantArray[1 + 2^(-auditX) + 3^(-auditX), 2],
 TestID -> "N4-version-specific-native-Zeta-capability"]
