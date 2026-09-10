(* Composable expansions: compare algebraic identities and transported error
   orders; deliberately test rejection of an unjustified derivative bound. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[Module[{x,y,s,t},
 s=AsymptoticInverse[Sin[x],{x,0},{y,3}]; t=SeriesRefine[s,8];
 {TrueQ[FullSimplify[Normal[t]==Normal[Series[ArcSin[y],{y,0,7}]],y>0]],
   t["DeclaredInputRemainder"], t["RemainderPower"]>=8}],
 {True,Automatic,True},TestID->"calculus-refinement-grows-an-automatically-expanded-forward-model"]

VerificationTest[Module[{x,y,s,t},
 s=AsymptoticInverse[x+x^2,{x,0},{y,3},"InputRemainder"->{3,0}]; t=SeriesRefine[s,8];
 {s["DeclaredInputRemainder"],If[FailureQ[t],t[[1]],"UnexpectedSuccess"]}],
 {{3,0},"InsufficientInputOrder"},TestID->"calculus-refinement-preserves-declared-forward-error-ceiling"]

VerificationTest[Module[{x, a, b, s},
  a = AsymptoticExpansion[Sin[x], {x, 0, 5}]; b = AsymptoticExpansion[Cos[x], {x, 0, 4}];
  s = SeriesAdd[a, b]; {Expand[Normal[s]], s["RemainderPower"]} /. x -> \[FormalX]],
  {1 + \[FormalX] - \[FormalX]^2/2 - \[FormalX]^3/6, 4}, TestID -> "calculus-add-common-precision"]

VerificationTest[Module[{x, a, b, s},
  a = AsymptoticExpansion[x + x^2, {x, 0, 2}]; b = AsymptoticExpansion[x + x^3, {x, 0, 3}];
  s = SeriesMultiply[a, b]; {Normal[s], s["RemainderPower"]} /. x -> \[FormalX]],
  {\[FormalX]^2, 3}, TestID -> "calculus-product-error-transport"]

VerificationTest[Module[{x, s}, s = SeriesPower[AsymptoticExpansion[x + x^2 + x^3, {x, 0, 3}], -1, 3];
  {Expand[Normal[s]], s["RemainderPower"]} /. x -> \[FormalX]],
  {-1 + 1/\[FormalX], 1}, TestID -> "calculus-reciprocal-loses-absolute-precision"]

VerificationTest[Module[{x, s}, s = SeriesLog[AsymptoticExpansion[x + x^2, {x, 0, 5}], 4];
  {Expand[Normal[s]], s["RemainderPower"]} /. x -> \[FormalX]],
  {\[FormalX] - \[FormalX]^2/2 + \[FormalX]^3/3 + Log[\[FormalX]], 4}, TestID -> "calculus-logarithm-of-series"]

VerificationTest[Module[{x, s}, s = SeriesExp[AsymptoticExpansion[1/x + Log[x] + x, {x, 0, 5}], 4];
  {TrueQ[FullSimplify[Normal[s] == x Exp[1/x] (1 + x + x^2/2 + x^3/6), x > 0]], s["RemainderPower"]}],
  {True, 4}, TestID -> "calculus-exponential-extracts-unbounded-carrier"]

VerificationTest[Module[{x}, FailureQ[SeriesExp[AsymptoticExpansion[1/x + 1, {x, 0, 0}], 4]]],
  True, TestID -> "calculus-exponential-rejects-nonvanishing-argument-error"]

VerificationTest[Module[{x, s, t}, s = SeriesExp[AsymptoticExpansion[1/x + x, {x, 0, 5}], 4];
  t = SeriesLog[s, 3]; TrueQ[FullSimplify[Normal[t] == 1/x + x, x > 0]]],
  True, TestID -> "calculus-log-exp-carrier-roundtrip"]

VerificationTest[Module[{x, y, outer, inner, s},
  outer = AsymptoticExpansion[Sin[x], {x, 0, 5}]; inner = AsymptoticExpansion[y^2 + y^3, {y, 0, 7}];
  s = SeriesCompose[outer, inner, "Cutoff" -> 8]; {Expand[Normal[s]], s["RemainderPower"]} /. y -> \[FormalY]],
  {\[FormalY]^2 + \[FormalY]^3 - \[FormalY]^6/6 - \[FormalY]^7/2, 8}, TestID -> "calculus-compose-ramified-inner"]

VerificationTest[Module[{x, y, s}, s = SeriesCompose[AsymptoticExpansion[Log[1 + x], {x, 0, 4}],
    AsymptoticExpansion[y^2 + y^3, {y, 0, 3}], "Cutoff" -> 7];
  {Normal[s], s["RemainderPower"]} /. y -> \[FormalY]],
  {\[FormalY]^2, 3}, TestID -> "calculus-compose-retains-inner-uncertainty"]

VerificationTest[Module[{x, y}, FailureQ[SeriesCompose[AsymptoticExpansion[Sin[x], {x, 0, 4}],
    AsymptoticExpansion[1 + y, {y, 0, 4}], "Cutoff" -> 4]]],
  True, TestID -> "calculus-compose-rejects-wrong-limit"]

VerificationTest[Module[{x, y, s}, s = SeriesCompose[AsymptoticExpansion[Log[2 - x], {x, 1, 4}, Direction -> "FromBelow"],
    AsymptoticExpansion[1 - y - y^2, {y, 0, 5}], "Cutoff" -> 4];
  Expand[Normal[s]] /. y -> \[FormalY]],
  \[FormalY] + \[FormalY]^2/2 - 2 \[FormalY]^3/3, TestID -> "calculus-compose-respects-one-sided-coordinate"]

VerificationTest[Module[{x, z, s}, s = SeriesObservable[AsymptoticExpansion[x + x^2, {x, 0, 5}], Sin[z], z, "Cutoff" -> 4];
  Expand[Normal[s]] /. x -> \[FormalX]],
  \[FormalX] + \[FormalX]^2 - \[FormalX]^3/6, TestID -> "calculus-regular-analytic-observable"]

VerificationTest[Module[{x, s}, s = SeriesTruncate[AsymptoticExpansion[x + x^2 Log[x]^3 + x^3, {x, 0, 5}], 2];
  {Normal[s], s["RemainderPower"], s["RemainderLogDegree"]} /. x -> \[FormalX]],
  {\[FormalX], 2, 3}, TestID -> "calculus-truncate-preserves-boundary-log-degree"]

VerificationTest[Module[{x, s}, s = SeriesRefine[AsymptoticExpansion[Sin[x], {x, 0, 2}], 6];
  {Expand[Normal[s]], s["RemainderPower"]} /. x -> \[FormalX]],
  {\[FormalX] - \[FormalX]^3/6 + \[FormalX]^5/120, 7}, TestID -> "calculus-refine-replays-original-function"]

VerificationTest[Module[{x, y, s}, s = SeriesRefine[AsymptoticInverse[x + x^2, {x, 0}, {y, 2}], 5];
  Expand[Normal[s]] /. y -> \[FormalY]],
  \[FormalY] - \[FormalY]^2 + 2 \[FormalY]^3 - 5 \[FormalY]^4, TestID -> "calculus-refine-replays-inverse"]

VerificationTest[Module[{x, s}, s = SeriesRefine[SeriesLog[AsymptoticExpansion[x + x^2, {x, 0, 3}], 2], 4];
  Expand[Normal[s]] /. x -> \[FormalX]],
  \[FormalX] - \[FormalX]^2/2 + \[FormalX]^3/3 + Log[\[FormalX]], TestID -> "calculus-refine-replays-observable-recipe"]

VerificationTest[Module[{x}, FailureQ[SeriesDifferentiate[AsymptoticExpansion[Sin[x], {x, 0, 4}]]]],
  True, TestID -> "calculus-does-not-differentiate-unqualified-big-o"]

VerificationTest[Module[{x, s}, s = SeriesDifferentiate[AsymptoticExpansion[Sin[x], {x, 0, 4}], 1, "RemainderDerivativeOrder" -> 1];
  {Expand[Normal[s]], s["RemainderPower"]} /. x -> \[FormalX]],
  {1 - \[FormalX]^2/2, 4}, TestID -> "calculus-differentiates-with-explicit-derivative-contract"]

VerificationTest[Module[{x, s}, s = SeriesDifferentiate[AsymptoticExpansion[x Log[x] + x^2, {x, 0, 4}]];
  {Expand[Normal[s]], s["Remainder"]} /. x -> \[FormalX]],
  {1 + 2 \[FormalX] + Log[\[FormalX]], 0}, TestID -> "calculus-differentiates-exact-power-log-expression"]

VerificationTest[Module[{x, s}, s = SeriesDifferentiate[AsymptoticExpansion[x^-2 + x^-3, {x, Infinity, 3}], 1,
    "RemainderDerivativeOrder" -> 1];
  TrueQ[FullSimplify[Normal[s] == -2/x^3 && s["RemainderScaleExpression"] == x^-4, x > 0]]],
  True, TestID -> "calculus-derivative-chain-rule-at-infinity"]

VerificationTest[Module[{x, s}, s = SeriesPower[AsymptoticExpansion[Sin[x], {x, 0, 3}], 0];
  {Normal[s], s["Remainder"], Normal[SeriesDifferentiate[s]]}],
  {1, 0, 0}, TestID -> "calculus-zero-power-is-exact"]

VerificationTest[Module[{x, y, s}, s = SeriesPower[AsymptoticInverse[2 x + x^2, {x, 0}, {y, 4}], 2, 4];
  Expand[Normal[s]] /. y -> \[FormalY]],
  \[FormalY]^2/4 - \[FormalY]^3/8, TestID -> "calculus-normalizes-scaled-inverse-coordinate"]

VerificationTest[Module[{x, y}, FailureQ[SeriesAdd[AsymptoticExpansion[x, {x, 0, 2}], AsymptoticExpansion[y, {y, 0, 2}]]]],
  True, TestID -> "calculus-rejects-incompatible-variables"]

VerificationTest[Module[{x}, FailureQ[SeriesMultiply[AsymptoticExpansion[x, {x, 0, 2}], 1.0]]],
  True, TestID -> "calculus-rejects-approximate-scalar"]

VerificationTest[Module[{x, s}, s = SeriesDifferentiate[AsymptoticExpansion[x + x^2, {x, 0, 2}]];
  {Normal[s], s["RemainderPower"]}],
  {1, 1}, TestID -> "calculus-known-finite-discarded-tail-is-differentiable"]

VerificationTest[Module[{x, s}, s = SeriesDifferentiate[AsymptoticExpansion[Sin[x], {x, 0, 3}], 1,
    "RemainderDerivativeOrder" -> 1]; FailureQ[SeriesRefine[s, 7]]],
  True, TestID -> "calculus-refinement-does-not-upgrade-a-declared-derivative-bound"]
