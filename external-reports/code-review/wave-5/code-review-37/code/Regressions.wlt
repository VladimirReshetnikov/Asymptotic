(* Desired contracts for the NARROW CANDIDATE PATCH. NOT EXECUTED BY THE AUTHOR.
   Load the intended package before TestReport of this file. A number of tests
   are expected to fail on the pinned unmodified baseline. Wolfram 15+ target. *)

VerificationTest[
 Module[{ell, result},
  result = AsymptoticAnalysis`Private`catch[
   AsymptoticAnalysis`Private`fwdAbs[
    {{{0, 1}, {1, I}}, Infinity, 0}, ell, True]];
  MatchQ[result, Failure["UnprovedAbsArgument", _Association]]],
 True, TestID -> "F01-private-complex-retained-coefficient"]

VerificationTest[
 Module[{a, x, z, s, result},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4},
    Assumptions -> a^2 == -1, "Backend" -> "Package"];
  result = AsymptoticAnalysis`SeriesObservable[s,
    Abs[1 + a z] + Abs[1 - a z] - 2, z, "Cutoff" -> 4];
  MatchQ[result, Failure["UnprovedAbsArgument", _Association]]],
 True, TestID -> "F01-public-observable-refuses-false-zero"]

VerificationTest[
 Module[{a, x, result},
  result = AsymptoticAnalysis`AsymptoticExpansion[
    Abs[1 + a x] + Abs[1 - a x] - 2, {x, 0, 4},
    Assumptions -> a^2 == -1, "Backend" -> "Package"];
  MatchQ[result, Failure["UnprovedAbsArgument", _Association]]],
 True, TestID -> "F01-forward-path-refuses-false-zero"]

VerificationTest[
 Module[{x, z, s, result},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4}, "Backend" -> "Package"];
  result = AsymptoticAnalysis`SeriesObservable[s, Abs[1 + z], z, "Cutoff" -> 4];
  MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries] &&
   TrueQ[Normal[result] == 1 + x] && result["Remainder"] === 0],
 True, TestID -> "F01-real-positive-control"]

VerificationTest[
 Module[{x, z, s, result},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4}, "Backend" -> "Package"];
  result = AsymptoticAnalysis`SeriesObservable[s, Abs[-1 - z], z, "Cutoff" -> 4];
  MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries] &&
   TrueQ[Normal[result] == 1 + x] && result["Remainder"] === 0],
 True, TestID -> "F01-real-negative-control"]

VerificationTest[
 Module[{ell}, AsymptoticAnalysis`Private`catch[
   AsymptoticAnalysis`Private`fwdAbs[{{}, 3, 2}, ell, True]]],
 {{}, 3, 2}, TestID -> "F01-pure-magnitude-error-control"]

VerificationTest[
 Module[{a, x, s, result},
  s = AsymptoticAnalysis`AsymptoticExpansion[a x, {x, 0, 3},
    Assumptions -> Element[a, Reals], "Backend" -> "Package"];
  result = AsymptoticAnalysis`SeriesPower[s, 0];
  MatchQ[result, Failure["UnprovedNonzeroBase", _Association]]],
 True, TestID -> "F02-parameter-domain-includes-zero"]

VerificationTest[
 Module[{x, s, result},
  s = AsymptoticAnalysis`AsymptoticExpansion[0, {x, 0, 3}, "Backend" -> "Package"];
  result = AsymptoticAnalysis`SeriesPower[s, 0];
  MatchQ[result, Failure["IndeterminatePower", _Association]]],
 True, TestID -> "F02-exact-zero-control"]

VerificationTest[
 Module[{a, x, s, result},
  s = AsymptoticAnalysis`AsymptoticExpansion[a x, {x, 0, 3},
    Assumptions -> (Element[a, Reals] && a != 0), "Backend" -> "Package"];
  result = AsymptoticAnalysis`SeriesPower[s, 0];
  MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries] &&
   Normal[result] === 1 && result["Remainder"] === 0],
 True, TestID -> "F02-unsigned-nonzero-parameter-control"]

VerificationTest[
 Module[{x, s, result},
  s = AsymptoticAnalysis`AsymptoticExpansion[-x, {x, 0, 3}, "Backend" -> "Package"];
  result = AsymptoticAnalysis`SeriesPower[s, 0];
  MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries] &&
   Normal[result] === 1 && result["Remainder"] === 0],
 True, TestID -> "F02-negative-nonzero-control"]

VerificationTest[
 Module[{x, y, g, result},
  g = AsymptoticAnalysis`AsymptoticInverse[Gamma[x], {x, Infinity}, {y, 1}];
  result = AsymptoticAnalysis`SeriesPower[g, 0, "Cutoff" -> 0];
  MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries] && Normal[result] === 0 &&
   result["Cutoff"] === 0 && result["RemainderPower"] === 0 &&
   result["Remainder"] =!= 0],
 True, TestID -> "F03-gamma-exclusive-zero-cutoff"]

VerificationTest[
 Module[{x, y, g, result},
  g = AsymptoticAnalysis`AsymptoticInverse[Gamma[x], {x, Infinity}, {y, 1}];
  result = AsymptoticAnalysis`SeriesPower[g, 0, "Cutoff" -> 2];
  MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries] && Normal[result] === 1 &&
   result["Cutoff"] === 2 && result["Remainder"] === 0],
 True, TestID -> "F03-gamma-positive-request-metadata"]

VerificationTest[
 Module[{x, y, g, result},
  g = AsymptoticAnalysis`AsymptoticInverse[System`BarnesG[x], {x, Infinity}, {y, 1}];
  result = AsymptoticAnalysis`SeriesPower[g, 0, "Cutoff" -> 0];
  MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries] && Normal[result] === 0 &&
   result["Cutoff"] === 0 && result["RemainderPower"] === 0],
 True, TestID -> "F03-barnes-shared-zero-power-path"]

VerificationTest[
 Module[{x, y, g, result},
  g = AsymptoticAnalysis`AsymptoticInverse[Gamma[x], {x, Infinity}, {y, 1}];
  result = AsymptoticAnalysis`SeriesPower[g, 0];
  MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries] && Normal[result] === 1 &&
   result["Cutoff"] === 1 && result["Remainder"] === 0],
 True, TestID -> "F03-automatic-default-control"]
