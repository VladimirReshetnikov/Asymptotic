(* Retained exact exponential cores, complete sectors and transported errors. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];
If[DownValues[AsymptoticAnalysis`AsymptoticCoreInverse] === {},
  Begin["AsymptoticAnalysis`Private`"];
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "CorePerturbation.wl"}]];
  End[]];
If[DownValues[AsymptoticAnalysis`AsymptoticExponentialCoreInverse] === {},
  Begin["AsymptoticAnalysis`Private`"];
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "ExponentialCorePerturbation.wl"}]];
  End[]];

VerificationTest[
  Module[{x, y, s, v, q},
    s = AsymptoticExponentialCoreInverse[x Exp[x], x^2, {x, Infinity}, {y, 2}];
    v = s["LocalVariable"]; q = s["LocalSectorCoefficients"];
    {TrueQ[Together[q[[1, 2]] + v^2/(v + 1)] === 0],
     TrueQ[Together[q[[2, 2]] - v^3 (-v^2 + 2 v + 4)/(2 (v + 1)^3)] === 0],
     s["LambertBranch"]}],
  {True, True, 0}, TestID -> "expcore-independent-first-two-corrections-to-xexpx"]

VerificationTest[
  Module[{x, y, s, phi},
    s = AsymptoticExponentialCoreInverse[x Exp[x], x^2, {x, Infinity}, {y, 1}];
    phi = s["CoreLocalInverse"];
    {TrueQ[FullSimplify[Normal[s] == phi - phi^3/((phi + 1) y), y > E]],
     ! FreeQ[s["CoreInverse"], ProductLog[_] | ProductLog[0, _]],
     s["SectorDepth"], s["MajorantContract"][["NumericCertificate"]]}],
  {True, True, 1, False}, TestID -> "expcore-exact-Lambert-retained-in-first-sector"]

