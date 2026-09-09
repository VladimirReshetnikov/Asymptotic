#!/usr/bin/env wolframscript
Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "PowerLogInverse.wl"}]];
Clear[x,y,u,L,z];

Print["Example 1: logarithmic inverse, blocks of u-power < 6"];
d1 = PowerLogInverseData[x+x^2(1+Log[x]),{x,y,6}];
Print[d1["Expression"] // InputForm];
Print["Remainder: ",d1["Remainder"] // InputForm];
Print["Residual certificate: ",PowerLogResidual[d1]["Certificate"]];
Print["First omitted residual blocks: ",PowerLogResidual[d1,6]["Expression"] // InputForm];

Print["Example 2: irrational power, first six blocks"];
r=Sqrt[2];
d2=PowerLogInverseData[x+x^r,{x,y,1+6(r-1)}];
Print[d2["Expression"] // InputForm];
Print["Residual certificate: ",PowerLogResidual[d2]["Certificate"]];

Print["Mixed power/log terms, nonunit leading coefficient and exponent"];
d3=PowerLogInverseData[4x^2(1+x Log[x]+3x^Sqrt[2]),{x,y,4}];
Print[d3["Expression"] // InputForm];
Print[d3["UniformizerRule"] // InputForm];
Print[d3["LogRule"] // InputForm];
Print["Residual certificate: ",PowerLogResidual[d3]["Certificate"]];

Print["Low-level normalized input with two correction generators"];
d4=PowerLogReversion[1,1,{{Sqrt[2]-1,1},{1,1+L}},{u,L},7/2];
Print[d4["Terms"] // InputForm];
Print[PowerLogResidual[d4]["Certificate"]];

Print["Leading logarithmic pivot, inverse of x (-Log[x]) near zero"];
Print[LogPowerBaseInverse[y,1,1,1] // InputForm];

Print["General homotopy jet: inverse of x^2+x^3"];
Print[InversePerturbationJet[Sqrt[z],z^(3/2),{z,y,3}] // InputForm];

(* Numerical root values are a diagnostic, not interval-certified bounds.
   FindRoot starts from the asymptotic approximation, on the small real germ. *)
Print["Numerical check of the logarithmic example at y=10^-8"];
y0=N[10^-8,80];
a0=N[d1["Expression"]/.y->y0,70];
root=x/.FindRoot[x+x^2(1+Log[x])==y0,{x,a0},WorkingPrecision->80,
 AccuracyGoal->60,PrecisionGoal->60];
Print["Absolute inverse error: ",N[Abs[root-a0],12]];
