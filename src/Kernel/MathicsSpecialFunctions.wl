(* Mathics does not implement the large-positive-argument LogGamma Series
   used by the Wolfram path. Use the classical finite Stirling model in the
   existing jet algebra. This is a Poincare expansion with an explicit tail,
   never an exact or convergent power series. DLMF 5.11.1 and 5.11(ii). *)

mathicsGrowingPositiveJetQ[rows_List, ell_, ass_] := rows =!= {} &&
  less[rows[[1, 1]], 0] && FreeQ[rows[[1, 2]], ell] &&
  provablyPositive[rows[[1, 2]], ass];

(* Mathics can evaluate an existing general definition while installing a
   more specific left-hand side. Temporarily retain the rules as held data. *)
$mathicsOriginalFwdAnalytic = DownValues[fwdAnalytic];
DownValues[fwdAnalytic] = {};
fwdAnalytic[LogGamma, {rows_List, precision_, degree_}, e_, u_, ell_, ass_, cutoff_, limit_] /;
    mathicsGrowingPositiveJetQ[rows, ell, ass] := Module[
  {argument = First[e], rate = -rows[[1, 1]], count, model, result},
  If[cutoff === Infinity,
    fail["InfiniteSeries", "The Gamma logarithm requires a finite Poincare working order."]];
  count = Max[0, Ceiling[(cutoff/rate + 1)/2] - 1];
  If[count + 1 > limit,
    fail["ResourceLimit", "The Stirling Bernoulli tail exceeds MaxTerms."]];
  model = (argument - 1/2) Log[argument] - argument + Log[2 Pi]/2 +
    Total[Table[BernoulliB[2 k]/(2 k (2 k - 1) argument^(2 k - 1)), {k, 1, count}]];
  result = fwd[model, u, ell, ass, cutoff, limit];
  pAdd[result, {{}, (2 count + 1) rate, 0}, ell, ass]];
DownValues[fwdAnalytic] = Join[DownValues[fwdAnalytic], $mathicsOriginalFwdAnalytic];
