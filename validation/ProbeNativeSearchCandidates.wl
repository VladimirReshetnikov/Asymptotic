(* Built-in-only differential candidates for native backend selection.
   No package is loaded. Results are characterization data, not assertions
   that any native approximation has a package analytic remainder bound. *)
nativeCandidatesRoot = DirectoryName[DirectoryName[$InputFileName]];
nativeCandidatesSource = $InputFileName;
nativeCandidatesBefore = IntegerString[FileHash[nativeCandidatesSource, "SHA256"], 16, 64];
nativeCandidatesRecords = {};
SetAttributes[nativeCandidatesRecord, HoldRest];
nativeCandidatesRecord[id_, expression_] := Module[{seconds, result, status, normal},
  {seconds, result} = AbsoluteTiming[TimeConstrained[Quiet[expression], 6, Missing["TimeLimit", 6]]];
  status = Which[MatchQ[result, Missing["TimeLimit", _]], "TimeLimit", result === $Aborted, "Aborted",
    result === $Failed, "Failed", FailureQ[result], "Failure",
    FreeQ[result, _System`Series | _System`Asymptotic], "Computed", True, "Unresolved"];
  normal = Quiet[TimeConstrained[Normal[result], 2, Missing["NormalTimeLimit", 2]]];
  AppendTo[nativeCandidatesRecords, <|"ID" -> id,
    "Input" -> ToString[HoldComplete[expression], InputForm], "Status" -> status,
    "Result" -> ToString[result, InputForm], "Normal" -> ToString[normal, InputForm],
    "Seconds" -> seconds, "Diagnostics" -> "Messages suppressed by Quiet; not captured.",
    "NativeHeadCount" -> Count[result, _System`Series | _System`Asymptotic, {0, Infinity}],
    "HasConditionalExpression" -> ! FreeQ[result, _ConditionalExpression]|>];
  Print[id, ": ", status, " (", seconds, " s): ", InputForm[normal]]];
SetAttributes[nativeCandidatesCase, HoldAllComplete];
nativeCandidatesCase[id_, args___] := (
  nativeCandidatesRecord[id <> "/Series", System`Series[args]];
  nativeCandidatesRecord[id <> "/Asymptotic", System`Asymptotic[args]]);
Clear[x, a, y, s];

(* A rule chooses Asymptotic first in Automatic. Native acceptance of zero,
   negative and noninteger goals must be measured rather than inferred from
   the package's positive nonzero-block goal validation. *)
nativeCandidatesCase["rule-zero-goal", Exp[x], x -> 0, SeriesTermGoal -> 0];
nativeCandidatesCase["rule-list-zero-goal", {Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 0];
nativeCandidatesCase["rule-list-negative-goal", {Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> -1];
nativeCandidatesCase["rule-list-half-goal", {Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 1/2];
nativeCandidatesCase["symbolic-center-rule", Exp[x], x -> a, SeriesTermGoal -> 3];
nativeCandidatesCase["constant-boolean", True, x -> 0, SeriesTermGoal -> 3];
nativeCandidatesCase["constant-string", "constant", x -> 0, SeriesTermGoal -> 3];
nativeCandidatesCase["association", <|"Exponential" -> Exp[x], "Linear" -> x|>, x -> 0, SeriesTermGoal -> 3];

(* Preserve transforms as syntax: exact evaluation of the integral/ODE must
   not preempt the comparison between the two native expansion functions. *)
nativeCandidatesCase["inactive-inverse-laplace", Inactive[InverseLaplaceTransform][
  1/(s Sqrt[s^3 + 1]), s, x], {x, 0, 3}];
nativeCandidatesCase["inactive-nonlinear-dsolve", Inactive[DSolveValue][
  {y'[x] == Exp[y[x]] + x, y[0] == 0}, y[x], x], {x, 0, 3}];

(* Extra order forms deliberately include requests that one or both built-ins
   may leave unresolved. No conversion to a different order is performed. *)
nativeCandidatesCase["negative-order-list", {Exp[x], Sin[x]}, {x, 0, -1}];
nativeCandidatesCase["fractional-order-list", {Exp[x], Sin[x]}, {x, 0, 3/2}];
nativeCandidatesCase["two-element-specification", Exp[x], {x, 0}];
nativeCandidatesCase["four-element-specification", Exp[x], {x, 0, 3, 1}];
nativeCandidatesCase["infinite-order-negative-goal", 1/(1 - x), {x, 0, Infinity}, SeriesTermGoal -> -1];
nativeCandidatesCase["infinite-order-zero-goal", 1/(1 - x), {x, 0, Infinity}, SeriesTermGoal -> 0];

nativeCandidatesUnchanged = nativeCandidatesBefore === IntegerString[FileHash[nativeCandidatesSource, "SHA256"], 16, 64];
nativeCandidatesOutput = Environment["ASYMPTOTIC_NATIVE_CANDIDATES_OUTPUT"];
If[! StringQ[nativeCandidatesOutput] || nativeCandidatesOutput === "",
  nativeCandidatesOutput = FileNameJoin[{nativeCandidatesRoot, "validation", "native-search-candidates-probe.json"}]];
nativeCandidatesExport = Export[nativeCandidatesOutput, <|"Kernel" -> $Version, "SystemID" -> $SystemID,
  "Scope" -> "Sixteen built-in-only differential cases; no package loaded. Six-second calculation limits and separate two-second Normal limits. Diagnostics suppressed, not captured. Not an acceptance suite.",
  "PackageLoadedByProbe" -> False,
  "AsymptoticAnalysisContextPresent" -> MemberQ[$Packages, "AsymptoticAnalysis`"],
  "FullPackageSuiteRun" -> False, "Records" -> nativeCandidatesRecords,
  "SourceUnchangedDuringRun" -> nativeCandidatesUnchanged,
  "ProbeSHA256" -> nativeCandidatesBefore|>, "RawJSON"];
Exit[If[nativeCandidatesUnchanged && StringQ[nativeCandidatesExport], 0, 1]];
