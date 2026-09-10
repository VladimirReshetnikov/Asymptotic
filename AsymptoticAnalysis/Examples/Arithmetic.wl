(* Run from a kernel or with wolfram.exe -script AsymptoticAnalysis/Examples/Arithmetic.wl. *)
Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]], "Kernel", "AsymptoticAnalysis.wl"}]];
Clear[x, y, a, b, exact];
a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
b = AsymptoticExpansion[Cos[x], {x, 0, 4}];

{a + b, a - b, a b, a/b, Sqrt[b]}
{x a, Sin[x] a, a/(1 + x)}
SeriesNormalize[(1 + a)/(1 - a), "Cutoff" -> 4]
SeriesNormalize[Sin[a] + Log[1 + a] + Exp[a], "Cutoff" -> 4]

(* New nonlinear operations on exact supplied expressions can compute more
   terms when needed. Unknown operand errors still cap the result. *)
exact = AsymptoticExpansion[x, {x, 0, 2}];
SeriesNormalize[1/(Exp[exact] - 1 - exact), "Cutoff" -> 3]

(* Different inverse cores retain separate error scales. *)
gamma = AsymptoticInverse[LogGamma[x], {x, Infinity}, y, SeriesTermGoal -> 1];
barnes = AsymptoticInverse[LogBarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 1];
combined = gamma + barnes;
{combined["Scale"], Normal[combined], combined["Remainder"]}
Log[gamma + 1]

Print["Available precision: ", InputForm[Normal[a b]], "; remainder: ", InputForm[(a b)["Remainder"]]];
Print["Composite inverse sum: ", InputForm[Normal[combined]]];
