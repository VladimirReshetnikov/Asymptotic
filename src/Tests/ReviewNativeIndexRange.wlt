(* C17: native integer representability is independent of sparse support and
   dense allocation length. Native boundary probes establish the signed-word
   fields and nonnegative signed-word order difference. Return booleans so
   JSON test receipts need not serialize the most-negative machine integer. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

nativeIndexRangeQ[value_] := MatchQ[value, Missing["NativeSeriesDataRange", _Association]];

VerificationTest[
  Module[{x, large = 2^100, s},
    s = AsymptoticExpansion[1 + x^large, {x, 0, large}];
    MatchQ[s, _GeneralizedSeries] && Normal[s] === 1 && s["Terms"] === {{0, 1}} &&
      s["Remainder"] === PowerLogRemainder[x, large, 0] && nativeIndexRangeQ[s["SeriesData"]] &&
      s["SeriesData"][[2]]["Indices"] === {0, large, 1}],
  True, TestID -> "review-native-index-huge-remainder-keeps-one-slot-sparse-result"]

VerificationTest[
  Module[{x, large = 2^100, s},
    s = AsymptoticExpansion[x^(1/large) + x, {x, 0, 1}];
    MatchQ[s, _GeneralizedSeries] && Normal[s] === x^(1/large) &&
      s["Remainder"] === PowerLogRemainder[x, 1, 0] && nativeIndexRangeQ[s["SeriesData"]] &&
      s["SeriesData"][[2]]["Indices"] === {1, large, large}],
  True, TestID -> "review-native-index-huge-denominator-keeps-fractional-sparse-result"]

VerificationTest[
  Module[{x, large = 2^100, s},
    s = AsymptoticExpansion[x^-large + 1, {x, 0, 0}];
    MatchQ[s, _GeneralizedSeries] && Normal[s] === x^-large &&
      s["Remainder"] === PowerLogRemainder[x, 0, 0] && nativeIndexRangeQ[s["SeriesData"]] &&
      s["SeriesData"][[2]]["Indices"] === {-large, 0, 1}],
  True, TestID -> "review-native-index-huge-negative-index-keeps-laurent-term"]

VerificationTest[
  Module[{x, large = 2^100, s},
    s = AsymptoticExpansion[x^large, {x, 0, 1}];
    MatchQ[s, _GeneralizedSeries] && Normal[s] === 0 && s["Terms"] === {} &&
      s["Remainder"] === PowerLogRemainder[x, large, 0] && nativeIndexRangeQ[s["SeriesData"]] &&
      s["SeriesData"][[2]]["OrderSpan"] === 0],
  True, TestID -> "review-native-index-empty-finite-part-still-checks-order-indices"]

VerificationTest[
  Module[{x, large = 2^100, s},
    s = AsymptoticExpansion[1 + x^-large, {x, Infinity, large}];
    MatchQ[s, _GeneralizedSeries] && Normal[s] === 1 &&
      s["Remainder"] === PowerLogRemainder[1/x, large, 0] && nativeIndexRangeQ[s["SeriesData"]]],
  True, TestID -> "review-native-index-infinity-uses-the-positive-small-coordinate-order"]

VerificationTest[
  Module[{x, b = 2^($SystemWordLength - 1), sd},
    sd = AsymptoticAnalysis`Private`makeRationalSeriesData[{{-b, 1}}, x, 0, {-b + 1, 0}];
    MatchQ[sd, _SeriesData] && sd[[3]] === {1} && sd[[4]] === -b && sd[[5]] === -b + 1 &&
      sd[[6]] === 1 && sd === SeriesData[x, 0, {1}, -b, -b + 1, 1]],
  True, TestID -> "review-native-index-most-negative-index-is-valid-with-a-short-span"]

VerificationTest[
  Module[{x, b = 2^($SystemWordLength - 1), lower, upper},
    lower = AsymptoticAnalysis`Private`makeRationalSeriesData[{}, x, 0, {-b, 0}];
    upper = AsymptoticAnalysis`Private`makeRationalSeriesData[{}, x, 0, {b - 1, 0}];
    MatchQ[lower, _SeriesData] && MatchQ[upper, _SeriesData] &&
      lower[[3]] === {} && lower[[4]] === -b && lower[[5]] === -b &&
      upper[[3]] === {} && upper[[4]] === b - 1 && upper[[5]] === b - 1],
  True, TestID -> "review-native-index-pure-remainders-accept-both-signed-boundaries"]

VerificationTest[
  Module[{x, maximum = 2^($SystemWordLength - 1) - 1, sd},
    sd = AsymptoticAnalysis`Private`makeRationalSeriesData[{{1/maximum, 1}}, x, 0, {1, 0}];
    MatchQ[sd, _SeriesData] && sd[[3]] === {1} && sd[[4]] === 1 &&
      sd[[5]] === maximum && sd[[6]] === maximum],
  True, TestID -> "review-native-index-maximum-denominator-does-not-require-dense-tail-padding"]

VerificationTest[
  Module[{x, b = 2^($SystemWordLength - 1), sd},
    sd = AsymptoticAnalysis`Private`makeRationalSeriesData[{{0, 1}}, x, 0, {1/b, 0}];
    nativeIndexRangeQ[sd] && sd[[2]]["Indices"] === {0, 1, b} &&
      sd[[2]]["OrderSpan"] === 1 && sd[[2]]["MaximumDenominator"] === b - 1],
  True, TestID -> "review-native-index-denominator-overflow-is-independent-of-small-indices"]

VerificationTest[
  Module[{x, b = 2^($SystemWordLength - 1), lower, upper},
    lower = AsymptoticAnalysis`Private`makeRationalSeriesData[{{-b - 1, 1}}, x, 0, {-b, 0}];
    upper = AsymptoticAnalysis`Private`makeRationalSeriesData[{{b - 1, 1}}, x, 0, {b, 0}];
    nativeIndexRangeQ[lower] && nativeIndexRangeQ[upper] &&
      lower[[2]]["OrderSpan"] === 1 && upper[[2]]["OrderSpan"] === 1 &&
      lower[[2]]["AllowedIndexRange"] === {-b, b - 1}],
  True, TestID -> "review-native-index-next-signed-indices-are-rejected-even-with-one-step-span"]

VerificationTest[
  Module[{x, maximum = 2^($SystemWordLength - 1) - 1, sd},
    sd = AsymptoticAnalysis`Private`makeRationalSeriesData[{{-maximum, 1}}, x, 0, {0, 0}];
    MatchQ[sd, _SeriesData] && sd[[3]] === {1} && sd[[4]] === -maximum && sd[[5]] === 0 &&
      sd === SeriesData[x, 0, {1}, -maximum, 0, 1]],
  True, TestID -> "review-native-index-largest-signed-order-span-retains-its-coefficient"]

VerificationTest[
  Module[{x, maximum = 2^($SystemWordLength - 1) - 1, a, b},
    a = AsymptoticAnalysis`Private`makeRationalSeriesData[{{-maximum, 1}}, x, 0, {1, 0}];
    b = AsymptoticAnalysis`Private`makeRationalSeriesData[{{-1, 1}}, x, 0, {maximum, 0}];
    nativeIndexRangeQ[a] && nativeIndexRangeQ[b] &&
      a[[2]]["OrderSpan"] === maximum + 1 && b[[2]]["OrderSpan"] === maximum + 1 &&
      a[[2]]["MaximumOrderSpan"] === maximum && b[[2]]["Indices"] === {-1, maximum, 1}],
  True, TestID -> "review-native-index-order-difference-overflow-cannot-silently-drop-coefficients"]

VerificationTest[
  Module[{x, maximum = 2^($SystemWordLength - 1) - 1, s},
    s = AsymptoticExpansion[x^-1 + x^maximum, {x, 0, maximum}];
    MatchQ[s, _GeneralizedSeries] && Normal[s] === 1/x && s["Terms"] === {{-1, 1}} &&
      s["Remainder"] === PowerLogRemainder[x, maximum, 0] && nativeIndexRangeQ[s["SeriesData"]] &&
      s["SeriesData"][[2]]["OrderSpan"] === maximum + 1],
  True, TestID -> "review-native-index-public-overflowing-span-preserves-the-sparse-laurent-term"]

VerificationTest[
  Module[{x, a, coord, sd, scalingCalls = 0, maximum = 2^($SystemWordLength - 1) - 1},
    a /: Power[a, _] := (scalingCalls++; 1);
    coord = AsymptoticAnalysis`Private`localCoordinate[x, 0, Automatic];
    sd = AsymptoticAnalysis`Private`makeInverseSeriesData[{{-maximum, 1}}, x, 0, a, coord, {1, 0}, 1, 0];
    nativeIndexRangeQ[sd] && scalingCalls === 0],
  True, TestID -> "review-native-index-shared-inverse-preflight-precedes-coefficient-scaling"]

VerificationTest[
  Module[{x, b = 2^($SystemWordLength - 1), range, density},
    range = AsymptoticAnalysis`Private`makeRationalSeriesData[{{0, 1}, {b - 1, 2}}, x, 0, {b, 0}];
    density = AsymptoticAnalysis`Private`makeRationalSeriesData[{{0, 1}, {100000, 2}}, x, 0, {100001, 0}];
    nativeIndexRangeQ[range] &&
      density === Missing["DenseSeriesDataLimit", <|"RequiredCoefficients" -> 100001, "Limit" -> 100000|>]],
  True, TestID -> "review-native-index-range-precedes-density-and-preserves-existing-density-refusal"]

VerificationTest[
  Module[{x, coord, large = 2^100, make},
    coord = AsymptoticAnalysis`Private`localCoordinate[x, 0, Automatic];
    make[terms_, remainder_] := AsymptoticAnalysis`Private`makeRationalSeriesData[terms, x, 0, remainder];
    AsymptoticAnalysis`Private`makeSeriesData[{{large, 1}}, x, -Infinity, coord, {large + 1, 0}, Log[x]] === Missing["NotAvailable"] &&
      make[{{Sqrt[2], 1}}, None] === Missing["IrrationalExponents"] &&
      make[{{large, 1}}, None] === Missing["Exact"] &&
      make[{{large, 1}}, {Sqrt[2], 0}] === Missing["IrrationalExponents"] &&
      make[{{0, 1}}, {large, 1}] === Missing["LogarithmicRemainder",
        <|"RemainderPower" -> large, "RemainderLogDegree" -> 1|>]],
  True, TestID -> "review-native-index-preserves-coordinate-exact-irrational-and-log-tail-precedence"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[x^(1/1000000007) + x, {x, 0, 1}];
    MatchQ[s, _GeneralizedSeries] &&
      s["SeriesData"] === SeriesData[x, 0, {1}, 1, 1000000007, 1000000007] &&
      Normal[s] === x^(1/1000000007) && s["RemainderPower"] === 1],
  True, TestID -> "review-native-index-retains-the-existing-billion-denominator-valid-control"]
