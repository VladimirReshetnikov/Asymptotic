(* Run after loading the desired standalone in a fresh kernel. Set
   $AuditRepository to a local checkout for offline tests, or leave it unset
   to fetch the four pinned test files. The full package suite is not run. *)
Module[{names, paths, text, path, report},
  names = {"NativeAutomatic", "NativeCompatibility", "NativeContracts", "NativePresentation"};
  paths = If[ValueQ[$AuditRepository],
    FileNameJoin[{$AuditRepository, "src", "Tests", # <> ".wlt"}] & /@ names,
    Table[
      text = Import[$AuditBase <> "src/Tests/" <> name <> ".wlt", "Text"];
      If[! StringQ[text], Print["Test download failed: " <> name]; Abort[]];
      path = FileNameJoin[{$TemporaryDirectory, name <> ".wlt"}];
      Export[path, text, "Text"]; path, {name, names}]];
  report = TestReport[paths];
  <|"KernelVersion" -> $Version, "SystemID" -> $SystemID,
    "Files" -> names, "Succeeded" -> report["TestsSucceededCount"],
    "Failed" -> report["TestsFailedCount"], "Report" -> report|>]