VerificationTest[
  Module[{x, y, s, v, marker, approximation, residual},
    s = AsymptoticExponentialCoreInverse[x Exp[x], x^2, {x, Infinity}, {y, 2}];
    v = s["LocalVariable"];
    approximation = v + Total[(#[[2]] marker^#[[1]]) & /@ Take[s["LocalSectorCoefficients"], 2]];
    residual = Normal[Series[approximation Exp[approximation - v] - v + marker approximation^2, {marker, 0, 2}]];
    TrueQ[Together[residual] === 0]],
  True, TestID -> "expcore-independent-normalized-original-equation-residual"]

VerificationTest[
  Module[{x, y, s, phi, v},
    s = AsymptoticExponentialCoreInverse[7 + 3 (x - 2) Exp[x - 2], 5 (x - 2)^2, {x, Infinity}, {y, 1}];
    phi = s["CoreInverse"]; v = s["CoreLocalInverse"];
    {s["SourceShift"], TrueQ[FullSimplify[phi == 2 + ProductLog[(y - 7)/3], y > 7 + 3 E]],
     TrueQ[FullSimplify[Normal[s] == phi - 5 v^3/((v + 1) (y - 7)), y > 7 + 3 E]]}],
  {2, True, True}, TestID -> "expcore-automatic-source-shift-and-target-affine-core"]

VerificationTest[
  Module[{x, y, s, v},
    s = AsymptoticExponentialCoreInverse[(-x - 2) Exp[-x - 2], (-x - 2)^2, {x, -Infinity}, {y, 1}];
    v = s["CoreLocalInverse"];
    {s["SourceShift"], s["Direction"],
     TrueQ[FullSimplify[Normal[s] == -2 - v + v^3/((v + 1) y), y > E]]}],
  {-2, "FromAbove", True}, TestID -> "expcore-negative-source-infinity-and-shift"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticExponentialCoreInverse[Exp[x^2], x^2, {x, Infinity}, {y, 1}];
    TrueQ[FullSimplify[Normal[s] == Sqrt[Log[y]] (1 - 1/(2 y)), y > E]]],
  True, TestID -> "expcore-elementary-exact-core-with-nonunit-phase-power"]

VerificationTest[
  Module[{x, y, s, v},
    s = AsymptoticExponentialCoreInverse[Exp[x]/x, x, {x, Infinity}, {y, 1}];
    v = s["CoreLocalInverse"];
    {s["LambertBranch"], TrueQ[FullSimplify[v == -ProductLog[-1, -1/y], y > E]],
     TrueQ[FullSimplify[Normal[s] == v - v^2/((v - 1) y), y > E]]}],
  {-1, True, True}, TestID -> "expcore-negative-core-power-selects-lower-real-Lambert-branch"]

VerificationTest[
  Module[{x, y, s, v},
    s = AsymptoticExponentialCoreInverse[x Exp[2 x^3], Log[x], {x, Infinity}, {y, 1}];
    v = s["CoreLocalInverse"];
    TrueQ[FullSimplify[Normal[s] == v - v Log[v]/((1 + 6 v^3) y), y > Exp[2]]]],
  True, TestID -> "expcore-general-phase-power-and-logarithmic-perturbation"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticExponentialCoreInverse[Exp[1/x], x, {x, 0}, {y, 1}];
    {TrueQ[FullSimplify[Normal[s] == 1/Log[y] + 1/(y Log[y]^3), y > E]],
     s["SourceCoordinate"][["ObservablePower"]]}],
  {True, -1}, TestID -> "expcore-finite-source-reciprocal-reconstruction"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticExponentialCoreInverse[Exp[1/(2 - x)], 2 - x, {x, 2}, {y, 1}, Direction -> "FromBelow"];
    TrueQ[FullSimplify[Normal[s] == 2 - 1/Log[y] - 1/(y Log[y]^3), y > E]]],
  True, TestID -> "expcore-shifted-finite-endpoint-from-below"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticExponentialCoreInverse[x Exp[x], x^2, {x, Infinity}, {y, 3}, "InputRemainder" -> {1, 0}];
    {s["InputRemainderContract"][["InverseSector"]], s["ExactModel"],
     Cases[s["InputRemainderTerm"], PowerLogRemainder[_, beta_, k_] :> {beta, k}, Infinity],
     s["SectorDepth"], s["InputRemainderScale"] =!= 0}],
  {1, False, {{2, 0}}, 3, True}, TestID -> "expcore-unknown-forward-error-stays-a-first-sector-ceiling"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticExponentialCoreInverse[x Exp[x], 0, {x, Infinity}, {y, 4}];
    {s["Remainder"], s["ExactInverse"], Length[s["Terms"]]}],
  {0, True, 1}, TestID -> "expcore-zero-perturbation-exact-termination"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticExponentialCoreInverse[x Exp[x], x^2, {x, Infinity}, {y, 1}, "CoreInverse" -> ProductLog[y]];
    s["CoreInverse"] === ProductLog[y]],
  True, TestID -> "expcore-user-exact-core-expression-verified"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticExponentialCoreInverse[x Exp[x], x^2, {x, Infinity}, {y, 1}, "CoreInverse" -> -ProductLog[y]], Failure["UnverifiedCoreInverse", _]]],
  True, TestID -> "expcore-wrong-core-branch-rejected"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticExponentialCoreInverse[x Exp[-x], x^2, {x, Infinity}, {y, 1}], Failure["UnsupportedExponentialCore", _]]],
  True, TestID -> "expcore-decaying-core-with-dominant-perturbation-rejected"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticExponentialCoreInverse[x Exp[x] + x, x^2, {x, Infinity}, {y, 1}], Failure["UnsupportedExponentialCore", _]]],
  True, TestID -> "expcore-nonexact-core-not-silently-truncated"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticExponentialCoreInverse[x Exp[x], Exp[x/2], {x, Infinity}, {y, 1}], Failure["UnsupportedExponentialPerturbation", _]]],
  True, TestID -> "expcore-additional-exponential-rank-needs-separate-contract"]

VerificationTest[
  Module[{x, y, a},
    MatchQ[AsymptoticExponentialCoreInverse[x Exp[x], a x^2, {x, Infinity}, {y, 1}], Failure["UnprovedPerturbationData", _]]],
  True, TestID -> "expcore-perturbation-coefficients-must-be-provably-real"]

VerificationTest[
  Module[{x, y},
    MatchQ[AsymptoticExponentialCoreInverse[x Exp[x], x^2, {x, Infinity}, {y, 4}, "MaxTerms" -> 3], Failure["ResourceLimit", _]]],
  True, TestID -> "expcore-sector-depth-resource-budget"]

VerificationTest[
  Module[{x, y, s, target, error, bound},
    s = AsymptoticExponentialCoreInverse[x Exp[x], x^2, {x, Infinity}, {y, 2}];
    target = 20 Exp[20] + 400;
    error = N[Abs[(Normal[s] /. y -> target) - 20], 90];
    bound = N[s["RemainderScaleExpression"] /. y -> target, 90];
    TrueQ[0 < error < 10 bound]],
  True, TestID -> "expcore-original-equation-known-source-numerical-oracle"]

VerificationTest[
  Module[{x, y, low, high, target, a, b},
    low = AsymptoticExponentialCoreInverse[x Exp[x], x^2, {x, Infinity}, {y, 1}];
    high = AsymptoticExponentialCoreInverse[x Exp[x], x^2, {x, Infinity}, {y, 2}];
    target = 15 Exp[15] + 225;
    a = N[Abs[(Normal[low] /. y -> target) - 15], 80];
    b = N[Abs[(Normal[high] /. y -> target) - 15], 80];
    TrueQ[0 < b < a]],
  True, TestID -> "expcore-additional-exact-sector-improves-known-source-error"]
