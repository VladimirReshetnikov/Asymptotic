(* DESIRED-BEHAVIOR regression candidates. NOT run in a native kernel here.
   First load the selected modular package, then TestReport[thisFile].
   Some tests are expected to fail on the pinned baseline.
   These are not a replacement for the upstream tests of the affected modules. *)
Get[FileNameJoin[{DirectoryName[$TestFileName], "fixtures.wl"}]];

VerificationTest[
 Module[{x, saved = Options[AsymptoticExpansion], s},
  Internal`WithLocalSettings[Null,
   SetOptions[AsymptoticExpansion, "Backend" -> "Series"];
   s = AsymptoticExpansion[Exp[x], {x, 0, 2}];
   MatchQ[s, _GeneralizedSeries] && s["Kind"] === "Native" &&
    Normal[s] === 1 + x + x^2/2,
   Options[AsymptoticExpansion] = saved]],
 True, TestID -> "audit-N01-declared-backend-default-is-used"]

VerificationTest[
 Module[{x, saved = Options[AsymptoticExpansion], s},
  Internal`WithLocalSettings[Null,
   SetOptions[AsymptoticExpansion, "Backend" -> "Series"];
   s = AsymptoticExpansion[Exp[x], {x, 0, 2}, "Backend" -> "Package"];
   MatchQ[s, _GeneralizedSeries] && s["Kind"] =!= "Native" && Normal[s] === 1 + x,
   Options[AsymptoticExpansion] = saved]],
 True, TestID -> "audit-N01-explicit-package-still-overrides-default"]

VerificationTest[
 Module[{x, saved = Options[AsymptoticExpansion], s, calls = 0},
  Internal`WithLocalSettings[Null,
   SetOptions[AsymptoticExpansion, "Backend" :> (calls++; "Series")];
   s = AsymptoticExpansion[Exp[x], {x, 0, 2}];
   MatchQ[s, _GeneralizedSeries] && s["Kind"] === "Native" && calls === 1,
   Options[AsymptoticExpansion] = saved]],
 True, TestID -> "audit-N01-delayed-default-resolved-once"]

VerificationTest[
 Module[{x, t, a, b},
  a = AsymptoticExpansion[I + x, {x, 0, 2}];
  b = AsymptoticExpansion[Function[t, t][I] + x, {x, 0, 2}];
  MatchQ[a, _GeneralizedSeries] && MatchQ[b, _GeneralizedSeries] &&
   a["Kind"] === "Native" && b["Kind"] === "Native" && Normal[a] === Normal[b]],
 True, TestID -> "audit-N02-reducible-function-inside-source-is-not-callable-contract"]

VerificationTest[
 Module[{x, t, s},
  s = AsymptoticExpansion[Function[t, t + t^2], {x, 0, 3}];
  MatchQ[s, _GeneralizedSeries] && s["Kind"] =!= "Native" && Normal[s] === x + x^2],
 True, TestID -> "audit-N02-actual-callable-still-uses-package"]

VerificationTest[
 Module[{x, r, s},
  r = Root[1 + # + #^4 &, 1];
  s = AsymptoticExpansion[Root[1 + # + #^4 &, 1] + x, {x, 0, 2}];
  MatchQ[s, _GeneralizedSeries] && s["Kind"] === "Native" &&
    TrueQ[FullSimplify[Normal[s] == r + x]]],
 True, TestID -> "audit-N02-root-polynomial-function-does-not-block-native-fallback"]

VerificationTest[
 Module[{x, a, s},
  s = AsymptoticExpansion[Sqrt[a^2] Exp[x], {x, 0, 2},
    "Assumptions" -> a > 0, "Backend" -> "Package"];
  MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[s] == a (1 + x), a > 0]]],
 True, TestID -> "audit-N03-string-assumptions-option-is-equivalent"]

VerificationTest[
 Module[{x, s},
  s = AsymptoticExpansion[Exp[x], {x, 0, 2}, AsymptoticAuditFixtures`Backend -> "Series"];
  MatchQ[s, _GeneralizedSeries] && s["Kind"] === "Native" && Normal[s] === 1 + x + x^2/2],
 True, TestID -> "audit-N03-symbol-backend-selector-is-equivalent"]

VerificationTest[
 Module[{x, s},
  s = AsymptoticExpansion[Exp[x], {x, 0, 2}, "Backend" -> "Series",
    AsymptoticAuditFixtures`MaxTerms -> 20];
  MatchQ[s, Failure["NativeOptionConflict", _Association]]],
 True, TestID -> "audit-N03-symbol-resource-option-is-not-discarded"]

VerificationTest[
 Module[{t, q},
  q = Series[AsymptoticAuditFixtures`ShortTaylor[t], {t, 0, 4}];
  MatchQ[q, _SeriesData] && q[[5]] === 2 && Normal[q] === 1 + t &&
   AsymptoticAuditFixtures`ShortTaylor[1/5] === 31/25],
 True, TestID -> "audit-D01-fixture-provides-truthful-short-taylor-jet"]

VerificationTest[
 Module[{x, z, s, r},
  s = AsymptoticExpansion[x, {x, 0, 5}, "Backend" -> "Package"];
  r = SeriesObservable[s, AsymptoticAuditFixtures`ShortTaylor[z], z, "Cutoff" -> 4];
  MatchQ[r, Failure["InsufficientNativeOrder", _Association]]],
 True, TestID -> "audit-D01-unknown-taylor-coefficients-are-not-filled-with-zero"]

VerificationTest[
 Module[{x, z, s, r},
  s = AsymptoticExpansion[x, {x, 0, 5}, "Backend" -> "Package"];
  r = SeriesObservable[s, Sin[z], z, "Cutoff" -> 4];
  MatchQ[r, _GeneralizedSeries] && Normal[r] === x - x^3/6],
 True, TestID -> "audit-D01-sufficient-native-taylor-probe-still-works"]

VerificationTest[
 Module[{x, y, z, s, c, r},
  s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}, "InputRemainder" -> {4, 0}];
  c = SeriesObservable[s, 7, z];
  r = SeriesRefine[c, 20];
  MatchQ[c, _GeneralizedSeries] && c["Exact"] === True &&
    MatchQ[r, _GeneralizedSeries] && Normal[r] === 7 && r["Remainder"] === 0 &&
    r["RefinementStatistics"]["SourceReplayRequired"] === False],
 True, TestID -> "audit-D02-exact-constant-refinement-ignores-insufficient-ancestor"]

VerificationTest[
 Module[{x, z, c, r},
  c = SeriesObservable[AsymptoticExpansion[x, {x, 0, 3}, "Backend" -> "Package"], 7, z];
  r = SeriesRefine[c, 20, "MaxTerms" -> 0];
  MatchQ[r, Failure["InvalidOption", _Association]]],
 True, TestID -> "audit-D02-invalid-budget-is-validated-before-noop"]

VerificationTest[
 Module[{x, z, c, r},
  c = SeriesObservable[AsymptoticExpansion[1 + x + x^2, {x, 0, 5},
    "Backend" -> "Package"], z, z];
  r = SeriesRefine[c, 1];
  MatchQ[r, _GeneralizedSeries] && Normal[r] === 1 && r["Remainder"] =!= 0],
 True, TestID -> "audit-D02-lower-cutoff-retargeting-policy-is-not-changed"]
