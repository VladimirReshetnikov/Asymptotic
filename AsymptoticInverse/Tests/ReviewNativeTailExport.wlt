(* C03: the optional native view must not drop a logarithmic error envelope.
   Retained logarithms remain valid native coefficients when the tail degree
   is zero. Native SeriesData itself uses formal series conventions. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[
  Module[{x, s, error},
    s = AsymptoticExpansion[x + x^2 Log[x], {x, 0, 2}];
    error = x + x^2 Log[x] - Normal[s];
    {Normal[s] === x, s["Remainder"] === PowerLogRemainder[x, 2, 1], s["SeriesData"],
      Limit[Abs[error]/x^2, x -> 0, Direction -> "FromAbove"],
      Limit[Abs[error]/(x^2 (1 + Abs[Log[x]])), x -> 0, Direction -> "FromAbove"]}],
  {True, True,
    Missing["LogarithmicRemainder", <|"RemainderPower" -> 2, "RemainderLogDegree" -> 1|>],
    Infinity, 1},
  TestID -> "review-native-tail-forward-log-envelope-has-unbounded-pure-power-error-ratio"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x + x^2 Log[x], {x, 0}, {y, 2}];
    {Normal[s] === y, s["Remainder"] === PowerLogRemainder[y, 2, 1], s["SeriesData"]}],
  {True, True, Missing["LogarithmicRemainder", <|"RemainderPower" -> 2, "RemainderLogDegree" -> 1|>]},
  TestID -> "review-native-tail-inverse-log-envelope-skips-only-optional-view"]

VerificationTest[
  Module[{x, s, pure},
    s = AsymptoticExpansion[1 + x^2 Log[x]^5, {x, 0, 2}];
    pure = AsymptoticExpansion[x^2 Log[x]^5, {x, 0, 2}];
    {Normal[s], Normal[pure], s["Remainder"] === PowerLogRemainder[x, 2, 5],
      pure["Remainder"] === PowerLogRemainder[x, 2, 5],
      s["SeriesData"], pure["SeriesData"]}],
  {1, 0, True, True,
    Missing["LogarithmicRemainder", <|"RemainderPower" -> 2, "RemainderLogDegree" -> 5|>],
    Missing["LogarithmicRemainder", <|"RemainderPower" -> 2, "RemainderLogDegree" -> 5|>]},
  TestID -> "review-native-tail-high-log-degree-and-empty-finite-part-retain-bound"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[(x - 2) + (x - 2)^2 Log[x - 2], {x, 2, 2}];
    {Normal[s] === x - 2, s["Remainder"] === PowerLogRemainder[x - 2, 2, 1],
      s["SeriesData"]}],
  {True, True, Missing["LogarithmicRemainder", <|"RemainderPower" -> 2, "RemainderLogDegree" -> 1|>]},
  TestID -> "review-native-tail-translated-forward-coordinate-keeps-logarithmic-envelope"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[1/x + Log[x]/x^2, {x, Infinity, 2}];
    {Normal[s] === 1/x, s["Remainder"] === PowerLogRemainder[1/x, 2, 1],
      s["SeriesData"]}],
  {True, True, Missing["LogarithmicRemainder", <|"RemainderPower" -> 2, "RemainderLogDegree" -> 1|>]},
  TestID -> "review-native-tail-positive-infinity-uses-small-coordinate-remainder-power"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[Sin[x] + x^2 Log[x], {x, 0, 6}];
    {s["SeriesData"] === SeriesData[x, 0, {1, Log[x], -1/6, 0, 1/120}, 1, 7, 1],
      s["Remainder"] === PowerLogRemainder[x, 7, 0],
      Expand[Normal[s] - (x + x^2 Log[x] - x^3/6 + x^5/120)] === 0}],
  {True, True, True},
  TestID -> "review-native-tail-retained-logarithmic-coefficients-with-pure-power-tail-still-export"]

