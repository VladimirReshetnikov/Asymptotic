(* UNRUN convenience driver. Run in a fresh kernel:
   wolframscript -file run_focused.wl /path/to/package.wl
   TestReport output is printed. This is NOT the upstream full-suite runner. *)
If[Length[$ScriptCommandLine] < 2, Print["Supply a local package path."]; Exit[2]];
packagePath = Last[$ScriptCommandLine];
If[! FileExistsQ[packagePath], Print["Package file not found."]; Exit[2]];
base = DirectoryName[$InputFileName];
testPath = FileNameJoin[{base,"TaylorIngressRegressions.wlt"}];
If[! FileExistsQ[testPath] || FileByteCount[testPath] == 0,
 Print["The explicitly named regression file is missing or empty."]; Exit[2]];
Get[packagePath];
If[Length[DownValues[AsymptoticAnalysis`AsymptoticExpansion]] == 0,
 Print["Package did not load."]; Exit[2]];
report = TestReport[testPath];
Print[report];
Print["Only TaylorIngressRegressions.wlt was selected. Inspect all results; this driver does not assert acceptance."];
