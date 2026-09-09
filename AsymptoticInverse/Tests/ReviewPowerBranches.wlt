(* A magnitude remainder does not determine the real branch of a fractional
   power. Nested observables must impose the same contract as SeriesPower. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[
  Module[{x, s},
    And @@ Table[
      s = AsymptoticExpansion[sign x^2, {x, 0, 1}];
      MatchQ[SeriesPower[s, 1/2], Failure["UnknownLeadingTerm", _Association]],
      {sign, {-1, 1}}]],
  True, TestID -> "review-power-direct-fractional-power-needs-more-than-pure-remainder"]

VerificationTest[
  Module[{x, z, s},
    s = AsymptoticExpansion[-x^2, {x, 0, 1}];
    And @@ Table[
      MatchQ[SeriesObservable[s, 1 + z^r, z],
        Failure["UnknownLeadingTerm", _Association]],
      {r, {1/2, 1/3, Sqrt[2]}}]],
  True, TestID -> "review-power-nested-plus-rejects-unproved-fractional-branches"]

VerificationTest[
  Module[{x, z, s},
    s = AsymptoticExpansion[x^2, {x, 0, 1}];
    (* The retained representation has forgotten the source's positive sign. *)
    MatchQ[SeriesObservable[s, 1 + Sqrt[z], z],
      Failure["UnknownLeadingTerm", _Association]]],
  True, TestID -> "review-power-nested-observable-does-not-infer-sign-from-discarded-source"]

VerificationTest[
  Module[{x, z, s},
    s = AsymptoticExpansion[-x^2, {x, 0, 1}];
    {MatchQ[SeriesObservable[s, Exp[Sqrt[z]], z],
       Failure["UnknownLeadingTerm", _Association]],
     MatchQ[SeriesObservable[s, (1 + z) Sqrt[z], z],
       Failure["UnknownLeadingTerm", _Association]]}],
  {True, True}, TestID -> "review-power-analytic-and-product-wrappers-preserve-branch-check"]

VerificationTest[
  Module[{x, z, s},
    s = AsymptoticExpansion[1 - x^2, {x, 0, 1}];
    MatchQ[SeriesObservable[s, 1 + Sqrt[z - 1], z],
      Failure["UnknownLeadingTerm", _Association]]],
  True, TestID -> "review-power-cancellation-inside-observable-cannot-prove-fractional-branch"]

VerificationTest[
  Module[{x, z, s},
    s = AsymptoticExpansion[-x^2, {x, 0, 1}];
    FailureQ[SeriesObservable[s,
      ConditionalExpression[1 + Sqrt[z], Element[Sqrt[z], Reals]], z]]],
  True, TestID -> "review-power-unproved-observable-condition-is-not-a-sign-certificate"]

VerificationTest[
  Module[{x, s, result},
    s = AsymptoticExpansion[-x^2 Log[x]^3, {x, 0, 1}];
    Table[result = SeriesPower[s, n];
      {Normal[result], result["RemainderPower"], result["RemainderLogDegree"]},
      {n, {2, 3}}]],
  {{0, 4, 6}, {0, 6, 9}},
  TestID -> "review-power-positive-integers-preserve-pure-remainder-power-and-log-bounds"]

VerificationTest[
  Module[{x, z, s, result},
    s = AsymptoticExpansion[-x^2 Log[x]^3, {x, 0, 1}];
    result = SeriesObservable[s, 1 + z^3, z, "Cutoff" -> 7];
    {Normal[result], result["RemainderPower"], result["RemainderLogDegree"]}],
  {1, 6, 9}, TestID -> "review-power-nested-integer-power-remains-valid-with-unknown-sign"]

VerificationTest[
  Module[{x, s, zero},
    s = AsymptoticExpansion[x^2, {x, 0, 1}];
    zero = AsymptoticExpansion[0, {x, 0, 1}];
    {FailureQ[SeriesPower[s, 0]], FailureQ[SeriesPower[zero, 0]],
      FailureQ[SeriesPower[s, -1]], FailureQ[SeriesPower[s, -1/2]],
      FailureQ[SeriesPower[zero, -1]]}],
  ConstantArray[True, 5],
  TestID -> "review-power-zero-and-negative-powers-still-require-a-nonzero-leading-term"]

VerificationTest[
  Module[{x, z, zero, direct, nested},
    zero = AsymptoticExpansion[0, {x, 0, 1}];
    direct = SeriesPower[zero, 1/2];
    nested = SeriesObservable[zero, 1 + Sqrt[z], z];
    {Normal[direct], direct["Remainder"], Normal[nested], nested["Remainder"]}],
  {0, 0, 1, 0}, TestID -> "review-power-exact-zero-has-exact-positive-fractional-powers"]

VerificationTest[
  Module[{x, z, a, s, result},
    s = AsymptoticExpansion[a + x, {x, 0, 3}, Assumptions -> a > 0];
    result = SeriesObservable[s, 1 + Sqrt[z], z, "Cutoff" -> 3];
    {TrueQ[FullSimplify[Normal[result] ==
        1 + Sqrt[a] + x/(2 Sqrt[a]) - x^2/(8 a^(3/2)), a > 0 && x > 0]],
      result["RemainderPower"], result["RemainderLogDegree"]}],
  {True, 3, 0}, TestID -> "review-power-proved-positive-symbolic-leading-coefficient-remains-supported"]

VerificationTest[
  Module[{x, z, a, s},
    s = AsymptoticExpansion[a + x, {x, 0, 3}, Assumptions -> Element[a, Reals]];
    FailureQ[SeriesObservable[s, 1 + Sqrt[z], z]]],
  True, TestID -> "review-power-real-symbolic-coefficient-with-unknown-sign-is-insufficient"]

VerificationTest[
  Module[{x, z, s, reciprocal, unit},
    s = AsymptoticExpansion[-x - x^2, {x, 0, 3}];
    reciprocal = SeriesPower[s, -1, 2]; unit = SeriesPower[s, 0];
    {Expand[Normal[reciprocal] - (-1/x + 1 - x)] === 0,
      reciprocal["RemainderPower"], Normal[unit], unit["Remainder"],
      FailureQ[SeriesObservable[s, 1 + Sqrt[z], z]]}],
  {True, 2, 1, 0, True},
  TestID -> "review-power-known-negative-leading-term-allows-integer-but-not-fractional-powers"]

VerificationTest[
  Module[{x, result},
    (* x-Sin[x] = x^3/6-x^5/120+..., so its positive square root starts
       x^(3/2)/Sqrt[6] and the next nonzero block has power 7/2. *)
    result = AsymptoticExpansion[Sqrt[x - Sin[x]], {x, 0, 2}];
    {TrueQ[FullSimplify[Normal[result] == x^(3/2)/Sqrt[6], x > 0]],
      TrueQ[2 < result["RemainderPower"] <= 7/2]}],
  {True, True},
  TestID -> "review-power-forward-retries-cancellation-to-recover-positive-leading-term"]

VerificationTest[
  Module[{x}, FailureQ[AsymptoticExpansion[Sqrt[Sin[x] - x], {x, 0, 1}]]],
  True, TestID -> "review-power-forward-cancellation-does-not-hide-a-nonreal-branch"]

VerificationTest[
  Module[{x, z, s},
    s = AsymptoticExpansion[1 + x, {x, 0, 3}];
    {FailureQ[SeriesObservable[s, 1 + z^0.5, z]],
      FailureQ[SeriesObservable[s, 1 + Sqrt[I z], z]]}],
  {True, True}, TestID -> "review-power-wrapped-powers-preserve-inexact-and-complex-input-rejection"]
