(* Run with: wolframscript -file Examples/examples.wl
   Or evaluate Get[".../Examples/examples.wl"] in a Wolfram notebook. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "RealInverseSeries.wl"}]];
Clear[x, y, z, eps, a];

Print["Example 1: complete logarithmic blocks through y^5"];
r1 = RealInverseSeries[x + x^2 (1 + Log[x]), {x, y}, 6];
Print[r1["Expansion"]];
Print[r1["Remainder"]];
Print[InverseResidual[r1]];

Print["Example 2: exactly the four displayed terms of the question"];
r2 = RealInverseSeries[x + x^Sqrt[2], {x, z}, 4 Sqrt[2] - 3];
Print[r2["Expansion"]];
Print[r2["Remainder"]];

Print["Example 3: mixed irrational and logarithmic powers"];
r3 = RealInverseSeries[x + x^Sqrt[2] + x^2 (1 + Log[x]), {x, y}, 3];
Print[r3["Expansion"]];
Print[r3["IndexCount"]];

Print["Example 4: positive nonunit monomial core"];
r4 = RealInverseSeries[3 x^2 (1 + Sqrt[x] (1 + Log[x]) + 2 x), {x, y}, 7/4];
Print[r4["Expansion"]];
Print[r4["Remainder"]];

Print["Example 5: independent Newton-jet method"];
r5 = RealInverseSeries[x + x^2 (1 + Log[x]), {x, y}, 6, Method -> "Newton"];
Print[FullSimplify[r1["Expansion"] == r5["Expansion"], y > 0]];

Print["Example 6: a finite forward expansion with declared differentiated remainder"];
(* Meaning: f(x)=x+x^2(1+Log[x])+O(x^4), with the corresponding derivative bound. *)
r6 = RealInverseSeries[x + x^2 (1 + Log[x]), {x, y}, 4,
 "InputRemainder" -> {4, 0}];
Print[r6["Expansion"]]; Print[r6["Remainder"]];

Print["Example 7: symbolic real coefficient, exact exponent"];
r7 = RealInverseSeries[x + a x^(3/2), {x, y}, 3,
 Assumptions -> Element[a, Reals]];
Print[r7["Expansion"]];

Print["Example 8: a parameter expansion, not an automatic asymptotic claim"];
Print[PerturbativeInverse[y, x^2 (1 + Log[x]), {x, y, eps}, 3]];

Print["Example 9: visible failure for a logarithmic dominant core"];
Print[RealInverseSeries[-x Log[x], {x, y}, 3]];
