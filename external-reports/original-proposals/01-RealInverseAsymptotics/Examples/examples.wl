Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],
  "Kernel", "RealInverseAsymptotics.wl"}]];
ClearAll[x,y,a,b,eps];

(* The original logarithmic example: complete blocks below y^6. *)
r1 = RealInverseAsymptotic[x+x^2 (1+Log[x]), {x,0}, {y,6}];
Print[Normal[r1]];
Print[r1["Remainder"]];  (* PowerLogRemainder[y,6,5] *)
Print[InverseResidual[r1]];

(* The irrational-power example, with exactly the requested four blocks. *)
r2 = RealInverseAsymptotic[x+x^Sqrt[2], {x,0}, {y,4 Sqrt[2]-3}];
Print[Normal[r2]];
Print[r2["Remainder"]];

(* Mixed irrational exponents and logarithms; no rational-grid substitution. *)
r3 = RealInverseAsymptotic[x+x^Sqrt[2](1+Log[x])+2 x^Sqrt[3],
  {x,0},{y,3}];
Print[Normal[r3]];
Print[InverseResidual[r3]["ZeroBelowCutoff"]];

(* A nonunit leading monomial, with its positive real inverse root. *)
r4 = RealInverseAsymptotic[3 x^2+3 x^3(1+Log[x]),{x,0},{y,2}];
Print[Normal[r4]];

(* Fixed real parameters are permitted in coefficients, not in exponents. *)
r5 = RealInverseAsymptotic[a x+b x^2,{x,0},{y,4},
  Assumptions -> a>0 && Element[b,Reals]];
Print[Normal[r5]];

(* An analytic elementary factor is expanded before entering the finite engine.
   Here Exp[x]-1 has remainder O[x^5] after the fourth Taylor polynomial,
   and its differentiated remainder is O[x^4]. *)
jet = Normal[Series[Exp[x]-1,{x,0,4}]]+x^Sqrt[2];
r6 = RealInverseAsymptotic[jet,{x,0},{y,5},InputRemainder->{5,0}];
Print[Normal[r6]];
Print[r6["Remainder"]];

(* Formal homotopy formula: epsilon is a marker, not a y-asymptotic order. *)
Print[PerturbativeInverse[x^2(1+Log[x]),{x},{y,4},eps]];

(* Positive-branch numerical comparison. This is a numerical diagnostic,
   not a rounding-certified interval. *)
value=N[1/10000,80];
approx=N[Normal[r1]/.y->value,60];
root=x/.FindRoot[x+x^2(1+Log[x])==value,{x,value},
  WorkingPrecision->80,AccuracyGoal->60,PrecisionGoal->60];
Print[<|"Approximation"->approx,"NumericalInverse"->root,
 "AbsoluteError"->Abs[approx-root]|>];
