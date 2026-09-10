(* Standalone deterministic campaign and the independent oracle shared by the
   modest generated regression suite. No package Private` jet, enumeration,
   Lagrange, Newton or residual helper is used to compute expected results.

   CLI: wolfram -script src/Tests/RunGeneratedCampaign.wl
   Optional environment variables: ASYMPTOTIC_CAMPAIGN_SEED, _CASES,
   _CASE_SECONDS, _SHRINK_ATTEMPTS, _SHRINK_SECONDS, _OUTPUT.
   Loading with GeneratedCampaign`$LibraryOnly=True defines helpers only. *)

If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

Begin["AsymptoticAnalysis`GeneratedCampaign`"];
$CampaignDirectory = DirectoryName[$InputFileName];
$DefaultSeed = 236369;
$OracleRevision = "native-marker-forward-substitution-v1";
$campaignTag = Unique["generatedCampaign$"];

campaignFailure[tag_, message_, data_: <||>] :=
  Throw[Failure[tag, Join[<|"MessageTemplate" -> message|>, data]], $campaignTag];
inputString[x_] := ToString[x, InputForm, PageWidth -> Infinity];
exactZeroQ[x_] := TrueQ[FullSimplify[x == 0]];
exactLessQ[a_, b_] := TrueQ[FullSimplify[a < b]];

(* The family cycle guarantees coverage independently of random choices.
   Randomness changes exact coefficients and the ordinary branch parameters. *)
generateCases[seed_Integer, count_Integer] := BlockRandom[
  SeedRandom[seed, Method -> "MersenneTwister"];
  Table[Module[{family = Mod[index - 1, 16] + 1, c, d, b, p, a, r, source = 0,
     sign = 1, offset = 0, contract = "Equality", name, h, degree = 1},
    p = RandomChoice[{-2, -1, 1, 3/2, 2}];
    a = RandomChoice[{-3, -1, 1, 2}]; r = RandomChoice[{-1, 1, 2}];
    d = {1/2, 1, 3/2}; name = "RationalLogPolynomials";
    Switch[family,
      2, d = {Sqrt[2]/2, Sqrt[3]/2}; name = "TwoIrrationalGaps",
      3, d = {Sqrt[2]/2, Sqrt[3]/2, Sqrt[5]/2}; name = "ThreeIrrationalGaps",
      4, d = {1, 2, 3}; p = 1; r = 1; name = "RationalCancellation",
      5, d = {Sqrt[2], Sqrt[3], Sqrt[2] + Sqrt[3]}; p = 1; r = 1;
         name = "IrrationalCollisionCancellation",
      6, source = 3; sign = -1; p = 2; offset = -2; name = "LeftTranslatedLogBranch",
      7, source = Infinity; p = 3/2; offset = 2; name = "ReciprocalSourceCoordinate",
      8, source = -Infinity; sign = -1; p = -2; name = "NegativeInfinityAndLeadingPower",
      9, p = 3/2; r = -2; name = "NonunitLeadingAndObservablePowers",
      10, degree = 2; d = {1, 3/2}; name = "QuadraticLogAmplitudes",
      11, d = {Sqrt[2]/2, Sqrt[3]/2}; contract = "DeclaredRemainder";
          name = "DeclaredRemainderAtBoundary",
      12, d = {Sqrt[2]/2, Sqrt[3]/2}; contract = "InputOrderRejection";
          name = "DeclaredRemainderBeyondBoundary",
      13, d = {1, Sqrt[2]}; contract = "ResourceLimit"; name = "IndexBudgetRejection",
      14, d = {1, 1, 2}; name = "DuplicateGapInputCancellation",
      15, Return[<|"Seed" -> seed, "Index" -> index, "Family" -> "ExactSourceLogCoordinate",
            "Contract" -> "ExactCoordinate", "Chart" -> "SourceLog",
            "Scale" -> RandomChoice[{1, 2, 3}], "Offset" -> RandomChoice[{-2, 0, 3}]|>, Module],
      16, Return[<|"Seed" -> seed, "Index" -> index, "Family" -> "ExactTargetLogCoordinate",
            "Contract" -> "ExactCoordinate", "Chart" -> "TargetLog",
            "Scale" -> RandomChoice[{1, 2, 3}], "Offset" -> RandomChoice[{-2, 0, 3}]|>, Module]];
    b = Table[RandomChoice[{-2, -1, 1, 2}] +
      Sum[RandomChoice[{-1, 0, 1}] logarithm^j, {j, degree}], {Length[d]}];
    If[family === 4, c = RandomChoice[{-2, -1, 1, 2}]; b = {c, 2 c^2, -1}];
    If[family === 5, b = {1, -2, -2 (2 + Sqrt[2] + Sqrt[3])}];
    If[family === 14, b = {1 + logarithm, -1 - logarithm, 2 - logarithm}];
    h = If[MemberQ[{"DeclaredRemainder", "InputOrderRejection"}, contract],
      2 (Min @@ d), 3 (Min @@ d)];
    <|"Seed" -> seed, "Index" -> index, "Family" -> name, "Contract" -> contract,
      "LeadingPower" -> p, "LeadingCoefficient" -> a, "ObservablePower" -> r,
      "SourcePoint" -> source, "SourceSign" -> sign, "TargetOffset" -> offset,
      "Gaps" -> d, "Polynomials" -> b, "RelativeCutoff" -> h|>], {index, count}]];

