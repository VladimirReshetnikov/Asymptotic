(* Elementary coefficient oracles come directly from Exp[t] = Sum[t^k/k!,k].
   The bounded variable-power oracle exponentiates
     x Log[1+1/x] = 1 - 1/(2x) + 1/(3x^2) - 1/(4x^3) + ... .
   The LogGamma oracle uses the independently tabulated squared Stirling
   coefficients. Expected values never call native Series or package algebra. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

exponentialForwardBracket[z_, n_] := Sum[z^-k/k!, {k, 0, n - 1}];
exponentialForwardEqual[s_, expr_, ass_: True] :=
  MatchQ[s, _PowerLogSeries] && TrueQ[FullSimplify[Normal[s] == expr, ass]];

VerificationTest[Module[{x, s, refined},
  (* The combined logarithm is -5 Log[x]-1/2+x/3-x^2/4+... .
     An optional attempt to prove the correction exact can reintroduce
     Exp[-1/x], whose separate exact jet is unsupported. The valid
     approximate logarithmic expansion must survive that failed probe. *)
  s = AsymptoticExpansion[x^-5 (1 + x)^(1/x^2) Exp[-1/x], {x, 0, 2}];
  refined = SeriesRefine[s, 3];
  {exponentialForwardEqual[s, Exp[-1/2] x^-5 (1 + x/3), x > 0],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == Exp[-1/2] x^-3, x > 0]],
    s["Exact"], s["RemainderPower"],
    exponentialForwardEqual[refined, Exp[-1/2] x^-5 (1 + x/3 - 7 x^2/36), x > 0],
    refined["RemainderPower"], refined["Exact"]}],
  {True, True, False, 2, True, 3, False},
  TestID -> "exponential-forward-optional-exactness-failure-preserves-cancelled-source-expansion"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[x + 1/x], x -> Infinity, SeriesTermGoal -> 5];
  {exponentialForwardEqual[s, Exp[x] exponentialForwardBracket[x, 5], x > 0],
    s["Terms"], s["RemainderPower"], s["RemainderLogDegree"],
    TrueQ[FullSimplify[s["Prefactor"] == Exp[x], x > 0]],
    TrueQ[FullSimplify[s["Remainder"] == Exp[x] PowerLogRemainder[1/x, 5, 0], x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == Exp[x]/(120 x^5), x > 0]],
    s["Exact"], s["Kind"]}],
  {True, {{0, 1}, {1, 1}, {2, 1/2}, {3, 1/6}, {4, 1/24}}, 5, 0,
    True, True, True, False, "Forward"},
  TestID -> "exponential-forward-unbounded-source-five-independent-coefficients"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[-x + 1/x], x -> Infinity, SeriesTermGoal -> 5];
  {exponentialForwardEqual[s, Exp[-x] exponentialForwardBracket[x, 5], x > 0],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == Exp[-x]/x^5, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == Exp[-x]/(120 x^5), x > 0]],
    s["RemainderPower"], Length[s["Terms"]]}],
  {True, True, True, 5, 5},
  TestID -> "exponential-forward-decaying-prefactor-transports-absolute-remainder"]

VerificationTest[Module[{x, s, refined},
  s = AsymptoticExpansion[x^x, x -> Infinity, SeriesTermGoal -> 5];
  refined = SeriesRefine[s, 7];
  {exponentialForwardEqual[s, x^x, x > 0], s["Terms"], s["Remainder"], s["Exact"],
    exponentialForwardEqual[refined, x^x, x > 0], refined["Remainder"], refined["Exact"]}],
  {True, {{0, 1}}, 0, True, True, 0, True},
  TestID -> "exponential-forward-variable-power-exact-model-terminates-and-refines"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[(1 + 1/x)^x, x -> Infinity, SeriesTermGoal -> 5];
  {exponentialForwardEqual[s, E (1 - 1/(2 x) + 11/(24 x^2)
      - 7/(16 x^3) + 2447/(5760 x^4)), x > 0],
    s["RemainderPower"], Length[s["Terms"]], s["Exact"]}],
  {True, 5, 5, False},
  TestID -> "exponential-forward-bounded-variable-power-preserves-ordinary-expansion"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[x^Sqrt[2], x -> Infinity, SeriesTermGoal -> 5];
  {exponentialForwardEqual[s, x^Sqrt[2], x > 0],
    s["Terms"], s["Remainder"], s["Exact"]}],
  {True, {{-Sqrt[2], 1}}, 0, True},
  TestID -> "exponential-forward-fixed-irrational-power-keeps-ordinary-term-convention"]

