(* Independent reversion formulas exercise repeated term-goal construction,
   including a final shrinking cutoff and different subsequent requests. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[Module[{x, y, s},
  s = AsymptoticLogarithmicInverse[x + x^2 Sqrt[-Log[x]] + x^(21/10) Sqrt[-Log[x]],
    {x, 0}, y, SeriesTermGoal -> 2];
  {TrueQ[FullSimplify[Normal[s] == y - y^2 Sqrt[-Log[y]], 0 < y < Exp[-2]]],
    s["Cutoff"], s["RemainderPower"], s["RemainderLogDegree"],
    Sort[s["IndexRegion"]["Inside"]], s["ReturnedTermCount"], s["TermGoalConstructionCalls"]}],
  {True, 21/10, 21/10, 2, {{0, 0}, {1, 0}}, 2, 3},
  TestID -> "logarithmic-builder-shrinking-cutoff-excludes-an-already-computed-block"]

VerificationTest[Module[{x, y, s, ell, expected},
  s = AsymptoticLogarithmicInverse[x + x^2 Sqrt[-Log[x]] + x^3 (-2 Log[x] - 1/2),
    {x, 0}, y, SeriesTermGoal -> 3];
  ell = -Log[y];
  expected = y - y^2 Sqrt[ell] + y^4 (5 ell^(3/2) - 11 Sqrt[ell]/4 + 1/(8 Sqrt[ell]));
  {s["Terms"][[All, 1]], TrueQ[FullSimplify[Normal[s] == expected, 0 < y < Exp[-2]]],
    s["RemainderPower"], s["TermGoalReached"]}],
  {{1, 2, 4}, True, 5, True},
  TestID -> "logarithmic-builder-retains-zero-coefficients-without-counting-cancelled-resonances"]

VerificationTest[Module[{x, y, first, second, third, ell},
  first = AsymptoticLogarithmicInverse[x + x^2 Sqrt[-Log[x]], {x, 0}, y, SeriesTermGoal -> 3];
  second = AsymptoticLogarithmicInverse[x + 3 x^2 Sqrt[-Log[x]], {x, 0}, y,
    SeriesTermGoal -> 3, "Power" -> 2];
  third = AsymptoticLogarithmicInverse[x + x^2 Sqrt[-Log[x]], {x, 0}, y, SeriesTermGoal -> 2];
  ell = -Log[y];
  TrueQ[FullSimplify[
    Normal[first] == y - y^2 Sqrt[ell] + y^3 (2 ell - 1/2) &&
    Normal[second] == y^2 - 6 y^3 Sqrt[ell] + 9 y^4 (5 ell - 1) &&
    Normal[third] == y - y^2 Sqrt[ell], 0 < y < Exp[-2]]]],
  True, TestID -> "logarithmic-builder-state-is-local-to-source-and-observable"]

VerificationTest[Module[{x, y, first, refined},
  first = AsymptoticLogarithmicInverse[x + Sqrt[x] Sqrt[Log[x]], {x, Infinity}, y,
    SeriesTermGoal -> 1];
  refined = SeriesRefine[first, -1/4];
  {TrueQ[FullSimplify[Normal[refined] == y - Sqrt[y] Sqrt[Log[y]], y > Exp[2]]],
    refined["RemainderPower"], refined["Power"]}],
  {True, 0, 1}, TestID -> "logarithmic-builder-refinement-rebuilds-the-infinite-source-coordinate"]

VerificationTest[Module[{x, y, a},
  {MatchQ[AsymptoticLogarithmicInverse[a x + x^2 Sqrt[-Log[x]], {x, 0}, y,
      SeriesTermGoal -> 0, Assumptions -> Element[a, Reals]], Failure["InvalidCutoff", _Association]],
    MatchQ[AsymptoticLogarithmicInverse[a x + x^2 Sqrt[-Log[x]], {x, 0}, {y, 3},
      Assumptions -> Element[a, Reals]],
      Failure["UnprovedSign", _Association]],
    MatchQ[AsymptoticLogarithmicInverse[x + x^2 Sqrt[-Log[x]], {x, 0}, {y, 1}],
      Failure["CutoffTooSmall", _Association]]}],
  {True, True, True}, TestID -> "logarithmic-builder-preserves-lazy-option-and-family-validation"]
