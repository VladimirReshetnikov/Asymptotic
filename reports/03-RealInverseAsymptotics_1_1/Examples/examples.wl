(* Run in a Wolfram Language kernel, or evaluate sections in a notebook. *)
Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],
 "Kernel", "RealInverseAsymptotics.wl"}]];
Clear[x, y, z, a, c];

(* The original logarithmic example. Output powers are strictly below 6. *)
r = RealInverseExpansion[x + x^2 (1 + Log[x]), {x, y}, 6];
Print["Logarithmic inverse: ", r["Expression"]];
Print["Big-O scale: ", r["RemainderScale"]];
Print[InverseResidual[r]];

(* Exactly the four displayed terms of the question's second example. *)
s = RealInverseExpansion[x + x^Sqrt[2], {x, z}, 4 Sqrt[2] - 3];
Print["Irrational-power inverse: ", s["Expression"]];
Print["Big-O scale: ", s["RemainderScale"]];
Print[InverseResidual[s]];

(* Multiple generators: exact ordering and resonant aggregation. *)
m = RealInverseExpansion[x + 2 x^Sqrt[2] + x^(3/2) (1 + Log[x]), {x, y}, 3];
Print["Mixed-support blocks: ", m["Blocks"]];
Print[InverseResidual[m]];

(* Nonlinear positive dominant core: x ~ Sqrt[y]. *)
p = RealInverseExpansion[x^2 + x^3, {x, y}, 3];
Print["Power-core inverse: ", p["Expression"]];
Print[InverseResidual[p]];

(* Symbolic parameters require explicit real/positive assumptions. *)
parametric = RealInverseExpansion[a x + c x^2, {x, y}, 5,
 Assumptions -> a > 0 && Element[c, Reals]];
Print[parametric["Expression"]];

(* The low-level formula permits broader h, but certifies no remainder. *)
formal = LagrangeInverseTruncation[x^2 (1 + Log[x]), {x, y}, 4];
Print[formal];

(* Numerical use: construct exactly first, substitute second. *)
Print[N[r["Expression"] /. y -> 10^-8, 60]];
