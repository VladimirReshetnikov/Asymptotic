(* This wrapper and complete suite remain unexecuted in the audit environment. *)
dir = DirectoryName[$InputFileName];
Get[FileNameJoin[{dir, "load_pinned.wl"}]];
report = TestReport[FileNameJoin[{dir, "regressions.wlt"}]];
Print[report];