caseSpecification[c_Association] := Module[{p, a, r, ri, point, sign, u, f, cut, opts, h},
  If[c["Contract"] === "ExactCoordinate",
    If[c["Chart"] === "SourceLog",
      f = c["Offset"] + c["Scale"] Log[Log[source]];
      Return[<|"Function" -> f, "SourcePoint" -> Infinity, "Cutoff" -> 3,
        "Options" -> {}, "Expected" -> Exp[Exp[(target - c["Offset"])/c["Scale"]]],
        "Domain" -> target > c["Offset"]|>, Module],
      f = c["Offset"] + c["Scale"] Exp[-1/source^2];
      Return[<|"Function" -> f, "SourcePoint" -> 0, "Cutoff" -> 3,
        "Options" -> {}, "Expected" -> 1/Sqrt[-Log[(target - c["Offset"])/c["Scale"]]],
        "Domain" -> c["Offset"] < target < c["Offset"] + c["Scale"]|>, Module]]];
  {p, a, r, point, sign, h} = Lookup[c,
    {"LeadingPower", "LeadingCoefficient", "ObservablePower", "SourcePoint", "SourceSign", "RelativeCutoff"}];
  ri = If[MemberQ[{Infinity, -Infinity}, point], -r, r];
  u = If[MemberQ[{Infinity, -Infinity}, point], sign/source, sign (source - point)];
  f = c["TargetOffset"] + a u^p (1 + Total[MapThread[
    u^#1 (#2 /. logarithm -> Log[u]) &, {c["Gaps"], c["Polynomials"]}]]);
  cut = (ri + h)/Abs[p];
  opts = {"Power" -> r, Direction -> If[MemberQ[{Infinity, -Infinity}, point], Automatic,
    If[sign === 1, "FromAbove", "FromBelow"]]};
  If[MemberQ[{"DeclaredRemainder", "InputOrderRejection"}, c["Contract"]],
    AppendTo[opts, "InputRemainder" -> {p + h, 3}]];
  If[c["Contract"] === "InputOrderRejection", cut += (Min @@ c["Gaps"])/Abs[p]];
  If[c["Contract"] === "ResourceLimit", AppendTo[opts, "MaxTerms" -> 1]];
  <|"Function" -> f, "SourcePoint" -> point, "Cutoff" -> cut,
    "Options" -> opts, "InternalPower" -> ri,
    "TargetSubstitution" -> (target -> c["TargetOffset"] + a small^p)|>];

(* Introduce independent t_i and one bookkeeping marker e. Native Series
   computes coefficients of the forward substitution. At order n the fresh
   unknown has coefficient p, so a scalar linear solve determines it. *)
nativeOracle[c_Association] := Catch[Module[
  {p = c["LeadingPower"], d = c["Gaps"], polys = c["Polynomials"], h = c["RelativeCutoff"],
   r, sign = c["SourceSign"], point = c["SourcePoint"], e, fresh, t, nmax,
   unit = 0, trial, equation, coefficient, slope, value, residual, observed, rules, rows, expected},
  r = If[MemberQ[{Infinity, -Infinity}, point], -c["ObservablePower"], c["ObservablePower"]];
  nmax = Ceiling[FullSimplify[h/(Min @@ d)]] - 1;
  If[! IntegerQ[nmax] || nmax < 0 || nmax > 6,
    campaignFailure["OracleDepthLimit", "The independent routine oracle permits marker depth at most six."]];
  t = Table[Unique["marker$"], {Length[d]}];
  equation[w_] := (1 + w)^p - 1 + e Total[MapThread[
    #1 (1 + w)^(p + #2) (#3 /. logarithm -> logarithm + Log[1 + w]) &, {t, d, polys}]];
  Do[trial = unit + fresh e^n;
    coefficient = Expand[Coefficient[Normal[Series[equation[trial], {e, 0, n}]], e, n]];
    slope = Coefficient[coefficient, fresh];
    If[! PolynomialQ[coefficient, fresh] || Exponent[coefficient, fresh] =!= 1 || ! exactZeroQ[slope - p],
      campaignFailure["OracleNontriangular", "Native forward substitution did not give the expected scalar linear equation.",
        <|"Order" -> n, "Coefficient" -> coefficient|>]];
    value = Expand[-(coefficient /. fresh -> 0)/slope];
    If[! exactZeroQ[coefficient /. fresh -> value],
      campaignFailure["OracleSolveFailure", "The independently solved coefficient did not satisfy its equation."]];
    unit = Expand[unit + value e^n], {n, nmax}];
  residual = Expand[Normal[Series[equation[unit], {e, 0, nmax}]]];
  If[! exactZeroQ[residual],
    campaignFailure["OracleResidualFailure", "The independent oracle has a nonzero forward residual.", <|"Residual" -> residual|>]];
  observed = Expand[Normal[Series[(1 + unit)^r, {e, 0, nmax}]] /. e -> 1];
  rules = CoefficientRules[observed, t];
  rows = ({RootReduce[First[#] . d], Last[#]} &) /@ rules;
  rows = Select[rows, exactLessQ[First[#], h] &];
  expected = sign^c["ObservablePower"] Total[(small^(r + #[[1]]) (#[[2]] /. logarithm -> Log[small])) & /@ rows];
  If[! MemberQ[{Infinity, -Infinity}, point] && c["ObservablePower"] === 1, expected += point];
  <|"Expression" -> expected, "MarkerDepth" -> nmax, "ForwardResidual" -> residual,
    "UnmergedWeightedTerms" -> rows|>], $campaignTag];

checkCase[c_Association] := Module[{spec = caseSpecification[c], expected, oracle, s, actual, ok, cap, observedRemainder, tag},
  s = AsymptoticInverse[spec["Function"], {source, spec["SourcePoint"]}, {target, spec["Cutoff"]}, Sequence @@ spec["Options"]];
  If[MemberQ[{"InputOrderRejection", "ResourceLimit"}, c["Contract"]],
    tag = If[c["Contract"] === "ResourceLimit", "ResourceLimit", "InsufficientInputOrder"];
    ok = FailureQ[s] && s[[1]] === tag;
    Return[<|"Passed" -> ok, "FailureClass" -> If[ok, "None", "RejectionContractMismatch"],
      "Expected" -> ("Failure[" <> tag <> ", _Association]"), "Observed" -> inputString[s],
      "Operation" -> "AsymptoticInverse rejection contract"|>, Module]];
  If[FailureQ[s], Return[<|"Passed" -> False, "FailureClass" -> "UnexpectedFailure:" <> ToString[s[[1]]],
    "Expected" -> "A finite expansion satisfying the independent oracle", "Observed" -> inputString[s],
    "Operation" -> "AsymptoticInverse"|>, Module]];
  If[c["Contract"] === "ExactCoordinate",
    expected = spec["Expected"]; actual = Normal[s];
    ok = TrueQ[FullSimplify[actual == expected, spec["Domain"]]] && s["Remainder"] === 0;
    Return[<|"Passed" -> ok, "FailureClass" -> If[ok, "None", "ExactCoordinateMismatch"],
      "Expected" -> inputString[expected], "Observed" -> inputString[actual],
      "ObservedRemainder" -> inputString[s["Remainder"]], "Operation" -> "Exact inverse coordinate pair"|>, Module]];
  oracle = nativeOracle[c];
  If[FailureQ[oracle], Return[<|"Passed" -> False, "FailureClass" -> "OracleFailure:" <> ToString[oracle[[1]]],
    "Expected" -> "A triangular native forward-substitution oracle", "Observed" -> inputString[oracle],
    "Operation" -> "Independent oracle construction"|>, Module]];
  expected = oracle["Expression"]; actual = Normal[s] /. spec["TargetSubstitution"];
  ok = TrueQ[FullSimplify[actual == expected, small > 0]];
  If[c["Contract"] === "DeclaredRemainder",
    cap = spec["Cutoff"]; observedRemainder = {s["RemainderPower"], s["RemainderLogDegree"]};
    ok = ok && exactZeroQ[s["RemainderPower"] - cap] && TrueQ[s["RemainderLogDegree"] >= 3]];
  <|"Passed" -> ok, "FailureClass" -> If[ok, "None", If[c["Contract"] === "DeclaredRemainder",
      "DeclaredPrecisionMismatch", "CoefficientMismatch"]],
    "Expected" -> inputString[expected], "Observed" -> inputString[actual],
    "ObservedRemainder" -> inputString[s["Remainder"]],
    "MarkerDepth" -> oracle["MarkerDepth"], "OracleForwardResidual" -> inputString[oracle["ForwardResidual"]],
    "Operation" -> "Native forward-substitution coefficient oracle"|>];

evaluateCase[c_, seconds_, messagePath_: None] := Module[{result, messages, stream, elapsed},
  stream = If[StringQ[messagePath], OpenWrite[messagePath, CharacterEncoding -> "UTF8"], None];
  elapsed = AbsoluteTiming[
    Block[{$MessageList = {}, $Messages = If[stream === None, $Messages, {stream}]},
      result = TimeConstrained[CheckAbort[checkCase[c],
        <|"Passed" -> False, "FailureClass" -> "CaseAborted", "Observed" -> "$Aborted"|>], seconds,
        <|"Passed" -> False, "FailureClass" -> "CaseTimeout", "Observed" -> "Per-case time limit reached"|>];
      messages = inputString /@ $MessageList;]][[1]];
  If[stream =!= None, Close[stream]];
  If[! AssociationQ[result], result = <|"Passed" -> False, "FailureClass" -> "MalformedCheckResult", "Observed" -> inputString[result]|>];
  If[messages =!= {} && TrueQ[result["Passed"]],
    result = Join[result, <|"Passed" -> False, "FailureClass" -> "UnexpectedMessages"|>]];
  Join[result, <|"Messages" -> messages, "ElapsedSeconds" -> elapsed|>]];

(* A lexicographically decreasing tuple of nonnegative integers prevents
   cycles. Numeric approximations are not used to accept a shrink or an oracle. *)
caseComplexity[c_] := Module[{data, integers},
  If[c["Contract"] === "ExactCoordinate", Return[{0, 0, 0, 0, 0}, Module]];
  data = Lookup[c, {"Gaps", "Polynomials", "LeadingPower", "LeadingCoefficient", "ObservablePower",
    "SourcePoint", "SourceSign", "TargetOffset", "RelativeCutoff"}];
  integers = Cases[data, n : (_Integer | _Rational) :> Abs[Numerator[n]] + Denominator[n], Infinity];
  {Length[c["Gaps"]], Total[(If[# === 0, 0, 1 + Exponent[#, logarithm]]) & /@ c["Polynomials"]],
    LeafCount[data], Total[integers], StringLength[inputString[data]]}];
lexLess[a_List, b_List] := Module[{}, Do[If[a[[j]] < b[[j]], Return[True, Module]];
  If[a[[j]] > b[[j]], Return[False, Module]], {j, Length[a]}]; False];

shrinkCandidates[c_] := Module[{out = {}, d, b, q, old, h, candidate},
  If[c["Contract"] === "ExactCoordinate", Return[{}, Module]];
  d = c["Gaps"]; b = c["Polynomials"]; h = c["RelativeCutoff"];
  If[Length[d] > 1, Do[AppendTo[out, Join[c, <|"Gaps" -> Delete[d, j], "Polynomials" -> Delete[b, j]|>]], {j, Length[d]}]];
  Do[q = b[[j]];
    If[q =!= 0 && Exponent[q, logarithm] > 0,
      AppendTo[out, Join[c, <|"Polynomials" -> ReplacePart[b, j -> Expand[q - Coefficient[q, logarithm, Exponent[q, logarithm]] logarithm^Exponent[q, logarithm]]]|>]]];
    Do[AppendTo[out, Join[c, <|"Polynomials" -> ReplacePart[b, j -> reduced]|>]], {reduced, {0, 1, -1}}], {j, Length[b]}];
  Do[old = c[key];
    Do[AppendTo[out, Join[c, Association[key -> reduced]]], {reduced, If[key === "TargetOffset", {0}, {1, -1}]}],
    {key, {"LeadingCoefficient", "LeadingPower", "ObservablePower", "TargetOffset"}}];
  AppendTo[out, Join[c, <|"RelativeCutoff" -> 2 (Min @@ d)|>]];
  Do[AppendTo[out, Join[c, <|"Gaps" -> ReplacePart[d, j -> 1]|>]], {j, Length[d]}];
  Select[DeleteDuplicates[out], Function[v,
    lexLess[caseComplexity[v], caseComplexity[c]] &&
    And @@ (exactLessQ[0, #] & /@ v["Gaps"]) && exactLessQ[0, v["RelativeCutoff"]] &&
    TrueQ[Ceiling[FullSimplify[v["RelativeCutoff"]/(Min @@ v["Gaps"])]] - 1 <= 6] &&
    (! MemberQ[{"DeclaredRemainder", "InputOrderRejection"}, v["Contract"]] ||
      And @@ (exactLessQ[#, v["RelativeCutoff"]] & /@ v["Gaps"]))]]];

shrinkFailure[initial_, failureClass_String, evaluator_, maxAttempts_Integer, seconds_,
    onAccept_: Function[Null], onAttempt_: Function[Null]] :=
 Module[{best = initial, trail = {}, attempts = 0, candidates, result, accepted, timedOut = False},
  TimeConstrained[
    While[attempts < maxAttempts,
      candidates = shrinkCandidates[best]; accepted = False;
      Do[If[attempts >= maxAttempts, Break[]]; attempts++;
        result = evaluator[candidate];
        onAttempt[<|"Case" -> candidate, "Result" -> result, "Attempt" -> attempts|>];
        If[AssociationQ[result] && ! TrueQ[result["Passed"]] && result["FailureClass"] === failureClass,
          best = candidate; AppendTo[trail, <|"Case" -> best, "Result" -> result, "Attempt" -> attempts|>];
          onAccept[Last[trail], Length[trail]]; accepted = True; Break[]], {candidate, candidates}];
      If[! accepted, Break[]]], seconds, timedOut = True];
  <|"OriginalCase" -> initial, "ReducedCase" -> best, "AcceptedShrinks" -> trail,
    "Attempts" -> attempts, "TimeLimitReached" -> timedOut,
    "OriginalComplexity" -> caseComplexity[initial], "ReducedComplexity" -> caseComplexity[best]|>];

caseEvidence[c_, result_] := <|"Seed" -> c["Seed"], "Index" -> c["Index"], "Family" -> c["Family"],
  "Contract" -> c["Contract"], "CaseInputForm" -> inputString[c],
  "OperationInputForm" -> inputString[caseSpecification[c]], "Result" -> result|>;
fileDigest[path_] := IntegerString[FileHash[path, "SHA256"], 16, 64];
writeEvidence[path_, data_, format_] := Module[{result = Export[path, data, format]},
  If[result === $Failed, campaignFailure["EvidenceWriteFailure", "The campaign stopped because an evidence file could not be written.",
    <|"Path" -> path|>]]; result];
Options[RunCampaign] = {"Seed" -> 236369, "CaseCount" -> 24, "PerCaseSeconds" -> 30,
  "ShrinkAttempts" -> 24, "ShrinkSeconds" -> 60, "OutputDirectory" -> Automatic};
RunCampaign[OptionsPattern[]] := Catch[Module[
  {seed = OptionValue["Seed"], count = OptionValue["CaseCount"], seconds = OptionValue["PerCaseSeconds"],
   maxShrink = OptionValue["ShrinkAttempts"], shrinkSeconds = OptionValue["ShrinkSeconds"],
   directory = OptionValue["OutputDirectory"], cases, manifest, records = {}, result, reduced, prefix, path, summary,
   packagePath, callback, attemptCallback, shrinkEvaluation},
  If[! IntegerQ[seed] || seed < 0 || seed > 2^31 - 1 || ! IntegerQ[count] || ! 1 <= count <= 10000 ||
     ! IntegerQ[seconds] || ! 1 <= seconds <= 600 || ! IntegerQ[maxShrink] || ! 0 <= maxShrink <= 1000 ||
     ! IntegerQ[shrinkSeconds] || ! 1 <= shrinkSeconds <= 600,
    campaignFailure["InvalidCampaignOptions", "Campaign bounds must be exact integers in their documented finite ranges."]];
  If[directory === Automatic,
    directory = FileNameJoin[{$CampaignDirectory, "campaign-results", DateString[{"Year", "Month", "Day", "-", "Hour", "Minute", "Second"}] <> "-" <> CreateUUID[]}]];
  If[! StringQ[directory] || FileExistsQ[directory] || DirectoryQ[directory],
    campaignFailure["EvidenceDirectoryExists", "Supply a new evidence directory; existing campaign evidence is never overwritten."]];
  If[CreateDirectory[directory, CreateIntermediateDirectories -> True] === $Failed,
    campaignFailure["EvidenceWriteFailure", "The campaign evidence directory could not be created."]];
  packagePath = FileNameJoin[{DirectoryName[$CampaignDirectory], "Kernel", "AsymptoticAnalysis.wl"}];
  cases = generateCases[seed, count];
  manifest = <|"Seed" -> seed, "Generator" -> "MersenneTwister with deterministic 16-family cycle",
    "OracleRevision" -> $OracleRevision, "KernelVersion" -> $Version, "SystemID" -> $SystemID,
    "KernelVersionNumber" -> $VersionNumber, "CaseCount" -> count, "PerCaseSeconds" -> seconds,
    "ShrinkAttempts" -> maxShrink, "ShrinkSeconds" -> shrinkSeconds,
    "PackageSHA256" -> fileDigest[packagePath],
    "KernelSourceSHA256" -> Association[(FileNameTake[#] -> fileDigest[#]) & /@
      Sort[FileNames["*.wl", DirectoryName[packagePath]]]],
    "RunnerSHA256" -> fileDigest[FileNameJoin[{$CampaignDirectory, "RunGeneratedCampaign.wl"}]],
    "EvidenceBoundary" -> "Exact symbolic oracle comparisons and explicit rejection contracts on the recorded kernel only."|>;
  writeEvidence[FileNameJoin[{directory, "manifest.json"}], manifest, "RawJSON"];
  writeEvidence[FileNameJoin[{directory, "inputs.wl"}], inputString[cases], "Text"];
  Do[prefix = "case-" <> IntegerString[c["Index"], 10, 5];
    result = evaluateCase[c, seconds, FileNameJoin[{directory, prefix <> "-messages.txt"}]];
    (* Preserve the original observation before attempting any shrink. *)
    writeEvidence[FileNameJoin[{directory, prefix <> ".json"}], caseEvidence[c, result], "RawJSON"];
    AppendTo[records, <|"Index" -> c["Index"], "Family" -> c["Family"], "Passed" -> TrueQ[result["Passed"]],
      "FailureClass" -> result["FailureClass"], "EvidenceFile" -> (prefix <> ".json")|>];
    Print[prefix, " ", c["Family"], ": ", If[TrueQ[result["Passed"]], "passed", result["FailureClass"]]];
    If[! TrueQ[result["Passed"]] && maxShrink > 0,
      callback = Function[{entry, number}, writeEvidence[FileNameJoin[{directory,
        prefix <> "-shrink-" <> IntegerString[number, 10, 3] <> ".json"}],
        Join[caseEvidence[entry["Case"], entry["Result"]], <|"Attempt" -> entry["Attempt"]|>], "RawJSON"]];
      attemptCallback = Function[entry, writeEvidence[FileNameJoin[{directory,
        prefix <> "-attempt-" <> IntegerString[entry["Attempt"], 10, 4] <> ".json"}],
        caseEvidence[entry["Case"], entry["Result"]], "RawJSON"]];
      shrinkEvaluation = 0;
      reduced = shrinkFailure[c, result["FailureClass"], Function[v,
        shrinkEvaluation++; evaluateCase[v, seconds, FileNameJoin[{directory,
          prefix <> "-attempt-" <> IntegerString[shrinkEvaluation, 10, 4] <> "-messages.txt"}]]],
        maxShrink, shrinkSeconds, callback, attemptCallback];
      writeEvidence[FileNameJoin[{directory, prefix <> "-shrink-summary.json"}],
        <|"OriginalCaseInputForm" -> inputString[c], "ReducedCaseInputForm" -> inputString[reduced["ReducedCase"]],
          "AcceptedShrinks" -> Length[reduced["AcceptedShrinks"]], "Attempts" -> reduced["Attempts"],
          "TimeLimitReached" -> reduced["TimeLimitReached"], "OriginalComplexity" -> reduced["OriginalComplexity"],
          "ReducedComplexity" -> reduced["ReducedComplexity"]|>, "RawJSON"]], {c, cases}];
  summary = <|"KernelVersion" -> $Version, "Seed" -> seed, "Passed" -> Count[Lookup[records, "Passed"], True],
    "Failed" -> Count[Lookup[records, "Passed"], False], "Directory" -> ExpandFileName[directory], "Cases" -> records|>;
  writeEvidence[FileNameJoin[{directory, "summary.json"}], summary, "RawJSON"]; summary], $campaignTag];

environmentInteger[name_String, default_Integer] := Module[{value = Environment[name]},
  If[! StringQ[value] || value === "", Return[default, Module]];
  If[! StringMatchQ[value, DigitCharacter ..] || StringLength[value] > 10,
    Return[Failure["InvalidEnvironmentOption", <|"Name" -> name, "Value" -> value|>], Module]];
  FromDigits[value]];

If[! TrueQ[$LibraryOnly], Module[{result, output = Environment["ASYMPTOTIC_CAMPAIGN_OUTPUT"]},
  result = RunCampaign[
    "Seed" -> environmentInteger["ASYMPTOTIC_CAMPAIGN_SEED", 236369],
    "CaseCount" -> environmentInteger["ASYMPTOTIC_CAMPAIGN_CASES", 24],
    "PerCaseSeconds" -> environmentInteger["ASYMPTOTIC_CAMPAIGN_CASE_SECONDS", 30],
    "ShrinkAttempts" -> environmentInteger["ASYMPTOTIC_CAMPAIGN_SHRINK_ATTEMPTS", 24],
    "ShrinkSeconds" -> environmentInteger["ASYMPTOTIC_CAMPAIGN_SHRINK_SECONDS", 60],
    "OutputDirectory" -> If[StringQ[output] && output =!= "", output, Automatic]];
  Print[inputString[result]]; Exit[If[AssociationQ[result] && result["Failed"] === 0, 0, 1]]]];
End[];
