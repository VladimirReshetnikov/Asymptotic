(* Run with wolframscript -file Tests/run-tests.wls *)
report = TestReport[FileNameJoin[{DirectoryName[$InputFileName],
  "RealInverseAsymptotics.wlt"}]];
Print[report];
Print["Succeeded: ", report["TestsSucceededCount"]];
Print["Failed: ", report["TestsFailedCount"]];
If[report["TestsFailedCount"] === 0, Exit[0], Exit[1]];
