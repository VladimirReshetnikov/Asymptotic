#!/usr/bin/env wolframscript
root = DirectoryName[DirectoryName[$InputFileName]];
Print["Kernel: ", $Version];
report = TestReport[FileNameJoin[{root,"Tests","RealInverseAsymptotics.wlt"}]];
Print[report];
succeeded = report["TestsSucceededCount"];
failed = report["TestsFailedCount"];
Print["Succeeded: ", succeeded];
Print["Failed: ", failed];
If[IntegerQ[succeeded] && succeeded > 0 && TrueQ[failed == 0],
 Exit[0], Exit[1]];
