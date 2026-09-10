(* Candidate independent helper. Does not replace any package/System symbol.
   The Wolfram/Mathics tests supplied with this review have not been run. *)
BeginPackage["AsymptoticAudit`"];
SparseUnivariateCoefficientRules::usage =
  "SparseUnivariateCoefficientRules[p,x] returns univariate coefficient rules without a dense degree-sized vector.";
Begin["`Private`"];
SparseUnivariateCoefficientRules[polynomial_, variable_Symbol] /;
    PolynomialQ[polynomial, variable] := Module[{expanded, terms, rows, groups},
  expanded = Expand[polynomial];
  If[expanded === 0, {},
    terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
    rows = Function[term, With[{degree = Exponent[term, variable]},
      {degree, Coefficient[term, variable, degree]}]] /@ terms;
    groups = GatherBy[rows, First];
    rows = {#[[1, 1]], Total[#[[All, 2]]]} & /@ groups;
    ({#[[1]]} -> #[[2]]) & /@ Reverse[SortBy[Select[rows, Last[#] =!= 0 &], First]]
  ]
];
End[];
EndPackage[];
