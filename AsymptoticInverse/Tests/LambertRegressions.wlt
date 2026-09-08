(* Logarithmic-scale inverse regressions.  The small x Log[x] branch uses
   ProductLog[-1, ...]; the large x Exp[x] branch uses ProductLog[0, ...]. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x Log[x], {x, 0}, y, SeriesTermGoal -> 3];
    s["Scale"]],
  "Logarithmic", TestID -> "lambert-small-logarithmic-core-dispatch"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x Log[x], {x, 0}, y, SeriesTermGoal -> 3];
    s["Blocks"] /. s["LogVariable"] -> \[FormalL]],
  {{0, 1}, {1, \[FormalL]}, {2, \[FormalL]^2 + \[FormalL]}},
  TestID -> "lambert-minus-one-inverse-coefficients"]

VerificationTest[
  Module[{x, y, s, a = 50, b = Log[50]},
    s = AsymptoticInverse[x Log[x], {x, 0}, y, SeriesTermGoal -> 3];
    TrueQ[FullSimplify[s[-Exp[-a]] == Exp[-a]/a (1 - b/a + (b^2 - b)/a^2)]]],
  True, TestID -> "lambert-minus-one-concrete-nested-log-expansion"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x Exp[x], {x, Infinity}, y, SeriesTermGoal -> 5];
    s["Blocks"] /. s["LogVariable"] -> \[FormalL]],
  {{0, 1}, {1, \[FormalL]}, {2, -\[FormalL]},
   {3, \[FormalL] + \[FormalL]^2/2},
   {4, -\[FormalL] - 3 \[FormalL]^2/2 - \[FormalL]^3/3}},
  TestID -> "lambert-principal-inverse-coefficients"]

VerificationTest[
  Module[{x, y, s, a = 50, b = Log[50]},
    s = AsymptoticInverse[x Exp[x], {x, Infinity}, y, SeriesTermGoal -> 5];
    TrueQ[FullSimplify[s[Exp[a]] == a - b + b/a + b (b - 2)/(2 a^2)
      + b (2 b^2 - 9 b + 6)/(6 a^3)]]],
  True, TestID -> "lambert-principal-concrete-nested-log-expansion"]

VerificationTest[
  Module[{x, y, s, a = 50, b = Log[50]},
    s = AsymptoticInverse[2 x Exp[3 x], {x, Infinity}, y, SeriesTermGoal -> 4];
    TrueQ[FullSimplify[s[(2/3) Exp[a]] == (a - b + b/a + b (b - 2)/(2 a^2))/3]]],
  True, TestID -> "lambert-scaled-exponential-core"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[-3 x^2 Log[x], {x, 0}, y, SeriesTermGoal -> 3];
    s["Blocks"] /. s["LogVariable"] -> \[FormalL]],
  {{0, 1}, {1, \[FormalL]/2}, {2, \[FormalL]/2 + 3 \[FormalL]^2/8}},
  TestID -> "lambert-scaled-ramified-logarithmic-core"]

VerificationTest[
  Module[{x, y, s, a = 50, b = Log[50]},
    s = AsymptoticInverse[-3 x^2 Log[x], {x, 0}, y, SeriesTermGoal -> 3, "Power" -> 2];
    TrueQ[FullSimplify[s[(3/2) Exp[-a]] == Exp[-a]/a (1 - b/a + (b^2 - b)/a^2)]]],
  True, TestID -> "lambert-ramified-observable-power"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x Exp[x], {x, Infinity}, y, SeriesTermGoal -> 3, "Power" -> 2];
    s["Blocks"] /. s["LogVariable"] -> \[FormalL]],
  {{0, 1}, {1, 2 \[FormalL]}, {2, \[FormalL]^2 - 2 \[FormalL]}},
  TestID -> "lambert-exponential-observable-power"]