VerificationTest[Module[{x, s, pref},
  pref = 2 Pi Exp[-2 x] x^(2 x - 1);
  s = AsymptoticExpansion[Exp[2 LogGamma[x]], x -> Infinity, SeriesTermGoal -> 5];
  {exponentialForwardEqual[s, pref (1 + 1/(6 x) + 1/(72 x^2)
      - 31/(6480 x^3) - 139/(155520 x^4)), x > 0],
    s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"] == pref 9871/(6531840 x^5), x > 0]],
    s["Exact"]}],
  {True, 5, True, False},
  TestID -> "exponential-forward-explicit-loggamma-source-reuses-prefactor-calculus"]

VerificationTest[Module[{x, positive, negative, bracket},
  bracket = exponentialForwardBracket[x, 5];
  positive = AsymptoticExpansion[x^2 Exp[x + 1/x], x -> Infinity, SeriesTermGoal -> 5];
  negative = AsymptoticExpansion[-3 x^2 Exp[x + 1/x], x -> Infinity, SeriesTermGoal -> 5];
  {exponentialForwardEqual[positive, x^2 Exp[x] bracket, x > 0],
    exponentialForwardEqual[negative, -3 x^2 Exp[x] bracket, x > 0],
    TrueQ[FullSimplify[positive["RemainderScaleExpression"] == Exp[x]/x^3, x > 0]],
    TrueQ[FullSimplify[negative["RemainderScaleExpression"] == 3 Exp[x]/x^3, x > 0]],
    TrueQ[FullSimplify[negative["FrontierTerm"] == -Exp[x]/(40 x^3), x > 0]],
    Length[positive["Terms"]], Length[negative["Terms"]]}],
  {True, True, True, True, True, 5, 5},
  TestID -> "exponential-forward-ordinary-signed-factors-preserve-five-relative-terms"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> 5];
  {exponentialForwardEqual[s, 1 + x + x^2/2 + x^3/6 + x^4/24],
    s["Terms"], s["Remainder"] === PowerLogRemainder[x, 5, 0],
    s["RemainderPower"], s["Exact"]}],
  {True, {{0, 1}, {1, 1}, {2, 1/2}, {3, 1/6}, {4, 1/24}}, True, 5, False},
  TestID -> "exponential-forward-finite-source-keeps-ordinary-taylor-semantics"]

VerificationTest[Module[{x, r}, Quiet[{
    FailureQ[AsymptoticExpansion[Exp[x + 1/x], x -> Infinity, SeriesTermGoal -> 0]],
    FailureQ[AsymptoticExpansion[Exp[x + 1/x], x -> Infinity, SeriesTermGoal -> 5, "MaxTerms" -> 1]],
    FailureQ[AsymptoticExpansion[Exp[x + 1/x], {x, Infinity, 3.5}]],
    FailureQ[AsymptoticExpansion[Exp[2.0 x + 1/x], x -> Infinity, SeriesTermGoal -> 5]],
    FailureQ[AsymptoticExpansion[Exp[r x], x -> Infinity, SeriesTermGoal -> 5]]}]],
  {True, True, True, True, True},
  TestID -> "exponential-forward-invalid-goals-budgets-inexact-data-and-unproved-parameters-fail"]

VerificationTest[Module[{x, s, refined},
  s = AsymptoticExpansion[ConditionalExpression[Exp[x + 1/x], x > 2],
    x -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 5];
  {exponentialForwardEqual[refined, Exp[x] exponentialForwardBracket[x, 5], x > 2],
    TrueQ[(s["TargetDomain"] /. x -> 1) === False],
    TrueQ[(s["SeriesRepresentation"]["Domain"] /. x -> 1) === False],
    TrueQ[(refined["TargetDomain"] /. x -> 1) === False],
    TrueQ[refined["TargetDomain"] /. x -> 3], refined["RemainderPower"]}],
  {True, True, True, True, True, 5},
  TestID -> "exponential-forward-conditional-domain-survives-refinement"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[Exp[1/x + x], x -> 0, SeriesTermGoal -> 5];
  {exponentialForwardEqual[s, Exp[1/x] (1 + x + x^2/2 + x^3/6 + x^4/24), x > 0],
    s["RemainderVariable"] === x, s["RemainderPower"], s["Direction"],
    TrueQ[FullSimplify[s["FrontierTerm"] == Exp[1/x] x^5/120, x > 0]]}],
  {True, True, 5, "FromAbove", True},
  TestID -> "exponential-forward-unbounded-source-at-positive-finite-endpoint"]

