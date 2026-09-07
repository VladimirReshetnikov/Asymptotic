Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "RealInverseAsymptotics.wl"}]];
Clear[x, y];

logarithmic = RealInverseAsymptotic[x+x^2(1+Log[x]), {x,0}, {y,7}];
Print["Logarithmic inverse: ", logarithmic["Expression"]];
Print["Remainder: ", logarithmic["Remainder"]];
Print["Boundary term: ", logarithmic["BoundaryTerm"]];
Print[CheckInverseAsymptotic[logarithmic]];

irrational = RealInverseAsymptotic[x+x^Sqrt[2], {x,0}, {y,4 Sqrt[2]-3}];
Print["Irrational inverse: ", irrational["Expression"]];
Print["Remainder: ", irrational["Remainder"]];
Print[CheckInverseAsymptotic[irrational]];

mixed = RealInverseAsymptotic[x+x^Sqrt[2]+x^2(1+Log[x]), {x,0}, {y,5/2}];
Print["Mixed inverse: ", mixed["Expression"]];
Print[CheckInverseAsymptotic[mixed]];

scaled = RealInverseAsymptotic[4 x^2(1+x(1+Log[x])), {x,0}, {y,5/2}];
Print["Scaled leading monomial: ", scaled["Expression"]];
Print[CheckInverseAsymptotic[scaled]];

(* Evaluate exact expressions only after constructing the expansion. *)
Print["Numerical logarithmic approximation at y=10^-6: ",
 N[logarithmic["Expression"] /. y->10^-6, 80]];

(* A compact formula for x+h(x), where h is of strictly higher power order.
   This returns N perturbation orders, not a cutoff-truncated result. *)
Clear[UnitInverseJet];
UnitInverseJet[h_, variable_Symbol, n_Integer] /; n >= 0 :=
 variable+Total[Table[(-1)^k D[h^k,{variable,k-1}]/k!,{k,1,n}]];
Print[Expand[UnitInverseJet[x^2(1+Log[x]),x,3]]];
