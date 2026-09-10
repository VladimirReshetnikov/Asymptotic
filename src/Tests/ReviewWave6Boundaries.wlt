(* Wave-6 public-boundary repairs: coefficient option spellings (report 48 N1),
   target-dependent SourceShift (46 N01, 50 F1), local numerical field labels
   (48 N3, 51 N02, 54 N04), named numeric constants as coordinates (52 N1),
   the Fourier residual's optional cutoff (52 N2), conditional exact
   observables (52 N3) and affine Dirichlet atoms (55 N01). *)

VerificationTest[
 Module[{x, y, s, k},
  s = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
  k[r_] := Lookup[r, {"Exponent", "Coefficient"}];
  {k[InverseExpansionCoefficient[s, {1}, "Power" -> 2]],
   k[InverseExpansionCoefficient[s, {1}, Power -> 2]],
   k[InverseExpansionCoefficient[s, {1}, Power -> 2, "Power" -> 3]],
   k[InverseExpansionCoefficient[s, {1}, "Power" -> 3, Power -> 2]],
   k[InverseExpansionCoefficient[s, {1}, {"Power" -> 2}]],
   k[InverseExpansionCoefficient[s, {1}, "Power" :> 2]],
   k[InverseExpansionCoefficient[AsymptoticInverse[x + x^2, {x, 0}, {y, 4}, "Power" -> 2], {1}]],
   k[InverseExpansionCoefficient[s, {1}]],
   InverseExpansionCoefficient[s, {1}, "Power" -> 0.5][[1]],
   InverseExpansionCoefficient[s, {1}, Power -> 0][[1]]}],
 {{3, -2}, {3, -2}, {3, -2}, {4, -3}, {3, -2}, {3, -2}, {3, -2}, {2, -1}, "InvalidOption", "InvalidOption"},
 TestID -> "coefficient-power-option-symbol-string-nested-and-delayed-spellings-agree-with-first-option-precedence"]

VerificationTest[
 Module[{x, y, dependent, control, fixed},
  dependent = AsymptoticExponentialCoreInverse[Exp[x], 1, {x, Infinity}, {y, 1}, "SourceShift" -> -Abs[y]];
  control = AsymptoticExponentialCoreInverse[Exp[x], 1, {x, Infinity}, {y, 1}];
  fixed = AsymptoticExponentialCoreInverse[Exp[x], 1, {x, Infinity}, {y, 1}, "SourceShift" -> 3];
  {dependent[[1]], dependent[[2]]["SourceShift"] === -Abs[y],
   MatchQ[control, _GeneralizedSeries], MatchQ[fixed, _GeneralizedSeries],
   TrueQ[Simplify[Normal[fixed] == Normal[control], y > 2]], fixed["SourceShift"],
   AsymptoticExponentialCoreInverse[Exp[x], 1, {x, Infinity}, {y, 1}, "SourceShift" -> x][[1]]}],
 {"TargetDependentSourceShift", True, True, True, True, 3, "InvalidVariables"},
 TestID -> "exponential-core-target-dependent-source-shift-is-refused-while-fixed-shifts-remain-admitted"]

VerificationTest[
 Module[{x, y, powered, plain},
  powered = InverseNumericalCheck[AsymptoticInverse[x, {x, 0}, {y, 3}, "Power" -> 2], 2, WorkingPrecision -> 30];
  plain = InverseNumericalCheck[AsymptoticInverse[x, {x, 0}, {y, 3}], 2, WorkingPrecision -> 30];
  {powered["ObservablePower"], TrueQ[powered["LocalRoot"]^2 == powered["LocalApproximation"]],
   TrueQ[powered["LocalReferenceObservable"] == powered["LocalRoot"]^2],
   StringContainsQ[powered["LocalCoordinate"], "LocalRoot is always the positive source displacement u"],
   StringContainsQ[powered["LocalCoordinate"], "(SourceSide u)^Power"],
   plain["ObservablePower"], TrueQ[plain["LocalReferenceObservable"] == plain["LocalRoot"]],
   TrueQ[plain["LocalApproximation"] == plain["LocalRoot"]]}],
 {2, True, True, True, True, 1, True, True},
 TestID -> "numerical-check-labels-distinguish-the-positive-displacement-from-its-powered-observable"]

VerificationTest[
 Module[{x, y},
  {AsymptoticExpansion[1/(1 + Pi), {Pi, 0, 3}, "Backend" -> "Package"][[1]],
   AsymptoticExpansion[1/(1 + Pi), {Pi, 0, 3}][[1]],
   AsymptoticInverse[x + x^2, {x, 0}, {Pi, 3}][[1]],
   AsymptoticInverse[E + E^2, {E, 0}, {y, 3}][[1]],
   AsymptoticInverse[x + x^2, {x, 0}, {Degree, 3}][[1]],
   MatchQ[AsymptoticExpansion[1/(1 + x), {x, 0, 3}, "Backend" -> "Package"], _GeneralizedSeries],
   MatchQ[AsymptoticInverse[x + x^2, {x, 0}, {y, 3}], _GeneralizedSeries]}],
 {"InvalidVariable", "InvalidVariable", "InvalidVariables", "InvalidVariable", "InvalidVariables", True, True},
 TestID -> "named-numeric-constants-are-refused-as-expansion-and-target-coordinates"]

