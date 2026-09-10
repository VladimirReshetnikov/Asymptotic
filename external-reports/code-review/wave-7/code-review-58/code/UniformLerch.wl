(* Additive research prototype. Does not modify AsymptoticAnalysis or System`.
   The theorem bounds exact expressions, not floating-point evaluation error.
   Portable syntax is used; Mathics execution has NOT been verified here. *)
BeginPackage["AsymptoticAudit`"];
UniformLerchModel::usage = "UniformLerchModel[lambda,s,a,K] gives a signed exact-expression remainder bound for LerchPhi[Exp[-lambda/a],s,a]. lambda and s are exact rational constants with lambda>0 and s>=0; a is an unset nonnumeric symbol; 0<=K<=64. The result is not an outward-rounded numerical certificate.";
Begin["`Private`"];
rationalQ[z_] := IntegerQ[z] || Head[z] === Rational;
positiveRationalQ[z_] := rationalQ[z] && TrueQ[z > 0];
nonnegativeRationalQ[z_] := rationalQ[z] && TrueQ[z >= 0];
moment[m_Integer, lambda_, s_] := Total[Table[
  Binomial[m, j] lambda^(m-j) Pochhammer[s, j], {j, 0, m}]];
UniformLerchModel[lambda_?positiveRationalQ, s_?nonnegativeRationalQ,
    a_Symbol, k_Integer] /; 0 <= k <= 64 && ! NumericQ[a] := Module[
  {leading, rows, expression, c, bound, sign = (-1)^k},
  leading = If[s === 0, 1/lambda,
    Exp[lambda] lambda^(s-1) Gamma[1-s, lambda]];
  rows = Join[{{s-1, leading}, {s, 1/2}}, Table[
    {s+2*j-1, BernoulliB[2*j] moment[2*j-1, lambda, s]/Factorial[2*j]}, {j, 1, k}]];
  expression = Total[(#[[2]] a^(-#[[1]])) & /@ rows];
  c = Abs[BernoulliB[2*k+2]] moment[2*k+1, lambda, s]/Factorial[2*k+2];
  bound = c a^(-s-2*k-1);
  <|"Expression" -> expression, "Terms" -> rows, "ScaleVariable" -> 1/a,
    "SourceFunction" -> LerchPhi[Exp[-lambda/a], s, a],
    "RemainderPower" -> s+2*k+1, "AbsoluteRemainderBound" -> bound,
    "RemainderLowerBound" -> If[sign === 1, 0, -bound],
    "RemainderUpperBound" -> If[sign === 1, bound, 0],
    "FrontierTerm" -> sign bound, "ValidityConditions" -> a > 0,
    "Parameters" -> {lambda, s}, "ParameterRegime" -> "lambda and s are fixed; a tends to positive Infinity",
    "Order" -> k, "OutwardRounded" -> False, "NumericalCertificate" -> False|>
];
UniformLerchModel[___] := Failure["InvalidArguments", <|"MessageTemplate" ->
  "Use positive rational lambda, nonnegative rational s, an unset nonnumeric symbol a, and integer K from 0 to 64."|>];
End[];
EndPackage[];
