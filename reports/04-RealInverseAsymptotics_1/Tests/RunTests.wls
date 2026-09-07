#!/usr/bin/env wolframscript
report = TestReport[FileNameJoin[{DirectoryName[$InputFileName], "RealInverseAsymptotics.wlt"}]];
Print[report];
Exit[If[report["TestsFailedCount"] == 0, 0, 1]];
