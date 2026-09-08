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
