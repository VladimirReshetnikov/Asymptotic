(* Usage: set ASYMPTOTIC_PACKAGE to the reviewed modular core or standalone
   file. Optionally set ASYMPTOTIC_AUDIT_SUITE=Proposed (or All).
   Then run: wolframscript -file tests/RunAudit.wls
   Baseline+Support is the default. No network fetches or repository writes. *)
root=DirectoryName[DirectoryName[$InputFileName]];
package=Environment["ASYMPTOTIC_PACKAGE"];
If[!StringQ[package] || !FileExistsQ[package],
 Print["Set ASYMPTOTIC_PACKAGE to an existing package .wl file."]; Exit[2]];
sourceHash=IntegerString[FileHash[package,"SHA256"],16,64];
Get[package];
If[Length[DownValues[AsymptoticInverse`AsymptoticExpansion]]==0,
 Print["Package loading did not install AsymptoticExpansion."]; Exit[2]];
Get[FileNameJoin[{root,"code","AuditSupport.wl"}]];
selection=Environment["ASYMPTOTIC_AUDIT_SUITE"];
suites=Switch[selection,"Proposed",{"ProposedContracts.wlt"},
 "All",{"Baseline.wlt","Support.wlt","ProposedContracts.wlt"},
 _,{"Baseline.wlt","Support.wlt"}];
paths=FileNameJoin[{root,"tests",#}]& /@ suites;
If[paths==={} || !And@@(FileExistsQ /@ paths), Print["Missing/empty suite selection."];Exit[2]];
report=TestReport[paths,ProgressReporting->False];
count=report["TestsSucceededCount"]+report["TestsFailedCount"];
results=<|"ExecutionStatus"->"ExecutedByThisRunner", "WolframVersion"->$Version,
 "SystemID"->$SystemID,"SourceFile"->ExpandFileName[package],
 "ObservedSourceSHA256"->sourceHash,
 "ReferenceCommit"->"07a9781212beb2eeb9ff16aa625b50ac27974078",
 "ReferenceCommitIsNotAnExecutionAttestation"->True,
 "Suites"->suites,"Succeeded"->report["TestsSucceededCount"],
 "Failed"->report["TestsFailedCount"],
 "Results"->( <|"TestID"->#["TestID"],"Outcome"->#["Outcome"],
   "Actual"->ToString[#["ActualOutput"],InputForm],
   "Expected"->ToString[#["ExpectedOutput"],InputForm],
   "Messages"->ToString[#["ActualMessages"],InputForm]|>& /@ Values[report["TestResults"]])|>;
out=FileNameJoin[{root,"evidence","native-audit-results.json"}];
exported=Export[out,results,"RawJSON"];
Print["Succeeded: ",report["TestsSucceededCount"],"; failed: ",report["TestsFailedCount"]];
Print["Output: ",out];
Exit[If[count>0 && report["TestsFailedCount"]==0 && StringQ[exported],0,1]];
