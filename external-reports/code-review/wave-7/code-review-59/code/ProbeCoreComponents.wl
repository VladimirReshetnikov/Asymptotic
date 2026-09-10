(* UNEXECUTED integration probe. Load the chosen package entry first.
   No network access, automatic package load, or repository modification.
   The plain-y variant is a diagnostic control, NOT the principal witness. *)
Begin["ReviewCoreComponents`"];
ClearAll[x, y, z, ell, project, report];
Print[InputForm[<|"Probe" -> "Core component dependence", "Version" -> $Version|>]];
project[result_, power_] := If[Head[result] === AsymptoticAnalysis`GeneralizedSeries,
  <|"Head" -> Head[result], "Expression" -> Normal[result],
    "TargetDomain" -> result["TargetDomain"],
    "Remainder" -> result["Remainder"],
    "Envelope" -> result["RemainderScaleExpression"],
    "ErrorOnPositiveRay" -> FullSimplify[y^power - Normal[result], y > 8],
    "EnvelopeOnPositiveRay" -> FullSimplify[result["RemainderScaleExpression"], y > 8],
    "Model" -> result["CoreModel"]|>,
  <|"Head" -> Head[result], "Result" -> result|>];
Print[InputForm[<|"AbsCoefficientRealness" ->
  FullSimplify[Element[Abs[y]/2, Reals]],
  "InternalCoefficientRealness" ->
    AsymptoticAnalysis`Private`realPolynomialCondition[Abs[y]/2, ell, True]|>]];
report = AsymptoticAnalysis`AsymptoticCoreInverse[
  x + Abs[y]/2, -Abs[y]/2, {x, Infinity}, {y, 0}];
Print[InputForm[<|"Case" -> "N01-depth0", "Projection" -> project[report, 1]|>]];
report = AsymptoticAnalysis`AsymptoticCoreInverse[
  x + Abs[y]/2, -Abs[y]/2, {x, Infinity}, {y, 1}, "Power" -> 2];
Print[InputForm[<|"Case" -> "N01-depth1-square", "Projection" -> project[report, 2]|>]];
report = AsymptoticAnalysis`AsymptoticCoreInverse[
  x + y/2, -y/2, {x, Infinity}, {y, 0}];
Print[InputForm[<|"Case" -> "Plain-target-reality-control", "Projection" -> project[report, 1]|>]];
report = AsymptoticAnalysis`AsymptoticCoreInverse[
  x + 2, -2, {x, Infinity}, {y, 0}];
Print[InputForm[<|"Case" -> "Fixed-offset-control", "Projection" -> project[report, 1]|>]];
report = AsymptoticAnalysis`AsymptoticCoreInverse[
  x, 1/x, {x, Infinity}, {y, 1}];
Print[InputForm[<|"Case" -> "Fixed-source-perturbation-control", "Projection" -> project[report, 1]|>]];
End[];
