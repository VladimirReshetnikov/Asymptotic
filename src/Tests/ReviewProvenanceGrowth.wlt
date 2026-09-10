(* P07: lifted scalar and regular operands record only a chart template of
   the series they were lifted beside, so a chain of `t + c` or `t e` steps
   references each ancestor once and its recipe tree grows linearly; replay
   re-expands the lifted expression against the template instead of
   refining the template. *)

provenanceGrowthNodes[s_] := Count[s, _GeneralizedSeries, {0, Infinity}];

VerificationTest[
 Module[{x, s, chain, scalarChain, mixedChain},
  s = AsymptoticExpansion[Exp[x], {x, 0, 6}];
  chain = NestList[SeriesAdd[#, 1] &, s, 8];
  scalarChain = NestList[SeriesMultiply[#, 2] &, s, 8];
  mixedChain = NestList[SeriesAdd[SeriesMultiply[#, Sin[x]], 1] &, s, 6];
  {provenanceGrowthNodes /@ chain, provenanceGrowthNodes /@ scalarChain,
   provenanceGrowthNodes /@ mixedChain,
   Normal[Last[chain]] === Normal[s] + 8, Normal[Last[scalarChain]] === Expand[256 Normal[s]],
   ! KeyExistsQ[Last[chain][[1]]["SeriesRecipe"][[2, 2]][[1]]["SeriesRecipe"][[2, 1, 1]], "SeriesRecipe"]}],
 {Range[1, 25, 3], Range[1, 25, 3], Range[1, 37, 6], True, True, True},
 TestID -> "lifted-operands-keep-a-chart-template-so-recipe-trees-grow-linearly"]

VerificationTest[
 Module[{x, s, t, sum, product, mixed, negative, refinedSum, refinedProduct, refinedMixed, refinedNegative},
  s = AsymptoticExpansion[Exp[x], {x, 0, 4}];
  sum = Nest[SeriesAdd[#, 1] &, s, 3];
  product = SeriesMultiply[s, Sin[x]];
  mixed = SeriesAdd[SeriesMultiply[SeriesAdd[s, 2], Cos[x]], 1/3];
  t = AsymptoticExpansion[1/x + 1, {x, 0, 3}];
  negative = SeriesMultiply[t, Exp[x]];
  refinedSum = SeriesRefine[sum, 9]; refinedProduct = SeriesRefine[product, 9];
  refinedMixed = SeriesRefine[mixed, 8]; refinedNegative = SeriesRefine[negative, 6];
  {Normal[refinedSum] === Normal[AsymptoticExpansion[Exp[x], {x, 0, 9}]] + 3, refinedSum["RemainderPower"],
   Expand[Normal[refinedProduct] - Normal[AsymptoticExpansion[Exp[x] Sin[x], {x, 0, 9}]]] === 0, refinedProduct["RemainderPower"],
   Expand[Normal[refinedMixed] - Normal[AsymptoticExpansion[(Exp[x] + 2) Cos[x] + 1/3, {x, 0, 8}]]] === 0, refinedMixed["RemainderPower"],
   Expand[Normal[refinedNegative] - Normal[AsymptoticExpansion[(1/x + 1) Exp[x], {x, 0, 6}]]] === 0, refinedNegative["RemainderPower"],
   refinedSum["RefinementStatistics"]["Strategy"], refinedNegative["RefinementStatistics"]["Strategy"]}],
 {True, 9, True, 9, True, 8, True, 6, "ReplayOperationRecipe", "ReplayOperationRecipe"},
 TestID -> "replay-re-expands-lifted-operands-against-their-chart-template"]
