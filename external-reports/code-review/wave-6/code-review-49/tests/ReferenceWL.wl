(* UNEXECUTED portable reference tests; load code/LerchEnclosure.wl first. *)
If[DownValues[AsymptoticAuditLerch`LerchRationalEnclosure] === {},
  Print["Load code/LerchEnclosure.wl first."],
  Module[{r, lo, hi, q, upper, k = 256, failures = {}, count = 0, z, a, s, n},
    Do[
      r = AsymptoticAuditLerch`LerchRationalEnclosure[z,s,a,n];
      {lo,hi} = r["Interval"];
      q = Sum[z^j/(a+j)^s, {j,0,k-1}];
      upper = q + z^k/((a+k)^s (1-z));
      count++;
      If[! TrueQ[lo <= q <= upper <= hi], AppendTo[failures,{z,s,a,n}]],
      {z,{1/5,1/2,3/4}}, {a,{1,10,100}}, {s,{1,2}}, {n,0,5}];
    Print[<|"Kernel"->$Version, "Cases"->count, "Failures"->failures|>]
  ]
];
