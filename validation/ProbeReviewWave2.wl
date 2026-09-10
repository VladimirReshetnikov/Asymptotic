(* Bounded characterization, NOT a passing acceptance suite. Each result records
   current public behavior for a specific wave-2 finding, including open defects. *)
root = DirectoryName[DirectoryName[$InputFileName]];
sources = Append[FileNames["*.wl", FileNameJoin[{root, "AsymptoticAnalysis", "Kernel"}]], $InputFileName];
hashes[] := Association[(StringReplace[FileNameJoin[
  Drop[FileNameSplit[ExpandFileName[#]], Length[FileNameSplit[root]]]], "\\" -> "/"] ->
  IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@ sources];
before = hashes[];
Get[FileNameJoin[{root, "AsymptoticAnalysis", "Kernel", "AsymptoticAnalysis.wl"}]];
SetAttributes[probe, HoldRest];
probe[id_, body_] := Module[{seconds, value},
  {seconds, value} = AbsoluteTiming[Quiet[TimeConstrained[body, 30, $Aborted]]];
  Print[id, ": ", ToString[value, InputForm]];
  <|"Finding" -> id, "Seconds" -> seconds, "TimedOut" -> (value === $Aborted),
    "ObservedResult" -> ToString[value, InputForm]|>];
results = {
  probe["R10 N01 / R11 N01 / R12 N01: certificate context", Module[{x, y, s, c},
    s = AsymptoticInverse[ConditionalExpression[x, x > 100], {x, Infinity}, {y, 2}];
    c = Assuming[x > 100, InverseCertificate[s, 2, "Interval" -> {1, 3}, "Center" -> 2, "MaxRefinements" -> 0]];
    If[FailureQ[c], c[[1]], c]]],
  probe["R11 N02 / R14 N01: parameter captured by composition", Module[{x, a, outer, inner, s},
    outer = AsymptoticExpansion[x/(a + x), {x, 0, 2}, Assumptions -> a > 0];
    inner = AsymptoticExpansion[a, {a, 0, 4}];
    s = SeriesCompose[outer, inner];
    If[MatchQ[s, _GeneralizedSeries], {Normal[s], s["Remainder"], "ExactDiagonal" -> 1/2}, s]]],
  probe["R11 N03: opaque smooth function has no analytic tail proof", Module[{g, x, s},
    g[t_?NumericQ] := If[TrueQ[t == 0], 0, t^2 Log[1 + Abs[Log[Abs[t]]]]]; g'[0] = 0;
    s = AsymptoticExpansion[g[x], {x, 0, 2}];
    If[MatchQ[s, _GeneralizedSeries], {Normal[s], s["Remainder"]}, s]]],
  probe["R12 N02: known nonreal algebraic block before truncation", Module[{x, c, s},
    c = Root[5 + 5 # + #^5 &, 2];
    s = AsymptoticExpansion[c/x, {x, 0, -2}];
    If[FailureQ[s], s[[1]], {Normal[s], s["Remainder"]}]]],
  probe["R12 N03: native machine-index range", Module[{x, s},
    s = AsymptoticExpansion[1 + x^(2^100), {x, 0, 2}];
    If[MatchQ[s, _GeneralizedSeries], {Normal[s], s["SeriesData"]}, s]]],
  probe["R13 A1: semantic equal powers at product boundary", Module[{x, a, b, s, t},
    a = Sinh[1]^2; b = (Cosh[2] - 1)/2;
    s = AsymptoticExpansion[1 + x^a + x^b Log[x]^3 + x^(2 a), {x, 0, 2 a}];
    t = SeriesMultiply[s, s];
    If[MatchQ[t, _GeneralizedSeries], {t["RemainderLogDegree"], "RequiredDegree" -> 6}, t]]]
};
unchanged = before === hashes[];
Export[FileNameJoin[{root, "validation", "review-wave-2-intake.json"}], <|
  "Kernel" -> $Version, "Scope" -> "Six bounded public characterization probes for wave-2 findings. Open defects are recorded; this is not an acceptance suite or full-suite run.",
  "PerProbeTimeConstraintSeconds" -> 30, "Results" -> results,
  "SourcesUnchangedDuringRun" -> unchanged, "TestedSourceSHA256" -> before|>, "RawJSON"];
Exit[If[TrueQ[unchanged], 0, 1]];
