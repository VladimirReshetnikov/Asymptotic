(* Bounded public characterization of fixed-parameter composition scope.
   This records observations; it is not a passing acceptance suite. *)
root = DirectoryName[DirectoryName[$InputFileName]];
packageRoot = Environment["ASYMPTOTIC_PACKAGE_ROOT"];
If[! StringQ[packageRoot] || ! DirectoryQ[packageRoot], packageRoot = FileNameJoin[{root, "src"}]];
output = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
If[! StringQ[output] || output === "", output = FileNameJoin[{root, "validation", "composition-scope-probes.json"}]];
sources = Append[FileNames["*.wl", FileNameJoin[{packageRoot, "Kernel"}]], $InputFileName];
sourceKey[path_] := If[path === $InputFileName, "validation/ProbeCompositionScope.wl",
  "src/Kernel/" <> FileNameTake[path]];
hashes[] := Association[(sourceKey[#] -> IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ sources];
before = hashes[];
Get[FileNameJoin[{packageRoot, "Kernel", "AsymptoticAnalysis.wl"}]];
SetAttributes[probe, HoldRest];
probe[id_, body_] := Module[{seconds, value},
  {seconds, value} = AbsoluteTiming[Quiet[TimeConstrained[body, 30, $Aborted]]];
  Print[id, ": ", ToString[value, InputForm]];
  <|"Case" -> id, "Seconds" -> seconds, "TimedOut" -> (value === $Aborted),
    "ObservedResult" -> ToString[value, InputForm]|>];
summary[s_] := If[MatchQ[s, _GeneralizedSeries],
  {Normal[s], s["Remainder"], s["Assumptions"], s["TargetDomain"]}, s];
results = {
  probe["reported-rational-diagonal", Module[{x, a, o, i},
    o = AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 0];
    i = AsymptoticExpansion[a, {a, 0, 4}]; summary[SeriesCompose[o, i]]]],
  probe["parameter-hidden-in-discarded-source", Module[{x, a, o, i},
    o = AsymptoticExpansion[1 + x^2/a^2, {x, 0, 2}, Assumptions -> a > 0];
    i = AsymptoticExpansion[a, {a, 0, 4}]; summary[SeriesCompose[o, i]]]],
  probe["nonpolynomial-source-diagonal", Module[{x, a, o, i},
    o = AsymptoticExpansion[Cos[x/a], {x, 0, 2}, Assumptions -> a > 0];
    i = AsymptoticExpansion[a, {a, 0, 4}]; summary[SeriesCompose[o, i]]]],
  probe["derived-outer-keeps-hidden-source-scope", Module[{x, a, o, i},
    o = SeriesTruncate[AsymptoticExpansion[1 + x^2/a^2, {x, 0, 3}, Assumptions -> a > 0], 2];
    i = AsymptoticExpansion[a, {a, 0, 4}]; summary[SeriesCompose[o, i]]]],
  probe["inexact-inner-needs-new-error-analysis", Module[{x, a, o, i},
    o = AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 0];
    i = AsymptoticExpansion[a + a^2, {a, 0, 2}]; summary[SeriesCompose[o, i]]]],
  probe["exact-outer-valid-parameter-substitution", Module[{x, a, o, i},
    o = AsymptoticExpansion[x + a, {x, 0, 3}, Assumptions -> a > 0];
    i = AsymptoticExpansion[a, {a, 0, 4}]; summary[SeriesCompose[o, i]]]],
  probe["exact-outer-transports-inner-uncertainty", Module[{x, a, o, i},
    o = AsymptoticExpansion[x/a, {x, 0, 3}, Assumptions -> a > 0];
    i = AsymptoticExpansion[a + a^2, {a, 0, 2}]; summary[SeriesCompose[o, i]]]],
  probe["outer-parameter-condition-fails-on-diagonal", Module[{x, a, o, i},
    o = AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 1];
    i = AsymptoticExpansion[a, {a, 0, 4}]; summary[SeriesCompose[o, i]]]],
  probe["inverse-source-symbol-is-bound-not-fixed", Module[{x, y, o, i},
    o = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
    i = AsymptoticExpansion[x, {x, 0, 4}]; summary[SeriesCompose[o, i]]]],
  probe["same-variable-composition-control", Module[{x, o, i},
    o = AsymptoticExpansion[Sin[x], {x, 0, 5}];
    i = AsymptoticExpansion[x^2, {x, 0, 8}]; summary[SeriesCompose[o, i]]]]
};
unchanged = before === hashes[];
Export[output, <|"Kernel" -> $Version,
  "Scope" -> "Ten bounded composition-scope characterizations; independent diagonal values are 1/2, 2, and Cos[1]. Not an acceptance or full-suite run.",
  "PerProbeTimeConstraintSeconds" -> 30, "Results" -> results,
  "SourcesUnchangedDuringRun" -> unchanged, "TestedSourceSHA256" -> before|>, "RawJSON"];
Exit[If[TrueQ[unchanged], 0, 1]];
