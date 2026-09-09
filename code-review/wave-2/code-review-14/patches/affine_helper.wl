(* Proposed private helper for InverseCertificates.wl. Native-unverified.
   Recognize rational affine trees before any intermediate interval rounding.
   The pair {a,b} denotes a*x+b. Nonlinear/unsupported trees fail conservatively. *)
certAuditAffinePair[e_, x_Symbol] := Module[{pairs, acc, next},
  Which[e === x, {1, 0}, certRationalQ[e], {0, e},
    Head[e] === Plus,
      pairs = certAuditAffinePair[#, x] & /@ (List @@ e);
      If[MemberQ[pairs, $Failed], $Failed, Total[pairs]],
    Head[e] === Times,
      pairs = certAuditAffinePair[#, x] & /@ (List @@ e);
      If[MemberQ[pairs, $Failed], Return[$Failed, Module]];
      acc = {0, 1};
      Do[If[acc[[1]] pair[[1]] =!= 0, Return[$Failed, Module]];
        next = {acc[[1]] pair[[2]] + acc[[2]] pair[[1]], acc[[2]] pair[[2]]};
        acc = next, {pair, pairs}]; acc,
    True, $Failed]];
certAuditAffineRange[e_, x_Symbol, interval_, ctx_] := Module[{pair},
  pair = certAuditAffinePair[e, x];
  If[pair === $Failed, $Failed,
    certRoundInterval[Sort[pair[[1]] interval + pair[[2]]], ctx]]];
