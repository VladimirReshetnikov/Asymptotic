(* Endpoint, general logarithmic polynomial, and real-branch coverage. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[
  Module[{x, y, s}, s = AsymptoticInverse[x Log[x], {x, Infinity}, y, SeriesTermGoal -> 3];
    {s["LambertBranch"], s["Blocks"] /. s["LogVariable"] -> \[FormalL]}],
  {0, {{0, 1}, {1, -\[FormalL]}, {2, \[FormalL]^2 + \[FormalL]}}},
  TestID -> "leading-log-at-positive-infinity"]

VerificationTest[
  Module[{x, y, s, c}, s = AsymptoticInverse[x Log[-x], {x, -Infinity}, y, SeriesTermGoal -> 6];
    c = InverseNumericalCheck[s, -Exp[50], WorkingPrecision -> 40];
    TrueQ[c["ExactInverse"] < 0 && c["Error"]/Abs[c["ExactInverse"]] < 10^-6 && InverseResidual[s]["ZeroBelowCutoff"]]],
  True, TestID -> "leading-log-at-negative-infinity-real-branch"]

VerificationTest[
  Module[{x, y, s}, s = AsymptoticInverse[x (Log[x]^2 + 1), {x, 0}, y, SeriesTermGoal -> 3];
    {s["LambertPolynomialLog"], s["Blocks"] /. s["LogVariable"] -> \[FormalL]}],
  {True, {{0, 1}, {1, 2 \[FormalL]}, {2, 3 \[FormalL]^2 + 2 \[FormalL] - 1/4}}},
  TestID -> "general-log-polynomial-first-correction"]

VerificationTest[
  Module[{x, y, s}, s = AsymptoticInverse[x (Log[x]^2 + Log[x] + 1), {x, 0}, y, SeriesTermGoal -> 3];
    s["Blocks"] /. s["LogVariable"] -> \[FormalL]],
  {{0, 1}, {1, 2 \[FormalL]}, {2, 3 \[FormalL]^2 + 2 \[FormalL] - 3/16}},
  TestID -> "general-log-polynomial-centering"]

VerificationTest[
  Module[{x, y, s, c}, s = AsymptoticInverse[x (Log[x]^2 + 1), {x, 0}, y, SeriesTermGoal -> 6];
    c = InverseNumericalCheck[s, Exp[-100], WorkingPrecision -> 40];
    TrueQ[InverseResidual[s]["ZeroBelowCutoff"] && c["Error"]/Abs[c["ExactInverse"]] < 10^-6]],
  True, TestID -> "general-log-polynomial-independent-numerical-check"]

VerificationTest[
  Module[{x, y, s, c}, s = AsymptoticInverse[x (Log[x]^2 + 1), {x, Infinity}, y, SeriesTermGoal -> 6];
    c = InverseNumericalCheck[s, Exp[50], WorkingPrecision -> 40];
    TrueQ[InverseResidual[s]["ZeroBelowCutoff"] && c["Error"]/Abs[c["ExactInverse"]] < 10^-5]],
  True, TestID -> "general-log-polynomial-at-infinity"]

VerificationTest[
  Module[{x, y, s}, s = AsymptoticInverse[-x^2 (Log[x]^3 + Log[x] + 1), {x, 0}, y,
      SeriesTermGoal -> 5, "Power" -> 2];
    InverseResidual[s]["ZeroBelowCutoff"]],
  True, TestID -> "cubic-log-polynomial-observable-residual"]

VerificationTest[
  Module[{x, y, s}, s = AsymptoticInverse[x (Log[x]^2 + 1) + x^2, {x, 0}, y, SeriesTermGoal -> 4];
    {s["LambertPolynomialLog"], s["LeadingCoreOnly"], MissingQ[s["ExactInverseExpression"]], InverseResidual[s]["ZeroBelowCutoff"]}],
  {True, True, True, True}, TestID -> "general-log-polynomial-with-flat-perturbation"]

VerificationTest[
  Module[{x, y, s}, s = AsymptoticInverse[x (Log[x]^2 + 1), {x, 0}, y, SeriesTermGoal -> 3];
    {InverseResidual[s]["ZeroBelowCutoff"], InverseResidual[s, 5]["ZeroBelowCutoff"]}],
  {True, False}, TestID -> "general-log-residual-uses-returned-truncation"]

VerificationTest[
  Module[{x, y, b}, AsymptoticInverse[x (Log[x] + b), {x, 0}, {y, 3}]],
  Failure["UnprovedRealCoefficient", _Association], SameTest -> MatchQ,
  TestID -> "lambert-requires-real-logarithmic-shift"]

VerificationTest[
  Module[{x, y, b}, AsymptoticInverse[x Log[x] + b x^2, {x, 0}, {y, 3}]],
  Failure["UnprovedRealCoefficient", _Association], SameTest -> MatchQ,
  TestID -> "lambert-requires-real-flat-log-perturbation"]

VerificationTest[
  Module[{x, y, b}, AsymptoticInverse[x Exp[x] + b x^2, {x, Infinity}, {y, 3}]],
  Failure["UnprovedRealCoefficient", _Association], SameTest -> MatchQ,
  TestID -> "lambert-requires-real-flat-exponential-perturbation"]

VerificationTest[
  Module[{x, y, b}, AsymptoticInverse[x (Log[x]^2 + b), {x, 0}, {y, 3}, Assumptions -> Element[b, Reals]]["Scale"]],
  "Logarithmic", TestID -> "lambert-real-polynomial-parameter-under-assumptions"]

VerificationTest[
  Module[{x, y, s}, s = AsymptoticInverse[x/(-Log[x])^Sqrt[2], {x, 0}, y, SeriesTermGoal -> 4];
    {s["LambertBranch"], InverseResidual[s]["ZeroBelowCutoff"]}],
  {0, True}, TestID -> "irrational-negative-log-power"]
