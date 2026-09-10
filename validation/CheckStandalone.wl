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
loadingLegacyNames[] := Join[Names["AsymptoticInverse`*"], Names["AsymptoticInverse`Private`*"]];
If[MemberQ[$Packages, "AsymptoticAnalysis`"] ||
    Names["AsymptoticAnalysis`*"] =!= {} ||
    MemberQ[$Packages, "AsymptoticInverse`"] || loadingLegacyNames[] =!= {} ||
    Names["Global`AsymptoticExpansion"] =!= {} ||
    Names["Global`GeneralizedSeries"] =!= {},
  Print["Acceptance checks require a kernel without preloaded package definitions."];
  Exit[2]];
If[loadingMode =!= "Paclet" && StringQ[loadingPath] && loadingPath =!= "", PrependTo[$Path, loadingPath]];
loadingStringStreamsBefore = Count[Streams[], InputStream["String", _]];
loadingResult = If[loadingMode === "Missing", Quiet[Check[loadingGet[], $Failed]],
  Check[Switch[loadingMode,
    "Needs", Needs["AsymptoticAnalysis`"],
    "Paclet", PacletDirectoryLoad[loadingPath]; Needs["AsymptoticAnalysis`"],
    _, loadingGet[]], $Failed]];
If[loadingMode === "Missing",
  loadingChecks = {loadingResult === $Failed,
    ! MemberQ[$Packages, "AsymptoticAnalysis`"], $Context === "Global`"};
  Export[loadingOutput, <|"Kernel" -> $Version, "Source" -> loadingSource,
    "Mode" -> loadingMode, "Succeeded" -> Count[loadingChecks, True],
    "Failed" -> Count[loadingChecks, Except[True]], "Checks" -> loadingChecks|>, "RawJSON"];
  Exit[If[And @@ loadingChecks, 0, 1]]];
If[loadingResult === $Failed || ! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Print["Package loading failed: ", loadingSource]; Exit[1]];

