(* Native Wolfram regression specifications. NOT RUN during this audit.
   Load the reviewed package before TestReport; run_native.wl does this.
   A01 nested power is expected to FAIL on the reviewed source and pass after patching. *)
VerificationTest[Module[{x, z, s},
  s = AsymptoticExpansion[-x^2, {x, 0, 1}];
  {Normal[s], s["RemainderPower"], FailureQ[SeriesPower[s, 1/2]]}],
  {0, 2, True}, TestID -> "audit-A01-direct-guard-baseline"]

VerificationTest[Module[{x, z, s},
  s = AsymptoticExpansion[-x^2, {x, 0, 1}];
  FailureQ[SeriesObservable[s, 1 + Sqrt[z], z]]],
  True, TestID -> "audit-A01-nested-fractional-power-must-reject-unknown-sign"]

VerificationTest[Module[{x, z, s},
  s = AsymptoticExpansion[-x^2, {x, 0, 1}];
  FailureQ[SeriesObservable[s, Sin[Sqrt[z]], z]]],
  True, TestID -> "audit-A01-deeper-nesting-must-not-bypass-branch-proof"]

VerificationTest[Module[{x, s, t},
  s = AsymptoticExpansion[0, {x, 0, 2}]; t = SeriesPower[s, 1/2];
  MatchQ[t, _GeneralizedSeries] && Normal[t] === 0 && t["Remainder"] === 0],
  True, TestID -> "audit-A01-exact-zero-positive-power-remains-valid"]

VerificationTest[Module[{x, z, s, t},
  s = AsymptoticExpansion[x^2, {x, 0, 3}];
  t = SeriesObservable[s, 1 + Sqrt[z], z];
  MatchQ[t, _GeneralizedSeries] && Expand[Normal[t] - 1 - x] === 0],
  True, TestID -> "audit-A01-known-positive-leading-monomial-remains-valid"]

VerificationTest[Module[{x, s, t},
  s = AsymptoticExpansion[Sin[x], {x, 0, 5}]; t = SeriesTruncate[s, 9];
  MatchQ[t, _GeneralizedSeries] && t["RemainderPower"] === s["RemainderPower"]],
  True, TestID -> "audit-truncation-cannot-manufacture-precision"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Sin[x], {x, 0, 5}];
  FailureQ[SeriesDifferentiate[s]]],
  True, TestID -> "audit-bare-asymptotic-error-is-not-a-derivative-certificate"]

VerificationTest[Module[{ell, result},
  result = AsymptoticInverse`Private`catch[
    AsymptoticInverse`Private`jetComposeBlock[{{1, 1}}, 0, 1, 50, ell, True, 20000]];
  result === {{0, 1}}],
  True, TestID -> "audit-A03-zero-coefficient-tail-has-constant-result"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticInverse[x + x^2, {x, 0}, {y, 6}];
  MatchQ[s, _GeneralizedSeries] &&
    Expand[Normal[s] - (y-y^2+2 y^3-5 y^4+14 y^5)] === 0],
  True, TestID -> "audit-low-order-Catalan-inverse-control"]
