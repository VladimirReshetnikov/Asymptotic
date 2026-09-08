(* Exact-core marker coefficients, branch checks and independent error contracts. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];
If[DownValues[AsymptoticInverse`AsymptoticCoreInverse] === {},
  Begin["AsymptoticInverse`Private`"];
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "CorePerturbation.wl"}]];
  End[]];

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 2}];
    {s["MarkerTerms"] === {{0, y}, {1, -y^2}, {2, 2 y^3}},
     s["FirstOmittedMarkerTerm"] === -5 y^4, s["RemainderPower"], s["RemainderLogDegree"]}],
  {True, True, 4, 0},
  TestID -> "core-identity-Catalan-marker-coefficients"]

VerificationTest[
  Module[{x, y, s, u, first, second},
    s = AsymptoticCoreInverse[x Log[x], x^2, {x, 0}, {y, 1}];
    u = s["LocalVariable"];
    first = s["LocalMarkerTerms"][[1, 2]];
    second = s["LocalMarkerTerms"][[2, 2]];
    {TrueQ[Together[first + u^2/(1 + Log[u])] === 0],
     TrueQ[Together[second - u^3 (4 Log[u] + 3)/(2 (1 + Log[u])^3)] === 0],
     s["FirstOmittedMarkerDegree"], s["RemainderPower"], s["MajorantContract"][["NumericCertificate"]]}],
  {True, True, 2, 3, False}, TestID -> "core-Lambert-correction-and-omitted-term"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x Log[x], x^2, {x, 0}, {y, 2}];
    {! FreeQ[s["CoreInverse"], ProductLog[-1, _]],
     s["Scale"], s["Truncation"], Length[s["MarkerTerms"]],
     s["CoreCertificate"][["CoreIdentity"]]}],
  {True, "ExactCorePerturbation", "Depth", 3, True},
  TestID -> "core-Lambert-preserved-exact-branch-and-marker-semantics"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x^2, x^3, {x, 0}, {y, 1}];
    {TrueQ[FullSimplify[Normal[s] == Sqrt[y] - y/2, y > 0]],
     s["RemainderPower"], s["RemainderVariable"] === Sqrt[y]}],
  {True, 3, True}, TestID -> "core-nonunit-leading-power"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x, 1/x, {x, Infinity}, {y, 2}];
    {TrueQ[Together[Normal[s] - (y - 1/y - 1/y^3)] === 0],
     s["RemainderPower"], s["RemainderVariable"] === 1/y}],
  {True, 5, True}, TestID -> "core-infinity-observable-error-scaling"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x - 3, (x - 3)^2, {x, 3}, {y, 1}];
    TrueQ[Expand[Normal[s] - (3 + y - y^2)] === 0]],
  True, TestID -> "core-shifted-source-reconstruction"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[-x, x^2, {x, 0}, {y, 1}, Direction -> "FromBelow"];
    {TrueQ[Expand[Normal[s] - (-y + y^2)] === 0], s["Direction"]}],
  {True, "FromBelow"}, TestID -> "core-from-below-source-sign"]

VerificationTest[
  Module[{x, y, s, phi},
    phi = (Sqrt[1 + 4 y] - 1)/2;
    s = AsymptoticCoreInverse[x + x^2, x^3, {x, 0}, {y, 1}, "CoreInverse" -> phi];
    {s["CoreInverse"] === phi, s["CoreCertificate"][["Type"]],
     TrueQ[FullSimplify[Normal[s] == phi - phi^3/(1 + 2 phi), y > 0]]}],
  {True, "SymbolicLeftInverse", True}, TestID -> "core-explicit-algebraic-inverse-validated"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 1}, "CoreInverse" -> -y];
    MatchQ[s, Failure["UnverifiedCoreInverse", _]]],
  True, TestID -> "core-wrong-exact-inverse-rejected"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticCoreInverse[x Log[x], x, {x, 0}, {y, 1}], Failure["NonSmallCorePerturbation", _]]],
  True, TestID -> "core-zero-power-gap-requires-separate-log-scale"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticCoreInverse[Log[x], x, {x, 0}, {y, 1}], Failure["UnsupportedCorePerturbation", _]]],
  True, TestID -> "core-pure-logarithm-not-misclassified"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 3}, "InputRemainder" -> {3, 2}];
    {s["RemainderPower"], s["RemainderLogDegree"], s["InputRemainderPair"],
     s["ExactModel"], Length[s["MarkerTerms"]]}],
  {3, 2, {3, 2}, False, 4}, TestID -> "core-explicit-input-error-coarsens-certified-order"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x Log[x], 0, {x, 0}, {y, 3}, "InputRemainder" -> {2, 3}];
    {s["RemainderPower"], s["RemainderLogDegree"], s["InputRemainderPair"]}],
  {2, 2, {2, 2}}, TestID -> "core-logarithmic-input-error-transport"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x, 0, {x, 0}, {y, 9}];
    {s["Remainder"], s["ExactInverse"], Length[s["MarkerTerms"]]}],
  {0, True, 1}, TestID -> "core-zero-perturbation-exact-termination"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 3}, "MaxTerms" -> 3], Failure["ResourceLimit", _]]],
  True, TestID -> "core-budget-covers-first-omitted-coefficient"]

VerificationTest[
  Module[{x, y, s, n = 2, u, marker, approximate, residual},
    s = AsymptoticCoreInverse[x + x^2, x^3, {x, 0}, {y, n},
      "CoreInverse" -> (Sqrt[1 + 4 y] - 1)/2];
    u = s["LocalVariable"];
    approximate = u + Total[(marker^#[[1]] #[[2]]) & /@ Take[s["LocalMarkerTerms"], n]];
    residual = Series[approximate + approximate^2 + marker approximate^3 - (u + u^2), {marker, 0, n}];
    TrueQ[Together[Normal[residual]] === 0]],
  True, TestID -> "core-independent-marker-composition-residual"]

VerificationTest[
  Module[{x, y, s, xx, yy, error, scale},
    s = AsymptoticCoreInverse[x Log[x], x^2, {x, 0}, {y, 2}];
    xx = N[Exp[-20], 90]; yy = xx Log[xx] + xx^2;
    error = Abs[N[Normal[s] /. y -> yy, 70] - xx];
    scale = N[s["RemainderScaleExpression"] /. y -> yy, 70];
    TrueQ[0 < error < scale]],
  True, TestID -> "core-Lambert-corrected-inverse-numerical-oracle"]

VerificationTest[
  Module[{x, y, s, u, w, c},
    s = AsymptoticCoreInverse[x + Log[x], 1/x, {x, Infinity}, {y, 2}];
    u = s["LocalVariable"]; c = s["LocalMarkerTerms"][[1 ;; 2, 2]] /. u -> 1/w;
    {s["CoreInverse"] === ProductLog[Exp[y]],
     TrueQ[Together[c[[1]] + 1/(w + 1)] === 0],
     TrueQ[Together[c[[2]] + (2 w + 1)/(2 w (w + 1)^3)] === 0],
     s["CoreCertificate"][["CoreType"]], s["RemainderPower"]}],
  {True, True, True, "PowerPlusLog", 5},
  TestID -> "core-power-plus-log-exact-Lambert-and-independent-coefficients"]

VerificationTest[
  Module[{x, y, s, u, w, marker, approximation, residual},
    s = AsymptoticCoreInverse[x + Log[x], 1/x, {x, Infinity}, {y, 2}];
    u = s["LocalVariable"];
    approximation = w + Total[(marker^#[[1]] (#[[2]] /. u -> 1/w)) & /@
      Take[s["LocalMarkerTerms"], 2]];
    residual = Normal[Series[approximation - w + Log[approximation/w] + marker/approximation,
      {marker, 0, 2}]];
    TrueQ[Together[residual] === 0]],
  True, TestID -> "core-power-plus-log-original-equation-marker-residual"]

VerificationTest[
  Module[{x, y, s, phi},
    phi = ProductLog[Exp[y]];
    s = AsymptoticCoreInverse[x + Log[x], 1/x, {x, Infinity}, {y, 1}, "CoreInverse" -> phi];
    {s["CoreInverse"] === phi,
     TrueQ[Together[Normal[s] - phi + 1/(1 + phi)] === 0],
     s["CoreCertificate"][["Type"]]}],
  {True, True, "RecognizedExactCore"},
  TestID -> "core-supplied-power-plus-log-exact-inverse-preserved"]

VerificationTest[
  Module[{x, y, s, w},
    s = AsymptoticCoreInverse[7 + 2 x + 3 Log[x], 4/x, {x, Infinity}, {y, 1}];
    w = 3 ProductLog[(2/3) Exp[(y - 7)/3]]/2;
    {TrueQ[FullSimplify[s["CoreInverse"] == w, y > 10]],
     s["CoreModel"][["Offset"]],
     TrueQ[FullSimplify[Normal[s] == w - 4/(2 w + 3), y > 10]]}],
  {True, 7, True}, TestID -> "core-power-plus-log-target-offset-and-scales"]

VerificationTest[
  Module[{x, y, s, w},
    s = AsymptoticCoreInverse[x - Log[x], 1/x, {x, Infinity}, {y, 1}];
    w = -ProductLog[-1, -Exp[-y]];
    {TrueQ[FullSimplify[s["CoreInverse"] == w, y > 2]],
     ! FreeQ[s["CoreInverse"], ProductLog[-1, _]],
     TrueQ[N[s["TargetDomain"] /. y -> 10, 40]]}],
  {True, True, True}, TestID -> "core-power-minus-log-selects-divergent-lower-Lambert-branch"]

VerificationTest[
  Module[{x, y, s, w},
    s = AsymptoticCoreInverse[x^2 + Log[x], 1/x, {x, Infinity}, {y, 1}];
    w = Sqrt[ProductLog[2 Exp[2 y]]/2];
    {TrueQ[FullSimplify[s["CoreInverse"] == w, y > 1]],
     TrueQ[FullSimplify[Normal[s] == w - 1/(2 w^2 + 1), y > 1]],
     s["RemainderPower"]}],
  {True, True, 5}, TestID -> "core-nonunit-divergent-power-plus-log"]

VerificationTest[
  Module[{x, y, s, xx, yy, error, scale},
    s = AsymptoticCoreInverse[x + Log[x], 1/x, {x, Infinity}, {y, 2}];
    xx = N[100, 80]; yy = xx + Log[xx] + 1/xx;
    error = Abs[N[Normal[s] /. y -> yy, 60] - xx];
    scale = N[s["RemainderScaleExpression"] /. y -> yy, 60];
    TrueQ[0 < error < 10 scale]],
  True, TestID -> "core-power-plus-log-original-function-numerical-oracle"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 2}, "Power" -> -2];
    {TrueQ[Together[Normal[s] - (1/y^2 + 2/y - 1)] === 0],
     s["FirstOmittedMarkerTerm"] === 2 y, s["RemainderPower"],
     s["CoreInverse"] === y, s["CoreObservableExpression"] === y^-2,
     s["LocalObservablePower"]}],
  {True, True, 1, True, True, -2},
  TestID -> "core-negative-power-finite-Catalan-observable"]

VerificationTest[
  Module[{x, y, s, marker, exactObservable, expected},
    s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 3}, "Power" -> -2];
    exactObservable = ((1 + Sqrt[1 + 4 marker y])/(2 y))^2;
    expected = Normal[Series[exactObservable, {marker, 0, 3}]] /. marker -> 1;
    TrueQ[Together[Normal[s] - expected] === 0]],
  True, TestID -> "core-negative-power-independent-exact-algebraic-inverse"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x, 1/x, {x, Infinity}, {y, 2}, "Power" -> -1];
    {TrueQ[Together[Normal[s] - (1/y + 1/y^3 + 2/y^5)] === 0],
     s["RemainderPower"], s["LocalObservablePower"], s["Power"]}],
  {True, 7, 1, -1}, TestID -> "core-negative-power-infinity-Catalan-observable"]

VerificationTest[
  Module[{x, y, s, u, w, c},
    s = AsymptoticCoreInverse[x + Log[x], 1/x, {x, Infinity}, {y, 2}, "Power" -> -1];
    u = s["LocalVariable"]; c = s["LocalMarkerTerms"][[1 ;; 2, 2]] /. u -> 1/w;
    {TrueQ[Together[c[[1]] - 1/(w^2 (w + 1))] === 0],
     TrueQ[Together[c[[2]] - (4 w + 3)/(2 w^3 (w + 1)^3)] === 0],
     s["RemainderPower"]}],
  {True, True, 7}, TestID -> "core-negative-power-plus-log-independent-coefficients"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x - 3, (x - 3)^2, {x, 3}, {y, 2}, "Power" -> -2];
    {TrueQ[Together[Normal[s] - (1/y^2 + 2/y - 1)] === 0],
     s["CoreInverse"] === 3 + y, s["ObservableExpression"] === (x - 3)^-2,
     s["RemainderPower"]}],
  {True, True, True, 1}, TestID -> "core-shifted-finite-power-is-displacement-power"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[3 - x, (x - 3)^2, {x, 3}, {y, 1},
      Direction -> "FromBelow", "Power" -> -1];
    {TrueQ[Together[Normal[s] + 1/y + 1] === 0],
     s["CoreInverse"] === 3 - y, s["RemainderPower"]}],
  {True, True, 1}, TestID -> "core-shifted-from-below-negative-odd-power-sign"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x, 1/x, {x, -Infinity}, {y, 1}, "Power" -> -1];
    {TrueQ[Together[Normal[s] - (1/y + 1/y^3)] === 0],
     TrueQ[s["TargetDomain"] /. y -> -10], s["RemainderPower"]}],
  {True, True, 5}, TestID -> "core-negative-infinity-negative-odd-power-sign"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 2}, "Power" -> 1/2];
    {TrueQ[FullSimplify[Normal[s] == Sqrt[y] - y^(3/2)/2 + 7 y^(5/2)/8, y > 0]],
     s["RemainderPower"]}],
  {True, 7/2}, TestID -> "core-positive-source-ramified-real-observable"]

VerificationTest[
  Module[{x, y, s, r = -Sqrt[2]},
    s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 1}, "Power" -> r];
    {TrueQ[FullSimplify[Normal[s] == y^r - r y^(r + 1), y > 0]],
     TrueQ[FullSimplify[s["RemainderPower"] == r + 2]]}],
  {True, True}, TestID -> "core-negative-irrational-real-observable"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 4}, "Power" -> -2,
      "InputRemainder" -> {3, 2}];
    {s["TruncationRemainderPair"], s["InputRemainderPair"],
     s["RemainderPower"], s["RemainderLogDegree"], s["ExactModel"]}],
  {{3, 0}, {0, 2}, 0, 2, False}, TestID -> "core-negative-finite-power-input-error-ceiling"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x, 1/x, {x, Infinity}, {y, 3}, "Power" -> -1,
      "InputRemainder" -> {2, 1}];
    {s["TruncationRemainderPair"], s["InputRemainderPair"],
     s["RemainderPower"], s["RemainderLogDegree"], Length[s["MarkerTerms"]]}],
  {{9, 0}, {4, 1}, 4, 1, 4}, TestID -> "core-negative-infinite-power-input-error-ceiling"]

VerificationTest[
  Module[{x, y, s, u, w},
    s = AsymptoticCoreInverse[7 + 3 (x - 2) Log[5 (x - 2)], 4 (x - 2)^2,
      {x, 2}, {y, 1}, "Power" -> -2, "InputRemainder" -> {3, 4}];
    u = s["LocalVariable"]; w = (y - 7)/(3 ProductLog[-1, 5 (y - 7)/3]);
    {TrueQ[FullSimplify[s["CoreInverse"] == 2 + w, -1/10 < y - 7 < 0]],
     TrueQ[FullSimplify[s["LocalMarkerTerms"][[1, 2]] == 8/(3 u (1 + Log[5 u])), u > 0]],
     s["InputRemainderPair"], s["RemainderPower"], s["RemainderLogDegree"]}],
  {True, True, {0, 3}, 0, 3}, TestID -> "core-shifted-scaled-Lambert-negative-power-and-input-error"]

VerificationTest[
  Module[{x, y, s, xx, yy, error, scale},
    s = AsymptoticCoreInverse[7 + 3 (x - 2) Log[5 (x - 2)], 4 (x - 2)^2,
      {x, 2}, {y, 2}, "Power" -> -2];
    xx = N[Exp[-20], 100]; yy = 7 + 3 xx Log[5 xx] + 4 xx^2;
    error = Abs[N[Normal[s] /. y -> yy, 75] - xx^-2];
    scale = N[s["RemainderScaleExpression"] /. y -> yy, 75];
    TrueQ[0 < error < 100 scale]],
  True, TestID -> "core-shifted-scaled-Lambert-negative-power-original-numerical-oracle"]

VerificationTest[
  Module[{x, y, values},
    values = {AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 1}, "Power" -> 0],
      AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 1}, "Power" -> 1.5],
      AsymptoticCoreInverse[-x, x^2, {x, 0}, {y, 1}, Direction -> "FromBelow", "Power" -> 1/3],
      AsymptoticCoreInverse[x, 1/x, {x, -Infinity}, {y, 1}, "Power" -> -1/2]};
    And @@ (MatchQ[#, Failure["InvalidOption", _]] & /@ values)],
  True, TestID -> "core-invalid-or-unproved-real-observable-branches-rejected"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x + Log[x], 0, {x, Infinity}, {y, 5}, "Power" -> -1];
    {s["Remainder"], s["ExactInverse"],
     TrueQ[Together[Normal[s] - 1/ProductLog[Exp[y]]] === 0]}],
  {0, True, True}, TestID -> "core-exact-negative-power-retains-core-without-perturbation"]
