(* SPDX-License-Identifier: MIT-0
   Opt-in, session-local repair for the ordinary jetMerge support partition.
   Audited against Asymptotic commit
   921387e5ba1239bfda96e63e64e89bf63d9c41e6.
   Load AsymptoticInverse first, then call InstallSemanticWeightFix[].
   This does not edit the repository or fix the other issues in the article. *)
BeginPackage["AsymptoticAudit`"];
InstallSemanticWeightFix::usage = "InstallSemanticWeightFix[] replaces the one structural GatherBy in ordinary jetMerge with proved-equality grouping. Returns a status association or Failure.";
RemoveSemanticWeightFix::usage = "RemoveSemanticWeightFix[] restores the DownValues saved by this session's installer.";
Begin["`Private`"];
If[!ValueQ[$SavedJetMergeDownValues], $SavedJetMergeDownValues = None];
If[!ValueQ[$InstalledJetMergeDownValues], $InstalledJetMergeDownValues = None];
InstallSemanticWeightFix[] := Module[{before, after, count},
  before = DownValues[AsymptoticInverse`Private`jetMerge];
  If[before === {}, Return[Failure["PackageNotLoaded", <|
    "MessageTemplate" -> "Load the pinned AsymptoticInverse package first."|>]]];
  If[$InstalledJetMergeDownValues =!= None && before === $InstalledJetMergeDownValues,
    Return[<|"Applied" -> False, "AlreadyInstalled" -> True|>]];
  If[$SavedJetMergeDownValues =!= None,
    Return[Failure["DefinitionsChanged", <|"MessageTemplate" ->
      "jetMerge changed after installation; do not overwrite unrelated definitions."|>]]];
  count = Count[before, HoldPattern[GatherBy[_, First]], Infinity];
  If[count =!= 1, Return[Failure["UnexpectedDefinitions", <|
    "MessageTemplate" -> "Expected exactly one GatherBy[_,First] anchor.",
    "AnchorCount" -> count|>]]];
  after = before /. HoldPattern[GatherBy[rows_, First]] :>
    Split[Sort[rows, Function[{left, right},
        AsymptoticInverse`Private`less[left[[1]], right[[1]]]]],
      Function[{left, right},
        AsymptoticInverse`Private`equal[left[[1]], right[[1]]]]];
  If[after === before, Return[Failure["NoChange", <||>]]];
  $SavedJetMergeDownValues = before;
  $InstalledJetMergeDownValues = after;
  DownValues[AsymptoticInverse`Private`jetMerge] = after;
  <|"Applied" -> True, "AnchorCount" -> count,
    "Scope" -> "Ordinary semantic weight merging only",
    "AuditedCommit" -> "921387e5ba1239bfda96e63e64e89bf63d9c41e6"|>
];
RemoveSemanticWeightFix[] := Module[{},
  If[$SavedJetMergeDownValues === None,
    Return[<|"Restored" -> False, "Reason" -> "NotInstalled"|>]];
  If[DownValues[AsymptoticInverse`Private`jetMerge] =!= $InstalledJetMergeDownValues,
    Return[Failure["DefinitionsChanged", <|"MessageTemplate" ->
      "Refusing to discard a later edit to jetMerge."|>]]];
  DownValues[AsymptoticInverse`Private`jetMerge] = $SavedJetMergeDownValues;
  $SavedJetMergeDownValues = None; $InstalledJetMergeDownValues = None;
  <|"Restored" -> True|>
];
End[]; EndPackage[];
