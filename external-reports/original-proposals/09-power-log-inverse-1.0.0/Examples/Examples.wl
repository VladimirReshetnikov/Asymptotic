(* Evaluate with Get[".../Examples/Examples.wl"]. *)
Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],"Kernel","PowerLogInverse.wl"}]];
Clear[x,y,ell,alpha,beta];

(* 1. Original logarithmic example: retain y exponents strictly below 5. *)
logData=PowerLogInverseData[x+x^2(1+Log[x]),{x,y,5}];
Print["Logarithmic inverse: ",Collect[logData["Expression"],y]];
Print["Remainder scale: ",logData["Remainder"]["Scale"]];

(* 2. The exact cutoff reproduces the four terms in the archived question. *)
powerData=PowerLogInverseData[x+x^Sqrt[2],{x,y,4Sqrt[2]-3}];
Print["Irrational-power inverse: ",powerData["Expression"]];

(* 3. Symbolic alpha: a depth cutoff needs no floor of a symbolic number. *)
Print[PowerLogInverse[x+x^alpha,{x,y,5},
 "Truncation"->"Depth",Assumptions->alpha>1]];

(* 4. Several interacting exact irrational gaps and logarithms. *)
mixed=PowerLogInverseData[x+x^Sqrt[2](1+Log[x])+2x^Sqrt[3],{x,y,5/2}];
Print["Mixed-scale blocks: ",mixed["Terms"]];

(* 5. A leading coefficient and a ramified leading power. *)
Print[PowerLogInverse[3x^2(1+x(1+Log[x])),{x,y,5/2}]];

(* 6. An explicit model and a single all-orders coefficient. *)
model=PowerLogModel[1,1,{{1,1+ell}},ell];
Print["Sixth perturbation coefficient: ",PowerLogCoefficient[model,{6}]];

(* 7. The inverse squared, without squaring a too-short inverse truncation. *)
Print[PowerLogInverse[x+x^2,{x,y,6},"InversePower"->2]];

(* 8. A numerical residual bound for the first example.
   Mathematically f'(x)>=1-2 Exp[-5/2]>0 on x>0. Floating-point evaluation
   is not itself interval certification; the theorem is in the article. *)
value=10^-6;
approx=N[logData["Expression"]/.y->value,80];
residual=approx+approx^2(1+Log[approx])-value;
Print["Approximation: ",approx];
Print["Numerically evaluated residual/slope bound: ",
 N[Abs[residual]/(1-2Exp[-5/2]),30]];

(* Failure is intentional: logarithmic leading terms need a different core. *)
Print[PowerLogInverse[x Log[x],{x,y,3}]];
