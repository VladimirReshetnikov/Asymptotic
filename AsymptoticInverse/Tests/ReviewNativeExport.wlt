(* Independent native-export contracts and bounded sparse-input regressions. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[x^(1/101) + x, {x, 0, 1}];
  {s["SeriesData"] === SeriesData[x, 0, {1}, 1, 101, 101], s["RemainderPower"]}],
  {True, 1},
  TestID -> "review-native-export-short-coefficients-retain-rational-tail-index"]

VerificationTest[Module[{x, s},
  s = MemoryConstrained[AsymptoticExpansion[x^(1/1000000007) + x, {x, 0, 1}], 64000000, $Aborted];
  {Head[s] === GeneralizedSeries, s["SeriesData"] === SeriesData[x, 0, {1}, 1, 1000000007, 1000000007],
   Normal[s] === x^(1/1000000007), s["Remainder"] === PowerLogRemainder[x, 1, 0]}],
  {True, True, True, True},
  TestID -> "review-native-export-billion-slot-tail-needs-only-one-coefficient"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[x^(1/100003) + x + x^2, {x, 0, 2}];
  {s["SeriesData"], Normal[s] === x^(1/100003) + x, s["RemainderPower"]}],
  {Missing["DenseSeriesDataLimit", <|"RequiredCoefficients" -> 100003, "Limit" -> 100000|>], True, 2},
  TestID -> "review-native-export-wide-retained-gap-skips-cache-without-losing-sparse-result"]

VerificationTest[Module[{x},
  AsymptoticExpansion[x^(1/100003) + x, {x, 0, 2}]["SeriesData"]],
  Missing["Exact"], TestID -> "review-native-export-exact-result-precedes-allocation-limit"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[x^(-1/101) + x^-1, {x, Infinity, 1}];
  {s["SeriesData"] === SeriesData[x, Infinity, {1}, 1, 101, 101],
   Normal[s] === x^(-1/101), s["RemainderPower"]}],
  {True, True, 1}, TestID -> "review-native-export-infinity-retains-local-exponent-sign"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[(x - 2)^(1/101) + x - 2, {x, 2, 1}];
  s["SeriesData"] === SeriesData[x, 2, {1}, 1, 101, 101]],
  True, TestID -> "review-native-export-translated-finite-coordinate"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[x^-2 + x^(-1/2) + x^2, {x, 0, 2}];
  s["SeriesData"] === SeriesData[x, 0, {1, 0, 0, 1}, -4, 4, 2]],
  True, TestID -> "review-native-export-negative-minimum-and-interior-zero-slots"]

VerificationTest[Module[{x, y, a, s, refined},
  s = AsymptoticInverse[a x + x^2, {x, 0}, {y, 3}, Assumptions -> a > 0];
  refined = SeriesRefine[s, 4];
  {s["SeriesData"] === SeriesData[y, 0, {1/a, -1/a^3}, 1, 3, 1],
   refined["SeriesData"] === SeriesData[y, 0, {1/a, -1/a^3, 2/a^5}, 1, 4, 1]}],
  {True, True}, TestID -> "review-native-export-symbolic-leading-scale-survives-refinement"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticInverse[5 + 2 x + x^2, {x, 0}, {y, 4}];
  s["SeriesData"] === SeriesData[y, 5, {1/2, -1/8, 1/16}, 1, 4, 1]],
  True, TestID -> "review-native-export-inverse-target-translation-and-coefficient-scaling"]

VerificationTest[Module[{x, coord, forward, inverse},
  coord = AsymptoticInverse`Private`localCoordinate[x, 0, Automatic];
  forward = AsymptoticInverse`Private`makeSeriesData[{}, x, 0, coord, {7/3, 0}, Log[x]];
  inverse = AsymptoticInverse`Private`makeInverseSeriesData[{}, x, 0, 2, coord, {7/3, 0}, 1, 0];
  {forward === SeriesData[x, 0, {}, 7, 7, 3], inverse === forward}],
  {True, True}, TestID -> "review-native-export-empty-jet-retains-pure-remainder-index"]

VerificationTest[Module[{x, coord, edge, wider},
  coord = AsymptoticInverse`Private`localCoordinate[x, 0, Automatic];
  edge = AsymptoticInverse`Private`makeSeriesData[{{0, 1}, {99999, 2}}, x, 0, coord, {100001, 0}, Log[x]];
  wider = AsymptoticInverse`Private`makeInverseSeriesData[{{0, 1}, {100000, 2}}, x, 0, 2, coord, {100001, 0}, 1, 0];
  {Length[edge[[3]]], Normal[edge] === 1 + 2 x^99999, wider}],
  {100000, True, Missing["DenseSeriesDataLimit", <|"RequiredCoefficients" -> 100001, "Limit" -> 100000|>]},
  TestID -> "review-native-export-shared-cap-includes-boundary-and-rejects-next-slot"]

VerificationTest[Module[{x, coord, make, inverse},
  coord = AsymptoticInverse`Private`localCoordinate[x, 0, Automatic];
  make[terms_, rem_] := AsymptoticInverse`Private`makeSeriesData[terms, x, 0, coord, rem, Log[x]];
  inverse[terms_, rem_] := AsymptoticInverse`Private`makeInverseSeriesData[terms, x, 0, 1, coord, rem, 1, 0];
  {make[{{Sqrt[2], 1}}, None], inverse[{{Sqrt[2], 1}}, None],
   make[{{1, 1}}, None], inverse[{{1, 1}}, None],
   make[{{1, 1}}, {Sqrt[2], 0}], inverse[{{1, 1}}, {Sqrt[2], 0}]}],
  {Missing["IrrationalExponents"], Missing["IrrationalExponents"], Missing["Exact"], Missing["Exact"],
   Missing["IrrationalExponents"], Missing["IrrationalExponents"]},
  TestID -> "review-native-export-irrational-and-exact-guard-precedence"]

VerificationTest[Module[{x, coord},
  coord = AsymptoticInverse`Private`localCoordinate[x, 0, Automatic];
  {AsymptoticInverse`Private`makeSeriesData[{{Sqrt[2], 1}}, x, -Infinity, coord, None, Log[x]],
   AsymptoticInverse`Private`makeSeriesData[{}, x, 0, Join[coord, <|"Direction" -> "FromBelow"|>], None, Log[x]],
   AsymptoticInverse`Private`makeInverseSeriesData[{}, x, 0, 1, coord, None, 2, 0]}],
  ConstantArray[Missing["NotAvailable"], 3],
  TestID -> "review-native-export-coordinate-guards-precede-content-inspection"]
