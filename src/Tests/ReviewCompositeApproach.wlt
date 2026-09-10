(* C18: the composite fallback derives the target endpoint and approach side
   from the complete target chart. The retained target domain decides the
   side before an isolated scale or coefficient sign, and a flat pole chart
   tends to a signed infinity rather than to its finite offset. *)

approachOf[s_] := AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`seriesEnvelopeApproach[s[[1]], 20000]];

VerificationTest[
 Module[{x, y, reflected, direct, scaled},
  reflected = AsymptoticSpecialInverse["Erfc", {x, -Infinity}, {y, 1}];
  direct = AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 1}];
  scaled = AsymptoticSpecialInverse["Erfc", {x, -Infinity}, {y, 1}, "TargetOffset" -> 7, "TargetScale" -> -2];
  {Lookup[approachOf[reflected], {"Point", "Direction"}], Lookup[approachOf[direct], {"Point", "Direction"}],
   Lookup[approachOf[scaled], {"Point", "Direction"}]}],
 {{2, "FromBelow"}, {0, "FromAbove"}, {3, "FromAbove"}},
 TestID -> "composite-approach-of-the-reflected-erfc-adapter-follows-its-target-domain"]

VerificationTest[
 Module[{x, y, negative, positive, shifted},
  negative = AsymptoticSpecialInverse["QuadraticThreshold", {x, 3}, {y, 2}, "QuadraticCoefficient" -> -3];
  positive = AsymptoticSpecialInverse["QuadraticThreshold", {x, 3}, {y, 2}, "QuadraticCoefficient" -> 3];
  shifted = AsymptoticSpecialInverse["QuadraticThreshold", {x, 3}, {y, 2}, "TargetOffset" -> 7, "TargetScale" -> -2, "QuadraticCoefficient" -> 3];
  {Lookup[approachOf[negative], {"Point", "Direction"}], Lookup[approachOf[positive], {"Point", "Direction"}],
   Lookup[approachOf[shifted], {"Point", "Direction"}]}],
 {{0, "FromBelow"}, {0, "FromAbove"}, {7, "FromBelow"}},
 TestID -> "composite-approach-of-a-quadratic-threshold-follows-the-curvature-and-scale"]

VerificationTest[
 Module[{x, y, regular, pole, negativePole},
  regular = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 2}];
  pole = AsymptoticFlatInverse[1/x + Exp[-1/x], {x, 0}, {y, 2}];
  negativePole = AsymptoticFlatInverse[-1/x + Exp[-1/x], {x, 0}, {y, 2}];
  {Lookup[approachOf[regular], {"Point", "Direction"}], Lookup[approachOf[pole], {"Point", "Direction"}],
   Lookup[approachOf[negativePole], {"Point", "Direction"}],
   Lookup[approachOf[FlatSeriesMultiply[pole, pole]], {"Point", "Direction"}],
   Lookup[approachOf[AsymptoticInverse[1/x + 7, {x, 0}, {y, 2}]], {"Point", "Direction"}],
   Lookup[approachOf[AsymptoticInverse[x + x^2, {x, 0}, {y, 3}, Direction -> "FromBelow"]], {"Point", "Direction"}]}],
 {{0, "FromAbove"}, {Infinity, "FromBelow"}, {-Infinity, "FromAbove"}, {Infinity, "FromBelow"}, {Infinity, "FromBelow"}, {0, "FromBelow"}},
 TestID -> "composite-approach-of-flat-pole-inverses-tends-to-a-signed-infinity"]
