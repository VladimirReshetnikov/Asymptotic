(* Desired-contract specifications. UNEXECUTED during this review.
   Load AsymptoticAnalysis and ScopeGammaAdapterDerivativeBounds.wl first.
   Branch contract tests permit refusal or the independently identified root.
   Their failures on an unchanged baseline are not infrastructure failures. *)
VerificationTest[
  Module[{s, evidence},
    s = AsymptoticAnalysis`AsymptoticInverse[
      x + 8 x^2 - 16 x^3, {x, 0}, {y, 2}];
    evidence = AsymptoticAnalysis`InverseNumericalCheck[s, 1/2, WorkingPrecision -> 50];
    FailureQ[evidence] || (AssociationQ[evidence] &&
      (Lookup[evidence, "ReferenceBranchStatus", None] === "Unverified" ||
       TrueQ[Abs[Lookup[evidence, "ReferenceRoot", Infinity] - 1/4] < 10^-30]))
  ], True, TestID -> "N1-cubic-do-not-accept-remote-root-as-germ-reference"]

VerificationTest[
  Module[{s, evidence},
    s = AsymptoticAnalysis`AsymptoticInverse[
      384 x^4 - 304 x^3 + 56 x^2 + x, {x, 0}, {y, 2}];
    evidence = AsymptoticAnalysis`InverseNumericalCheck[s, 1/2, WorkingPrecision -> 50];
    FailureQ[evidence] || (AssociationQ[evidence] &&
      (Lookup[evidence, "ReferenceBranchStatus", None] === "Unverified" ||
       TrueQ[Abs[Lookup[evidence, "ReferenceRoot", Infinity] - 1/8] < 10^-30]))
  ], True, TestID -> "N1-quartic-derivative-sign-is-not-enough"]

VerificationTest[
  Module[{s, fixed, contract},
    s = AsymptoticAnalysis`AsymptoticSpecialInverse[
      "LogGamma", {x, Infinity}, {y, 1}, "TargetScale" -> 1/2];
    fixed = AsymptoticAudit`ScopeGammaAdapterDerivativeBounds[s];
    contract = fixed["DerivativeBoundContract"];
    TrueQ[FullSimplify[contract["LowerBound"] ==
      (Log[x] - 1/(2 x) - 1/(12 x^2))/2, x > 2]] &&
      ! KeyExistsQ[fixed[[1]], "OriginalDerivativeLowerBound"]
  ], True, TestID -> "N2-half-scale-bound-is-transported-and-scoped"]

VerificationTest[
  Module[{s, fixed, contract},
    s = AsymptoticAnalysis`AsymptoticSpecialInverse[
      "Gamma", {x, Infinity}, {y, 1}, "TargetScale" -> -1];
    fixed = AsymptoticAudit`ScopeGammaAdapterDerivativeBounds[s];
    contract = fixed["DerivativeBoundContract"];
    contract["DerivativeSign"] === -1 &&
      TrueQ[FullSimplify[contract["LowerBound"] ==
        Gamma[x] (Log[x] - 1/(2 x) - 1/(12 x^2)), x > 2]]
  ], True, TestID -> "N2-gamma-negative-scale-separates-sign-and-magnitude"]

VerificationTest[
  Module[{s, fixed},
    s = AsymptoticAnalysis`AsymptoticSpecialInverse[
      "LogGamma", {x, Infinity}, {y, 1}, "TargetScale" -> 1/2];
    fixed = AsymptoticAudit`ScopeGammaAdapterDerivativeBounds[s];
    Normal[fixed] === Normal[s] && fixed["Remainder"] === s["Remainder"] &&
      fixed["Function"] === s["Function"]
  ], True, TestID -> "N2-helper-does-not-alter-expansion-or-equation"]

VerificationTest[
  Normal[AsymptoticAnalysis`AsymptoticInverse[
    x + 8 x^2 - 16 x^3, {x, 0}, {y, 2}]],
  y, TestID -> "N1-cubic-construction-positive-control"]

VerificationTest[
  Normal[AsymptoticAnalysis`AsymptoticInverse[
    384 x^4 - 304 x^3 + 56 x^2 + x, {x, 0}, {y, 2}]],
  y, TestID -> "N1-quartic-construction-positive-control"]