(* These expressions are parsed only AFTER the package has established its
   context, just as in a notebook's next input cell. *)
loadingReport = TestReport[{
  VerificationTest[{Names["AsymptoticAnalysis`Mathics`*"],
      MemberQ[$ContextPath, "AsymptoticAnalysis`Mathics`"],
      Context[Module], Context[Return], Context[Lookup], Context[Simplify]},
    {{}, False, "System`", "System`", "System`", "System`"},
    TestID -> "loading-mathics-adapters-remain-unparsed-on-native-wolfram"],
  VerificationTest[Module[{x, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s},
    s = AsymptoticExpansion[x^a - x^b + x^2, {x, 0},
      SeriesTermGoal -> 1, "Backend" -> "Package"];
    {Normal[s] === x^2, s["Remainder"], s["ReturnedTermCount"]}],
    {True, 0, 1}, TestID -> "loading-exact-equal-exponents-cancel-before-counting"],
  VerificationTest[Module[{x, a, outer, inner, s},
    outer = AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 0,
      "Backend" -> "Package"];
    inner = AsymptoticExpansion[a, {a, 0, 4}, "Backend" -> "Package"];
    s = SeriesCompose[outer, inner];
    {Normal[s], s["Remainder"], s["Exact"]}],
    {1/2, 0, True}, TestID -> "loading-diagonal-composition-replays-joint-source"],
  VerificationTest[Quiet[Module[{x, s},
    s = AsymptoticExpand[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 0];
    {Normal[s] === {1, x}, s["NativeBackend"],
      Lookup[s["NativeAttempts"], "EvaluationStatus"]}]],
    {True, "Series", {"Unresolved", "Computed"}},
    TestID -> "loading-second-native-backend-finds-successful-result"],
  VerificationTest[{
      Context[AsymptoticInverse], Context[AsymptoticExpansion], Context[GeneralizedSeries],
      MemberQ[$Packages, "AsymptoticAnalysis`"],
      MemberQ[$Packages, "AsymptoticInverse`"], loadingLegacyNames[]},
    {"AsymptoticAnalysis`", "AsymptoticAnalysis`", "AsymptoticAnalysis`", True, False, {}},
    TestID -> "loading-renamed-context-preserves-public-inverse-name-without-legacy-definitions"],
  VerificationTest[Module[{x, s},
    s = AsymptoticExpand[Exp[I x], {x, 0, 3}];
    {s["Kind"], s["OrderConvention"],
      s["NativeResult"] === Series[Exp[I x], {x, 0, 3}]}],
    {"Native", "Native", True}, TestID -> "loading-automatic-native-representation-fallback"],
  VerificationTest[Module[{x, y, s, c},
    s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
    c = InverseCertificate[s, 2, "Interval" -> {1, 2}, "RelativeError" -> 10^-120,
      "MaxRefinements" -> 3, "RefineExpansion" -> False];
    AssociationQ[c] && TrueQ[c["AccuracyGoalReached"]] &&
      c["CertifiedRelativeErrorBound"] <= 10^-120],
    True, TestID -> "loading-relative-certificate-review18-repair"],
  VerificationTest[Module[{x, s},
    s = AsymptoticExpand[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
    {Context[AsymptoticExpand], s["Kind"],
      s["NativeResult"] === Series[Exp[I x], {x, 0, 3}],
      s["Exact"] === Missing["NotEstablished"]}],
    {"AsymptoticAnalysis`", "Native", True, True}, TestID -> "loading-native-series-and-held-alias"],
  VerificationTest[Module[{x, s},
    s = AsymptoticExpansion[Sin[x], x -> 0, "Backend" -> "Asymptotic"];
    {Normal[s] === Asymptotic[Sin[x], x -> 0],
      MatchQ[SeriesRefine[s, 4], Failure["NativeSeriesContract", _Association]]}],
    {True, True}, TestID -> "loading-native-asymptotic-contract-guard"],
  VerificationTest[{$Context, Context[AsymptoticExpansion],
    Names["Global`AsymptoticExpansion"], Names["Global`GeneralizedSeries"],
    Count[Streams[], InputStream["String", _]] === loadingStringStreamsBefore},
    {"Global`", "AsymptoticAnalysis`", {}, {}, True}, TestID -> "loading-contexts-and-stream-cleanup"],
  VerificationTest[Module[{x, y, s},
    s = AsymptoticInverse[x + x^Sqrt[2], {x, 0}, y, SeriesTermGoal -> 3];
    MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[s] ==
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
    MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[s] ==
      3^(3 x - 1/2) x^(2 x) Exp[-2 x] (1 - 1/(18 x) + 1/(648 x^2)), x > 0]]],
    True, TestID -> "loading-gamma-ratio"],
  VerificationTest[Module[{x, s},
    s = AsymptoticExpansion[BesselK[0, x], x -> Infinity, SeriesTermGoal -> 3];
    MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[s] ==
      Sqrt[Pi/(2 x)] Exp[-x] (1 - 1/(8 x) + 9/(128 x^2)), x > 0]]],
    True, TestID -> "loading-late-native-special-functions"],
  VerificationTest[Module[{x, a, b, s},
    a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
    b = AsymptoticExpansion[Cos[x], {x, 0, 4}]; s = a b;
    {Expand[Normal[s]] === x - 2 x^3/3, s["Remainder"] =!= 0,
      FreeQ[Normal[s], _GeneralizedSeries | _PowerLogRemainder | _SeriesData],
      ! FreeQ[ToBoxes[s, StandardForm], _InterpretationBox]}],
    {True, True, True, True}, TestID -> "loading-arithmetic-normal-and-display"],
  VerificationTest[Module[{before, result, x, s},
    before = Length[UpValues[GeneralizedSeries]];
    result = Check[loadingGet[], $Failed];
    s = AsymptoticExpansion[Zeta[x], x -> Infinity, SeriesTermGoal -> 3];
    {result =!= $Failed, Length[UpValues[GeneralizedSeries]] === before,
      Normal[s] === 1 + 2^-x + 3^-x,
      Count[Streams[], InputStream["String", _]] === loadingStringStreamsBefore,
      AsymptoticExpand[Sin[x], x -> 0, "Backend" -> "Asymptotic"]["NativeBackend"] === "Asymptotic",
      ! MemberQ[$Packages, "AsymptoticInverse`"] && loadingLegacyNames[] === {}}],
    {True, True, True, True, True, True}, TestID -> "loading-explicit-reload-and-dirichlet" ]
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
