(* Load this file with Get to evaluate the examples in a Wolfram kernel.
   The source and target variables are distinct and exact arithmetic is used. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel",
  "RealInverseAsymptotics.wl"}]];
Clear[x,y,ell,a,b];

(* Original logarithmic example, retaining every y-power strictly below 5. *)
logarithmic = RealInverseSeries[x+x^2 (1+Log[x]), {x,0}, y, 5];
Print["Logarithmic inverse: ", logarithmic["Expression"]];
Print["Remainder metadata: ", logarithmic["Remainder"]];
Print["First omitted exponent bucket: ", logarithmic["FrontierExpression"]];

(* Original irrational-power example: four displayed terms. *)
irrational = RealInverseSeries[x+x^Sqrt[2], {x,0}, y, 4 Sqrt[2]-3];
Print["Irrational-power inverse: ", irrational["Expression"]];
Print["Remainder metadata: ", irrational["Remainder"]];
Print["Pure-power coefficients n=0..6: ",
 Table[PurePowerInverseCoefficient[Sqrt[2],n],{n,0,6}]];

(* Mixed powers and logarithms, including coincident exponent sums. *)
mixed = RealInverseSeries[x+x^(3/2)+2 x^2 Log[x], {x,0}, y, 3];
Print["Mixed model: ", mixed["Expression"]];

(* Leading monomial 2 x^3; t=(y/2)^(1/3) is normalized internally. *)
nonlinear = InversePowerLog[2,3,{{1/2,1+ell}},ell,y,5/6];
Print["Nonlinear leading monomial: ", nonlinear["Expression"]];

(* Powers of the inverse, without expanding a separately computed inverse. *)
square = RealInverseSeries[x+x^2,{x,0},y,6,"ObservablePower"->2];
reciprocal = RealInverseSeries[x+x^(3/2),{x,0},y,1,"ObservablePower"->-1];
Print["Square of inverse: ",square["Expression"]];
Print["Reciprocal of inverse: ",reciprocal["Expression"]];

(* Exact real parameter assumptions. *)
parameterized = RealInverseSeries[a x+b x^2,{x,0},y,3,
 Assumptions->a>0 && Element[b,Reals]];
Print["Parameterized example: ",parameterized["Expression"]];

(* Algorithm agreement and a normalized composition residual. *)
fixedPoint = RealInverseSeries[x+x^2 (1+Log[x]),{x,0},y,5,
 "Method"->"FixedPoint"];
Print["Algorithm difference (expected 0): ",
 FullSimplify[logarithmic["Expression"]-fixedPoint["Expression"],y>0]];
(* Residual cutoff 4 is a RELATIVE t-power, not the inverse's y-power cutoff. *)
residual = RealInverseResidual[logarithmic,4];
Print["Residual jet: ",residual];

(* A cancelled frontier bucket is not falsely claimed to be nonzero. *)
cancelled = RealInverseSeries[x+x^2+2 x^3,{x,0},y,3];
Print["Cancelled frontier: ",
 {cancelled["FrontierPolynomial"],cancelled["Remainder"]}];

(* Explicit failures rather than guessed exponent ordering or branch selection. *)
Print["Expected inexact-input failure: ",
 RealInverseSeries[x+x^1.4142,{x,0},y,3]];
Print["Expected leading-logarithm failure: ",
 RealInverseSeries[x Log[x],{x,0},y,3]];
