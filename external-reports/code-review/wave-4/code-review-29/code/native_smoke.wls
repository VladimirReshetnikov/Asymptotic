(* Fresh-kernel characterization. Original audit observations are in
   results/native-observations.json. This script is a reusable reconstruction,
   not a transcript of an executed file. No remote download is performed here. *)
source = Environment["ASYMPTOTIC_AUDIT_SOURCE"];
If[!StringQ[source] || !FileExistsQ[source],
  Print["Set ASYMPTOTIC_AUDIT_SOURCE to the pinned standalone package file."]; Exit[2]];
Get[source];
Clear[x];
s = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 4}, "Backend" -> "Package"];
Print[InputForm[<|"Kernel" -> $Version, "SourceBytes" -> FileByteCount[source],
  "Expression" -> Normal[s], "Remainder" -> s["Remainder"],
  "NativeTwoSidedSign" -> Limit[Sign[x], x -> 0],
  "NativeAutomaticSign" -> Limit[Sign[x], x -> 0, Direction -> Automatic],
  "NativeFromBelowSign" -> Limit[Sign[x], x -> 0, Direction -> 1],
  "NativeFromAboveSign" -> Limit[Sign[x], x -> 0, Direction -> -1],
  "LimitOptions" -> Options[Limit]|>]];
