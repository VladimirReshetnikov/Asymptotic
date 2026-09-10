(* UNEXECUTED WOLFRAM LANGUAGE REFERENCE IMPLEMENTATION.
   Independent of AsymptoticAnalysis; no package monkey-patching.
   Run tests/ReferenceWL.wl after loading this file. *)
BeginPackage["AsymptoticAuditLerch`"];
LerchRationalEnclosure::usage = "LerchRationalEnclosure[z,s,a,n] returns exact rational bounds for 0<=z<1, a>0 rational, positive integer s, and first omitted Taylor index n<=64.";
Begin["`Private`"];
exactRationalQ[q_] := IntegerQ[q] || Head[q] === Rational;
moments[z_, order_Integer] := Module[{values = {1/(1-z)}, coefficients = {1}, next, k, j, p},
  For[k = 1, k <= order, k++,
    p = Fold[#1 z + #2 &, 0, Reverse[coefficients]];
    AppendTo[values, z p/(1-z)^(k+1)];
    next = ConstantArray[0, Length[coefficients] + 1];
    For[j = 0, j < Length[coefficients], j++,
      next[[j+1]] += (j+1) coefficients[[j+1]];
      next[[j+2]] += (k-j) coefficients[[j+1]]];
    coefficients = next]; values];
LerchRationalEnclosure[z_, s_, a_, n_] := Module[
  {m, polynomial = 0, rising = 1, k, u, mean, second, variance, p, lo, hi, interval},
  If[! TrueQ[exactRationalQ[z] && exactRationalQ[a] && 0 <= z < 1 && a > 0 &&
      IntegerQ[s] && s > 0 && IntegerQ[n] && 0 <= n <= 64],
    Return[Failure["Domain", <|"MessageTemplate" -> "Requires rational 0<=z<1, rational a>0, positive integer s, integer 0<=n<=64."|>]]];
  m = moments[z, n+2];
  For[k = 0, k < n, k++,
    polynomial += (-1)^k rising m[[k+1]]/(Factorial[k] a^(s+k));
    rising *= s+k];
  u = rising m[[n+1]]/(Factorial[n] a^(s+n));
  If[u === 0,
    mean = variance = lo = hi = 0,
    mean = m[[n+2]]/(m[[n+1]] a (n+1));
    second = 2 m[[n+3]]/(m[[n+1]] a^2 (n+1) (n+2));
    variance = second - mean^2; p = s+n;
    lo = u/(1+mean)^p;
    hi = Min[u, lo + u p (p+1) variance/2]];
  interval = If[EvenQ[n], {polynomial+lo, polynomial+hi},
    {polynomial-hi, polynomial-lo}];
  <|"Interval" -> interval, "Polynomial" -> polynomial,
    "SignedRemainderInterval" -> {lo, hi}, "FirstOmittedMagnitude" -> u,
    "WeightedMean" -> mean, "WeightedVariance" -> variance,
    "Conditions" -> True, "ExactRationalEndpoints" -> True,
    "FirstOmittedTaylorIndex" -> n|>];
LerchRationalEnclosure[___] := Failure["Arguments", <|"MessageTemplate" -> "Use LerchRationalEnclosure[z,s,a,n]."|>];
End[];
EndPackage[];
