Get[FileNameJoin[{DirectoryName[$InputFileName], "NativeCommon.wl"}]];
suite = Environment["ASYMPTOTIC_AUDIT_SUITE"];
If[! MemberQ[{"Desired","Proposal"},suite],suite="Proposal"];
file = FileNameJoin[{auditRoot,"tests",suite<>"Contracts.wlt"}];
report = TimeConstrained[MemoryConstrained[Block[{$Assumptions=True},TestReport[file]],1024^3,$Failed],600,$Failed];
If[Head[report]=!=TestReportObject,Print["The native suite did not complete."];Exit[2]];
props=report["Properties"];
resultKey=SelectFirst[{"Results","ResultList","TestResults"},MemberQ[props,#]&,None];
If[resultKey===None,Print["No supported test-result property."];Exit[2]];
items=report[resultKey];
If[! (ListQ[items]||AssociationQ[items])||Length[items]===0,Print["No tests executed."];Exit[2]];
auditWrite["native-"<>ToLowerCase[suite]<>"-tests.json",Join[auditMetadata[],
  <|"Suite"->suite,"Count"->Length[items],"ReportSucceeded"->TrueQ[report["ReportSucceeded"]],
    "Report"->ToString[report,InputForm,PageWidth->Infinity]|>]];
Exit[If[TrueQ[report["ReportSucceeded"]],0,1]];
