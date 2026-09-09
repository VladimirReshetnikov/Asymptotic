(* Run in a fresh kernel:
     wolframscript -file code/run_audit.wls
     wolframscript -file code/run_audit.wls --patched
   Baseline intentionally fails tests for the reported defects.
   A source path can be supplied with ASYMPTOTIC_AUDIT_PACKAGE; it must have
   the exact pinned standalone SHA-256. No installed files are modified. *)
$AuditPatched = MemberQ[$ScriptCommandLine,"--patched"];
$AuditHere = DirectoryName[$InputFileName];
$AuditExpectedSHA = "b2aebac8176649ff53634816f17e92c8f0ccb397f7606a5ac819b6f157b6d7ed";
$AuditURL = "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/07a9781212beb2eeb9ff16aa625b50ac27974078/AsymptoticInverse.wl";
$AuditPath = Environment["ASYMPTOTIC_AUDIT_PACKAGE"];
If[!StringQ[$AuditPath] || $AuditPath==="",
 $AuditPath=Quiet[Check[URLDownload[$AuditURL],$Failed]]];
If[!StringQ[$AuditPath] || !FileExistsQ[$AuditPath],Print["Package download/file unavailable"];Exit[2]];
If[FileHash[$AuditPath,"SHA256","HexString"]=!=$AuditExpectedSHA,
 Print["Pinned source hash mismatch; no evaluation performed."];Exit[2]];
$AuditLoadPath=$AuditPath;
If[$AuditPatched,
 $AuditText=Import[$AuditPath,"Text"];
 $AuditPatches=Import[FileNameJoin[{$AuditHere,"patches.json"}],"RawJSON"];
 If[!AllTrue[$AuditPatches,StringCount[$AuditText,#["old"]]===#["expected"]&],
  Print["Patch anchor mismatch; no evaluation performed."];Exit[2]];
 $AuditText=StringReplace[$AuditText,(#["old"]->#["new"])& /@ $AuditPatches];
 $AuditLoadPath=CreateTemporary[];
 Export[$AuditLoadPath,$AuditText,"Text",CharacterEncoding->"UTF8"]];
Get[$AuditLoadPath];
$AuditReport=TimeConstrained[TestReport[FileNameJoin[{$AuditHere,"audit_regressions.wlt"}]],300,$Aborted];
$AuditPassed=If[$AuditReport===$Aborted,0,Quiet[Check[$AuditReport["TestsSucceededCount"],$Failed]]];
$AuditFailed=If[$AuditReport===$Aborted,0,Quiet[Check[$AuditReport["TestsFailedCount"],$Failed]]];
$AuditExpectedCount=If[$AuditPatched,13,12];
$AuditCountValid=IntegerQ[$AuditPassed] && IntegerQ[$AuditFailed] &&
  $AuditPassed+$AuditFailed===$AuditExpectedCount;
$AuditResult=If[$AuditReport===$Aborted,
 <|"Version"->$Version,"SystemID"->$SystemID,"Patched"->$AuditPatched,"Status"->"TimedOut"|>,
 <|"Version"->$Version,"SystemID"->$SystemID,"Patched"->$AuditPatched,
   "BaselineSHA256"->$AuditExpectedSHA,
   "TestsSucceeded"->$AuditPassed,
   "TestsFailed"->$AuditFailed,
   "ExpectedTestCount"->$AuditExpectedCount,"TestCountValid"->$AuditCountValid,
   "ReportInputForm"->ToString[$AuditReport,InputForm]|>];
$AuditOutput=FileNameJoin[{$AuditHere,"..","results",If[$AuditPatched,"regressions-patched.json","regressions-baseline.json"]}];
If[Quiet[Check[Export[$AuditOutput,$AuditResult,"RawJSON"],$Failed]]===$Failed,
 Print["Result export failed."];Exit[2]];
Print[$AuditResult];
If[$AuditPatched,Quiet[DeleteFile[$AuditLoadPath]]];
Exit[If[$AuditReport===$Aborted || !TrueQ[$AuditCountValid],2,If[$AuditFailed===0,0,1]]];
