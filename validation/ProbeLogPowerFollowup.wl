(* Characterize the two first-pass failures without changing their expectations. *)
Module[{root, files, hashes, before, obs, observe, x, y, a, u, ell, f, out},
 root = DirectoryName[DirectoryName[$InputFileName]];
 files = Sort[FileNames["*.wl", FileNameJoin[{root, "src", "Kernel"}]]];
 hashes[] := Association[(StringReplace[FileNameTake[#, -3], "\\" -> "/"] ->
   FileHash[#, "SHA256", "HexString"]) & /@ files];
 before = hashes[];
 Get[FileNameJoin[{root, "src", "Kernel", "AsymptoticAnalysis.wl"}]];
 observe[name_, held_HoldComplete] := Module[{s, t},
  {t, s} = AbsoluteTiming[TimeConstrained[ReleaseHold[held], 20, $Aborted]];
  Print[name, ": ", InputForm[s]];
  <|"Case" -> name, "Seconds" -> t, "Result" -> ToString[s, InputForm]|>];
 obs = Block[{$Assumptions = True}, {
  observe["public-infinity-real-symbolic", HoldComplete[
   With[{s = AsymptoticAnalysis`AsymptoticInverse[x + Log[x^a]^2/x,
    {x, Infinity}, {y, 1}, "Truncation" -> "Depth", Assumptions -> Element[a, Reals]]},
    If[MatchQ[s, _AsymptoticAnalysis`GeneralizedSeries],
     KeyTake[s[[1]], {"Expression", "Remainder", "Model"}], s]]]],
  observe["parser-reciprocal-symbolic-power", HoldComplete[
   AsymptoticAnalysis`Private`parseFinite[1/u + u Log[(1/u)^a]^2, u, ell, Element[a, Reals]]]],
  observe["refine-positive-nested-power", HoldComplete[
   Refine[Log[(1/u)^a], u > 0 && Element[a, Reals]]]],
  observe["simplify-positive-nested-power", HoldComplete[
   Simplify[Log[(1/u)^a], u > 0 && Element[a, Reals]]]],
  observe["flat-complex-phase-admission", HoldComplete[
   AsymptoticAnalysis`AsymptoticFlatInverse[
    x + x^2 Exp[-1/x + Log[x^a]^2 - a^2 Log[x]^2],
    {x, 0}, {y, 1}, Assumptions -> a^2 == -1]]],
  observe["automatic-inexact-forward", HoldComplete[
   With[{s = AsymptoticAnalysis`AsymptoticExpansion[x + 0.5 x^2, {x, 0, 3}]},
    If[MatchQ[s, _AsymptoticAnalysis`GeneralizedSeries],
     KeyTake[s[[1]], {"Kind", "Backend", "Expression", "NativeResult"}], s]]]],
  observe["package-inexact-forward", HoldComplete[
   AsymptoticAnalysis`AsymptoticExpansion[x + 0.5 x^2, {x, 0, 3}, "Backend" -> "Package"]]]
 }];
 out = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
 If[! StringQ[out] || out === "", out = FileNameJoin[{root, "validation", "log-power-normalization-followup.json"}]];
 Export[out, <|"Kernel" -> $Version, "Scope" -> "Seven bounded follow-up observations of first-pass failures and an adjacent phase path; not acceptance.",
  "SourceSHA256" -> before, "SourcesUnchangedDuringRun" -> (before === hashes[]),
  "ProbeSHA256" -> FileHash[$InputFileName, "SHA256", "HexString"], "Observations" -> obs|>, "RawJSON"];
 Exit[If[before === hashes[], 0, 1]]];
