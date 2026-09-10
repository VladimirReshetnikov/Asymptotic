(* Review regressions: precision transport, leading-term discovery, exact input,
   and the positive local coordinate of the selected real branch. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x + x^2, {x, 0}, {y, 2},
      "Power" -> -1, "InputRemainder" -> {3, 0}];
    FailureQ[s]],
  True, TestID -> "review-reciprocal-observable-input-precision"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x + x^2, {x, 0}, {y, 4},
      "Power" -> 2, "InputRemainder" -> {3, 0}];
    {Expand[Normal[s]], s["RemainderPower"]} /. y -> \[FormalY]],
  {\[FormalY]^2 - 2 \[FormalY]^3, 4},
  TestID -> "review-square-observable-input-precision"]

VerificationTest[
  Module[{x, y}, FailureQ[AsymptoticInverse[x + 1/x, {x, Infinity}, {y, 4},
    "InputRemainder" -> {3, 0}]]],
  True, TestID -> "review-infinity-input-precision"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[Sin[x^3], {x, 0}, {y, 1}];
    TrueQ[FullSimplify[Normal[s] == y^(1/3), y > 0]]],
  True, TestID -> "review-inverse-leading-term-beyond-initial-order"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[1 + Sin[x^3], {x, 0}, {y, 1}];
    TrueQ[FullSimplify[Normal[s] == (y - 1)^(1/3), y > 1]]],
  True, TestID -> "review-inverse-leading-term-after-constant-limit"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x - Sin[x], {x, 0}, {y, 1}];
    TrueQ[FullSimplify[Normal[s] == (6 y)^(1/3), y > 0]]],
  True, TestID -> "review-inverse-leading-term-after-cancellation"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[-1/x + x, {x, 0}, {y, 3}];
    s["RemainderVariable"] /. y -> \[FormalY]],
  -1/\[FormalY], TestID -> "review-negative-infinite-target-coordinate"]

VerificationTest[
  Module[{y},
    AsymptoticAnalysis`Private`remainderScale[PowerLogRemainder[-y, 3/2, 1]] /. y -> -4],
  8 (1 + Log[4]), TestID -> "review-negative-target-remainder-rendering-scale"]

VerificationTest[
  Module[{x}, FailureQ[AsymptoticExpansion[1.5 x + x^2, {x, 0, 3}, "Backend" -> "Package"]]],
  True, TestID -> "review-forward-rejects-inexact-coefficients"]

VerificationTest[
  Module[{x, s, native},
    native = Series[1.5 x + x^2, {x, 0, 3}];
    s = AsymptoticExpansion[1.5 x + x^2, {x, 0, 3}];
    MatchQ[s, _GeneralizedSeries] && s["Kind"] === "Native" &&
      s["NativeResult"] === native && Normal[s] === Normal[native]],
  True, TestID -> "review-automatic-inexact-forward-preserves-native-series-result"]

VerificationTest[
  Module[{x, y}, FailureQ[AsymptoticInverse[1.5 x + x^2, {x, 0}, {y, 3}]]],
  True, TestID -> "review-inverse-rejects-inexact-coefficients"]

VerificationTest[
  Module[{x}, FailureQ[PowerLogModel[1.5 x + x^2, {x, 0}]]],
  True, TestID -> "review-model-rejects-inexact-coefficients"]

VerificationTest[
  Module[{x}, FailureQ[AsymptoticExpansion[x + x^2, {x, 0, 3}, "MaxTerms" -> 0]]],
  True, TestID -> "review-forward-validates-resource-budget"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[x^2, {x, 0}, y, SeriesTermGoal -> 1];
    FailureQ[InverseNumericalCheck[s, -1]]],
  True, TestID -> "review-numerical-check-rejects-complex-root"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[0, {x, 0, 3}];
    {Normal[s], s["Remainder"], s["Exact"]}],
  {0, 0, True}, TestID -> "review-forward-exact-zero"]

