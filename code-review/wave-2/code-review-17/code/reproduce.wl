(* SPDX-License-Identifier: MIT-0
   Invoke: wolframscript -file reproduce.wl /absolute/path/AsymptoticInverse.wl
   The loaded file must be the pinned baseline or regenerated patched build.
   This script performs focused probes, not the full repository test suite. *)
If[Length[$ScriptCommandLine] < 2,
  Print["Usage: wolframscript -file reproduce.wl /path/AsymptoticInverse.wl"];
  Exit[2]];
packagePath = Last[$ScriptCommandLine];
If[! FileExistsQ[packagePath], Print["Package not found: ", packagePath]; Exit[2]];
Get[packagePath];
Clear[x, y];
record = <|"Kernel" -> $Version, "Package" -> ExpandFileName[packagePath],
  "PackageSHA256" -> IntegerString[FileHash[packagePath, "SHA256"], 16, 64]|>;
s = Block[{$Assumptions = True},
  AsymptoticInverse`AsymptoticInverse[
    ConditionalExpression[x, x > 10], {x, Infinity}, {y, 3}]];
record["CertificateClean"] = Block[{$Assumptions = True},
  AsymptoticInverse`InverseCertificate[s, 2,
    "Interval" -> {1, 3}, "Center" -> 2, "MaxRefinements" -> 0]];
record["CertificateHostile"] = Block[{$Assumptions = x > 10},
  AsymptoticInverse`InverseCertificate[s, 2,
    "Interval" -> {1, 3}, "Center" -> 2, "MaxRefinements" -> 0]];
record["CertificateValid"] = Block[{$Assumptions = x > 10},
  AsymptoticInverse`InverseCertificate[s, 12,
    "Interval" -> {11, 13}, "Center" -> 12, "MaxRefinements" -> 0]];
a = AsymptoticInverse`AsymptoticFlatInverse[
  x + Exp[-1/x], {x, 0}, {y, 1}];
record["FlatProducts"] = Table[
  b = AsymptoticInverse`AsymptoticFlatInverse[
    x + Exp[-1/x], {x, 0}, {y, n}];
  c = AsymptoticInverse`FlatSeriesMultiply[a, b];
  <|"Depth" -> n, "Expression" -> Normal[c],
    "Remainder" -> c["Remainder"],
    "TailPair" -> c["FlatRepresentation"]["SectorTail"]|>, {n, 1, 3}];
record["NumericalResolution"] = AsymptoticInverse`InverseNumericalCheck[
  a, 1/1000, WorkingPrecision -> 50];
record["NativeZetaAsymptotic"] = Asymptotic[Zeta[x], x -> Infinity,
  SeriesTermGoal -> 3];
record["NativeZetaSeriesRaw"] = Series[Zeta[x], {x, Infinity, 3}];
record["NativeZetaSeriesNormal"] = Normal[record["NativeZetaSeriesRaw"]];
record["NativePowerLog"] = Series[x^x, {x, 0, 3}];
record["NativeClassicalInverse"] = InverseSeries[Series[x + x^2, {x, 0, 5}], y];
record["NativeIrrationalInverse"] = TimeConstrained[
  AsymptoticSolve[x + x^Sqrt[2] == y, {x, 0}, {y, 0, 3}, Reals],
  10, Missing["TimeLimit"]];
record["NativeFlatInverse"] = TimeConstrained[
  AsymptoticSolve[x + Exp[-1/x] == y, {x, 0}, {y, 0, 3}, Reals],
  10, Missing["TimeLimit"]];
record["PackageZeta"] = AsymptoticInverse`AsymptoticExpansion[
  Zeta[x], x -> Infinity, SeriesTermGoal -> 3];
Print[InputForm[record]];
output = FileNameJoin[{DirectoryName[ExpandFileName[$InputFileName]],
  "native-run-" <> DateString[{"Year", "Month", "Day", "-", "Hour", "Minute", "Second"}] <> ".wl"}];
Put[record, output];
Print["Saved: ", output];
