(* W3-10: Log[u^k] may be replaced by k Log[u] on the positive
   local coordinate only after k has been proved real. The exponent may
   have either sign. These checks separate finite-model admission from
   explicitly requested native complex/formal expansion. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

reviewLogPowerEqual[a_, b_, ass_: True] := Block[{$Assumptions = True},
  TrueQ[FullSimplify[a == b, Assumptions -> ass]]];
reviewLogPowerParsed[e_, u_Symbol, ell_Symbol, ass_] := Block[{$Assumptions = True},
  Module[{rows = AsymptoticAnalysis`Private`parseFinite[e, u, ell, ass]},
    If[rows === $Failed, $Failed,
      Total[(u^#[[1]] #[[2]]) & /@ rows] /. ell -> Log[u]]]];

VerificationTest[
  Module[{u, ell, a, inputs},
    inputs = {u + u^2 Log[u^a]^2,
      u + u^2 Log[2 u^a]^2,
      u + u^2 (Log[2 u^a] + Log[u^a/2])^2/4,
      u + u^2 Log[(u^a)^2]^2};
    And @@ (reviewLogPowerParsed[#, u, ell, a^2 == -1] === $Failed & /@ inputs)],
  True, TestID -> "review-log-power-parser-preserves-complex-principal-log-winding"]

VerificationTest[
  Module[{u, ell, a},
    {reviewLogPowerParsed[u + u^2 Log[u^a]^2, u, ell, True],
      reviewLogPowerParsed[u + u^2 Log[2 u^a]^2, u, ell, True]}],
  {$Failed, $Failed},
  TestID -> "review-log-power-parser-does-not-assume-undeclared-exponents-real"]

VerificationTest[
  Module[{u, ell, k},
    And @@ Table[
      reviewLogPowerEqual[
        reviewLogPowerParsed[u + u^2 Log[u^k]^2, u, ell, True],
        u + k^2 u^2 Log[u]^2, u > 0],
      {k, {2, -3, 0, 1/2, -Sqrt[2], Sqrt[2]}}]],
  True, TestID -> "review-log-power-parser-keeps-integer-rational-irrational-and-zero-exponents"]

VerificationTest[
  Module[{u, ell, a, ass},
    And @@ Table[
      reviewLogPowerEqual[
        reviewLogPowerParsed[u + u^2 Log[u^a]^2, u, ell, ass],
        u + a^2 u^2 Log[u]^2, ass && u > 0],
      {ass, {Element[a, Reals], a < 0, a > 0}}]],
  True, TestID -> "review-log-power-parser-requires-reality-without-requiring-positive-exponent"]

VerificationTest[
  Module[{u, ell, a, c, ass},
    ass = c > 0 && Element[a, Reals];
    reviewLogPowerEqual[
      reviewLogPowerParsed[u + u^2 Log[c u^a]^2, u, ell, ass],
      u + u^2 (Log[c] + a Log[u])^2, ass && u > 0]],
  True, TestID -> "review-log-power-parser-retains-positive-symbolic-scale-identity"]

VerificationTest[
  Module[{u, ell, c},
    {reviewLogPowerParsed[u + u^2 Log[c u^2]^2, u, ell, c < 0],
      reviewLogPowerParsed[u + u^2 Log[c u^2]^2, u, ell, Element[c, Reals]]}],
  {$Failed, $Failed},
  TestID -> "review-log-power-parser-still-requires-positive-scale"]

VerificationTest[
  Module[{x, y, a, s},
    s = AsymptoticInverse[x + x^2 Log[x^a]^2, {x, 0}, {y, 1},
      "Truncation" -> "Depth", Assumptions -> a^2 == -1];
    MatchQ[s, Failure["UnsupportedInput", _Association]]],
  True, TestID -> "review-log-power-depth-inverse-rejects-real-winding-source"]

VerificationTest[
  Module[{x, y, a, s},
    (* The two real radial constants cancel before squaring, so this is
       a real winding source, unlike a single squared scaled logarithm. *)
    s = AsymptoticInverse[
      x + x^2 (Log[2 x^a] + Log[x^a/2])^2/4, {x, 0}, {y, 1},
      "Truncation" -> "Depth", Assumptions -> a^2 == -1];
    MatchQ[s, Failure["UnsupportedInput", _Association]]],
  True, TestID -> "review-log-power-depth-inverse-rejects-paired-scaled-real-winding-source"]

VerificationTest[
  Module[{x, y, a, s},
    s = AsymptoticCoreInverse[x, x^2 Log[x^a]^2, {x, 0}, {y, 1},
      Assumptions -> a^2 == -1];
    MatchQ[s, Failure["UnsupportedCorePerturbation", _Association]]],
  True, TestID -> "review-log-power-core-perturbation-requires-a-valid-finite-power-log-model"]

VerificationTest[
  Module[{x, y, a, s, coefficients},
    s = AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 1},
      Assumptions -> a^2 == -1];
    coefficients = {Log[y^a]^2, (Log[2 y^a] + Log[y^a/2])^2/4};
    MatchQ[s, _GeneralizedSeries] &&
      And @@ (MatchQ[FlatSeriesMultiply[s, #],
        Failure["UnsupportedFlatCoefficient", _Association]] & /@ coefficients)],
  True, TestID -> "review-log-power-flat-scalar-rejects-unscaled-and-paired-scaled-winding"]

VerificationTest[
  Module[{x, y, a, s},
    s = AsymptoticInverse[x + x^2 Log[x^a]^2, {x, 0}, {y, 1},
      "Truncation" -> "Depth", Assumptions -> a < 0];
    MatchQ[s, _GeneralizedSeries] &&
      reviewLogPowerEqual[Normal[s], y - a^2 y^2 Log[y]^2, a < 0 && y > 0] &&
      {s["RemainderPower"], s["RemainderLogDegree"]} === {3, 4}],
  True, TestID -> "review-log-power-negative-real-exponent-keeps-depth-coefficient-and-frontier"]

VerificationTest[
  Module[{x, y, a, c, ass, s},
    ass = c > 0 && Element[a, Reals];
    s = AsymptoticInverse[x + x^2 Log[c x^a]^2, {x, 0}, {y, 1},
      "Truncation" -> "Depth", Assumptions -> ass];
    MatchQ[s, _GeneralizedSeries] && reviewLogPowerEqual[Normal[s],
      y - y^2 (Log[c] + a Log[y])^2, ass && y > 0]],
  True, TestID -> "review-log-power-real-scaled-depth-inverse-has-independent-first-correction"]

VerificationTest[
  Module[{x, y, a, zero, cancelled},
    zero = AsymptoticInverse[x + x^2 Log[x^0]^2, {x, 0}, {y, 1},
      "Truncation" -> "Depth"];
    cancelled = AsymptoticInverse[
      x + x^2 (Log[x^a]^2 - Log[x^a]^2), {x, 0}, {y, 1},
      "Truncation" -> "Depth", Assumptions -> a^2 == -1];
    And @@ (MatchQ[#, _GeneralizedSeries] && Normal[#] === y &&
      #["Remainder"] === 0 & /@ {zero, cancelled})],
  True, TestID -> "review-log-power-zero-exponent-and-exact-cancellation-remain-exact"]

VerificationTest[
  Module[{x, y, a, s, refined, oracle},
    s = Assuming[a < 0, AsymptoticInverse[x + x^2 Log[x^a]^2,
      {x, 0}, {y, 1}, "Truncation" -> "Depth"]];
    refined = Assuming[a^2 == -1, SeriesRefine[s, 2]];
    (* Lagrange inversion: -p(y), then p(y) p'(y), for
       p(y)=a^2 y^2 Log[y]^2. *)
    oracle = y - a^2 y^2 Log[y]^2 +
      2 a^4 y^3 (Log[y]^4 + Log[y]^3);
    MatchQ[refined, _GeneralizedSeries] &&
      reviewLogPowerEqual[Normal[refined], oracle, a < 0 && y > 0] &&
      Block[{$Assumptions = True},
        TrueQ[FullSimplify[Equivalent[refined["Assumptions"], a < 0]]]]],
  True, TestID -> "review-log-power-depth-refinement-uses-stored-realness-under-conflicting-ambient"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticCoreInverse[x, x^2 Log[x^-2]^2, {x, 0}, {y, 1}];
    MatchQ[s, _GeneralizedSeries] &&
      reviewLogPowerEqual[Normal[s], y - 4 y^2 Log[y]^2, y > 0]],
  True, TestID -> "review-log-power-core-keeps-negative-real-exponent-correction"]

VerificationTest[
  Module[{x, y, a, s, product},
    s = Assuming[a < 0,
      AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 1}]];
    product = Assuming[a^2 == -1, FlatSeriesMultiply[s, Log[y^a]^2]];
    MatchQ[product, _GeneralizedSeries] && reviewLogPowerEqual[Normal[product],
      a^2 Log[y]^2 (y - y^2 Exp[-1/y]), a < 0 && y > 0]],
  True, TestID -> "review-log-power-flat-scalar-uses-stored-real-exponent-assumptions"]

VerificationTest[
  Module[{x, y, a, s},
    s = AsymptoticInverse[x + Log[x^a]^2/x, {x, Infinity}, {y, 1},
      "Truncation" -> "Depth", Assumptions -> Element[a, Reals]];
    MatchQ[s, _GeneralizedSeries] && reviewLogPowerEqual[Normal[s],
      y - a^2 Log[y]^2/y, Element[a, Reals] && y > 0]],
  True, TestID -> "review-log-power-infinity-coordinate-preserves-real-exponent-sign-change"]

VerificationTest[
  Module[{u, ell, a, b, c, ass},
    ass = Element[{a, b}, Reals] && c > 0;
    reviewLogPowerEqual[
      reviewLogPowerParsed[u + u^2 Log[(c (1/u)^a)^b]^2, u, ell, ass],
      u + b^2 u^2 (Log[c] - a Log[u])^2, ass && u > 0]],
  True, TestID -> "review-log-power-recurses-through-positive-scaled-real-power-trees"]

VerificationTest[
  Module[{u, ell, a, b},
    And @@ (reviewLogPowerParsed[#, u, ell, a^2 == -1 && Element[b, Reals]] === $Failed & /@
      {u + u^2 Log[(1/u)^a]^2, u + u^2 Log[(u^a)^b]^2,
       u + u^2 Log[(-u)^b]^2})],
  True, TestID -> "review-log-power-recursion-does-not-rescue-complex-or-negative-inner-bases"]

VerificationTest[
  Module[{x, y, a, s},
    s = AsymptoticFlatInverse[x + x^2 Exp[-1/x + Log[x^a]^2 - a^2 Log[x]^2],
      {x, 0}, {y, 1}, Assumptions -> a^2 == -1];
    MatchQ[s, Failure["UnsupportedFlatPhase", _Association]]],
  True, TestID -> "review-log-power-flat-phase-cannot-manufacture-monomial-by-erasing-winding"]

VerificationTest[
  Module[{x, a, native, s},
    native = Series[Log[x^a], {x, 1, 2}, Assumptions -> a^2 == -1];
    s = AsymptoticExpansion[Log[x^a], {x, 1, 2},
      "Backend" -> "Series", Assumptions -> a^2 == -1];
    MatchQ[s, _GeneralizedSeries] && s["Kind"] === "Native" &&
      s["NativeResult"] === native && Normal[s] === Normal[native]],
  True, TestID -> "review-log-power-explicit-native-complex-expansion-retains-native-semantics"]
