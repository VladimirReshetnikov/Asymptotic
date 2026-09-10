(* Examples for AsymptoticAnalysis. The script loads the package itself.
   From the repository root: wolfram.exe -noinit -script src/Examples/Examples.wl *)
Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]], "Kernel", "AsymptoticAnalysis.wl"}]];
ClearAll[x, y, z, alpha, a, b];
show[label_, e_] := Print[label, ": ", ToString[e, InputForm]];

(* --- Question 236367: the real branch of the inverse near 0+ --- *)
r1 = AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 6}];
show["inverse of x + x^2 (1 + Log[x])", Normal[r1]];
show["its remainder class", r1["Remainder"]];
show["as SeriesData", r1["SeriesData"]];
show["formal residual vanishes below the cutoff", InverseResidual[r1]["ZeroBelowCutoff"]];
show["numerical check at y = 10^-4", InverseNumericalCheck[r1, 10^-4]];

r2 = AsymptoticInverse[x + x^Sqrt[2], {x, 0}, y, SeriesTermGoal -> 4];
show["inverse of x + x^Sqrt[2], four terms", Normal[r2]];
show["remainder", r2["Remainder"]];

(* --- The second question: forward expansion with irrational exponents at infinity --- *)
f1 = AsymptoticExpansion[(1 + x + x^Sqrt[2])^Sqrt[2], {x, Infinity}, SeriesTermGoal -> 7];
show["(1 + x + x^Sqrt[2])^Sqrt[2] at infinity", Normal[f1]];
show["remainder", f1["Remainder"]];
show["... and its inverse", Normal[AsymptoticInverse[(1 + x + x^Sqrt[2])^Sqrt[2], {x, Infinity}, {y, 1/2}]]];

(* --- More forward expansions --- *)
show["x^x near 0", Normal[AsymptoticExpansion[x^x, {x, 0}, SeriesTermGoal -> 4]]];
show["Sin[x] + x^2 Log[x] near 0", AsymptoticExpansion[Sin[x] + x^2 Log[x], {x, 0, 6}]["SeriesData"]];
show["(x + Log[x])^(3/2) at infinity", Normal[AsymptoticExpansion[(x + Log[x])^(3/2), {x, Infinity, 2}]]];

(* --- Nonunit leading power, resonances, several irrational gaps --- *)
show["3 x^2 (1 + x (1 + Log[x]))", Normal[AsymptoticInverse[3 x^2 (1 + x (1 + Log[x])), {x, 0}, {y, 2}]]];
show["x + x^2 + x^3 (the y^4 block cancels)", Normal[AsymptoticInverse[x + x^2 + x^3, {x, 0}, {y, 7}]]];
show["x + x^Sqrt[2] (1 + Log[x]) + 2 x^Sqrt[3]", Normal[AsymptoticInverse[x + x^Sqrt[2] (1 + Log[x]) + 2 x^Sqrt[3], {x, 0}, {y, 3}]]];

(* --- Other endpoints and observables --- *)
show["inverse of x + Log[x] at infinity (Wright omega)", Normal[AsymptoticInverse[Log[x] + x, {x, Infinity}, {y, 3}]]];
show["inverse of x + 1/x at infinity", Normal[AsymptoticInverse[x + 1/x, {x, Infinity}, {y, 4}]]];
show["inverse of x - x^2 near x = 1", Normal[AsymptoticInverse[x - x^2, {x, 1}, {y, 3}]]];
show["inverse of 1/x + 1 near 0 (pole)", Normal[AsymptoticInverse[1/x + 1, {x, 0}, {y, 3}]]];
show["square of the inverse of x + x^2", Normal[AsymptoticInverse[x + x^2, {x, 0}, {y, 5}, "Power" -> 2]]];
show["arctan from tan", Normal[AsymptoticInverse[Tan[x], {x, 0}, y, SeriesTermGoal -> 4]]];

(* --- Symbolic data --- *)
show["symbolic coefficients", Normal[AsymptoticInverse[a x + b x^2, {x, 0}, {y, 4}, Assumptions -> a > 0 && Element[b, Reals]]]];
show["symbolic exponent (depth truncation)", Normal[AsymptoticInverse[x + x^alpha, {x, 0}, {y, 3}, "Truncation" -> "Depth", Assumptions -> alpha > 1]]];

(* --- Helpers --- *)
show["Lagrange-Buermann formula generator", Expand[PerturbativeInverse[x^2 (1 + Log[x]), {x, y}, 3]]];
show["single multi-index coefficient", InverseExpansionCoefficient[r1, {6}]["Coefficient"]];
show["parsed model", PowerLogModel[3 x^2 (1 + x (1 + Log[x])), {x, 0}]];

(* --- Leading logarithms and exponential cores: relative logarithmic order --- *)
lambertSmall = AsymptoticInverse[x Log[x], {x, 0}, y, SeriesTermGoal -> 4];
show["x Log[x] at 0+, y approaching 0-", Normal[lambertSmall]];
show["Lambert branch", lambertSmall["LambertBranch"]];
show["logarithmic local variable and prefactor", {lambertSmall["LogarithmicVariable"], lambertSmall["Prefactor"]}];
show["logarithmic remainder", lambertSmall["Remainder"]];
show["numerical check against x Log[x]", InverseNumericalCheck[lambertSmall, -Exp[-100]]];

lambertLarge = AsymptoticInverse[x Exp[x], {x, Infinity}, y, SeriesTermGoal -> 5];
show["x Exp[x] at infinity", Normal[lambertLarge]];
show["Lambert normalized residual", InverseResidual[lambertLarge]];
show["numerical check against x Exp[x]", InverseNumericalCheck[lambertLarge, Exp[100]]];

show["scaled exponential core", Normal[AsymptoticInverse[2 x Exp[3 x], {x, Infinity}, {y, 4}]]];
show["logarithmic core with a higher-power correction", AsymptoticInverse[x Log[x] + x^2, {x, 0}, {y, 4}]];
show["irrational Puiseux composition", AsymptoticExpansion[ArcCos[1 - x^Sqrt[2]], {x, 0, 3}]];
