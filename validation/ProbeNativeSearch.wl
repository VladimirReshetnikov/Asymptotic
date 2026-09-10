(* Bounded native-search characterization, not an acceptance suite.
   Each direct call is independent. No result below is assumed to establish
   an analytic remainder contract or native capability beyond that call. *)
nativeSearchRoot = DirectoryName[DirectoryName[$InputFileName]];
nativeSearchFiles = Join[FileNames["*.wl", FileNameJoin[{nativeSearchRoot, "src", "Kernel"}]], {$InputFileName}];
nativeSearchHashes[] := Association[(StringReplace[
  FileNameJoin[Drop[FileNameSplit[ExpandFileName[#]], Length[FileNameSplit[nativeSearchRoot]]]], "\\" -> "/"] ->
  IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ nativeSearchFiles];
nativeSearchBefore = nativeSearchHashes[];
nativeSearchLoaded = Check[Get[FileNameJoin[{nativeSearchRoot, "src", "Kernel", "AsymptoticAnalysis.wl"}]], $Failed];
If[nativeSearchLoaded === $Failed, Print["Package loading failed."]; Exit[2]];
nativeSearchRecords = {};
SetAttributes[nativeSearchRecord, HoldRest];
nativeSearchStatus[result_] := Which[MatchQ[result, Missing["TimeLimit", _]], "TimeLimit",
  result === $Aborted, "Aborted", result === $Failed, "Failed", FailureQ[result], "Failure",
  FreeQ[result, _System`Series | _System`Asymptotic], "Computed", True, "Unresolved"];
nativeSearchRecord[id_, expression_] := Module[{seconds, result, nativeResult, status, normal, instrumentation},
  {seconds, result} = AbsoluteTiming[TimeConstrained[Quiet[expression], 10, Missing["TimeLimit", 10]]];
  instrumentation = ! MatchQ[result, _GeneralizedSeries] && ! FreeQ[result, _GeneralizedSeries];
  (* NativeRequest metadata itself contains held Series/Asymptotic heads.
     Strip wrappers before inspecting results, including counter-list records. *)
  nativeResult = result /. s_GeneralizedSeries :> If[s["Kind"] === "Native", s["NativeResult"], s];
  status = If[instrumentation, "Instrumentation", nativeSearchStatus[nativeResult]];
  normal = Quiet[TimeConstrained[Normal[nativeResult], 3, Missing["NormalTimeLimit", 3]]];
  AppendTo[nativeSearchRecords, <|"ID" -> id,
    "Input" -> ToString[HoldComplete[expression], InputForm],
    "Status" -> status, "Result" -> ToString[nativeResult, InputForm],
    "Normal" -> ToString[normal, InputForm], "Seconds" -> seconds,
    "Diagnostics" -> "Messages suppressed by Quiet; not captured.",
    "InstrumentedResultStatus" -> If[instrumentation, nativeSearchStatus[nativeResult], Null],
    "NativeHeadCount" -> Count[nativeResult, _System`Series | _System`Asymptotic, {0, Infinity}],
    "HasConditionalExpression" -> ! FreeQ[nativeResult, _ConditionalExpression],
    "WrapperKind" -> If[MatchQ[result, _GeneralizedSeries], result["Kind"], Null],
    "WrapperMetadata" -> If[MatchQ[result, _GeneralizedSeries] && result["Kind"] === "Native",
      ToString[KeyTake[result[[1]], {"NativeBackend", "NativeEvaluationStatus", "BackendSelectionReason",
        "NativeAttempts", "BackendAttempts", "PackageFailure"}], InputForm], Null]|>];
  Print[id, ": ", status, " (", seconds, " s): ", InputForm[normal]]];
SetAttributes[nativeSearchCase, HoldAllComplete];
nativeSearchCase[id_, args___] := (
  nativeSearchRecord[id <> "/Series", System`Series[args]];
  nativeSearchRecord[id <> "/Asymptotic", System`Asymptotic[args]];
  nativeSearchRecord[id <> "/Automatic", AsymptoticExpansion[args]]);
Clear[x, y, t, k, n, a, nativeSearchUnknown];

(* Report 17 N4 controls. The retained finite expressions are not unique to
   the package; its Dirichlet result additionally supplies explicit bounds. *)
nativeSearchCase["N4-x-power-x", x^x, {x, 0, 3}];
nativeSearchCase["N4-zeta-rule", Zeta[x], x -> Infinity, SeriesTermGoal -> 3];
nativeSearchCase["N4-zeta-triple", Zeta[x], {x, Infinity, 3}];
nativeSearchRecord["N4-native-inverse-series", InverseSeries[Series[x + x^2, {x, 0, 5}], y]];

(* Inactive transforms are the main candidate witnesses for a first native
   backend remaining unresolved while the other backend computes a result. *)
nativeSearchCase["inactive-integral-finite", Inactive[Integrate][Exp[-x t], {t, 0, 1}],
  x -> Infinity, SeriesTermGoal -> 3];
nativeSearchCase["inactive-integral-triple", Inactive[Integrate][Exp[-x t], {t, 0, 1}],
  {x, Infinity, 3}];
nativeSearchCase["inactive-geometric-sum", Inactive[Sum][Exp[-k x], {k, 1, Infinity}],
  {x, 0, 3}];
nativeSearchCase["bessel-growing-argument", BesselJ[0, x], {x, Infinity, 2}];
nativeSearchCase["formal-list-partial", {Exp[x], nativeSearchUnknown[1/x]}, {x, 0, 2}];
nativeSearchCase["symbolic-order-unresolved", Exp[x], {x, 0, n}];

(* Record the native Direction option behavior rather than presupposing that
   package direction strings are accepted or can be discarded by delegation. *)
nativeSearchCase["direction-from-below-complex", Exp[I x], {x, 0, 2}, Direction -> "FromBelow"];
nativeSearchCase["direction-automatic-complex", Exp[I x], {x, 0, 2}, Direction -> Automatic];
nativeSearchCase["conditional-valid-complex", ConditionalExpression[Exp[I x], x > 0], {x, 0, 2}];
nativeSearchCase["conditional-incompatible-complex", ConditionalExpression[Exp[I x], x < 0], {x, 0, 2}];

(* Option support and laziness are separate from source syntax. These calls
   characterize the native counts; they do not assume native delayed options
   themselves are necessarily evaluated once. *)
nativeSearchRecord["option-common-intersection", Intersection[First /@ Options[System`Series], First /@ Options[System`Asymptotic]]];
nativeSearchRecord["option-series-only", Complement[First /@ Options[System`Series], First /@ Options[System`Asymptotic]]];
nativeSearchRecord["option-asymptotic-only", Complement[First /@ Options[System`Asymptotic], First /@ Options[System`Series]]];
nativeSearchRecord["automatic-common-option-counters", Module[{source = 0, assumptions = 0, goal = 0, result},
  result = AsymptoticExpansion[(source++; Inactive[Integrate][Exp[-x t], {t, 0, 1}]),
    x -> Infinity, Assumptions :> (assumptions++; True), SeriesTermGoal :> (goal++; 3)];
  {source, assumptions, goal, result}]];
nativeSearchRecord["series-common-option-counters", Module[{source = 0, assumptions = 0, goal = 0, result},
  result = System`Series[(source++; Inactive[Integrate][Exp[-x t], {t, 0, 1}]),
    x -> Infinity, Assumptions :> (assumptions++; True), SeriesTermGoal :> (goal++; 3)];
  {source, assumptions, goal, result}]];
nativeSearchRecord["asymptotic-common-option-counters", Module[{source = 0, assumptions = 0, goal = 0, result},
  result = System`Asymptotic[(source++; Inactive[Integrate][Exp[-x t], {t, 0, 1}]),
    x -> Infinity, Assumptions :> (assumptions++; True), SeriesTermGoal :> (goal++; 3)];
  {source, assumptions, goal, result}]];
nativeSearchRecord["automatic-exclusive-option-conflict", AsymptoticExpansion[
  Exp[x], {x, 0, 2}, Analytic -> False, WorkingPrecision -> 30]];

nativeSearchUnchanged = nativeSearchBefore === nativeSearchHashes[];
nativeSearchOutput = Environment["ASYMPTOTIC_NATIVE_SEARCH_OUTPUT"];
If[! StringQ[nativeSearchOutput] || nativeSearchOutput === "",
  nativeSearchOutput = FileNameJoin[{nativeSearchRoot, "validation", "native-search-probe.json"}]];
nativeSearchExport = Export[nativeSearchOutput,
  <|"Kernel" -> $Version, "SystemID" -> $SystemID,
    "Scope" -> "Bounded direct-native differential characterization and protected-routing controls; not an acceptance suite. Every call has a ten-second limit, and Normal has a separate three-second limit. Diagnostics are suppressed, not captured. Instrumentation records are labeled separately from native outputs.",
    "ReviewedReportSnapshot" -> "921387e5ba1239bfda96e63e64e89bf63d9c41e6",
    "ReportEvidenceScope" -> "Report 17 N4 transcribes Wolfram 15.0.0 Linux observations. These records independently characterize the current host and source.",
    "FullPackageSuiteRun" -> False, "Records" -> nativeSearchRecords,
    "SourcesUnchangedDuringRun" -> nativeSearchUnchanged,
    "TestedSourceSHA256" -> nativeSearchBefore|>, "RawJSON"];
Exit[If[nativeSearchUnchanged && StringQ[nativeSearchExport], 0, 1]];
