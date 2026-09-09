(* wolframscript -file Tests/RunTests.wl *)
report = TestReport[FileNameJoin[{DirectoryName[$InputFileName],
  "RealInverseAsymptotics.wlt"}]];
Print[report];
Print["Wolfram kernel: ", $Version];
If[TrueQ[report["TestsFailedCount"] == 0], Exit[0], Exit[1]];
