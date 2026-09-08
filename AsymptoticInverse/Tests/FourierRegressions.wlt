(* Finite Fourier modes and independent coefficient/residual checks. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
 Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[
 Module[{x, y, s, expected},
  s = AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 4}];
  expected = y - y^2 Sin[Log[y]] + y^3 Sin[Log[y]] (2 Sin[Log[y]] + Cos[Log[y]]);
  {TrueQ[Simplify[TrigExpand[Normal[s] - expected], y > 0] == 0], s["RemainderPower"], s["RemainderLogDegree"]}],
 {True, 4, 0}, TestID -> "fourier-primary-inverse-example-and-nonoscillatory-remainder"]

VerificationTest[
 Module[{x, y, s},
  s = AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 5}];
  FourierInverseResidual[s]["ZeroBelowCutoff"]],
 True, TestID -> "fourier-independent-normalized-equation-residual"]

VerificationTest[
 Module[{x, y, s, l, expected},
  s = AsymptoticFourierInverse[x + x^2 Sin[Log[x]] + x^3 Cos[2 Log[x]], {x, 0}, {y, 4}];
  l = Log[y]; expected = y - y^2 Sin[l] + y^3 (Sin[l] (2 Sin[l] + Cos[l]) - Cos[2 l]);
  {TrueQ[Simplify[TrigExpand[Normal[s] - expected], y > 0] == 0],
   s["FourierFrequencies"], FourierInverseResidual[s]["ZeroBelowCutoff"]}],
 {True, {-2, -1, 0, 1, 2}, True}, TestID -> "fourier-two-frequency-resonance-combines-direct-and-generated-modes"]

VerificationTest[
 Module[{x, y, s, ell, b, expected},
  b = Sin[ell] + Cos[2 ell];
  s = AsymptoticFourierInverse[x + x^2 (b /. ell -> Log[x]), {x, 0}, {y, 4}];
  expected = y - y^2 (b /. ell -> Log[y]) + y^3 (b (2 b + D[b, ell]) /. ell -> Log[y]);
  {TrueQ[Simplify[TrigExpand[Normal[s] - expected], y > 0] == 0], Length[s["FourierFrequencies"]]}],
 {True, 9}, TestID -> "fourier-convolution-generates-and-merges-mode-sums"]

VerificationTest[
 Module[{ell, modes, expected},
  modes = AsymptoticInverse`Private`fourierReadCoefficient[
    Sin[Sqrt[2] ell] Sin[Sqrt[3] ell] + Cos[Sqrt[5 + 2 Sqrt[6]] ell]/2, ell, True, 20];
  expected = Cos[(Sqrt[2] - Sqrt[3]) ell]/2;
  {Length[modes], TrueQ[FullSimplify[AsymptoticInverse`Private`fourierExpression[modes, ell, True] == expected, Element[ell, Reals]]]}],
 {2, True}, TestID -> "fourier-algebraic-frequency-equality-cancels-a-resonant-pair"]

VerificationTest[
 Module[{ell, modes, derivative, expected},
  modes = AsymptoticInverse`Private`fourierReadCoefficient[(1 + ell) Sin[2 ell] + Cos[ell], ell, True, 20];
  derivative = AsymptoticInverse`Private`fourierEuler[modes, ell, True, 20];
  expected = Sin[2 ell] + 2 (1 + ell) Cos[2 ell] - Sin[ell];
  TrueQ[Simplify[TrigExpand[AsymptoticInverse`Private`fourierExpression[derivative, ell, True] - expected], Element[ell, Reals]] == 0]],
 True, TestID -> "fourier-euler-derivative-agrees-with-direct-trigonometric-differentiation"]

VerificationTest[
 Module[{x, y, s, ell, b, expected},
  b = ell Sin[ell];
  s = AsymptoticFourierInverse[x + x^2 Log[x] Sin[Log[x]], {x, 0}, {y, 4}];
  expected = y - y^2 (b /. ell -> Log[y]) + y^3 (b (2 b + D[b, ell]) /. ell -> Log[y]);
  {TrueQ[Simplify[TrigExpand[Normal[s] - expected], y > 0] == 0],
   s["RemainderLogDegree"], FreeQ[s["RemainderScaleExpression"], Sin | Cos]}],
 {True, 3, True}, TestID -> "fourier-polynomial-amplitudes-use-degree-envelopes"]

VerificationTest[
 Module[{x, y}, AsymptoticFourierInverse[x Sin[Log[x]] + x^2, {x, 0}, {y, 4}]],
 Failure["OscillatoryLeadingBlock", _Association], SameTest -> MatchQ,
 TestID -> "fourier-oscillatory-leading-block-is-not-assigned-an-eventual-sign"]

VerificationTest[
 Module[{x, y}, AsymptoticFourierInverse[x (2 + Sin[Log[x]]) + x^2, {x, 0}, {y, 4}]],
 Failure["OscillatoryLeadingBlock", _Association], SameTest -> MatchQ,
 TestID -> "fourier-positive-periodic-leading-core-is-outside-monomial-core-contract"]

VerificationTest[
 Module[{x, y}, AsymptoticFourierInverse[x + x^2 Sin[Log[x]^2], {x, 0}, {y, 4}]],
 Failure["UnsupportedFourierScale", _Association], SameTest -> MatchQ,
 TestID -> "fourier-nonlinear-logarithmic-phase-is-rejected"]

