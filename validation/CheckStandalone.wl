(* Fresh-kernel acceptance checks shared by local, HTTP and GitHub loads.
   Invoked by check_standalone_loading.py, not by the full package suite. *)
loadingSource = Environment["ASYMPTOTIC_LOAD_SOURCE"];
loadingMode = Environment["ASYMPTOTIC_LOAD_MODE"];
loadingOutput = Environment["ASYMPTOTIC_LOAD_RESULT"];
loadingPath = Environment["ASYMPTOTIC_LOAD_PATH"];
loadingRemote = StringQ[loadingSource] &&
  StringStartsQ[loadingSource, "http://" | "https://"];
loadingMethod = If[loadingRemote, "URLDownload followed by local Get", "Automatic"];
loadingGet[] := If[loadingRemote,
  Get[URLDownload[loadingSource]], Get[loadingSource]];
If[! StringQ[loadingSource] || ! StringQ[loadingOutput], Exit[2]];
If[MemberQ[$Packages, "AsymptoticInverse`"] ||
    Names["AsymptoticInverse`*"] =!= {} ||
    Names["Global`AsymptoticExpansion"] =!= {} ||
    Names["Global`PowerLogSeries"] =!= {},
  Print["Acceptance checks require a kernel without preloaded package definitions."];
  Exit[2]];
If[StringQ[loadingPath] && loadingPath =!= "", PrependTo[$Path, loadingPath]];
loadingStringStreamsBefore = Count[Streams[], InputStream["String", _]];
loadingResult = If[loadingMode === "Missing", Quiet[Check[loadingGet[], $Failed]],
  Check[If[loadingMode === "Needs", Needs["AsymptoticInverse`"], loadingGet[]], $Failed]];
If[loadingMode === "Missing",
  loadingChecks = {loadingResult === $Failed,
    ! MemberQ[$Packages, "AsymptoticInverse`"], $Context === "Global`"};
  Export[loadingOutput, <|"Kernel" -> $Version, "Source" -> loadingSource,
    "Mode" -> loadingMode, "Succeeded" -> Count[loadingChecks, True],
    "Failed" -> Count[loadingChecks, Except[True]], "Checks" -> loadingChecks|>, "RawJSON"];
  Exit[If[And @@ loadingChecks, 0, 1]]];
If[loadingResult === $Failed || ! MemberQ[$Packages, "AsymptoticInverse`"],
  Print["Package loading failed: ", loadingSource]; Exit[1]];

(* These expressions are parsed only AFTER the package has established its
   context, just as in a notebook's next input cell. *)
loadingReport = TestReport[{
  VerificationTest[{$Context, Context[AsymptoticExpansion],
    Names["Global`AsymptoticExpansion"], Names["Global`PowerLogSeries"],
    Count[Streams[], InputStream["String", _]] === loadingStringStreamsBefore},
    {"Global`", "AsymptoticInverse`", {}, {}, True}, TestID -> "loading-contexts-and-stream-cleanup"],
  VerificationTest[Module[{x, y, s},
    s = AsymptoticInverse[x + x^Sqrt[2], {x, 0}, y, SeriesTermGoal -> 3];
    MatchQ[s, _PowerLogSeries] && TrueQ[FullSimplify[Normal[s] ==
      y - y^Sqrt[2] + Sqrt[2] y^(2 Sqrt[2] - 1), y > 0]]],
    True, TestID -> "loading-irrational-inverse"],
  VerificationTest[Module[{x, y, s},
    s = AsymptoticInverse[(Sqrt[1 + 4 x] - 1)/2, {x, 0}, y, SeriesTermGoal -> 3];
    {TrueQ[FullSimplify[Normal[s] == y + y^2]], s["Remainder"],
      s["ExactTerminationCertificate"]["Verified"]}],
    {True, 0, True},
    TestID -> "loading-early-exact-termination"],
  VerificationTest[Module[{x, s},
    s = AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity, SeriesTermGoal -> 3];
    MatchQ[s, _PowerLogSeries] && TrueQ[FullSimplify[Normal[s] ==
      3^(3 x - 1/2) x^(2 x) Exp[-2 x] (1 - 1/(18 x) + 1/(648 x^2)), x > 0]]],
    True, TestID -> "loading-gamma-ratio"],
  VerificationTest[Module[{x, s},
    s = AsymptoticExpansion[BesselK[0, x], x -> Infinity, SeriesTermGoal -> 3];
    MatchQ[s, _PowerLogSeries] && TrueQ[FullSimplify[Normal[s] ==
      Sqrt[Pi/(2 x)] Exp[-x] (1 - 1/(8 x) + 9/(128 x^2)), x > 0]]],
    True, TestID -> "loading-late-native-special-functions"],
  VerificationTest[Module[{x, a, b, s},
    a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
    b = AsymptoticExpansion[Cos[x], {x, 0, 4}]; s = a b;
    {Expand[Normal[s]] === x - 2 x^3/3, s["Remainder"] =!= 0,
      FreeQ[Normal[s], _PowerLogSeries | _PowerLogRemainder | _SeriesData],
      ! FreeQ[ToBoxes[s, StandardForm], _InterpretationBox]}],
    {True, True, True, True}, TestID -> "loading-arithmetic-normal-and-display"],
  VerificationTest[Module[{before, result, x, s},
    before = Length[UpValues[PowerLogSeries]];
    result = Check[loadingGet[], $Failed];
    s = AsymptoticExpansion[Zeta[x], x -> Infinity, SeriesTermGoal -> 3];
    {result =!= $Failed, Length[UpValues[PowerLogSeries]] === before,
      Normal[s] === 1 + 2^-x + 3^-x,
      Count[Streams[], InputStream["String", _]] === loadingStringStreamsBefore}],
    {True, True, True, True}, TestID -> "loading-explicit-reload-and-dirichlet" ]
}, ProgressReporting -> False];
loadingResults = (<|"TestID" -> #["TestID"], "Outcome" -> #["Outcome"],
  "ActualOutput" -> ToString[#["ActualOutput"], InputForm]|> &) /@ Values[loadingReport["TestResults"]];
Export[loadingOutput, <|"Kernel" -> $Version, "Source" -> loadingSource,
  "Mode" -> loadingMode, "GetMethod" -> ToString[loadingMethod, InputForm],
  "Succeeded" -> loadingReport["TestsSucceededCount"],
  "Failed" -> loadingReport["TestsFailedCount"], "Results" -> loadingResults|>, "RawJSON"];
Print["Succeeded: ", loadingReport["TestsSucceededCount"], "  Failed: ", loadingReport["TestsFailedCount"]];
Do[If[result["Outcome"] =!= "Success", Print[InputForm[result]]], {result, loadingResults}];
Exit[If[loadingReport["TestsFailedCount"] === 0, 0, 1]];
