(* C08: recipe replay propagates an observed precision shortfall back into
   the operand demand, and a request the transported precision cannot meet
   is recorded as the achieved cutoff beside the request. W3-07: an exact
   derived value is refined without recomputing an uncertain ancestor. *)

VerificationTest[
 Module[{x, s, p, r, fresh},
  s = AsymptoticExpansion[Exp[x] - 1, {x, 0, 3}];
  p = SeriesPower[s, -10];
  r = SeriesRefine[p, 5];
  fresh = AsymptoticExpansion[(Exp[x] - 1)^-10, {x, 0, 5}];
  {p["RemainderPower"], r["Cutoff"], r["RemainderPower"], KeyExistsQ[r[[1]], "RequestedCutoff"],
   r["RefinementStatistics"]["ReplayRounds"], r["RefinementStatistics"]["RequestedCutoff"],
   Expand[Normal[r] - Normal[fresh]] === 0, fresh["RemainderPower"]}],
 {-8, 5, 5, False, 2, 5, True, 5},
 TestID -> "replay-propagates-the-precision-shortfall-of-a-negative-power-back-to-its-operand"]

VerificationTest[
 Module[{x, s, direct, deep},
  s = AsymptoticExpansion[Exp[x] - 1, {x, 0, 3}];
  direct = SeriesPower[s, -10, 5];
  deep = SeriesRefine[SeriesPower[AsymptoticInverse[x + x^2, {x, 0}, {\[FormalY], 3}, "InputRemainder" -> {3, 0}], -2], 6];
  {direct["Cutoff"], direct["RemainderPower"], direct["RequestedCutoff"],
   Head[deep], If[MatchQ[deep, _GeneralizedSeries], {deep["Cutoff"], deep["RemainderPower"], deep["RequestedCutoff"],
     deep["RefinementStatistics"]["AchievedCutoff"], deep["RefinementStatistics"]["ReplayRounds"]}, deep[[1]]]}],
 {-8, -8, 5, Failure, "InsufficientInputOrder"},
 TestID -> "a-request-the-transported-precision-cannot-meet-records-the-achieved-cutoff-beside-the-request"]

VerificationTest[
 Module[{x, y, inv, zero, sum, refined, refinedSum, low},
  inv = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}, "InputRemainder" -> {3, 0}];
  zero = SeriesMultiply[inv, 0];
  sum = SeriesAdd[SeriesMultiply[inv, 0], 5];
  refined = SeriesRefine[zero, 10];
  refinedSum = SeriesRefine[sum, 12];
  low = SeriesRefine[sum, 2];
  {zero["Remainder"], Normal[refined], refined["Remainder"], refined["Cutoff"],
   refined["RefinementStatistics"]["Strategy"], refined["RefinementStatistics"]["NewCoefficientEvaluations"],
   Normal[refinedSum], refinedSum["Cutoff"], refinedSum["Assumptions"] === sum["Assumptions"],
   refinedSum["TargetDomain"] === sum["TargetDomain"], Length[refinedSum["RefinementHistory"]],
   Head[low], Normal[low], low["Cutoff"]}],
 {0, 0, 0, 10, "ExactDerivedValue", 0, 5, 12, True, True, 1, GeneralizedSeries, 5, 2},
 TestID -> "an-exact-derived-value-is-refined-without-recomputing-an-uncertain-ancestor"]
