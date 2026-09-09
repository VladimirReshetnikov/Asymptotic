(* Stage 1/5 acceptance: exact independent formulas and several known-source
   numerical targets. Numerical comparisons are evidence, not certificates. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

acceptanceKnownSources[s_, f_, x_, y_, points_, factor_] := Module[{ratios},
  If[! MatchQ[s, _GeneralizedSeries], Return[False, Module]];
  ratios = Table[With[{target = N[f /. x -> point, 110]},
    N[Abs[(Normal[s] /. y -> target) - N[point, 100]]/
      (s["RemainderScaleExpression"] /. y -> target), 80]], {point, points}];
  And @@ (TrueQ[0 < # < factor] & /@ ratios)];

VerificationTest[Module[{x, y, s, l, expected},
  s = AsymptoticInverse[Exp[x^2 + x Log[x]], {x, Infinity}, {y, 1}]; l = Log[y];
  expected = Sqrt[l] - Log[l]/4 + (Log[l]^2 + 4 Log[l])/(32 Sqrt[l]);
  {TrueQ[FullSimplify[Normal[s] == expected, y > E]], InverseResidual[s]["ZeroBelowCutoff"]}],
  {True, True}, TestID -> "acceptance-coordinate-polynomial-log-phase-independent-coefficients"]

VerificationTest[Module[{x, y, f, s}, f = Exp[x^2 + x Log[x]];
  s = AsymptoticInverse[f, {x, Infinity}, {y, 1}];
  acceptanceKnownSources[s, f, x, y, {10, 20, 40}, 20]],
  True, TestID -> "acceptance-coordinate-polynomial-log-phase-three-numerical-scales"]

VerificationTest[Module[{x, y, s, l},
  s = AsymptoticInverse[x^3 Exp[x^2 + x], {x, Infinity}, {y, 1}]; l = Log[y];
  {TrueQ[FullSimplify[Normal[s] == Sqrt[l] - 1/2 + (1/8 - 3 Log[l]/4)/Sqrt[l], y > E]],
    InverseResidual[s]["ZeroBelowCutoff"]}],
  {True, True}, TestID -> "acceptance-coordinate-cubic-amplitude-phase-independent-coefficients"]

VerificationTest[Module[{x, y, s, l},
  s = AsymptoticInverse[Exp[(x - 3)^2 + (x - 3)], {x, Infinity}, {y, 1}]; l = Log[y];
  TrueQ[FullSimplify[Normal[s] == 3 + Sqrt[l] - 1/2 + 1/(8 Sqrt[l]), y > E]]],
  True, TestID -> "acceptance-coordinate-quadratic-oracle-keeps-source-translation"]

VerificationTest[Module[{x, y, s, expected},
  s = AsymptoticInverse[Log[x]^2 + Log[x], {x, Infinity}, {y, 1}];
  expected = Exp[Sqrt[y] - 1/2] (1 + 1/(8 Sqrt[y]));
  {TrueQ[FullSimplify[Normal[s] == expected, y > 1]], s["RemainderPower"]}],
  {True, 1}, TestID -> "acceptance-source-quadratic-log-at-infinity-exponential-oracle"]

VerificationTest[Module[{x, y, f, s}, f = Log[x]^2 + Log[x];
  s = AsymptoticInverse[f, {x, Infinity}, {y, 1}];
  acceptanceKnownSources[s, f, x, y, Exp /@ {10, 20, 40}, 10]],
  True, TestID -> "acceptance-source-quadratic-log-three-numerical-scales"]

VerificationTest[Module[{x, y, s},
  s = AsymptoticInverse[Log[x]^2 + Log[x], {x, Infinity}, y, SeriesTermGoal -> 1];
  {s["ReturnedTermCount"], TrueQ[FullSimplify[Normal[s] == Exp[Sqrt[y] - 1/2], y > 1]],
    s["RemainderPower"] > 0}],
  {1, True, True}, TestID -> "acceptance-source-coarse-term-goal-still-has-vanishing-relative-error"]

VerificationTest[Module[{x, y, s, t}, s = AsymptoticInverse[-Log[x], {x, 0}, {y, 2}];
  t = AsymptoticInverse[(-Log[x])^2 - Log[x], {x, 0}, {y, 1}];
  {Normal[s] === Exp[-y] && s["Remainder"] === 0,
    TrueQ[FullSimplify[Normal[t] == Exp[-Sqrt[y] + 1/2] (1 - 1/(8 Sqrt[y])), y > 1]]}],
  {True, True}, TestID -> "acceptance-source-negative-log-and-positive-quadratic-log-core"]

VerificationTest[Module[{x, y, s, t, w, exactOracle},
  s = AsymptoticInverse[Exp[x] + Exp[2 x], {x, Infinity}, {y, 2}];
  exactOracle = -Log[w] - ArcSinh[w/2];
  t = Normal[Series[exactOracle, {w, 0, 3}]] /. w -> 1/Sqrt[y];
  TrueQ[FullSimplify[Normal[s] == t, y > 1]]],
  True, TestID -> "acceptance-source-two-growing-rates-independent-quadratic-oracle"]

VerificationTest[Module[{x, y, s, d = 1 - 1/Sqrt[2]},
  s = AsymptoticInverse[Exp[x] + Exp[Sqrt[2] x], {x, Infinity}, {y, 2 d}];
  TrueQ[FullSimplify[Normal[s] == Log[y]/Sqrt[2] - y^-d/Sqrt[2], y > 1]]],
  True, TestID -> "acceptance-source-incommensurable-exponential-rates"]

VerificationTest[Module[{x, y, f, s, d = 1 - 1/Sqrt[2]}, f = Exp[x] + Exp[Sqrt[2] x];
  s = AsymptoticInverse[f, {x, Infinity}, {y, 2 d}];
  acceptanceKnownSources[s, f, x, y, {10, 20, 40}, 10]],
  True, TestID -> "acceptance-source-incommensurable-rates-three-numerical-scales"]

VerificationTest[Module[{x, y, s, f}, f = Exp[-x] + 2 Exp[-3 x];
  s = AsymptoticInverse[f, {x, Infinity}, {y, 3}];
  {TrueQ[FullSimplify[Normal[s] == -Log[y] + 2 y^2, 0 < y < 1]],
    acceptanceKnownSources[s, f, x, y, {5, 10, 15}, 20]}],
  {True, True}, TestID -> "acceptance-source-weighted-decaying-rates-three-numerical-scales"]

VerificationTest[Module[{x, y, s, v, f}, f = 3 - Exp[-x] + Exp[-2 x];
  s = AsymptoticInverse[f, {x, Infinity}, {y, 4}]; v = 3 - y;
  {s["Limit"], TrueQ[FullSimplify[Normal[s] == -Log[v] - v - 3 v^2/2 - 10 v^3/3, 0 < v < 1/4]],
    TrueQ[FullSimplify[! s["TargetDomain"], y > 3]],
    acceptanceKnownSources[s, f, x, y, {5, 10, 15}, 20]}],
  {3, True, True, True}, TestID -> "acceptance-source-signed-finite-target-offset-and-side"]

VerificationTest[Module[{x, y, f, s, expected},
  f = 2 Exp[x] + Exp[2 x] - Exp[x] + 3 Exp[2 x] - 2 Exp[2 x];
  s = AsymptoticInverse[f, {x, Infinity}, {y, 1}];
  expected = Log[y/2]/2 - 1/(2 Sqrt[2 y]);
  TrueQ[FullSimplify[Normal[s] == expected, y > 1]]],
  True, TestID -> "acceptance-source-duplicate-and-cancelled-exponential-rates"]

VerificationTest[Module[{x, a, b, s},
  a = AsymptoticExpansion[1 + x Log[x]^3, {x, 0, 1}];
  b = AsymptoticExpansion[Log[x]^2, {x, 0, 1}]; s = SeriesMultiply[a, b];
  {Normal[s] === Log[x]^2, s["RemainderPower"], s["RemainderLogDegree"]}],
  {True, 1, 5}, TestID -> "acceptance-calculus-product-discarded-boundary-raises-log-degree"]

VerificationTest[Module[{x, uncertain},
  uncertain = AsymptoticExpansion[x + x^2, {x, 0, 1}];
  FailureQ[SeriesPower[uncertain, -1, 3]]],
  True, TestID -> "acceptance-calculus-reciprocal-rejects-uncertain-leading-term"]

VerificationTest[Module[{x, y, s, directSquare, directReciprocal, square, reciprocal, oracle},
  s = AsymptoticInverse[2 x + x^2, {x, 0}, {y, 7}]; oracle = -1 + Sqrt[1 + y];
  square = SeriesPower[s, 2, 5]; reciprocal = SeriesPower[s, -1, 4];
  directSquare = AsymptoticInverse[2 x + x^2, {x, 0}, {y, 5}, "Power" -> 2];
  directReciprocal = AsymptoticInverse[2 x + x^2, {x, 0}, {y, 4}, "Power" -> -1];
  {Expand[Normal[square] - Normal[Series[oracle^2, {y, 0, 4}]]] === 0,
    Expand[Normal[reciprocal] - Normal[Series[1/oracle, {y, 0, 3}]]] === 0,
    Expand[Normal[square] - Normal[directSquare]] === 0,
    Expand[Normal[reciprocal] - Normal[directReciprocal]] === 0,
    square["RemainderPower"] >= 5, reciprocal["RemainderPower"] >= 4}],
  {True, True, True, True, True, True}, TestID -> "acceptance-calculus-two-inverse-observables-independent-oracle"]

VerificationTest[Module[{x, y, outer, inner, s},
  outer = AsymptoticExpansion[1 - Cos[x], {x, 0, 6}];
  inner = AsymptoticExpansion[y^2 + y^3, {y, 0, 3}];
  s = SeriesCompose[outer, inner, "Cutoff" -> 8];
  {Expand[Normal[s]] === y^4/2, s["RemainderPower"]}],
  {True, 5}, TestID -> "acceptance-calculus-vanishing-first-derivative-improves-composition-error"]

VerificationTest[Module[{x, y, outer, inner, s},
  outer = AsymptoticExpansion[Sin[x] - x, {x, 0, 7}];
  inner = AsymptoticExpansion[y^2 + y^3, {y, 0, 3}];
  s = SeriesCompose[outer, inner, "Cutoff" -> 10];
  {Expand[Normal[s]] === -y^6/6, s["RemainderPower"]}],
  {True, 7}, TestID -> "acceptance-calculus-two-vanishing-derivatives-improve-composition-error"]

VerificationTest[Module[{x, y, z, s, observed, oracle, expected},
  s = AsymptoticInverse[(3 - x) + (3 - x)^2, {x, 3}, {y, 6}, Direction -> "FromBelow"];
  observed = SeriesObservable[s, (z - 3)^2, z, "Cutoff" -> 5];
  oracle = (1 - Sqrt[1 + 4 y])/2;
  expected = Normal[Series[oracle^2, {y, 0, 4}]];
  {Expand[Normal[observed] - expected] === 0, observed["RemainderPower"] >= 5}],
  {True, True}, TestID -> "acceptance-calculus-observable-at-shifted-left-source-endpoint"]
