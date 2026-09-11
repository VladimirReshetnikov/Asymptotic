(* The proof context normalizes reciprocal and exponential scale positivity
   and exact numeric coefficients skip the assumption prover, so ordinary
   Dirichlet arithmetic and Gamma expansions run without kernel messages;
   VerificationTest reports any Power::infy or Greater::nord as a failure. *)

VerificationTest[
 Module[{x, s, sum, gamma},
  ClearSystemCache[];
  s = AsymptoticExpansion[Zeta[x], {x, Infinity, 3}];
  sum = SeriesAdd[s, s];
  gamma = AsymptoticExpansion[Gamma[x], {x, Infinity, 6}, "Backend" -> "Package"];
  {Simplify[Normal[sum] - 2 Normal[s], x > 1] === 0, sum["Kind"], gamma["Kind"],
   AsymptoticAnalysis`Private`seriesPositivityCanon[x^(-1) > 0 && x > 1 && E^(-x) > 0] === (x > 0 && x > 1),
   AsymptoticAnalysis`Private`seriesPositivityCanon[-x^(-1) > 0] === (x < 0),
   AsymptoticAnalysis`Private`realPolynomialCondition[2 + 3 \[FormalL], \[FormalL], x^(-1) > 0 && E^(-x) > 0],
   AsymptoticAnalysis`Private`realPolynomialCondition[I, \[FormalL], True]}],
 {True, "Derived", "Forward", True, True, True, False},
 TestID -> "proof-context-positivity-is-normalized-and-numeric-coefficients-skip-the-prover"]
