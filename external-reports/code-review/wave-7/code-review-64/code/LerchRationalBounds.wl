(* Independent exact-rational review prototype. Not integrated in the repository.
   Python counterpart has executed independent tests. Mathics execution is unrun. *)
BeginPackage["ReviewLerch`"];
LerchRationalBounds::usage =
  "LerchRationalBounds[q,a,n] encloses LerchPhi[q,1,a] with exact rational Gauss/Radau bounds, for 0<=q<1, a>0, and integer 1<=n<=64.";
Begin["`Private`"];
ClearAll[exactRationalQ, gaussValue];
exactRationalQ[v_] := IntegerQ[v] || Head[v] === Rational;
gaussValue[q_, a_, n_, beta_, shift_, mass_] := Module[
  {s = 1-q, dp = 1, d, np = 0, num = mass, norm, j, b, l, dn, nn},
  d = a + shift + beta q/s;
  norm = mass q beta/s^2;
  Do[
    b = shift + ((1+q) j + beta q)/s;
    l = q j (j+beta-1)/s^2;
    dn = (a+b) d - l dp;
    nn = (a+b) num - l np;
    dp = d; d = dn; np = num; num = nn;
    norm = norm q (j+1) (j+beta)/s^2,
    {j, 1, n-1}];
  {num/d, d, norm}];
LerchRationalBounds[q_, a_, n_] := Module[{g, h, lower, upper, lc, uc},
  If[!exactRationalQ[q] || !exactRationalQ[a] || !IntegerQ[n] ||
      !TrueQ[0 <= q < 1] || !TrueQ[a > 0] || !TrueQ[1 <= n <= 64],
    Return[Failure["InvalidInput", <|"MessageTemplate" ->
      "Require exact rational 0<=q<1 and a>0, and integer 1<=n<=64."|>]]];
  If[q === 0, Return[<|"Lower" -> 1/a, "Upper" -> 1/a, "Width" -> 0,
    "LowerErrorCap" -> 0, "UpperErrorCap" -> 0, "Order" -> n,
    "Exact" -> True, "Method" -> "Degenerate geometric measure"|>]];
  g = gaussValue[q,a,n,1,0,1/(1-q)];
  h = gaussValue[q,a,n,2,1,q/(1-q)^2];
  If[!TrueQ[g[[2]] > 0 && h[[2]] > 0],
    Return[Failure["InvariantViolation", <|"Invariant" -> "PositiveDenominators"|>]]];
  lower = g[[1]];
  upper = 1/(a (1-q)) - h[[1]]/a;
  lc = g[[3]]/(a g[[2]]^2);
  uc = h[[3]]/(a (a+1) h[[2]]^2);
  If[!TrueQ[0 < lower < upper],
    Return[Failure["InvariantViolation", <|"Invariant" -> "StrictEnclosure"|>]]];
  <|"Lower" -> lower, "Upper" -> upper, "Width" -> upper-lower,
    "LowerErrorCap" -> lc, "UpperErrorCap" -> uc, "Order" -> n,
    "Exact" -> False, "Method" -> "Meixner-Gauss/Radau, s=1"|>];
LerchRationalBounds[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use LerchRationalBounds[q,a,n]."|>];
End[];
EndPackage[];
