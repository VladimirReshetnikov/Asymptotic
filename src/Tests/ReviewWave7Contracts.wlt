(* Wave-7 repairs: complex omitted tails under composite sine/cosine bounds
   (report 56 N01), structural idempotence of joined conditions (56 N02), the
   affine constant above a nonpositive cutoff (57, pinned in the Dirichlet
   suite), the reflected Erfc frontier sign (58 G01), componentwise validation
   of core inverses (59 N01, 60), and exact-jet realness predicates (61 N01). *)

VerificationTest[
 Module[{x, a, s, t, vanishing, sine, cosine, modulus},
  s = AsymptoticExpansion[1/(1 - a x^3), {x, 0, 1}, Assumptions -> a^2 == -1, "Backend" -> "Package"];
  t = SeriesMultiply[SeriesAdd[s, -1], x^-4];
  vanishing = SeriesMultiply[SeriesAdd[s, -1], x^2];
  sine = Sin[t]; cosine = Cos[t]; modulus = Abs[t];
  {t["Remainder"] === PowerLogRemainder[x, -2, 0], sine[[1]], sine[[2]]["EnvelopeLimit"], cosine[[1]],
   MatchQ[modulus, _GeneralizedSeries], modulus["Remainder"] === PowerLogRemainder[x, -2, 0],
   MatchQ[Sin[vanishing], _GeneralizedSeries], Sin[vanishing]["Remainder"] === PowerLogRemainder[x, 4, 0],
   MatchQ[Sin[AsymptoticExpansion[x, {x, 0, 3}, "Backend" -> "Package"]], _GeneralizedSeries]}],
 {True, "UnprovedRealRemainder", Infinity, "UnprovedRealRemainder", True, True, True, True, True},
 TestID -> "composite-sine-and-cosine-require-a-vanishing-envelope-when-the-omitted-tail-may-be-complex"]

VerificationTest[
 Module[{x, b, one, accumulated, k},
  one = AsymptoticExpansion[1 + x, {x, 0, 2}, "Backend" -> "Package", Assumptions -> b > 0];
  accumulated = one;
  Do[accumulated = SeriesAdd[accumulated, accumulated], {5}];
  {accumulated["Assumptions"] === (b > 0), LeafCount[accumulated["TargetDomain"]] <= 3,
   Simplify[Normal[accumulated] - 32 (1 + x)] === 0,
   SeriesAdd[AsymptoticExpansion[x, {x, 0, 2}, "Backend" -> "Package", Assumptions -> b > 0],
     AsymptoticExpansion[x, {x, 0, 2}, "Backend" -> "Package", Assumptions -> b < 1]]["Assumptions"] === (b > 0 && b < 1)}],
 {True, True, True, True},
 TestID -> "binary-arithmetic-joins-conditions-idempotently"]

VerificationTest[
 Module[{x, y, reflected, direct},
  reflected = AsymptoticSpecialInverse["Erfc", {x, -Infinity}, {y, 1}];
  direct = AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 1}];
  {reflected["RemainderPower"], Simplify[reflected["FrontierTerm"] + (direct["FrontierTerm"] /. y -> 2 - y)] === 0,
   Simplify[Normal[reflected] + (Normal[direct] /. y -> 2 - y)] === 0,
   Simplify[(reflected["FrontierTerm"] /. y -> 2 - y)/direct["FrontierTerm"]] === -1}],
 {3/2, True, True, True},
 TestID -> "reflected-erfc-adapter-carries-the-source-sign-in-its-frontier-term"]

VerificationTest[
 Module[{x, y},
  {AsymptoticCoreInverse[x - Re[y], Re[y] + 1/x, {x, Infinity}, {y, 2}][[1]],
   AsymptoticCoreInverse[1/x - Re[y], Re[y] + x, {x, 0}, {y, 2}][[1]],
   AsymptoticCoreInverse[x + Abs[y]/2, -Abs[y]/2, {x, Infinity}, {y, 1}, "Power" -> 2][[1]],
   Normal[AsymptoticCoreInverse[x, 1/x, {x, Infinity}, {y, 2}]] === y - 1/y - 1/y^3}],
 {"InvalidVariables", "InvalidVariables", "InvalidVariables", True},
 TestID -> "core-inverse-validates-core-and-perturbation-separately"]

VerificationTest[
 Module[{x, z, a, s, m, results},
  s = AsymptoticExpansion[x, {x, 0, 3}, Assumptions -> a == I, "Backend" -> "Package"];
  results = Table[SeriesObservable[s, ConditionalExpression[1, Element[a (Exp[z] - Sum[z^k/k!, {k, 0, m}]), Reals]], z, "Cutoff" -> m + 1][[1]], {m, 0, 3}];
  {results, SeriesObservable[s, ConditionalExpression[1, Element[a z^2, Reals]], z][[1]],
   Normal[SeriesObservable[AsymptoticExpansion[1 + x, {x, 0, 3}, "Backend" -> "Package"],
     ConditionalExpression[Exp[z], Element[z^2, Reals]], z]] === E (1 + x + x^2/2)}],
 {{"IncompatibleObservableCondition", "IncompatibleObservableCondition", "IncompatibleObservableCondition", "IncompatibleObservableCondition"},
  "IncompatibleObservableCondition", True},
 TestID -> "membership-conditions-are-proved-only-on-exact-jets"]
