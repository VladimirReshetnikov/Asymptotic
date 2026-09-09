(* Independent errors stay independent when two operands are identical.
   Equal finite expressions do not make unequal source data interchangeable. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

envelopeRefactoringFixture[x_, error_, domain_: True] := GeneralizedSeries[<|
  "Kind" -> "Derived", "Scale" -> "Composite", "Expression" -> 1 + x,
  "Remainder" -> error, "Variable" -> x, "Assumptions" -> True,
  "TargetDomain" -> domain, "SeriesApproach" -> <|"Variable" -> x,
    "Point" -> 0, "Direction" -> "FromAbove"|>|>];

VerificationTest[Module[{x, a, sum, product},
  a = envelopeRefactoringFixture[x, PowerLogRemainder[x, 2, 0], x > 0];
  sum = SeriesAdd[a, a]; product = SeriesMultiply[a, a];
  {Normal[sum] === 2 + 2 x, sum["Remainder"] === 2 PowerLogRemainder[x, 2, 0],
    Normal[product] === (1 + x)^2,
    TrueQ[FullSimplify[product["RemainderScaleExpression"] == 2 (1 + x) x^2 + x^4, x > 0]],
    product["CompositeRecipe"]["Operands"] === {a, a}}],
  {True, True, True, True, True},
  TestID -> "envelope-identical-operands-retain-both-errors-and-the-product-error"]

VerificationTest[Module[{x, a, b, sum},
  a = envelopeRefactoringFixture[x, PowerLogRemainder[x, 2, 0], x > 0];
  b = envelopeRefactoringFixture[x, PowerLogRemainder[x, 3, 0], x > 0];
  sum = SeriesAdd[a, b];
  {Normal[sum] === 2 + 2 x,
    sum["Remainder"] === PowerLogRemainder[x, 2, 0] + PowerLogRemainder[x, 3, 0], sum["Exact"]}],
  {True, True, False},
  TestID -> "envelope-equal-finite-expressions-do-not-share-different-errors"]

VerificationTest[Module[{x, a, b},
  a = envelopeRefactoringFixture[x, PowerLogRemainder[x, 2, 0], x > 0];
  b = envelopeRefactoringFixture[x, PowerLogRemainder[x, 2, 0], x < 0];
  MatchQ[SeriesAdd[a, b], Failure["IncompatibleDomains", _Association]]],
  True, TestID -> "envelope-combined-domain-still-rejects-a-new-contradiction"]

VerificationTest[Module[{x, a, result},
  a = envelopeRefactoringFixture[x, PowerLogRemainder[x, 2, 0], x > 0];
  result = SeriesAdd[a, ConditionalExpression[1, x < 1]];
  {Normal[result] === 2 + x, result["Remainder"] === PowerLogRemainder[x, 2, 0],
    TrueQ[FullSimplify[Equivalent[result["TargetDomain"], 0 < x < 1]]]}],
  {True, True, True},
  TestID -> "envelope-exact-conditional-operand-retains-the-new-domain"]

VerificationTest[Module[{x, a},
  a = envelopeRefactoringFixture[x, PowerLogRemainder[x, 2, 0], x > 0 && x < 0];
  MatchQ[SeriesAdd[a, a], Failure["IncompatibleDomains", _Association]]],
  True, TestID -> "envelope-identical-operands-still-validate-the-original-domain"]
