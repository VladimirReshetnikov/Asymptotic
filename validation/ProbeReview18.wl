(* Bounded characterization of report 18 on current source, not acceptance. *)
review18Root = DirectoryName[DirectoryName[$InputFileName]];
review18Files = Join[FileNames["*.wl", FileNameJoin[{review18Root, "AsymptoticAnalysis", "Kernel"}]], {$InputFileName}];
review18Hashes[] := Association[(StringReplace[
  FileNameJoin[Drop[FileNameSplit[ExpandFileName[#]], Length[FileNameSplit[review18Root]]]], "\\" -> "/"] ->
  IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ review18Files];
review18Before = review18Hashes[];
Get[FileNameJoin[{review18Root, "AsymptoticAnalysis", "Kernel", "AsymptoticAnalysis.wl"}]];
SetAttributes[review18Record, HoldRest];
review18Records = {};
review18Record[id_, expression_] := Module[{seconds, result, messages},
  Block[{$MessageList = {}},
    {seconds, result} = AbsoluteTiming[TimeConstrained[Quiet[expression], 30, Missing["TimeLimit", 30]]];
    messages = ToString[#, InputForm] & /@ $MessageList];
  AppendTo[review18Records, <|"ID" -> id, "Input" -> ToString[HoldComplete[expression], InputForm],
    "Result" -> ToString[result, InputForm], "Seconds" -> seconds, "Messages" -> messages|>];
  Print[id, ": ", InputForm[result]]];
review18CertificateSummary[c_] := Module[{data, best},
  data = If[FailureQ[c], c[[2]], c];
  best = If[FailureQ[c], Lookup[data, "BestCertificate", <||>], c];
  <|"Status" -> If[FailureQ[c], c[[1]], "ReturnedCertificate"],
    "Certified" -> Lookup[best, "Certified", Missing["Absent"]],
    "AccuracyGoalReached" -> Lookup[best, "AccuracyGoalReached", Missing["Absent"]],
    "EnclosureOrders" -> Lookup[Lookup[data, "History", {}], "EnclosureOrder"],
    "CertifiedErrorBoundApproximation" -> N[Lookup[best, "CertifiedErrorBound", Missing["Absent"]], 12]|>];
Clear[x, y];
review18Inverse = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
review18Record["N01-relative-default", review18CertificateSummary[
  InverseCertificate[review18Inverse, 2, "Interval" -> {1, 2}, "RelativeError" -> 10^-120,
    "MaxRefinements" -> 3, "RefineExpansion" -> False]]];
review18Record["N01-absolute-control", review18CertificateSummary[
  InverseCertificate[review18Inverse, 2, "Interval" -> {1, 2}, "TargetError" -> 10^-120,
    "MaxRefinements" -> 3, "RefineExpansion" -> False]]];
review18Record["N01-explicit-order-control", review18CertificateSummary[
  InverseCertificate[review18Inverse, 2, "Interval" -> {1, 2}, "RelativeError" -> 10^-120,
    "EnclosureOrder" -> 150, "MaxRefinements" -> 3, "RefineExpansion" -> False]]];
review18Record["N02-forward-lower-cutoff", Module[{s, t},
  s = AsymptoticExpansion[Sin[x], {x, 0, 7}]; t = SeriesRefine[s, 3];
  {Normal[s], s["Remainder"], Normal[t], t["Remainder"]}]];
review18Record["N02-inverse-lower-cutoff", Module[{s, t},
  s = AsymptoticInverse[x + x^2, {x, 0}, {y, 5}]; t = SeriesRefine[s, 3];
  {Normal[s], s["Remainder"], Normal[t], t["Remainder"]}]];
review18Record["D-C07-native-versus-analytic", Module[{p, n},
  p = AsymptoticExpansion[ArcSin[2] + x, {x, 0, 2}, "Backend" -> "Package"];
  n = AsymptoticExpansion[ArcSin[2] + x, {x, 0, 2}, "Backend" -> "Series"];
  {If[FailureQ[p], p[[1]], p], n["Kind"], Normal[n], n["Remainder"], n["Exact"]}]];
review18Record["D-C04-nonlinear-frontier", Module[{s, t, explicit},
  s = AsymptoticExpansion[x Log[x] + x^2, {x, 0, 2}]; t = SeriesExp[s]; explicit = SeriesExp[s, 3];
  {{Normal[t], t["Remainder"]}, {Normal[explicit], explicit["Remainder"]}}]];
review18Unchanged = review18Before === review18Hashes[];
review18Output = Export[FileNameJoin[{review18Root, "validation", "review-18-intake.json"}],
  <|"Kernel" -> $Version, "Scope" -> "Seven bounded characterizations of report 18 on current source, including known pending behavior; not an acceptance suite.",
    "ReviewedReportSnapshot" -> "921387e5ba1239bfda96e63e64e89bf63d9c41e6",
    "FullPackageSuiteRun" -> False, "Records" -> review18Records,
    "SourcesUnchangedDuringRun" -> review18Unchanged, "TestedSourceSHA256" -> review18Before|>, "RawJSON"];
Exit[If[review18Unchanged && StringQ[review18Output], 0, 1]];
