(* Bounded native characterization of principal-log identities and their consumers. *)
Module[{root, files, hashes, before, observe, observations, output, x, y, a, c, u, ell, n},
 root = DirectoryName[DirectoryName[$InputFileName]];
 files = Sort[FileNames["*.wl", FileNameJoin[{root, "src", "Kernel"}]]];
 hashes[] := Association[(StringReplace[FileNameTake[#, -3], "\\" -> "/"] ->
     FileHash[#, "SHA256", "HexString"]) & /@ files];
 before = hashes[];
 Get[FileNameJoin[{root, "src", "Kernel", "AsymptoticAnalysis.wl"}]];
 observe[name_, held_HoldComplete] := Module[{result, seconds},
   {seconds, result} = AbsoluteTiming[TimeConstrained[ReleaseHold[held], 20, $Aborted]];
   Print[name, ": ", InputForm[If[MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries], Normal[result], result]]];
   <|"Case" -> name, "Seconds" -> seconds,
     "Result" -> ToString[If[MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries],
       KeyTake[result[[1]], {"Kind", "Scale", "Expression", "Remainder", "Exact", "Truncation"}], result], InputForm],
     "Normal" -> ToString[If[MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries], Normal[result], result], InputForm]|>];
 observations = Block[{$Assumptions = True}, {
   observe["parser-complex-unscaled-log", HoldComplete[
     AsymptoticAnalysis`Private`parseFinite[u + u^2 Log[u^a]^2, u, ell, a^2 == -1]]],
   observe["parser-complex-scaled-log", HoldComplete[
     AsymptoticAnalysis`Private`parseFinite[u + u^2 Log[2 u^a]^2, u, ell, a^2 == -1]]],
   observe["parser-paired-scaled-real-source", HoldComplete[
     AsymptoticAnalysis`Private`parseFinite[u + u^2 (Log[2 u^a] + Log[u^a/2])^2/4, u, ell, a^2 == -1]]],
   observe["private-depth-constructor", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`construct[
       x + x^2 Log[x^a]^2, x, 0, y, 1, "Truncation" -> "Depth", Assumptions -> a^2 == -1]]]],
   observe["public-depth-unscaled-winding-source", HoldComplete[
     AsymptoticAnalysis`AsymptoticInverse[x + x^2 Log[x^a]^2, {x, 0}, {y, 1},
       "Truncation" -> "Depth", Assumptions -> a^2 == -1]]],
   observe["public-depth-paired-scaled-winding-source", HoldComplete[
     AsymptoticAnalysis`AsymptoticInverse[x + x^2 (Log[2 x^a] + Log[x^a/2])^2/4,
       {x, 0}, {y, 1}, "Truncation" -> "Depth", Assumptions -> a^2 == -1]]],
   observe["public-exact-core-winding-perturbation", HoldComplete[
     AsymptoticAnalysis`AsymptoticCoreInverse[x, x^2 Log[x^a]^2, {x, 0}, {y, 1}, Assumptions -> a^2 == -1]]],
   observe["public-flat-scalar-winding-log", HoldComplete[
     AsymptoticAnalysis`FlatSeriesMultiply[
       AsymptoticAnalysis`AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 1}, Assumptions -> a^2 == -1],
       Log[y^a]^2]]],
   observe["parser-real-negative-exponent-control", HoldComplete[
     AsymptoticAnalysis`Private`parseFinite[u + u^2 Log[u^a]^2, u, ell, a < 0]]],
   observe["parser-positive-scaled-real-exponent-control", HoldComplete[
     AsymptoticAnalysis`Private`parseFinite[u + u^2 Log[c u^a]^2, u, ell, c > 0 && Element[a, Reals]]]],
   observe["native-principal-log-winding-oracle", HoldComplete[{Log[Exp[-2 Pi I]], (I (-2 Pi))^2}]],
   observe["exact-source-at-winding-zero-points", HoldComplete[
     Table[FullSimplify[(x + x^2 Log[x^a]^2) /. {a -> I, x -> Exp[-2 Pi n]}], {n, 1, 2}]]],
   observe["false-correction-normalized-by-claimed-tail", HoldComplete[
     Limit[Exp[2 Pi n] (2 Pi n)^2/(1 + 2 Pi n)^4, n -> Infinity]]]
 }];
 output = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
 If[! StringQ[output] || output === "", output = FileNameJoin[{root, "validation", "log-power-normalization-baseline.json"}]];
 Export[output, <|"Kernel" -> $Version,
   "Scope" -> "Thirteen bounded native parser/constructor/public-path and independent principal-log observations; characterization, not a package acceptance suite. No full suite.",
   "SourceSHA256" -> before, "SourcesUnchangedDuringRun" -> (before === hashes[]),
   "ProbeSHA256" -> FileHash[$InputFileName, "SHA256", "HexString"], "Observations" -> observations|>, "RawJSON"];
 Print[output]; Exit[If[before === hashes[], 0, 1]]];
