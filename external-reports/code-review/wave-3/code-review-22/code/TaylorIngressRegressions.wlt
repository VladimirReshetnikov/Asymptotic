(* Desired-contract regressions for T01. UNRUN in the audit environment.
   Load AsymptoticAnalysis from the target checkout first. The short oracle is
   intentionally honest but incomplete: every returned coefficient and O term
   is valid for 1/(1-z). A client must not promote its unknown coefficients.
   Some tests are expected to fail on the unmodified pinned revision. *)

ClearAll[ReviewFixtures`shortTaylor, ReviewFixtures`fullTaylor,
  ReviewFixtures`shortCalls, ReviewFixtures`fullCalls];
ReviewFixtures`shortCalls = 0;
ReviewFixtures`fullCalls = 0;
ReviewFixtures`shortTaylor[0] = 1;
ReviewFixtures`fullTaylor[0] = 1;
ReviewFixtures`shortTaylor[z_?NumericQ] := 1/(1-z);
ReviewFixtures`fullTaylor[z_?NumericQ] := 1/(1-z);
ReviewFixtures`shortTaylor /: System`Series[
  ReviewFixtures`shortTaylor[arg_], {v_Symbol, 0, ord_Integer},
  opts : OptionsPattern[System`Series]] := (
  ReviewFixtures`shortCalls++;
  System`Series[1/(1-arg), {v, 0, Min[ord, 1]}, opts]);
ReviewFixtures`fullTaylor /: System`Series[
  ReviewFixtures`fullTaylor[arg_], {v_Symbol, 0, ord_Integer},
  opts : OptionsPattern[System`Series]] := (
  ReviewFixtures`fullCalls++;
  System`Series[1/(1-arg), {v, 0, ord}, opts]);

VerificationTest[
 Module[{u, raw},
  raw = Series[ReviewFixtures`shortTaylor[u], {u, 0, 3}];
  {Head[raw], raw[[5]], Normal[raw] === 1+u}],
 {SeriesData, 2, True},
 TestID -> "T01-fixture-honest-short-native-series"]

VerificationTest[
 Module[{x, z, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4}, "Backend" -> "Package"];
  r = AsymptoticAnalysis`SeriesObservable[s, ReviewFixtures`shortTaylor[z], z, "Cutoff" -> 3];
  MatchQ[r, Failure["InsufficientObservableNativeOrder", _Association]]],
 True, TestID -> "T01-reject-missing-quadratic-coefficient"]

VerificationTest[
 Module[{x, z, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4}, "Backend" -> "Package"];
  r = AsymptoticAnalysis`SeriesObservable[s, ReviewFixtures`shortTaylor[z], z, "Cutoff" -> 2];
  {MatchQ[r, _AsymptoticAnalysis`GeneralizedSeries],
   Normal[r] === 1+x, r["RemainderPower"]}],
 {True, True, 2}, TestID -> "T01-accept-endpoint-equal-to-required-endpoint"]

VerificationTest[
 Module[{x, z, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 4}, "Backend" -> "Package"];
  r = AsymptoticAnalysis`SeriesObservable[s, ReviewFixtures`fullTaylor[z], z, "Cutoff" -> 3];
  {Normal[r] === 1+x+x^2, r["RemainderPower"]}],
 {True, 3}, TestID -> "T01-complete-oracle-control"]

VerificationTest[
 Module[{x, z, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x^2, {x, 0, 6}, "Backend" -> "Package"];
  r = AsymptoticAnalysis`SeriesObservable[s, ReviewFixtures`shortTaylor[z], z, "Cutoff" -> 5];
  MatchQ[r, Failure["InsufficientObservableNativeOrder", _Association]]],
 True, TestID -> "T01-scaled-inner-valuation-insufficient-endpoint"]

VerificationTest[
 Module[{x, z, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x^2, {x, 0, 6}, "Backend" -> "Package"];
  r = AsymptoticAnalysis`SeriesObservable[s, ReviewFixtures`shortTaylor[z], z, "Cutoff" -> 4];
  {Normal[r] === 1+x^2, r["RemainderPower"]}],
 {True, 4}, TestID -> "T01-scaled-inner-valuation-boundary-is-sufficient"]

VerificationTest[
 Module[{x, z, s, r},
  s = AsymptoticAnalysis`AsymptoticExpansion[x, {x, 0, 6}, "Backend" -> "Package"];
  r = AsymptoticAnalysis`SeriesObservable[s, Cos[z], z, "Cutoff" -> 4];
  {Normal[r] === 1-x^2/2, r["RemainderPower"]}],
 {True, 4}, TestID -> "T01-zero-coefficients-are-not-unknown-coefficients"]
