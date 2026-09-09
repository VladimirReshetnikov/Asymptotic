(* Native-unrun comparison harness. No claim of a measured winner.
   Load the audited local package before Get of this file. Fresh kernel,
   empty $Assumptions, and consistent timeout are recommended. *)
Clear[x, y];
ClearAll[compareProbe];
SetAttributes[compareProbe, HoldAllComplete];
compareProbe[label_, expr_] := Module[{result, elapsed},
  {elapsed, result} = AbsoluteTiming[TimeConstrained[expr, 120, $TimedOut]];
  <|"Case" -> label, "Seconds" -> elapsed, "Head" -> Head[result], "Result" -> result|>
];
Block[{$Assumptions = True},
 Print[InputForm[<|"Version" -> $Version, "SystemID" -> $SystemID|>]];
 Scan[Print[InputForm[#]] &, {
  compareProbe["native analytic inverse", InverseSeries[Series[x+x^2, {x,0,6}]]],
  compareProbe["package analytic inverse", AsymptoticInverse`AsymptoticInverse[x+x^2,{x,0},{y,7}]],
  compareProbe["native irrational inverse", AsymptoticSolve[x+x^Sqrt[2]==y,x,{y,0,4},Assumptions->x>0]],
  compareProbe["package irrational inverse", AsymptoticInverse`AsymptoticInverse[x+x^Sqrt[2],{x,0},{y,4}]],
  compareProbe["native logarithmic forward", Asymptotic[Log[1+x Log[x]],{x,0,4},Direction->"FromAbove"]],
  compareProbe["package logarithmic forward", AsymptoticInverse`AsymptoticExpansion[Log[1+x Log[x]],{x,0,4}]],
  compareProbe["native Zeta forward", Asymptotic[Zeta[x],x->Infinity,SeriesTermGoal->4]],
  compareProbe["package Zeta forward", AsymptoticInverse`AsymptoticExpansion[Zeta[x],{x,Infinity},SeriesTermGoal->4]]
 }]
];
(* Orders are not matched merely because their printed numbers agree.
   Compare residual orders, admitted sides and error scales before timing. *)
