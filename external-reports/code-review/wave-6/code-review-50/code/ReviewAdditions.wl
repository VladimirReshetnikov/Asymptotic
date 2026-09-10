(* Additive prototype. No System or AsymptoticAnalysis definitions are replaced.
   This file has NOT been executed in Wolfram or Mathics in this review.
   The equivalent rational algorithms were independently tested in Python. *)
BeginPackage["AsymptoticIncrementalReview`"];
RationalMomentTable::usage = "RationalMomentTable[z,K] gives M_0(z),...,M_K(z) for exact rational |z|<1; M_0 includes the n=0 term.";
RationalLerchCoefficients::usage = "RationalLerchCoefficients[z,s,K] returns exact coefficients of a^(-s-k), k=0,...,K, including zero coefficients. z and s must be rational.";
AbsorbConstantExponentialPerturbation::usage = "AbsorbConstantExponentialPerturbation[core,c,{x,x0},{y,N},opts] is an opt-in exact regrouping for a perturbation c independent of x and y. It delegates (core+c,0) to AsymptoticExponentialCoreInverse. It changes the chosen core, not the represented function.";
Options[AbsorbConstantExponentialPerturbation] = {};
Begin["`Private`"];
exactRationalQ[x_] := MatchQ[x, _Integer | _Rational];
RationalMomentTable[z_, highest_] := Module[
  {numerator = {1}, denominator, result, value, next, k, j},
  If[! exactRationalQ[z] || ! TrueQ[-1 < z < 1],
    Return[Failure["InvalidMomentParameter", <|"MessageTemplate" -> "Use exact rational z with |z|<1."|>]]];
  If[! IntegerQ[highest] || highest < 0 || highest > 256,
    Return[Failure["InvalidMomentDegree", <|"MessageTemplate" -> "Use an integer moment degree from 0 through 256."|>]]];
  denominator = 1-z;
  result = ConstantArray[0, highest+1];
  For[k=0, k<=highest, k++,
    value = Fold[#1 z + #2 &, 0, Reverse[numerator]];
    result[[k+1]] = value/denominator;
    If[k < highest,
      next = ConstantArray[0, Length[numerator]+1];
      For[j=0, j<Length[numerator], j++,
        next[[j+1]] += j numerator[[j+1]];
        next[[j+2]] += (k+1-j) numerator[[j+1]]];
      numerator = next; denominator *= 1-z]];
  result];
RationalLerchCoefficients[z_, s_, highest_] := Module[{moments, factor=1, result, k},
  If[! exactRationalQ[s],
    Return[Failure["InvalidLerchParameter", <|"MessageTemplate" -> "This prototype requires an exact rational s."|>]]];
  moments = RationalMomentTable[z, highest];
  If[Head[moments] === Failure, Return[moments]];
  result = ConstantArray[0, highest+1];
  For[k=0, k<=highest, k++,
    result[[k+1]] = factor moments[[k+1]];
    factor *= -(s+k)/(k+1)];
  result];
(* Explicit Rules rather than OptionsPattern: options belong to the underlying
   constructor and are forwarded without advertising a second mutable default set.
   The underlying constructor validates real parameters and all other contracts. *)
AbsorbConstantExponentialPerturbation[core_, c_, {x_Symbol, x0_},
    {y_Symbol, n_}, opts___Rule] :=
  If[x === y || ! FreeQ[c, x | y],
    Failure["NonconstantPerturbation", <|"MessageTemplate" -> "The absorbed perturbation must be independent of both source and target."|>],
    If[Length[DownValues[AsymptoticAnalysis`AsymptoticExponentialCoreInverse]] === 0,
      Failure["PackageNotLoaded", <|"MessageTemplate" -> "Load AsymptoticAnalysis before calling this helper."|>],
      AsymptoticAnalysis`AsymptoticExponentialCoreInverse[core+c, 0, {x,x0}, {y,n}, opts]]];
AbsorbConstantExponentialPerturbation[___] :=
  Failure["InvalidArguments", <|"MessageTemplate" -> "Use the documented signature with immediate option rules. Delayed or nested option trees are not supported by this prototype."|>];
End[];
EndPackage[];
