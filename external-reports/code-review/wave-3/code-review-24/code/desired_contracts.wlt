(* Load the pinned package before TestReport[this file]. These are desired
   contracts, not claims that the unmodified package passes them. The complete
   file was not executed in the audit. Individual evidence is separately listed. *)
VerificationTest[
 Module[{old = Options[AsymptoticAnalysis`AsymptoticExpansion], r},
  Internal`WithLocalSettings[Null,
   SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Series"];
   r = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}];
   {r["Kind"], Normal[r]},
   Options[AsymptoticAnalysis`AsymptoticExpansion] = old]],
 {"Native", 1 + x + x^2/2 + x^3/6}, TestID -> "N01-canonical-default"]
VerificationTest[
 Module[{k = "Backend", r},
  r = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}, k -> "Series"];
  If[FailureQ[r], r, {r["Kind"], Normal[r]}]],
 {"Native", 1 + x + x^2/2 + x^3/6}, TestID -> "N02-computed-option-key"]
VerificationTest[
 Module[{n = 0, m = 0, r},
  r = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3},
     (n++; "Backend") :> (m++; "Series")];
  {If[FailureQ[r], r[[1]], r["Kind"]], n, m}],
 {"Native", 1, 1}, TestID -> "N02-single-key-and-delayed-value-consumption"]
VerificationTest[
 AsymptoticAnalysis`Private`catch[
  AsymptoticAnalysis`Private`fourierComposeBlock[
   {{1, {{0, 1}}}, {2, {{0, 1}}}}, 1, {{0, 1}}, 5, ell, True, 3, 1]],
 {{0, {{0, 1}}}, {1, {{0, 1}}}, {2, {{0, 1}}}},
 TestID -> "F01-terminating-Fourier-helper"]
VerificationTest[
 Module[{s}, s = AsymptoticAnalysis`AsymptoticFourierInverse[
   x + x^2, {x, 0}, {y, 7}, "MaxTerms" -> 7];
  AsymptoticAnalysis`FourierInverseResidual[s]["ZeroBelowCutoff"]],
 True, TestID -> "F01-public-residual-control"]
(* Run after installing the quadratic pilot; this is intentionally not a test
   of the unmodified package's currently conservative composite fallback. *)
VerificationTest[
 Module[{s, p},
  s = AsymptoticAnalysis`AsymptoticExpansion[LerchPhi[1/2, 2, x^2],
    {x, Infinity, 5}, "Backend" -> "Package"];
  p = AsymptoticAnalysis`SeriesMultiply[s, x];
  {p["Scale"], FullSimplify[Normal[p] - x Normal[s], x > 0],
   p["Remainder"]}],
 {"PowerLog", 0, AsymptoticAnalysis`PowerLogRemainder[x^(-2), 9/2, 0]},
 TestID -> "N03-quadratic-chart-ordered-product"]
