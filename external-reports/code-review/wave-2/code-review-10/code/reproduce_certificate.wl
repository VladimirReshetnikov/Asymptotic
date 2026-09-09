(* Load the pinned, UNMODIFIED package in a fresh kernel first. *)
Block[{$Assumptions = True}, Module[{x, y, s, clean, polluted},
 s = AsymptoticInverse`AsymptoticInverse[
   ConditionalExpression[x + x^2, x < 1/4], {x, 0}, {y, 3}];
 clean = AsymptoticInverse`InverseCertificate[s, 2,
   "Interval" -> {9/10, 11/10}, "Center" -> 1];
 polluted = Block[{$Assumptions = x < 1/4},
   AsymptoticInverse`InverseCertificate[s, 2,
     "Interval" -> {9/10, 11/10}, "Center" -> 1]];
 <|"Clean" -> clean, "Polluted" -> polluted|>
]]
