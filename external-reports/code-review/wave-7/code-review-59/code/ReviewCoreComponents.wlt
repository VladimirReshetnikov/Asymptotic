(* UNEXECUTED desired-contract MUnit tests for the repaired package.
   Run only after loading a chosen package entry into a fresh Wolfram kernel.
   No TestReport run took place during this audit. *)
Begin["ReviewCoreComponentsTests`"];
ClearAll[x, y, a, target, badTargetQ, expressionEqualsQ];
badTargetQ[s_] := MatchQ[s, Failure["InvalidVariables", _Association]];
expressionEqualsQ[s_, expected_, ass_] :=
  Head[s] === AsymptoticAnalysis`GeneralizedSeries &&
  TrueQ[FullSimplify[Normal[s] == expected, ass]];

VerificationTest[
 badTargetQ[AsymptoticAnalysis`AsymptoticCoreInverse[
  x + Abs[y]/2, -Abs[y]/2, {x, Infinity}, {y, 0}]], True,
 TestID -> "N01-cancelled-target-depth-zero"]
VerificationTest[
 badTargetQ[AsymptoticAnalysis`AsymptoticCoreInverse[
  x + Abs[y]/2, -Abs[y]/2, {x, Infinity}, {y, 1}, "Power" -> 2]], True,
 TestID -> "N01-cancelled-target-powered-depth-one"]
VerificationTest[
 badTargetQ[AsymptoticAnalysis`AsymptoticCoreInverse[
  x + Abs[y]/4, -Abs[y]/4, {x, Infinity}, {y, 2}, "Power" -> 4]], True,
 TestID -> "N01-target-quarter-powered"]
VerificationTest[
 badTargetQ[AsymptoticAnalysis`AsymptoticCoreInverse[
  x + Re[y]/2, -Re[y]/2, {x, Infinity}, {y, 0}]], True,
 TestID -> "N01-real-part-target"]
VerificationTest[
 badTargetQ[AsymptoticAnalysis`AsymptoticCoreInverse[
  x + Abs[target]/2, -Abs[target]/2, {x, Infinity}, {target, 0}]], True,
 TestID -> "N01-alpha-renamed-target"]
VerificationTest[
 badTargetQ[AsymptoticAnalysis`AsymptoticCoreInverse[
  x, 0, {x, Infinity}, {x, 0}]], True,
 TestID -> "N01-existing-distinct-symbol-guard"]
VerificationTest[
 MatchQ[AsymptoticAnalysis`AsymptoticCoreInverse[
  x + 0.5, -0.5, {x, Infinity}, {y, 0}], Failure["InexactInput", _Association]], True,
 TestID -> "N01-component-exactness-before-cancellation"]
VerificationTest[
 MatchQ[AsymptoticAnalysis`AsymptoticCoreInverse[
  x + I, -I, {x, Infinity}, {y, 0}], Failure["InexactInput", _Association]], True,
 TestID -> "N01-component-complex-constant-screen"]
VerificationTest[
 expressionEqualsQ[AsymptoticAnalysis`AsymptoticCoreInverse[
  x + 2, -2, {x, Infinity}, {y, 0}], y - 2, y > 8], True,
 TestID -> "N01-fixed-offset-depth-zero-control"]
VerificationTest[
 expressionEqualsQ[AsymptoticAnalysis`AsymptoticCoreInverse[
  x + 2, -2, {x, Infinity}, {y, 1}], y, y > 8], True,
 TestID -> "N01-fixed-offset-depth-one-control"]
VerificationTest[
 expressionEqualsQ[AsymptoticAnalysis`AsymptoticCoreInverse[
  x + a, -a, {x, Infinity}, {y, 1}, Assumptions -> Element[a, Reals]],
  y, y > Abs[a] + 8 && Element[a, Reals]], True,
 TestID -> "N01-fixed-parameter-not-forbidden"]
VerificationTest[
 expressionEqualsQ[AsymptoticAnalysis`AsymptoticCoreInverse[
  x, 1/x, {x, Infinity}, {y, 1}], y - 1/y, y > 8], True,
 TestID -> "N01-ordinary-higher-source-power-control"]
End[];
