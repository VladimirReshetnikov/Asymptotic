(* Numerical inverse checks solve in the local source coordinate, so a small
   displacement at a huge source origin is neither lost nor misjudged. *)

VerificationTest[
 Module[{x, y, a = 10^100, s, c, exact},
  s = AsymptoticInverse[(x - a) + (x - a)^2, {x, a}, {y, 4}];
  c = InverseNumericalCheck[s, 1/1000, WorkingPrecision -> 50];
  exact = 2/1000/(1 + Sqrt[1 + 4/1000]);
  {AssociationQ[c], c["SourceOffset"], c["SourceSide"],
   TrueQ[Abs[c["LocalRoot"] - exact] < 10^-45], Precision[c["LocalRoot"]] >= 50,
   TrueQ[c["ReferenceRoot"] - a == c["LocalRoot"]], Precision[c["ReferenceRoot"]] > 150,
   TrueQ[Abs[c["Error"] - Abs[exact - (1/1000 - 1/1000^2 + 2/1000^3)]] < 10^-40],
   TrueQ[c["Ratio"] < 10], TrueQ[Abs[c["RootResidual"]] < 10^-45]}],
 {True, 10^100, 1, True, True, True, True, True, True, True},
 TestID -> "numerical-check-huge-source-offset-is-solved-in-the-local-displacement"]

VerificationTest[
 Module[{x, y, a = 10^100, s, c},
  s = AsymptoticInverse[(x - a)^3 + (x - a)^4, {x, a}, {y, 2}];
  c = InverseNumericalCheck[s, 1/1000, WorkingPrecision -> 50];
  {AssociationQ[c], TrueQ[Abs[c["LocalRoot"]^3 + c["LocalRoot"]^4 - 1/1000] < 10^-45],
   TrueQ[0 < c["Ratio"] < 1], TrueQ[c["LocalRoot"] > 0], c["SourceDomainVerified"]}],
 {True, True, True, True, True},
 TestID -> "numerical-check-huge-source-offset-with-ramified-observable"]

VerificationTest[
 Module[{x, y, a = 10^100, s, c},
  s = AsymptoticInverse[(a - x) + (a - x)^2, {x, a}, {y, 4}, Direction -> "FromBelow"];
  c = InverseNumericalCheck[s, 1/1000, WorkingPrecision -> 50];
  {AssociationQ[c], c["SourceSide"], TrueQ[c["LocalRoot"] > 0],
   TrueQ[a - c["ReferenceRoot"] == c["LocalRoot"]],
   TrueQ[Abs[c["LocalRoot"] - 2/1000/(1 + Sqrt[1 + 4/1000])] < 10^-45]}],
 {True, -1, True, True, True},
 TestID -> "numerical-check-huge-source-offset-approached-from-below"]

VerificationTest[
 Module[{x, y, s, c, p},
  s = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
  c = InverseNumericalCheck[s, 1/1000, WorkingPrecision -> 50];
  p = AsymptoticInverse[x^2 + x^3, {x, 0}, {y, 3}, "Power" -> 2];
  {c["SourceOffset"], TrueQ[Precision[c["ReferenceRoot"]] == 50], c["ReferenceRoot"] === c["LocalRoot"],
   TrueQ[Abs[c["ReferenceRoot"] - 2/1000/(1 + Sqrt[1 + 4/1000])] < 10^-45],
   c["Error"] === Abs[c["ReferenceObservable"] - c["Approximation"]],
   AssociationQ[InverseNumericalCheck[p, 1/100, WorkingPrecision -> 40]]}],
 {0, True, True, True, True, True},
 TestID -> "numerical-check-zero-offset-fields-are-unchanged-by-the-local-coordinate"]

VerificationTest[
 Module[{x, y, s, c},
  s = AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
  c = InverseNumericalCheck[s, 4, WorkingPrecision -> 30];
  {c["SourceOffset"], c["SourceSide"], TrueQ[Abs[c["ReferenceRoot"] - 2] < 10^-25],
   c["ReferenceRoot"] === c["LocalRoot"], TrueQ[Abs[c["ForwardResidual"]] < 10^-25]}],
 {0, 1, True, True, True},
 TestID -> "numerical-check-at-infinity-uses-the-source-value-as-its-local-coordinate"]

VerificationTest[
 Module[{x, y, a = 10^100, s},
  s = AsymptoticInverse[(x - a) + (x - a)^2, {x, a}, {y, 4}];
  {InverseNumericalCheck[s, -1/1000, WorkingPrecision -> 50][[1]],
   AsymptoticAnalysis`Private`numericalSourceDomainCheck[<|"Variables" -> {x, y}, "SourceDomain" -> x - a > 0|>,
     a + 10^-60, 0, 50, {u, a + u, 10^-60}]}],
 {"OutsideBranch", True},
 TestID -> "numerical-check-domain-conditions-cancel-the-offset-before-numerical-evaluation"]
