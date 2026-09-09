(* EXPERIMENTAL, NATIVE-UNRUN. Load only in a disposable kernel AFTER loading
   the pinned AsymptoticInverse package. Replaces private pUnitSeries.
   Mathematical proof and limitations are in article/article.pdf.
   This is not a replacement for the complete package or its regression suite. *)

Begin["AsymptoticInverse`Private`"];

Clear[jetMulClosedAudit];
jetMulClosedAudit[u_List, v_List, cut_, ell_, ass_, limit_] := Module[
  {rows, count = 0, weight},
  rows = Reap[
    Do[
      Do[
        weight = canon[a[[1]] + b[[1]]];
        If[less[cut, weight], Break[]];
        count++;
        If[count > limit,
          fail["ResourceLimit", "Closed-boundary convolution exceeded MaxTerms."]];
        Sow[{weight, Expand[a[[2]] b[[2]]]}],
        {b, v}],
      {a, u}]
  ][[2]];
  If[rows === {}, {}, jetMerge[First[rows], ell, ass]]
];

pUnitSeries[U_List, PU_, DU_, cf_, cut_, ell_, ass_, limit_] := Module[
  {c = minOf[PU, cut], power = {{0, 1}}, answer = {}, k = 0,
   coefficient, boundary, degree},
  If[U === {}, Return[{{}, PU, DU}, Module]];
  If[c === Infinity,
    fail["InfiniteSeries", "An infinite series is required; use a finite working order."]];
  If[! less[0, jetValuation[U]],
    fail["NonSmallJet", "Unit-series arithmetic requires positive valuation."]];
  While[True,
    power = jetMulClosedAudit[power, U, c, ell, ass, limit];
    If[power === {}, Break[]];
    k++;
    If[k > limit, fail["ResourceLimit", "Closed-boundary Taylor depth exceeded MaxTerms."]];
    (* Exactly once, in increasing order: cf may contain mutable recurrence state. *)
    coefficient = cf[k];
    If[coefficient === Null, Break[]];
    If[! zeroQ[coefficient, ass],
      answer = jetMerge[Join[answer, jetScale[power, coefficient, ell, ass]], ell, ass]];
    If[Length[answer] > limit,
      fail["ResourceLimit", "Closed-boundary unit series exceeded MaxTerms."]]
  ];
  boundary = Total[Cases[answer, ({w_, q_} /; equal[w, c]) :> q]];
  degree = Max[0, polyDegree[boundary, ell]];
  If[equal[c, PU], degree = Max[degree, DU]];
  {Select[answer, less[#[[1]], c] &], c, degree}
];
End[];