VerificationTest[
 Module[{x, y, s},
  s = AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 3}];
  {FourierInverseResidual[s, "MaxTerms" -> 5000]["ZeroBelowCutoff"],
   FourierInverseResidual[s, {"MaxTerms" -> 5000}]["ZeroBelowCutoff"],
   FourierInverseResidual[s, Automatic, "MaxTerms" -> 5000]["ZeroBelowCutoff"],
   FourierInverseResidual[s, 2]["RelativeCutoff"],
   FourierInverseResidual[s, 0.5][[1]]}],
 {True, True, True, 2, "InvalidCutoff"},
 TestID -> "fourier-residual-options-without-a-cutoff-are-not-captured-by-the-optional-cutoff"]

VerificationTest[
 Module[{x, z, s, conditional, plain, refused, refined},
  s = AsymptoticExpansion[1/x, {x, 0, 3}, "Backend" -> "Package"];
  conditional = SeriesObservable[s, ConditionalExpression[Exp[z], z > 0], z];
  plain = SeriesObservable[s, Exp[z], z];
  refused = SeriesObservable[s, ConditionalExpression[Exp[z], z < 0], z];
  refined = SeriesRefine[conditional, 5];
  {conditional["Expression"] === plain["Expression"], conditional["Remainder"], conditional["Scale"],
   conditional["SeriesRecipe"][[1]], conditional["ObservableCondition"] === (z > 0), refused[[1]],
   refined["Expression"] === plain["Expression"],
   SeriesObservable[s, ConditionalExpression[Log[z], z > 0], z]["Expression"] === SeriesObservable[s, Log[z], z]["Expression"],
   SeriesObservable[s, ConditionalExpression[z^2, z > 0], z]["Expression"] === SeriesObservable[s, z^2, z]["Expression"]}],
 {True, 0, "Factored", "Observable", True, "IncompatibleObservableCondition", True, True, True},
 TestID -> "conditional-exact-observables-reach-the-exact-route-after-the-condition-is-proved"]

VerificationTest[
 Module[{x, atom, shifted, scaled, lerch, goal},
  atom = AsymptoticExpansion[Zeta[x], {x, Infinity, 2}, "Backend" -> "Package"];
  shifted = AsymptoticExpansion[Zeta[x] - 1, {x, Infinity, 2}, "Backend" -> "Package"];
  scaled = AsymptoticExpansion[-2 Zeta[x] + 3, {x, Infinity, 2}, "Backend" -> "Package"];
  lerch = AsymptoticExpansion[LerchPhi[1/2, 2, x] - 2, {x, Infinity, 3}, "Backend" -> "Package"];
  goal = AsymptoticExpansion[Zeta[x] - 1, x -> Infinity, SeriesTermGoal -> 3];
  {Simplify[Normal[shifted] - (Normal[atom] - 1)] === 0, shifted["ReturnedTermCount"], atom["ReturnedTermCount"],
   shifted["AffineCoefficients"], shifted["SpecialFunctionFamily"], shifted["Remainder"] === atom["Remainder"],
   Simplify[Normal[scaled] - (3 - 2 Normal[atom])] === 0, scaled["AffineCoefficients"],
   KeyExistsQ[scaled[[1]], "RemainderLowerBound"], KeyExistsQ[shifted[[1]], "RemainderLowerBound"],
   TrueQ[Abs[N[(-2 Zeta[10] + 3) - Normal[scaled] /. x -> 10, 40]] <= N[scaled["AbsoluteRemainderBound"] /. x -> 10, 40]],
   TrueQ[Abs[N[(LerchPhi[1/2, 2, 10] - 2) - Normal[lerch] /. x -> 10, 40]] <= N[lerch["AbsoluteRemainderBound"] /. x -> 10, 40]],
   lerch["AffineCoefficients"], lerch["RemainderBoundConstant"],
   Normal[goal] === 2^-x + 3^-x, goal["ReturnedTermCount"], goal["RequestedTermGoal"],
   MatchQ[AsymptoticExpansion[x Zeta[x], {x, Infinity, 2}, "Backend" -> "Package"], _GeneralizedSeries],
   MatchQ[AsymptoticExpansion[Zeta[x] + Zeta[2 x], {x, Infinity, 2}, "Backend" -> "Package"], _GeneralizedSeries]}],
 {True, 6, 7, {1, -1}, "Zeta", True, True, {-2, 3}, False, True, True, True, {1, -2}, 4,
  True, 2, 3, False, False},
 TestID -> "affine-combinations-of-one-dirichlet-atom-are-expanded-with-the-atom"]
