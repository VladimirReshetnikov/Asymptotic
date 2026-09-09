(* Nonlinear truncation can create a larger logarithmic degree at the same
   power as an inherited input remainder. Expected finite expressions below
   use the elementary Taylor coefficients of Log[1+v], Exp[v], (1+v)^r,
   and Sin[v]. The degree bounds are conservative, not asserted minimal. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[x Log[x] + x^3, {x, 0, 2}];
    {Expand[Normal[s] - x Log[x]] === 0,
      s["RemainderPower"], s["RemainderLogDegree"]}],
  {True, 3, 0},
  TestID -> "review-unit-precision-source-ceiling-has-no-logarithmic-factor"]

VerificationTest[
  Module[{x, s, result},
    s = AsymptoticExpansion[x Log[x] + x^3, {x, 0, 2}];
    result = SeriesLog[1 + s, 4];
    {Expand[Normal[result] - (x Log[x] - x^2 Log[x]^2/2)] === 0,
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 3, 3},
  TestID -> "review-unit-precision-log-keeps-nonlinear-degree-at-input-ceiling"]

VerificationTest[
  Module[{x, s, result},
    s = AsymptoticExpansion[x Log[x] + x^3, {x, 0, 2}];
    result = SeriesExp[s, 4];
    {Expand[Normal[result] - (1 + x Log[x] + x^2 Log[x]^2/2)] === 0,
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 3, 3},
  TestID -> "review-unit-precision-exp-keeps-nonlinear-degree-at-input-ceiling"]

VerificationTest[
  Module[{x, s, result},
    s = AsymptoticExpansion[x Log[x] + x^3, {x, 0, 2}];
    result = SeriesPower[1 + s, 1/2, 4];
    {Expand[Normal[result] - (1 + x Log[x]/2 - x^2 Log[x]^2/8)] === 0,
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 3, 3},
  TestID -> "review-unit-precision-square-root-keeps-nonlinear-degree-at-input-ceiling"]

VerificationTest[
  Module[{ell},
    (* The later block has degree seven. A valuation-one, third-order
       majorant permits degree 3*7=21; no sharp degree-seven bound is required. *)
    AsymptoticInverse`Private`unitSeriesPrecision[
      {{1, 1}, {2, ell^7}}, 3, 0, 4, ell]],
  {3, 21},
  TestID -> "review-unit-precision-degree-majorant-includes-later-blocks"]

VerificationTest[
  Module[{x, s, results, expected},
    s = AsymptoticExpansion[x + x^2 Log[x]^7 + x^3, {x, 0, 3}];
    results = {SeriesLog[1 + s, 4], SeriesExp[s, 4], SeriesPower[1 + s, 1/2, 4]};
    expected = {x + x^2 (Log[x]^7 - 1/2),
      1 + x + x^2 (Log[x]^7 + 1/2),
      1 + x/2 + x^2 (Log[x]^7/2 - 1/8)};
    MapThread[{Expand[Normal[#1] - #2] === 0,
      #1["RemainderPower"], #1["RemainderLogDegree"]} &, {results, expected}]],
  ConstantArray[{True, 3, 21}, 3],
  TestID -> "review-unit-precision-public-operations-preserve-later-block-majorant"]

VerificationTest[
  Module[{x, s, result},
    s = AsymptoticExpansion[x Log[x] + x^3 Log[x]^8, {x, 0, 2}];
    result = SeriesExp[s, 4];
    {Expand[Normal[result] - (1 + x Log[x] + x^2 Log[x]^2/2)] === 0,
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 3, 8},
  TestID -> "review-unit-precision-larger-inherited-degree-still-dominates"]

VerificationTest[
  Module[{x, s, result},
    s = AsymptoticExpansion[x Log[x] + x^3 Log[x]^8, {x, 0, 2}];
    result = SeriesLog[1 + s, 2];
    {Expand[Normal[result] - x Log[x]] === 0,
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 2, 2},
  TestID -> "review-unit-precision-cutoff-below-input-ceiling-uses-new-frontier"]

VerificationTest[
  Module[{x, s, result},
    s = AsymptoticExpansion[x Log[x] + x^3, {x, 0, 2}];
    result = SeriesLog[1 + s, 3];
    {Expand[Normal[result] - (x Log[x] - x^2 Log[x]^2/2)] === 0,
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 3, 3},
  TestID -> "review-unit-precision-equal-cutoff-combines-input-and-nonlinear-bounds"]

VerificationTest[
  Module[{x, s, results, expected},
    s = AsymptoticExpansion[x Log[x], {x, 0, 2}];
    results = {SeriesLog[1 + s, 4], SeriesExp[s, 4], SeriesPower[1 + s, 1/2, 4]};
    expected = {x Log[x] - x^2 Log[x]^2/2 + x^3 Log[x]^3/3,
      1 + x Log[x] + x^2 Log[x]^2/2 + x^3 Log[x]^3/6,
      1 + x Log[x]/2 - x^2 Log[x]^2/8 + x^3 Log[x]^3/16};
    {s["Remainder"], MapThread[{Expand[Normal[#1] - #2] === 0,
      #1["RemainderPower"], #1["RemainderLogDegree"]} &, {results, expected}]}],
  {0, ConstantArray[{True, 4, 4}, 3]},
  TestID -> "review-unit-precision-exact-argument-uses-requested-nonlinear-cutoff"]

VerificationTest[
  Module[{x, s, results},
    s = AsymptoticExpansion[x^3 Log[x]^5, {x, 0, 2}];
    results = {SeriesLog[1 + s, 4], SeriesExp[s, 4], SeriesPower[1 + s, 1/2, 4]};
    {Normal[#], #["RemainderPower"], #["RemainderLogDegree"]} & /@ results],
  {{0, 3, 5}, {1, 3, 5}, {1, 3, 5}},
  TestID -> "review-unit-precision-pure-argument-remainder-keeps-its-existing-bound"]

VerificationTest[
  Module[{x, zero, results},
    zero = AsymptoticExpansion[0, {x, 0, 2}];
    results = {SeriesLog[1 + zero, 4], SeriesExp[zero, 4], SeriesPower[1 + zero, 1/2, 4]};
    {Normal[#], #["Remainder"]} & /@ results],
  {{0, 0}, {1, 0}, {1, 0}},
  TestID -> "review-unit-precision-exact-zero-argument-does-not-acquire-uncertainty"]

VerificationTest[
  Module[{x, s, result},
    (* The cubic Taylor product lies exactly at the irrational input frontier;
       its logarithmic degree six cannot be absorbed by a higher power. *)
    s = AsymptoticExpansion[x^Sqrt[2] Log[x]^2 + x^(3 Sqrt[2]), {x, 0, 3}];
    result = SeriesLog[1 + s, 6];
    {TrueQ[FullSimplify[Normal[result] == x^Sqrt[2] Log[x]^2
        - x^(2 Sqrt[2]) Log[x]^4/2, x > 0]],
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 3 Sqrt[2], 6},
  TestID -> "review-unit-precision-irrational-valuation-retains-a-safe-tail-degree"]

VerificationTest[
  Module[{x, s, result},
    s = AsymptoticExpansion[x Log[x] + x^3, {x, 0, 2}];
    result = SeriesPower[1 + s, -1, 4];
    {Expand[Normal[result] - (1 - x Log[x] + x^2 Log[x]^2)] === 0,
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 3, 3},
  TestID -> "review-unit-precision-reciprocal-unit-preserves-nonlinear-frontier"]

VerificationTest[
  Module[{x, z, s, result},
    s = AsymptoticExpansion[x Log[x] + x^3, {x, 0, 2}];
    result = SeriesObservable[s, Sin[z], z, "Cutoff" -> 4];
    {Expand[Normal[result] - x Log[x]] === 0,
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 3, 3},
  TestID -> "review-unit-precision-generic-analytic-observable-keeps-boundary-degree"]
