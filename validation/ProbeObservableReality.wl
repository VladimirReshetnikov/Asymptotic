(* Characterize complex inner paths separately from the original ingress baseline. *)
Module[{root, files, hashes, before, x, z, a, s, r, output},
 root = DirectoryName[DirectoryName[$InputFileName]];
 files = Sort[FileNames["*.wl", FileNameJoin[{root, "src", "Kernel"}]]];
 hashes[] := Association[(StringReplace[FileNameTake[#, -3], "\\" -> "/"] ->
     FileHash[#, "SHA256", "HexString"]) & /@ files];
 before = hashes[];
 Get[FileNameJoin[{root, "src", "Kernel", "AsymptoticAnalysis.wl"}]];
 s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 3}, "Backend" -> "Package", Assumptions -> a^2 == -1];
 r = TimeConstrained[AsymptoticAnalysis`SeriesObservable[s, a Re[a z], z], 20, $Aborted];
 output = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
 If[! StringQ[output] || output === "", output = FileNameJoin[{root, "validation", "observable-reality-first-pass.json"}]];
 Export[output, <|"Kernel" -> $Version,
   "Scope" -> "One native complex-inner-path characterization after the initial endpoint/side repair, before reality admission. Not the original ingress baseline and not an acceptance suite.",
   "SourceSHA256" -> before, "SourcesUnchangedDuringRun" -> (before === hashes[]),
   "ProbeSHA256" -> FileHash[$InputFileName, "SHA256", "HexString"],
   "SourceKind" -> s["Kind"], "Assumptions" -> "a^2 == -1",
   "Observable" -> "a Re[a z]", "Normal" -> ToString[Normal[r], InputForm],
   "Remainder" -> If[MatchQ[r, _AsymptoticAnalysis`GeneralizedSeries], ToString[r["Remainder"], InputForm], Null],
   "ExactValueAtBothParameterRoots" -> ToString[FullSimplify[{I Re[I x], -I Re[-I x]}, x > 0], InputForm]|>, "RawJSON"];
 Print[output]; Print["Normal=", InputForm[Normal[r]]];
 Exit[If[before === hashes[], 0, 1]]];
