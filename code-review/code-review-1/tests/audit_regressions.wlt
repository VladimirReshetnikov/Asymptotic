(* Prospective native regression tests. NOT EXECUTED during this audit.
   Load the package BEFORE TestReport reads this file. Tests A01-nested, A02,
   A03-strict and A04 target corrected behavior and may fail on the pinned source.
   A03-strict is an intentional stricter export policy, not a claim that the
   authoritative GeneralizedSeries remainder is wrong. No huge array is tested. *)
Clear[a, x, y, z];

VerificationTest[
 Module[{s = AsymptoticInverse`AsymptoticExpansion[-x^2, {x, 0, 2}]},
  FailureQ[AsymptoticInverse`SeriesPower[s, 1/2]]],
 True, TestID -> "A01-direct-pure-remainder-power-rejected"]

VerificationTest[
 Module[{s = AsymptoticInverse`AsymptoticExpansion[-x^2, {x, 0, 2}]},
  FailureQ[AsymptoticInverse`SeriesObservable[s, 1 + Sqrt[z], z]]],
 True, TestID -> "A01-nested-pure-remainder-power-must-also-reject"]

VerificationTest[
 Module[{s, r}, s = AsymptoticInverse`AsymptoticExpansion[x^2, {x, 0, 3}];
  r = AsymptoticInverse`SeriesObservable[s, 1 + Sqrt[z], z];
  MatchQ[r, _AsymptoticInverse`GeneralizedSeries] &&
   TrueQ[FullSimplify[Normal[r] == 1 + x, Assumptions -> x > 0]]],
 True, TestID -> "A01-known-positive-base-preserved"]

VerificationTest[
 Module[{s, r}, s = AsymptoticInverse`AsymptoticExpansion[0, {x, 0, 2}];
  r = AsymptoticInverse`SeriesObservable[s, 1 + Sqrt[z], z];
  MatchQ[r, _AsymptoticInverse`GeneralizedSeries] && Normal[r] === 1 && r["Remainder"] === 0],
 True, TestID -> "A01-exact-zero-positive-power-preserved"]

VerificationTest[
 Module[{s}, s = AsymptoticInverse`AsymptoticExpansion[x^(1/20011) + x, {x, 0, 1}, "MaxTerms" -> 10];
  MatchQ[s, _AsymptoticInverse`GeneralizedSeries] && MissingQ[s["SeriesData"]]],
 True, TestID -> "A02-optional-dense-export-capped-before-allocation"]

VerificationTest[
 Module[{s}, s = AsymptoticInverse`AsymptoticExpansion[x + x^2 Log[x], {x, 0, 2}];
  {s["RemainderPower"], s["RemainderLogDegree"]}],
 {2, 1}, TestID -> "A03-authoritative-logarithmic-envelope-preserved"]

VerificationTest[
 Module[{s}, s = AsymptoticInverse`AsymptoticExpansion[x + x^2 Log[x], {x, 0, 2}];
  MissingQ[s["SeriesData"]]],
 True, TestID -> "A03-strict-export-refuses-logarithmic-error-loss"]

VerificationTest[
 Module[{s}, s = AsymptoticInverse`AsymptoticExpansion[Exp[x], {x, 0, 4}];
  MatchQ[s["SeriesData"], _SeriesData]],
 True, TestID -> "A03-ordinary-native-export-remains-available"]

VerificationTest[
 Module[{s}, s = Assuming[a == 0,
    AsymptoticInverse`AsymptoticExpansion[a x + x^2, {x, 0, 3}]];
  Block[{$Assumptions = True},
   TrueQ[FullSimplify[Normal[s] == a x + x^2,
     Assumptions -> s["Assumptions"]]]]],
 True, TestID -> "A04-exact-result-retains-all-used-assumptions"]

VerificationTest[
 Module[{s}, s = Assuming[a > 0,
    AsymptoticInverse`AsymptoticInverse[a x + x^2, {x, 0}, {y, 3}]];
  If[FailureQ[s], True,
   Block[{$Assumptions = True},
    TrueQ[FullSimplify[a > 0, Assumptions -> s["Assumptions"]]]]]],
 True, TestID -> "A04-ambient-sign-proof-retained-or-conservatively-rejected"]

VerificationTest[
 Module[{s}, s = Block[{$Assumptions = True},
    AsymptoticInverse`AsymptoticExpansion[a x + x^2, {x, 0, 3}, Assumptions -> a == 0]];
  Block[{$Assumptions = True},
   TrueQ[FullSimplify[Normal[s] == a x + x^2, Assumptions -> s["Assumptions"]]]]],
 True, TestID -> "A04-explicit-assumption-workaround"]

VerificationTest[
 Normal[AsymptoticInverse`AsymptoticInverse[x + x^2, {x, 0}, {y, 5}]],
 y - y^2 + 2 y^3 - 5 y^4, TestID -> "control-classical-Catalan-inverse"]

VerificationTest[
 Module[{s = AsymptoticInverse`AsymptoticInverse[x + x^Sqrt[2], {x, 0}, y, SeriesTermGoal -> 3]},
  TrueQ[FullSimplify[Normal[s] == y - y^Sqrt[2] + Sqrt[2] y^(2 Sqrt[2] - 1), Assumptions -> y > 0]]],
 True, TestID -> "control-irrational-power-inverse"]

VerificationTest[
 Module[{s = AsymptoticInverse`AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}]},
  TrueQ[FullSimplify[Normal[s] == y - y^2 (1 + Log[y]) +
    y^3 (2 Log[y]^2 + 5 Log[y] + 3), Assumptions -> y > 0]]],
 True, TestID -> "control-complete-logarithmic-block"]

VerificationTest[
 Module[{s, c}, s = AsymptoticInverse`AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
  c = AsymptoticInverse`InverseCertificate[s, 1/10,
    "Interval" -> {2/25, 1/10}, "Center" -> 9/100];
  AssociationQ[c] && TrueQ[c["Certified"]] &&
    TrueQ[c["DerivativeLowerBound"] > 0] &&
    c["CertifiesInputRemainderFamily"] === False],
 True, TestID -> "control-exact-certificate-scope"]
