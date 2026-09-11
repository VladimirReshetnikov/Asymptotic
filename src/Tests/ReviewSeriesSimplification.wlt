(* Simplify and FullSimplify on result objects. An Association is atomic to
   the simplifiers, so a GeneralizedSeries used to be inert to them; the
   UpValues now simplify every coefficient-bearing field under the recorded
   assumptions together with any supplied ones, record the strengthened
   assumptions, and leave the remainder and the replay data alone. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
  Module[{x, b, s, positional, option},
    s = AsymptoticExpansion[Exp[x] + Abs[b] x^2, {x, 0, 3}, "Backend" -> "Package", Assumptions -> Element[b, Reals]];
    positional = FullSimplify[s, b > 0];
    option = FullSimplify[s, Assumptions -> b > 0];
    {Normal[s], Normal[positional], positional["Terms"], positional["Blocks"], positional["Remainder"] === s["Remainder"],
     positional["Assumptions"], option === positional, Simplify[s] === s, Expand[positional[1/2]]}],
  {1 + x + x^2 (1/2 + Abs[b]), 1 + x + (1/2 + b) x^2, {{0, 1}, {1, 1}, {2, 1/2 + b}}, {{0, 1}, {1, 1}, {2, 1/2 + b}}, True,
   Element[b, Reals] && b > 0, True, True, 13/8 + b/4} /. {x -> _Symbol, b -> _Symbol}, SameTest -> MatchQ,
  TestID -> "series-simplification-fullsimplify-reaches-coefficients-under-supplied-assumptions"]

VerificationTest[
  Module[{x, y, l, fl, r},
    l = Quiet[AsymptoticInverse[x + x Log[x], {x, Infinity}, {y, 3}], InverseFunction::ifun];
    fl = FullSimplify[l];
    r = SeriesRefine[fl, 4];
    {l["Terms"][[2]], fl["Terms"], fl["Remainder"] === l["Remainder"], Expand[fl["Blocks"]] === Expand[l["Blocks"]],
     Head[Normal[fl]] === Head[Normal[l]], MatchQ[r, _GeneralizedSeries] && r["RemainderPower"] === 4,
     TrueQ[Abs[N[Normal[fl] /. y -> 100, 30] - N[Normal[l] /. y -> 100, 30]] < 10^-25]}],
  {{1, -Log[(1 + Log[y])^(-1)]},
   {{0, 1}, {1, Log[1 + Log[y]]}, {2, (-1 + Log[1 + Log[y]]) Log[1 + Log[y]]}}, True, True, True, True, True} /. y -> _Symbol,
  SameTest -> MatchQ,
  TestID -> "series-simplification-logarithmic-inverse-keeps-remainder-shape-and-replay"]

VerificationTest[
  Module[{x, y, c, fc},
    c = AsymptoticExponentialCoreInverse[x Exp[x], 1, {x, Infinity}, {y, 2}];
    fc = FullSimplify[c];
    {MatchQ[fc, _GeneralizedSeries], fc["Remainder"] === c["Remainder"],
     TrueQ[Abs[N[Normal[fc] /. y -> 50, 30] - N[Normal[c] /. y -> 50, 30]] < 10^-25],
     ! FreeQ[Normal[fc], ProductLog]}],
  {True, True, True, True},
  TestID -> "series-simplification-productlog-coefficients-stay-equal-in-value"]

VerificationTest[
  Module[{x, c, n, fn},
    n = AsymptoticExpansion[(Sin[c]^2 + Cos[c]^2) Exp[x], {x, 0, 2}, "Backend" -> "Series"];
    fn = FullSimplify[n];
    {n["Kind"], Normal[fn], fn["NativeResult"][[3]], fn["Remainder"] === n["Remainder"]}],
  {"Native", 1 + x + x^2/2, {1, 1, 1/2}, True} /. x -> _Symbol,
  SameTest -> MatchQ,
  TestID -> "series-simplification-native-objects-simplify-their-coefficients"]

VerificationTest[
  Module[{x, b, s, t},
    s = AsymptoticExpansion[Exp[x] + Abs[b] x^2, {x, 0, 3}, "Backend" -> "Package", Assumptions -> Element[b, Reals]];
    t = FullSimplify[s, b > 0];
    {Normal[SeriesAdd[t, t]], Normal[SeriesMultiply[t, t]] === Normal[FullSimplify[SeriesMultiply[s, s], b > 0]],
     Normal[FullSimplify[s + 1, b > 0]]}],
  {2 + 2 x + (1 + 2 b) x^2, True, 2 + x + (1/2 + b) x^2} /. {x -> _Symbol, b -> _Symbol}, SameTest -> MatchQ,
  TestID -> "series-simplification-results-take-part-in-operations"]
