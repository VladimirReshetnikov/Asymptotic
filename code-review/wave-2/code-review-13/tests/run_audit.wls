(* Usage: wolframscript -file run_audit.wls /path/to/Asymptotic [--semantic-fix]
   Reads a local checkout. Does not fetch code or edit the checkout.
   Real-domain regressions are expected to fail until separately repaired. *)
args = Rest[$ScriptCommandLine];
If[Length[args] < 1, Print["Supply the local repository root."]; Exit[2]];
repo = ExpandFileName[First[args]];
root = DirectoryName[$InputFileName];
kernel = FileNameJoin[{repo, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}];
If[!FileExistsQ[kernel], Print["Modular kernel not found: ", kernel]; Exit[2]];
Get[kernel];
If[MemberQ[args, "--semantic-fix"],
 Get[FileNameJoin[{root, "..", "code", "semantic_weight_hotfix.wl"}]];
 status = AsymptoticAudit`InstallSemanticWeightFix[];
 Print[status]; If[FailureQ[status], Exit[2]]];
reports = TestReport /@ (FileNameJoin[{root, #}] & /@
 {"semantic_weight_regressions.wlt", "real_domain_regressions.wlt"});
(* Avoid trusting a zero-test run as success. *)
Print[<|"Version" -> $Version, "Reports" -> reports|>];
succeeded = Total[(#["TestsSucceededCount"] &) /@ reports];
failed = Total[(#["TestsFailedCount"] &) /@ reports];
If[!IntegerQ[succeeded] || !IntegerQ[failed] || succeeded + failed =!= 9, Exit[2]];
Exit[If[failed === 0, 0, 1]];
