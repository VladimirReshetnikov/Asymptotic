(* W3-12: a signed quadratic or monomial scale coordinate such as w = x^-2
   selects the one real branch the retained domain proves, so ordered
   arithmetic with a regular operand stays a power-log series in that scale
   instead of falling back to a composite envelope. An unproved sign keeps
   the conservative composite result. *)

VerificationTest[
 Module[{x, u, s, p, q, refined, negative, unknown},
  s = AsymptoticExpansion[LerchPhi[1/2, 2, x^2], {x, Infinity, 5}, "Backend" -> "Package"];
  p = SeriesMultiply[s, x];
  q = SeriesMultiply[s, 1/x];
  refined = SeriesRefine[p, 13/2];
  negative = AsymptoticAnalysis`Private`seriesCoordinateRule[
    <|"Variable" -> x, "ScaleVariable" -> 1/x^2, "Domain" -> x < 0, "Assumptions" -> True|>, u];
  unknown = AsymptoticAnalysis`Private`seriesCoordinateRule[
    <|"Variable" -> x, "ScaleVariable" -> 1/x^2, "Domain" -> True, "Assumptions" -> True|>, u];
  {s["Scale"], p["Scale"], p["Blocks"][[All, 1]], Simplify[Normal[p] - (2/x^3 - 4/x^5 + 18/x^7), x > 0] === 0,
   p["Remainder"] === PowerLogRemainder[x^-2, 9/2, 0], q["Scale"], q["Blocks"][[All, 1]], q["Remainder"] === PowerLogRemainder[x^-2, 11/2, 0],
   refined["Scale"], refined["Blocks"][[All, 1]], refined["Remainder"] === PowerLogRemainder[x^-2, 13/2, 0],
   Simplify[(x /. AsymptoticAnalysis`Private`seriesCoordinateRule[AsymptoticAnalysis`Private`seriesData[s, 20000], u]) - u^(-1/2), u > 0] === 0,
   Simplify[(x /. negative) + u^(-1/2), u > 0] === 0, unknown}],
 {"PowerLog", "PowerLog", {3/2, 5/2, 7/2}, True, True,
  "PowerLog", {5/2, 7/2, 9/2}, True,
  "PowerLog", {3/2, 5/2, 7/2, 9/2, 11/2}, True, True, True, $Failed},
 TestID -> "signed-monomial-scale-coordinates-select-the-proved-branch-for-regular-operands"]
