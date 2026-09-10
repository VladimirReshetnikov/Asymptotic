(* Pure string transformation of a standalone package before it is loaded.
   Use $AuditPatchDirectory to point to this code directory, and set
   $AuditStandaloneText to an inspected baseline standalone source string. *)
If[! ValueQ[$AuditPatchDirectory], $AuditPatchDirectory = DirectoryName[$InputFileName]];
$AuditPatchSpecification = Import[FileNameJoin[{$AuditPatchDirectory, "native_boundary_patch.json"}], "RawJSON"];
AuditPatchedStandalone[text_String, spec_Association] := Module[
  {result = text, old, new, expected, marker, additions},
  If[StringContainsQ[result, "$nativeBoundaryExpansionDefaults ="],
    Return[Failure["AlreadyPatched", <||>], Module]];
  Do[
    old = edit["old"]; expected = edit["count"];
    If[StringCount[result, old] =!= expected,
      Return[Failure["AnchorMismatch", <|"Anchor" -> old,
        "Expected" -> expected, "Actual" -> StringCount[result, old]|>], Module]],
    {edit, spec["replacements"]}];
  result = StringReplace[result, (# ["old"] -> # ["new"] &) /@ spec["replacements"]];
  marker = "(* END SOURCE: src/Kernel/NativeCompatibility.wl *)";
  If[StringCount[result, marker] =!= 1,
    Return[Failure["StandaloneMarkerMismatch", <||>], Module]];
  StringReplace[result, marker -> (spec["append"] <> "\n" <> marker)]];
