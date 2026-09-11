(* Loading lifecycle (wave-4 W4-17). A module load that is interrupted or
   fails hands the caller's context state back before the interruption
   propagates; a load started from a stale package context returns to
   Global`. Each probe loads a damaged copy of the modular tree, records the
   caller's state around it, then reinstalls the real package. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

loadingLifecycleKernel = FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel"}];
loadingLifecycleMain = FileNameJoin[{loadingLifecycleKernel, "AsymptoticAnalysis.wl"}];

loadingLifecycleCopy[replacements_Association] := Module[{dir},
  dir = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
    "asymptotic-loading-" <> ToString[$ProcessID] <> "-" <> ToString[RandomInteger[10^9]]}]];
  Scan[CopyFile[#, FileNameJoin[{dir, FileNameTake[#]}]] &, FileNames["*.wl", loadingLifecycleKernel]];
  KeyValueMap[Function[{file, text},
    If[text === None, DeleteFile[FileNameJoin[{dir, file}]],
      Export[FileNameJoin[{dir, file}], text, "Text"]]], replacements];
  dir];

(* Returns the load result, whether the caller's state survived, and the
   state and behavior after the real package is reinstalled. *)
loadingLifecycleProbe[replacements_Association, load_] := Module[{dir, before, result, restored, x},
  dir = loadingLifecycleCopy[replacements];
  before = {$Context, $ContextPath};
  result = load[FileNameJoin[{dir, "AsymptoticAnalysis.wl"}]];
  restored = {$Context, $ContextPath} === before;
  DeleteDirectory[dir, DeleteContents -> True];
  Get[loadingLifecycleMain];
  (* The caller's context is whatever it was (Global` in a script, a session
     context in a notebook or sandbox); the reinstalled package returns to it,
     or to Global` when the interruption hit the entry file and the next load
     recovered from the stale package context. *)
  {result, restored, $Context === before[[1]] || $Context === "Global`", First[$ContextPath],
    Normal[AsymptoticExpansion[Exp[x], {x, 0, 3}]] === 1 + x + x^2/2}];

VerificationTest[
  loadingLifecycleProbe[<|"SeriesOperations.wl" -> "Abort[];\n"|>, CheckAbort[Get[#], "aborted"] &],
  {"aborted", True, True, "AsymptoticAnalysis`", True},
  TestID -> "loading-lifecycle-abort-inside-a-module-restores-the-caller-state"]

(* Messages issued while Get reads a file are printed but not collected by
   the test harness, so the load-failure message is observed with Check and
   the expected messages are silenced around it. *)
SetAttributes[loadingLifecycleReported, HoldRest];
loadingLifecycleReported[path_, silenced_] := Quiet[
  Check[CheckAbort[Get[path], "aborted"], "loadfail reported", {AsymptoticExpansion::loadfail}],
  silenced];

VerificationTest[
  loadingLifecycleProbe[<|"SeriesOperations.wl" -> None|>,
    loadingLifecycleReported[#, {Get::noopen, AsymptoticExpansion::loadfail}] &],
  {"loadfail reported", True, True, "AsymptoticAnalysis`", True},
  TestID -> "loading-lifecycle-missing-module-abandons-the-load-with-a-message"]

VerificationTest[
  loadingLifecycleProbe[<|"SeriesOperations.wl" -> "seriesProbe = (1 + ;\n"|>,
    loadingLifecycleReported[#, {Syntax::sntx, AsymptoticExpansion::loadfail}] &],
  {"loadfail reported", True, True, "AsymptoticAnalysis`", True},
  TestID -> "loading-lifecycle-syntax-error-abandons-the-load-instead-of-installing-part"]

(* A time constraint is a real interruption at an unplanned phase. Whether it
   lands inside a module (state restored at once) or in the entry file (state
   recovered by the next load), the reload returns to the caller's context or
   Global` and the package works. *)
VerificationTest[
  loadingLifecycleProbe[<||>, TimeConstrained[Get[#], 0.05, "constrained"] &][[{1, 3, 4, 5}]],
  {"constrained", True, "AsymptoticAnalysis`", True},
  TestID -> "loading-lifecycle-time-constrained-load-reloads-cleanly"]

VerificationTest[
  Module[{before = {$Context, $ContextPath}, after},
    $Context = "AsymptoticAnalysis`Private`";
    $ContextPath = {"AsymptoticAnalysis`", "AsymptoticAnalysis`Mathics`", "System`", "Global`"};
    Get[loadingLifecycleMain];
    after = {$Context, $ContextPath};
    $Context = before[[1]]; $ContextPath = before[[2]];
    after],
  {"Global`", {"AsymptoticAnalysis`", "System`", "Global`"}},
  TestID -> "loading-lifecycle-stale-package-context-recovers-to-global"]

VerificationTest[
  Module[{before = {$Context, $ContextPath}},
    Get[loadingLifecycleMain];
    {$Context, $ContextPath} === before],
  True,
  TestID -> "loading-lifecycle-ordinary-reload-keeps-the-caller-state"]
