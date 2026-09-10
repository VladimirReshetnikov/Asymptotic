(* Wave-5 report 37 F01 (with retired 40 and 41): the signed-real modulus
   shortcut applies only to provably real retained coefficients; a nonreal
   jet is handled by the norm square on the real coordinate and its positive
   root. Report 42 N01: a modulus of a nonzero remainder keeps a magnitude
   bound but no classical derivative contract. *)

VerificationTest[
 Module[{x, a, cancellation, squared, differenceAtI},
  cancellation = AsymptoticExpansion[Abs[1 + a x] + Abs[1 - a x] - 2, {x, 0, 4}, "Backend" -> "Package", Assumptions -> a^2 == -1];
  squared = AsymptoticExpansion[Abs[1 + a x]^2 + Abs[1 - a x]^2, {x, 0, 4}, "Backend" -> "Package", Assumptions -> a^2 == -1];
  differenceAtI[s_, exact_] := And @@ (TrueQ[Simplify[(Normal[s] /. a -> #) - exact == 0, x > 0]] & /@ {I, -I});
  {MatchQ[cancellation, _GeneralizedSeries], cancellation["RemainderPower"], cancellation["Exact"],
   differenceAtI[cancellation, x^2], Simplify[Normal[cancellation] - x^2 (Abs[a]^2 - Re[a]^2)] === 0,
   MatchQ[squared, _GeneralizedSeries], differenceAtI[squared, 2 + 2 x^2],
   Simplify[Normal[squared] - (2 + 2 Abs[a]^2 x^2)] === 0}],
 {True, 4, False, True, True, True, True, True},
 TestID -> "modulus-of-nonreal-jets-uses-the-norm-square-instead-of-the-sign-rule"]

VerificationTest[
 Module[{x, a, boundary, unproved},
  boundary = AsymptoticExpansion[Abs[Log[x] + a] + Abs[Log[x] - a], {x, 0, 2}, "Backend" -> "Package", Assumptions -> a^2 == -1];
  unproved = AsymptoticExpansion[Abs[a + x], {x, 0, 3}, "Backend" -> "Package"];
  {boundary[[1]], MatchQ[unproved, _Failure]}],
 {"LogarithmicLeadingPower", True},
 TestID -> "modulus-with-a-nonconstant-nonreal-logarithmic-leading-block-is-refused"]

VerificationTest[
 Module[{x, a, control, squaredControl, negative, logarithmic},
  control = AsymptoticExpansion[Abs[1 + a x] + Abs[1 - a x] - 2, {x, 0, 4}, "Backend" -> "Package", Assumptions -> Element[a, Reals]];
  squaredControl = AsymptoticExpansion[Abs[1 + a x]^2 + Abs[1 - a x]^2, {x, 0, 4}, "Backend" -> "Package", Assumptions -> Element[a, Reals]];
  negative = AsymptoticExpansion[Abs[-2 + x], {x, 0, 3}, "Backend" -> "Package"];
  logarithmic = AsymptoticExpansion[Abs[Log[x] + 1], {x, 0, 2}, "Backend" -> "Package"];
  {Normal[control], control["Remainder"], Simplify[Normal[squaredControl] - (2 + 2 a^2 x^2)] === 0,
   Normal[negative] === 2 - x, Normal[logarithmic] === -1 - Log[x], logarithmic["Remainder"]}],
 {0, 0, True, True, True, 0},
 TestID -> "modulus-sign-rule-is-unchanged-for-provably-real-coefficients"]

VerificationTest[
 Module[{x, z, exact, declared, absolute},
  exact = AsymptoticExpansion[1 + x, {x, 0, 3}, "Backend" -> "Package"];
  declared = GeneralizedSeries[Join[AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Package"][[1]],
    <|"RemainderDerivativeOrder" -> 3|>]];
  absolute = SeriesObservable[exact, Abs[z], z];
  {Normal[absolute] === 1 + x, absolute["Remainder"], absolute["RemainderDerivativeOrder"],
   declared["Remainder"] =!= 0,
   SeriesObservable[declared, z + z^2, z]["RemainderDerivativeOrder"],
   SeriesObservable[declared, Abs[z], z]["RemainderDerivativeOrder"],
   Normal[SeriesObservable[declared, Abs[z], z]] === 1 + x + x^2/2}],
 {True, 0, Infinity, True, 3, 0, True},
 TestID -> "modulus-of-a-nonzero-remainder-keeps-magnitude-but-drops-the-derivative-contract"]

(* Report 42's public chain: a pure remainder with a declared derivative
   contract, differentiated once, then passed through Abs. The magnitude bound
   survives; a further derivative of the modulus is refused. *)
VerificationTest[
 Module[{x, y, z, s, identity, remainder, differentiated, absolute, control},
  s = AsymptoticInverse[x, {x, 0}, {y, 2}, "InputRemainder" -> {3, 0}];
  identity = AsymptoticExpansion[y, {y, 0, 4}, "Backend" -> "Package"];
  remainder = SeriesAdd[s, SeriesMultiply[identity, -1]];
  differentiated = SeriesDifferentiate[remainder, 1, "RemainderDerivativeOrder" -> 2];
  absolute = SeriesObservable[differentiated, Abs[z], z];
  control = SeriesObservable[AsymptoticExpansion[-y - y^2, {y, 0, 4}, "Backend" -> "Package"], Abs[z], z];
  {MatchQ[differentiated, _GeneralizedSeries], differentiated["RemainderDerivativeOrder"],
   MatchQ[absolute, _GeneralizedSeries], absolute["RemainderDerivativeOrder"],
   absolute["RemainderPower"] === differentiated["RemainderPower"],
   SeriesDifferentiate[absolute][[1]],
   Normal[control] === y + y^2, control["Remainder"], Normal[SeriesDifferentiate[control]] === 1 + 2 y}],
 {True, 1, True, 0, True, "UnprovedRemainderDerivative", True, 0, True},
 TestID -> "modulus-of-a-differentiated-pure-remainder-refuses-a-further-derivative"]
