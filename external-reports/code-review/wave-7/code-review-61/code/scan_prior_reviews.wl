(* Reproduce the lexical comparison, not a semantic equivalence test.
   Uses public, commit-pinned GitHub resources. Run selected waves in separate
   calls on a remote kernel to avoid network gateway limits. This exact whole
   program was not run as one job; equivalent per-wave batches were run.
   The public GitHub API may impose rate limits.
*)
Module[{commit = "efa1aeec4845a9c35e140963a0333d0c9ec33b05", tree, paths,
    base, pattern, results, text, lines},
  tree = Import["https://api.github.com/repos/VladimirReshetnikov/Asymptotic/git/trees/" <>
    commit <> "?recursive=1", "RawJSON"];
  If[! AssociationQ[tree] || TrueQ[tree["truncated"]], Return[$Failed]];
  paths = Select[(#["path"] & /@ tree["tree"]),
    StringStartsQ[#, "external-reports/code-review/"] && StringEndsQ[#, ".tex"] &];
  base = "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/" <> commit <> "/";
  pattern = RegularExpression["(?i)(inverseFunctionConditionOnJet|realness predicate|reality predicate|Hermitian|half[- ]spectrum|predicate.{0,40}truncat|truncat.{0,40}predicate)"];
  results = Table[
    text = Quiet[TimeConstrained[Import[base <> path, "Text"], 15, $Failed]];
    If[! StringQ[text], {path, "READ_FAILED"},
      lines = StringSplit[text, "\n", All];
      {path, StringLength[text], Select[MapIndexed[{First[#2], #1} &, lines],
        StringContainsQ[#[[2]], pattern] &]}], {path, paths}];
  results
]
