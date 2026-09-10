(* Native observation runner. Supplied, NOT executed during this audit.
   It reads an existing checkout, makes no source changes and records raw
   outcomes. Exit 0 means observations were written, NOT that defects passed. *)
repo = Environment["ASYMPTOTIC_REPO"];
If[! StringQ[repo] || repo === "", Print["Set ASYMPTOTIC_REPO to a local checkout."]; Exit[2]];
kernel = FileNameJoin[{repo, "src", "Kernel", "AsymptoticAnalysis.wl"}];
If[! FileExistsQ[kernel], Print["Canonical package loader not found: ", kernel]; Exit[2]];
loaded = Quiet[Check[Get[kernel]; True, False]];
If[! TrueQ[loaded] || Names["AsymptoticAnalysis`SeriesObservable"] === {},
  Print["Package load failed. No observations were accepted."]; Exit[2]];

SetAttributes[observe, HoldRest];
observations = {};
observe[label_String, expression_] := Module[{value, seconds, messages},
  Block[{$MessageList = {}, $RecursionLimit = 4096},
    {seconds, value} = AbsoluteTiming[TimeConstrained[expression, 60, $TimedOut]];
    messages = ToString[#, InputForm] & /@ $MessageList];
  AppendTo[observations, <|"Name" -> label, "ElapsedSeconds" -> seconds,
    "TimedOut" -> (value === $TimedOut), "ResultInputForm" -> ToString[value, InputForm],
    "Messages" -> messages|>]];

observe["N01-public-regularity-chain",
 Module[{x, y, z, s, exactIdentity, remainder, differentiated, absolute, result, chain},
  s = AsymptoticAnalysis`AsymptoticInverse[x, {x, 0}, {y, 2}, "InputRemainder" -> {3, 0}];
  exactIdentity = AsymptoticAnalysis`AsymptoticExpansion[y, {y, 0, 4}, "Backend" -> "Package"];
  If[FailureQ[s] || FailureQ[exactIdentity], Return[{s, exactIdentity}, Module]];
  remainder = AsymptoticAnalysis`SeriesAdd[s,
    AsymptoticAnalysis`SeriesMultiply[exactIdentity, -1]];
  If[FailureQ[remainder], Return[remainder, Module]];
  differentiated = AsymptoticAnalysis`SeriesDifferentiate[remainder, 1,
    "RemainderDerivativeOrder" -> 2];
  If[FailureQ[differentiated], Return[differentiated, Module]];
  absolute = AsymptoticAnalysis`SeriesObservable[differentiated, Abs[z], z];
  If[FailureQ[absolute], Return[absolute, Module]];
  result = AsymptoticAnalysis`SeriesDifferentiate[absolute];
  chain = ({Normal[#], #["RemainderPower"], #["RemainderDerivativeOrder"]} &) /@
    {remainder, differentiated, absolute};
  <|"Chain" -> chain, "FinalResult" -> result,
    "FinalDifferentiationRefused" -> FailureQ[result]|>]];

observe["N01-exact-sign-known-control",
 Module[{y, z, s, a},
  s = AsymptoticAnalysis`AsymptoticExpansion[-y - y^2, {y, 0, 4}, "Backend" -> "Package"];
  a = AsymptoticAnalysis`SeriesObservable[s, Abs[z], z];
  {Normal[a], a["Remainder"], Normal[AsymptoticAnalysis`SeriesDifferentiate[a]]}]];

Do[With[{depth = d}, observe["N02-Horner-depth-" <> ToString[depth],
 Module[{x, expr, result, time, ctx},
  expr = Nest[1 + x # &, 1 + x^2, depth];
  ctx = <|"SeriesOrder" -> 12, "Bits" -> 88, "ExponentMagnitudeLimit" -> 10000|>;
  {time, result} = AbsoluteTiming[
    AsymptoticAnalysis`Private`certEnclose[expr, x, {0, 1/2}, ctx]];
  <|"Depth" -> depth, "LeafCount" -> LeafCount[expr],
    "EnclosureSeconds" -> time, "Enclosure" -> result|>]]], {d, {8, 16, 32, 64}}];

Do[With[{n = count}, observe["N03-Zeta-noop-" <> ToString[n],
 Module[{x, s, r, time, cutoff},
  s = AsymptoticAnalysis`AsymptoticExpansion[Zeta[x], {x, Infinity, Log[n + 1]},
    "Backend" -> "Package", "MaxTerms" -> 200000];
  If[FailureQ[s], Return[s, Module]];
  cutoff = Log[n + 2];
  {time, r} = AbsoluteTiming[AsymptoticAnalysis`SeriesTruncate[s, cutoff, "MaxTerms" -> 200000]];
  <|"RequestedBlocks" -> n, "ActualBlocks" -> Length[s["Blocks"]],
    "TruncationSeconds" -> time, "Result" -> r,
    "BoundPreserved" -> (r["AbsoluteRemainderBound"] === s["AbsoluteRemainderBound"])|>]]],
  {count, {8, 16, 32, 64}}];

out = Environment["ASYMPTOTIC_AUDIT_OUTPUT"];
If[! StringQ[out] || out === "",
  out = FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]], "evidence", "native_observations.json"}]];
commit = Quiet[Check[StringTrim[RunProcess[{"git", "-C", repo, "rev-parse", "HEAD"}, "StandardOutput"]], "Unavailable"]];
report = <|"Scope" -> "Native observations, not a full upstream test suite",
  "KernelVersion" -> $Version, "ExpectedCommit" -> "651f2029d0b2cd4da9e4dfdf1f4275a124d23b99",
  "ObservedCommit" -> commit, "Repository" -> repo, "Observations" -> observations|>;
If[Export[out, report, "RawJSON"] === $Failed, Print["Could not write observations."]; Exit[2]];
Print["Wrote ", out, ". Inspect results; exit 0 is not a correctness verdict."];
Exit[0];
