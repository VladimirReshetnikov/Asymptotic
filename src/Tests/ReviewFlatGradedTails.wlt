(* C23: flat products select the dominant omitted-tail candidate by
   exponential grade before weakening it to the schema's sector N+1. *)

VerificationTest[
 Module[{x, y, s, a},
  Table[s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, n}]; a = FlatSeriesMultiply[s, s];
   {a["SectorDepth"], Cases[a["SectorRemainder"], PowerLogRemainder[_, p_, d_] :> {p, d}, Infinity],
    a["SectorTailGrade"], a["Terms"] === Take[{{0, y^2}, {1, -2 y}, {2, 1 + 2/y}, {3, -3/y^3}}, n + 1],
    a["InnerRemainders"]}, {n, 1, 3}]],
 {{1, {{-1, 0}}, 2, True, {}}, {2, {{-3, 0}}, 3, True, {}}, {3, {{-5, 0}}, 4, True, {}}},
 TestID -> "flat-square-tail-keeps-the-first-omitted-sector-instead-of-the-tail-product-pole"]

VerificationTest[
 Module[{x, y, s1, s3, m},
  s1 = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 1}];
  s3 = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 3}];
  m = FlatSeriesMultiply[s1, s3];
  {m["SectorDepth"], Cases[m["SectorRemainder"], PowerLogRemainder[_, p_, d_] :> {p, d}, Infinity],
   m["SectorTailGrade"], m["Terms"] === FlatSeriesMultiply[s3, s1]["Terms"],
   Cases[FlatSeriesMultiply[s3, s1]["SectorRemainder"], PowerLogRemainder[_, p_, d_] :> p, Infinity]}],
 {1, {{-1, 0}}, 2, True, {-1}},
 TestID -> "flat-product-of-unequal-depths-is-graded-and-symmetric"]

VerificationTest[
 Module[{x, y, s3, t, mt},
  s3 = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 3}];
  t = FlatSeriesTruncate[s3, -3]; mt = FlatSeriesMultiply[t, t];
  {t["InnerRemainders"][[All, 1]], Cases[mt["SectorRemainder"], PowerLogRemainder[_, p_, _] :> p, Infinity],
   mt["InnerRemainders"][[All, 1]], mt["SectorTailGrade"],
   Cases[mt["InnerRemainders"], PowerLogRemainder[_, p_, _] :> p, Infinity]}],
 {{1, 2, 3}, {-5}, {1, 2, 3}, 4, {1, -1, -2}},
 TestID -> "flat-product-with-pure-unknown-inner-coefficients-keeps-them-in-their-sectors"]

VerificationTest[
 Module[{x, y, s, sq, zero, scaled},
  s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 1}];
  sq = FlatSeriesMultiply[s, s]; zero = FlatSeriesMultiply[s, 0]; scaled = FlatSeriesMultiply[s, y];
  {zero["Remainder"], zero["Exact"], zero["SectorTailGrade"],
   Cases[scaled["SectorRemainder"], PowerLogRemainder[_, p_, _] :> p, Infinity], scaled["SectorTailGrade"],
   Cases[FlatSeriesMultiply[sq, sq]["SectorRemainder"], PowerLogRemainder[_, p_, _] :> p, Infinity],
   FlatSeriesMultiply[sq, sq]["SectorTailGrade"],
   Cases[FlatSeriesObservable[s, z^2 + z, z]["SectorRemainder"], PowerLogRemainder[_, p_, _] :> p, Infinity],
   Cases[FlatSeriesDifferentiate[sq]["SectorRemainder"], PowerLogRemainder[_, p_, _] :> p, Infinity],
   sq["FlatRepresentation"]["DerivativeContract"] === AsymptoticAnalysis`Private`flatOpsData[s, 1000]["DerivativeContract"],
   FlatSeriesMultiply[sq, sq]["FlatRepresentation"]["DerivativeContract"] === sq["FlatRepresentation"]["DerivativeContract"]}],
 {0, True, Infinity, {-1}, 2, {1}, 2, {-2}, {-3}, True, True},
 TestID -> "flat-exact-zero-annihilates-and-grades-propagate-through-scalar-product-observable-and-derivative"]

VerificationTest[
 AsymptoticAnalysis`Private`flatOpsGradedTail[{{4, {-4, 0}}, {2, {-1, 0}}, {2, {-1, 2}}, {3, {-10, 0}}, {2, {Infinity, 0}}, {Infinity, {-20, 0}}}],
 {{-1, 2}, 2},
 TestID -> "flat-graded-tail-selects-the-least-sector-then-power-log-dominance-and-ignores-exact-zeros"]
