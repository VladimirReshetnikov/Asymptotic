(* C22, arithmetic half: a quantitative forward tail bound survives a sum,
   a product, a scalar multiple and a shift, and the transported bound can be
   truncated again. Checked against the defining sums numerically. *)

VerificationTest[
 Module[{x, z, w, sum, prod, scaled, shifted, within},
  z = AsymptoticExpansion[Zeta[x], x -> Infinity, SeriesTermGoal -> 3];
  w = AsymptoticExpansion[Zeta[x] - 1, x -> Infinity, SeriesTermGoal -> 3];
  sum = SeriesAdd[z, w]; prod = SeriesMultiply[z, w]; scaled = SeriesMultiply[z, 3]; shifted = SeriesAdd[z, 5];
  within[s_, exact_] := TrueQ[N[Abs[(exact /. x -> 10) - (Normal[s] /. x -> 10)], 30] <= N[s["AbsoluteRemainderBound"] /. x -> 10, 30]];
  {KeyExistsQ[sum[[1]], "AbsoluteRemainderBound"], sum["ForwardRemainderContract"]["Type"], sum["ForwardRemainderContract"]["Operation"],
   Simplify[sum["AbsoluteRemainderBound"] - 2 (1 + 4/(x - 1))/4^x, x > 1] === 0, sum["ArithmeticDiscardedPart"],
   TrueQ[Simplify[sum["RemainderBoundConditions"], x > 1]],
   within[sum, 2 Zeta[x] - 1], within[prod, Zeta[x] (Zeta[x] - 1)], within[scaled, 3 Zeta[x]], within[shifted, Zeta[x] + 5],
   Simplify[scaled["AbsoluteRemainderBound"] - 3 (1 + 4/(x - 1))/4^x, x > 1] === 0,
   Simplify[shifted["AbsoluteRemainderBound"] - (1 + 4/(x - 1))/4^x, x > 1] === 0,
   KeyExistsQ[prod[[1]], "RemainderLowerBound"], prod["ForwardRemainderContract"]["Operation"]}],
 {True, "TransportedThroughArithmetic", "Add", True, 0, True, True, True, True, True, True, True, False, "Multiply"},
 TestID -> "arithmetic-transports-absolute-tail-bounds-through-sums-products-scalars-and-shifts"]

VerificationTest[
 Module[{x, z, prod, truncated, within, plain},
  z = AsymptoticExpansion[Zeta[x], x -> Infinity, SeriesTermGoal -> 3];
  prod = SeriesMultiply[z, z];
  truncated = SeriesTruncate[prod, Log[3]];
  within[s_, exact_] := TrueQ[N[Abs[(exact /. x -> 10) - (Normal[s] /. x -> 10)], 30] <= N[s["AbsoluteRemainderBound"] /. x -> 10, 30]];
  plain = SeriesAdd[AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Package"], AsymptoticExpansion[Sin[x], {x, 0, 3}, "Backend" -> "Package"]];
  {Simplify[Normal[prod] - (1 + 2 2^-x + 2 3^-x), x > 1] === 0, Simplify[prod["ArithmeticDiscardedPart"] - (4^-x + 2 6^-x + 9^-x), x > 1] === 0,
   within[prod, Zeta[x]^2], Simplify[Normal[truncated] - (1 + 2 2^-x), x > 1] === 0,
   truncated["ForwardRemainderContract"]["Type"], within[truncated, Zeta[x]^2],
   KeyExistsQ[plain[[1]], "AbsoluteRemainderBound"]}],
 {True, True, True, True, "TransportedThroughTruncation", True, False},
 TestID -> "arithmetic-transport-records-the-discarded-product-part-and-composes-with-truncation"]