VerificationTest[
  Module[{x, y, s, c},
    s = AsymptoticInverse[x Log[x], {x, 0}, y, SeriesTermGoal -> 7];
    c = InverseNumericalCheck[s, -Exp[-50], WorkingPrecision -> 40];
    TrueQ[0 < c["ExactInverse"] < Exp[-1] &&
      c["Error"]/Abs[c["ExactInverse"]] < 10^-6]],
  True, TestID -> "lambert-minus-one-numerical-selected-small-branch"]

VerificationTest[
  Module[{x, y, s, c},
    s = AsymptoticInverse[x Exp[x], {x, Infinity}, y, SeriesTermGoal -> 6];
    c = InverseNumericalCheck[s, Exp[100], WorkingPrecision -> 40];
    TrueQ[c["ExactInverse"] > 90 && c["Error"] < 10^-5]],
  True, TestID -> "lambert-principal-numerical-large-branch"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x Log[x], {x, 0}, y, SeriesTermGoal -> 3];
    FailureQ[InverseNumericalCheck[s, 1/100]]],
  True, TestID -> "lambert-numerical-rejects-wrong-target-side"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x Exp[x], {x, Infinity}, {y, 3}];
    s["Blocks"] /. s["LogVariable"] -> \[FormalL]],
  {{0, 1}, {1, \[FormalL]}, {2, -\[FormalL]}},
  TestID -> "lambert-exclusive-relative-logarithmic-cutoff"]

VerificationTest[
  Module[{x, y, s, a = 50, b = Log[50]},
    s = AsymptoticInverse[x (1 + Log[x]), {x, 0}, y, SeriesTermGoal -> 3];
    TrueQ[FullSimplify[s[-Exp[-a - 1]] == Exp[-a - 1]/a (1 - b/a + (b^2 - b)/a^2)]]],
  True, TestID -> "lambert-affine-logarithmic-core"]

VerificationTest[
  Module[{x, y, s, a = 50, b = Log[50]},
    s = AsymptoticInverse[x/(-Log[x]), {x, 0}, y, SeriesTermGoal -> 4];
    TrueQ[FullSimplify[s[Exp[-a]] == Exp[-a] (a - b + b/a + b (b - 2)/(2 a^2))]]],
  True, TestID -> "lambert-principal-branch-at-finite-endpoint"]

VerificationTest[
  Module[{x, y, s, c},
    s = AsymptoticInverse[x Log[x] + x^2, {x, 0}, y, SeriesTermGoal -> 7];
    c = InverseNumericalCheck[s, -Exp[-50], WorkingPrecision -> 40];
    TrueQ[s["LeadingCoreOnly"] && 0 < c["ExactInverse"] < Exp[-1] &&
      c["Error"]/Abs[c["ExactInverse"]] < 10^-6]],
  True, TestID -> "lambert-small-core-with-power-perturbation"]

VerificationTest[
  Module[{x, y, s, c},
    s = AsymptoticInverse[x Exp[x] + x^2, {x, Infinity}, y, SeriesTermGoal -> 6];
    c = InverseNumericalCheck[s, Exp[100], WorkingPrecision -> 40];
    TrueQ[s["LeadingCoreOnly"] && c["ExactInverse"] > 90 && c["Error"] < 10^-5]],
  True, TestID -> "lambert-large-core-with-polynomial-perturbation"]

VerificationTest[
  Module[{x, y, s, a = 50, b = Log[50]},
    s = AsymptoticInverse[x Exp[-x], {x, Infinity}, y, SeriesTermGoal -> 4];
    TrueQ[FullSimplify[s[Exp[-a]] == a + b + b/a - b (b - 2)/(2 a^2)]]],
  True, TestID -> "lambert-minus-one-decaying-exponential-at-infinity"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[Exp[-x], {x, Infinity}, y, SeriesTermGoal -> 3];
    {TrueQ[FullSimplify[Normal[s] == -Log[y], 0 < y < 1]], s["Remainder"]}],
  {True, 0}, TestID -> "lambert-elementary-decaying-exponential"]
