(* Not executed during authoring. Usage:
   wolframscript -file code/run_focused.wl /path/to/AsymptoticAnalysis.wl *)
args = Rest[$ScriptCommandLine];
If[Length[args] =!= 1, Print["Supply one local package entry file."]; Exit[2]];
entry = ExpandFileName[First[args]];
tests = FileNameJoin[{DirectoryName[$InputFileName], "AbsGuardRegressions.wlt"}];
If[! FileExistsQ[entry] || ! FileExistsQ[tests], Print["Missing input file."]; Exit[2]];
Get[entry];
Print["Kernel: ", $Version, "; entry: ", entry];
report = TestReport[tests];
Print[report];
Exit[If[TrueQ[report["TestsFailedCount"] === 0 && report["TestsSucceededCount"] === 8], 0, 1]];
