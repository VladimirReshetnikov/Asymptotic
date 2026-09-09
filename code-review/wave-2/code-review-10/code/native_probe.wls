(* Run in a FRESH native kernel:
   wolframscript -file code/native_probe.wls /path/to/AsymptoticInverse.wl
   wolframscript -file code/native_probe.wls /path/to/AsymptoticInverse.wl --patched
   The optional patch modifies only a temporary working copy. *)
Module[{args, source, here, text, spec, patched, tmp, checks, report, output, mode},
  args = Rest[$ScriptCommandLine]; here = DirectoryName[$InputFileName];
  If[Length[args] < 1, Print["Supply the pinned standalone file path; optional --patched."]; Exit[2]];
  source = ExpandFileName[First[args]];
  If[!FileExistsQ[source], Print["Input file not found: ", source]; Exit[2]];
  patched = MemberQ[args, "--patched"];
  text = Import[source, "Text"];
  If[!StringQ[text], Print["Cannot read source text."]; Exit[2]];
  spec = Import[FileNameJoin[{here, "patch_spec.json"}], "RawJSON"];
  If[patched,
    Do[Do[
      If[StringCount[text, edit["before"]] =!= 1,
        Print["Source anchor mismatch for ", patch["id"], "; no package loaded."]; Exit[2]];
      text = StringReplace[text, edit["before"] -> edit["after"]],
      {edit, patch["edits"]}], {patch, spec["patches"]}]];
  tmp = CreateTemporary[]; Export[tmp, text, "Text"]; Get[tmp];
  Get[FileNameJoin[{here, "regression_checks.wl"}]];
  checks = AsymptoticAudit`RunChecks[];
  report = <|"KernelVersion" -> $Version, "SystemID" -> $SystemID,
    "ExpectedSnapshot" -> spec["snapshot"],
    "InputFile" -> source, "InputSHA256" -> FileHash[source, "SHA256", "HexString"],
    "LoadedWorkingCopySHA256" -> FileHash[tmp, "SHA256", "HexString"],
    "SourceCaveat" -> "Caller-supplied source; compare its provenance with the pinned snapshot. This runner records hashes, not an independent Git commit verification.",
    "Mode" -> If[patched, "Two narrow in-memory patches", "Unmodified input"],
    "Checks" -> checks, "Passed" -> Count[Values[checks], True],
    "Total" -> Length[checks], "FullUpstreamSuiteRun" -> False|>;
  mode = If[patched, "patched", "baseline"];
  output = FileNameJoin[{DirectoryName[here], "evidence", "native_" <> mode <> "_rerun.json"}];
  Export[output, report, "RawJSON"]; Print[report]; Print["Wrote ", output];
  DeleteFile[tmp]; Exit[If[AllTrue[Values[checks], TrueQ], 0, 1]]
]
