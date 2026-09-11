(* Polynomial monotonicity certificate (wave-5 report 43 E01). The native
   kernel warns about multivalued inverses while evaluating the inputs; the
   package selects the branch itself, so the warning is silenced. A rational
   polynomial body whose derivative has real zeros of even multiplicity is
   still strictly monotone on the whole real line; the exact Sturm
   certificate decides it where the sign proofs fail, on both kernels. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
  Module[{t, a, certify},
    certify[body_] := With[{c = AsymptoticAnalysis`Private`inverseBranchPolynomialMonotonicity[body, t]},
      If[AssociationQ[c], {c["Type"], c["Sign"], c["StationaryRealRoots"]}, c]];
    {certify[t - 2 t^3/3 + t^5/5], certify[t + t^3], certify[t^3], certify[-t - t^3],
     certify[t - t^3], certify[t^2], certify[5], certify[t^2 (t - 1)^2 (t + 2)^3],
     certify[t^7/7 - 2 t^5/5 + t^3/3 + t], certify[t^3/3 + a t]}],
  {{"PolynomialSturmCertificate", 1, 2}, {"PolynomialSturmCertificate", 1, 0}, {"PolynomialSturmCertificate", 1, 1},
   {"PolynomialSturmCertificate", -1, 0}, None, None, None, None, {"PolynomialSturmCertificate", 1, 0}, None},
  TestID -> "polynomial-monotonicity-certificate-decides-even-multiplicity-stationary-points"]

(* The fixtures' derivatives: (1 - t^2)^2 for the quintic (two double real
   zeros, hence two stationary points and strict monotonicity), and
   (t^2 - 1)^2 t^2 + 1 for the septic (positive everywhere, no stationary
   point, but the strict sign proof of a sextic is beyond FullSimplify on
   Mathics, so the certificate is what decides it there). *)
VerificationTest[
  Module[{t},
    {Factor[D[t - 2 t^3/3 + t^5/5, t]], Expand[D[t^7/7 - 2 t^5/5 + t^3/3 + t, t] - ((t^2 - 1)^2 t^2 + 1)]}],
  {(-1 + t)^2 (1 + t)^2, 0} /. t -> _Symbol, SameTest -> MatchQ,
  TestID -> "polynomial-monotonicity-certificate-fixtures-have-the-stated-derivatives"]

VerificationTest[
  Module[{x, t, s},
    s = Quiet[AsymptoticExpansion[ConditionalExpression[InverseFunction[Function[t, t - 2 t^3/3 + t^5/5]][x], x > 0], {x, 0, 6}], InverseFunction::ifun];
    {MatchQ[s, _GeneralizedSeries], Expand[Normal[s] - (x + 2 x^3/3 + 17 x^5/15)], s["RemainderPower"]}],
  {True, 0, 7},
  TestID -> "polynomial-monotonicity-certificate-expands-the-quintic-inverse-with-two-stationary-points"]

VerificationTest[
  Module[{x, t, s},
    s = Quiet[AsymptoticExpansion[InverseFunction[Function[t, t^3 + 3 t^2 + 3 t]][x], {x, Infinity, 2}, "Backend" -> "Package"], InverseFunction::ifun];
    {MatchQ[s, _GeneralizedSeries], Expand[Normal[s] - (x^(1/3) - 1 + x^(-2/3)/3 - x^(-5/3)/9)]}],
  {True, 0},
  TestID -> "polynomial-monotonicity-certificate-admits-a-cubic-with-a-double-stationary-point-at-infinity"]
