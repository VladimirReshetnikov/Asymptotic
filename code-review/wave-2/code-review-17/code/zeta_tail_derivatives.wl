(* SPDX-License-Identifier: MIT-0
   Analytically derived bound for fixed-order derivatives of a Zeta tail.
   This is an independent proposal, NOT an installed package API or a
   rational-interval certificate. See the proof and conditions in the article. *)
ClearAll[ZetaTailDerivativeBound];
ZetaTailDerivativeBound[m_Integer?Positive, 0, s_] :=
  ConditionalExpression[m^(-s) (1 + m/(s - 1)), Element[s, Reals] && s > 1];
ZetaTailDerivativeBound[m_Integer?Positive, j_Integer?Positive, s_] := Module[
  {first = Max[m, 2], ell},
  ell = Log[first];
  ConditionalExpression[
    first^(-s) ell^j + first^(1 - s) Sum[
      Factorial[j]/Factorial[j - k] ell^(j - k)/(s - 1)^(k + 1), {k, 0, j}],
    Element[s, Reals] && s > 1 && s ell >= j]];
ZetaTailDerivativeBound[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use positive integer first omitted n, nonnegative integer derivative order, and a real source exponent."|>];
