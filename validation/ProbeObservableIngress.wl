(* Bounded characterization of observable Taylor information and approach sides.
   The custom provider truthfully supplies only Sin[u] = u + O[u]^2. *)
Module[{root, files, hashes, before, observations, observe, x, z, u, output},
 root = DirectoryName[DirectoryName[$InputFileName]];
 files = Sort[FileNames["*.wl", FileNameJoin[{root, "src", "Kernel"}]]];
 hashes[] := Association[(StringReplace[FileNameTake[#, -3], "\\" -> "/"] ->
     FileHash[#, "SHA256", "HexString"]) & /@ files];
 before = hashes[];
 Get[FileNameJoin[{root, "src", "Kernel", "AsymptoticAnalysis.wl"}]];
 ClearAll[ReviewObservableFixture`shortSin];
 ReviewObservableFixture`shortSin[0] = 0;
 ReviewObservableFixture`shortSin[t_?NumericQ] := Sin[t];
 ReviewObservableFixture`shortSin /:
   HoldPattern[Series[ReviewObservableFixture`shortSin[v_], {t_Symbol, 0, n_Integer}, opts___]] /; v === t :=
     SeriesData[t, 0, {1}, 1, 2, 1];
 observe[name_, held_HoldComplete] := Module[{r, seconds},
   {seconds, r} = AbsoluteTiming[TimeConstrained[ReleaseHold[held], 20, $Aborted]];
   <|"Case" -> name, "Seconds" -> seconds,
     "Result" -> ToString[If[MatchQ[r, _AsymptoticAnalysis`GeneralizedSeries],
       KeyTake[r[[1]], {"Kind", "Expression", "Remainder", "Exact", "Cutoff"}], r], InputForm],
     "Normal" -> ToString[If[MatchQ[r, _AsymptoticAnalysis`GeneralizedSeries | _SeriesData], Normal[r], r], InputForm],
     "Remainder" -> If[MatchQ[r, _AsymptoticAnalysis`GeneralizedSeries], ToString[r["Remainder"], InputForm], Null]|>];
 observations = {
   observe["truthful-short-sine-provider", HoldComplete[Series[ReviewObservableFixture`shortSin[u], {u, 0, 5}, Assumptions -> u > 0]]],
   observe["short-provider-composed-with-exact-identity", HoldComplete[
     AsymptoticAnalysis`SeriesObservable[AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 5}, "Backend" -> "Package"],
       ReviewObservableFixture`shortSin[z], z, "Cutoff" -> 5]]],
   observe["native-fractional-part-left", HoldComplete[Series[FractionalPart[1 - u], {u, 0, 2}, Assumptions -> u > 0]]],
   observe["fractional-part-left-composition", HoldComplete[
     AsymptoticAnalysis`SeriesObservable[AsymptoticAnalysis`AsymptoticExpansion[1 - x, {x, 0, 2}, "Backend" -> "Package"], FractionalPart[z], z]]],
   observe["fractional-part-right-composition", HoldComplete[
     AsymptoticAnalysis`SeriesObservable[AsymptoticAnalysis`AsymptoticExpansion[1 + x, {x, 0, 2}, "Backend" -> "Package"], FractionalPart[z], z]]],
   observe["fractional-part-exact-point", HoldComplete[
     AsymptoticAnalysis`SeriesObservable[AsymptoticAnalysis`AsymptoticExpansion[1, {x, 0, 2}, "Backend" -> "Package"], FractionalPart[z], z]]],
   observe["fractional-part-side-lost-by-truncation", HoldComplete[
     AsymptoticAnalysis`SeriesObservable[AsymptoticAnalysis`AsymptoticExpansion[1 - x, {x, 0, 1}, "Backend" -> "Package"], FractionalPart[z], z]]],
   observe["fractional-part-nonjump-control", HoldComplete[
     AsymptoticAnalysis`SeriesObservable[AsymptoticAnalysis`AsymptoticExpansion[1/2 - x, {x, 0, 2}, "Backend" -> "Package"], FractionalPart[z], z]]],
   observe["short-sine-error-order-independent-limit", HoldComplete[Limit[(Sin[x] - x)/x^3, x -> 0]]]
 };
 output = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
 If[! StringQ[output] || output === "", output = FileNameJoin[{root, "validation", "observable-ingress-baseline.json"}]];
 Export[output, <|"Kernel" -> $Version,
   "Scope" -> "Nine bounded native observations of the unchanged loaded sources; characterization, not a package acceptance suite. No full suite.",
   "SourceSHA256" -> before, "SourcesUnchangedDuringRun" -> (before === hashes[]),
   "ProbeSHA256" -> FileHash[$InputFileName, "SHA256", "HexString"], "Observations" -> observations|>, "RawJSON"];
 Print[output];
 Do[Print[o["Case"], ": ", o["Normal"], " remainder=", o["Remainder"]], {o, observations}];
 ClearAll[ReviewObservableFixture`shortSin];
 Exit[If[before === hashes[], 0, 1]]];
