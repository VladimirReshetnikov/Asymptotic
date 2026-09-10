(* EXPERIMENTAL, NATIVE-UNRUN / MATHICS-UNRUN.
   Load only after the pinned package, in a disposable Mathics session.
   This changes one package-private helper, not System`FindRoot.
   The legacy helper name is preserved to avoid changing its consumers.
   A rational reconstruction is only a candidate: exact substitution is proof.
   No claim of a general arbitrary-precision FindRoot implementation is made. *)
If[! (StringQ[$Version] && StringContainsQ[$Version, "Mathics"]),
  Print["ExactSeedCandidate.wl is Mathics-only; no definitions were changed."],
Unprotect[AsymptoticAnalysis`Private`mathicsNumericalExactIntegerSeed];
ClearAll[AsymptoticAnalysis`Private`mathicsNumericalExactIntegerSeed];
SetAttributes[AsymptoticAnalysis`Private`mathicsNumericalExactIntegerSeed, HoldAllComplete];
AsymptoticAnalysis`Private`mathicsNumericalExactIntegerSeed[held_HoldComplete, variable_Symbol, seed_] :=
  System`Block[{variable}, System`Module[{candidate, polynomial, digits, bits, auditTag = Unique["exactSeed$"]},
    System`Catch[
    If[! NumericQ[seed] || ! TrueQ[Im[seed] == 0] ||
        ! FreeQ[seed, Indeterminate | _DirectedInfinity], System`Throw[$Failed, auditTag]];
    (* Retain the existing integer shortcut first. *)
    candidate = Round[seed];
    If[! IntegerQ[candidate] || ! (SameQ[seed, candidate] ||
        SameQ[seed, N[candidate, Precision[seed]]]),
      (* Bound reconstruction input. Unknown/oversized cases keep the old
         conservative refusal. These private limits are proposal policy. *)
      digits = N[Precision[seed]];
      If[! (MatchQ[seed, _Integer | _Rational] ||
          (NumericQ[digits] && TrueQ[0 < digits <= 1000])),
        System`Throw[$Failed, auditTag]];
      If[! TrueQ[seed == 0 || 2^-4096 <= Abs[seed] <= 2^4096],
        System`Throw[$Failed, auditTag]];
      candidate = Quiet[Check[Rationalize[seed, 0], $Failed]];
      If[! MatchQ[candidate, _Integer | _Rational], System`Throw[$Failed, auditTag]];
      bits = Max[IntegerLength[Abs[Numerator[candidate]], 2],
        IntegerLength[Denominator[candidate], 2]];
      If[bits > 4096 || ! (SameQ[seed, candidate] ||
          SameQ[seed, N[candidate, Precision[seed]]]), System`Throw[$Failed, auditTag]]];
    If[! MatchQ[held, HoldComplete[Equal[_, _]]], System`Throw[$Failed, auditTag]];
    polynomial = ReleaseHold[held /. HoldPattern[Equal[left_, right_]] :>
      (left - right)];
    If[! AsymptoticAnalysis`Private`exactQ[polynomial] || ! FreeQ[polynomial, Indeterminate | _DirectedInfinity] ||
        ! PolynomialQ[polynomial, variable], System`Throw[$Failed, auditTag]];
    If[SameQ[polynomial /. variable -> candidate, 0], candidate, $Failed], auditTag]]];
];