VerificationTest[Module[{x, s},
  s = AsymptoticExpansion[x^(x + 1/x), x -> Infinity, SeriesTermGoal -> 5];
  {exponentialForwardEqual[s, x^x Sum[Log[x]^k/(k! x^k), {k, 0, 4}], x > 0],
    s["RemainderPower"], s["RemainderLogDegree"],
    TrueQ[FullSimplify[s["FrontierTerm"] == x^x Log[x]^5/(120 x^5), x > 0]],
    Length[s["Terms"]]}],
  {True, 5, 5, True, 5},
  TestID -> "exponential-forward-variable-power-retains-logarithmic-correction-blocks"]

VerificationTest[Module[{x, s, pref},
  (* Sqrt[x-1]+1/x = Sqrt[x] - 1/(2 Sqrt[x]) + 1/x
       - 1/(8 x^(3/2)) + ... . Exponentiation gives c_2=9/8,
     c_3=-1/8-1/2-1/48=-31/48. Realness needs only x>1 eventually. *)
  pref = Exp[Sqrt[x]];
  s = AsymptoticExpansion[Exp[Sqrt[x - 1] + 1/x],
    x -> Infinity, SeriesTermGoal -> 3];
  {exponentialForwardEqual[s, pref (1 - 1/(2 Sqrt[x]) + 9/(8 x)), x > 1],
    s["Terms"], s["RemainderPower"], s["RemainderLogDegree"],
    TrueQ[FullSimplify[s["FrontierTerm"] == -31 pref/(48 x^(3/2)), x > 1]]}],
  {True, {{0, 1}, {1/2, -1/2}, {1, 9/8}}, 3/2, 0, True},
  TestID -> "exponential-forward-source-realness-needs-only-eventual-shifted-domain"]

VerificationTest[Module[{x, s, refined},
  (* The exact normalized bracket is 1-1/x. A finite Taylor expansion of
     Log[1-1/x] alone cannot certify that its exponential terminates. *)
  s = AsymptoticExpansion[(x - 1) Exp[x], x -> Infinity, SeriesTermGoal -> 5];
  refined = SeriesRefine[s, 7];
  {exponentialForwardEqual[s, (x - 1) Exp[x], x > 1],
    s["Terms"], s["Remainder"], s["Exact"],
    exponentialForwardEqual[refined, (x - 1) Exp[x], x > 1],
    refined["Remainder"], refined["Exact"]}],
  {True, {{0, 1}, {1, -1}}, 0, True, True, 0, True},
  TestID -> "exponential-forward-polynomial-factor-proves-exact-bracket-and-refines"]

VerificationTest[Module[{x, s, refined},
  s = AsymptoticExpansion[Exp[x + Log[1 + 1/x]],
    x -> Infinity, SeriesTermGoal -> 5];
  refined = SeriesRefine[s, 7];
  {exponentialForwardEqual[s, Exp[x] (1 + 1/x), x > 0],
    s["Terms"], s["Remainder"], s["Exact"],
    exponentialForwardEqual[refined, Exp[x] (1 + 1/x), x > 0],
    refined["Remainder"], refined["Exact"]}],
  {True, {{0, 1}, {1, 1}}, 0, True, True, 0, True},
  TestID -> "exponential-forward-logarithmic-source-proves-exact-bracket-and-refines"]

VerificationTest[Module[{x, s},
  (* Multiplying squared Gamma's exponential source by x shifts only its
     exact prefactor. Its independent Stirling correction remains intact. *)
  s = AsymptoticExpansion[x Exp[2 LogGamma[x]],
    x -> Infinity, SeriesTermGoal -> 3];
  {TrueQ[FullSimplify[Log[s["Prefactor"]]
      - (2 x Log[x] - 2 x + Log[2 Pi]), x > 0] === 0],
    s["Terms"], s["RemainderPower"],
    TrueQ[FullSimplify[s["FrontierTerm"]/s["Prefactor"] == -31/(6480 x^3), x > 0]],
    s["Exact"]}],
  {True, {{0, 1}, {1, 1/6}, {2, 1/72}}, 3, True, False},
  TestID -> "exponential-forward-explicit-loggamma-source-with-ordinary-factor"]