VerificationTest[
  Module[{x, y, alpha, beta, s},
    s = AsymptoticInverse[1 + x^alpha + x^beta, {x, 0}, {y, 1},
      "Truncation" -> "Depth", Assumptions -> alpha > beta > 0];
    {s["LeadingPower"] === beta, s["Limit"]}],
  {True, 1}, TestID -> "review-depth-leading-power-after-constant"]

VerificationTest[
  Module[{x, y, alpha},
    {FailureQ[AsymptoticInverse[x^I, {x, 0}, {y, 1}, "Truncation" -> "Depth"]],
     FailureQ[AsymptoticInverse[x^alpha, {x, 0}, {y, 1}, "Truncation" -> "Depth",
       Assumptions -> Element[alpha, Reals] && alpha != 0]]}],
  {True, True}, TestID -> "review-depth-requires-real-leading-power-with-known-sign"]

VerificationTest[
  Module[{x, y},
    FailureQ[AsymptoticInverse[x + x^2, {x, 0}, {y, 1},
      "Truncation" -> "Depth", "InputRemainder" -> {3, 0}]]],
  True, TestID -> "review-depth-rejects-untransported-input-remainder"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[Sin[x] + x^3 Log[x]^10, {x, 0, 2}];
    {Normal[s], s["RemainderPower"], s["RemainderLogDegree"]} /. x -> \[FormalX]],
  {\[FormalX], 3, 10}, TestID -> "review-addition-preserves-log-degree-at-precision-boundary"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[Sin[x^2] (1 + x^3 Log[x]^10), {x, 0, 4}];
    {Normal[s], s["RemainderPower"], s["RemainderLogDegree"]} /. x -> \[FormalX]],
  {\[FormalX]^2, 5, 10}, TestID -> "review-multiplication-preserves-log-degree-at-precision-boundary"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[1/(Exp[x^5] - 1), {x, 0, 2}];
    TrueQ[FullSimplify[Normal[s] == x^-5 - 1/2, x > 0]] &&
      TrueQ[s["RemainderPower"] >= 2]],
  True, TestID -> "review-forward-retries-hidden-reciprocal-leading-term"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[1/(Exp[x^5] - 1), {x, 0}, {y, 1}];
    TrueQ[FullSimplify[Normal[s] == y^(-1/5), y > 0]]],
  True, TestID -> "review-inverse-retries-hidden-reciprocal-leading-term"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticExpansion[Cot[Sin[x^5]], {x, 0, 2}];
    TrueQ[FullSimplify[Normal[s] == x^-5, x > 0]] &&
      TrueQ[s["RemainderPower"] >= 2]],
  True, TestID -> "review-forward-retries-hidden-analytic-pole"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[(Sqrt[1 + 4 x] - 1)/2, {x, 0}, y, SeriesTermGoal -> 3];
    {TrueQ[FullSimplify[Normal[s] == y + y^2]], s["Remainder"],
      s["RequestedTermGoal"], s["ReturnedTermCount"], s["ExactModel"],
      s["ExactTerminationCertificate"]["Verified"]}],
  {True, 0, 3, 2, False, True}, TestID -> "review-terminating-inverse-of-nonpolynomial-forward"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[Sqrt[x] + 1, {x, Infinity}, y, SeriesTermGoal -> 4];
    {TrueQ[FullSimplify[Normal[s] == (y - 1)^2]], s["Remainder"],
      s["ReturnedTermCount"], s["ExactTerminationCertificate"]["Verified"]}],
  {True, 0, 3, True}, TestID -> "review-terminating-inverse-at-infinity"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticInverse[(Sqrt[1 + 4 x] - 1)/2 + x^3, {x, 0}, y, SeriesTermGoal -> 3];
    {TrueQ[FullSimplify[Normal[s] == y + y^2 - y^3]], s["Remainder"] =!= 0,
      s["ExactTerminationCertificate"]}],
  {True, True, None}, TestID -> "review-termination-requires-original-function-identity"]