VerificationTest[
 Module[{x, y, s, ell, b, expected},
  b = Sin[2 ell + 1];
  s = AsymptoticFourierInverse[x + x^2 (b /. ell -> Log[x]), {x, 0}, {y, 4}];
  expected = y - y^2 (b /. ell -> Log[y]) + y^3 (b (2 b + D[b, ell]) /. ell -> Log[y]);
  TrueQ[Simplify[TrigExpand[Normal[s] - expected], y > 0] == 0]],
 True, TestID -> "fourier-affine-phase-includes-exact-phase-shifts"]

VerificationTest[
 Module[{x, y, s, v, expected},
  s = AsymptoticFourierInverse[2 + x - 3 + (x - 3)^2 Sin[Log[x - 3]], {x, 3}, {y, 4}];
  v = y - 2;
  expected = 3 + v - v^2 Sin[Log[v]] + v^3 Sin[Log[v]] (2 Sin[Log[v]] + Cos[Log[v]]);
  TrueQ[Simplify[TrigExpand[Normal[s] - expected], y > 2] == 0]],
 True, TestID -> "fourier-source-and-target-translations-preserve-the-logarithmic-coordinate"]

VerificationTest[
 Module[{x, y, s},
  s = AsymptoticFourierInverse[x + Sin[Log[x]]/x, {x, Infinity}, {y, 3}];
  {TrueQ[Simplify[Normal[s] - (y - Sin[Log[y]]/y), y > 1] == 0],
   FourierInverseResidual[s]["ZeroBelowCutoff"], s["RemainderPower"]}],
 {True, True, 3}, TestID -> "fourier-infinity-coordinate-reconstructs-the-original-variable"]

VerificationTest[
 Module[{x, y, s, coefficient, ell},
  s = AsymptoticFourierInverse[x^2 + x^3 Sin[Log[x]], {x, 0}, {y, 3}, "Power" -> 2];
  coefficient = FourierInverseCoefficient[s, {1}]; ell = coefficient["LogVariable"];
  {TrueQ[Simplify[coefficient["Expression"] + Sin[ell], Element[ell, Reals]] == 0],
   FourierInverseResidual[s]["ZeroBelowCutoff"]}],
 {True, True}, TestID -> "fourier-nonunit-leading-power-and-observable-reconstruct-for-residual"]

VerificationTest[
 Module[{x, y}, AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 4}, "MaxFrequencies" -> 4]],
 Failure["FrequencyLimit", _Association], SameTest -> MatchQ,
 TestID -> "fourier-frequency-budget-is-enforced-across-retained-blocks"]

VerificationTest[
 Module[{x, y}, AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 4}, "InputRemainder" -> {3, 0}]],
 Failure["InsufficientInputOrder", _Association], SameTest -> MatchQ,
 TestID -> "fourier-input-remainder-caps-target-precision"]

VerificationTest[
 Module[{x, y, s},
  s = AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 3}, "InputRemainder" -> {3, 2}];
  {s["RemainderPower"], s["RemainderLogDegree"], s["ExactModel"], FourierInverseResidual[s]["ZeroBelowCutoff"]}],
 {3, 2, False, True}, TestID -> "fourier-input-logarithmic-envelope-is-retained-at-the-precision-cap"]

VerificationTest[
 Module[{ell, modes, envelope},
  modes = AsymptoticInverse`Private`fourierReadCoefficient[ell Sin[ell], ell, True, 10];
  envelope = AsymptoticInverse`Private`fourierEnvelope[modes, ell, 1 + Abs[ell], True];
  {TrueQ[Simplify[envelope == 1 + Abs[ell], Element[ell, Reals]]], envelope /. ell -> -Pi}],
 {True, 1 + Pi},
 TestID -> "fourier-envelope-does-not-vanish-at-an-oscillatory-zero"]

VerificationTest[
 Module[{ell}, AsymptoticInverse`Private`catch[
   AsymptoticInverse`Private`fourierCoefficient[{1000000}, {1}, {{{0, 1}}}, 1, 1, ell, True, 100, 10]]],
 Failure["ResourceLimit", _Association], SameTest -> MatchQ,
 TestID -> "fourier-individual-coefficient-depth-has-an-explicit-resource-budget"]

VerificationTest[
 Module[{ell}, AsymptoticInverse`Private`catch[
   AsymptoticInverse`Private`fourierComposeBlock[{{1, {{0, 1}}}}, -1, {{0, 1}}, 1000,
    ell, True, 10, 10]]],
 Failure["ResourceLimit", _Association], SameTest -> MatchQ,
 TestID -> "fourier-large-residual-composition-has-an-explicit-resource-budget"]

VerificationTest[
 Module[{ell, modes},
  modes = AsymptoticInverse`Private`fourierReadCoefficient[(1 + ell^2) Sin[ell], ell, True, 10];
  AsymptoticInverse`Private`fourierRealQ[modes, ell, True, 10]],
 True, TestID -> "fourier-conjugacy-localizes-the-real-logarithm-before-polynomial-validation"]

VerificationTest[
 {AsymptoticFourierInverse[1], FourierInverseResidual[1], FourierInverseCoefficient[1, {0}]} /. Failure[tag_, _Association] :> tag,
 {"InvalidArguments", "InvalidArguments", "InvalidArguments"},
 TestID -> "fourier-public-apis-return-failures-for-malformed-calls"]
