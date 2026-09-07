(* Educational formula from Appendix A; NOT the validated package API.
   Assumes the positive near-identity inverse and the analytic homotopy
   hypotheses. n is perturbation depth, not an output-exponent cutoff.
   No branch validation, model parsing or remainder metadata is performed.
   Native execution was unavailable during preparation.
   SPDX-License-Identifier: MIT *)
Clear[NearIdentityInverse];
NearIdentityInverse[f_, {x_Symbol, y_Symbol}, n_Integer] /;
    (n >= 0 && x =!= y) :=
 Module[{h = f - x},
  Expand[y + Total[Table[
    ((-1)^k/Factorial[k] D[h^k, {x, k - 1}]) /. x -> y,
    {k, 1, n}]]]
 ];
