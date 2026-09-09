(* Focused regressions for native asymptotic ingress. The expected Erfc
   coefficients follow from integration by parts, and the half-integer
   Bessel formula is exact. Native Series is not an expected-value oracle.
   The two private-helper tests exercise error and coefficient admission
   contracts directly, independently of which native AST a kernel emits. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

nativeIngressEqual[s_, expected_, x_] := MatchQ[s, _GeneralizedSeries] &&
  TrueQ[FullSimplify[Normal[s] == expected, x > 0]];

nativeIngressErrorAtScale[s_, scale_, x_] := Module[{bound, ratio},
  If[! MatchQ[s, _GeneralizedSeries] || s["Remainder"] === 0, Return[False, Module]];
  bound = s["Remainder"] /.
    PowerLogRemainder[w_, p_, d_] :> w^p (1 + Abs[Log[w]])^d;
  ratio = FullSimplify[bound/scale, x > 0];
  FreeQ[ratio, x] && TrueQ[FullSimplify[ratio > 0]]];

VerificationTest[Module[{x},
  FailureQ[AsymptoticExpansion[BesselJ[0, x], {x, 0, 4},
    SeriesTermGoal -> #]] & /@ {-1, 0, 1/2, False}],
  {True, True, True, True},
  TestID -> "native-ingress-explicit-cutoff-still-rejects-invalid-term-goals"]

VerificationTest[Module[{x, s, tail},
  tail = Exp[-x^2]/(Sqrt[Pi] x) (1 - 1/(2 x^2) + 3/(4 x^4));
  s = AsymptoticExpansion[Exp[x] + Erfc[x], x -> Infinity, SeriesTermGoal -> 3];
  {nativeIngressEqual[s, Exp[x] + tail, x],
    nativeIngressErrorAtScale[s, Exp[-x^2]/x^7, x]}],
  {True, True},
  TestID -> "native-ingress-exact-exponential-summand-does-not-exhaust-term-goal-loop"]

VerificationTest[Module[{x, s, tail},
  tail = Exp[-x^2]/(Sqrt[Pi] x) (1 - 1/(2 x^2) + 3/(4 x^4));
  s = AsymptoticExpansion[x + Erfc[x], x -> Infinity, SeriesTermGoal -> 3];
  {nativeIngressEqual[s, x + tail, x],
    nativeIngressErrorAtScale[s, Exp[-x^2]/x^7, x]}],
  {True, True},
  TestID -> "native-ingress-exact-laurent-summand-does-not-exhaust-term-goal-loop"]

VerificationTest[Module[{x, s, expected},
  expected = 1 + Exp[-x^2]/(Sqrt[Pi] x^21)
    (1 - 1/(2 x^2) + 3/(4 x^4));
  s = AsymptoticExpansion[1 + x^-20 Erfc[x], x -> Infinity, SeriesTermGoal -> 3];
  {nativeIngressEqual[s, expected, x],
    nativeIngressErrorAtScale[s, Exp[-x^2]/x^27, x]}],
  {True, True},
  TestID -> "native-ingress-constant-offset-cannot-hide-unresolved-scaled-tail"]

VerificationTest[Module[{u, unknown, expressions},
  expressions = {1/(1 + Sin[1/u]), Log[1 + Sin[1/u]], unknown[Sin[1/u]]};
  FailureQ[AsymptoticInverse`Private`catch[
    AsymptoticInverse`Private`specialNativeCoefficientDegree[#, u, True]]] & /@ expressions],
  {True, True, True},
  TestID -> "native-ingress-rejects-unbounded-or-unknown-functions-of-bounded-modes"]

VerificationTest[Module[{u, a},
  {AsymptoticInverse`Private`specialNativeCoefficientDegree[
      Log[u]^2 (1 + Sin[1/u])^3 + Cos[1/u^2], u, True],
    FailureQ[AsymptoticInverse`Private`catch[
      AsymptoticInverse`Private`specialNativeCoefficientDegree[Sin[a/u], u, True]]]}],
  {2, True},
  TestID -> "native-ingress-bounded-polynomial-modes-need-proved-real-phases"]

VerificationTest[Module[{u, data, bound},
  (* The first omitted term of Exp[u Log[u]] is u^3 Log[u]^3/6.
     A tail carrying only the retained maximum logarithmic degree 2 would
     not bound that term at power 3. A strict power margin does. *)
  data = AsymptoticInverse`Private`specialNativeTree[
    SeriesData[u, 0, {1, Log[u], Log[u]^2/2}, 0, 3, 1], u, True, 20000];
  bound = data[[2]] /.
    PowerLogRemainder[w_, p_, d_] :> w^p (1 + Abs[Log[w]])^d;
  {Expand[data[[1]] - (1 + u Log[u] + u^2 Log[u]^2/2)] === 0,
    Limit[u^3 Log[u]^3/bound, u -> 0, Direction -> "FromAbove"] === 0,
    Limit[bound/u^2, u -> 0, Direction -> "FromAbove"] === 0}],
  {True, True, True},
  TestID -> "native-ingress-native-tail-absorbs-unrecorded-next-logarithmic-degree"]

VerificationTest[Module[{u, data, bound},
  (* The next term on this half-integer lattice is u^(3/2) Log[u]^3/6.
     Use a complete three-coefficient jet: native evaluation increases the
     requested numerator 2 to 3 for {1,Log[u]} on a denominator-2 lattice. *)
  data = AsymptoticInverse`Private`specialNativeTree[
    SeriesData[u, 0, {1, Log[u], Log[u]^2/2}, 0, 3, 2], u, True, 20000];
  bound = data[[2]] /.
    PowerLogRemainder[w_, p_, d_] :> w^p (1 + Abs[Log[w]])^d;
  {Expand[data[[1]] - (1 + Sqrt[u] Log[u] + u Log[u]^2/2)] === 0,
    Limit[u^(3/2) Log[u]^3/bound, u -> 0, Direction -> "FromAbove"] === 0,
    Limit[bound/u, u -> 0, Direction -> "FromAbove"] === 0}],
  {True, True, True},
  TestID -> "native-ingress-native-tail-margin-respects-puiseux-lattice"]

VerificationTest[Module[{x, s, expected},
  expected = ((1 - 1/x) Exp[x] + (1 + 1/x) Exp[-x])/Sqrt[2 Pi x];
  s = AsymptoticExpansion[BesselI[3/2, x], x -> Infinity, SeriesTermGoal -> 3];
  {nativeIngressEqual[s, expected, x],
    MatchQ[s, _GeneralizedSeries] && s["Remainder"] === 0}],
  {True, True},
  TestID -> "native-ingress-exact-half-integer-bessel-retains-subdominant-exponential"]
