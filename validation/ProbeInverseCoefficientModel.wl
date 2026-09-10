(* W3-08: characterize coefficient queries on result families and models.
   This records actual outcomes and messages; it is not an acceptance suite. *)
Module[{root, probe = $InputFileName, hashes, before, probeHash, observe,
    results, output, x, y, ell},
 root = DirectoryName[DirectoryName[probe]];
 hashes[] := Association[(StringReplace[FileNameTake[#, -3], "\\" -> "/"] ->
     FileHash[#, "SHA256", "HexString"]) & /@
   Sort[FileNames["*.wl", FileNameJoin[{root, "src", "Kernel"}]]]];
 before = hashes[]; probeHash = FileHash[probe, "SHA256", "HexString"];
 Get[FileNameJoin[{root, "src", "Kernel", "AsymptoticAnalysis.wl"}]];
 observe[name_, held_HoldComplete] := Module[{value, seconds, messages},
   Block[{$MessageList = {}},
    {seconds, value} = AbsoluteTiming[TimeConstrained[ReleaseHold[held], 20, $Aborted]];
    messages = ToString[#, InputForm] & /@ $MessageList];
   Print[name, ": ", InputForm[value]];
   <|"Case" -> name, "Result" -> ToString[value, InputForm],
     "Messages" -> messages, "Seconds" -> seconds, "TimedOut" -> (value === $Aborted)|>];
 results = Block[{$Assumptions = True}, {
   observe["forward-object", HoldComplete[
     AsymptoticAnalysis`InverseExpansionCoefficient[
       AsymptoticAnalysis`AsymptoticExpansion[1 + x, {x, 0, 2}, "Backend" -> "Package"], {0}]]],
   observe["derived-object", HoldComplete[
     Module[{s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 2}, "Backend" -> "Package"]},
       AsymptoticAnalysis`InverseExpansionCoefficient[AsymptoticAnalysis`SeriesMultiply[s, s], {0}]]]],
   observe["empty-model", HoldComplete[AsymptoticAnalysis`InverseExpansionCoefficient[<||>, {}]]],
   observe["ordinary-inverse", HoldComplete[
     AsymptoticAnalysis`InverseExpansionCoefficient[
       AsymptoticAnalysis`AsymptoticInverse[x + x^2, {x, 0}, {y, 4}], {1}]]],
   observe["ordinary-model", HoldComplete[
     AsymptoticAnalysis`InverseExpansionCoefficient[
       AsymptoticAnalysis`PowerLogModel[x + x^2, {x, 0}], {2}]]],
   observe["zero-dimensional-model", HoldComplete[
     AsymptoticAnalysis`InverseExpansionCoefficient[
       AsymptoticAnalysis`PowerLogModel[x, {x, 0}], {}]]],
   observe["wrong-dimension", HoldComplete[
     AsymptoticAnalysis`InverseExpansionCoefficient[
       AsymptoticAnalysis`PowerLogModel[x + x^2, {x, 0}], {}]]],
   observe["native-object", HoldComplete[
     AsymptoticAnalysis`InverseExpansionCoefficient[
       AsymptoticAnalysis`AsymptoticExpansion[Sin[x], {x, 0, 3}, "Backend" -> "Series"], {1}]]],
   observe["core-object", HoldComplete[
     AsymptoticAnalysis`InverseExpansionCoefficient[
       AsymptoticAnalysis`AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 3}], {1}]]],
   observe["fourier-object", HoldComplete[
     AsymptoticAnalysis`InverseExpansionCoefficient[
       AsymptoticAnalysis`AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 3}], {1}]]],
   observe["infinite-endpoint-power", HoldComplete[
     AsymptoticAnalysis`InverseExpansionCoefficient[
       AsymptoticAnalysis`AsymptoticInverse[x + 1/x, {x, Infinity}, {y, 4}], {1}]]]
 }];
 output = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
 If[! StringQ[output] || output === "", output = FileNameJoin[{root, "validation", "inverse-coefficient-model-baseline.json"}]];
 Export[output, <|"Kernel" -> $Version, "Scope" -> "Eleven bounded coefficient-model characterization observations; no full suite.",
   "SourceCount" -> Length[before], "SourceSHA256" -> before,
   "SourcesUnchangedDuringRun" -> (before === hashes[]),
   "ProbeSHA256" -> probeHash, "ProbeUnchangedDuringRun" -> (probeHash === FileHash[probe, "SHA256", "HexString"]),
   "Observations" -> results|>, "RawJSON"];
 Exit[If[before === hashes[], 0, 1]]];
