(* SOURCE-EDIT FRAGMENTS, not a loadable patch. Unexecuted candidate.
   File: src/Kernel/InverseCertificates.wl, pinned review snapshot.
   Insertions preserve the existing Failure tag and diagnostic fields. *)

(* 1. In certAttempt's FIRST OutsideBranch failure, add this association field:
   exact rational/infinite source-side checks cannot improve with arithmetic. *)
"ArithmeticRetryable" -> If[
  certRationalQ[a["ExpansionPoint"]] ||
    MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], False, Automatic]

(* 2. In certEnclose's FINAL UnsupportedEnclosure failure, add: *)
"ArithmeticRetryable" -> False

(* 3. In InverseCertificate, immediately AFTER appending the current attempt
   to history and BEFORE retry planning, add the following statement. *)
If[FailureQ[result] &&
    SameQ[Lookup[result[[2]], "ArithmeticRetryable", Automatic], False],
  Return[Failure[result[[1]], Join[result[[2]],
    <|"History" -> history,
      "StoppingReason" -> "NonRefinableArithmeticFailure",
      "Refinements" -> iteration|>,
    If[AssociationQ[best], <|"BestCertificate" -> best|>, <||>]]], Module]];

(* Do NOT classify every OutsideBranch/IntervalDomain/DerivativeNotSeparated
   failure as permanent: some arise from finite-precision over-enclosures.
   An unknown retryability value retains the existing retry behavior. *)
