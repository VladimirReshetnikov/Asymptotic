(* Run in a fresh kernel. The script locates the package relative to itself. *)
Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],
  "Kernel", "RealInverseAsymptotics.wl"}]];
Clear[x, y, L, a, c];

logResult = RealInverseAsymptotic[x + x^2 (1 + Log[x]), {x, 0}, {y, 0, 5}];
Print["Logarithmic inverse through y^5: ", logResult["Expression"]];
Print["Its Big-O scale: ", logResult["RemainderScale"]];

irrationalResult = RealInverseAsymptotic[x + x^Sqrt[2], {x, 0},
  {y, 0, 3 Sqrt[2] - 2}];
Print["Exactly four irrational-power terms: ", irrationalResult["Expression"]];
Print["Next power: ", irrationalResult["FirstOmittedPower"]];

mixedResult = InversePowerLogModel[3, 2,
  {{Sqrt[2] - 1, 1 + L}, {1, 2 - L^2}}, L, {y, 0, 3/2}];
Print["Mixed model: ", mixedResult["Expression"]];

(* Resonance: two contributions at weight 2 cancel. The remainder is safe,
   but deliberately not optimized by searching through subsequent zero blocks. *)
cancelResult = RealInverseAsymptotic[x + x^2 + 2 x^3, {x, 0}, {y, 0, 2}];
Print["First omitted coefficient (zero): ", cancelResult["FirstOmittedCoefficient"]];

(* Symbolic real coefficients require explicit hypotheses. *)
parameterResult = InversePowerLogModel[c, 1, {{1, a + L}}, L,
  {y, 0, 3}, Assumptions -> c > 0 && Element[a, Reals]];
Print[parameterResult["Expression"]];

(* A source jet for F(x)=x+x Sin[x] has relative remainder O[x^5].
   Derivative control is required as well, and is elementary for this example. *)
jetResult = InversePowerLogJet[1, 1, {{1, 1}, {3, -1/6}}, L,
  {y, 0, 4}, {5, 0}];
Print["Inverse from source jet: ", jetResult["Expression"]];
Print["Combined remainder scale: ", jetResult["RemainderScale"]];

(* A non-polynomial logarithmic coefficient: the derivative theorem, not the
   finite-polynomial model theorem, applies. *)
oscillatoryBlocks = LagrangeInverseBlocks[x^2 Sin[Log[x]],
  {x, 0}, {y, 0}, 3, "DerivativeScale" -> {1, 0}];
Print["Oscillatory blocks: ", oscillatoryBlocks["Expression"]];
Print[oscillatoryBlocks["Hypotheses"]];

(* Beyond all algebraic orders: derivative blocks, no automatic exponential
   remainder certificate is claimed by this generic routine. *)
flatBlocks = LagrangeInverseBlocks[Exp[-1/x], {x, 0}, {y, 0}, 3];
Print["Exponential sectors: ", flatBlocks["Expression"]];

(* Use exact arguments or genuinely high-precision numbers. *)
Print[EvaluateInverseAsymptotic[logResult, 10^-8, WorkingPrecision -> 60]];

(* For these TWO source functions global derivative bounds are proved in the
   article. These expressions are mathematical bounds whenever the finite
   approximant is positive; numerical rounding still needs interval control
   to produce a machine-certified enclosure. *)
logErrorBound = Abs[InverseResidual[logResult]]/(1 - 2 Exp[-5/2]);
irrationalErrorBound = Abs[InverseResidual[irrationalResult]];
Print["Residual error-bound expressions available as logErrorBound and irrationalErrorBound."];
