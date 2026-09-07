Get[FileNameJoin[{DirectoryName[$InputFileName],"..","Kernel","RealLogPowerInverse.wl"}]];
Clear[x,y,L];

(* Original positive-real logarithmic germ. *)
r1=RealInverseExpansion[x+x^2(1+Log[x]),{x,y},5];
Print[r1["Expression"]];
Print[r1["Remainder"]];
Print[InverseResidual[r1]];

(* Equivalent explicit structured input, with a visible logarithm symbol. *)
s1=LogPowerInverseExpansion[{{1,1+L}},{y,L},5];
Print[s1["Terms"]];

(* The original Piecewise expression can be normalized under x>0 first. *)
f=Piecewise[{{x+x^2 Log[x^2 E^2]/2,x!=0}},0];
fPositive=FullSimplify[f,Assumptions->x>0];
Print[RealInverseExpansion[fPositive,{x,y},3]["Expression"]];

(* Irrational powers: cutoff is an exact exponent, not number of terms. *)
a=Sqrt[2]-1;
r2=RealInverseExpansion[x+x^Sqrt[2],{x,y},1+6 a];
Print[r2["Expression"]];
Print[InverseResidual[r2]["Vanishes"]];
Print[Table[PurePowerInverseCoefficient[Sqrt[2],n],{n,0,6}]];

(* Mixed and resonant scales, including a nonunit linear coefficient. *)
r3=LogPowerInverseExpansion[{{Sqrt[2]-1,1+L},{1,2-L}},
 {y,L},3,"LinearCoefficient"->2];
Print[r3["Expression"]];
Print[InverseResidual[r3]["Vanishes"]];

(* High-precision comparison; use exact y0 or sufficient input precision. *)
y0=10^-6;
gApprox=N[r1["Expression"]/.y->y0,60];
gNumeric=x/.FindRoot[x+x^2(1+Log[x])==y0,
 {x,N[y0,80]},WorkingPrecision->80,AccuracyGoal->65,PrecisionGoal->65];
Print[N[{gApprox,gNumeric,Abs[gApprox-gNumeric]},20]];

(* TestReport is supplied separately; results must be run in your kernel. *)
