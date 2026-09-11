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
  (* Trimmed integer powers (P01) make x^3 at working cutoff 2 a pure O(x^3)
     remainder, so s - 1 = O(x^3): t is O(x^-1) and the vanishing product O(x^5),
     one power sharper than the O(x^2) the untrimmed engine reported. *)
  {t["Remainder"] === PowerLogRemainder[x, -1, 0], sine[[1]], sine[[2]]["EnvelopeLimit"], cosine[[1]],
   MatchQ[modulus, _GeneralizedSeries], modulus["Remainder"] === PowerLogRemainder[x, -1, 0],
   MatchQ[Sin[vanishing], _GeneralizedSeries], Sin[vanishing]["Remainder"] === PowerLogRemainder[x, 5, 0],
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

(* Report 62 CG-01: already-aligned operational conditions are not duplicated
   by zero-series addition, scalar-zero addition or unit multiplication;
   distinct parameter assumptions are kept and contradictory ones refused. *)
VerificationTest[
 Module[{x, a, b, s, z, chain, copies, scalarChain, unitChain, distinct, contradictory},
  s = AsymptoticExpansion[x, {x, 0, 3}, "Backend" -> "Package"];
  z = AsymptoticExpansion[0, {x, 0, 3}, "Backend" -> "Package"];
  copies[r_] := Count[r["TargetDomain"], HoldPattern[x > 0], {0, Infinity}];
  chain = NestList[SeriesAdd[#, z] &, s, 4];
  scalarChain = NestList[SeriesAdd[#, 0] &, s, 4];
  unitChain = NestList[SeriesMultiply[#, 1] &, s, 4];
  distinct = SeriesAdd[AsymptoticExpansion[a x, {x, 0, 3}, "Backend" -> "Package", Assumptions -> a > 0],
    AsymptoticExpansion[b x, {x, 0, 3}, "Backend" -> "Package", Assumptions -> b > 0]];
  contradictory = SeriesAdd[AsymptoticExpansion[a x, {x, 0, 3}, "Backend" -> "Package", Assumptions -> a > 0],
    AsymptoticExpansion[a x, {x, 0, 3}, "Backend" -> "Package", Assumptions -> a < 0]];
  {Union[copies /@ chain], Union[copies /@ scalarChain], Union[copies /@ unitChain],
   Union[Normal /@ Join[chain, scalarChain, unitChain]] === {x},
   LeafCount[Last[chain]["TargetDomain"]] <= 3,
   Simplify[Normal[distinct] - (a + b) x] === 0, distinct["Assumptions"] === (a > 0 && b > 0), distinct["TargetDomain"] === (x > 0),
   contradictory[[1]]}],
 {{1}, {1}, {1}, True, True, True, True, True, "IncompatibleDomains"},
 TestID -> "binary-arithmetic-keeps-one-copy-of-each-aligned-operational-condition"]

(* Report 63 F01/F02: the exact-rational certificate logarithm keeps relative
   precision just below one (reciprocal reduction) and for an exact affine
   argument near one (exact range passed to the logarithm), so the three
   public witnesses certify at enclosure order 2 without refinement. *)
VerificationTest[
 Module[{x, d = 2^-200, ctx = <|"SeriesOrder" -> 2, "Bits" -> 48, "ExponentMagnitudeLimit" -> 10000|>,
   below, affine, contained, fallback, product},
  below = AsymptoticAnalysis`Private`certLogPoint[1 - d, ctx];
  affine = AsymptoticAnalysis`Private`certLogExpression[1 + x, x, {d, d}, ctx];
  contained = Block[{$MaxExtraPrecision = 1000}, And @@ Table[With[{v = AsymptoticAnalysis`Private`certLogPoint[q, ctx]},
     v[[1]] <= N[Log[q], 300] <= v[[2]]], {q, {1/3, 999/1000, 1 - d, 1/1024, 1 + d, 7/5}}]];
  fallback = AsymptoticAnalysis`Private`certLogExpression[x^2 + x, x, {2, 2}, ctx];
  product = AsymptoticAnalysis`Private`certLogExpression[(x - 3) (x - 4), x, {1, 1}, ctx];
  {below[[2]] < 0, (below[[2]] - below[[1]])/d < 2^-44,
   affine[[1]] > 0, (affine[[2]] - affine[[1]])/d < 2^-44, contained,
   AsymptoticAnalysis`Private`certLogPoint[1, ctx],
   First[AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`certLogPoint[0, ctx]]],
   First[AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`certLogExpression[1 + x, x, {-2, -1}, ctx]]],
   fallback[[1]] <= N[Log[6], 100] <= fallback[[2]], product[[1]] <= N[Log[6], 100] <= product[[2]],
   AsymptoticAnalysis`Private`certLogExpression[(1 + x)/(1 + d), x, {d, d}, ctx]}],
 {True, True, True, True, True, {0, 0}, "IntervalDomain", "IntervalDomain", True, True, {0, 0}},
 TestID -> "certificate-logarithm-keeps-relative-precision-near-one"]

VerificationTest[
 Module[{x, y, d = 2^-200, a, b, c, summary},
  summary[r_, root_] := If[AssociationQ[r],
    {TrueQ[r["Certified"]], TrueQ[r["RootEnclosure"][[1]] <= root <= r["RootEnclosure"][[2]]],
     TrueQ[r["CertifiedErrorBound"] < d/8], r["EnclosureOrder"], r["Refinements"]},
    {r[[1]], r[[2]]["Reason"]}];
  a = AsymptoticInverse[Log[x], {x, 1}, {y, 3}, Direction -> "FromBelow"];
  b = AsymptoticInverse[Log[1 + x], {x, 0}, {y, 3}];
  c = AsymptoticInverse[Log[1 + x], {x, 0}, {y, 3}, Direction -> "FromBelow"];
  {summary[InverseCertificate[a, Log[1 - d], "Interval" -> {1 - 2 d, 1 - d/2}, "Center" -> 1 - d,
     "EnclosureOrder" -> 2, "MaxRefinements" -> 0], 1 - d],
   summary[InverseCertificate[b, Log[1 + d], "Interval" -> {d/2, 2 d}, "Center" -> d,
     "EnclosureOrder" -> 2, "MaxRefinements" -> 0], d],
   summary[InverseCertificate[c, Log[1 - d], "Interval" -> {-2 d, -d/2}, "Center" -> -d,
     "EnclosureOrder" -> 2, "MaxRefinements" -> 0], -d]}],
 {{True, True, True, 2, 0}, {True, True, True, 2, 0}, {True, True, True, 2, 0}},
 TestID -> "certificate-logarithmic-witnesses-certify-at-the-lowest-order-without-refinement"]

(* Report 64 N01 restates the component-validation defect of 59 N01 / 60 N01
   with an all-depth witness whose sum is exactly 1/x while the marker
   approximations alternate, and a family with a vanishing perturbation
   ratio; both are refused, the fixed-data controls are retained and an
   inexact operand keeps its own refusal. *)
VerificationTest[
 Module[{x, y, moving, small, positive, negative, zero, inexact},
  moving = Table[AsymptoticCoreInverse[1/x + Abs[y]/2, -Abs[y]/2, {x, 0}, {y, n}], {n, 0, 3}];
  small = AsymptoticCoreInverse[1/x + Sqrt[Abs[y]], -Sqrt[Abs[y]], {x, 0}, {y, 2}];
  positive = AsymptoticCoreInverse[1/x + 2, -2, {x, 0}, {y, 2}];
  negative = AsymptoticCoreInverse[1/x - 2, 2, {x, 0}, {y, 2}];
  zero = AsymptoticCoreInverse[1/x, 0, {x, 0}, {y, 2}];
  inexact = AsymptoticCoreInverse[1/x + 0.5, -0.5, {x, 0}, {y, 2}];
  {Union[First /@ moving], small[[1]], Head[positive], Simplify[Normal[positive] - (1/(y - 2) - 2/(y - 2)^2 + 4/(y - 2)^3)] === 0,
   Head[negative], Normal[zero] === 1/y, zero["Remainder"], inexact[[1]]}],
 {{"InvalidVariables"}, "InvalidVariables", GeneralizedSeries, True, GeneralizedSeries, True, 0, "InexactInput"},
 TestID -> "core-inverse-refuses-cancelling-target-dependent-operands-at-every-depth"]
