(* Usage: set ASYMPTOTIC_REPO to a local checkout, then
     wolframscript -file code/run_native.wls
   No download, installation, source editing, or upstream writes occur.
   Native results do not exist until this script is actually run. *)
ClearAll["Global`*"];
If[MemberQ[$Packages,"AsymptoticInverse`"],Print["Use a fresh kernel."];Exit[2]];
auditRoot=DirectoryName[DirectoryName[$InputFileName]];
repo=Environment["ASYMPTOTIC_REPO"];
If[! StringQ[repo] || ! DirectoryQ[repo],Print["Set ASYMPTOTIC_REPO to a local repository checkout."];Exit[2]];
kernel=FileNameJoin[{repo,"AsymptoticInverse","Kernel","AsymptoticInverse.wl"}];
If[! FileExistsQ[kernel],Print["Canonical package entry point not found."];Exit[2]];
sourceFiles=Sort[FileNames["*.wl",DirectoryName[kernel]]];
hashes=Association@Table[file->IntegerString[FileHash[file,"SHA256"],16,64],{file,sourceFiles}];
commit=Quiet[Check[RunProcess[{"git","-C",repo,"rev-parse","HEAD"},"StandardOutput"],"Unavailable"]];
Get[kernel];
If[! MemberQ[$Packages,"AsymptoticInverse`"],Print["Package loading did not establish its context."];Exit[2]];
probes=Get[FileNameJoin[{auditRoot,"code","baseline_probes.wl"}]];
records=Table[
 Block[{$MessageList={}},
  timed=AbsoluteTiming[TimeConstrained[MemoryConstrained[ReleaseHold[Last[probe]],
    1024^3,Failure["MemoryLimit",<||>]],60,Failure["TimeLimit",<||>]]];
  <|"ID"->First[probe],"Seconds"->First[timed],
    "ResultInputForm"->ToString[Last[timed],InputForm],
    "Messages"->(ToString[#,InputForm]& /@ $MessageList)|>],{probe,probes}];
Get[FileNameJoin[{auditRoot,"code","AuditExtensions.wl"}]];
report=TestReport[FileNameJoin[{auditRoot,"code","native_regressions.wlt"}]];
output=<|"Evidence"->"Observed local native execution; not the upstream full suite",
 "Version"->$Version,"SystemID"->$SystemID,"LocalCommit"->StringTrim[commit],
 "ReferenceCommit"->"921387e5ba1239bfda96e63e64e89bf63d9c41e6",
 "SourceSHA256"->hashes,"Probes"->records,
 "PrototypeTestsRun"->report["TestsRunCount"],
 "PrototypeTestsSucceeded"->report["TestsSucceededCount"],
 "PrototypeTestsFailed"->report["TestsFailedCount"]|>;
outputPath=FileNameJoin[{auditRoot,"evidence","native_observations.json"}];
written=Quiet[Check[Export[outputPath,output,"RawJSON"],$Failed]];
Export[FileNameJoin[{auditRoot,"evidence","native_test_report.txt"}],ToString[report,InputForm],"Text"];
If[written===$Failed || ! FileExistsQ[outputPath],Print["Native report export failed."];Exit[3]];
If[! IntegerQ[report["TestsRunCount"]] || report["TestsRunCount"]==0 || report["TestsFailedCount"]>0,
 Print["One or more prototype regressions failed; inspect the report."];Exit[1]];
Print[outputPath];Exit[0];
