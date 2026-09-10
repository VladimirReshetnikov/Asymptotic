(* Bounded algebraic operations needed by the package's Fourier and special
   inverse families. Loaded early, only on Mathics, before consumer parsing.
   These are exact identities; no branch or nonzero assumption is introduced. *)

Begin["AsymptoticAnalysis`Mathics`"];
ClearAll[AsymptoticAnalysis`Mathics`CoefficientRules,
  AsymptoticAnalysis`Mathics`TrigToExp,
  AsymptoticAnalysis`Mathics`ExpToTrig,
  AsymptoticAnalysis`Mathics`Take];

CoefficientRules[polynomial_, variable_Symbol] /; PolynomialQ[polynomial, variable] :=
  Reverse[Select[MapIndexed[({First[#2] - 1} -> #1) &,
    CoefficientList[Expand[polynomial], variable]], Last[#] =!= 0 &]];
CoefficientRules[polynomial_, {variable_Symbol}] := CoefficientRules[polynomial, variable];
CoefficientRules[arguments___] := System`CoefficientRules[arguments];

TrigToExp[expression_] := expression //. {
  Sin[z_] :> (Exp[I z] - Exp[-I z])/(2 I),
  Cos[z_] :> (Exp[I z] + Exp[-I z])/2,
  Sinh[z_] :> (Exp[z] - Exp[-z])/2,
  Cosh[z_] :> (Exp[z] + Exp[-z])/2};

(* For a Fourier mode z=I omega L, this is Euler's identity directly in
   omega L. It also remains an identity for arbitrary complex exponents. *)
ExpToTrig[expression_] := expression /. Power[E, z_] :> Cos[z/I] + I Sin[z/I];

(* Mathics Take does not recognize UpTo. A shorter sequence must remain a
   sequence, including the empty case, when forming complete inverse sectors. *)
Take[expression_, System`UpTo[n_Integer?NonNegative]] :=
  System`Take[expression, Min[n, Length[expression]]];
Take[arguments___] := System`Take[arguments];

End[];
