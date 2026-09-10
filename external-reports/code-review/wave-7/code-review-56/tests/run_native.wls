(* Wolfram-script wrapper; not claimed to be a Mathics CLI wrapper. *)
root = Environment["ASYMPTOTIC_REPO"];
If[! StringQ[root] || root === "" || ! DirectoryQ[root],
  Print["Set ASYMPTOTIC_REPO to a local pinned checkout."]; Exit[2]];
distribution = FileNameJoin[{root, "AsymptoticAnalysis.wl"}];
If[! FileExistsQ[distribution], Print["Standalone distribution not found."]; Exit[2]];
Get[distribution];
Get[FileNameJoin[{DirectoryName[$InputFileName], "package_probes.wl"}]];
(* Zero means observations were printed, not that the package passed a suite. *)
Exit[0];