VerificationTest[
  Module[{x, y, forward, inverse},
    forward = AsymptoticExpansion[Exp[x], {x, 0, 3}];
    inverse = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
    {forward["SeriesData"] === SeriesData[x, 0, {1, 1, 1/2}, 0, 3, 1],
      inverse["SeriesData"] === SeriesData[y, 0, {1, -1, 2}, 1, 4, 1]}],
  {True, True},
  TestID -> "review-native-tail-ordinary-forward-and-inverse-native-views-remain-available"]

VerificationTest[
  Module[{x, coarse, refined},
    coarse = AsymptoticExpansion[x + x^2 Log[x] + x^3, {x, 0, 2}];
    refined = SeriesRefine[coarse, 3];
    {coarse["SeriesData"],
      refined["SeriesData"] === SeriesData[x, 0, {1, Log[x]}, 1, 3, 1],
      refined["Remainder"] === PowerLogRemainder[x, 3, 0],
      Expand[Normal[refined] - (x + x^2 Log[x])] === 0}],
  {Missing["LogarithmicRemainder", <|"RemainderPower" -> 2, "RemainderLogDegree" -> 1|>],
    True, True, True},
  TestID -> "review-native-tail-refinement-can-move-logarithm-from-omitted-bound-into-retained-coefficient"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}, "InputRemainder" -> {3, 4}];
    {Normal[s] === y - y^2, s["Remainder"] === PowerLogRemainder[y, 3, 4],
      s["SeriesData"]}],
  {True, True, Missing["LogarithmicRemainder", <|"RemainderPower" -> 3, "RemainderLogDegree" -> 4|>]},
  TestID -> "review-native-tail-declared-input-logarithmic-error-is-preserved-after-inversion"]

VerificationTest[
  Module[{x, coord},
    coord = AsymptoticInverse`Private`localCoordinate[x, 0, Automatic];
    {AsymptoticInverse`Private`makeSeriesData[{{1, 1}}, x, -Infinity, coord, {2, 1}, Log[x]],
      AsymptoticInverse`Private`makeSeriesData[{{1, 1}}, x, 0,
        Join[coord, <|"Direction" -> "FromBelow"|>], {2, 1}, Log[x]],
      AsymptoticInverse`Private`makeInverseSeriesData[{{1, 1}}, x, 0, 1, coord, {2, 1}, 2, 0]}],
  ConstantArray[Missing["NotAvailable"], 3],
  TestID -> "review-native-tail-coordinate-refusals-precede-logarithmic-tail-classification"]

VerificationTest[
  Module[{x, coord, make, inverse},
    coord = AsymptoticInverse`Private`localCoordinate[x, 0, Automatic];
    make[terms_, rem_] := AsymptoticInverse`Private`makeSeriesData[terms, x, 0, coord, rem, Log[x]];
    inverse[terms_, rem_] := AsymptoticInverse`Private`makeInverseSeriesData[terms, x, 0, 1, coord, rem, 1, 0];
    {make[{{Sqrt[2], 1}}, {2, 1}], inverse[{{Sqrt[2], 1}}, {2, 1}],
      make[{{1, Log[x]}}, None], inverse[{{1, Log[x]}}, None],
      make[{{1, 1}}, {Sqrt[2], 1}], inverse[{{1, 1}}, {Sqrt[2], 1}]}],
  {Missing["IrrationalExponents"], Missing["IrrationalExponents"],
    Missing["Exact"], Missing["Exact"], Missing["IrrationalExponents"], Missing["IrrationalExponents"]},
  TestID -> "review-native-tail-exact-and-irrational-content-guards-keep-existing-precedence"]

VerificationTest[
  Module[{x, a, coord, terms},
    coord = AsymptoticInverse`Private`localCoordinate[x, 0, Automatic];
    terms = {{1/100003, 1}, {1, 1}};
    {AsymptoticInverse`Private`makeSeriesData[terms, x, 0, coord, {2, 3}, Log[x]],
      AsymptoticInverse`Private`makeInverseSeriesData[terms, x, 0, a, coord, {2, 3}, 1, 0]}],
  ConstantArray[Missing["LogarithmicRemainder", <|"RemainderPower" -> 2, "RemainderLogDegree" -> 3|>], 2],
  TestID -> "review-native-tail-logarithmic-bound-refusal-precedes-dense-allocation-and-coefficient-scaling"]
