(* Run in a fresh native kernel. This program was supplied but NOT run here.
   wolframscript -file characterize.wls /path/to/AsymptoticAnalysis.wl output.json *)
scriptDirectory = DirectoryName[$InputFileName];
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 2,
 Print["Usage: characterize.wls package-entry-point output.json"]; Exit[2]];
entryPoint = ExpandFileName[arguments[[1]]]; output = ExpandFileName[arguments[[2]]];
If[! FileExistsQ[entryPoint], Print["Package entry point not found."]; Exit[2]];
Get[entryPoint]; Get[FileNameJoin[{scriptDirectory, "fixtures.wl"}]];

ClearAll[capture, summarize];
summarize[s_GeneralizedSeries] := <|
 "Shape" -> "GeneralizedSeries", "Kind" -> ToString[s["Kind"], InputForm],
 "Normal" -> ToString[Normal[s], InputForm], "Remainder" -> ToString[s["Remainder"], InputForm],
 "Exact" -> ToString[s["Exact"], InputForm], "NativeBackend" -> ToString[s["NativeBackend"], InputForm],
 "RefinementStatistics" -> ToString[s["RefinementStatistics"], InputForm]|>;
summarize[r_] := <|"Shape" -> ToString[Head[r], InputForm], "Result" -> ToString[r, InputForm]|>;
SetAttributes[capture, HoldAllComplete];
capture[label_String, expression_] := Module[{value, messages, elapsed},
 Block[{$MessageList = {}},
  {elapsed, value} = AbsoluteTiming[TimeConstrained[CheckAbort[expression, $Aborted], 30, $TimedOut]];
  messages = ToString[#, InputForm] & /@ $MessageList];
 Join[<|"Case" -> label, "Seconds" -> elapsed, "Messages" -> messages|>, summarize[value]]];

observations = {
 capture["N01/default-Series", Module[{saved = Options[AsymptoticExpansion]},
  Internal`WithLocalSettings[Null,
   SetOptions[AsymptoticExpansion, "Backend" -> "Series"];
   AsymptoticExpansion[Exp[x], {x, 0, 2}], Options[AsymptoticExpansion] = saved]]],
 capture["N01/explicit-Series-control", AsymptoticExpansion[Exp[x], {x, 0, 2}, "Backend" -> "Series"]],
 capture["N02/literal-control", AsymptoticExpansion[I + x, {x, 0, 2}]],
 capture["N02/applied-Function", AsymptoticExpansion[Function[t, t][I] + x, {x, 0, 2}]],
 capture["N03/string-Assumptions", AsymptoticExpansion[Sqrt[a^2] Exp[x], {x, 0, 2},
   "Assumptions" -> a > 0, "Backend" -> "Package"]],
 capture["N03/symbol-Backend", AsymptoticExpansion[Exp[x], {x, 0, 2}, AsymptoticAuditFixtures`Backend -> "Series"]],
 capture["D01/fixture", Series[AsymptoticAuditFixtures`ShortTaylor[t], {t, 0, 4}]],
 capture["D01/observable", Module[{s}, s = AsymptoticExpansion[x, {x, 0, 5}, "Backend" -> "Package"];
   SeriesObservable[s, AsymptoticAuditFixtures`ShortTaylor[z], z, "Cutoff" -> 4]]],
 capture["D02/constant-refinement", Module[{s, c},
   s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}, "InputRemainder" -> {4, 0}];
   c = SeriesObservable[s, 7, z]; SeriesRefine[c, 20]]]
};
record = <|"KernelVersion" -> $Version, "SystemID" -> $SystemID,
 "PackageEntryPoint" -> entryPoint,
 "ExpectedSnapshotForBaseline" -> "6687962f3c858a4f93623cfc496f33e35c6763d4",
 "RevisionVerification" -> "The caller must identify the selected source; this harness does not infer a commit from a filename.",
 "Evidence" -> "Native observations from this user-run invocation, not an interval proof or full-suite acceptance.",
 "Observations" -> observations|>;
If[Export[output, record, "RawJSON"] === $Failed, Exit[3]];
Print["Wrote ", output];
