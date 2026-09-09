(* Desired behavior after the proposed fixes. Several tests are intentionally
   expected to fail on unmodified 1.8.0. NOT RUN during this audit.
   Load the package BEFORE TestReport["proposed_regressions.wlt"]. *)

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse`AsymptoticInverse[x + x^2, {x, 0}, {y, 5}];
    Expand[Normal[s] - (y - y^2 + 2 y^3 - 5 y^4)]],
  0, TestID -> "control-quadratic-inverse"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticInverse`AsymptoticExpansion[1 + x^(1/100003) + x + x^2, {x, 0, 2}];
    MatchQ[s["SeriesData"], Missing["DenseSeriesDataBudget", _Association]]],
  True, TestID -> "F01-dense-span-guard"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticInverse`AsymptoticExpansion[(1 + x)^256, {x, 0, 3}, "MaxTerms" -> 200];
    MatchQ[s, _AsymptoticInverse`GeneralizedSeries] &&
      Expand[Normal[s] - (1 + 256 x + 32640 x^2)] === 0],
  True, TestID -> "F02-small-output-large-power"]

VerificationTest[
  Module[{x, y, j, s},
    s = AsymptoticInverse`AsymptoticInverse[x (1 + Sum[x^(1 + j/1000), {j, 1, 24}]),
      {x, 0}, {y, 5}, Method -> "Newton"];
    MatchQ[s, _AsymptoticInverse`GeneralizedSeries] && s["ReturnedTermCount"] === 142],
  True, TestID -> "F03-Newton-does-not-enumerate-full-simplex"]

VerificationTest[
  Module[{x, a}, FailureQ[AsymptoticInverse`AsymptoticExpansion[a + x, {x, 0, 2}]]],
  True, TestID -> "F04-real-coefficients-require-proof"]

VerificationTest[
  Module[{x}, FailureQ[AsymptoticInverse`AsymptoticExpansion[ArcCos[2 + x], {x, 0, 3}]]],
  True, TestID -> "F04-nonreal-elementary-source-rejected"]

VerificationTest[
  Module[{x, s, t, r},
    s = AsymptoticInverse`AsymptoticExpansion[1/(1 + x), {x, 0, 3}];
    t = AsymptoticInverse`AsymptoticExpansion[x^-10, {x, 0, 3}];
    r = AsymptoticInverse`SeriesRefine[AsymptoticInverse`SeriesMultiply[s, t], 5];
    MatchQ[r, _AsymptoticInverse`GeneralizedSeries] && TrueQ[r["RemainderPower"] >= 5]],
  True, TestID -> "F05-refinement-meets-requested-precision"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticInverse`AsymptoticExpansion[1 + x Log[x], {x, 0, 1}];
    MatchQ[s["SeriesData"], Missing["LogarithmicRemainder"]]],
  True, TestID -> "F06-no-silent-log-envelope-loss"]
