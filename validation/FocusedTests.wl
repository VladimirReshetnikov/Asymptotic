(* Shared runner for explicitly selected .wlt files. Returns a process exit
   code so entry scripts and runner self-checks can use the same reporting. *)
Begin["FocusedValidation`Private`"];
runnerFile = $InputFileName;

sourceHashes[root_, files_] := Association[(StringReplace[
    FileNameJoin[Drop[FileNameSplit[ExpandFileName[#]], Length[FileNameSplit[root]]]],
    "\\" -> "/"] -> IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ files];

testResult[suite_, result_] := Module[{details},
  details = If[result["Outcome"] === "Success", <||>, <|
    "ExpectedOutput" -> ToString[result["ExpectedOutput"], InputForm],
    "ActualOutput" -> ToString[result["ActualOutput"], InputForm],
    "ActualMessages" -> ToString[result["ActualMessages"], InputForm]|>];
  If[details =!= <||>, Print["FAILED ", result["TestID"],
    "\n expected: ", details["ExpectedOutput"], "\n actual: ", details["ActualOutput"],
    "\n messages: ", details["ActualMessages"]]];
  Join[<|"Suite" -> suite, "TestID" -> result["TestID"], "Outcome" -> result["Outcome"]|>, details]];

runSuite[root_, suite_, timeout_] := Module[{seconds, report, summary},
  Print["Checking: ", suite];
  {seconds, report} = AbsoluteTiming[TimeConstrained[
    TestReport[FileNameJoin[{root, "AsymptoticAnalysis", "Tests", suite}],
      ProgressReporting -> False], timeout, $Aborted]];
  If[Head[report] =!= TestReportObject,
    Print["ABORTED: ", suite];
    Return[{<|"Suite" -> suite, "Outcome" -> "Aborted", "Seconds" -> seconds,
      "Succeeded" -> 0, "Failed" -> 1|>, {}}, Module]];
  If[Length[report["TestResults"]] === 0,
    Print["NO TESTS: ", suite];
    Return[{<|"Suite" -> suite, "Outcome" -> "Empty", "Seconds" -> seconds,
      "Succeeded" -> 0, "Failed" -> 1|>, {}}, Module]];
  summary = <|"Suite" -> suite, "Succeeded" -> report["TestsSucceededCount"],
    "Failed" -> report["TestsFailedCount"], "Seconds" -> seconds|>;
  Print["Succeeded: ", summary["Succeeded"], "  Failed: ", summary["Failed"]];
  {summary, testResult[suite, #] & /@ Values[report["TestResults"]]}];

FocusedValidation`Run[root0_String, entry_String, config_Association] := Module[
  {root = ExpandFileName[root0], suites = config["Suites"], timeout = Lookup[config, "Timeout", 600],
    sources, before, runs, summaries, unchanged, succeeded, failed, output, exported},
  If[! MatchQ[suites, {__String}], Print["Select at least one explicit test file."]; Return[1, Module]];
  sources = DeleteDuplicates[Join[
    FileNames["*.wl", FileNameJoin[{root, "AsymptoticAnalysis", "Kernel"}]],
    FileNameJoin[{root, "AsymptoticAnalysis", "Tests", #}] & /@ suites, {entry, runnerFile}]];
  If[! AllTrue[sources, FileExistsQ], Print["Missing validation source: ", Select[sources, ! FileExistsQ[#] &]];
    Return[1, Module]];
  before = sourceHashes[root, sources];
  If[Check[Get[FileNameJoin[{root, "AsymptoticAnalysis", "Kernel", "AsymptoticAnalysis.wl"}]], $Failed] === $Failed ||
      ! MemberQ[$Packages, "AsymptoticAnalysis`"],
    Print["Package loading failed; no test suites were run."]; Return[1, Module]];
  runs = runSuite[root, #, timeout] & /@ suites;
  summaries = runs[[All, 1]];
  unchanged = AllTrue[sources, FileExistsQ] && before === sourceHashes[root, sources];
  succeeded = Total[Lookup[summaries, "Succeeded"]];
  failed = Total[Lookup[summaries, "Failed"]] + If[unchanged, 0, 1];
  output = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
  If[! StringQ[output] || output === "", output = FileNameJoin[{root, "validation", config["Output"]}]];
  exported = Export[output, <|"Kernel" -> $Version, "Scope" -> config["Scope"],
    "PerSuiteTimeConstraintSeconds" -> timeout, "Suites" -> suites, "SuiteResults" -> summaries,
    "Succeeded" -> succeeded, "Failed" -> failed, "Results" -> Join @@ runs[[All, 2]],
    "SourcesUnchangedDuringRun" -> unchanged, "TestedSourceSHA256" -> before|>, "RawJSON"];
  Print["Kernel: ", $Version, "\nTotal succeeded: ", succeeded, "  Failed: ", failed];
  If[TrueQ[failed == 0] && StringQ[exported], 0, 1]];
End[];
