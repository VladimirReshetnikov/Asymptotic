(* UNEXECUTED characterization, not an acceptance receipt.
   In a fresh kernel, set $AuditPackagePath to the absolute modular or
   standalone .wl path, then Get this file. Use a new process for candidate
   sources. No repository files are changed. Each observation prints raw
   InputForm output; reaching END does not mean a test passed. *)

If[! StringQ[$AuditPackagePath] || ! FileExistsQ[$AuditPackagePath],
  Print["Set $AuditPackagePath to an existing absolute package entry path."];
  Abort[]];
Print["AUDIT VERSION: ", $Version];
Print["AUDIT SYSTEM: ", $SystemID];
Print["AUDIT PACKAGE PATH: ", $AuditPackagePath];
Print["EXPECTED SOURCE REVISION: 8cee870994f506b501bae3ea6bd4a3a7edb895c1"];
Print["The source revision above is expected, NOT independently verified by this WL file."];
Get[$AuditPackagePath];
If[Length[DownValues[AsymptoticAnalysis`Private`certIntegerPower]] === 0,
  Print["Required certificate helper absent; stop."]; Abort[]];

ClearAll[auditObserve];
SetAttributes[auditObserve, HoldAll];
auditObserve[label_, body_] := Module[{value},
  Print["BEGIN OBSERVATION: ", label];
  value = System`TimeConstrained[body, 60, $Aborted];
  Print[ToString[value, InputForm]];
  Print["END OBSERVATION: ", label]];

Clear[x, y, a];
auditContext = <|"Bits" -> 48, "SeriesOrder" -> 2,
  "ExponentMagnitudeLimit" -> 10000|>;

auditObserve["N01 direct cube interval",
 AsymptoticAnalysis`Private`catch[
  AsymptoticAnalysis`Private`certIntegerPower[{-1/4, 1}, 3, auditContext]]];
auditObserve["N01 derivative interval",
 AsymptoticAnalysis`Private`catch[
  AsymptoticAnalysis`Private`certEnclose[1/16 + (x - 1)^3,
   x, {3/4, 2}, auditContext]]];
auditObserve["N01 inverse construction and preserved source",
 auditInverse = AsymptoticAnalysis`AsymptoticInverse[(x - 1)^4/4 + x/16,
   {x, 2/3}, {y, 3}, Direction -> "FromAbove"];
 {Head[auditInverse], auditInverse["Function"], auditInverse["Expression"]}];
auditObserve["N01 public certificate at exact center",
 AsymptoticAnalysis`InverseCertificate[auditInverse, 1/16,
  "Interval" -> {3/4, 2}, "Center" -> 1, "EnclosureOrder" -> 2,
  "MaxRefinements" -> 0, "RefineExpansion" -> False]];

If[StringContainsQ[$Version, "Mathics"],
 auditObserve["N02 held assumption rewrite",
  auditHeld = HoldComplete[Rule[Assumptions,
   If[Context[Unevaluated[System`Element]] === "System`", a > 0, a < 0]]];
  auditProtected = AsymptoticAnalysis`Private`mathicsProtectInputAssumptions[auditHeld];
  {auditHeld, auditProtected, Last[ReleaseHold[auditHeld]],
   Last[ReleaseHold[auditProtected]]}];
 auditObserve["N02 public inline assumption program",
  AsymptoticAnalysis`AsymptoticExpansion[Sqrt[a^2] + x, {x, 0, 2},
   Assumptions -> If[Context[Unevaluated[System`Element]] === "System`",
     a > 0, a < 0], "Backend" -> "Package"]];
 auditObserve["N02 real membership still protected",
  AsymptoticAnalysis`Private`mathicsProtectInputAssumptions[
   HoldComplete[Rule[Assumptions, System`Element[Sin[a], Reals]]]]];
 auditObserve["N03 actual Mathics primitive and helper characterization",
  auditQ1 = Sqrt[2] + Sqrt[3] - Sqrt[5 + 2 Sqrt[6] + 10^-30];
  auditQ2 = Sqrt[2] + Sqrt[3] - Sqrt[5 + 2 Sqrt[6] + 10^-40];
  {N[auditQ1], N[auditQ2],
   AsymptoticAnalysis`Private`mathicsNumericalSplitLog[
     {auditQ1, auditQ2, 10^-20}]}];
 auditObserve["N03 intended positive small-tail control",
  {AsymptoticAnalysis`Private`mathicsNumericalSplitLog[{Sqrt[Pi], 10^-20}],
   AsymptoticAnalysis`Private`mathicsNumericalN[Log[Sqrt[Pi] 10^-20], 60]}],
 Print["Mathics-only N02/N03 helpers not invoked on the official kernel."]];

auditObserve["N04 signed-power numerical metadata",
 auditPowerInverse = AsymptoticAnalysis`AsymptoticInverse[x, {x, 0}, {y, 4},
   Direction -> "FromBelow", "Power" -> 3];
 auditNumerical = AsymptoticAnalysis`InverseNumericalCheck[auditPowerInverse, -2,
   WorkingPrecision -> 50];
 {auditPowerInverse["Expression"], auditNumerical}];
Print["OBSERVATIONS COMPLETE. Inspect raw values, messages and aborts; no acceptance claim."];
