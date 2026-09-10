(* Load a chosen package entry before Get of this file. This probe does not
   download code, mutate package definitions, or assert that a failure is a pass.
   On the reviewed baseline it records the bad remainder. On a repaired package
   the target-dependent request should instead return Failure. *)
If[Length[Names["AsymptoticAnalysis`AsymptoticExponentialCoreInverse"]] == 0,
  Print["Load AsymptoticAnalysis before running this probe."]; Abort[]];
Module[{bad, control, x, y, projection},
  bad = AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
    Exp[x], 1, {x, Infinity}, {y, 1}, "SourceShift" -> -Abs[y]];
  control = AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
    Exp[x], 1, {x, Infinity}, {y, 1}];
  projection[s_] := If[Head[s] === AsymptoticAnalysis`GeneralizedSeries,
    <|"Outcome" -> "GeneralizedSeries",
      "Expression" -> FullSimplify[Normal[s], y > 2],
      "RemainderScaleExpression" -> FullSimplify[s["RemainderScaleExpression"], y > 2],
      "TargetDomain" -> s["TargetDomain"],
      "CoreParameters" -> s["CoreParameters"]|>, s];
  Print[InputForm[<|"KernelVersion" -> $Version, "BadRequest" -> projection[bad],
    "Control" -> projection[control], "ExactInverse" -> Log[y - 1]|>]];
];
