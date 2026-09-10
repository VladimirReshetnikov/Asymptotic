(* Independent exact-rational reference; no AsymptoticAnalysis definitions
   or System definitions are changed. Wolfram 15 reference controls were
   executed; Mathics execution has not been performed. *)
BeginPackage["AsymptoticAudit`"];
NegativeLerchInterval::usage =
  "NegativeLerchInterval[q,s,a,k] gives exact rational lower/upper bounds for LerchPhi[-q,s,a], for rational 0<=q<=1, positive integer s, rational a>0, and integer 0<=k<=256.";
Begin["`Private`"];
ClearAll[rationalQ];
rationalQ[v_] := IntegerQ[v] || Head[v] === Rational;
NegativeLerchInterval[q_, s_, a_, k_] := Module[
  {row, d = {}, j, r, partial, tail, lower, upper},
  If[! rationalQ[q] || ! rationalQ[a] || ! IntegerQ[s] ||
      ! IntegerQ[k] || ! TrueQ[0 <= q <= 1 && a > 0 &&
        1 <= s <= 1000 && 0 <= k <= 256],
    Return[Failure["InvalidArguments", <|"MessageTemplate" ->
      "Require rational 0<=q<=1, rational a>0, integer 1<=s<=1000, and integer 0<=k<=256."|>]]];
  row = Table[1/(a + j)^s, {j, 0, k}];
  Do[AppendTo[d, First[row]]; row = Most[row] - Rest[row], {j, 0, k - 1}];
  AppendTo[d, First[row]];
  r = q/(1 + q);
  (* Explicit empty powers avoid the native indeterminate 0^0 at q=0. *)
  partial = Total[Table[If[j === 0, 1, r^j] d[[j + 1]]/(1 + q),
    {j, 0, k - 1}]];
  tail = If[k === 0, 1, r^k] d[[k + 1]];
  lower = partial + tail/(1 + q); upper = partial + tail;
  <|"Lower" -> lower, "Upper" -> upper, "Width" -> upper - lower,
    "PartialSum" -> partial, "DifferenceCoefficient" -> Last[d],
    "Order" -> k, "Parameters" -> {q, s, a},
    "Arithmetic" -> "Exact rational arithmetic", "Theorem" -> "PositiveEulerDifferences"|>];
End[];
EndPackage[];
