#!/usr/bin/env wolframscript
root = DirectoryName[$InputFileName];
Print["Kernel: ", $Version];
report = TestReport[FileNameJoin[{root, "RealInverseAsymptotics.wlt"}]];
Print[report];
Print["Succeeded: ", report["TestsSucceededCount"]];
Print["Failed: ", report["TestsFailedCount"]];
Export[FileNameJoin[{root, "wolfram-test-report.txt"}],
 ToString[{$Version, report}, InputForm], "Text"];
Exit[If[report["TestsFailedCount"] == 0, 0, 1]];
